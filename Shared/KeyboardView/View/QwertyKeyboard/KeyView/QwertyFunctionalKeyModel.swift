//
//  QwertyFunctionalKeyModel.swift
//  Keyboard
//
//  Created by β α on 2020/09/18.
//  Copyright © 2020 DevEn3. All rights reserved.
//

import Foundation
import SwiftUI

struct QwertyFunctionalKeyModel: QwertyKeyModelProtocol{
    static var delete = QwertyFunctionalKeyModel(labelType: .image("delete.left"), rowInfo: (normal: 7, functional: 2, space: 0, enter: 0), pressActions: [.delete(1)], longPressActions: [.repeat(.delete(1))])

    
    let pressActions: [ActionType]
    var longPressActions: [KeyLongPressActionType]
    ///暫定
    let variationsModel = VariationsModel([])

    let labelType: KeyLabelType
    let needSuggestView: Bool
    let keySizeType: QwertyKeySizeType
    let unpressedKeyColorType: QwertyUnpressedKeyColorType = .special

    init(labelType: KeyLabelType, rowInfo: (normal: Int, functional: Int, space: Int, enter: Int), pressActions: [ActionType], longPressActions: [KeyLongPressActionType] = [], needSuggestView: Bool = false){
        self.labelType = labelType
        self.pressActions = pressActions
        self.longPressActions = longPressActions
        self.needSuggestView = needSuggestView
        self.keySizeType = .functional(normal: rowInfo.normal, functional: rowInfo.functional, enter: rowInfo.enter, space: rowInfo.space)
    }

    func label(width: CGFloat, states: VariableStates, color: Color?) -> KeyLabel {
        KeyLabel(self.labelType, width: width, textColor: color)
    }

    func sound() {
        self.pressActions.first?.sound()
    }

}
