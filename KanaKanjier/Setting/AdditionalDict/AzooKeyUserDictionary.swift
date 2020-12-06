//
//  AzooKeyUserDictionary.swift
//  KanaKanjier
//
//  Created by β α on 2020/12/05.
//  Copyright © 2020 DevEn3. All rights reserved.
//

import SwiftUI
import Foundation

final class EditableUserDictionaryData: ObservableObject {
    lazy var availableChars: [Character] = {
        do{
            let string = try String(contentsOfFile: Bundle.main.bundlePath + "/charID.chid", encoding: String.Encoding.utf8)

            return Array(string).filter{!["\t",","," ","\0"].contains($0)}
        }catch{
            return []
        }
    }()

    @Published var ruby: String
    @Published var word: String
    @Published var isVerb: Bool
    @Published var isPersonName: Bool
    @Published var isPlaceName: Bool

    let id: Int

    init(ruby: String, word: String, isVerb: Bool, isPersonName: Bool, isPlaceName: Bool, id: Int){
        self.ruby = ruby
        self.word = word
        self.id = id
        self.isVerb = isVerb
        self.isPersonName = isPersonName
        self.isPlaceName = isPlaceName
    }

    func neadVerbCheck() -> Bool {
        return self.ruby.last == "る" && ["る", "ル"].contains(self.word.last)
    }

    var mizenkeiRuby: String {
        self.ruby.dropLast() + "らない"
    }

    var mizenkeiWord: String {
        self.word.dropLast() + "らない"
    }

    enum AppendError{
        case rubyEmpty
        case wordEmpty
        case unavailableCharacter

        var message: String {
            switch self{
            case .rubyEmpty:
                return "読みが空です"
            case .wordEmpty:
                return "単語が空です"
            case .unavailableCharacter:
                return "読みに使用できない文字が含まれます。ひらがな、英字、数字を指定してください"
            }
        }

    }

    var error: AppendError? {
        if ruby.isEmpty{
            return .rubyEmpty
        }
        if word.isEmpty{
            return .wordEmpty
        }
        if !self.ruby.applyingTransform(.hiraganaToKatakana, reverse: false)!.allSatisfy{self.availableChars.contains($0)}{
            return .unavailableCharacter
        }
        return nil
    }

    func makeStableData() -> UserDictionaryData {
        return UserDictionaryData(ruby: ruby, word: word, isVerb: isVerb, isPersonName: isPersonName, isPlaceName: isPlaceName, id: id)
    }

}

struct UserDictionary: Codable {
    let items: [UserDictionaryData]

    init(items: [UserDictionaryData]){
        self.items = items.indices.map{i in
            let item = items[i]
            return UserDictionaryData(ruby: item.ruby, word: item.word, isVerb: item.isVerb, isPersonName: item.isPersonName, isPlaceName: item.isPlaceName, id: i)
        }
    }

    func save(){
        let encoder = JSONEncoder()
        let saveData: Data
        if let encodedValue = try? encoder.encode(self) {
            saveData = encodedValue
        }else{
            saveData = Data()
        }
        let userDefaults = UserDefaults(suiteName: SharedStore.appGroupKey)!
        userDefaults.set(saveData, forKey: "user_dict")
    }
    static func get() -> Self? {
        let userDefaults = UserDefaults(suiteName: SharedStore.appGroupKey)!
        if let value = userDefaults.value(forKey: "user_dict") as? Data{
            let decoder = JSONDecoder()
            if let userDictionary = try? decoder.decode(UserDictionary.self, from: value) {
                return userDictionary
            }
        }
        return nil
    }
}

struct UserDictionaryData: Identifiable, Codable{
    let ruby: String
    let word: String
    let isVerb: Bool
    let isPersonName: Bool
    let isPlaceName: Bool
    let id: Int

    func makeEditableData() -> EditableUserDictionaryData {
        return EditableUserDictionaryData(ruby: ruby, word: word, isVerb: isVerb, isPersonName: isPersonName, isPlaceName: isPlaceName, id: id)
    }

    static func emptyData(id: Int) -> Self {
        return UserDictionaryData(ruby: "", word: "", isVerb: false, isPersonName: false, isPlaceName: false, id: id)
    }
}

final class UserDictManagerVariables: ObservableObject {
    @Published var items: [UserDictionaryData] = [
        UserDictionaryData(ruby: "あずき", word: "azooKey", isVerb: false, isPersonName: true, isPlaceName: false, id: 0),
    ]
    @Published var mode: Mode = .list
    @Published var selectedItem: EditableUserDictionaryData? = nil

    enum Mode{
        case list
        case details
    }

    init(){
        if let userDictionary = UserDictionary.get(){
            self.items = userDictionary.items
        }
    }
}

struct AzooKeyUserDictionaryView: View {
    @ObservedObject private var variables: UserDictManagerVariables = UserDictManagerVariables()

    var body: some View {
        if variables.mode == .list{
            UserDictionaryDataListView(variables: variables)
        }else{
            if let item = self.variables.selectedItem{
                UserDictionaryDataSettingView(item, variables: variables)
            }
        }
    }
}


struct UserDictionaryDataListView: View {
    let exceptionKey = "その他"

    @ObservedObject private var variables: UserDictManagerVariables
    @State private var editMode = EditMode.inactive

    init(variables: UserDictManagerVariables){
        self.variables = variables
    }

    var body: some View {
        Form {
            Section{
                Text("変換候補に単語を追加することができます。iOSの標準のユーザ辞書とは異なります。")
            }

            Section{
                HStack{
                    Spacer()
                    Button{
                        let id = variables.items.map{$0.id}.max()
                        self.variables.selectedItem = UserDictionaryData.emptyData(id: (id ?? -1) + 1).makeEditableData()
                        self.variables.mode = .details

                    }label: {
                        HStack {
                            Image(systemName: "plus")
                            Text("追加する")
                        }
                    }
                    Spacer()

                }
            }
            let currentGroupedItems: [String: [UserDictionaryData]] = Dictionary(grouping: variables.items, by: {$0.ruby.first.map{String($0)} ?? exceptionKey}).mapValues{$0.sorted{$0.id < $1.id}}
            let keys = currentGroupedItems.keys
            let currentKeys: [String] = keys.contains(exceptionKey) ? [exceptionKey] + keys.filter{$0 != exceptionKey}.sorted() : keys.sorted()

            ForEach(currentKeys, id: \.self){key in
                Section(header: Text(key)){
                    List{
                        ForEach(currentGroupedItems[key]!){data in
                            Button{
                                self.variables.selectedItem = data.makeEditableData()
                                self.variables.mode = .details
                            }label: {
                                HStack{
                                    Text(data.word)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Text(data.ruby)
                                        .foregroundColor(.systemGray)
                                }
                            }
                        }
                        .onDelete(perform: self.delete(section: key))
                    }.environment(\.editMode, $editMode)
                }

            }
        }
        .navigationBarTitle(Text("ユーザ辞書"), displayMode: .inline)
        .navigationBarItems(trailing: EmptyView())
    }

    func delete(section: String) -> (IndexSet) -> Void {
        return {(offsets: IndexSet) in
            let indices: [Int]
            if section == exceptionKey{
                indices = variables.items.indices.filter{variables.items[$0].ruby.first == nil}
            }else{
                indices = variables.items.indices.filter{variables.items[$0].ruby.hasPrefix(section)}
            }
            let sortedIndices = indices.sorted{
                variables.items[$0].id < variables.items[$1].id
            }
            variables.items.remove(atOffsets: IndexSet(offsets.map{sortedIndices[$0]}))
            let userDictionary = UserDictionary(items: variables.items)
            userDictionary.save()
        }
    }

}

struct UserDictionaryDataSettingView: View {
    @ObservedObject private var item: EditableUserDictionaryData
    @ObservedObject private var variables: UserDictManagerVariables

    init(_ item: EditableUserDictionaryData, variables: UserDictManagerVariables){
        self.item = item
        self.variables = variables
    }

    var body: some View {
        Form {
            Section(header: Text("読みと単語")){
                TextField("読み", text: $item.ruby)
                    .padding(.vertical, 2)
                TextField("単語", text: $item.word)
                    .padding(.vertical, 2)
                if let error = item.error{
                    HStack{
                        Image(systemName: "exclamationmark.triangle")
                        Text(error.message)
                            .font(.caption)
                    }
                }
            }
            Section(header: Text("詳細な設定")){
                if item.neadVerbCheck(){
                    HStack{
                        Toggle(isOn: $item.isVerb) {
                            Text("「\(item.mizenkeiWord)(\(item.mizenkeiRuby))」と言える")
                        }
                    }
                }
                HStack{
                    Spacer()
                    Toggle(isOn: $item.isPersonName) {
                        Text("人・動物・会社などの名前である")
                    }
                }
                HStack{
                    Spacer()
                    Toggle(isOn: $item.isPlaceName) {
                        Text("場所・建物などの名前である")
                    }
                }

            }
        }
        .navigationTitle(Text("詳細設定"))
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(
            trailing: Button{
                if item.error == nil{
                    self.save()
                    variables.mode = .list
                }
            }label: {
                Text("完了")
            }
        )
        .onDisappear{
            self.save()
            print("見えなくなるからここで更新処理をかける")
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)){_ in
            self.save()
            print("バックグラウンドに入るからここで更新処理をかける")
        }
        .onTapGesture {
            UIApplication.shared.closeKeyboard()
        }

    }

    func save(){
        if item.error == nil{
            if let itemIndex = variables.items.firstIndex(where: {$0.id == self.item.id}) {
                variables.items[itemIndex] = item.makeStableData()
            }else{
                variables.items.append(item.makeStableData())
            }

            let userDictionary = UserDictionary(items: variables.items)
            userDictionary.save()
        }

    }
}
