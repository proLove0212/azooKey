//
//  KeyboardView.swift
//  Calculator-Keyboard
//
//  Created by β α on 2020/04/08.
//  Copyright © 2020 DevEn3. All rights reserved.
//

import Foundation
import SwiftUI

//キーボードの状態管理
enum TabState: Equatable{
    case hira
    case abc
    case number
    case other(String)

    static func ==(lhs: TabState, rhs: TabState) -> Bool {
        switch (lhs, rhs) {
        case (.hira, .hira), (.abc, .abc), (.number, .number): return true
        case let (.other(ls), .other(rs)): return ls == rs
        default:
            return false
        }
    }
}

enum KeyboardLanguage{
    case english
    case japanese
}

//Storeからアクセス出来るべきデータ。
final class KeyboardModelVariableSection: ObservableObject{
    @Published var keyboardOrientation: KeyboardOrientation = .vertical
    @Published var isTextMagnifying = false
    @Published var magnifyingText = ""
    @Published var refreshing = true
    func refreshView(){
        refreshing.toggle()
    }
}

struct KeyboardModel {
    let resultModel = ResultModel()
    let variableSection: KeyboardModelVariableSection = KeyboardModelVariableSection()
}

struct KeyboardView: View {
    //二つ以上になったらまとめてvariableSectioinにすること！
    @ObservedObject private var modelVariableSection: KeyboardModelVariableSection
    private let model: KeyboardModel
    @State private var messageManager: MessageManager = MessageManager()
    @State private var isResultViewExpanded: Bool = false
    private var sharedResultData = SharedResultData()

    init(){
        self.model = Store.shared.keyboardViewModel
        self.modelVariableSection = self.model.variableSection
    }

    var body: some View {
        ZStack{[unowned modelVariableSection] in
            Design.shared.colors.backGroundColor
                .frame(maxWidth: .infinity)
                .overlay(
                    Group{
                        if let name = Design.shared.themeManager.theme.pictureFileName{
                            Image(name)
                                .resizable()
                                .scaledToFill()
                                .frame(width: Design.shared.screenWidth)
                                .clipped()
                        }
                    }
                )
            if isResultViewExpanded{
                ExpandedResultView(isResultViewExpanded: $isResultViewExpanded, sharedResultData: sharedResultData)
                    .padding(.bottom, 2)
            }else{
                VStack(spacing: 0){
                    ResultView(model: model.resultModel, isResultViewExpanded: $isResultViewExpanded, sharedResultData: sharedResultData)
                        .padding(.vertical, 6)
                    if modelVariableSection.refreshing{
                        switch (modelVariableSection.keyboardOrientation, Design.shared.layout){
                        case (.vertical, .flick):
                            VerticalFlickKeyboardView(Store.shared.keyboardModel as! VerticalFlickKeyboardModel)
                        case (.vertical, .qwerty):
                            VerticalQwertyKeyboardView(Store.shared.keyboardModel as! VerticalQwertyKeyboardModel)
                        case (.horizontal, .flick):
                            HorizontalKeyboardView(Store.shared.keyboardModel as! HorizontalFlickKeyboardModel)
                        case (.horizontal, .qwerty):
                            HorizontalQwertyKeyboardView(Store.shared.keyboardModel as! HorizontalQwertyKeyboardModel)
                        }
                    }else{
                        switch (modelVariableSection.keyboardOrientation, Design.shared.layout){
                        case (.vertical, .flick):
                            VerticalFlickKeyboardView(Store.shared.keyboardModel as! VerticalFlickKeyboardModel)
                        case (.vertical, .qwerty):
                            VerticalQwertyKeyboardView(Store.shared.keyboardModel as! VerticalQwertyKeyboardModel)
                        case (.horizontal, .flick):
                            HorizontalKeyboardView(Store.shared.keyboardModel as! HorizontalFlickKeyboardModel)
                        case (.horizontal, .qwerty):
                            HorizontalQwertyKeyboardView(Store.shared.keyboardModel as! HorizontalQwertyKeyboardModel)
                        }
                    }
                }.padding(.bottom, 2)
            }
            if modelVariableSection.isTextMagnifying{
                LargeTextView(modelVariableSection.magnifyingText, isTextMagnifying: $modelVariableSection.isTextMagnifying)
            }
            
            ForEach(messageManager.necessaryMessages, id: \.id){data in
                if messageManager.requireShow(data.id){
                    MessageView(data: data, manager: $messageManager)
                }
            }
        }
    }
}
