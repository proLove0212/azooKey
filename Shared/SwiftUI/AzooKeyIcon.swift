//
//  AzooKeyIconView.swift
//  AzooKeyIconView
//
//  Created by ensan on 2021/07/22.
//  Copyright © 2021 ensan. All rights reserved.
//

import SwiftUI

struct AzooKeyIcon: View {
    @Environment(\.colorScheme) private var colorScheme
    private let color: Color
    private let looks: Looks
    private let arguments: Arguments
    enum Looks {
        case normal
        case king
        case santaClaus
        case strawHat
    }
    enum Color {
        case auto
        case color(SwiftUI.Color)
    }
    private enum Arguments {
        case relative(size: CGFloat, textStyle: Font.TextStyle)
        case fixed(size: CGFloat)
    }
    init(fontSize: CGFloat, relativeTo textStyle: Font.TextStyle = .body, color: Color = .auto, looks: Looks = .normal) {
        self.color = color
        self.arguments = .relative(size: fontSize, textStyle: textStyle)
        self.looks = looks
    }

    init(fixedSize: CGFloat, color: Color = .auto, looks: Looks = .normal) {
        self.color = color
        self.arguments = .fixed(size: fixedSize)
        self.looks = looks
    }

    private var foregroundColor: SwiftUI.Color {
        switch self.color {
        case .auto:
            switch colorScheme {
            case .light:
                return .init(red: 0.398, green: 0.113, blue: 0.218)
            case .dark:
                return .white
            @unknown default:
                return .init(red: 0.398, green: 0.113, blue: 0.218)
            }
        case let .color(color):
            return color
        }
    }

    @ViewBuilder
    private var icon: some View {
        switch looks {
        case .normal:
            Text("1")
                .foregroundColor(foregroundColor)
        case .king:
            ZStack(alignment: .center) {
                Text("α")
                    .foregroundColor(foregroundColor)
                Text("\u{EA00}")
                    .foregroundColor(.orange)
            }
        case .strawHat:
            ZStack(alignment: .center) {
                Text("β")
                    .foregroundColor(foregroundColor)
                Text("\u{EA10}")
                    .foregroundColor(SwiftUI.Color(red: 243 / 255, green: 210 / 255, blue: 82 / 255))
                Text("\u{EA11}")
                    .foregroundColor(.white)
            }
        case .santaClaus:
            ZStack(alignment: .center) {
                Text("γ")
                    .foregroundColor(foregroundColor)
                Text("\u{EA20}")
                    .foregroundColor(.black)
                Text("\u{EA21}")
                    .foregroundColor(.white)
                Text("\u{EA22}")
                    .foregroundColor(.red)
            }
        }
    }

    private var font: Font {
        switch self.arguments {
        case let .relative(size: size, textStyle: textStyle):
            return Design.fonts.azooKeyIconFont(size, relativeTo: textStyle)
        case let .fixed(size: size):
            return Design.fonts.azooKeyIconFont(fixedSize: size)
        }
    }

    var body: some View {
        icon.font(font)
    }
}
