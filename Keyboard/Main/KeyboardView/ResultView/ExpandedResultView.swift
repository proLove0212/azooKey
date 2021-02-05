//
//  ExpandedResultView.swift
//  Keyboard
//
//  Created by β α on 2020/09/05.
//  Copyright © 2020 DevEn3. All rights reserved.
//

import Foundation
import SwiftUI

class SharedResultData: ObservableObject{
    @Published var results: [ResultData] = []
}

struct ExpandedResultView: View {
    @ObservedObject private var sharedResultData: SharedResultData
    @Binding private var isResultViewExpanded: Bool

    @State private var splitedResults: [SplitedResultData]

    init(isResultViewExpanded: Binding<Bool>, sharedResultData: SharedResultData){
        self.sharedResultData = sharedResultData
        self._isResultViewExpanded = isResultViewExpanded
        self._splitedResults = State(initialValue: Self.registerResults(results: sharedResultData.results))
    }

    // FIXME: これはGridViewが使えないからこうなっている。
    var body: some View {
        VStack{
            HStack(alignment: .center){
                Spacer()
                    .frame(height: 18)
                //候補をしまうボタン
                Button(action: {
                    self.collapse()
                }){
                    Image(systemName: "chevron.up")
                        .font(Design.shared.fonts.iconImageFont)
                        .frame(height: 18)
                }
                .buttonStyle(ResultButtonStyle(height: 18))
                .padding(.trailing, 10)
            }
            .padding(.top, 10)
            ScrollView{
                LazyVStack(alignment: .leading){
                    ForEach(splitedResults, id: \.id){results in
                        Divider()
                        HStack{
                            ForEach(results.results, id: \.id){datum in
                                Button(action: {
                                    self.pressed(data: datum)
                                }){
                                    Text(datum.candidate.text)
                                }
                                .buttonStyle(ResultButtonStyle(height: 18))
                                .contextMenu{
                                    ResultContextMenuView(text: datum.candidate.text)
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, 3)
                .padding(.leading, 15)

            }
        }
        .frame(height: Design.shared.keyboardHeight, alignment: .bottom)
    }

    private func pressed(data: ResultData){
        Store.shared.action.notifyComplete(data.candidate)
        self.collapse()
    }

    private func collapse(){
        isResultViewExpanded = false
    }

    private static func registerResults(results: [ResultData]) -> [SplitedResultData] {
        var curSum: CGFloat = .zero
        var splited: [SplitedResultData] = []
        var curResult: [ResultData] = []
        let font = UIFont.systemFont(ofSize: Design.shared.fonts.resultViewFontSize+1)
        results.forEach{[unowned font] datum in
            let width = datum.candidate.text.size(withAttributes: [.font: font]).width + 20
            if !Design.shared.isOverScreenWidth(curSum + width){
                curResult.append(datum)
                curSum += width
            }else{
                splited.append(SplitedResultData(id: splited.count, results: curResult))
                curSum = width
                curResult = [datum]
            }
        }
        splited.append(SplitedResultData(id: splited.count, results: curResult))
        return splited
    }

}

struct SplitedResultData: Identifiable{
    let id: Int
    let results: [ResultData]
}
