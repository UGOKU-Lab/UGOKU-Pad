import 'dart:typed_data';

/// Platform-independent BLE device handle.
abstract class DeviceHandle {
  /// Stable identifier (MAC on mobile, opaque id on web).
  String get id;

  /// Human-readable device name (may be empty).
  String get name;

  /// Whether GATT is currently connected.
  bool get isConnected;

  /// Connection state changes.
  Stream<bool> get connectionState;

  Future<void> connect({Duration? timeout});

  Future<void> disconnect();

  /// Returns the characteristic identified by [serviceUuid] and
  /// [characteristicUuid]. Returns null if not found.
  Future<CharacteristicHandle?> getCharacteristic({
    required String serviceUuid,
    required String characteristicUuid,
  });
}

/// Platform-independent BLE characteristic handle.
abstract class CharacteristicHandle {
  String get uuid;

  /// True if the characteristic supports Write Without Response.
  bool get supportsWriteWithoutResponse;

  /// Enable notifications and return the stream of received values.
  /// The returned stream is broadcast.
  Future<Stream<List<int>>> startNotifications();

  Future<void> stopNotifications();

  /// Write [data] to the characteristic. When [withoutResponse] is true and
  /// the characteristic supports it, uses Write Without Response.
  Future<void> writeValue(Uint8List data, {bool withoutResponse = true});
}

/// Result of a passive scan (mobile only).
class ScanResultHandle {
  final DeviceHandle device;
  final int? rssi;

  const ScanResultHandle({required this.device, this.rssi});
}

/// Platform-independent BLE adapter.
abstract class BleAdapter {
  /// True if the platform supports passive scanning with results listing
  /// (mobile/desktop). False on web where only a browser-driven picker is
  /// available.
  bool get supportsScanning;

  /// True if the platform requires a browser picker (web).
  bool get requiresBrowserPicker;

  /// Stream of scan results. Empty/never on web.
  Stream<List<ScanResultHandle>> get scanResults;

  Stream<bool> get isScanning;

  Future<void> startScan({
    Duration? timeout,
    List<String> serviceUuids = const [],
  });

  Future<void> stopScan();

  /// Returns devices already connected at the OS level for any of
  /// [serviceUuids]. Empty on web.
  Future<List<DeviceHandle>> systemDevices(List<String> serviceUuids);

  /// Opens the browser picker and returns the chosen device. Throws on mobile
  /// where this flow is not used.
  Future<DeviceHandle?> requestDevice({
    required List<String> serviceUuids,
    List<String> optionalServiceUuids = const [],
  });

  /// Ensures any platform-level prerequisites are satisfied (e.g. Android
  /// runtime permissions). No-op on web.
  Future<bool> ensurePermissions();
}
