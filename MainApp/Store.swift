//
//  Store.swift
//  MainApp
//
//  Created by ensan on 2020/09/16.
//  Copyright © 2020 ensan. All rights reserved.
//

import Foundation
import SwiftUI

final class Store {
    static let shared = Store()
    static var variableSection = StoreVariableSection()
    var feedbackGenerator = UINotificationFeedbackGenerator()
    var messageManager = MessageManager()

    init() {
        SemiStaticStates.shared.setNeedsInputModeSwitchKeyMode(DeviceName.shared.needsInputSwitchKey())
        // ユーザ辞書に登録がない場合など
        self.messageManager.getMessagesContainerAppShouldMakeWhichDone().forEach {
            messageManager.done($0.id)
        }
        SharedStore.setInitialAppVersion()
        SharedStore.setLastAppVersion()
    }

    func noticeReloadUserDict() {
        SharedStore.userDefaults.set(true, forKey: "reloadUserDict")
    }

    var isKeyboardActivated: Bool {
        let bundleName = SharedStore.bundleName
        guard let keyboards = UserDefaults.standard.dictionaryRepresentation()["AppleKeyboards"] as? [String] else {
            return true
        }
        return keyboards.contains(bundleName)
    }

    let imageMaximumWidth: CGFloat = 500

    var shouldTryRequestReview: Bool = false

    func shouldRequestReview() -> Bool {
        self.shouldTryRequestReview = false
        if let lastDate = UserDefaults.standard.value(forKey: "last_reviewed_date") as? Date {
            if -lastDate.timeIntervalSinceNow < 10000000 {   // 約3ヶ月半経過していたら
                return false
            }
        }

        let rand = Int.random(in: 0...4)

        if rand == 0 {
            UserDefaults.standard.set(Date(), forKey: "last_reviewed_date")
            return true
        }
        return false
    }

    func showCustardImportView(url: URL) {
        Self.variableSection.importFile = url
    }
}

final class StoreVariableSection: ObservableObject {
    @Published var isKeyboardActivated: Bool = Store.shared.isKeyboardActivated
    @Published var requireFirstOpenView: Bool = !Store.shared.isKeyboardActivated
    @Published var japaneseLayout: LanguageLayout = .flick
    @Published var englishLayout: LanguageLayout = .flick
    @Published var importFile: URL?

    init() {
        @KeyboardSetting(.japaneseKeyboardLayout) var japaneseKeyboardLayout
        self.japaneseLayout = japaneseKeyboardLayout
        @KeyboardSetting(.englishKeyboardLayout) var englishKeyboardLayout
        self.englishLayout = englishKeyboardLayout
    }
}
