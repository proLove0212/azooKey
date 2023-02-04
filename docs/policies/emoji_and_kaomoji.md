# Emoji and Kaomoji Policy

## 絵文字と顔文字の分離

azooKeyでは絵文字と顔文字の分離を行っています。「絵文字をもっぱら用いる人」「顔文字をもっぱら用いる人」「区別なく用いる人」がいるためです。

上記の分離を実現するため、絵文字と顔文字は本体辞書としてはバンドルされず、ユーザ辞書と共にビルドされ、キーボード上で用いられています。

## 絵文字の更新

絵文字はUnicodeによっておおよそ1年間隔で更新が実施されます。このため、アプリケーションも1年間隔でデータを修正する必要があります。また、iOS / iPadOSでは絵文字の追加がOSの更新に伴って実施されます。

azooKeyの絵文字データは`MainApp/DataSet`の位置にバージョン別に保存されています。このデータをSwift側で読み込み、OSバージョンに応じてどこまで追加するかを判断し、ユーザ辞書とともに辞書ファイルとしてビルドし、保存します。

このため、iOS / iPadOSの更新直後すぐに新しい絵文字が使えるようにはならず、一度本体アプリを開いて辞書ファイルの再ビルドを行う必要があります。これを促すため、絵文字の更新と共にMessageViewをキーボード上に表示します。

## 絵文字キーボード

絵文字キーボードの実装は現状ないため、標準の絵文字キーボードの利用を推奨しています。しかし要望の多い機能であり、実装を予定しています。

絵文字キーボードの実装にあたってはCustardKitを利用する予定であり、絵文字キーボードを実現するためのAPIの整備が必要になっています。