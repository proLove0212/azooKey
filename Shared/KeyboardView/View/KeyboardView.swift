//
//  KeyboardView.swift
//  Calculator-Keyboard
//
//  Created by β α on 2020/04/08.
//  Copyright © 2020 DevEn3. All rights reserved.
//

import Foundation
import SwiftUI

struct ThemeEnvironmentKey: EnvironmentKey {
    typealias Value = ThemeData

    static var defaultValue: ThemeData = .default
}

extension EnvironmentValues {
    var themeEnvironment: ThemeData {
        get {
            return self[ThemeEnvironmentKey.self]
        }
        set {
            self[ThemeEnvironmentKey.self] = newValue
        }
    }
}

struct MessageEnvironmentKey: EnvironmentKey {
    typealias Value = Bool

    static var defaultValue = true
}

extension EnvironmentValues {
    var showMessage: Bool {
        get {
            return self[MessageEnvironmentKey.self]
        }
        set {
            self[MessageEnvironmentKey.self] = newValue
        }
    }
}

struct KeyboardView<Candidate: ResultViewItemData>: View {
    @ObservedObject private var variableStates = VariableStates.shared
    @State private var resultData: [ResultData<Candidate>] = []

    private unowned let resultModelVariableSection: ResultModelVariableSection<Candidate>

    @State private var messageManager: MessageManager = MessageManager()
    @State private var isResultViewExpanded = false

    @Environment(\.themeEnvironment) private var theme
    @Environment(\.showMessage) private var showMessage

    private let defaultTab: Tab.ExistentialTab?

    init(resultModelVariableSection: ResultModelVariableSection<Candidate>, defaultTab: Tab.ExistentialTab? = nil) {
        self.resultModelVariableSection = resultModelVariableSection
        self.defaultTab = defaultTab
    }

    var body: some View {
        ZStack { [unowned variableStates] in
            theme.backgroundColor.color
                .frame(maxWidth: .infinity)
                .overlay(
                    Group {
                        if let image = theme.picture.image {
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: SemiStaticStates.shared.screenWidth, height: Design.keyboardScreenHeight)
                                .clipped()
                        }
                    }
                )
            Group {
                if isResultViewExpanded {
                    ExpandedResultView(isResultViewExpanded: $isResultViewExpanded, resultData: resultData)
                } else {
                    VStack(spacing: 0) {
                        ResultView(model: resultModelVariableSection, isResultViewExpanded: $isResultViewExpanded, resultData: $resultData)
                            .padding(.vertical, 6)
                        if variableStates.refreshing {
                            keyboardView(tab: variableStates.tabManager.tab.existential)
                        } else {
                            keyboardView(tab: variableStates.tabManager.tab.existential)
                        }
                    }
                }
            }
            .resizingFrame(
                size: $variableStates.interfaceSize,
                position: $variableStates.interfacePosition,
                initialSize: CGSize(width: SemiStaticStates.shared.screenWidth, height: SemiStaticStates.shared.screenHeight)
            )
            .padding(.bottom, 2)
            if variableStates.boolStates.isTextMagnifying {
                LargeTextView(text: variableStates.magnifyingText, isViewOpen: $variableStates.boolStates.isTextMagnifying)
            }
            if showMessage {
                ForEach(messageManager.necessaryMessages, id: \.id) {data in
                    if messageManager.requireShow(data.id) {
                        MessageView(data: data, manager: $messageManager)
                    }
                }
            }
        }
        .frame(height: Design.keyboardScreenHeight)
    }

    func keyboardView(tab: Tab.ExistentialTab) -> some View {
        let target: Tab.ExistentialTab
        if let defaultTab {
            target = defaultTab
        } else {
            target = tab
        }

        return Group {
            switch target {
            case .flick_hira:
                FlickKeyboardView(keyModels: FlickDataProvider().hiraKeyboard)
            case .flick_abc:
                FlickKeyboardView(keyModels: FlickDataProvider().abcKeyboard)
            case .flick_numbersymbols:
                FlickKeyboardView(keyModels: FlickDataProvider().numberKeyboard)
            case .qwerty_hira:
                QwertyKeyboardView(keyModels: QwertyDataProvider().hiraKeyboard)
            case .qwerty_abc:
                QwertyKeyboardView(keyModels: QwertyDataProvider().abcKeyboard)
            case .qwerty_number:
                QwertyKeyboardView(keyModels: QwertyDataProvider().numberKeyboard)
            case .qwerty_symbols:
                QwertyKeyboardView(keyModels: QwertyDataProvider().symbolsKeyboard)
            case let .custard(custard):
                CustomKeyboardView(custard: custard)
            }
        }
    }
}
