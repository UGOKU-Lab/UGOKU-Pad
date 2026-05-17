import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_web_bluetooth/flutter_web_bluetooth.dart' as fwb;
import 'package:flutter_web_bluetooth/js_web_bluetooth.dart' as jswb;

import 'ble_types.dart';

BleAdapter createBleAdapter() => _WebBleAdapter();

class _WebBleAdapter implements BleAdapter {
  @override
  bool get supportsScanning => false;

  @override
  bool get requiresBrowserPicker => true;

  @override
  Stream<List<ScanResultHandle>> get scanResults =>
      const Stream<List<ScanResultHandle>>.empty();

  @override
  Stream<bool> get isScanning => Stream<bool>.value(false);

  @override
  Future<void> startScan({
    Duration? timeout,
    List<String> serviceUuids = const [],
  }) async {
    // Web Bluetooth has no passive scanning; nothing to do.
  }

  @override
  Future<void> stopScan() async {}

  @override
  Future<List<DeviceHandle>> systemDevices(List<String> serviceUuids) async {
    return const [];
  }

  @override
  Future<DeviceHandle?> requestDevice({
    required List<String> serviceUuids,
    List<String> optionalServiceUuids = const [],
  }) async {
    if (!fwb.FlutterWebBluetooth.instance.isBluetoothApiSupported) {
      throw StateError(
          'Web Bluetooth is not available. Use Chrome/Edge/Opera over HTTPS.');
    }
    final filters = [
      fwb.RequestFilterBuilder(services: serviceUuids),
    ];
    final options = fwb.RequestOptionsBuilder(
      filters,
      optionalServices: optionalServiceUuids,
    );
    try {
      final device = await fwb.FlutterWebBluetooth.instance.requestDevice(options);
      return _WebDeviceHandle(device);
    } on jswb.UserCancelledDialogError {
      // User dismissed the picker; treat as a no-op.
      return null;
    } on jswb.DeviceNotFoundError {
      // No matching device available; treat as a no-op.
      return null;
    }
  }

  @override
  Future<bool> ensurePermissions() async => true;
}

class _WebDeviceHandle implements DeviceHandle {
  final fwb.BluetoothDevice _device;

  _WebDeviceHandle(this._device);

  @override
  String get id => _device.id;

  @override
  String get name => _device.name ?? '';

  @override
  bool get isConnected => _device.hasGATT;

  @override
  Stream<bool> get connectionState => _device.connected;

  @override
  Future<void> connect({Duration? timeout}) =>
      _device.connect(timeout: timeout ?? const Duration(seconds: 10));

  @override
  Future<void> disconnect() async {
    _device.disconnect();
  }

  @override
  Future<CharacteristicHandle?> getCharacteristic({
    required String serviceUuid,
    required String characteristicUuid,
  }) async {
    final services = await _device.discoverServices();
    final lowerService = serviceUuid.toLowerCase();
    fwb.BluetoothService? target;
    for (final s in services) {
      if (s.uuid.toLowerCase() == lowerService) {
        target = s;
        break;
      }
    }
    if (target == null) return null;
    try {
      final ch = await target.getCharacteristic(characteristicUuid);
      return _WebCharacteristicHandle(ch);
    } catch (e) {
      debugPrint('getCharacteristic failed: $e');
      return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is _WebDeviceHandle && other._device.id == _device.id;

  @override
  int get hashCode => _device.id.hashCode;
}

class _WebCharacteristicHandle implements CharacteristicHandle {
  final fwb.BluetoothCharacteristic _characteristic;
  StreamController<List<int>>? _controller;
  StreamSubscription<ByteData>? _subscription;

  _WebCharacteristicHandle(this._characteristic);

  @override
  String get uuid => _characteristic.uuid;

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

    await _characteristic.startNotifications();
    _subscription = _characteristic.value.listen(
      (bd) => controller.add(bd.buffer
          .asUint8List(bd.offsetInBytes, bd.lengthInBytes)
          .toList()),
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
      await _characteristic.stopNotifications();
    } catch (_) {
      // device may be disconnected already
    }
  }

  @override
  Future<void> writeValue(Uint8List data, {bool withoutResponse = true}) {
    final useWwr = withoutResponse && supportsWriteWithoutResponse;
    return useWwr
        ? _characteristic.writeValueWithoutResponse(data)
        : _characteristic.writeValueWithResponse(data);
  }
}
