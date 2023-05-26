import 'package:flutter/material.dart';
import 'package:trustify_demo/model/Passkey.dart';

class InspectPasskey extends StatelessWidget {
  final Passkey thisPasskey;

  const InspectPasskey({Key? key, required this.thisPasskey}) : super(key: key);

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
                  thisPasskey.relyingPartyId,
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 30),
                const Text(
                  'Username',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  thisPasskey.username,
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 30),
                const Text(
                  'Credential ID',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  thisPasskey.passkeyId,
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 50),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          // Handle button 1 press
                        },
                        child: const Text('Authenticate'),
                      ),
                      const SizedBox(width: 20),
                      ElevatedButton(
                        onPressed: () {
                          // Handle button 2 press
                        },
                        child: const Text('Transfer'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
