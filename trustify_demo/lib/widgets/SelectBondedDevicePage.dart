import 'package:flutter/material.dart';

import '../controllers/bluetooth_controller.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import './BluetoothDeviceListEntry.dart';

class SelectBondedDevicePage extends StatefulWidget {
  /// If true, on page start there is performed discovery upon the bonded devices.
  /// Then, if they are not avaliable, they would be disabled from the selection.
  final bool checkAvailability;
  final BluetoothController bluetoothController;

  const SelectBondedDevicePage(
      {required this.bluetoothController, this.checkAvailability = true});

  @override
  _SelectBondedDevicePage createState() => _SelectBondedDevicePage();
}

class _SelectBondedDevicePage extends State<SelectBondedDevicePage> {
  @override
  void initState() {
    super.initState();
    widget.bluetoothController.onBluetoothStateChanged = () => setState(() {});
    setupBondedDevicesList(widget.checkAvailability);
  }

  void setupBondedDevicesList(bool checkAvailability) {
    widget.bluetoothController.isDiscovering = checkAvailability;
    if (widget.bluetoothController.isDiscovering) {
      widget.bluetoothController.startDiscovery();
    }
    FlutterBluetoothSerial.instance
        .getBondedDevices()
        .then((List<BluetoothDevice> bondedDevices) {
      setState(() {
        widget.bluetoothController.devices = bondedDevices
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
    });
  }

  @override
  void dispose() {
    // Avoid memory leak (`setState` after dispose) and cancel discovery
    widget.bluetoothController.discoveryStreamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
// the code you provided me just now
    List<BluetoothDeviceListEntry> list = widget.bluetoothController.devices
        .map((_device) => BluetoothDeviceListEntry(
              device: _device.device,
              rssi: _device.rssi,
              enabled: _device.availability == DeviceAvailability.yes,
              onTap: () {
                Navigator.of(context).pop(_device.device);
              },
            ))
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Trustify Wallet Demo',
          style: TextStyle(
            color: Colors.purple,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: <Widget>[
          widget.bluetoothController.isDiscovering
              ? FittedBox(
                  child: Container(
                    margin: new EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  ),
                )
              : IconButton(
                  icon: Icon(Icons.replay),
                  onPressed: widget.bluetoothController.restartDiscovery,
                )
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.purple.shade400,
              Colors.purple.shade700,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            color: Colors.white,
            elevation: 4.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Select Device',
                      style: TextStyle(
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16.0),
                    Expanded(child: ListView(children: list)),
                  ]),
            ),
          ),
        ),
      ),
    );
  }
}
