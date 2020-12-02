//
//  afterCharacterAdded.swift
//  Keyboard
//
//  Created by β α on 2020/09/14.
//  Copyright © 2020 DevEn3. All rights reserved.
//

import Foundation
extension Kana2Kanji{
    ///カナを漢字に変換する関数, 最後の一文字を追加した場合。
    /// - Parameters:
    ///   - inputData: 今のInputData。
    ///   - N_best: N_best。
    ///   - addedCount: 文字数
    ///   - previousResult: 追加される前のデータ。
    /// - Returns:
    ///   - 変換候補。
    ///### 実装状況
    ///(0)多用する変数の宣言。
    ///
    ///(1)まず、追加された一文字に繋がるノードを列挙する。
    ///
    ///(2)次に、計算済みノードから、(1)で求めたノードにつながるようにregisterして、N_bestを求めていく。
    ///
    ///(3)(1)のregisterされた結果をresultノードに追加していく。この際EOSとの連接コストを計算しておく。
    ///
    ///(4)ノードをアップデートした上で返却する。
    func kana2lattice_added(_ inputData: InputData, N_best: Int, addedCount: Int, previousResult: (inputData: InputData, nodes: [[LatticeNode]])) -> (result: LatticeNode, nodes: [[LatticeNode]]) {
        if addedCount == 1{
            return kana2lattice_addedLast(inputData, N_best: N_best, previousResult: previousResult)
        }
        //(0)
        let nodes = previousResult.nodes
        let count = inputData.count

        //(1)
        let addedNodes: [[LatticeNode]] = ( .zero ..< count).map{(i: Int) in
            (previousResult.inputData.count ..< max(previousResult.inputData.count, min(count, i+self.dicdataStore.maxlength+1))).flatMap{j -> [LatticeNode] in
                if j<i{
                    return []
                }
                return self.dicdataStore.getLOUDSData(inputData: inputData, from: i, to: j)
            }
        }
        //(2)
        nodes.indices.forEach{(i: Int) in
            nodes[i].forEach{(node: LatticeNode) in
                if node.prevs.isEmpty{
                    return
                }
                if self.dicdataStore.shouldBeRemoved(data: node.data){
                    return
                }
                //変換した文字数
                let nextIndex = node.rubyCount + i
                addedNodes[nextIndex].forEach{(nextnode: LatticeNode) in
                    //この関数はこの時点で呼び出して、後のnode.registered.isEmptyで最終的に弾くのが良い。
                    if self.dicdataStore.shouldBeRemoved(data: nextnode.data){
                        return
                    }
                    //クラスの連続確率を計算する。
                    let ccValue = self.dicdataStore.getCCValue(node.data.rcid, nextnode.data.lcid)
                    let ccBonus = PValue(self.dicdataStore.getMatch(node.data, next: nextnode.data) * self.ccBonusUnit)
                    node.prevs.indices.forEach{(index: Int) in
                        let newValue = ccValue + ccBonus + node.values[index]
                        //追加すべきindexを取得する
                        let lastindex = (nextnode.prevs.lastIndex(where: {$0.totalValue>=newValue}) ?? -1) + 1
                        if lastindex == N_best{
                            return
                        }
                        let newnode = node.getSqueezedNode(index, value: newValue)
                        nextnode.prevs.insert(newnode, at: lastindex)
                        //カウントがオーバーしている場合は除去する
                        if nextnode.prevs.count > N_best{
                            nextnode.prevs.removeLast()
                        }
                    }
                }
            }
        }

        //(3)
        let result = LatticeNode.EOSNode

        addedNodes.indices.forEach{(i: Int) in
            addedNodes[i].forEach{(node: LatticeNode) in
                if node.prevs.isEmpty{
                    return
                }
                if self.dicdataStore.shouldBeRemoved(data: node.data){
                    return
                }
                //生起確率を取得する。
                let wValue = node.data.value()
                //valuesを更新する
                node.values = node.prevs.map{$0.totalValue + wValue}
                let nextIndex = node.rubyCount + i
                if count == nextIndex{
                    //最後に至るので
                    node.prevs.indices.forEach{
                        let newnode = node.getSqueezedNode($0, value: node.values[$0])
                        result.prevs.append(newnode)
                    }
                }else{
                    addedNodes[nextIndex].forEach{(nextnode: LatticeNode) in
                        //この関数はこの時点で呼び出して、後のnode.registered.isEmptyで最終的に弾くのが良い。
                        if self.dicdataStore.shouldBeRemoved(data: nextnode.data){
                            return
                        }
                        //クラスの連続確率を計算する。
                        let ccValue = self.dicdataStore.getCCValue(node.data.rcid, nextnode.data.lcid)
                        let ccBonus = PValue(self.dicdataStore.getMatch(node.data, next: nextnode.data) * 2)
                        node.prevs.indices.forEach{(index: Int) in
                            let newValue = ccValue + ccBonus + node.values[index]
                            //追加すべきindexを取得する
                            let lastindex = (nextnode.prevs.lastIndex(where: {$0.totalValue>=newValue}) ?? -1) + 1
                            if lastindex == N_best{
                                return
                            }
                            let newnode = node.getSqueezedNode(index, value: newValue)
                            nextnode.prevs.insert(newnode, at: lastindex)
                            //カウントがオーバーしている場合は除去する
                            if nextnode.prevs.count > N_best{
                                nextnode.prevs.removeLast()
                            }
                        }
                    }
                }
            }
        }

        //(4)

        let updatedNodes = nodes.indices.map{nodes[$0] + addedNodes[$0]} + addedNodes.suffix(addedNodes.endIndex - nodes.endIndex)
        return (result: result, nodes: updatedNodes)
    }
}
