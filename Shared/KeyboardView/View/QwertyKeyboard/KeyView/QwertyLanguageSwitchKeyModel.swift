//
//  QwertyLanguageSwitchKeyModel.swift
//  KanaKanjier
//
//  Created by β α on 2021/03/06.
//  Copyright © 2021 DevEn3. All rights reserved.
//

import Foundation
import SwiftUI

//symbolタブ、123タブで表示される切り替えボタン
struct QwertySwitchLanguageKeyModel: QwertyKeyModelProtocol{
    let languages: (KeyboardLanguage, KeyboardLanguage)
    var currentTabLanguage: KeyboardLanguage? {
        VariableStates.shared.tabManager.currentTab.existential.language
    }

    var pressActions: [ActionType]{
        let target: KeyboardLanguage
        if languages.0 == currentTabLanguage{
            target = languages.1
        }else if languages.1 == currentTabLanguage{
            target = languages.0
        }else{
            target = VariableStates.shared.keyboardLanguage
        }
        switch target{
        case .ja_JP:
            return [.moveTab(.user_dependent(.japanese))]
        case .en_US:
            return [.moveTab(.user_dependent(.english))]
        case .none, .el_GR:
            return []

        }
    }
    let longPressActions: LongpressActionType = .none
    ///暫定
    let variationsModel = VariationsModel([])

    let needSuggestView: Bool = false

    let keySizeType: QwertyKeySizeType
    let unpressedKeyColorType: QwertyUnpressedKeyColorType = .special

    init(rowInfo: (normal: Int, functional: Int, space: Int, enter: Int), languages: (KeyboardLanguage, KeyboardLanguage)){
        self.keySizeType = .functional(normal: rowInfo.normal, functional: rowInfo.functional, enter: rowInfo.enter, space: rowInfo.space)
        self.languages = languages
    }

    func label(width: CGFloat, states: VariableStates, color: Color?) -> KeyLabel {
        if languages.0 == currentTabLanguage{
            return KeyLabel(.selectable(languages.0.symbol, languages.1.symbol), width: width, textColor: color)
        }else if languages.1 == currentTabLanguage{
            return KeyLabel(.selectable(languages.1.symbol, languages.0.symbol), width: width, textColor: color)
        }else{
            return KeyLabel(.text(VariableStates.shared.keyboardLanguage.symbol), width: width, textColor: color)
        }
    }

    func sound() {
        Sound.tabOrOtherKey()
    }
}