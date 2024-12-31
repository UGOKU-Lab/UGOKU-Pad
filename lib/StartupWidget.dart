import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ugoku_console/privacy_page.dart';

import 'console_page.dart';
import 'console_list_page.dart';
import 'console_panel/generation_parameter.dart';

/// Handles the startup process.
class StartupWidget extends StatelessWidget {
    /// The process to be done in the startup.
    late final _startup = SharedPreferences.getInstance().then((instance) async {
    final packageInfo = await PackageInfo.fromPlatform();
    final version = packageInfo.version;

    print("Version: $version");

    final savedVersion = instance.getString('version');

    final savedConsoles = instance
        .getStringList('consoles')
        ?.map((str) => ConsoleSaveObject.fromJson(jsonDecode(str)))
        .toList() ??
        [];

    if (savedVersion != version) {
      instance.setString('version', version);

      final newlyCreatedWidgets = [
        ConsoleSaveObject(
          'Release Notes: $version',
          ConsolePanelParameter(
            rows: 1,
            columns: 1,
            cells: [
              ConsolePanelCellParameter(
                row: 0,
                column: 0,
                creator: 'Note',
                property: {
                  'title': 'Release Notes: $version',
                  'body':
                  'Welcome to the $version of the UGOKU Pad.\n'
                  'With this app, you can connect to a microcontroller such as ESP32 via Bluetooth and do various things such as operating the motor and displaying sensor values with a console created by yourself.\n'
                      '\n'
                      'This offers the following key features:\n'
                      '- Console creation\n'
                      '- Connection to your Bluetooth devices\n'
                      '- Control of the devices using BLE\n'
                      '\n'
                      '[url=https://ugoku-lab.github.io/ugokupad.html]How to use[/url]',
                  'body_ja':
                  'UGOKU Pad $versionへようこそ。\n'
                  'このアプリではESP32などのマイコンにBluetooth接続し、自分で作成したコンソールでモータの操作やセンサ値の表示など様々なことを行うことができます。\n'
                      '\n'
                  '主な機能：\n'
                  '- コンソールの作成\n'
                  '- Bluetoothデバイスへの接続\n'
                  '- BLEを使用したデバイスのコントロール\n'
                      '\n'
                  '使い方は[url=https://ugoku-lab.github.io/ugokupad.html]こちら[/url]'
                },
              ),
            ],
          ),
        ),
        ConsoleSaveObject(
          'Sample: Simple Controller',
          ConsolePanelParameter(
            rows: 2,
            columns: 2,
            cells: [
              ConsolePanelCellParameter(
                  row: 0, column: 0, creator: 'Slider', property: {}),
              ConsolePanelCellParameter(
                  row: 0, column: 1, creator: 'Toggle Switch', property: {}),
              ConsolePanelCellParameter(
                  row: 1, column: 0, creator: 'Joystick', property: {}),
              ConsolePanelCellParameter(
                  row: 1, column: 1, creator: 'Joystick', property: {}),
            ],
          ),
        ),
        ConsoleSaveObject(
          'Sample: PID Adjuster',
          ConsolePanelParameter(
            rows: 2,
            columns: 3,
            cells: [
              ConsolePanelCellParameter(
                  row: 0,
                  column: 0,
                  width: 2,
                  creator: 'Line Chart',
                  property: {}),
              ConsolePanelCellParameter(
                  row: 0, column: 2, creator: 'Value Monitor', property: {}),
              ConsolePanelCellParameter(
                  row: 1, column: 0, creator: 'Adjuster', property: {}),
              ConsolePanelCellParameter(
                  row: 1, column: 1, creator: 'Adjuster', property: {}),
              ConsolePanelCellParameter(
                  row: 1, column: 2, creator: 'Adjuster', property: {}),
            ],
          ),
        ),
        ConsoleSaveObject(
          'Sample: ESP32 Arduino Sample',
          ConsolePanelParameter(
            rows: 3,
            columns: 2,
            cells: [
              ConsolePanelCellParameter(
                  row: 0, column: 0, creator: 'Adjuster', property: {"channel": "3", "maxValue": 180.0}),
              ConsolePanelCellParameter(
                  row: 0, column: 1, creator: 'Toggle Switch', property: {"channel": "1"}),
              ConsolePanelCellParameter(
                  row: 1, column: 0, creator: 'Value Monitor', property: {"channel": "5"}),
              ConsolePanelCellParameter(
                  row: 1, column: 1, creator: 'Joystick', property: {"channelY": "2", "maxValueX": 180.0, "maxValueY": 180.0}),
              ConsolePanelCellParameter(
                  row: 2, column: 0, width: 2, creator: 'Line Chart', property: {"channel": "5", "maxValue": 50.0}),
            ],
          ),
        ),
      ];

      /*
      for (final newConsole in newlyCreatedWidgets) {
        while (savedConsoles.any((c) => c.title == newConsole.title)) {
          newConsole.title = '${newConsole.title}_';
        }
      }
      */

      for (final newConsole in newlyCreatedWidgets) {
        if (newConsole.title.startsWith("Release Notes:")) {
          // Remove any existing console that starts with "Release Notes:"
          savedConsoles.removeWhere((c) => c.title.startsWith("Release Notes:"));
          // Add the new "Release Notes:" console
          savedConsoles.add(newConsole);
        } else if (!savedConsoles.any((c) => c.title == newConsole.title)) {
          // If the title doesn't exist, add the console
          savedConsoles.add(newConsole);
        }
      }

      await instance.setStringList('consoles',
          savedConsoles.map((c) => jsonEncode(c.toJson())).toList());
    }

    // Return the recently used console.
    final recentlyUsed = instance.getString('recentlyUsed');

    return recentlyUsed != null
        ? ConsolePanelParameter.fromJson(jsonDecode(recentlyUsed))
        : savedConsoles
        .where((c) => c.title == 'Release Notes: $version')
        .first
        .parameter;
  });

  StartupWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _startup,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasData) {
            return ConsolePage(initialConsole: snapshot.data!);
          }
          if (snapshot.hasError) {
            return ConsolePage(
              initialConsole: ConsolePanelParameter.fromError(
                  "Startup Failed", "No console to be opened."),
            );
          }
        }

        return Container();
      },
    );
  }
}