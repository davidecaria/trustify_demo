import 'package:flutter/material.dart';
import 'package:trustify_demo/widgets/HomePage.dart';
import 'package:trustify_demo/widgets/Login.dart';
import 'package:trustify_demo/model/Wallet.dart';
import 'package:trustify_demo/demoData/demoPasskey.dart';

void main() async {
  runApp(const MyApp());

  Wallet applicationWallet = Wallet();
  bool walletExists = await applicationWallet.readWalletKeyPair();

  if(!walletExists) {
    applicationWallet.initialize();
    await applicationWallet.storeWalletKeyPair();
  }

  await testPasskey.createCredential();
  applicationWallet.walletPasskeys?.add(testPasskey);

}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
