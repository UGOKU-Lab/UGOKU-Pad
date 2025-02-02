import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ugoku_console/privacy_page.dart';

import 'bluetooth/device_connection_page.dart';
import 'bluetooth/service_provider.dart';
import 'bluetooth/target_device_provider.dart';
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

  bool _isFullScreen = false;

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
                    : const Text("No device connected",
                    style: TextStyle(fontStyle: FontStyle.italic)),
              ),
            ),
            latestTargetDevice != null
                ? OutlinedButton(
                onPressed: () {
                  // Try connecting to the device.
                  ref.read(targetDeviceProvider.notifier).state =
                      latestTargetDevice;
                },
                child: const Text("Connect"))
                : OutlinedButton(
                onPressed: () {
                  // Push the page to select the device.
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const DeviceConnectionPage()));
                },
                child: const Text("Select")),
          ]);
        }),
        actions: [
          _isFullScreen
              ? IconButton(
              onPressed: () {
                SystemChrome.setEnabledSystemUIMode(
                    SystemUiMode.edgeToEdge);
                setState(() {
                  _isFullScreen = false;
                });
              },
              icon: const Icon(Icons.fullscreen_exit))
              : IconButton(
              onPressed: () {
                SystemChrome.setEnabledSystemUIMode(
                    SystemUiMode.immersiveSticky);
                setState(() {
                  _isFullScreen = true;
                });
              },
              icon: const Icon(Icons.fullscreen))
        ],
        centerTitle: true,
        scrolledUnderElevation: 0,
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              child: Text("Settings"),
            ),
            ListTile(
              leading: const Icon(Icons.bluetooth),
              title: const Text("Device"),
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
              title: const Text("Console"),
              onTap: () async {
                // Pop the drawer.
                Navigator.of(context).pop();

                // Push a page for editing, then get the result.
                ConsolePanelParameter? result =
                await Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const ConsoleListPage(),
                ));

                // Create the selected console.
                if (mounted && result != null) {
                  setState(() {
                    _save = result;
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.history_edu),
              title: const Text("License"),
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
                        applicationLegalese: 'Copyright (c) 2024 UGOKU',
                      ),
                    ),
                  )),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.book),
              title: const Text("Terms"),
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
                : ConsoleErrorWidgetCreator.propertyNotDetermined,
          ));
    });
  }
}
