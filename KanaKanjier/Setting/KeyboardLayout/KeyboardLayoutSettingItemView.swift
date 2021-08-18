//
//  LanguageLayoutSettingView.swift
//  KanaKanjier
//
//  Created by β α on 2020/11/09.
//  Copyright © 2020 DevEn3. All rights reserved.
//

import SwiftUI

extension LanguageLayout {
    var label: LocalizedStringKey {
        switch self {
        case .flick:
            return "フリック入力"
        case .qwerty:
            return "ローマ字入力"
        case let .custard(identifier):
            return LocalizedStringKey(identifier)
        }
    }
}

struct LanguageLayoutSettingView<SettingKey: LanguageLayoutKeyboardSetting>: View {
    @State private var selection: LanguageLayout = .flick
    @State private var ignoreChange = false
    private let custardManager = CustardManager.load()
    private let language: Language
    private let setTogether: Bool

    enum Language {
        case japanese
        case english

        var name: LocalizedStringKey {
            switch self {
            case .japanese:
                return "日本語"
            case .english:
                return "英語"
            }
        }
    }

    init(_ key: SettingKey, language: Language = .japanese, setTogether: Bool = false) {
        self.language = language
        self.setTogether = setTogether
        self._selection = State(initialValue: SettingKey.value)
        self.types = {
            let keyboardlanguage: KeyboardLanguage
            switch language {
            case .japanese:
                keyboardlanguage = .ja_JP
            case .english:
                keyboardlanguage = .en_US
            }
            return [.flick, .qwerty] + CustardManager.load().availableCustard(for: keyboardlanguage).map {.custard($0)}
        }()
    }

    private let types: [LanguageLayout]

    private var labelText: LocalizedStringKey {
        if setTogether {
            return "キーボードの種類(現在: \(selection.label))"
        } else {
            return "\(language.name)キーボードの種類(現在: \(selection.label))"
        }
    }

    private var tab: Tab.ExistentialTab {
        switch (selection, language) {
        case (.flick, .japanese):
            return .flick_hira
        case (.flick, .english):
            return .flick_abc
        case (.qwerty, .japanese):
            return .qwerty_hira
        case (.qwerty, .english):
            return .qwerty_abc
        case let (.custard(identifier), _):
            if let custard = try? custardManager.custard(identifier: identifier) {
                return .custard(custard)
            } else {
                return .custard(.errorMessage)
            }
        }
    }

    var body: some View {
        VStack {
            Text(labelText)
            CenterAlignedView {
                KeyboardPreview(theme: .default, scale: 0.8, defaultTab: tab)
                    .allowsHitTesting(false)
                    .disabled(true)
            }
            Picker(selection: $selection, label: Text(labelText)) {
                ForEach(0 ..< types.count) { i in
                    Text(types[i].label).tag(types[i])
                }
            }
            .labelsHidden()
            .pickerStyle(.segmented)
        }
        .onChange(of: selection) { _ in
            if ignoreChange {
                return
            }
            let type = selection
            SettingKey.value = type
            switch language {
            case .japanese:
                Store.variableSection.japaneseLayout = type
            case .english:
                Store.variableSection.englishLayout = type
            }
            if setTogether {
                EnglishKeyboardLayout.value = type
                Store.variableSection.englishLayout = type
            }
        }
        .onAppear {
            self.ignoreChange = true
            self.selection = SettingKey.value
            self.ignoreChange = false
        }
        .onDisappear {
            self.ignoreChange = true
        }
    }
}
