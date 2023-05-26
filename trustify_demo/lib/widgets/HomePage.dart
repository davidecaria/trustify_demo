import 'package:flutter/material.dart';
import 'package:trustify_demo/model/Wallet.dart';
import 'package:trustify_demo/demoData/demoPasskey.dart';

import 'InspectPasskey.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Wallet applicationWallet = Wallet();
  List<String> passkeysRPsName = [];
  bool isLongPressActive = false;
  List<bool> selectedPasskeys = [];

  @override
  void initState() {
    super.initState();
    //TEST
    applicationWallet.setPasskeys(testPasskeysList);
    passkeysRPsName = applicationWallet.getPasskeysRpId();
    selectedPasskeys =
        List<bool>.generate(passkeysRPsName.length, (index) => false);
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
              Colors.purple.shade300,
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
                    'Your Wallet',
                    style: TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16.0),
                  Expanded(
                    child: ListView.builder(
                      itemCount: passkeysRPsName.length,
                      itemBuilder: (context, index) {
                        return InkWell(
                          onLongPress: () {
                            setState(() {
                              isLongPressActive = true;
                            });
                          },
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => InspectPasskey(
                                  thisPasskey:
                                      applicationWallet.walletPasskeys![index],
                                ),
                              ),
                            );
                          },
                          child: Align(
                            alignment: Alignment.center,
                            child: Stack(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16.0),
                                  child: Text(
                                    passkeysRPsName[index],
                                    style: const TextStyle(fontSize: 18.0),
                                  ),
                                ),
                                Visibility(
                                  visible: isLongPressActive,
                                  child: Positioned(
                                    right: 0,
                                    child: Checkbox(
                                      value: selectedPasskeys[index],
                                      onChanged: (value) {
                                        setState(() {
                                          selectedPasskeys[index] = value!;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: isLongPressActive
          ? BottomAppBar(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value:
                            selectedPasskeys.every((isSelected) => isSelected),
                        onChanged: (value) {
                          setState(() {
                            selectedPasskeys =
                                List.filled(selectedPasskeys.length, value!);
                          });
                        },
                      ),
                      const Text(
                        'Select All',
                        style: TextStyle(fontSize: 16.0),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Navigator.push(
                      //   context,
                      //   MaterialPageRoute(
                      //     builder: (context) => BluetoothTransferPage(),
                      //   ),
                      // );
                    },
                    child: const Text('Transfer'),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}
