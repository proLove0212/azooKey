//
//  VariableStates.swift
//  Keyboard
//
//  Created by β α on 2021/02/06.
//  Copyright © 2021 DevEn3. All rights reserved.
//

import Foundation
import SwiftUI

///実行中変更され、かつViewが変更を検知できるべき値。
final class VariableStates: ObservableObject{
    var action: ActionDepartment = ActionDepartment()
    static let shared = VariableStates()
    private(set) var inputStyle: InputStyle = .direct
    var tabManager = TabManager()

    private init(){}

    @Published var keyboardLanguage: KeyboardLanguage = .ja_JP
    @Published var keyboardOrientation: KeyboardOrientation = .vertical
    @Published var keyboardLayout: KeyboardLayout = .flick

    @Published var interfaceSize: CGSize = .zero
    @Published var aAKeyState: AaKeyState = .normal
    @Published var enterKeyType: UIReturnKeyType = .default
    @Published var enterKeyState: EnterKeyState = .return(.default)

    @Published var isTextMagnifying = false
    @Published var magnifyingText = ""

    @Published var showMoveCursorBar = false
    @Published var showTabBar = false

    @Published var refreshing = true

    @Published var enableResizing = false

    func initialize(){
        self.tabManager.initialize()
        self.refreshView()
    }

    func closeKeybaord(){
        self.tabManager.closeKeyboard()
    }

    func refreshView(){
        refreshing.toggle()
    }

    enum RoughEnterKeyState{
        case `return`
        case edit
        case complete
    }

    func setEnterKeyState(_ state: RoughEnterKeyState){
        switch state{
        case .return:
            self.enterKeyState = .return(enterKeyType)
        case .edit:
            self.enterKeyState = .edit
        case .complete:
            self.enterKeyState = .complete
        }
    }

    func setTab(_ tab: Tab){
        self.tabManager.moveTab(to: tab)
        self.refreshView()
    }

    func setUIReturnKeyType(type: UIReturnKeyType){
        self.enterKeyType = type
        if case let .return(prev) = self.enterKeyState, prev != type{
            self.setEnterKeyState(.return)
        }
    }

    func setInputStyle(_ style: InputStyle){
        self.action.changeInputStyle(from: self.inputStyle, to: style)
        self.inputStyle = style
    }

    ///workarounds
    ///* 1回目に値を保存してしまう
    ///* if bool {} else{}にしてboolをvariableSectionに持たせてtoggleする。←これを採用した。
    func setOrientation(_ orientation: KeyboardOrientation){
        if self.keyboardOrientation == orientation{
            self.refreshView()
            return
        }
        self.keyboardOrientation = orientation
    }

}

