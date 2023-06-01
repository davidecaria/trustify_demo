import 'package:flutter/material.dart';
import 'package:trustify_demo/model/Passkey.dart';
import './BluetoothPage.dart';

class InspectPasskey extends StatefulWidget {
  final Passkey thisPasskey;

  const InspectPasskey({Key? key, required this.thisPasskey}) : super(key: key);

  @override
  _InspectPasskeyState createState() => _InspectPasskeyState();
}

class _InspectPasskeyState extends State<InspectPasskey> {
  bool isLoading = false;

  Future<void> handleAuthentication() async {
    setState(() {
      isLoading = true;
    });

    final authenticationResult = await widget.thisPasskey.authenticate();

    setState(() {
      isLoading = false;
    });

    if (authenticationResult) {
      const snackBar = SnackBar(
        content: Text("Authentication with Passkey successful"),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    } else {
      const snackBar = SnackBar(
        content: Text("Authentication with Passkey failed"),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
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
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Passkey',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Relying Party',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.thisPasskey.relyingPartyId,
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 30),
                const Text(
                  'Username',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.thisPasskey.username,
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 30),
                const Text(
                  'Credential ID',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.thisPasskey.passkeyId,
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 50),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: isLoading ? null : handleAuthentication,
                        child: Text('Authenticate'),
                      ),
                      const SizedBox(width: 20),
                      ElevatedButton(
                        onPressed: () async {
                          // Handle button 2 press
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                // TODO: pass the E2E key reference and retrive later
                                builder: (context) => BluetoothPage()),
                          );
                        },
                        child: const Text('Transfer'),
                      ),
                    ],
                  ),
                ),
                if (isLoading)
                  Center(
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
