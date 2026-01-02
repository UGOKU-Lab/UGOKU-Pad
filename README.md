# UGOKU Pad
<img src="https://github.com/user-attachments/assets/b2da444f-e0e3-46c4-aa92-2031e2f38083" width="600">

[UGOKU Pad](https://ugoku-lab.github.io/ugokupad.html)は、ESP32などのマイコンをBluetoothでスマートフォンと接続し、簡単に操作できるアプリです。  
ジョイスティックやスライダー、ボタンなど、色々なウィジェットを組み合わせて、自分だけの操作パネルを作成できます。  
モーターの操作やセンサーデータをモニタリングなど、様々な用途で活用できます。  
[UGOKU-Pad Arduino Library](https://github.com/UGOKU-Lab/UGOKU-Pad_Arduino) を使用することで、ESP32などのマイコンで簡単に通信プログラムを記述できます。Arduino IDEのライブラリマネージャーから "UGOKU-Pad" を検索してインストールすることも可能です。

[<img src="https://github.com/user-attachments/assets/73952bbe-7f89-46e9-9a6e-cdc7eea8e7c8" alt="Get it on Google Play" height="60">](https://play.google.com/store/apps/details?id=com.ugoku_lab.ugoku_console)　[<img src="https://github.com/user-attachments/assets/e27e5d09-63d0-4a2e-9e14-0bb05dabd487" alt="Get it on Google Play" height="60">](https://apps.apple.com/jp/app/ugoku-pad/id6739496098)

## 特徴
操作パネル（Console）上に、トグルスイッチやジョイスティックなどの入力ウィジェット、Value Monitor や Line Chart などのモニターウィジェットを任意の位置やサイズで配置できます。
各ウィジェットには任意のチャンネル番号を設定できます。

<img src="https://github.com/user-attachments/assets/83dc999a-abfa-456a-82dc-63a0d83efa90" width="1000">

## BLE通信について
**Flutter**の**flutter_blue_plus**ライブラリを用いて、Android/IOSの標準BLEに対応しています。  
チャンネル・バリューのペア(2バイト)9組と、全体のチェックサム(1バイト)を合わせた **19バイト固定長** のパケットで送受信します。  
最大9チャンネル分のデータを1パケットに集約して送受信することでBLE通信を効率化し、低遅延を実現しています。

| 要素         |役割| サイズ |
|--------------|--|------------|
| データペア (x9) |(チャンネル, バリュー) のペア × 9組| 18バイト (2バイト×9) |
| チェックサム |上記18バイトの排他的論理和(XOR)| 1バイト            |
|          | 合計          | 19バイト            |

50msごとに呼び出される `periodicSend()` により、以下を実行します。
- 最大9チャンネル分のデータを1パケットに集約
- 9チャンネルに満たない場合は、残りをダミーデータ(0)で埋めて19バイトにします
- 先頭18バイトのXORチェックサムを計算して末尾に付与
- Write Without Response で BLE 送信
- 9チャンネル超過分は自動的に複数パケットへ分割して送信

### UML図
<img src="https://github.com/user-attachments/assets/8f412e8d-542b-4886-8fee-9444f8d7e2e7" alt="UML図" width="700" />

## ライセンス
このプロジェクトは **GPLv3** のもとでライセンスされています。  


