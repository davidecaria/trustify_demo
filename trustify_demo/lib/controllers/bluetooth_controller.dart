import 'dart:async';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class BluetoothController {
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;

  Function? onBluetoothStateChanged;

  BluetoothState get bluetoothState => _bluetoothState;

  List<dynamic> devices = List<DeviceWithAvailability>.empty(growable: true);

  // Availability
  StreamSubscription<BluetoothDiscoveryResult>? discoveryStreamSubscription;
  bool isDiscovering = false;

  void initState() {
    // Get current state
    FlutterBluetoothSerial.instance.state.then((state) {
      _bluetoothState = state;
      if (onBluetoothStateChanged != null) {
        onBluetoothStateChanged!();
      }
    });

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

  void dispose() {
    // FlutterBluetoothSerial.instance.setPairingRequestHandler(null);
  }

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

  void restartDiscovery() {
    isDiscovering = true;
    startDiscovery();
  }

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

enum DeviceAvailability {
  no,
  maybe,
  yes,
}

class DeviceWithAvailability {
  BluetoothDevice device;
  DeviceAvailability availability;
  int? rssi;

  DeviceWithAvailability(this.device, this.availability, [this.rssi]);
}
