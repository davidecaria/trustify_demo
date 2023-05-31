import 'package:flutter/material.dart';
import 'package:trustify_demo/model/Wallet.dart';
import 'package:trustify_demo/demoData/demoPasskey.dart';
import '../model/Passkey.dart';
import 'InspectPasskey.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Wallet applicationWallet = Wallet();
  List<String> passkeysRPsId = [];
  bool isLongPressActive = false;
  List<bool> selectedPasskeys = [];
  List<Passkey?> passkeysList = [];

  @override
  void initState() {
    super.initState();

    passkeysList = applicationWallet.walletPasskeys!.toList();
    passkeysRPsId = applicationWallet.getPasskeysRpId();
    selectedPasskeys =
        List<bool>.generate(passkeysRPsId.length, (index) => false);
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
                    'Your Wallet',
                    style: TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16.0),
                  Align(
                      alignment: Alignment.center,
                      child: ElevatedButton(
                        onPressed: () async {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              String usernameInput =
                                  ""; // Variable to store user input
                              String relyingPartyNameInput = "";
                              return AlertDialog(
                                title: const Text('Synchronize a Passkey'),
                                content: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                        'Provide your credential information to synchronize your Passkey with this Wallet'),
                                    const SizedBox(height: 8.0),
                                    TextField(
                                      onChanged: (value) {
                                        relyingPartyNameInput =
                                            value; // Update the user input variable
                                      },
                                      decoration: const InputDecoration(
                                        hintText: 'Service name',
                                      ),
                                    ),
                                    TextField(
                                      onChanged: (value) {
                                        usernameInput =
                                            value; // Update the user input variable
                                      },
                                      decoration: const InputDecoration(
                                        hintText: 'Username',
                                      ),
                                    ),
                                  ],
                                ),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context)
                                          .pop(); // Close the dialog
                                    },
                                    child: const Text('Close'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      if (usernameInput == "" ||
                                          relyingPartyNameInput == "") {
                                        const snackBar = SnackBar(
                                          content: Text("Empty parameters"),
                                        );
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(snackBar);
                                      } else {
                                        //Passkey synchronization process
                                        Passkey synchronizedPasskey =
                                            Passkey.empty();

                                        final isSynchronized =
                                            await synchronizedPasskey
                                                .synchronize(
                                                    relyingPartyNameInput,
                                                    usernameInput);

                                        if (isSynchronized) {
                                          setState(() {
                                            applicationWallet.addNewPasskey(
                                                synchronizedPasskey);

                                            passkeysList = applicationWallet
                                                .walletPasskeys!
                                                .toList();
                                            passkeysRPsId = applicationWallet
                                                .getPasskeysRpId();
                                            selectedPasskeys =
                                                List<bool>.generate(
                                                    passkeysRPsId.length,
                                                    (index) => false);
                                          });
                                        } else {
                                          const snackBar = SnackBar(
                                            content:
                                                Text("Synchronization failed"),
                                          );
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(snackBar);
                                        }

                                        Navigator.of(context)
                                            .pop(); // Close the dialog
                                      }
                                    },
                                    child: const Text('Confirm'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        child: const Text('Synchronize a Passkey'),
                      )),
                  Expanded(
                    child: ListView.builder(
                      itemCount: passkeysRPsId.length,
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
                                  thisPasskey: passkeysList[index]!,
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
                                    passkeysRPsId[index],
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
