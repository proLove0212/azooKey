//
//  UserSetting.swift
//  KanaKanjier
//
//  Created by β α on 2020/11/20.
//  Copyright © 2020 DevEn3. All rights reserved.
//

import SwiftUI

enum Setting: String {
    case japaneseKeyboardLayout = "keyboard_type"
    case englishKeyboardLayout = "keyboard_type_en"
    case preferredLanguage = "preferred_language_order"
    case numberTabCustomKeys = "roman_number_custom_keys"

    case koganaKeyFlick = "kogana_flicks"
    case kanaSymbolsKeyFlick = "kana_symbols_flick"
    case symbolsTabKeyFlick = "symbols_tab_flick"
    case abcTabKeyFlick = "abc_tab_flick"
    case hiraTabKeyFlick = "hira_tab_flick"

    case learningType = "memory_learining_styple_setting"
    case stopLearningWhenSearch = "stop_learning_when_search"

    case unicodeCandidate = "unicode_candidate"
    case wesJapCalender = "western_japanese_calender_candidate"
    case typographyLetter = "typography_roman_candidate"
    case englishCandidate = "roman_english_candidate"
    case halfKana = "half_kana_candidate"
    case fullRoman = "full_roman_candidate"
    case memoryReset = "memory_reset_setting"
    case useOSuserDict = "use_OS_user_dict"

    case enableSound = "sound_enable_setting"

    case resultViewFontSize = "result_view_font_size"
    case keyViewFontSize = "key_view_font_size"

    case displayTabBarButton = "display_tab_bar_button"

    var key: String {
        self.rawValue
    }

    static let boolSetting: [Self] = [.wesJapCalender, .typographyLetter, .halfKana, .unicodeCandidate, .englishCandidate, .stopLearningWhenSearch, .enableSound]

    var title: LocalizedStringKey {
        switch self {
        case .japaneseKeyboardLayout:
            return "日本語キーボードの種類"
        case .englishKeyboardLayout:
            return "日本語キーボードの種類"
        case .preferredLanguage:
            return "入力する言語"
        case .numberTabCustomKeys:
            return "数字タブのカスタムキー機能"
        case .koganaKeyFlick:
            return "「小ﾞﾟ」キーのフリック割り当て"
        case .kanaSymbolsKeyFlick:
            return "「､｡?!」キーのフリック割り当て"
        case .symbolsTabKeyFlick:
            return "「☆123」キーのフリック割り当て"
        case .abcTabKeyFlick:
            return "「abc」キーのフリック割り当て"
        case .hiraTabKeyFlick:
            return "「あいう」キーのフリック割り当て"
        case .learningType:
            return "学習の使用"
        case .stopLearningWhenSearch:
            return "検索時は学習を停止"
        case .unicodeCandidate:
            return "unicode変換"
        case .englishCandidate:
            return "日本語入力中の英単語変換"
        case .wesJapCalender:
            return "西暦⇄和暦変換"
        case .typographyLetter:
            return "装飾英字変換"
        case .halfKana:
            return "半角カナ変換"
        case .fullRoman:
            return "全角英数字変換"
        case .memoryReset:
            return "学習のリセット"
        case .enableSound:
            return "キー音のON/OFF"
        case .resultViewFontSize:
            return "変換候補の表示サイズ"
        case .keyViewFontSize:
            return "キーの表示サイズ"
        case .displayTabBarButton:
            return "タブバーボタン" // TODO: ローカライズ
        case .useOSuserDict:
            return "OSのユーザ辞書の利用"
        }
    }

    var explanation: LocalizedStringKey {
        switch self {
        case .japaneseKeyboardLayout:
            return "日本語の入力方法をフリック入力とローマ字入力から選択できます。"
        case .englishKeyboardLayout:
            return "英語の入力方法をフリック入力とローマ字入力から選択できます。"
        case .preferredLanguage:
            return "キーボード上で入力する言語を選択できます。"

        case .numberTabCustomKeys:
            return "数字タブの「、。！？…」部分に好きな記号や文字を割り当てて利用することができます。"

        // flick layoutのカスタムキー
        case .koganaKeyFlick:
            return "「小ﾞﾟ」キーの「左」「上」「右」フリックに、好きな文字列を割り当てて利用することができます。"
        case .kanaSymbolsKeyFlick:
            return "「､｡?!」キーの「左」「上」「右」フリックに割り当てられた文字を変更することができます。"
        case .symbolsTabKeyFlick:
            return "「☆123」キーの「上」「右」「下」フリックに、好きな操作を割り当てて利用することができます。"
        case .abcTabKeyFlick:
            return "「abc」キーの「上」「右」「下」フリックに、好きな操作を割り当てて利用することができます。"
        case .hiraTabKeyFlick:
            return "「あいう」キーの「上」「右」「下」フリックに、好きな操作を割り当てて利用することができます。"

        case .learningType:
            return "「新たに学習し、反映する(デフォルト)」「新たな学習を停止する」「新たに学習せず、これまでの学習も反映しない」選択できます。この設定の変更で学習結果が消えることはありません。"
        case .stopLearningWhenSearch:
            return "web検索などで入力した単語を学習しません。"
        case .unicodeCandidate:
            return "「u3042→あ」のように、入力されたunicode番号に対応する文字に変換します。接頭辞にはu, u+, U, U+が使えます。"
        case .englishCandidate:
            return "「いんてれsちんg」→「interesting」のように、ローマ字日本語入力中も英語への変換候補を表示します。"
        case .wesJapCalender:
            return "「2020ねん→令和2年」「れいわ2ねん→2020年」のように西暦と和暦を相互に変換して候補に表示します。"
        case .typographyLetter:
            return "英字入力をした際、「𝕥𝕪𝕡𝕠𝕘𝕣𝕒𝕡𝕙𝕪」のような装飾字体を候補に表示します。"
        case .halfKana:
            return "半角ｶﾀｶﾅへの変換を候補に表示します。"
        case .fullRoman:
            return "全角英数字(ａｂｃ１２３)への変換候補を表示します。"
        case .memoryReset:
            return "学習履歴を全て消去します。この操作は取り消せません。"
        case .enableSound:
            return "キーを押した際に音を鳴らします。"
        case .resultViewFontSize:
            return "変換候補の文字の大きさを指定できます。"
        case .keyViewFontSize:
            return "キーの文字の大きさを指定できます。文字が大きすぎる場合表示が崩れることがあります。"
        case .displayTabBarButton:
            return "変換候補欄が空のときにタブバーボタンを表示します" // TODO: ローカライズ
        case .useOSuserDict:
            return "iOS標準のユーザ辞書を利用します。"
        }
    }
}

enum DefaultSetting {
    static func bool(_ setting: Setting) -> Bool? {
        switch setting {
        case .wesJapCalender, .typographyLetter, .halfKana, .fullRoman, .unicodeCandidate, .englishCandidate, .displayTabBarButton:
            return true
        case .stopLearningWhenSearch, .enableSound, .useOSuserDict:
            return false
        default:
            return nil
        }
    }

    static func double(_ setting: Setting) -> Double? {
        switch setting {
        case .resultViewFontSize, .keyViewFontSize:
            return -1
        default: return nil
        }
    }

    static func flickCustomKey(_ setting: Setting) -> KeyFlickSetting? {
        switch setting {
        case .koganaKeyFlick:
            return CustomizableFlickKey.kogana.defaultSetting
        case .kanaSymbolsKeyFlick:
            return CustomizableFlickKey.kanaSymbols.defaultSetting
        case .hiraTabKeyFlick:
            return CustomizableFlickKey.hiraTab.defaultSetting
        case .abcTabKeyFlick:
            return CustomizableFlickKey.abcTab.defaultSetting
        case .symbolsTabKeyFlick:
            return CustomizableFlickKey.symbolsTab.defaultSetting
        default:
            return nil
        }
    }

    static func qwertyCustomKeys(_ setting: Setting) -> QwertyCustomKeysValue? {
        switch setting {
        case .numberTabCustomKeys:
            return QwertyCustomKeysValue.defaultValue
        default:
            return nil
        }
    }

    static let japaneseKeyboardLayout = KeyboardLayout.flick
    static let englishKeyboardLayout = KeyboardLayout.flick

    static let preferredLanguage = PreferredLanguage(first: .ja_JP, second: .en_US)

    static let memorySetting = LearningType.inputAndOutput
}
