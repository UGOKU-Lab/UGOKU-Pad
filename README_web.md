# UGOKU Pad — Web版

本ドキュメントは [UGOKU Pad](./README.md) の **Web ブラウザ対応版** についてまとめたものです。
モバイル版 (Android / iOS) の機能解説は [README.md](./README.md) を参照してください。

## 概要

[Web Bluetooth API](https://developer.mozilla.org/ja/docs/Web/API/Web_Bluetooth_API) を利用して、ブラウザから直接 ESP32 などの BLE デバイスに接続し、操作パネルを表示できます。アプリのインストールは不要で、URL を開くだけで使えます。

| 項目 | 内容 |
|---|---|
| **対応ブラウザ** | Chrome / Edge / Opera（デスクトップ / Android Chrome） |
| **非対応ブラウザ** | Safari（iOS / macOS）, Firefox（Web Bluetooth 未実装のため） |
| **配信要件** | HTTPS 必須（`localhost` は例外として HTTP でも可） |
| **通信プロトコル** | モバイル版と完全互換（19 バイト固定長パケット、50 ms 周期送信） |
| **対応ファームウェア** | [UGOKU-Pad Arduino Library](https://github.com/UGOKU-Lab/UGOKU-Pad_Arduino) |

## アーキテクチャ

BLE 通信層を抽象化し、プラットフォームに応じて実装を切り替えています。

```
lib/bluetooth/ble/
├── ble_types.dart          # 共通インターフェイス (DeviceHandle / CharacteristicHandle / BleAdapter)
├── ble_adapter.dart        # 条件付き import + シングルトン
├── ble_adapter_stub.dart   # フォールバック
├── ble_adapter_io.dart     # flutter_blue_plus 実装 (Android / iOS / Win / Mac / Linux)
└── ble_adapter_web.dart    # flutter_web_bluetooth 実装 (Web)
```

| プラットフォーム | 使用パッケージ | デバイス選択 UI |
|---|---|---|
| Android / iOS | `flutter_blue_plus` | アプリ内スキャンリスト |
| **Web** | `flutter_web_bluetooth` | **ブラウザのネイティブピッカー** |

UI 側は `bleAdapter.requiresBrowserPicker` で分岐するため、プラットフォーム固有のコードを意識する必要はありません。

## ビルドと起動

### 依存関係の解決

```bash
flutter pub get
```

> Dart SDK 3.11 以上、Flutter SDK 3.38 以上が必要です。古い場合は `flutter upgrade` を実行してください。

### 開発時 (Hot Reload あり)

```bash
flutter run -d chrome --web-port=8080
```

`flutter run -d chrome` が起動した Chrome インスタンスでのみ動作します。他ブラウザから `http://localhost:8080` にアクセスしても画面が真っ白になります（DDC が特定 Chrome に結びつくため）。

### 本番ビルド + 任意ブラウザでの確認

```bash
flutter build web
cd build/web
python -m http.server 8081
```

これで `http://localhost:8081` から任意のブラウザでアクセス可能です（Web Bluetooth 対応ブラウザに限る）。

### 公開デプロイ

```bash
# GitHub Pages 等のサブパス配信時
flutter build web --base-href "/ugoku-pad/"
```

ビルド成果物 `build/web/` を任意の HTTPS 配信先（GitHub Pages, Firebase Hosting, Cloudflare Pages 等）にアップロードしてください。

## 使い方

1. ESP32 側で UGOKU-Pad ファームウェアを書き込み起動しておく
2. ブラウザで Web 版 URL を開く
3. 任意のコンソールを作成または選択
4. 上部の **「Select」ボタン** → 「**接続**」ボタンをタップ
5. ブラウザの**デバイス選択ダイアログ**で UGOKU デバイスを選択
6. 接続確立後、ジョイスティック / スライダー / トグルスイッチ等のウィジェットを操作

## 既知の制約

| 制約 | 詳細 | 回避策 |
|---|---|---|
| 対応ブラウザが限定的 | Safari / Firefox は Web Bluetooth 未対応 | Chrome / Edge / Opera を使う |
| HTTPS 必須 | プライバシー保護のためのブラウザ仕様 | HTTPS ホスティング、または `localhost` |
| 自動再接続不可 | リロード後はピッカーで再選択が必要 | Web Bluetooth Permissions API の安定化待ち |
| パッシブスキャン不可 | ユーザー操作（クリック）が必須でブラウザ標準ピッカーのみ | 仕様上の制限 |
| Firebase Analytics 未設定 | `firebase_options.dart` 未生成 | `flutterfire configure` で Web 用設定を追加（任意） |

## 主要なBLE仕様

| 項目 | 値 |
|---|---|
| Service UUID | `4fafc201-1fb5-459e-8fcc-c5c9c331914b` |
| Characteristic UUID | `beb5483e-36e1-4688-b7f5-ea07361b26a8` |
| Properties | READ / WRITE / WRITE_NR / NOTIFY |
| パケット長 | 19 バイト固定（9 ペア × 2 バイト + 1 バイト XOR チェックサム）|
| 送信周期 | 50 ms |

UUID 定数は `lib/bluetooth/constants.dart` の `UgokuPadUuids` に定義されています。`UGOKU-Pad_Arduino/src/UGOKU-Pad_Definitions.h` と同期を保ってください。

## トラブルシューティング

### 画面が真っ白
- `flutter run -d chrome` で起動した Chrome 以外からアクセスしている → release ビルドを別ポートで配信して使う
- DevTools (F12) → Console タブのエラーを確認

### デバイスピッカーに UGOKU デバイスが出てこない
- ESP32 側で UGOKU-Pad ファームウェアが起動しアドバタイズ中か確認
- ESP32 と PC が物理的に近い距離にあるか確認
- Service UUID (`4fafc201-...`) が一致しているか確認

### 接続後すぐに切れる
- ブラウザ DevTools Console でエラーを確認
- ESP32 のシリアルモニタで通信ログを確認

### `setState() called after dispose()` エラー
- v2.1.5 以降で修正済み (toggle switch / button widget の dispose 漏れ)

## ライセンス

[GPLv3](./LICENSE)
