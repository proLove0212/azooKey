//
//  KanaComponent.swift
//  Keyboard
//
//  Created by β α on 2020/09/19.
//  Copyright © 2020 DevEn3. All rights reserved.
//

import Foundation

final class KanaRomanStateHolder {
    var components: [KanaComponent] = []
    var count: Int {
        return components.count
    }

    init() {}

    init(components: [KanaComponent]) {
        self.components = components
    }

    /// internalCharacterCount+1文字目から始まるfreezedなデータを返す。
    func freezedData(internalCharacterCount: Int) -> KanaComponent? {
        var index = -1
        let counts = components.map {$0.internalText.count}
        while true {
            if counts.endIndex == index {
                return nil
            }
            let sum = counts.prefix(index + 1).reduce(0, +)
            if sum == internalCharacterCount - 1 {
                if components[index + 1].isFreezed {
                    return components[index + 1]
                } else {
                    return nil
                }
            }
            if sum > internalCharacterCount - 1 {
                if components[index].isFreezed {
                    let delta = sum - internalCharacterCount + 1
                    let splited = components[index].split().suffix(delta)
                    return KanaComponent(internalText: splited.map {$0.internalText}.joined(), kana: splited.map {$0.displayedText}.joined(), isFreezed: true, escapeRomanKanaConverting: true)
                } else {
                    return nil
                }
            }
            index += 1
        }
    }

    // 左側=leftSideTextの部分に対してテキストを挿入する
    @discardableResult
    func insert(_ input: String, leftSideText: some StringProtocol, isFreezed: Bool = false) -> (result: String, delete: Int, input: String) {
        if isFreezed {
            let component = KanaComponent(internalText: input, kana: input, isFreezed: true, escapeRomanKanaConverting: true)
            if components.isEmpty {
                let (text, _, delete, input) = String.roman2hiraganaConsideringDisplaying(current: [], added: input)
                self.components = [component]
                return (text, delete, input)
            }
            if leftSideText.isEmpty {
                let (text, _, delete, input) = String.roman2hiraganaConsideringDisplaying(current: [], added: input)
                self.components.insert(component, at: 0)
                return (text, delete, input)
            }
            let index = supremumIndexWithFreezing(for: leftSideText)
            let (text, _, delete, input) = String.roman2hiraganaConsideringDisplaying(current: self.components[0...index], added: input)
            self.components.insert(component, at: index+1)
            return (text, delete, input)
        }
        if components.isEmpty {
            let (text, components, delete, input) = String.roman2hiraganaConsideringDisplaying(current: [], added: input)
            self.components = components
            return (text, delete, input)
        }
        if leftSideText.isEmpty {
            let (text, components, delete, input) = String.roman2hiraganaConsideringDisplaying(current: [], added: input)
            self.components.insert(contentsOf: components, at: 0)
            return (text, delete, input)
        }
        let index = supremumIndexWithFreezing(for: leftSideText)
        let (text, components, delete, input) = String.roman2hiraganaConsideringDisplaying(current: self.components[0...index], added: input)
        self.components = components + self.components.suffix(count - index - 1)
        return (text, delete, input)

    }

    // 左側=leftSideTextの部分に対してテキストを挿入する
    func complete(_ completed: some StringProtocol) {
        let index = supremumIndexWithFreezing(for: completed)
        components = Array(components.dropFirst(index + 1))
    }

    // 左側=leftSideTextを削除する
    // 必要な動作：入力された数のcharacterを左から落とす
    func complete(_ completedCount: Int) -> Int {
        var count = 0
        var displayedTextCount = 0
        while !components.isEmpty {
            let charCount = components[0].internalText.count
            if count + charCount < completedCount {
                let first = components.removeFirst()
                count += charCount
                displayedTextCount += first.displayedText.count
                continue
            } else if count + charCount == completedCount {
                let first = components.removeFirst()
                displayedTextCount += first.displayedText.count
                break
            } else {
                var firsts = components[0].split()
                while count < completedCount {
                    count += firsts[0].internalText.count
                    let first = firsts.removeFirst()
                    displayedTextCount += first.displayedText.count
                }
                self.components = firsts + components.dropFirst()
                break
            }
        }
        return displayedTextCount
    }

    // 左側=leftSideTextの部分に対してかな文字count分削除する
    func delete(kanaCount: Int, leftSideText: some StringProtocol) {
        if self.components.isEmpty {
            return
        }
        let index = supremumIndexWithFreezing(for: leftSideText)
        var deletedCount = 0
        var prefix = components.prefix(index + 1)
        do {
            var _index = index
            while deletedCount < kanaCount {
                if _index == -1 {
                    break
                }
                let _count = prefix[_index].displayedText.count
                if deletedCount + _count > kanaCount {
                    let component = prefix.popLast()
                    let splited = component?.split() ?? []
                    prefix += splited.dropLast(kanaCount - deletedCount)
                    break
                } else if deletedCount + _count == kanaCount {
                    prefix.removeLast()
                    break
                } else {
                    prefix.removeLast()
                    _index -= 1
                    deletedCount += _count
                }
            }
        }
        components = prefix + components.suffix(count - index - 1)
    }

    // 左側=leftSideTextとなるようにカーソルを移動したとして、freezeを実行する
    func freeze(leftSideText: some StringProtocol) {
        let result = supremumIndex(for: leftSideText)
        if !result.match {
            let component = components[result.index]
            components = Array(components.prefix(result.index) + component.split() + components.suffix(count - result.index - 1))
        } else {
            let component = components[result.index]
            if ["っ", "ん"].contains(component.displayedText) {
                let new = KanaComponent(internalText: component.internalText, kana: component.displayedText, isFreezed: true, escapeRomanKanaConverting: true)
                components[result.index] = new
            }
        }
    }

    // 左側=leftSideTextとなるようにカーソルを移動したとして、freezeを実行する
    func supremumIndexWithFreezing(for leftSideText: some StringProtocol) -> Int {
        let result = supremumIndex(for: leftSideText)
        if !result.match {
            let component = components[result.index]
            components = Array(components.prefix(result.index) + component.split() + components.suffix(count - result.index - 1))
        } else {
            let component = components[result.index]
            if ["っ", "ん"].contains(component.displayedText) && component.internalText.count == 1 && !component.isFreezed {
                let new = KanaComponent(internalText: component.internalText, kana: component.displayedText, isFreezed: true, escapeRomanKanaConverting: true)
                components[result.index] = new
            }
        }
        return supremumIndex(for: leftSideText).index
    }

    func supremumIndex(for leftSideText: some StringProtocol) -> (index: Int, match: Bool) {
        var index = count
        let mappedKana = components.map {$0.displayedText}
        while true {
            if index == .zero || !mappedKana.prefix(index).joined().hasPrefix(leftSideText) {
                index += 1
                break
            }
            index -= 1
        }
        return (index - 1, mappedKana.prefix(index).joined() == leftSideText)
    }
}

struct KanaComponent {
    /// 内部的に一文字として扱う単位。
    let internalText: String
    /// ユーザが見ているテキストに対応する単位。
    let displayedText: String
    /// 誤り可能性・変換を禁止し、この文字のまま使うことを求める変数。
    let isFreezed: Bool
    /// ローマ字かな変換でエスケープを要求する変数。
    let escapeRomanKanaConverting: Bool

    init(internalText: String, kana: String, isFreezed: Bool = false, escapeRomanKanaConverting: Bool = true) {
        self.internalText = internalText
        self.displayedText = kana
        self.isFreezed = isFreezed
        self.escapeRomanKanaConverting = escapeRomanKanaConverting
    }

    func split() -> [KanaComponent] {
        return self.displayedText.map {KanaComponent(internalText: String($0), kana: String($0), isFreezed: true, escapeRomanKanaConverting: true)}
    }
}
