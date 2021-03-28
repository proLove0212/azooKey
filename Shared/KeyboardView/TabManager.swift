//
//  TabManager.swift
//  KanaKanjier
//
//  Created by β α on 2021/02/20.
//  Copyright © 2021 DevEn3. All rights reserved.
//

import Foundation
import SwiftUI

extension Custard: Equatable {
    public static func == (lhs: Custard, rhs: Custard) -> Bool {
        return lhs.identifier == rhs.identifier
    }
}

enum Tab: Equatable {
    case existential(ExistentialTab)
    case user_dependent(UserDependentTab)
    case last_tab

    enum ExistentialTab: Equatable {
        case flick_hira
        case flick_abc
        case flick_numbersymbols
        case qwerty_hira
        case qwerty_abc
        case qwerty_number
        case qwerty_symbols
        case custard(Custard)

        var inputStyle: InputStyle {
            switch self{
            case .qwerty_hira:
                return .roman2kana
            case let .custard(custard):
                switch custard.input_style{
                case .direct:
                    return .direct
                case .roman2kana:
                    return .roman2kana
                }
            default:
                return .direct
            }
        }

        var layout: KeyboardLayout {
            switch self{
            case .flick_hira, .flick_abc, .flick_numbersymbols:
                return .flick
            case .qwerty_hira, .qwerty_abc, .qwerty_number, .qwerty_symbols:
                return .qwerty
            case let .custard(custard):
                switch custard.interface.keyStyle{
                case .tenkeyStyle:
                    return .flick
                case .pcStyle:
                    return .qwerty
                }
            }
        }

        var language: KeyboardLanguage? {
            switch self{
            case .flick_abc, .qwerty_abc:
                return .en_US
            case .flick_hira, .qwerty_hira:
                return .ja_JP
            case let .custard(custard):
                switch custard.language{
                case .ja_JP:
                    return .ja_JP
                case .en_US:
                    return .en_US
                case .el_GR:
                    return .el_GR
                case .undefined:
                    return nil
                case .none:
                    return KeyboardLanguage.none
                }
            case .flick_numbersymbols, .qwerty_number, .qwerty_symbols:
                return nil
            }
        }
    }

    enum UserDependentTab: Equatable {
        case japanese
        case english

        var actualTab: ExistentialTab {
            //ユーザの設定に合わせて遷移先のタブ(非user_dependent)を返す
            switch self{
            case .english:
                switch SettingData.shared.languageLayout(for: .englishKeyboardLayout){
                case .flick:
                    return .flick_abc
                case .qwerty:
                    return .qwerty_abc
                case let .custard(identifier):
                    return .custard((try? CustardManager.load().custard(identifier: identifier)) ?? .errorMessage)
                }
            case .japanese:
                switch SettingData.shared.languageLayout(for: .japaneseKeyboardLayout){
                case .flick:
                    return .flick_hira
                case .qwerty:
                    return .qwerty_hira
                case let .custard(identifier):
                    return .custard((try? CustardManager.load().custard(identifier: identifier)) ?? .errorMessage)
                }
            }
        }
    }

    var inputStyle: InputStyle {
        switch self{
        case let .existential(tab):
            return tab.inputStyle
        case let .user_dependent(tab):
            let actualTab = tab.actualTab
            return actualTab.inputStyle
        case .last_tab:
            fatalError()
        }
    }

    var layout: KeyboardLayout {
        switch self{
        case let .existential(tab):
            return tab.layout
        case let .user_dependent(tab):
            let actualTab = tab.actualTab
            return actualTab.layout
        case .last_tab:
            fatalError()
        }
    }

    var language: KeyboardLanguage? {
        switch self{
        case let .existential(tab):
            return tab.language
        case let .user_dependent(tab):
            let actualTab = tab.actualTab
            return actualTab.language
        case .last_tab:
            fatalError()
        }
    }
}

extension TabData{
    var tab: Tab {
        switch self{
        case let .system(tab):
            switch tab{
            case .flick_japanese:
                return .existential(.flick_hira)
            case .flick_english:
                return .existential(.flick_abc)
            case .flick_numbersymbols:
                return .existential(.flick_numbersymbols)
            case .qwerty_japanese:
                return .existential(.qwerty_hira)
            case .qwerty_english:
                return .existential(.qwerty_abc)
            case .qwerty_numbers:
                return .existential(.qwerty_number)
            case .qwerty_symbols:
                return .existential(.qwerty_symbols)
            case .user_japanese:
                return .user_dependent(.japanese)
            case .user_english:
                return .user_dependent(.english)
            case .last_tab:
                return .last_tab
            }
        case let .custom(identifier):
            if let custard = try? CustardManager.load().custard(identifier: identifier){
                return .existential(.custard(custard))
            }else{
                return .existential(.custard(.errorMessage))
            }
        }
    }
}

struct TabManager{
    private(set) var currentTab: ManagerTab = .user_dependent(.japanese)
    private(set) var lastTab: ManagerTab? = nil

    enum ManagerTab{
        case existential(Tab.ExistentialTab)
        case user_dependent(Tab.UserDependentTab)

        var existential: Tab.ExistentialTab {
            switch self{
            case let .existential(tab):
                return tab
            case let .user_dependent(tab):
                return tab.actualTab
            }
        }
    }

    func isCurrentTab(tab: Tab) -> Bool {
        switch tab{
        case let .existential(actualTab):
            return currentTab.existential == actualTab
        case let .user_dependent(type):
            return type.actualTab == currentTab.existential
        case .last_tab:
            return false
        }
    }

    mutating func initialize(){
        switch lastTab{
        case .none:
            let targetTab: Tab = {
                switch SettingData.shared.preferredLanguageSetting.first{
                case .en_US:
                    return .user_dependent(.english)
                case .ja_JP:
                    return .user_dependent(.japanese)
                case .none, .el_GR:
                    return .user_dependent(.japanese)
                }
            }()
            self.moveTab(to: targetTab)
        case let .existential(tab):
            self.moveTab(to: tab)
        case let .user_dependent(tab):
            self.moveTab(to: .user_dependent(tab))
        }
    }

    mutating func closeKeyboard(){
        self.lastTab = self.currentTab
    }

    mutating private func moveTab(to destination: Tab.ExistentialTab){
        //VariableStateの状態を遷移先のタブに合わせて適切に変更する
        VariableStates.shared.setKeyboardLayout(destination.layout)
        VariableStates.shared.setInputStyle(destination.inputStyle)
        if let language = destination.language{
            VariableStates.shared.keyboardLanguage = language
        }

        //selfの状態を更新する
        self.lastTab = self.currentTab
        self.currentTab = .existential(destination)
    }

    mutating func moveTab(to destination: Tab){
        //適切なタブを取得する
        let actualTab: Tab.ExistentialTab
        switch destination{
        case let .existential(tab):
            actualTab = tab
        case let .user_dependent(tab):
            actualTab = tab.actualTab
        case .last_tab:
            guard let lastTab = self.lastTab else{
                return
            }
            actualTab = lastTab.existential
        }

        //VariableStateの状態を遷移先のタブに合わせて適切に変更する
        VariableStates.shared.setKeyboardLayout(actualTab.layout)
        VariableStates.shared.setInputStyle(actualTab.inputStyle)
        if let language = actualTab.language{
            VariableStates.shared.keyboardLanguage = language
        }

        //selfの状態を更新する
        switch destination{
        case let .existential(tab):
            self.lastTab = self.currentTab
            self.currentTab = .existential(tab)
        case let .user_dependent(tab):
            self.lastTab = self.currentTab
            self.currentTab = .user_dependent(tab)
        case .last_tab:
            if let lasttab = self.lastTab{
                self.currentTab = lasttab
            }
            self.lastTab = nil
        }
    }
}
