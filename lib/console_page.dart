import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ugoku_console/privacy_page.dart';
import 'package:ugoku_console/util/AppLocale.dart';

import 'bluetooth/device_connection_page.dart';
import 'bluetooth/constants.dart';
import 'bluetooth/service_provider.dart';
import 'bluetooth/target_device_provider.dart';
import 'console_edit_page.dart';
import 'console_list_page.dart';
import 'console_panel/console_panel_widget.dart';
import 'console_panel/generation_parameter.dart';
import 'console_widget_creator/console_error_widget_creator.dart';
import 'console_widget_creator/console_widget_creator_factory_widget.dart';

/// The page to create the selected console.
class ConsolePage extends StatefulWidget {
  final ConsolePanelParameter initialConsole;
  const ConsolePage({super.key, required this.initialConsole});

  @override
  State<ConsolePage> createState() => _ConsolePageState();
}

class _ConsolePageState extends State<ConsolePage> {
  late ConsolePanelParameter _save = widget.initialConsole;

  String? _consoleTitle;

  /// The latest target device to connect.
  BluetoothDevice? latestTargetDevice;

  get child => null;

  @override
  void initState() {
    super.initState();

    checkPrivacyPolicyStatus();
  }

  Future<void> checkPrivacyPolicyStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? hasAccepted = prefs.getBool('hasAcceptedPrivacyPolicy');

    _consoleTitle = prefs.getString('recentlyUsedTitle') ?? _consoleTitle;

    //await Future.delayed(const Duration(seconds: 1));

    // Show PrivacyPage if the user hasn't accepted yet
    /*
    if (hasAccepted != true) {
      PackageInfo.fromPlatform().then(
            (packageInfo) => Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => Theme(
            data: Theme.of(context).copyWith(
                appBarTheme: const AppBarTheme(centerTitle: true)),
            child: const PrivacyPage(
            ),
          ),
        )),
      );
    }
    */

    if (hasAccepted != true) {
      PackageInfo.fromPlatform().then(
            (packageInfo) => showDialog(
          context: context,
          barrierDismissible: false,  // Prevents dismissal by tapping outside the dialog
          builder: (BuildContext context) {
            return Theme(
              data: Theme.of(context).copyWith(
                appBarTheme: const AppBarTheme(centerTitle: true),
              ),
              child: const PrivacyPage(),
            );
          },
        ),
      );
    }
  }

  Future<void> _openConsoleEditor() async {
    isEditingConsole = true;
    isAddingConsole = false;

    final prefs = await SharedPreferences.getInstance();
    final previousTitle = _consoleTitle ??
        prefs.getString('recentlyUsedTitle') ??
        AppLocale.live_console.getString(context);
    final initialSave = ConsoleSaveObject(
      previousTitle,
      _save.copy(),
    );

    final ConsoleSaveObject? result = await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ConsoleEditPage(save: initialSave),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    setState(() {
      _save = result.parameter;
      _consoleTitle = result.title;
    });

    final savedConsoles = prefs
        .getStringList("consoles")
        ?.map((json) => jsonDecode(json))
        .whereType<Map<String, dynamic>>()
        .map((map) => ConsoleSaveObject.fromJson(map))
        .toList();
    if (savedConsoles != null) {
      var index =
          savedConsoles.indexWhere((save) => save.title == previousTitle);
      if (index == -1) {
        index = savedConsoles.indexWhere((save) => save.title == result.title);
      }
      if (index == -1) {
        savedConsoles.add(ConsoleSaveObject(result.title, result.parameter));
      } else {
        savedConsoles[index] = ConsoleSaveObject(
          result.title,
          result.parameter,
        );
      }
      await prefs.setStringList(
        "consoles",
        savedConsoles.map((save) => jsonEncode(save.toJson())).toList(),
      );
    }
    await prefs.setString(
      'recentlyUsed',
      jsonEncode(result.parameter.toJson()),
    );
    await prefs.setString('recentlyUsedTitle', result.title);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer(builder: (context, ref, _) {
          // The bluetooth connection.
          final connection = ref.watch(servicesProvider);

          // The target device to connect.
          final connectionTargetDevice =
          ref.watch(connectionTargetDeviceProvider);

          // Display the latest target device.
          if (connectionTargetDevice != null) {
            latestTargetDevice = connectionTargetDevice;

            // Return the text.
            // The line through decoration will be applied if the connection is
            // not available.
            return Text(
              connectionTargetDevice.platformName.isEmpty
                  ? connectionTargetDevice.remoteId.str
                  : connectionTargetDevice.platformName,

              style: TextStyle(
                decoration: connection.when(
                  data: (data) => null,
                  error: (error, trace) => TextDecoration.lineThrough,
                  loading: () => TextDecoration.lineThrough,
                ),
                fontStyle: FontStyle.italic,
              ),
            );
          }

          // Return the text with an action button.
          return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Flexible(
              child: Padding(
                padding: const EdgeInsets.only(right: 5),
                child: latestTargetDevice != null
                  ? Text(
                  latestTargetDevice!.platformName,

                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    decoration: TextDecoration.lineThrough))
                  : Text(AppLocale.no_device.getString(context),
                  style: const TextStyle(fontStyle: FontStyle.italic)),
              ),
            ),
            const SizedBox(width: 8),
            latestTargetDevice != null
                ? OutlinedButton(
                onPressed: () {
                  // Try connecting to the device.
                  ref.read(targetDeviceProvider.notifier).state =
                      latestTargetDevice;
                },
                child: Text(AppLocale.connect.getString(context)))
                : OutlinedButton(
                onPressed: () {
                  // Push the page to select the device.
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const DeviceConnectionPage()));
                },
                child: Text(AppLocale.select.getString(context))),
          ]);
        }),
        actions: [
          IconButton(
            onPressed: () {
              _openConsoleEditor();
            },
            icon: const Icon(Icons.edit),
          ),
        ],
        centerTitle: true,
        scrolledUnderElevation: 0,
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              child: Text(AppLocale.settings.getString(context)),
            ),
            ListTile(
              leading: const Icon(Icons.bluetooth),
              title: Text(AppLocale.device.getString(context)),
              onTap: () {
                // Pop the drawer.
                Navigator.of(context).pop();

                // Push a page for the device connection.
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const DeviceConnectionPage(),
                ));
              },
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_customize),
              title: Text(AppLocale.console.getString(context)),
              onTap: () async {
                // Pop the drawer.
                Navigator.of(context).pop();

                // Push a page for editing, then get the result.
                ConsolePanelParameter? result =
                await Navigator.of(context).push(PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const ConsoleListPage(),
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) =>
                          child,
                ));

                // Create the selected console.
                if (mounted && result != null) {
                  final pref = await SharedPreferences.getInstance();
                  setState(() {
                    _save = result;
                    _consoleTitle =
                        pref.getString('recentlyUsedTitle') ?? _consoleTitle;
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.history_edu),
              title: Text(AppLocale.license.getString(context)),
              onTap: () {
                // Pop the drawer.
                Navigator.of(context).pop();

                // Show the license page.
                PackageInfo.fromPlatform().then(
                      (packageInfo) => Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => Theme(
                      data: Theme.of(context).copyWith(
                          appBarTheme: const AppBarTheme(centerTitle: true)),
                      child: LicensePage(
                        applicationName: packageInfo.appName,
                        applicationVersion: packageInfo.version,
                        applicationLegalese:
                            AppLocale.license_legalese.getString(context),
                      ),
                    ),
                  )),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.book),
              title: Text(AppLocale.terms.getString(context)),
              onTap: () {
                // Pop the drawer.
                Navigator.of(context).pop();

                // Show the license page.
                /*
                PackageInfo.fromPlatform().then(
                      (packageInfo) => Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => Theme(
                      data: Theme.of(context).copyWith(
                          appBarTheme: const AppBarTheme(centerTitle: true)),
                      child: const PrivacyPage(

                      ),
                    ),
                  )),
                );
                */

                PackageInfo.fromPlatform().then(
                      (packageInfo) => showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext context) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          appBarTheme: const AppBarTheme(centerTitle: true),
                        ),
                        child: const PrivacyPage(),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(5),
        child: ConsoleWidget(parameter: _save),
      ),
    );
  }
}

/// The widget that creates a console with the given [parameter].
class ConsoleWidget extends StatelessWidget {
  final ConsolePanelParameter parameter;

  /// Creates a functional console with the [parameter].
  const ConsoleWidget({
    super.key,
    required this.parameter,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Center(
          child: ConsolePanelWidget.fromParameter(
            parameter,
            constraints: constraints,
            cellContentBuilder: (context, cell) => cell.property != null
                ? ConsoleCreatorFactoryWidget.consoleBuilder(
              context,
              cell.creator,
              property: cell.property!,
            )
                : ConsoleErrorWidgetCreator.propertyNotDetermined(context),
          ));
    });
  }
}
