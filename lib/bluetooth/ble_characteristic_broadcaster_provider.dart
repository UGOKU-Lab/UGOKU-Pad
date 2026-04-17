import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ugoku_console/bluetooth/service_provider.dart';
import 'package:ugoku_console/bluetooth/target_device_provider.dart';

import 'ble_characteristic_broadcaster.dart';

final bleStateChannelProvider = Provider<Iterable<BleStateChannel>>((ref) {
  return List.generate(256, (index) => BleStateChannel(index));
});

/// Provides a broadcaster.
final bleStateBroadcasterProvider = Provider<BleStateBroadcaster>((ref) {
  ref.watch(servicesProvider);
  final channels = ref.watch(bleStateChannelProvider).toList();

  final characteristic = ref.watch(targetCharacteristicProvider);

  final broadcaster = characteristic == null
      ? BleStateBroadcaster(channels)
      : BleStateBroadcaster(channels, characteristic: characteristic);

  ref.onDispose(broadcaster.dispose);

  return broadcaster;
});
