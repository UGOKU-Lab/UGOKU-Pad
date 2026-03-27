import 'dart:io';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ugoku_console/bluetooth/target_device_provider.dart';

import 'constants.dart';

/// Whether the connection process is on-going.
bool _negotiating = false;

/// The connection target.
BluetoothDevice? _connectionTargetDevice;

/// Provides the current target device associated with the [servicesProvider].
///
/// This filters the devices from [targetDeviceProvider] to keep the connection
/// process legal. Successors received during the connection process will be
/// ignored.
final connectionTargetDeviceProvider = Provider<BluetoothDevice?>((ref) {
  final device = ref.watch(targetDeviceProvider);

  if (!_negotiating) {
    _connectionTargetDevice = device;
  }

  return _connectionTargetDevice;
});

final servicesProvider = FutureProvider<List<BluetoothService>>((ref) async {
  final device = ref.watch(connectionTargetDeviceProvider);
  var services = <BluetoothService>[];

  // Check if the device is null and return an empty list if so
  if (device == null) {
    return [];
  }

  // Start the connection process
  _negotiating = true;

  try {
    // Try to connect to the target device with a timeout
    await device.connect(timeout: const Duration(seconds: 10));

    // Listen for the connection state changes
    device.connectionState.listen((event) {
      if (event == BluetoothConnectionState.disconnected) {
        // Unselect the target if disconnected
        if (ref.read(targetDeviceProvider) == device) {
          ref.read(targetDeviceProvider.notifier).state = null;
        }
      }
    });

    // Clear GATT cache for Android devices
    if (Platform.isAndroid) {
      device.clearGattCache();
    }

    // Discover services offered by the device
    services = await device.discoverServices();

    // Query descriptors from the services
    final descriptors = services
        .expand((service) => service.characteristics)
        .expand((characteristic) => characteristic.descriptors)
        .where((descriptor) {
      final uuid = descriptor.descriptorUuid.toString();

      // Check for specific descriptor UUID patterns
      return DescriptorUuidPatten.userDescription.hasMatch(uuid) ||
          DescriptorUuidPatten.presentationFormat.hasMatch(uuid) ||
          DescriptorUuidPatten.aggregationFormat.hasMatch(uuid);
    });

    // Read each descriptor asynchronously
    for (final descriptor in descriptors) {
      await descriptor.read();
    }

  } catch (error) {
    // Unselect the target device if an error occurs
    ref.read(targetDeviceProvider.notifier).state = null;
  } finally {
    // Set negotiating flag to false
    _negotiating = false;
  }


  BluetoothService lastservice = services.last;
  BluetoothCharacteristic lastCharacteristic = lastservice.characteristics.last;

  ref.read(targetCharacteristicProvider.notifier).state = lastCharacteristic;

  return services;
});
