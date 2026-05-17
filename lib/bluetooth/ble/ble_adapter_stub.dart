import 'ble_types.dart';

/// Fallback used when neither dart:io nor dart:html is available.
BleAdapter createBleAdapter() {
  throw UnsupportedError('No BLE adapter available for this platform.');
}
