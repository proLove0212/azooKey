//
//  ContentView.swift
//  KanaKanjier
//
//  Created by β α on 2020/09/03.
//  Copyright © 2020 DevEn3. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @State private var selection = 0
    @ObservedObject private var storeVariableSection = Store.variableSection
    @State private var isPresented = true

    @State private var messageManager = MessageManager()
    @State private var showWalkthrough = false

    var body: some View {
        ZStack {
            TabView(selection: $selection) {
                TipsTabView()
                    .tabItem {
                        VStack {
                            Image(systemName: "lightbulb.fill").font(.system(size: 20, weight: .light))
                                .foregroundColor(.systemGray2)
                            Text("使い方")
                        }
                    }
                    .tag(0)
                ThemeTabView()
                    .tabItem {
                        VStack {
                            Image(systemName: "photo").font(.system(size: 20, weight: .light))
                                .foregroundColor(.systemGray2)
                            Text("着せ替え")
                        }
                    }
                    .tag(1)
                CustomizeTabView()
                    .tabItem {
                        VStack {
                            Image(systemName: "gearshape.2.fill").font(.system(size: 20, weight: .light))
                                .foregroundColor(.systemGray2)
                            Text("拡張")
                        }
                    }
                    .tag(2)
                SettingTabView()
                    .tabItem {
                        VStack {
                            Image(systemName: "wrench.fill").font(.system(size: 20, weight: .light))
                                .foregroundColor(.systemGray2)
                            Text("設定")
                        }
                    }
                    .tag(3)
            }
            .fullScreenCover(isPresented: $storeVariableSection.requireFirstOpenView) {
                EnableAzooKeyView()
            }
            .onChange(of: selection) {value in
                if value == 2 {
                    if ContainerInternalSetting.shared.walkthroughState.shouldDisplay(identifier: .extensions) {
                        self.showWalkthrough = true
                    }
                }
            }
            .onChange(of: storeVariableSection.importFile) { value in
                if value != nil {
                    selection = 2
                }
            }
            BottomSheetView(isOpen: $showWalkthrough, maxHeight: UIScreen.main.bounds.height * 0.9, minHeight: 0, headerColor: .background) {
                CustomizeTabWalkthroughView(isShowing: $showWalkthrough)
                    .background(Color.background)
            }
            ForEach(messageManager.necessaryMessages, id: \.id) {data in
                if messageManager.requireShow(data.id) {
                    switch data.id {
                    case .mock:
                        EmptyView()
                    case .ver1_5_update_loudstxt:
                        // ユーザ辞書を更新する
                        DataUpdateView(id: data.id, manager: $messageManager) {
                            let builder = LOUDSBuilder(txtFileSplit: 2048)
                            builder.process()
                            Store.shared.noticeReloadUserDict()
                        }
                    case .iOS14_5_new_emoji:
                        // 絵文字を更新する
                        DataUpdateView(id: data.id, manager: $messageManager) {
                            AdditionalDictManager().userDictUpdate()
                        }
                    }
                }
            }
        }
    }
}
