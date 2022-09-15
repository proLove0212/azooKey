//
//  IntKeyboardSetting.swift
//  KanaKanjier
//
//  Created by β α on 2022/09/15.
//  Copyright © 2022 DevEn3. All rights reserved.
//

import Foundation
import SwiftUI

struct AutomaticCompletionStrengthKey: KeyboardSettingKey, StoredInUserDefault {
    enum Value: Int {
        case disabled  // 無効化
        case weak      // 弱い
        case normal    // 普通
        case strong    // 強い
        case ultrastrong  // 非常に強い

        var treshold: Int {
            switch self {
            case .disabled: return .max
            case .weak: return 16
            case .normal: return 13
            case .strong: return 10
            case .ultrastrong: return 6
            }
        }
    }
    static let title: LocalizedStringKey = "自動確定の速さ"
    static let explanation: LocalizedStringKey = "自動確定を使うと長い文章を打っているときに候補の選択がしやすくなります。"
    static let defaultValue: Value = Value.normal
    static let key: String = "automatic_completion_strength"

    static func get() -> Value? {
        let object = SharedStore.userDefaults.object(forKey: key)
        if let object, let value = object as? Int {
            return Value(rawValue: value)
        }
        return nil
    }
    static func set(newValue: Value) {
        SharedStore.userDefaults.set(newValue.rawValue, forKey: key)
    }

    static var value: Value {
        get {
            get() ?? defaultValue
        }
        set {
            set(newValue: newValue)
        }
    }
}

extension KeyboardSettingKey where Self == AutomaticCompletionStrengthKey {
    static var automaticCompletionStrength: Self { .init() }
}
