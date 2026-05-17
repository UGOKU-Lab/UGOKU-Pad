import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ble/ble_adapter.dart';

/// Provides the target bluetooth device.
///
/// Change the state of the notifier to select the target device.
final targetDeviceProvider = StateProvider<DeviceHandle?>((ref) {
  return null;
});

final targetCharacteristicProvider =
    StateProvider<CharacteristicHandle?>((ref) {
  return null;
});
