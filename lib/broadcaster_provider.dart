import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ugoku_console/util/broadcaster/multi_channel_broadcaster.dart';

import 'bluetooth/ble_characteristic_broadcaster.dart';
import 'bluetooth/ble_characteristic_broadcaster_provider.dart';
import 'bluetooth/service_provider.dart';

/// Provides a multi-channel broadcaster for the current connection.
final broadcasterProvider = Provider<MultiChannelBroadcaster>((ref) {
  return ref.watch(bleStateBroadcasterProvider);
});

final availableChannelProvider = Provider<Iterable<BroadcastChannel>>((ref) {
  return ref.watch(bleStateChannelProvider);
});
