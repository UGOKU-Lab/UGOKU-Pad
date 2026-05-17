import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ble/ble_adapter.dart';
import 'constants.dart';
import 'target_device_provider.dart';

/// Whether the connection process is on-going.
bool _negotiating = false;

/// The connection target.
DeviceHandle? _connectionTargetDevice;

/// Provides the current target device associated with the [servicesProvider].
///
/// This filters the devices from [targetDeviceProvider] to keep the connection
/// process legal. Successors received during the connection process will be
/// ignored.
final connectionTargetDeviceProvider = Provider<DeviceHandle?>((ref) {
  final device = ref.watch(targetDeviceProvider);

  if (!_negotiating) {
    _connectionTargetDevice = device;
  }

  return _connectionTargetDevice;
});

/// Establishes the GATT connection and locates the UGOKU-Pad characteristic.
/// The Future completes when the characteristic is ready; the result is the
/// characteristic itself.
final servicesProvider = FutureProvider<CharacteristicHandle?>((ref) async {
  final device = ref.watch(connectionTargetDeviceProvider);

  // Check if the device is null and return null if so
  if (device == null) {
    ref.read(targetCharacteristicProvider.notifier).state = null;
    return null;
  }

  // Start the connection process
  _negotiating = true;

  CharacteristicHandle? characteristic;
  try {
    // Try to connect to the target device with a timeout
    await device.connect(timeout: const Duration(seconds: 10));

    // Listen for the connection state changes
    device.connectionState.listen((connected) {
      if (!connected) {
        // Unselect the target if disconnected
        if (ref.read(targetDeviceProvider) == device) {
          ref.read(targetDeviceProvider.notifier).state = null;
        }
      }
    });

    characteristic = await device.getCharacteristic(
      serviceUuid: UgokuPadUuids.service,
      characteristicUuid: UgokuPadUuids.characteristic,
    );

    if (characteristic == null) {
      throw StateError('UGOKU-Pad characteristic not found on device.');
    }
  } catch (error) {
    // Unselect the target device if an error occurs
    ref.read(targetDeviceProvider.notifier).state = null;
    ref.read(targetCharacteristicProvider.notifier).state = null;
    rethrow;
  } finally {
    // Set negotiating flag to false
    _negotiating = false;
  }

  ref.read(targetCharacteristicProvider.notifier).state = characteristic;
  return characteristic;
});
