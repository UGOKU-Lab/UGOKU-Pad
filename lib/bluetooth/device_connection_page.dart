import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ugoku_console/bluetooth/ble/ble_adapter.dart';
import 'package:ugoku_console/bluetooth/constants.dart';
import 'package:ugoku_console/bluetooth/service_provider.dart';
import 'package:ugoku_console/bluetooth/target_device_provider.dart';
import 'package:ugoku_console/util/AppLocale.dart';

/// The page to connect a bluetooth device.
class DeviceConnectionPage extends StatelessWidget {
  const DeviceConnectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(AppLocale.device_page_title.getString(context)),
        centerTitle: true,
      ),
      body: bleAdapter.requiresBrowserPicker
          ? const _WebPickerBody()
          : const _ScanBody(),
    );
  }
}

/// Mobile/desktop: scan + list devices.
class _ScanBody extends StatefulWidget {
  const _ScanBody();

  @override
  State<_ScanBody> createState() => _ScanBodyState();
}

class _ScanBodyState extends State<_ScanBody> {
  var _scanResults = <ScanResultHandle>[];
  var _systemDevices = <DeviceHandle>[];
  var _isScanning = false;
  late StreamSubscription _scanResultSubscription;
  late StreamSubscription _isScanningSubscription;

  @override
  void initState() {
    super.initState();

    _scanResultSubscription = bleAdapter.scanResults.listen((results) {
      _scanResults = results;
      if (mounted) setState(() {});
    });

    _isScanningSubscription = bleAdapter.isScanning.listen((isScanning) {
      _isScanning = isScanning;
      if (mounted) setState(() {});
    });

    _loadSystemDevices();
    _ensureAndStartScan();
  }

  Future<void> _loadSystemDevices() async {
    try {
      final devices = await bleAdapter.systemDevices([UgokuPadUuids.service]);
      if (!mounted) return;
      setState(() {
        _systemDevices = devices;
      });
    } catch (e) {
      debugPrint('systemDevices failed: $e');
    }
  }

  Future<void> _ensureAndStartScan() async {
    final granted = await bleAdapter.ensurePermissions();
    if (!granted) return;
    await _startDeviceScan();
  }

  @override
  void dispose() {
    _scanResultSubscription.cancel();
    _isScanningSubscription.cancel();
    bleAdapter.stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        final listedDevices = <DeviceHandle>{
          ..._systemDevices,
          ..._scanResults.map((r) => r.device),
        }.toList();

        if (listedDevices.isEmpty) {
          return Center(
            child: _isScanning
                ? const CircularProgressIndicator()
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(AppLocale.device_page_empty.getString(context)),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: _rescan,
                        child: Text(
                            AppLocale.device_page_scan.getString(context)),
                      ),
                    ],
                  ),
          );
        }

        return Consumer(
          builder: (context, ref, _) {
            final targetDeviceNotifier =
                ref.watch(targetDeviceProvider.notifier);
            final currentTargetDevice =
                ref.watch(connectionTargetDeviceProvider);
            final connectionStatus = ref.watch(servicesProvider).when(
                  data: (_) => 'established',
                  loading: () => 'negotiating',
                  error: (_, __) => 'error',
                );

            return Stack(
              children: [
                ListView.builder(
                  itemCount: listedDevices.length,
                  itemBuilder: (context, index) {
                    final DeviceHandle device = listedDevices[index];
                    return ListTile(
                      title: _buildDeviceTitle(device),
                      subtitle: _buildDeviceSubtitle(device),
                      enabled: connectionStatus != 'negotiating',
                      trailing: currentTargetDevice == device
                          ? connectionStatus == 'established'
                              ? const Icon(Icons.bluetooth_connected)
                              : connectionStatus == 'negotiating'
                                  ? const CircularProgressIndicator()
                                  : const Icon(Icons.error)
                          : null,
                      onTap: () async {
                        targetDeviceNotifier.state = null;
                        await Future.delayed(
                            const Duration(milliseconds: 100));
                        targetDeviceNotifier.state = device;
                      },
                    );
                  },
                ),
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FloatingActionButton(
                    onPressed: _isScanning ? null : _rescan,
                    child: const Icon(Icons.replay),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _rescan() async {
    // Refresh system-connected devices on rescan so devices paired after the
    // page opened (or missed by an initial race) appear without reopen.
    await _loadSystemDevices();
    await _startDeviceScan();
  }

  Future _startDeviceScan() async {
    if (_isScanning) return;
    await bleAdapter.startScan(
      timeout: const Duration(seconds: 15),
      serviceUuids: const [UgokuPadUuids.service],
    );
  }

  Widget _buildDeviceTitle(DeviceHandle device) {
    final text = device.name.isEmpty ? device.id : device.name;
    return Text(text);
  }

  Widget? _buildDeviceSubtitle(DeviceHandle device) {
    return device.name.isEmpty ? null : Text(device.id);
  }
}

/// Web: a single "Connect" button that opens the browser device picker.
class _WebPickerBody extends ConsumerStatefulWidget {
  const _WebPickerBody();

  @override
  ConsumerState<_WebPickerBody> createState() => _WebPickerBodyState();
}

class _WebPickerBodyState extends ConsumerState<_WebPickerBody> {
  bool _busy = false;
  String? _error;

  Future<void> _openPicker() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final device = await bleAdapter.requestDevice(
        serviceUuids: const [UgokuPadUuids.service],
        optionalServiceUuids: const [UgokuPadUuids.service],
      );
      if (!mounted) return;
      if (device != null) {
        ref.read(targetDeviceProvider.notifier).state = null;
        await Future.delayed(const Duration(milliseconds: 100));
        ref.read(targetDeviceProvider.notifier).state = device;
        if (mounted) Navigator.of(context).maybePop();
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final connectionStatus = ref.watch(servicesProvider).when(
          data: (_) => 'established',
          loading: () => 'negotiating',
          error: (_, __) => 'error',
        );

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bluetooth_searching, size: 64),
            const SizedBox(height: 16),
            Text(
              AppLocale.device_page_title.getString(context),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _busy ? null : _openPicker,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.bluetooth),
              label: Text(AppLocale.connect.getString(context)),
            ),
            const SizedBox(height: 12),
            if (connectionStatus == 'negotiating')
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                    AppLocale.device_page_connecting.getString(context)),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center),
              ),
            const SizedBox(height: 24),
            Text(
              AppLocale.device_page_web_requirement.getString(context),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
