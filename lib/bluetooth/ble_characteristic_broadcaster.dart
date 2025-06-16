import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../util/broadcaster/multi_channel_broadcaster.dart';
import 'ble_characteristic_representation_format.dart';
import 'constants.dart';

class BleStateChannel implements BroadcastChannel {
  int channelId;

  BleStateChannel(this.channelId);

  @override
  String get identifier => channelId.toString();

  @override
  String? get name => "#$channelId";

  @override
  String? get description => null;

  @override
  int get hashCode => identifier.hashCode;

  @override
  bool operator ==(Object other) {
    return other is BleStateChannel && other.identifier == identifier;
  }
}

class BleStateBroadcaster implements MultiChannelBroadcaster {
  /// Available channels.
  final List<BleStateChannel> channels;

  /// The BLE characteristic for communication.
  final BluetoothCharacteristic? characteristic;

  /// The stream that translates the binary data from the [characteristic] to the [_ValueOnChannel], then broadcasts to the branches.
  final _root = StreamController<_ValueOnChannel>.broadcast();

  /// The branches of root streams.
  final _branches = <BleStateChannel, _TwoWayStreamController<double, double>>{};

  final _sendDataMap = <BleStateChannel, int>{};
  final _receiveBuffer = <int>[];
  final _dataMap = <BleStateChannel, int>{};
  final _channelCache = <String, BleStateChannel?>{};

  late StreamSubscription<List<int>> _notificationSubscription;
  late Timer _periodicSendTimer;

  /// Creates a broadcaster using [characteristic].
  BleStateBroadcaster(
      this.channels, {
        this.characteristic, // Optional named parameter
      }) {
    // Enable notifications on the characteristic only if it's provided
    if (characteristic != null) {
      _setNotifications();
    }

    // Set the timer for periodic send
    _periodicSendTimer = Timer.periodic(
      const Duration(milliseconds: 50),
          (_) => _periodicSend(),
    );
  }

  Future<void> _setNotifications() async {
    await characteristic?.setNotifyValue(true);
    print('setNotifyValue(true) succeeded');

    // Listen to notifications
    _notificationSubscription =
        characteristic!.onValueReceived.listen(
            _distribute, onError: (error) {
          // Handle error
          print('Notification error: $error');
        });
  }

  /// Handle a full notification/read from the BLE characteristic.
  /// On both platforms, we expect exactly 19 bytes: 9×(channel, value) + 1×(checksum).
  void _distribute(List<int> data) {

    //print('*** Raw notification bytes: $data');

    _receiveBuffer.addAll(data);

    // Process in 19-byte chunks
    while (_receiveBuffer.length >= 19) {
      // Take the first 19 bytes
      final chunk = _receiveBuffer.sublist(0, 19);
      _receiveBuffer.removeRange(0, 19);

      // Verify XOR checksum: XOR of bytes[0..17] must equal bytes[18]
      int computedXor = 0;
      for (int i = 0; i < 18; i++) {
        computedXor ^= chunk[i];
      }
      if (computedXor != chunk[18]) {
        // Bad checksum: drop this packet entirely
        print('Bad checksum on incoming 19-byte packet.');
        continue;
      }

      // Parse each of the 9 (channel, value) pairs
      for (int i = 0; i < 9; i++) {
        final int ch = chunk[2 * i];     // byte indices: 0,2,4,...,16
        final int val = chunk[2 * i + 1]; // byte indices: 1,3,5,...,17

        // Emit only if this channel is in our “channels” list
        _root.sink.add(_ValueOnChannel(ch, val));
      }
    }
  }

  /// Called every 50 ms. Gathers up to 9 pending channel/value pairs, builds one
  /// 19-byte packet (9×(channel, value) + 1 checksum), and writes it.
  Future<void> _periodicSend() async {
    if (_sendDataMap.isEmpty || characteristic == null) return;

    try {
      final entries = _sendDataMap.entries.toList();
      int offset = 0;

      // We may need multiple 19-byte packets if more than 9 entries queued
      while (offset < entries.length) {
        final List<int> packetData = [];

        // Take up to 9 pairs from offset
        final chunk = entries.skip(offset).take(9).toList();
        for (final kv in chunk) {
          packetData.add(kv.key.channelId); // 1 byte for channel
          packetData.add(kv.value);         // 1 byte for value
        }

        // If < 9 pairs, pad the remainder with zeros so packetData length = 18
        while (packetData.length < 18) {
          packetData.add(0);
        }

        // Compute XOR over the first 18 bytes
        int xor = 0;
        for (final b in packetData) {
          xor ^= b;
        }
        // Append checksum as the 19th byte
        packetData.add(xor);

        // Send the full 19-byte packet
        final bool supportsWWR = characteristic!.properties.writeWithoutResponse;
        if (supportsWWR) {
          await characteristic!.write(Uint8List.fromList(packetData), withoutResponse: true);
        } else {
          await characteristic!.write(Uint8List.fromList(packetData));
        }

        offset += 9; // Move to next block of 9 entries (if any)
      }

      // Clear everything once we’ve sent
      _sendDataMap.clear();
    } catch (e) {
      print('Error in _periodicSend: $e');
    }
  }

  void dispose() {
    _periodicSendTimer.cancel();

    _notificationSubscription.cancel();
  }

  @override
  Stream<double>? streamOn(String channelId) {
    final channel = _getChannel(channelId);

    if (channel == null) {
      return null;
    }

    return _getBranch(channel)?.downward.stream;
  }

  /// Gets the sink on the [channel].
  @override
  Sink<double>? sinkOn(String channelId) {
    final channel = _getChannel(channelId);

    if (channel == null) {
      return null;
    }

    return _getBranch(channel)?.upward.sink;
  }

  @override
  double? read(String channelId) {
    final channel = _getChannel(channelId);

    if (channel == null) {
      return null;
    }

    return _dataMap[channel]?.toDouble();
  }

  BleStateChannel? _getChannel(String channelId) {
    if (_channelCache[channelId] == null) {
      _channelCache[channelId] = channels
          .where((channel) => channel.identifier == channelId)
          .firstOrNull;
    }

    return _channelCache[channelId];
  }

  _TwoWayStreamController<double, double>? _getBranch(BleStateChannel channel) {
    if (!_branches.containsKey(channel)) {
      final upward = StreamController<double>();
      final downward = StreamController<double>.broadcast();

      // Broadcast data to the branch by the channel.
      _root.stream
          .where((event) => event.channel == channel.channelId)
          .listen((event) {
        downward.sink.add(event.value.toDouble());

        // Store the data to the map.
        _dataMap[channel] = event.value;
      });

      // Pass data to the root with the channel.
      upward.stream.listen((event) {
        final value = event.floor();

        // Echo back to downward.
        downward.sink.add(event);

        // Store the data to the map.
        _sendDataMap[channel] = value;
        _dataMap[channel] = value;
      });

      _branches[channel] = (upward: upward, downward: downward);
    }

    return _branches[channel];
  }
}

/// The bundle of the 2 streams.
typedef _TwoWayStreamController<T, U> = ({
StreamController<T> upward,
StreamController<U> downward,
});

/// The [value] on the [channel].
///
/// Now sent/received in a 19‐byte block:
///
/// - Bytes 0–1   =  (channel0, value0)
/// - Bytes 2–3   =  (channel1, value1)
/// - …
/// - Bytes 16–17 =  (channel8, value8)
/// - Byte 18     =  XOR checksum of bytes 0..17
class _ValueOnChannel {
  final int channel; // Channel ID as an integer
  final int value;

  /// Creates a [value] on the [channel].
  _ValueOnChannel(this.channel, this.value);

  /// Parses a list of bytes to a [_ValueOnChannel].
  ///
  /// Returns null if the given list is an invalid sequence.
  static _ValueOnChannel? fromIntList(List<int> list) {
    if (list.length < 3) {
      return null;
    }

    final channel = list[0];
    final value = list[1];
    final checksum = list[2];

    if (channel ^ value != checksum) {
      return null;
    }

    return _ValueOnChannel(channel, value);
  }

  /// Converts to a byte list.
  Uint8List toUint8List() {
    final checksum = channel ^ value;
    return Uint8List.fromList([channel, value, checksum]);
  }
}
