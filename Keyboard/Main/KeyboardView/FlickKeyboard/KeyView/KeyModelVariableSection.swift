//
//  KeyModelVariableSection.swift
//  Keyboard
//
//  Created by β α on 2020/04/12.
//  Copyright © 2020 DevEn3. All rights reserved.
//

import Foundation
import SwiftUI

final class KeyModelVariableSection: ObservableObject{
    @Published var keyboardState: TabState = .hira
    @Published var enterKeyState: EnterKeyState = .return(.default)
    @Published var aAKeyState: AaKeyState = .normal
    @Published var suggestState: SuggestState = .nothing
    @Published var pressState: KeyPressState = .inactive
}
