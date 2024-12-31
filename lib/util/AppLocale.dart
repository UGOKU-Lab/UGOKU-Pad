mixin AppLocale {
  static const String privacy = 'privacy';
  static const String privacy_file = 'privacy_file';
  static const String privacy_agree = 'privacy_agree';
  static const String privacy_close = 'privacy_close';

  static const Map<String, dynamic> EN = {
    privacy: 'Terms of App & Privacy Policy',
    privacy_file: 'assets/privacy/privacy_policy_en.md',
    privacy_agree: 'Agree',
    privacy_close: 'Close',
  };

  static const Map<String, dynamic> JA = {
    privacy: '利用規約・プライバシーポリシー',
    privacy_file: 'assets/privacy/privacy_policy_ja.md',
    privacy_agree: '同意',
    privacy_close: '閉じる',
  };
}