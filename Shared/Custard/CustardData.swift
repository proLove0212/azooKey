//
//  CustardData.swift
//  KanaKanjier
//
//  Created by β α on 2021/02/18.
//  Copyright © 2021 DevEn3. All rights reserved.
//

import Foundation

/// - 変換対象の言語を指定します。
/// - specify language to convert
public enum CustardLanguage: String, Codable {
    /// - 英語(アメリカ)に変換します
    /// - convert to American English
    case en_US

    /// - 日本語(共通語)に変換します
    /// - convert to common Japanese
    case ja_JP

    /// - ギリシア語に変換します
    /// - convert to Greek
    case el_GR

    /// - 変換を行いません
    /// - don't convert
    case none

    /// - 特に変換する言語を指定しません
    /// - don't specify
    case undefined
}

/// - 入力方式を指定します。
/// - specify input style
public enum CustardInputStyle: String, Codable {
    /// - 入力された文字をそのまま用います
    /// - use inputted characters directly
    case direct

    /// - 入力されたローマ字を仮名に変換して用います
    /// - use roman-kana conversion
    case roman2kana
}

/// - カスタードのバージョンを指定します。
/// - specify custard version
public enum CustardVersion: String, Codable {
    case v1_0 = "1.0"
}

public struct CustardMetaData: Codable {
    public init(custard_version: CustardVersion, display_name: String) {
        self.custard_version = custard_version
        self.display_name = display_name
    }

    ///version
    var custard_version: CustardVersion

    ///display name
    /// - used in tab bar
    let display_name: String
}

public struct Custard: Codable {
    public init(identifier: String, language: CustardLanguage, input_style: CustardInputStyle, metadata: CustardMetaData, interface: CustardInterface) {
        self.identifier = identifier
        self.language = language
        self.input_style = input_style
        self.metadata = metadata
        self.interface = interface
    }

    ///identifier
    /// - must be unique
    let identifier: String

    ///language to convert
    let language: CustardLanguage

    ///input style
    let input_style: CustardInputStyle

    ///metadata
    let metadata: CustardMetaData

    ///interface
    let interface: CustardInterface

    public func write(to url: URL) throws {
        let encoded_data = try JSONEncoder().encode(self)
        try encoded_data.write(to: url)
    }
}

/// - インターフェースのキーのスタイルです
/// - style of keys
public enum CustardInterfaceStyle: String, Codable {
    /// - フリック可能なキー
    /// - flickable keys
    case tenkeyStyle = "tenkey_style"

    /// - 長押しで他の文字を選べるキー
    /// - keys with variations
    case pcStyle = "pc_style"
}

/// - インターフェースのレイアウトのスタイルです
/// - style of layout
public enum CustardInterfaceLayout: Codable {
    /// - 画面いっぱいにマス目状で均等に配置されます
    /// - keys are evenly layouted in a grid pattern fitting to the screen
    case gridFit(CustardInterfaceLayoutGridValue)

    /// - はみ出した分はスクロールできる形でマス目状に均等に配置されます
    /// - keys are layouted in a scrollable grid pattern and can be overflown
    case gridScroll(CustardInterfaceLayoutScrollValue)
}

public extension CustardInterfaceLayout{
    private enum CodingKeys: CodingKey {
        case type
        case row_count, column_count
        case direction
    }
    enum ValueType: String, Codable{
        case grid_fit
        case grid_scroll
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .gridFit(value):
            try container.encode(ValueType.grid_fit, forKey: .type)
            try container.encode(value.rowCount, forKey: .row_count)
            try container.encode(value.columnCount, forKey: .column_count)
        case let .gridScroll(value):
            try container.encode(ValueType.grid_scroll, forKey: .type)
            try container.encode(value.direction, forKey: .direction)
            try container.encode(value.rowCount, forKey: .row_count)
            try container.encode(value.columnCount, forKey: .column_count)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ValueType.self, forKey: .type)
        let rowCount = try container.decode(Double.self, forKey: .row_count)
        let columnCount = try container.decode(Double.self, forKey: .column_count)
        switch type {
        case .grid_fit:
            self = .gridFit(.init(rowCount: abs(Int(rowCount)), columnCount: abs(Int(columnCount))))
        case .grid_scroll:
            let direction = try container.decode(CustardInterfaceLayoutScrollValue.ScrollDirection.self, forKey: .direction)
            self = .gridScroll(.init(direction: direction, rowCount: abs(rowCount), columnCount: abs(columnCount)))
        }
    }
}

public struct CustardInterfaceLayoutGridValue {
    public init(rowCount: Int, columnCount: Int) {
        self.rowCount = rowCount
        self.columnCount = columnCount
    }

    /// - 横方向に配置するキーの数
    /// - number of keys placed horizontally
    let rowCount: Int
    /// - 縦方向に配置するキーの数
    /// - number of keys placed vertically
    let columnCount: Int
}

public struct CustardInterfaceLayoutScrollValue {
    public init(direction: ScrollDirection, rowCount: Double, columnCount: Double) {
        self.direction = direction
        self.rowCount = rowCount
        self.columnCount = columnCount
    }

    /// - スクロールの方向
    /// - direction of scroll
    let direction: ScrollDirection

    /// - 一列に配置するキーの数
    /// - number of keys in scroll normal direction
    let rowCount: Double

    /// - 画面内に収まるスクロール方向のキーの数
    /// - number of keys in screen in scroll direction
    let columnCount: Double

    /// - direction of scroll
    public enum ScrollDirection: String, Codable{
        case vertical
        case horizontal
    }
}

/// - 画面内でのキーの位置を決める指定子
/// - the specifier of key's position in screen
public enum CustardKeyPositionSpecifier: Hashable {
    /// - gridFitのレイアウトを利用した際のキーの位置指定子
    /// - position specifier when you use grid fit layout
    case gridFit(GridFitPositionSpecifier)

    /// - gridScrollのレイアウトを利用した際のキーの位置指定子
    /// - position specifier when you use grid scroll layout
    case gridScroll(GridScrollPositionSpecifier)
}

/// - gridFitのレイアウトを利用した際のキーの位置指定子に与える値
/// - values in position specifier when you use grid fit layout
public struct GridFitPositionSpecifier: Codable, Hashable {
    public init(x: Int, y: Int, width: Int = 1, height: Int = 1) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }

    /// - 横方向の位置(左をゼロとする)
    /// - horizontal position (leading edge is zero)
    let x: Int

    /// - 縦方向の位置(上をゼロとする)
    /// - vertical positon (top edge is zero)
    let y: Int


    let width: Int
    let height: Int

    private enum CodingKeys: CodingKey{
        case x, y, width, height
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.x = abs(try container.decode(Int.self, forKey: .x))
        self.y = abs(try container.decode(Int.self, forKey: .y))
        self.width = abs(try container.decode(Int.self, forKey: .width))
        self.height = abs(try container.decode(Int.self, forKey: .height))
    }
}

/// - gridScrollのレイアウトを利用した際のキーの位置指定子に与える値
/// - values in position specifier when you use grid scroll layout
public struct GridScrollPositionSpecifier: Codable, Hashable, ExpressibleByIntegerLiteral {
    /// - 通し番号
    /// - index
    let index: Int

    public init(_ index: Int){
        self.index = index
    }
}

/// - 記述の簡便化のため定義
/// - conforms to protocol for writability
public extension GridScrollPositionSpecifier {
    typealias IntegerLiteralType = Int

    init(integerLiteral value: Int) {
        self.index = value
    }
}

/// - インターフェース
/// - interface
public struct CustardInterface: Codable {
    public init(keyStyle: CustardInterfaceStyle, keyLayout: CustardInterfaceLayout, keys: [CustardKeyPositionSpecifier : CustardInterfaceKey]) {
        self.keyStyle = keyStyle
        self.keyLayout = keyLayout
        self.keys = keys
    }

    /// - キーのスタイル
    /// - style of keys
    /// - warning: Currently when you use gird scroll. layout, key style would be ignored.
    let keyStyle: CustardInterfaceStyle

    /// - キーのレイアウト
    /// - layout of keys
    let keyLayout: CustardInterfaceLayout

    /// - キーの辞書
    /// - dictionary of keys
    /// - warning: You must use specifiers consistent with key layout. When you use inconsistent one, it would be ignored.
    let keys: [CustardKeyPositionSpecifier: CustardInterfaceKey]
}

public extension CustardInterface {
    private enum CodingKeys: CodingKey{
        case key_style
        case key_layout
        case keys
    }

    private enum KeyType: String, Codable {
        case custom, system
    }

    private enum SpecifierType: String, Codable {
        case grid_fit, grid_scroll
    }

    private struct Element: Codable{
        init(specifier: CustardKeyPositionSpecifier, key: CustardInterfaceKey) {
            self.specifier = specifier
            self.key = key
        }

        let specifier: CustardKeyPositionSpecifier
        let key: CustardInterfaceKey

        private var specifierType: SpecifierType {
            switch self.specifier{
            case .gridFit: return .grid_fit
            case .gridScroll: return .grid_scroll
            }
        }

        private var keyType: KeyType {
            switch self.key{
            case .system: return .system
            case .custom: return .custom
            }
        }

        private enum CodingKeys: CodingKey {
            case specifier_type
            case specifier
            case key_type
            case key
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(specifierType, forKey: .specifier_type)
            switch self.specifier{
            case let .gridFit(value as Encodable),
                 let .gridScroll(value as Encodable):
                try value.containerEncode(container: &container, key: .specifier)
            }
            try container.encode(keyType, forKey: .key_type)
            switch self.key{
            case let .system(value as Encodable),
                 let .custom(value as Encodable):
                try value.containerEncode(container: &container, key: .key)
            }
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let specifierType = try container.decode(SpecifierType.self, forKey: .specifier_type)
            switch specifierType{
            case .grid_fit:
                let specifier = try container.decode(GridFitPositionSpecifier.self, forKey: .specifier)
                self.specifier = .gridFit(specifier)
            case .grid_scroll:
                let specifier = try container.decode(GridScrollPositionSpecifier.self, forKey: .specifier)
                self.specifier = .gridScroll(specifier)
            }

            let keyType = try container.decode(KeyType.self, forKey: .key_type)
            switch keyType{
            case .system:
                let key = try container.decode(CustardInterfaceSystemKey.self, forKey: .key)
                self.key = .system(key)
            case .custom:
                let key = try container.decode(CustardInterfaceCustomKey.self, forKey: .key)
                self.key = .custom(key)
            }
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(keyStyle, forKey: .key_style)
        try container.encode(keyLayout, forKey: .key_layout)
        let elements = self.keys.map{Element(specifier: $0.key, key: $0.value)}
        try container.encode(elements, forKey: .keys)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.keyStyle = try container.decode(CustardInterfaceStyle.self, forKey: .key_style)
        self.keyLayout = try container.decode(CustardInterfaceLayout.self, forKey: .key_layout)
        let elements = try container.decode([Element].self, forKey: .keys)
        self.keys = elements.reduce(into: [:]){dictionary, element in
            dictionary[element.specifier] = element.key
        }
    }
}

/// - キーのデザイン
/// - design information of key
public struct CustardKeyDesign: Codable {
    public init(label: CustardKeyLabelStyle, color: CustardKeyDesign.ColorType) {
        self.label = label
        self.color = color
    }

    let label: CustardKeyLabelStyle
    let color: ColorType

    public enum ColorType: String, Codable{
        case normal
        case special
        case selected
    }
}

/// - バリエーションのキーのデザイン
/// - design information of key
public struct CustardVariationKeyDesign: Codable {
    public init(label: CustardKeyLabelStyle) {
        self.label = label
    }

    let label: CustardKeyLabelStyle
}

/// - キーに指定するラベル
/// - labels on the key
public enum CustardKeyLabelStyle: Codable {
    case text(String)
    case systemImage(String)
}

public extension CustardKeyLabelStyle{
    private enum CodingKeys: CodingKey{
        case text
        case system_image
    }

    private var key: CodingKeys {
        switch self{
        case .text: return .text
        case .systemImage: return .system_image
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .text(value),
             let .systemImage(value):
            try container.encode(value, forKey: key)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        guard let key = container.allKeys.first else{
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Unabled to decode CustardKeyLabelStyle."
                )
            )
        }
        switch key {
        case .text:
            let value = try container.decode(
                String.self,
                forKey: .text
            )
            self = .text(value)
        case .system_image:
            let value = try container.decode(
                String.self,
                forKey: .system_image
            )
            self = .systemImage(value)
        }
    }
}

/// - キーの変種の種類
/// - type of key variation
public enum CustardKeyVariationType {
    /// - variation of flick
    /// - warning: when you use pc style, this type of variation would be ignored.
    case flickVariation(FlickDirection)

    /// - variation selectable when keys were longoressed, especially used in pc style keyboard.
    /// - warning: when you use flick key style, this type of variation would be ignored.
    case longpressVariation
}

/// - key's data in interface
public enum CustardInterfaceKey {
    case system(CustardInterfaceSystemKey)
    case custom(CustardInterfaceCustomKey)
}

/// - keys prepared in default
public enum CustardInterfaceSystemKey: Codable {
    /// - the globe key
    case changeKeyboard

    /// - the enter key that changes its label in condition
    case enter

    ///custom keys.
    /// - flick 小ﾞﾟkey
    case flickKogaki
    /// - flick ､｡!? key
    case flickKutoten
    /// - flick hiragana tab
    case flickHiraTab
    /// - flick abc tab
    case flickAbcTab
    /// - flick number and symbols tab
    case flickStar123Tab
}

public extension CustardInterfaceSystemKey{
    private enum CodingKeys: CodingKey {
        case type
    }

    private enum ValueType: String, Codable {
        case change_keyboard
        case enter
        case flick_kogaki
        case flick_kutoten
        case flick_hira_tab
        case flick_abc_tab
        case flick_star123_tab
    }

    private var valueType: ValueType {
        switch self{
        case .changeKeyboard: return .change_keyboard
        case .enter: return .enter
        case .flickKogaki: return .flick_kogaki
        case .flickKutoten: return .flick_kutoten
        case .flickHiraTab: return .flick_hira_tab
        case .flickAbcTab: return .flick_abc_tab
        case .flickStar123Tab: return .flick_star123_tab
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.valueType, forKey: .type)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ValueType.self, forKey: .type)
        switch type {
        case .enter:
            self = .enter
        case .change_keyboard:
            self = .changeKeyboard
        case .flick_kogaki:
            self = .flickKogaki
        case .flick_kutoten:
            self = .flickKutoten
        case .flick_hira_tab:
            self = .flickHiraTab
        case .flick_abc_tab:
            self = .flickAbcTab
        case .flick_star123_tab:
            self = .flickStar123Tab
        }
    }
}

/// - keys you can defined
public struct CustardInterfaceCustomKey: Codable {
    public init(design: CustardKeyDesign, press_actions: [CodableActionData], longpress_actions: CodableLongpressActionData, variations: [CustardInterfaceVariation]) {
        self.design = design
        self.press_actions = press_actions
        self.longpress_actions = longpress_actions
        self.variations = variations
    }

    /// - design of this key
    let design: CustardKeyDesign

    /// - actions done when this key is pressed. actions are done in order.
    let press_actions: [CodableActionData]

    /// - actions done when this key is longpressed. actions are done in order.
    let longpress_actions: CodableLongpressActionData

    /// - variations available when user flick or longpress this key
    let variations: [CustardInterfaceVariation]
}

public extension CustardInterfaceCustomKey {
    /// Create simple input key using flick
    /// - parameters:
    ///  - center: string inputed when tap the key
    ///  - subs: set string inputed when flick the key up to four letters. letters are stucked in order left -> top -> right -> bottom
    ///  - centerLabel: (optional) if needed, set label of center. without specification `center` is set as label
    static func flickSimpleInputs(center: String, subs: [String], centerLabel: String? = nil) -> Self {
        let variations: [CustardInterfaceVariation] = zip(subs, [FlickDirection.left, .top, .right, .bottom]).map{letter, direction in
            .init(
                type: .flickVariation(direction),
                key: .init(
                    design: .init(label: .text(letter)),
                    press_actions: [.input(letter)],
                    longpress_actions: .none
                )
            )
        }

        return .init(
            design: .init(label: .text(centerLabel ?? center), color: .normal),
            press_actions: [.input(center)],
            longpress_actions: .none,
            variations: variations
        )
    }

    static let flickDelete: Self = .init(
        design: .init(label: .systemImage("delete.left"), color: .special),
        press_actions: [.delete(1)],
        longpress_actions: .init(repeat: [.delete(1)]),
        variations: [
            .init(
                type: .flickVariation(.left),
                key: .init(
                    design: .init(label: .systemImage("xmark")),
                    press_actions: [.smartDeleteDefault],
                    longpress_actions: .none
                )
            ),
        ]
    )

    static let flickSpace: Self = .init(
        design: .init(label: .text("空白"), color: .special),
        press_actions: [.input(" ")],
        longpress_actions: .init(start: [.toggleCursorBar]),
        variations: [
            .init(
                type: .flickVariation(.left),
                key: .init(
                    design: .init(label: .text("←")),
                    press_actions: [.moveCursor(-1)],
                    longpress_actions: .init(repeat: [.moveCursor(-1)])
                )
            ),
            .init(
                type: .flickVariation(.top),
                key: .init(
                    design: .init(label: .text("全角")),
                    press_actions: [.input("　")],
                    longpress_actions: .none
                )
            ),
            .init(
                type: .flickVariation(.bottom),
                key: .init(
                    design: .init(label: .text("tab")),
                    press_actions: [.input("\t")],
                    longpress_actions: .none
                )
            )
        ]
    )
}

/// - variation of key, includes flick keys and selectable variations in pc style keyboard.
public struct CustardInterfaceVariation: Codable {
    public init(type: CustardKeyVariationType, key: CustardInterfaceVariationKey) {
        self.type = type
        self.key = key
    }

    /// - type of the variation
    let type: CustardKeyVariationType

    /// - data of variation
    let key: CustardInterfaceVariationKey
}

public extension CustardInterfaceVariation {
    private enum CodingKeys: CodingKey{
        case type
        case direction
        case key
    }

    private enum ValueType: String, Codable {
        case flick_variation
        case longpress_variation
    }

    private var valueType: ValueType {
        switch self.type{
        case .flickVariation: return .flick_variation
        case .longpressVariation: return .longpress_variation
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.key, forKey: .key)
        try container.encode(self.valueType, forKey: .type)
        switch self.type{
        case let .flickVariation(value):
            try container.encode(value, forKey: .direction)
        case .longpressVariation:
            break
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.key = try container.decode(CustardInterfaceVariationKey.self, forKey: .key)
        let valueType = try container.decode(ValueType.self, forKey: .type)
        switch valueType{
        case .flick_variation:
            let direction = try container.decode(FlickDirection.self, forKey: .direction)
            self.type = .flickVariation(direction)
        case .longpress_variation:
            self.type = .longpressVariation
        }
    }
}

/// - data of variation key
public struct CustardInterfaceVariationKey: Codable {
    public init(design: CustardVariationKeyDesign, press_actions: [CodableActionData], longpress_actions: CodableLongpressActionData) {
        self.design = design
        self.press_actions = press_actions
        self.longpress_actions = longpress_actions
    }

    /// - label on this variation
    let design: CustardVariationKeyDesign

    /// - actions done when you select this variation. actions are done in order..
    let press_actions: [CodableActionData]

    /// - actions done when you 'long select' this variation, like long-flick. actions are done in order.
    let longpress_actions: CodableLongpressActionData
}

public extension Custard{
    static let hieroglyph: Custard = {
        let hieroglyphs = Array(String.UnicodeScalarView((UInt32(0x13000)...UInt32(0x133FF)).compactMap(UnicodeScalar.init))).map(String.init)

        var keys: [CustardKeyPositionSpecifier: CustardInterfaceKey] = [
            .gridScroll(0): .system(.changeKeyboard),
            .gridScroll(1): .custom(
                .init(
                    design: .init(label: .text("←"), color: .special),
                    press_actions: [.moveCursor(-1)],
                    longpress_actions: .init(repeat: [.moveCursor(-1)]),
                    variations: []
                )
            ),
            .gridScroll(2): .custom(
                .init(
                    design: .init(label: .systemImage("list.dash"), color: .special),
                    press_actions: [.toggleTabBar],
                    longpress_actions: .none,
                    variations: []
                )
            ),
            .gridScroll(3): .custom(
                .init(
                    design: .init(label: .text("→"), color: .special),
                    press_actions: [.moveCursor(1)],
                    longpress_actions: .init(repeat: [.moveCursor(1)]),
                    variations: []
                )
            ),
            .gridScroll(4): .custom(
                .init(
                    design: .init(label: .systemImage("delete.left"), color: .special),
                    press_actions: [.delete(1)],
                    longpress_actions: .init(repeat: [.delete(1)]),
                    variations: []
                )
            ),
        ]

        hieroglyphs.indices.forEach{
            keys[.gridScroll(GridScrollPositionSpecifier(5+$0))] = .custom(
                .init(
                    design: .init(label: .text(hieroglyphs[$0]), color: .normal),
                    press_actions: [.input(hieroglyphs[$0])],
                    longpress_actions: .none,
                    variations: []
                )
            )
        }

        let custard = Custard(
            identifier: "Hieroglyphs",
            language: .undefined,
            input_style: .direct,
            metadata: .init(custard_version: .v1_0, display_name: "ヒエログリフ"),
            interface: .init(
                keyStyle: .tenkeyStyle,
                keyLayout: .gridScroll(.init(direction: .vertical, rowCount: 8, columnCount: 4.2)),
                keys: keys
            )
        )
        return custard
    }()
}
