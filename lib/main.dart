import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ugoku_console/util/AppLocale.dart';

import 'StartupWidget.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  _registerLicenses();
  runApp(const ProviderScope(child: MyApp()));
}

bool _licensesRegistered = false;

void _registerLicenses() {
  if (_licensesRegistered) {
    return;
  }
  _licensesRegistered = true;

  LicenseRegistry.addLicense(() async* {
    final licenseText = await rootBundle.loadString('LICENSE');
    yield LicenseEntryWithLineBreaks(
      const <String>['UGOKU Pad'],
      licenseText,
    );
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final FlutterLocalization _localization = FlutterLocalization.instance;

  @override
  void initState() {

    // Get the device's current locale language code
    String deviceLanguage = ui.window.locale.languageCode;

    // Set the default language based on the device language
    String initLanguageCode = (deviceLanguage == 'ja') ? 'ja' : 'en';

    print('initLanguageCode: $initLanguageCode');

    _localization.init(
      mapLocales: [
        const MapLocale('en', AppLocale.EN),
        const MapLocale('ja', AppLocale.JA)
      ],
      initLanguageCode: initLanguageCode,
    );
    _localization.onTranslatedLanguage = _onTranslatedLanguage;
    super.initState();
  }

  // the setState function here is a must to add
  void _onTranslatedLanguage(Locale? locale) {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "UGOKU Pad",
      theme: ThemeData(
        //colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        colorScheme: ColorScheme.fromSeed(
          primary: const Color(0xFF673AB7),
          seedColor: Colors.deepPurple,
          surface: Colors.white,
        ),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      darkTheme: ThemeData.dark(useMaterial3: true),
      supportedLocales: _localization.supportedLocales,
      localizationsDelegates: _localization.localizationsDelegates,
      home: StartupWidget(),
    );
  }
}