import 'package:flutter/material.dart';
import 'package:trustify_demo/widgets/BluetoothTransferPage.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<String> passkeys = [
    'Passkey 1',
    'Passkey 2',
    'Passkey 3',
    'Passkey 4',
    'Passkey 5'
  ];
  bool isLongPressActive = false;
  List<bool> selectetPasskeys = List<bool>.generate(5, (index) => false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trustify Wallet Demo'),
        backgroundColor: Colors.purple,
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
                      itemCount: passkeys.length,
                      itemBuilder: (context, index) {
                        return InkWell(
                          onLongPress: () {
                            setState(() {
                              isLongPressActive = true;
                            });
                          },
                          child: Stack(
                            children: [
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16.0),
                                child: Text(
                                  passkeys[index],
                                  style: const TextStyle(fontSize: 18.0),
                                ),
                              ),
                              Visibility(
                                visible: isLongPressActive,
                                child: Positioned(
                                  right: 0,
                                  child: Checkbox(
                                    value: selectetPasskeys[index],
                                    onChanged: (value) {
                                      setState(() {
                                        selectetPasskeys[index] = value!;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ],
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
                            selectetPasskeys.every((isSelected) => isSelected),
                        onChanged: (value) {
                          setState(() {
                            selectetPasskeys =
                                List.filled(selectetPasskeys.length, value!);
                          });
                        },
                      ),
                      Text(
                        'Select All',
                        style: TextStyle(fontSize: 16.0),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () {
                     //  Navigator.push(
                     //    context,
                     //    MaterialPageRoute(
                     //        builder: (context) => BluetoothTransferPage()),
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
