//
//  extension Converter.swift
//  Keyboard
//
//  Created by β α on 2020/09/11.
//  Copyright © 2020 DevEn3. All rights reserved.
//

import Foundation

extension KanaKanjiConverter{
    ///和暦で書かれた入力を西暦に変換する関数
    /// - parameters:
    ///   - string: 入力
    func toSeireki(_ inputData: InputData) -> [Candidate] {
        let string = inputData.katakanaString
        let count = inputData.characters.count
        let makeResult0: (String) -> Candidate = {
            return Candidate(
                text: $0,
                value: -18,
                correspondingCount: count,
                lastMid: 237,
                data: [LRE_DicDataElement(word: $0, ruby: string, cid: 1285, mid: 237, value: -18)]
            )
        }


        let katakanaStringCount = string.count
        if string == "メイジガンネン"{
            return [
                makeResult0("1868年")
            ]
        }
        if string == "タイショウガンネン"{
            return [
                makeResult0("1912年")
            ]
        }
        if string == "ショウワガンネン"{
            return [
                makeResult0("1926年")
            ]
        }
        if string == "ヘイセイガンネン"{
            return [
                makeResult0("1989年")
            ]
        }
        if string == "レイワガンネン"{
            return [
                makeResult0("2019年")
            ]
        }
        if !string.hasSuffix("ネン"){
            return []
        }
        if string.hasPrefix("ショウワ"){
            if katakanaStringCount == 8, let year = Int(string[4...5]){
                return [
                    makeResult0("\(year + 1925)年")
                ]
            }
            if katakanaStringCount == 7, let year = Int(string[4...4]){
                return [
                    makeResult0("\(year + 1925)年")
                ]
            }
        }
        if string.hasPrefix("ヘイセイ"){
            if katakanaStringCount == 8, let year = Int(string[4...5]){
                return [
                    makeResult0("\(year + 1988)年")
                ]
            }
            if katakanaStringCount == 7, let year = Int(string[4...4]){
                return [
                    makeResult0("\(year + 1988)年")
                ]
            }
        }
        if string.hasPrefix("レイワ"){
            if katakanaStringCount == 7, let year = Int(string[3...4]){
                return [
                    makeResult0("\(year + 2018)年")
                ]
            }
            if katakanaStringCount == 6, let year = Int(string[3...3]){
                return [
                    makeResult0("\(year + 2018)年")
                ]
            }
        }
        if string.hasPrefix("メイジ"){
            if katakanaStringCount == 7, let year = Int(string[3...4]){
                return [
                    makeResult0("\(year + 1867)年")
                ]
            }
            if katakanaStringCount == 6, let year = Int(string[3...3]){
                return [
                    makeResult0("\(year + 1867)年")
                ]
            }
        }
        
        if string.hasPrefix("タイショウ"){
            if katakanaStringCount == 9, let year = Int(string[5...6]){
                return [
                    makeResult0("\(year + 1911)年")
                ]
            }
            if katakanaStringCount == 8, let year = Int(string[5...5]){
                return [
                    makeResult0("\(year + 1911)年")
                ]
            }
        }
        return []

    }
    ///西暦で書かれた入力を和暦に変換する関数
    /// - parameters:
    ///   - string: 入力
    func toWareki(_ inputData: InputData) -> [Candidate] {
        let string = inputData.katakanaString

        let makeResult0: (String) -> Candidate = {
            return Candidate(
                text: $0,
                value: -18,
                correspondingCount: inputData.characters.count,
                lastMid: 237,
                data: [LRE_DicDataElement(word: $0, ruby: string, cid: 1285, mid: 237, value: -18)]
            )
        }
        let makeResult1: (String) -> Candidate = {
            return Candidate(
                text: $0,
                value: -19,
                correspondingCount: inputData.characters.count,
                lastMid: 237,
                data: [LRE_DicDataElement(word: $0, ruby: string, cid: 1285, mid: 237, value: -19)]
            )
        }

        guard let seireki = Int(string.prefix(4)) else{
            return []
        }
        if !string.hasSuffix("ネン"){
            return []
        }
        if seireki == 1989{
            return [
                makeResult0("平成元年"),
                makeResult1("昭和64年")
            ]
        }
        if seireki == 2019{
            return [
                makeResult0("令和元年"),
                makeResult1("平成31年")
            ]
        }
        if seireki == 1926{
            return [
                makeResult0("昭和元年"),
                makeResult1("大正15年")
            ]
        }
        if seireki == 1912{
            return [
                makeResult0("大正元年"),
                makeResult1("明治45年")
            ]
        }
        if seireki == 1868{
            return [
                makeResult0("明治元年"),
                makeResult1("慶應4年")
            ]

        }
        if (1990...2018).contains(seireki){
            let i = seireki-1988
            return [
                makeResult0("平成\(i)年"),
            ]
        }
        if (1927...1988).contains(seireki){
            let i = seireki-1925
            return [
                makeResult0("昭和\(i)年"),
            ]
        }
        if (1869...1911).contains(seireki){
            let i = seireki-1967
            return [
                makeResult0("明治\(i)年"),
            ]
        }
        if (1912...1926).contains(seireki){
            let i = seireki-1911
            return [
                makeResult0("大正\(i)年"),
            ]
        }
        if 2020<=seireki{
            let i = seireki-2018
            return [
                makeResult0("令和\(i)年"),
            ]
        }
        return []
    }

}
