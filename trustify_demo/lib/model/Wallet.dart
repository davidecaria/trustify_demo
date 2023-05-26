import 'package:pointycastle/pointycastle.dart';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/export.dart';
import 'package:encrypt/encrypt.dart';
import '../utils/crypto.dart';
import 'Passkey.dart';


class Wallet {
  //singleton instantiation
  static final Wallet _instance = Wallet._internal();
  RSAPublicKey? walletPublicKey;
  RSAPrivateKey? walletPrivateKey;
  List<Passkey>? walletPasskeys;

  //default values
  Wallet._internal() {
    walletPublicKey = null;
    walletPrivateKey = null;
    walletPasskeys = [];
  }

  factory Wallet() {
    return _instance;
  }

  initialize() {
    AsymmetricKeyPair<RSAPublicKey,
        RSAPrivateKey> walletPair = generateRSAkeyPair(getSecureRandom());
    walletPublicKey = walletPair.publicKey;
    walletPrivateKey = walletPair.privateKey;
  }

  void setPasskeys(List<Passkey> passkeysList) {
    for (var passkey in passkeysList) {
      walletPasskeys?.add(passkey);
    }
  }

  List<String> getPasskeysRpId() {
    List<String> passkeysRpId = [];

    for (var passkey in walletPasskeys!) {
        passkeysRpId.add(passkey.relyingPartyId);
      }

    return passkeysRpId;

  }


  Future<void> storeWalletKeyPair() async {
    await storeKeyPair(
        "wallet_public_key", walletPublicKey!, "wallet_private_key",
        walletPrivateKey!);
  }

  Future<bool> readWalletKeyPair() async {
    List<String?> walletKeyPair = await readKeyPair(
        "wallet_public_key", "wallet_private_key");

    if (walletKeyPair[0] == null || walletKeyPair[1] == null) {
      return false;
    }
    final pubKey = RSAKeyParser().parse(walletKeyPair[0]!) as RSAPublicKey;
    final privKey = RSAKeyParser().parse(walletKeyPair[1]!) as RSAPrivateKey;

    walletPublicKey = pubKey;
    walletPrivateKey = privKey;

    return true;
  }

  String walletEncrypt(String plaintext) {
    return rsaEncrypt(plaintext, walletPublicKey!);
  }

  String walletDecrypt(String ciphertext) {
    return rsaDecrypt(ciphertext, walletPrivateKey!);
  }

  String walletSign(String message) {
    return rsaSign(message, walletPrivateKey!);
  }

  bool walletVerify(String signature, String message) {
    return rsaVerify(signature, message, walletPublicKey!);
  }
}