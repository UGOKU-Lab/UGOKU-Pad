# UGOKU Pad
<img src="https://github.com/user-attachments/assets/b2da444f-e0e3-46c4-aa92-2031e2f38083" width="600">

[UGOKU Pad](https://ugoku-lab.github.io/ugokupad.html)は、ESP32などのマイコンをBluetoothでスマートフォンと接続し、簡単に操作できるアプリです。  
ジョイスティックやスライダー、ボタンなど、色々なウィジェットを組み合わせて、自分だけの操作パネルを作成できます。  
モーターの操作やセンサーデータをモニタリングなど、様々な用途で活用できます。  
[ESP32に対応したArduinoサンプルコード](https://github.com/UGOKU-Lab/ESP32_Arduino_for_UGOKU_Pad)も公開しているので、気軽にお試しいただけます。

[<img src="https://github.com/user-attachments/assets/73952bbe-7f89-46e9-9a6e-cdc7eea8e7c8" alt="Get it on Google Play" height="60">](https://play.google.com/store/apps/details?id=com.ugoku_lab.ugoku_console)　[<img src="https://github.com/user-attachments/assets/e27e5d09-63d0-4a2e-9e14-0bb05dabd487" alt="Get it on Google Play" height="60">](https://apps.apple.com/jp/app/ugoku-pad/id6739496098)

## 特徴
操作パネル（Console）上に、トグルスイッチやジョイスティックなどの入力ウィジェット、Value Monitor や Line Chart などのモニターウィジェットを任意の位置やサイズで配置できます。
各ウィジェットには任意のチャンネル番号を設定できます。

<img src="https://github.com/user-attachments/assets/83dc999a-abfa-456a-82dc-63a0d83efa90" width="1000">

## BLE通信について
**Flutter**の**flutter_blue_plus**ライブラリを用いて、Android/IOSの標準BLEに対応しています。  
チャンネル・バリュー・チェックサムの3バイトのデータを単位として送受信します。  
最大9チャンネル分のデータを1パケットに集約して送受信することでBLE通信を効率化し、低遅延を実現しています。

| 要素         |役割| 単位サイズ | 9チャンネル時の合計 |
|--------------|--|------------|--------------------|
| チャンネル |各ウィジェット・軸に割り当てる任意の番号(0-255)| 1バイト    | 9バイト             |
| バリュー   |各ウィジェットで送信または受信する値(0-255)| 1バイト    | 9バイト             
| チェックサム |チャンネルとバリューの排他的論理和| 1バイト    | 1バイト             |
|          | | 合計          | 19バイト            |

50msごとに呼び出される `periodicSend()` により、以下を実行します。
- 最大9チャンネル分のデータを1パケットに集約
- XORチェックサムの計算
- Write Without Response で BLE 送信
- 9チャンネル超過分は自動的に複数パケットへ分割して送信

### UML図
<img src="https://github.com/user-attachments/assets/8f412e8d-542b-4886-8fee-9444f8d7e2e7" alt="UML図" width="700" />

## ライセンス
このプロジェクトは **GPLv3** のもとでライセンスされています。  


