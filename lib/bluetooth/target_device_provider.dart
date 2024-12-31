import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the target bluetooth device.
///
/// Change the state of the notifier to select the target device.
final targetDeviceProvider = StateProvider<BluetoothDevice?>((ref) {
  return null;
});

final targetCharacteristicProvider = StateProvider<BluetoothCharacteristic?>((ref) {
  return null;
});