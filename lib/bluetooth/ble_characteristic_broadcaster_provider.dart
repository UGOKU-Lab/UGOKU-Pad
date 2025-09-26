import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ugoku_console/bluetooth/service_provider.dart';
import 'package:ugoku_console/bluetooth/target_device_provider.dart';

import 'ble_characteristic_broadcaster.dart';

BleStateBroadcaster? _broadcaster;

final bleStateChannelProvider = Provider<Iterable<BleStateChannel>>((ref) {
  return List.generate(256, (index) => BleStateChannel(index));
});

/// Provides a broadcaster.
final bleStateBroadcasterProvider = Provider<BleStateBroadcaster>((ref) {
  final services = ref.watch(servicesProvider);
  final channels = ref.watch(bleStateChannelProvider).toList();

  // Log the channels
  print('bleStateChannelProvider Channels: $channels');

  final device = ref.watch(connectionTargetDeviceProvider);
  print('bleStateChannelProvider Device: $device');

  final characteristic = ref.watch(targetCharacteristicProvider);
  print('bleStateChannelProvider characteristic: $characteristic');

  // Dispose the previous broadcaster
  _broadcaster?.dispose();

  if (characteristic == null) {
    return BleStateBroadcaster(channels);
  } else {
    return BleStateBroadcaster(channels, characteristic: characteristic);
  }

});



