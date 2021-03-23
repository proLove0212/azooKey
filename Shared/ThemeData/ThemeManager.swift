//
//  ThemeIndex.swift
//  KanaKanjier
//
//  Created by β α on 2021/02/09.
//  Copyright © 2021 DevEn3. All rights reserved.
//

import Foundation
import UIKit

struct ThemeIndices: Codable, Equatable {
    var currentIndices: [Int] = [0]
    var selectedIndex: Int = 0
}

struct ThemeIndexManager: Equatable {
    private var index: ThemeIndices

    private static func fileURL(name: String) -> URL {
        let directoryPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: SharedStore.appGroupKey)!
        let url = directoryPath.appendingPathComponent(name)
        return url
    }

    private static func directoryExistCheck() {
        let directoryPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: SharedStore.appGroupKey)!
        let filePath = directoryPath.appendingPathComponent("themes/").path
        //try! FileManager.default.removeItem(atPath: filePath)
        if !FileManager.default.fileExists(atPath: filePath){
            do{
                debug("ファイルを新規作成")
                try FileManager.default.createDirectory(atPath: filePath, withIntermediateDirectories: true)
            } catch {
                debug(error)
            }
        }
    }

    static func load() -> Self {
        directoryExistCheck()
        let themeIndexURL = fileURL(name: "themes/index.json")
        do{
            let data = try Data(contentsOf: themeIndexURL)
            let themeIndex = try JSONDecoder().decode(ThemeIndices.self, from: data)
            return self.init(index: themeIndex)
        } catch {
            debug(error)
            return self.init(index: ThemeIndices())
        }
    }

    func save() {
        let themeIndexURL = Self.fileURL(name: "themes/index.json")
        do {
            let data = try JSONEncoder().encode(self.index)
            try data.write(to: themeIndexURL, options: .atomicWrite)
        } catch {
            debug(error)
        }
    }

    func theme(at index: Int) throws -> ThemeData {
        if index == 0{
            return .default
        }
        let themeFileURL = Self.fileURL(name: "themes/theme_\(index).theme")
        let data = try Data(contentsOf: themeFileURL)
        var themeData = try JSONDecoder().decode(ThemeData.self, from: data)

        //背景画像を設定する
        if case let .path(path) = themeData.picture, let uiImage = UIImage(contentsOfFile: Self.fileURL(name: path).path){
            themeData.picture = .uiImage(uiImage)
        }

        return themeData
    }

    mutating func saveTheme(theme: ThemeData) throws -> Int {
        var saveData = theme
        let id: Int
        if let _id = saveData.id{
            id = _id
        }else{
            //この場合idを決定する
            id = self.nextIndex
            saveData.id = id
        }

        //背景画像を設定する
        if case let .uiImage(image) = saveData.picture, let pngImageData = image.pngData(){
            let imagePath = "themes/theme_\(id)_bg.png"
            let fileURL = Self.fileURL(name: imagePath)
            try pngImageData.write(to: fileURL)
            saveData.picture = .path(imagePath)
        }

        //テーマを保存する
        do{
            let encoder = JSONEncoder()
            let data = try encoder.encode(saveData)
            let fileURL = Self.fileURL(name: "themes/theme_\(id).theme")
            try data.write(to: fileURL)
        }

        if !self.index.currentIndices.contains(id){
            self.index.currentIndices.append(id)
        }
        self.save()
        return id
    }

    mutating func select(at index: Int){
        self.index.selectedIndex = index
        self.save()
    }

    mutating func remove(index: Int){
        if index == 0{
            return
        }
        self.index.currentIndices = self.index.currentIndices.filter{$0 != index}
        if index == self.index.selectedIndex{
            self.index.selectedIndex = 0
        }
        do{
            let themeFileURL = Self.fileURL(name: "themes/theme_\(index).theme")
            let bgFileURL = Self.fileURL(name: "themes/theme_\(index)_bg.png")

            try FileManager.default.removeItem(atPath: themeFileURL.path)
            try FileManager.default.removeItem(atPath: bgFileURL.path)
            self.save()
        }catch{
            debug(error)
        }
    }

    var indices: [Int] {
        return index.currentIndices
    }

    var selectedIndex: Int {
        return index.selectedIndex
    }

    var nextIndex: Int {
        return (index.currentIndices.last ?? 0) + 1
    }


}
