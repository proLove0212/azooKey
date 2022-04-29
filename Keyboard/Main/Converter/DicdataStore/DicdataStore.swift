//
//  DicdataStore.swift
//  Keyboard
//
//  Created by β α on 2020/09/17.
//  Copyright © 2020 DevEn3. All rights reserved.
//

import Foundation

final class OSUserDict {
    var dict: DicdataStore.Dicdata = []
}

final class DicdataStore {
    init() {
        debug("DicdataStoreが初期化されました")
        self.setup()
    }

    typealias Dicdata = [DicdataElement]
    private var ccParsed: Array<Bool> = .init(repeating: false, count: 1319)
    private var ccLines: [[Int: PValue]] = []
    private var mmValue: [PValue] = []
    private let treshold: PValue = -17

    private var loudses: [String: LOUDS] = [:]
    private var importedLoudses: Set<String> = []
    private var charsID: [Character: UInt8] = [:]
    private var memory: LearningMemorys = LearningMemorys()
    private var zeroHintPredictionDicdata: Dicdata?

    private var osUserDict = OSUserDict()

    internal let maxlength: Int = 20
    private let midCount = 502
    private let cidCount = 1319

    private let numberFormatter = NumberFormatter()
    /// 初期化時のセットアップ用の関数。プロパティリストを読み込み、連接確率リストを読み込んで行分割し保存しておく。
    private func setup() {
        numberFormatter.numberStyle = .spellOut
        numberFormatter.locale = .init(identifier: "ja-JP")
        self.ccLines = [[Int: PValue]].init(repeating: [:], count: cidCount)

        do {
            let string = try String(contentsOfFile: Bundle.main.bundlePath + "/charID.chid", encoding: String.Encoding.utf8)
            charsID = [Character: UInt8].init(uniqueKeysWithValues: string.enumerated().map {($0.element, UInt8($0.offset))})
        } catch {
            debug("ファイルが存在しません: \(error)")
        }
        do {
            let url = Bundle.main.bundleURL.appendingPathComponent("mm.binary")
            do {
                let binaryData = try Data(contentsOf: url, options: [.uncached])
                let ui64array = binaryData.withUnsafeBytes {pointer -> [Float] in
                    return Array(
                        UnsafeBufferPointer(
                            start: pointer.baseAddress!.assumingMemoryBound(to: Float.self),
                            count: pointer.count / MemoryLayout<Float>.size
                        )
                    )
                }
                self.mmValue = ui64array.map {PValue($0)}
            } catch {
                debug("Failed to read the file.")
                self.mmValue = [PValue].init(repeating: .zero, count: self.midCount*self.midCount)
            }
        }
        let _ = self.loadLOUDS(identifier: "user")
    }

    func sendToDicdataStore(_ data: KeyboardActionDepartment.DicdataStoreNotification) {
        switch data {
        case .notifyAppearAgain:
            break
        case .reloadUserDict:
            self.reloadUserDict()
        case let .notifyLearningType(type):
            self.memory.notifyChangeLearningType(type)
        case .closeKeyboard:
            self.closeKeyboard()
        case .resetMemory:
            self.memory.reset()
        case let .importOSUserDict(osUserDict):
            self.osUserDict = osUserDict
        }
    }

    private func closeKeyboard() {
        self.memory.save()
    }

    private func reloadUserDict() {
        let _ = self.loadLOUDS(identifier: "user")
    }

    /// ペナルティ関数。文字数で決める。
    private func getPenalty(data: DicdataElement) -> PValue {
        return -2.0/PValue(data.word.count)
    }

    /// 計算時に利用。無視すべきデータかどうか。
    private func shouldBeRemoved(value: PValue, wordCount: Int) -> Bool {
        let d = value - self.treshold
        if d < 0 {
            return true
        }
        return 2.0/PValue(wordCount) < -d
    }

    /// 計算時に利用。無視すべきデータかどうか。
    internal func shouldBeRemoved(data: DicdataElement) -> Bool {
        let value = data.value()
        if value <= -30 {
            return true
        }
        let d = value - self.treshold
        if d < 0 {
            return true
        }
        return self.getPenalty(data: data) < -d
    }

    private func loadLOUDS(identifier: String) -> LOUDS? {
        if importedLoudses.contains(identifier) {
            return self.loudses[identifier]
        }

        importedLoudses.insert(identifier)
        if let louds = LOUDS.build(identifier) {
            self.loudses[identifier] = louds
            return louds
        } else {
            debug("loudsの読み込みに失敗、identifierは\(identifier)")
            return nil
        }
    }

    private func perfectMatchLOUDS(identifier: String, key: String) -> [Int] {
        guard let louds = self.loadLOUDS(identifier: identifier) else {
            return []
        }
        return [louds.searchNodeIndex(chars: key.map {self.charsID[$0, default: .max]})].compactMap {$0}
    }

    private func throughMatchLOUDS(identifier: String, key: String) -> [Int] {
        guard let louds = self.loadLOUDS(identifier: identifier) else {
            return []
        }
        return louds.byfixNodeIndices(chars: key.map {self.charsID[$0, default: .max]})
    }

    private func prefixMatchLOUDS(identifier: String, key: String, depth: Int = .max) -> [Int] {
        guard let louds = self.loadLOUDS(identifier: identifier) else {
            return []
        }
        return louds.prefixNodeIndices(chars: key.map {self.charsID[$0, default: .max]}, maxDepth: depth)
    }

    private func getDicdata(identifier: String, indices: Set<Int>) -> [DicdataElement] {
        // split = 2048
        let dict = [Int: [Int]].init(grouping: indices, by: {$0 >> 11})
        let data: [[Substring]] = dict.flatMap {(dictKeyValue) -> [[Substring]] in
            let datablock: [String] = LOUDS.getData(identifier + "\(dictKeyValue.key)", indices: dictKeyValue.value.map {$0 & 2047})
            let strings = datablock.flatMap {$0.split(separator: ",", omittingEmptySubsequences: false)}
            return strings.map {$0.split(separator: "\t", omittingEmptySubsequences: false)}
        }
        return data.filter {$0.count > 5}.map {self.convertDicdata(from: $0)}
    }

    /// kana2latticeから参照する。
    /// - Parameters:
    ///   - inputData: 入力データ
    ///   - from: 起点
    internal func getLOUDSData<T: InputDataProtocol, LatticeNode: LatticeNodeProtocol>(inputData: T, from index: Int) -> [LatticeNode] {
        conversionBenchmark.start(process: .辞書読み込み_全体)
        defer {
            conversionBenchmark.end(process: .辞書読み込み_全体)
        }
        conversionBenchmark.start(process: .辞書読み込み_軽量データ読み込み)
        let toIndex = min(inputData.count, index + self.maxlength)
        let segments = (index ..< toIndex).map {inputData[index...$0]}
        let wisedicdata: Dicdata = (index ..< toIndex).flatMap {self.getWiseDicdata(head: segments[$0-index], allowRomanLetter: $0+1 == toIndex)}
        let memorydicdata: Dicdata = (index ..< toIndex).flatMap {self.getMatch(segments[$0-index])}
        let osuserdictdicdata: Dicdata = (index ..< toIndex).flatMap {self.getMatchOSUserDict(segments[$0-index])}
        conversionBenchmark.end(process: .辞書読み込み_軽量データ読み込み)

        // MARK: 誤り訂正の対象を列挙する。比較的重い処理。
        // ⏱0.125108 : 辞書読み込み_誤り訂正候補列挙
        conversionBenchmark.start(process: .辞書読み込み_誤り訂正候補列挙)
        var string2segment = [String: Int].init()
        // indicesをreverseすることで、stringWithTypoは長さの長い順に並ぶ=removeでヒットしやすくなる
        let stringWithTypoData: [(string: String, penalty: PValue)] = (index ..< toIndex).reversed().flatMap {(end) -> [(string: String, penalty: PValue)] in
            let result = inputData.getRangeWithTypos(index, end)
            result.forEach {
                string2segment[$0.string] = end-index
            }
            return result
        }

        let string2penalty = [String: PValue].init(stringWithTypoData, uniquingKeysWith: {max($0, $1)})
        conversionBenchmark.end(process: .辞書読み込み_誤り訂正候補列挙)

        // MARK: 検索対象を列挙していく。prefixの共通するものを削除して検索をなるべく減らすことが目的。
        // ⏱0.021212 : 辞書読み込み_検索対象列挙
        conversionBenchmark.start(process: .辞書読み込み_検索対象列挙)
        // prefixの共通するものを削除して検索をなるべく減らす
        let strings = stringWithTypoData.map { $0.string }
        let stringSet = strings.reduce(into: Set(strings)) { (`set`, string) in
            if string.count > 4 {
                return
            }
            if set.contains(where: {$0.hasPrefix(string) && $0 != string}) {
                set.remove(string)
            }
        }
        conversionBenchmark.end(process: .辞書読み込み_検索対象列挙)

        // MARK: 列挙した検索対象から、順に検索を行う。この時点ではindicesを取得するのみ。
        // ⏱0.222327 : 辞書読み込み_検索
        conversionBenchmark.start(process: .辞書読み込み_検索)
        // 先頭の文字: そこで検索したい文字列の集合
        let group = [Character: [String]].init(grouping: stringSet, by: {$0.first!})

        var indices: [(String, Set<Int>)] = group.map {dic in
            let key = String(dic.key)
            print("辞書読み込み_検索", key, dic.value)
            let set = Set(dic.value.flatMap {string in self.throughMatchLOUDS(identifier: key, key: string)})
            return (key, set)
        }
        indices.append(("user", Set(stringSet.flatMap {self.throughMatchLOUDS(identifier: "user", key: $0)})))
        conversionBenchmark.end(process: .辞書読み込み_検索)

        // MARK: 検索によって得たindicesから辞書データを実際に取り出していく
        // ⏱0.064742 : 辞書読み込み_辞書データ生成
        conversionBenchmark.start(process: .辞書読み込み_辞書データ生成)
        let dicdata: Dicdata = indices.flatMap {(identifier, value) -> Dicdata in
            let result: Dicdata = self.getDicdata(identifier: identifier, indices: value).compactMap {(data: Dicdata.Element) in
                let penalty = string2penalty[data.ruby, default: .zero]
                if penalty.isZero {
                    return data
                }
                let ratio = Self.getTypoPenaltyRatio(data.lcid)
                let pUnit: PValue = self.getPenalty(data: data)/2   // 負の値
                let adjust = pUnit * penalty * ratio
                if self.shouldBeRemoved(value: data.value() + adjust, wordCount: data.ruby.count) {
                    return nil
                }
                return data.adjustedData(adjust)
            }
            return result
        }
        var totaldicdata: Dicdata = []
        totaldicdata.append(contentsOf: dicdata)
        totaldicdata.append(contentsOf: wisedicdata)
        totaldicdata.append(contentsOf: memorydicdata)
        totaldicdata.append(contentsOf: osuserdictdicdata)
        conversionBenchmark.end(process: .辞書読み込み_辞書データ生成)
        conversionBenchmark.start(process: .辞書読み込み_ノード生成)

        if index == .zero {
            let result: [LatticeNode] = totaldicdata.map {
                let node = LatticeNode(data: $0, romanString: segments[string2segment[$0.ruby, default: 0]], rubyCount: nil)
                node.prevs.append(LatticeNode.RegisteredNode.BOSNode())
                return node
            }
            conversionBenchmark.end(process: .辞書読み込み_ノード生成)
            return result
        } else {
            let result: [LatticeNode] = totaldicdata.map {LatticeNode(data: $0, romanString: segments[string2segment[$0.ruby, default: .zero]], rubyCount: nil)}
            conversionBenchmark.end(process: .辞書読み込み_ノード生成)
            return result
        }
    }

    /// kana2latticeから参照する。louds版。
    /// - Parameters:
    ///   - inputData: 入力データ
    ///   - to: 終点
    internal func getLOUDSData<T: InputDataProtocol, LatticeNode: LatticeNodeProtocol>(inputData: T, from fromIndex: Int, to toIndex: Int) -> [LatticeNode] {
        conversionBenchmark.start(process: .辞書読み込み_全体)
        defer {
            conversionBenchmark.end(process: .辞書読み込み_全体)
        }

        conversionBenchmark.start(process: .辞書読み込み_軽量データ読み込み)
        let segment = inputData[fromIndex...toIndex]
        let wisedicdata: Dicdata = self.getWiseDicdata(head: segment, allowRomanLetter: toIndex == inputData.count - 1)
        let memorydicdata: Dicdata = self.getMatch(segment)
        let osuserdictdicdata: Dicdata = self.getMatchOSUserDict(segment)
        conversionBenchmark.end(process: .辞書読み込み_軽量データ読み込み)

        conversionBenchmark.start(process: .辞書読み込み_誤り訂正候補列挙)
        let stringWithTypoData = inputData.getRangeWithTypos(fromIndex, toIndex)
        let string2penalty = [String: PValue].init(stringWithTypoData, uniquingKeysWith: {max($0, $1)})
        conversionBenchmark.end(process: .辞書読み込み_誤り訂正候補列挙)

        // MARK: 検索によって得たindicesから辞書データを実際に取り出していく
        conversionBenchmark.start(process: .辞書読み込み_検索)
        // 先頭の文字: そこで検索したい文字列の集合
        let group = [Character: [String]].init(grouping: stringWithTypoData.map {$0.string}, by: {$0.first!})

        var indices: [(String, Set<Int>)] = group.map {dic in
            let key = String(dic.key)
            let set = Set(dic.value.flatMap {string in self.perfectMatchLOUDS(identifier: key, key: string)})
            return (key, set)
        }
        indices.append(("user", Set(stringWithTypoData.flatMap {self.perfectMatchLOUDS(identifier: "user", key: $0.string)})))
        conversionBenchmark.end(process: .辞書読み込み_検索)

        conversionBenchmark.start(process: .辞書読み込み_辞書データ生成)
        let dicdata: Dicdata = indices.flatMap {(identifier, value) -> Dicdata in
            let result: Dicdata = self.getDicdata(identifier: identifier, indices: value).compactMap {(data: Dicdata.Element) in
                let penalty = string2penalty[data.ruby, default: .zero]
                if penalty.isZero {
                    return data
                }
                let ratio = Self.getTypoPenaltyRatio(data.lcid)
                let pUnit: PValue = self.getPenalty(data: data)/2   // 負の値
                let adjust = pUnit * penalty * ratio
                if self.shouldBeRemoved(value: data.value() + adjust, wordCount: data.ruby.count) {
                    return nil
                }
                return data.adjustedData(adjust)
            }
            return result
        }

        var totaldicdata: Dicdata = []
        totaldicdata.append(contentsOf: dicdata)
        totaldicdata.append(contentsOf: wisedicdata)
        totaldicdata.append(contentsOf: memorydicdata)
        totaldicdata.append(contentsOf: osuserdictdicdata)
        conversionBenchmark.end(process: .辞書読み込み_辞書データ生成)
        conversionBenchmark.start(process: .辞書読み込み_ノード生成)
        if fromIndex == .zero {
            let result: [LatticeNode] = totaldicdata.map {
                let node = LatticeNode(data: $0, romanString: segment, rubyCount: nil)
                node.prevs.append(LatticeNode.RegisteredNode.BOSNode())
                return node
            }
            conversionBenchmark.end(process: .辞書読み込み_ノード生成)
            return result
        } else {
            let result: [LatticeNode] = totaldicdata.map {LatticeNode(data: $0, romanString: segment, rubyCount: nil)}
            conversionBenchmark.end(process: .辞書読み込み_ノード生成)
            return result
        }
    }

    internal func getZeroHintPredictionDicdata() -> Dicdata {
        if let dicdata = self.zeroHintPredictionDicdata {
            return dicdata
        }
        do {
            let csvString = try String(contentsOfFile: Bundle.main.bundlePath + "/p_null.csv", encoding: String.Encoding.utf8)
            let csvLines = csvString.split(separator: "\n")
            let csvData = csvLines.map {$0.split(separator: ",", omittingEmptySubsequences: false)}
            let dicdata: Dicdata = csvData.map {convertDicdata(from: $0)}
            self.zeroHintPredictionDicdata = dicdata
            return dicdata
        } catch {
            debug(error)
            self.zeroHintPredictionDicdata = []
            return []
        }
    }

    /// 辞書から予測変換データを読み込む関数
    /// - Parameters:
    ///   - head: 辞書を引く文字列
    /// - Returns:
    ///   発見されたデータのリスト。
    internal func getPredictionLOUDSDicdata<S: StringProtocol>(head: S) -> Dicdata {
        let count = head.count
        if count == .zero {
            return []
        }
        if count == 1 {
            do {
                let csvString = try String(contentsOfFile: Bundle.main.bundlePath + "/p_\(head).csv", encoding: String.Encoding.utf8)
                let csvLines = csvString.split(separator: "\n")
                let csvData = csvLines.map {$0.split(separator: ",", omittingEmptySubsequences: false)}
                let dicdata: Dicdata = csvData.map {self.convertDicdata(from: $0)}
                return dicdata
            } catch {
                debug("ファイルが存在しません: \(error)")
                return []
            }
        } else if count == 2 {
            let first = String(head.first!)
            // 最大700件に絞ることによって低速化を回避する。
            // FIXME: 場当たり的な対処。改善が求められる。
            let prefixIndices = self.prefixMatchLOUDS(identifier: first, key: String(head), depth: 5).prefix(700)
            return self.getDicdata(identifier: first, indices: Set(prefixIndices))
        } else {
            let first = String(head.first!)
            let prefixIndices = self.prefixMatchLOUDS(identifier: first, key: String(head)).prefix(700)
            return self.getDicdata(identifier: first, indices: Set(prefixIndices))
        }
    }

    private func convertDicdata<S: StringProtocol>(from dataString: [S]) -> DicdataElement {
        let ruby = String(dataString[0])
        let word = dataString[1].isEmpty ? ruby:String(dataString[1])
        let lcid = Int(dataString[2]) ?? .zero
        let rcid = Int(dataString[3]) ?? lcid
        let mid = Int(dataString[4]) ?? .zero
        let value: PValue = PValue(dataString[5]) ?? -30.0
        let element = DicdataElement(word: word, ruby: ruby, lcid: lcid, rcid: rcid, mid: mid, value: value)
        let adjust: PValue = PValue(self.getSingleMemory(element) * 3)
        return element.adjustedData(adjust)
    }

    /// 補足的な辞書情報を得る。
    private func getWiseDicdata(head: String, allowRomanLetter: Bool) -> Dicdata {
        var result: Dicdata = []
        result.append(contentsOf: self.getJapaneseNumberDicdata(head: head))
        if let number = Float(head) {
            result.append(DicdataElement(ruby: head, cid: 1295, mid: 361, value: -14))
            if number.truncatingRemainder(dividingBy: 1) == 0 {
                let int = Int(number)
                if int < Int(1E18) && -Int(1E18) < int, let kansuji = self.numberFormatter.string(from: NSNumber(value: int)) {
                    result.append(DicdataElement(word: kansuji, ruby: head, cid: 1295, mid: 361, value: -16))
                }
            }
        }

        // headを英単語として候補に追加する
        if VariableStates.shared.keyboardLanguage == .en_US && head.onlyRomanAlphabet {
            result.append(DicdataElement(ruby: head, cid: 1288, mid: 40, value: -14))
        }
        // 入力を全てひらがな、カタカナに変換したものを候補に追加する
        if VariableStates.shared.keyboardLanguage != .en_US && VariableStates.shared.inputStyle == .roman2kana {
            if let katakana = Roman2Kana.katakanaChanges[head], let hiragana = Roman2Kana.hiraganaChanges[head] {
                result.append(DicdataElement(word: hiragana, ruby: katakana, cid: 1288, mid: 501, value: -13))
                result.append(DicdataElement(ruby: katakana, cid: 1288, mid: 501, value: -14))
            }
        }

        if head.count == 1, let hira = head.applyingTransform(.hiraganaToKatakana, reverse: true), allowRomanLetter || !head.onlyRomanAlphabet {
            if head == hira {
                result.append(DicdataElement(ruby: head, cid: 1288, mid: 501, value: -14))
            } else {
                result.append(DicdataElement(word: hira, ruby: head, cid: 1288, mid: 501, value: -13))
                result.append(DicdataElement(ruby: head, cid: 1288, mid: 501, value: -14))
            }
        }
        return result
    }

    private func loadCCBinary(url: URL) -> [(Int32, Float)] {
        do {
            let binaryData = try Data(contentsOf: url, options: [.uncached])
            let ui64array = binaryData.withUnsafeBytes {pointer -> [(Int32, Float)] in
                return Array(
                    UnsafeBufferPointer(
                        start: pointer.baseAddress!.assumingMemoryBound(to: (Int32, Float).self),
                        count: pointer.count / MemoryLayout<(Int32, Float)>.size
                    )
                )
            }
            return ui64array
        } catch {
            debug("Failed to read the file.", error)
            return []
        }
    }

    /// OSのユーザ辞書からrubyに等しい語を返す。
    private func getMatchOSUserDict<S: StringProtocol>(_ ruby: S) -> Dicdata {
        return self.osUserDict.dict.filter {$0.ruby == ruby}
    }

    /// OSのユーザ辞書からrubyに先頭一致する語を返す。
    internal func getPrefixMatchOSUserDict<S: StringProtocol>(_ ruby: S) -> Dicdata {
        return self.osUserDict.dict.filter {$0.ruby.hasPrefix(ruby)}
    }

    /// rubyに等しい語を返す。
    private func getMatch<S: StringProtocol>(_ ruby: S) -> Dicdata {
        return self.memory.match(ruby)
    }
    /// rubyに等しい語の回数を返す。
    internal func getSingleMemory(_ data: DicdataElement) -> Int {
        return self.memory.getSingle(data)
    }
    /// rubyを先頭にもつ語を返す。
    internal func getPrefixMemory<S: StringProtocol>(_ prefix: S) -> Dicdata {
        return self.memory.getPrefixDicdata(prefix)
    }
    /// 二つの語の並び回数を返す。
    internal func getMatch(_ previous: DicdataElement, next: DicdataElement) -> Int {
        return self.memory.matchNext(previous, next: next)
    }
    /// 一つの後から連結する次の語を返す。
    internal func getNextMemory(_ data: DicdataElement) -> [(next: DicdataElement, count: Int)] {
        return self.memory.getNextData(data)
    }

    // 学習を反映する
    internal func updateLearningData(_ candidate: Candidate, with previous: DicdataElement?) {
        self.memory.update(candidate.data, lastData: previous)
    }
    /// class idから連接確率を得る関数
    /// - Parameters:
    ///   - former: 左側の語のid
    ///   - latter: 右側の語のid
    /// - Returns:
    ///   連接確率の対数。
    /// - 要求があった場合ごとにファイルを読み込んで
    /// 速度: ⏱0.115224 : 変換_処理_連接コスト計算_CCValue
    internal func getCCValue(_ former: Int, _ latter: Int) -> PValue {
        if !ccParsed[former] {
            let url = Bundle.main.bundleURL.appendingPathComponent("\(former).binary")
            let values = loadCCBinary(url: url)
            ccLines[former] = [Int: PValue].init(uniqueKeysWithValues: values.map {(Int($0.0), PValue($0.1))})
            ccParsed[former] = true
        }
        let defaultValue = ccLines[former][-1, default: -25]
        return ccLines[former][latter, default: defaultValue]
    }

    /// meaning idから意味連接尤度を得る関数
    /// - Parameters:
    ///   - former: 左側の語のid
    ///   - latter: 右側の語のid
    /// - Returns:
    ///   意味連接確率の対数。
    /// - 要求があった場合ごとに確率値をパースして取得する。
    internal func getMMValue(_ former: Int, _ latter: Int) -> PValue {
        if former == 500 || latter == 500 {
            return 0
        }
        return self.mmValue[former * self.midCount + latter]
    }

    // 誤り訂正候補の構築の際、ファイルが存在しているか事前にチェックし、存在していなければ以後の計算を打ち切ることで、計算を減らす。
    internal static func existFile<S: StringProtocol>(identifier: S) -> Bool {
        let fileName = identifier.prefix(1)
        let path = Bundle.main.bundlePath + "/" + fileName + ".louds"
        return FileManager.default.fileExists(atPath: path)
    }

    /*
     文節の切れ目とは

     * 後置機能語→前置機能語
     * 後置機能語→内容語
     * 内容語→前置機能語
     * 内容語→内容語

     となる。逆に文節の切れ目にならないのは

     * 前置機能語→内容語
     * 内容語→後置機能語

     の二通りとなる。

     */
    /// class idから、文節かどうかを判断する関数。
    /// - Parameters:
    ///   - c_former: 左側の語のid
    ///   - c_latter: 右側の語のid
    /// - Returns:
    ///   そこが文節であるかどうか。
    internal static func isClause(_ former: Int, _ latter: Int) -> Bool {
        // EOSが基本多いので、この順の方がヒット率が上がると思われる。
        let latter_wordtype = Self.judgeWordType(cid: latter)
        if latter_wordtype == 3 {
            return false
        }
        let former_wordtype = Self.judgeWordType(cid: former)
        if former_wordtype == 3 {
            return false
        }
        if latter_wordtype == 0 {
            return former_wordtype != 0
        }
        if latter_wordtype == 1 {
            return former_wordtype != 0
        }
        return false
    }

    private static let BOS_EOS_wordIDs: Set<Int> = [0, 1316]
    private static let PREPOSITION_wordIDs: Set<Int> = [1315, 6, 557, 558, 559, 560]
    private static let INPOSITION_wordIDs: Set<Int> = Set<Int>((561..<868).map {$0}
                                                                + (1283..<1297).map {$0}
                                                                + (1306..<1310).map {$0}
                                                                + (11..<53).map {$0}
                                                                + (555..<557).map {$0}
                                                                + (1281..<1283).map {$0}
    ).union([1314, 3, 2, 4, 5, 1, 9])
    /*
     private static let POSTPOSITION_wordIDs: Set<Int> = Set<Int>((7...8).map{$0}
     + (54..<555).map{$0}
     + (868..<1281).map{$0}
     + (1297..<1306).map{$0}
     + (1310..<1314).map{$0}
     ).union([10])
     */
    internal static func includeMMValueCalculation(_ data: DicdataElement) -> Bool {
        // LREでない場合はfalseを返す。
        if !data.isLRE {
            return false
        }
        // 非自立動詞
        if 895...1280 ~= data.lcid {
            return true
        }
        // 非自立名刺
        if 1297...1305 ~= data.lcid {
            return true
        }
        // 内容語かどうか
        return Self.INPOSITION_wordIDs.contains(data.lcid)
    }

    internal static func getTypoPenaltyRatio(_ lcid: Int) -> PValue {
        // 助詞147...368, 助動詞369...554
        if 147...554 ~= lcid {
            return 2.5
        }
        return 1
    }

    // カウントをゼロにすべき語の種類
    internal static func needWValueMemory(_ data: DicdataElement) -> Bool {
        // 助詞、助動詞
        if 147...554 ~= data.lcid {
            return false
        }
        // 接頭辞
        if 557...560 ~= data.lcid {
            return false
        }
        // 接尾名詞を除去
        if 1297...1305 ~= data.lcid {
            return false
        }
        // 記号を除去
        if 6...9 ~= data.lcid {
            return false
        }
        if 0 == data.lcid || 1316 == data.lcid {
            return false
        }

        return true
    }

    ///
    /// - Returns:
    ///   - 3 when BOS/EOS
    ///   - 0 when preposition
    ///   - 1 when core
    ///   - 2 when postposition
    internal static func judgeWordType(cid: Int) -> Int {
        if Self.BOS_EOS_wordIDs.contains(cid) {
            return 3    // BOS/EOS
        }
        if Self.PREPOSITION_wordIDs.contains(cid) {
            return 0    // 前置
        }
        if Self.INPOSITION_wordIDs.contains(cid) {
            return 1 // 内容
        }
        return 2   // 後置
    }

    internal static let possibleNexts: [String: [String]] = [
        "x": ["ァ", "ィ", "ゥ", "ェ", "ォ", "ッ", "ャ", "ュ", "ョ", "ヮ"],
        "l": ["ァ", "ィ", "ゥ", "ェ", "ォ", "ッ", "ャ", "ュ", "ョ", "ヮ"],
        "xt": ["ッ"],
        "lt": ["ッ"],
        "xts": ["ッ"],
        "lts": ["ッ"],
        "xy": ["ャ", "ュ", "ョ"],
        "ly": ["ャ", "ュ", "ョ"],
        "xw": ["ヮ"],
        "lw": ["ヮ"],
        "v": ["ヴ"],
        "k": ["カ", "キ", "ク", "ケ", "コ"],
        "q": ["クァ", "クィ", "クゥ", "クェ", "クォ"],
        "qy": ["クャ", "クィ", "クュ", "クェ", "クョ"],
        "qw": ["クヮ", "クィ", "クゥ", "クェ", "クォ"],
        "ky": ["キャ", "キィ", "キュ", "キェ", "キョ"],
        "g": ["ガ", "ギ", "グ", "ゲ", "ゴ"],
        "gy": ["ギャ", "ギィ", "ギュ", "ギェ", "ギョ"],
        "s": ["サ", "シ", "ス", "セ", "ソ"],
        "sy": ["シャ", "シィ", "シュ", "シェ", "ショ"],
        "sh": ["シャ", "シィ", "シュ", "シェ", "ショ"],
        "z": ["ザ", "ジ", "ズ", "ゼ", "ゾ"],
        "zy": ["ジャ", "ジィ", "ジュ", "ジェ", "ジョ"],
        "j": ["ジ"],
        "t": ["タ", "チ", "ツ", "テ", "ト"],
        "ty": ["チャ", "チィ", "チュ", "チェ", "チョ"],
        "ts": ["ツ"],
        "th": ["テャ", "ティ", "テュ", "テェ", "テョ"],
        "tw": ["トァ", "トィ", "トゥ", "トェ", "トォ"],
        "cy": ["チャ", "チィ", "チュ", "チェ", "チョ"],
        "ch": ["チ"],
        "d": ["ダ", "ヂ", "ヅ", "デ", "ド"],
        "dy": ["ヂ"],
        "dh": ["デャ", "ディ", "デュ", "デェ", "デョ"],
        "dw": ["ドァ", "ドィ", "ドゥ", "ドェ", "ドォ"],
        "n": ["ナ", "ニ", "ヌ", "ネ", "ノ", "ン"],
        "ny": ["ニャ", "ニィ", "ニュ", "ニェ", "ニョ"],
        "h": ["ハ", "ヒ", "フ", "ヘ", "ホ"],
        "hy": ["ヒャ", "ヒィ", "ヒュ", "ヒェ", "ヒョ"],
        "hw": ["ファ", "フィ", "フェ", "フォ"],
        "f": ["フ"],
        "b": ["バ", "ビ", "ブ", "ベ", "ボ"],
        "by": ["ビャ", "ビィ", "ビュ", "ビェ", "ビョ"],
        "p": ["パ", "ピ", "プ", "ペ", "ポ"],
        "py": ["ピャ", "ピィ", "ピュ", "ピェ", "ピョ"],
        "m": ["マ", "ミ", "ム", "メ", "モ"],
        "my": ["ミャ", "ミィ", "ミュ", "ミェ", "ミョ"],
        "y": ["ヤ", "ユ", "イェ", "ヨ"],
        "r": ["ラ", "リ", "ル", "レ", "ロ"],
        "ry": ["リャ", "リィ", "リュ", "リェ", "リョ"],
        "w": ["ワ", "ウィ", "ウェ", "ヲ"],
        "wy": ["ヰ", "ヱ"]
    ]
}
