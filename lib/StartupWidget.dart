import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'console_page.dart';
import 'console_list_page.dart';
import 'console_panel/generation_parameter.dart';

/// Handles the startup process.
class StartupWidget extends StatelessWidget {
    /// The process to be done in the startup.
    late final _startup = SharedPreferences.getInstance().then((instance) async {
    final packageInfo = await PackageInfo.fromPlatform();
    final versionName   = packageInfo.version;
    final buildNumber   = packageInfo.buildNumber;
    final version    = '$versionName+$buildNumber';

    final savedVersion = instance.getString('version');

    final savedConsoles = instance
        .getStringList('consoles')
        ?.map((str) => ConsoleSaveObject.fromJson(jsonDecode(str)))
        .toList() ??
        [];

    if (savedVersion != version) {
      instance.setString('version', version);

      final sampleConsoles = [
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
        ConsoleSaveObject(
          'Sample: UGOKU One',
          ConsolePanelParameter(
            rows: 8,
            columns: 4,
            cells: [
              ConsolePanelCellParameter(
                  row: 0, column: 0, creator: 'Headline Text', property: {"text": "IMU"}),
              ConsolePanelCellParameter(
                  row: 0, column: 1, creator: 'Value Monitor', property: {"channel": "100"}),
              ConsolePanelCellParameter(
                  row: 0, column: 2, creator: 'Value Monitor', property: {"channel": "101"}),
              ConsolePanelCellParameter(
                  row: 0, column: 3, creator: 'Value Monitor', property: {"channel": "102"}),
              ConsolePanelCellParameter(
                  row: 1, column: 0, creator: 'Headline Text', property: {"text": "LED"}),
              ConsolePanelCellParameter(
                  row: 1, column: 1, creator: 'Toggle Switch', property: {"channel": "2"}),
              ConsolePanelCellParameter(
                  row: 1, column: 2, creator: 'Toggle Switch', property: {"channel": "4"}),
              ConsolePanelCellParameter(
                  row: 1, column: 3, creator: 'Toggle Switch', property: {"channel": "13"}),
              ConsolePanelCellParameter(
                  row: 2, column: 0, width: 4, creator: 'Headline Text', property: {"text": "サーボ"}),
              ConsolePanelCellParameter(
                  row: 3, column: 0, width: 2, height: 2, creator: 'Adjuster', property: {"channel": "27", "maxValue": 180.0, "initialValue": 90.0}),
              ConsolePanelCellParameter(
                  row: 3, column: 2, width: 2, height: 2,  creator: 'Adjuster', property: {"channel": "14", "maxValue": 180.0, "initialValue": 90.0}),
              ConsolePanelCellParameter(
                  row: 5, column: 0, width: 2, creator: 'Headline Text', property: {"text": "モータ"}),
              ConsolePanelCellParameter(
                  row: 5, column: 2, width: 2, creator: 'Button', property: {"channel": "23", "buttonText": "PWR OUT"}),
              ConsolePanelCellParameter(
                  row: 6, column: 0, width: 2, height: 2, creator: 'Joystick', property: {"channelY": "19"}),
              ConsolePanelCellParameter(
                  row: 6, column: 2, width: 2, height: 2, creator: 'Joystick', property: {"channelY": "17"}),
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
      ];

      for (final sample in sampleConsoles) {
        if (!savedConsoles.any((c) => c.title == sample.title)) {
          savedConsoles.add(sample);
        }
      }

      await instance.setStringList('consoles',
          savedConsoles.map((c) => jsonEncode(c.toJson())).toList());
    }

    // Return the recently used console.
    final recentlyUsed = instance.getString('recentlyUsed');

    if (recentlyUsed != null) {
      return ConsolePanelParameter.fromJson(jsonDecode(recentlyUsed));
    }

    if (savedConsoles.isNotEmpty) {
      return savedConsoles.first.parameter;
    }

    return ConsolePanelParameter.fromError(
        "No Console", "Please create a console from the menu.");
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

        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}