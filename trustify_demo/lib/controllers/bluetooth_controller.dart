import 'dart:async';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

/// A controller for managing Bluetooth state and device discovery.
class BluetoothController {
  /// The current state of the Bluetooth adapter. Initially set to UNKNOWN
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;

  /// A callback function that is called when the Bluetooth state changes.
  Function? onBluetoothStateChanged;

  /// Returns the current state of the Bluetooth adapter.
  BluetoothState get bluetoothState => _bluetoothState;

  /// A list of available devices.
  List<dynamic> devices = List<DeviceWithAvailability>.empty(growable: true);

  // Listens to the stream of BluetoothDiscoveryResults returned by the startDiscovery()
  StreamSubscription<BluetoothDiscoveryResult>? discoveryStreamSubscription;

  /// A variable tracking whether the controller is currently discovering devices. Initially set to false
  bool isDiscovering = false;

  /// Initializes the controller and sets up listeners for Bluetooth state changes.
  void initState() {
    // Get current state
    FlutterBluetoothSerial.instance.state.then((state) {
      _bluetoothState = state;
      if (onBluetoothStateChanged != null) {
        onBluetoothStateChanged!();
      }
    });

    // Repeatedly check if the Bluetooth adapter is enabled
    Future.doWhile(() async {
      // Wait if adapter not enabled
      if ((await FlutterBluetoothSerial.instance.isEnabled) ?? false) {
        return false;
      }
      await Future.delayed(Duration(milliseconds: 200));
      return true;
    }).then((_) {
      // Handle completion
    });

    // Listen for further state changes
    FlutterBluetoothSerial.instance
        .onStateChanged()
        .listen((BluetoothState state) {
      _bluetoothState = state;
      if (onBluetoothStateChanged != null) {
        onBluetoothStateChanged!();
      }
    });
  }

  /// Disposes of the controller and any active listeners.
  void dispose() {
    // Remove any listeners set up in initState()
    FlutterBluetoothSerial.instance.setPairingRequestHandler(null);
  }

  /// Starts discovering available devices.
  void startDiscovery() {
    discoveryStreamSubscription =
        FlutterBluetoothSerial.instance.startDiscovery().listen((r) {
      Iterator i = devices.iterator;
      while (i.moveNext()) {
        var _device = i.current;
        if (_device.device == r.device) {
          _device.availability = DeviceAvailability.yes;
          _device.rssi = r.rssi;
        }
      }
    });

    discoveryStreamSubscription?.onDone(() {
      // Call setState here to update the list of bonded devices
      if (onBluetoothStateChanged != null) {
        onBluetoothStateChanged!();
      }
    });
  }

  /// Restarts the discovery process.
  void restartDiscovery() {
    isDiscovering = true;
    startDiscovery();
  }

  /// Sets up the list of bonded devices.
  ///
  /// If [checkAvailability] is `true`, the availability of each device will be checked.
  void setupBondedDevicesList(bool checkAvailability) {
    isDiscovering = checkAvailability;
    if (isDiscovering) {
      startDiscovery();
    }
    FlutterBluetoothSerial.instance
        .getBondedDevices()
        .then((List<BluetoothDevice> bondedDevices) {
      devices = bondedDevices
          .map(
            (device) => DeviceWithAvailability(
              device,
              checkAvailability
                  ? DeviceAvailability.maybe
                  : DeviceAvailability.yes,
            ),
          )
          .toList();
    });
  }
}

/// An enumeration of device availability states.
enum DeviceAvailability {
  no,
  maybe,
  yes,
}

/// A class representing a Bluetooth device with availability information.
class DeviceWithAvailability {
  /// The Bluetooth device.
  BluetoothDevice device;

  /// The availability of the device.
  DeviceAvailability availability;

  /// The received signal strength indicator (RSSI) of the device, if available.
  int? rssi;

  /// Creates a new [DeviceWithAvailability] with the given [device], [availability], and [rssi].
  DeviceWithAvailability(this.device, this.availability, [this.rssi]);
}
