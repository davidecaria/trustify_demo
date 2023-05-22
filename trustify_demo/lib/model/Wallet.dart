import 'package:pointycastle/pointycastle.dart';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/export.dart';
import 'package:encrypt/encrypt.dart';
import '../utils/crypto.dart';


class Wallet {
  //public key-pair
  static final Wallet _instance = Wallet._internal();

  RSAPublicKey? walletPublicKey;
  RSAPrivateKey? walletPrivateKey;

  Wallet._internal() {
    walletPublicKey = null;
    walletPrivateKey = null;
  }

  factory Wallet() {
    return _instance;
  }

  initialize() {
    AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> walletPair = generateRSAkeyPair(getSecureRandom());
    walletPublicKey = walletPair.publicKey;
    walletPrivateKey = walletPair.privateKey;
  }

  Future<void> storeWalletKeyPair() async {
    await storeKeyPair("wallet_public_key", walletPublicKey!, "wallet_private_key", walletPrivateKey!);
  }

  Future<bool> readWalletKeyPair() async {
    List<String?> walletKeyPair = await readKeyPair("wallet_public_key", "wallet_private_key");

    if(walletKeyPair[0] == null || walletKeyPair[1] == null) {
      return false;
    }
    final pubKey = RSAKeyParser().parse(walletKeyPair[0]!) as RSAPublicKey;
    final privKey = RSAKeyParser().parse(walletKeyPair[1]!) as RSAPrivateKey;

    walletPublicKey = pubKey;
    walletPrivateKey = privKey;

    return true;

  }

}
