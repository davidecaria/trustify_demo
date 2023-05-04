import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  //TODO: List of mock Passkeys objects to be displayed
  final List<String> passkeys = ['Passkey 1', 'Passkey 2', 'Passkey 3', 'Passkey 4', 'Passkey 5'];

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
                          onTap: () {
                            // TODO: Handle item click
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: Text(
                              passkeys[index],
                              style: const TextStyle(fontSize: 18.0),
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
    );
  }
}