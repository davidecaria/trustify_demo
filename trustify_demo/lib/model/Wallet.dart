/// This class represent the device-bounded Wallet.
import 'package:pointycastle/pointycastle.dart';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/export.dart';
import 'package:encrypt/encrypt.dart';
import '../utils/Crypto.dart' as crypto;
import 'Passkey.dart';

/// This class represent the device-bounded Wallet.
///
/// It is characterized by: an asymmetric key-pair [walletPublicKey], [walletPrivateKey] used to authenticate User and the device;
/// a [Set] of [Passkey] objects identified as [walletPasskeys]
class Wallet {
  //singleton instantiation
  static final Wallet _instance = Wallet._internal();
  RSAPublicKey? walletPublicKey;
  RSAPrivateKey? walletPrivateKey;
  Set<Passkey>? walletPasskeys;

  //default values
  Wallet._internal() {
    walletPublicKey = null;
    walletPrivateKey = null;
    walletPasskeys = {};
  }

  factory Wallet() {
    return _instance;
  }

  /// It allows the creation of a new [Wallet] object
  initialize() {
    AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> walletPair =
        crypto.generateRSAkeyPair(crypto.getSecureRandom());
    walletPublicKey = walletPair.publicKey;
    walletPrivateKey = walletPair.privateKey;
  }

  /// It allows to import a [List] of [Passkey] objects inside the [Wallet]
  void setPasskeys(List<Passkey> passkeysList) {
    for (var passkey in passkeysList) {
      walletPasskeys?.add(passkey);
    }
  }

  /// It allows to retrieve a [List] of each stored [Passkey] object corresponding [relyingPartyId]
  ///
  /// returns the [List] of [relyingPartyId]
  List<String> getPasskeysRpId() {
    List<String> passkeysRpId = [];

    for (var passkey in walletPasskeys!) {
      passkeysRpId.add(passkey.relyingPartyId);
    }

    return passkeysRpId;
  }

  /// It allows to add a new [Passkey] object inside [walletPasskeys]
  void addNewPasskey(Passkey newPasskey) {
    walletPasskeys?.add(newPasskey);
  }

  /// It allows to securely store, inside the device, the [Wallet] associated asymmettric key-pair
  Future<void> storeWalletKeyPair() async {
    await crypto.storeKeyPair("wallet_public_key", walletPublicKey!,
        "wallet_private_key", walletPrivateKey!);
  }

  /// It allows to read from the device secure storage the [Wallet] associated asymmettric key-pair
  ///
  /// Returns [bool] value representing success or failure of the operation
  Future<bool> readWalletKeyPair() async {
    List<String?> walletKeyPair =
        await crypto.readKeyPair("wallet_public_key", "wallet_private_key");

    if (walletKeyPair[0] == null || walletKeyPair[1] == null) {
      return false;
    }
    final pubKey = RSAKeyParser().parse(walletKeyPair[0]!) as RSAPublicKey;
    final privKey = RSAKeyParser().parse(walletKeyPair[1]!) as RSAPrivateKey;

    walletPublicKey = pubKey;
    walletPrivateKey = privKey;

    return true;
  }

  /// It allows to perform encryption with [walletPublicKey] of the provided parameter [plaintext]
  ///
  /// It returns the resulting ciphertext obtained by encrypting [plaintext]
  String walletEncrypt(String plaintext) {
    return crypto.rsaEncrypt(plaintext, walletPublicKey!);
  }

  /// It allows to perform decryption with [walletPublicKey] of the provided parameter [ciphertext]
  ///
  /// It returns the resulting plaintext obtained by decrypting [ciphertext]
  String walletDecrypt(String ciphertext) {
    return crypto.rsaDecrypt(ciphertext, walletPrivateKey!);
  }

  /// It allows to sign provided parameter [message] with [walletPrivateKey]
  ///
  /// It returns the resulting signature computed over [message]
  String walletSign(String message) {
    return crypto.rsaSign(message, walletPrivateKey!);
  }

  /// It allows to verify provided parameter [message] and [signature] with [walletPublicKey]
  ///
  /// It returns a [bool] value expressing success or failure of [signature] verification computed over [message]
  bool walletVerify(String signature, String message) {
    return crypto.rsaVerify(signature, message, walletPublicKey!);
  }
}
