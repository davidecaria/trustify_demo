import 'package:flutter/material.dart';
import 'package:trustify_demo/widgets/HomePage.dart';
import 'package:trustify_demo/widgets/Login.dart';
import 'package:trustify_demo/model/Wallet.dart';
import 'package:trustify_demo/demoData/demoPasskey.dart';

void main() async {
  runApp(const TrustifyClientDemo());

  Wallet applicationWallet = Wallet();
  bool walletExists = await applicationWallet.readWalletKeyPair();

  if (!walletExists) {
    applicationWallet.initialize();
    await applicationWallet.storeWalletKeyPair();
  }

  var isCreated = await testPasskey1.createCredential();
  if (isCreated) {
    applicationWallet.walletPasskeys?.add(testPasskey1);
  }

  isCreated = await testPasskey2.createCredential();
  if (isCreated) {
    applicationWallet.walletPasskeys?.add(testPasskey2);
  }
}

class TrustifyClientDemo extends StatelessWidget {
  const TrustifyClientDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trustify Wallet Demo',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomePage(),
    );
  }
}
