export 'ble_types.dart';

import 'ble_types.dart';
import 'ble_adapter_stub.dart'
    if (dart.library.io) 'ble_adapter_io.dart'
    if (dart.library.js_interop) 'ble_adapter_web.dart' as impl;

BleAdapter? _cached;

/// Returns the platform-specific BLE adapter (singleton).
BleAdapter get bleAdapter => _cached ??= impl.createBleAdapter();
