//
//  RegisteredNode.swift
//  Keyboard
//
//  Created by β α on 2020/09/16.
//  Copyright © 2020 DevEn3. All rights reserved.
//

import Foundation

protocol RegisteredNodeProtocol {
    var data: DicdataElement {get}
    var prev: (any RegisteredNodeProtocol)? {get}
    var totalValue: PValue {get}
    var ruby: String {get}
    var rubyCount: Int {get}

    static func BOSNode() -> Self
    static func fromLastCandidate(_ candidate: Candidate) -> Self
}

struct RegisteredNode: RegisteredNodeProtocol {
    let data: DicdataElement
    let prev: (any RegisteredNodeProtocol)?
    let totalValue: PValue
    var convertTargetLength: Int
    // 入力に対応する文字列
    // ダイレクト入力中であれば「今日は」に対して「キョウハ」
    // ローマ字入力中であれば「今日は」に対してkyouhaになる
    var input: String

    var rubyCount: Int {
        convertTargetLength
    }

    // カタカナ
    var ruby: String {
        input
    }

    init(data: DicdataElement, registered: RegisteredNode?, totalValue: PValue, convertTargetLength: Int, input: String) {
        self.data = data
        self.prev = registered
        self.totalValue = totalValue
        self.input = input
        self.convertTargetLength = convertTargetLength
    }

    static func BOSNode() -> RegisteredNode {
        RegisteredNode(data: DicdataElement.BOSData, registered: nil, totalValue: 0, convertTargetLength: 0, input: "")
    }

    static func fromLastCandidate(_ candidate: Candidate) -> RegisteredNode {
        RegisteredNode(
            data: DicdataElement(word: "", ruby: "", lcid: CIDData.BOS.cid , rcid: candidate.data.last?.rcid ?? CIDData.BOS.cid, mid: candidate.lastMid, value: 0),
            registered: nil,
            totalValue: 0,
            convertTargetLength: 0,
            input: ""
        )
    }
}


extension RegisteredNodeProtocol {
    func getCandidateData() -> CandidateData {
        guard let prev = self.prev else {
            let unit = ClauseDataUnit()
            unit.mid = self.data.mid
            unit.ruby = self.ruby
            unit.rubyCount = self.rubyCount
            return CandidateData(clauses: [(clause: unit, value: .zero)], data: [])
        }
        var lastcandidate = prev.getCandidateData()    // 自分に至るregisterdそれぞれのデータに処理

        if self.data.word.isEmpty {
            return lastcandidate
        }

        guard let lastClause = lastcandidate.lastClause else {
            return lastcandidate
        }

        if lastClause.text.isEmpty || !DicdataStore.isClause(prev.data.rcid, self.data.lcid) {
            // 文節ではないので、最後に追加する。
            lastClause.text.append(self.data.word)
            lastClause.ruby.append(self.ruby)
            lastClause.rubyCount += self.rubyCount
            // 最初だった場合を想定している
            if (lastClause.mid == 500 && self.data.mid != 500) || DicdataStore.includeMMValueCalculation(self.data) {
                lastClause.mid = self.data.mid
            }
            lastcandidate.clauses[lastcandidate.clauses.count-1].value = self.totalValue
            lastcandidate.data.append(self.data)
            return lastcandidate
        }
        // 文節の区切りだった場合
        else {
            let unit = ClauseDataUnit()
            unit.text = self.data.word
            unit.ruby = self.ruby
            unit.rubyCount = self.rubyCount
            if DicdataStore.includeMMValueCalculation(self.data) {
                unit.mid = self.data.mid
            }
            // 前の文節の処理
            lastClause.nextLcid = self.data.lcid
            // TODO: ここに手を加える必要がある
            // この部分は`input`が不完全であるため不適切な実装になっている。改善が必要。
            switch VariableStates.shared.inputStyle {
            case .direct:
                break
            case .roman2kana:
                lastClause.ruby = lastClause.ruby.roman2katakana
            }
            lastcandidate.clauses.append((clause: unit, value: self.totalValue))
            lastcandidate.data.append(self.data)
            return lastcandidate
        }
    }
}
