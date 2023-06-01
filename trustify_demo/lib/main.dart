import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:trustify_demo/utils/Crypto.dart';
import 'package:trustify_demo/utils/Server.dart' as server;
import 'package:trustify_demo/widgets/Login.dart';
import 'package:trustify_demo/demoData/demoPasskey.dart' as demo;

import 'model/Wallet.dart';

void main() async {
  runApp(const TrustifyClientDemo());
  Wallet applicationWallet = Wallet();
  bool walletExists = await applicationWallet.readWalletKeyPair();

  if (!walletExists) {
    applicationWallet.initialize();
    await applicationWallet.storeWalletKeyPair();

    final b64PemWalletPublicKey = encodeCryptoMaterial(Uint8List.fromList(
        encodePublicKeyInPem(applicationWallet.walletPublicKey!).codeUnits));

    final requestBody = {"walletPublicKey": b64PemWalletPublicKey};

    // store user information server-side
    await server.newUser(requestBody);

    //DEMO storing server-side a demo passkey to be later synchronized with this wallet
    demo.demoPasskeySynchronize["walletPublicKey"] = b64PemWalletPublicKey;
    await server.registerPasskey(demo.demoPasskeySynchronize);
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
      home: const LoginForm(),
      debugShowCheckedModeBanner: false,
    );
  }
}
