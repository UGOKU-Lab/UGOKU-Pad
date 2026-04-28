# CLAUDE.md

## プロジェクト概要
UGOKU Padは、ESP32などのマイコンをBluetooth(BLE)でスマートフォンと接続し操作するFlutterアプリ。ジョイスティック・スライダー・ボタンなどのウィジェットを組み合わせて操作パネルを作成できる。Android/iOS対応。

## ミッションとコンセプト
- **コンセプト**: 「うごくものづくりをもっと手軽に」
- **ミッション**: 電子工作やロボット開発のハードルを下げ、子供から大人まで誰もが「動かす楽しさ」を即座に体験できる未来を作る。

## ターゲットユーザー
- Arduinoを少し触ったことがある初心者（中学生〜大人）
- ロボット教室や教育機関
- プロトタイプを素早く作りたい研究者やエンジニア

## トーンと振る舞い
- **親しみやすく丁寧**: 専門用語を多用せず、直感的に理解できる平易な日本語を使う
- **プロアクティブ**: バグ修正だけでなく、ドキュメントの改善やUI/UX改善の提案も行う（ただし承認なしに実装しない）
- **モダンな美意識**: UI/UXやデザインは「プレミアム感」「ワクワク感」を重視した洗練されたスタイルを提案する

## 技術スタック
- **Flutter** (Dart, SDK ^3.11.0)
- **状態管理**: flutter_riverpod
- **BLE通信**: flutter_blue_plus
- **永続化**: shared_preferences
- **Firebase**: firebase_core, firebase_analytics
- **ローカライズ**: flutter_localization
- **ライセンス**: GPLv3

## プロジェクト構造
```
lib/
  main.dart                    # エントリーポイント、ローカリゼーション設定
  bluetooth/                   # BLE通信関連
  console_page.dart            # 操作パネル画面
  console_edit_page.dart       # パネル編集画面
  console_list_page.dart       # パネル一覧画面
  console_panel/               # パネルのセル・ウィジェット
  console_widget_creator/      # ウィジェット作成
  broadcaster_provider.dart    # データ送受信プロバイダー
  util/
    AppLocale.dart             # ローカライズ定義
    broadcaster/               # ブロードキャスター
    form/                      # フォーム関連
    widget/                    # ユーティリティウィジェット
  privacy_page.dart            # プライバシーポリシー表示
```

## BLE通信プロトコル
- チャンネル/バリューのペア(2バイト) × 9組 + チェックサム(1バイト) = **19バイト固定長パケット**
- 50ms間隔で `periodicSend()` により送信
- 9チャンネル超過分は自動的に複数パケットへ分割
- **プロトコル仕様変更時はファームウェア互換性への影響を明記し、事前承認を得ること**
- BLE通信の実装は [UGOKU-Pad Arduino Library](https://github.com/UGOKU-Lab/UGOKU-Pad_Arduino) との整合性を常に保つこと。パケット構造・チャンネル仕様・チェックサム計算など、通信プロトコルに関わる変更を行う際は必ずArduinoライブラリ側の実装を確認する

## 開発ルール

### 言語
- Claude Codeでは**日本語**で応答する
- **コード内のコメントは英語**で記述する

### コーディング方針
- 勝手な変更を加えない。指示に忠実に従う
- 改善案がある場合は「要約・理由・具体差分」の形式で提案し、承認後に実装する

### ローカライズ
- UI文言やユーザー向けメッセージを変更する場合は**日本語(ja)と英語(en)の両方**を用意する
- `lib/main.dart` のローカリゼーション方針を尊重する

### プライバシー
- `assets/privacy/privacy_policy_ja.md` と `assets/privacy/privacy_policy_en.md` の整合性を保つ
- プライバシー文言の変更は事前確認を必須とする

### 権限・動作確認
- 権限周り（位置情報/Bluetooth等）の挙動を変える場合はローカルで動作確認を行い、PRに再現手順を記載する

### セキュリティ
- キーストア・秘密鍵・APIキー等はリポジトリに含めない
- `key.properties.example` のようなテンプレートを利用し、本物の秘密はGitHub Secrets等で管理する

### ライセンス
- GPLv3。外部ライブラリ導入時はライセンス互換性に注意する

## よく使うコマンド
```bash
flutter pub get          # 依存関係の取得
flutter run              # アプリの実行
flutter build apk        # Android APKビルド
flutter build ios        # iOSビルド
flutter test             # テスト実行
flutter analyze          # 静的解析
```

## 関連リソース
- **GitHub Organization**: [UGOKU-Lab](https://github.com/UGOKU-Lab)
- **公式Webサイト**: [ugoku-lab.github.io](https://ugoku-lab.github.io/)
- **UGOKU Pad リポジトリ**: [UGOKU-Pad](https://github.com/UGOKU-Lab/UGOKU-Pad)
- **Arduino ライブラリ**: [UGOKU-Pad_Arduino](https://github.com/UGOKU-Lab/UGOKU-Pad_Arduino)
- **UGOKU One (ハードウェア)**: [UGOKU-One](https://github.com/UGOKU-Lab/UGOKU-One)
- **サンプルコード**: [UGOKU-One_Arduino_sample_for_UGOKU-Pad](https://github.com/UGOKU-Lab/UGOKU-One_Arduino_sample_for_UGOKU-Pad)
