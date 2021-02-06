//
//  QwertyKeyModelProtocol.swift
//  Keyboard
//
//  Created by β α on 2020/09/18.
//  Copyright © 2020 DevEn3. All rights reserved.
//

import Foundation
import SwiftUI

protocol QwertyKeyModelProtocol{
    var pressActions: [ActionType] {get}
    var longPressActions: [KeyLongPressActionType] {get}
    var keySize: CGSize {get}
    var needSuggestView: Bool {get}
    
    var variableSection: QwertyKeyModelVariableSection {get set}
    
    var variationsModel: VariationsModel {get}

    func label(states: VariableStates) -> KeyLabel
    func backGroundColorWhenPressed(states: VariableStates) -> Color
    func backGroundColorWhenUnpressed(states: VariableStates) -> Color

    func press()
    func longPressReserve()
    func longPressEnd()
    
    func sound()
}


extension QwertyKeyModelProtocol{
    func press(){
        self.pressActions.forEach{Store.shared.action.registerAction($0)}
    }
    
    func longPressReserve(){
        self.longPressActions.forEach{Store.shared.action.reserveLongPressAction($0)}
    }
    
    func longPressEnd(){
        self.longPressActions.forEach{Store.shared.action.registerLongPressActionEnd($0)}
    }
        
    func backGroundColorWhenPressed(states: VariableStates) -> Color {
        Design.shared.colors.highlightedKeyColor
    }
    func backGroundColorWhenUnpressed(states: VariableStates) -> Color {
        Design.shared.colors.normalKeyColor
    }
}