import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

import './SelectBondedDevicePage.dart';
import '../controllers/bluetooth_controller.dart';

/// A page for managing Bluetooth state and device discovery.
class BluetoothPage extends StatefulWidget {
  @override
  _BluetoothPageState createState() => _BluetoothPageState();
}

/// The state for a [BluetoothPage].
class _BluetoothPageState extends State<BluetoothPage> {
  /// The [BluetoothController] used to manage Bluetooth state and device discovery.
  final BluetoothController _bluetoothController = BluetoothController();

  @override
  void initState() {
    super.initState();
    // Set up a callback function to be called when the Bluetooth state changes
    _bluetoothController.onBluetoothStateChanged = () {
      setState(() {});
    };
    // Initialize the Bluetooth controller
    _bluetoothController.initState();
  }

  @override
  void dispose() {
    // Dispose of the Bluetooth controller
    _bluetoothController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                    'Transmit E2E Key',
                    style: TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16.0),
                  Expanded(
                    child: ListView(
                      children: <Widget>[
                        SwitchListTile(
                          title: const Text('Enable Bluetooth'),
                          value: _bluetoothController.bluetoothState.isEnabled,
                          onChanged: (bool value) async {
                            if (value) {
                              await FlutterBluetoothSerial.instance
                                  .requestEnable();
                            } else {
                              await FlutterBluetoothSerial.instance
                                  .requestDisable();
                            }

                            // Wait for the Bluetooth state to update before calling setState
                            await Future.delayed(Duration(milliseconds: 500));
                            setState(() {});
                          },
                        ),
                        ListTile(
                          title: const Text('Bluetooth status'),
                          subtitle: Text(
                              _bluetoothController.bluetoothState.toString()),
                          trailing: ElevatedButton(
                            child: const Text('Settings'),
                            onPressed: () {
                              FlutterBluetoothSerial.instance.openSettings();
                            },
                          ),
                        ),
                        ListTile(
                          title: ElevatedButton(
                            child:
                                const Text('Select Paired Device and Transmit'),
                            onPressed: () async {
                              final BluetoothDevice? selectedDevice =
                                  await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) {
                                    return SelectBondedDevicePage(
                                      bluetoothController: _bluetoothController,
                                      checkAvailability: false,
                                    );
                                  },
                                ),
                              );

                              if (selectedDevice != null) {
                                print('Connect -> selected ' +
                                    selectedDevice.address);
                                // TODO
                              } else {
                                print('Connect -> no device selected');
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
