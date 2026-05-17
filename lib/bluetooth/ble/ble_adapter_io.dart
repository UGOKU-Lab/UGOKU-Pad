import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import 'ble_types.dart';

BleAdapter createBleAdapter() => _IoBleAdapter();

class _IoBleAdapter implements BleAdapter {
  @override
  bool get supportsScanning => true;

  @override
  bool get requiresBrowserPicker => false;

  @override
  Stream<List<ScanResultHandle>> get scanResults =>
      FlutterBluePlus.scanResults.map((results) => results
          .map((r) => ScanResultHandle(
                device: _IoDeviceHandle(r.device),
                rssi: r.rssi,
              ))
          .toList());

  @override
  Stream<bool> get isScanning => FlutterBluePlus.isScanning;

  @override
  Future<void> startScan({
    Duration? timeout,
    List<String> serviceUuids = const [],
  }) async {
    if (Platform.isAndroid) {
      FlutterBluePlus.setLogLevel(LogLevel.none, color: false);
    }
    await FlutterBluePlus.startScan(
      timeout: timeout ?? const Duration(seconds: 15),
      withServices: serviceUuids.map((u) => Guid(u)).toList(),
    );
  }

  @override
  Future<void> stopScan() => FlutterBluePlus.stopScan();

  @override
  Future<List<DeviceHandle>> systemDevices(List<String> serviceUuids) async {
    final guids = serviceUuids.map((u) => Guid(u)).toList();
    final devices = await FlutterBluePlus.systemDevices(guids);
    return devices.map((d) => _IoDeviceHandle(d)).toList();
  }

  @override
  Future<DeviceHandle?> requestDevice({
    required List<String> serviceUuids,
    List<String> optionalServiceUuids = const [],
  }) {
    throw UnsupportedError(
        'requestDevice() is only available on web. Use scan + systemDevices on this platform.');
  }

  @override
  Future<bool> ensurePermissions() async {
    if (!Platform.isAndroid) {
      return true;
    }
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();
    return statuses[Permission.bluetoothScan]!.isGranted &&
        statuses[Permission.bluetoothConnect]!.isGranted;
  }
}

class _IoDeviceHandle implements DeviceHandle {
  final BluetoothDevice _device;

  _IoDeviceHandle(this._device);

  @override
  String get id => _device.remoteId.str;

  @override
  String get name => _device.platformName;

  @override
  bool get isConnected => _device.isConnected;

  @override
  Stream<bool> get connectionState => _device.connectionState
      .map((state) => state == BluetoothConnectionState.connected);

  @override
  Future<void> connect({Duration? timeout}) =>
      _device.connect(timeout: timeout ?? const Duration(seconds: 10));

  @override
  Future<void> disconnect() => _device.disconnect();

  @override
  Future<CharacteristicHandle?> getCharacteristic({
    required String serviceUuid,
    required String characteristicUuid,
  }) async {
    if (Platform.isAndroid) {
      try {
        await _device.clearGattCache();
      } catch (e) {
        debugPrint('clearGattCache failed: $e');
      }
    }
    final services = await _device.discoverServices();
    final targetServiceGuid = Guid(serviceUuid);
    final targetCharGuid = Guid(characteristicUuid);

    for (final s in services) {
      if (s.serviceUuid != targetServiceGuid) continue;
      for (final c in s.characteristics) {
        if (c.characteristicUuid == targetCharGuid) {
          return _IoCharacteristicHandle(c);
        }
      }
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is _IoDeviceHandle && other._device.remoteId == _device.remoteId;

  @override
  int get hashCode => _device.remoteId.hashCode;
}

class _IoCharacteristicHandle implements CharacteristicHandle {
  final BluetoothCharacteristic _characteristic;
  StreamController<List<int>>? _controller;
  StreamSubscription<List<int>>? _subscription;

  _IoCharacteristicHandle(this._characteristic);

  @override
  String get uuid => _characteristic.characteristicUuid.toString();

  @override
  bool get supportsWriteWithoutResponse =>
      _characteristic.properties.writeWithoutResponse;

  @override
  Future<Stream<List<int>>> startNotifications() async {
    if (_controller != null) {
      return _controller!.stream;
    }
    final controller = StreamController<List<int>>.broadcast(
      onCancel: () async {
        await _subscription?.cancel();
        _subscription = null;
      },
    );
    _controller = controller;

    await _characteristic.setNotifyValue(true);
    _subscription = _characteristic.onValueReceived.listen(
      controller.add,
      onError: (Object e) => debugPrint('Notification error: $e'),
    );
    return controller.stream;
  }

  @override
  Future<void> stopNotifications() async {
    await _subscription?.cancel();
    _subscription = null;
    await _controller?.close();
    _controller = null;
    try {
      await _characteristic.setNotifyValue(false);
    } catch (_) {
      // device may be disconnected already
    }
  }

  @override
  Future<void> writeValue(Uint8List data, {bool withoutResponse = true}) {
    final useWwr = withoutResponse && supportsWriteWithoutResponse;
    return _characteristic.write(data, withoutResponse: useWwr);
  }
}
