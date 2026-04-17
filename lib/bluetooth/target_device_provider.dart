import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the target bluetooth device.
///
/// Use [TargetDeviceNotifier.set] to select or clear the target device.
class TargetDeviceNotifier extends Notifier<BluetoothDevice?> {
  @override
  BluetoothDevice? build() => null;

  void set(BluetoothDevice? device) => state = device;
}

final targetDeviceProvider =
    NotifierProvider<TargetDeviceNotifier, BluetoothDevice?>(
  TargetDeviceNotifier.new,
);

class TargetCharacteristicNotifier
    extends Notifier<BluetoothCharacteristic?> {
  @override
  BluetoothCharacteristic? build() => null;

  void set(BluetoothCharacteristic? characteristic) => state = characteristic;
}

final targetCharacteristicProvider = NotifierProvider<
    TargetCharacteristicNotifier, BluetoothCharacteristic?>(
  TargetCharacteristicNotifier.new,
);
