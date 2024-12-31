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
  late Timer _periodicReadTimer;

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
      const Duration(milliseconds: 100),
          (_) => _periodicSend(),
    );

    if (Platform.isIOS) {
      // Set the timer for periodic read
      _periodicReadTimer = Timer.periodic(
          const Duration(milliseconds: 100), (timer) async {
        if (characteristic != null) {
          try {
            var value = await characteristic!.read();
            _distribute(
                value); // Process the value as you would in a notification
          } catch (error) {
            print('Error reading characteristic: $error');
          }
        } else {
          //print("Characteristic is not available.");
        }
      });
    }
  }

  Future<void> _setNotifications() async {
    if (Platform.isIOS) {
      // Check if notifications are supported
      if (characteristic!.properties.notify) {
        await characteristic?.setNotifyValue(true);

        // Listen to notifications
        _notificationSubscription =
            characteristic!.onValueReceived.listen(
                _distribute, onError: (error) {
              // Handle error
              print('Notification error: $error');
            });
      } else {
        // Handle the case where notifications are not supported
        print('Notifications not supported on this characteristic');
      }
    } else { // Android
      // Check if notifications are supported
      if (true) {//(characteristic!.properties.notify) {
        await characteristic?.setNotifyValue(true);

        // Listen to notifications
        _notificationSubscription =
            characteristic!.onValueReceived.listen(
                _distribute, onError: (error) {
              // Handle error
              print('Notification error: $error');
            });
      } else {
        // Handle the case where notifications are not supported
        print('Notifications not supported on this characteristic');
      }
    }
  }

  void _distribute(List<int> data) {
    _receiveBuffer.addAll(data);

    while (_receiveBuffer.length >= 3) {
      final bleData = _ValueOnChannel.fromIntList(_receiveBuffer);

      if (bleData != null) {
        // Push the data to the downward branches.
        _root.sink.add(bleData);
        _receiveBuffer.removeRange(0, 3);
      } else {
        // Discard first byte and go next.
        _receiveBuffer.removeAt(0);
      }
    }
  }

  Future<void> _periodicSend() async {
    try {
      // Make a copy of the entries to avoid concurrent modification during iteration
      final entriesCopy = Map.of(_sendDataMap);

      // Iterate over the copy and send data
      for (final entry in entriesCopy.entries) {
        final channelId = entry.key.channelId;
        final value = entry.value;

        // Prepare data to send
        final dataToSend = _ValueOnChannel(channelId, value).toUint8List();

        // Send the data to the device
        await characteristic?.write(dataToSend);
      }

      // Clear the original map after sending all the data
      _sendDataMap.clear();
    } catch (e) {
      // Handle any errors during the process
      print('Error in _periodicSend: $e');
    }
  }

  void dispose() {
    _periodicSendTimer.cancel();

    if (Platform.isIOS) {
      _periodicReadTimer.cancel();
    }

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
/// This will be sent/received in 3 bytes:
///
/// - The first byte is the [channel] (0-255);
/// - The second byte is the [value];
/// - The third byte is the XOR checksum of the [channel] and [value].
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
