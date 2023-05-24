import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';
import 'package:local_auth/local_auth.dart';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/asymmetric/api.dart';
import '../utils/crypto.dart';

class Passkey {

  late String passkeyId;

  //TEST
  late Uint8List passkeyIV;
  //TEST
  late Uint8List encryptedSecretKey;

  //used to generate attestation
  late String challenge;

  //rp
  late String relyingPartyName;
  late String relyingPartyId;

  //User
  late String userId;
  late String username;
  late String displayName;

  late String pubKeyCredParams;

  //excludeCredentials
  late String excludeCredentialsId;
  late String excludeCredentialsType;
  late String excludeCredentialsTransports;

  //authenticatorSelection
  late String authenticatorAttachment;
  late bool requireResidentKey;

  //passkey key-pair
  RSAPublicKey? passkeyPublicKey;
  RSAPrivateKey? passkeyPrivateKey;

  //end-to-end key
  Uint8List? endToEndKey;

  Passkey.empty() {
    userId = '';
    username = '';
    displayName = '';
    relyingPartyName = '';
    relyingPartyId = '';
  }

  Passkey({
    this.challenge = '',
    //This specifies support for ECDSA with P-256 and RSA PKCS#1 and supporting these gives complete coverage
    this.pubKeyCredParams = '[{"alg": -7, "type": "public-key"},{"alg": -257, "type": "public-key"}]',
    this.requireResidentKey = true,
    this.authenticatorAttachment = 'platform',
    this.excludeCredentialsId = '',
    this.excludeCredentialsType = 'public-key',
    this.excludeCredentialsTransports = '["internal"]',
    userId,
    username,
    displayName,
    relyingPartyName,
    relyingPartyId,
  }) {
    this.userId = userId!;
    this.username = username!;
    this.displayName = displayName!;
    this.relyingPartyName = relyingPartyName!;
    this.relyingPartyId = relyingPartyId!;
  }

  //set end-to-end key -> it will be used to retrieve the key and send to new device via bluetooth
  Future<void> readEndToEndKey(String passkeyId) async {
    final endToEndKeyId = "${passkeyId}_e2e";
    final endToEndKeyString = await readKeyValue(endToEndKeyId);
    endToEndKey =  Uint8List.fromList(utf8.encode(endToEndKeyString!));
  }

  // set passkeys key-pair
  Future<bool> readPasskeyKeyPair(String passkeyId) async {
    final passkeyPublicKeyId = "${passkeyId}_public";
    final passkeyPrivateKeyId = "${passkeyId}_private";

    List<String?> passkeyKeyPair = await readKeyPair(passkeyPublicKeyId, passkeyPrivateKeyId);

    if (passkeyKeyPair[0] == null || passkeyKeyPair[1] == null) {
      return false;
    }
    final pubKey = RSAKeyParser().parse(passkeyKeyPair[0]!) as RSAPublicKey;
    final privKey = RSAKeyParser().parse(passkeyKeyPair[1]!) as RSAPrivateKey;

    passkeyPublicKey = pubKey;
    passkeyPrivateKey = privKey;
    return true;
  }

  Future<bool> retrievePasskey(String relyingPartyId) async {
   try {
     final passkeyId = await readKeyValue(relyingPartyId);
     final credentialOption = await readKeyValue(passkeyId!);
     final Map<String, dynamic> jsonCredentialOption =  json.decode(credentialOption!);

     challenge = jsonCredentialOption['challenge'];
     relyingPartyName = jsonCredentialOption['rp']['name'];
     relyingPartyId = jsonCredentialOption['rp']['id'];
     userId = jsonCredentialOption['user']['id'];
     username = jsonCredentialOption['user']['name'];
     displayName = jsonCredentialOption['user']['displayName'];
     pubKeyCredParams = json.encode(jsonCredentialOption['pubKeyCredParams']);
     excludeCredentialsId = jsonCredentialOption['excludeCredentials'][0]['id'];
     excludeCredentialsType = jsonCredentialOption['excludeCredentials'][0]['type'];
     excludeCredentialsTransports = json.encode(jsonCredentialOption['excludeCredentials'][0]['transports']);
     authenticatorAttachment = jsonCredentialOption['authenticatorSelection']['authenticatorAttachment'];
     requireResidentKey = jsonCredentialOption['authenticatorSelection']['requireResidentKey'];

     // set key-pair
     final passkeyExists = await readPasskeyKeyPair(passkeyId);

      if(!passkeyExists) {
        return false;
      }

      return true;
   } catch(e) {
     return false;
   }
  }


  String getCredentialCreationOption() {
    String credentialCreationOption = '''
    {
      "challenge": "$challenge",
      "rp": {
        "name": "$relyingPartyName",
        "id": "$relyingPartyId"
      },
      "user": {
        "id": "$userId",
        "name": "$username",
        "displayName": "$displayName"
      },
      "pubKeyCredParams": $pubKeyCredParams,
      "excludeCredentials": [{"id":"$excludeCredentialsId", "type": "$excludeCredentialsType", "transports": $excludeCredentialsTransports}],
      "authenticatorSelection": {
        "authenticatorAttachment": "$authenticatorAttachment",
        "requireResidentKey": $requireResidentKey
      }
    }
  ''';
  return credentialCreationOption;
  }

  Future<bool> createCredential() async {
    try {

      final LocalAuthentication localAuth = LocalAuthentication();
      bool isAuthenticated = await localAuth.authenticate(
        localizedReason: 'Confirm to register a passkey for $relyingPartyName', // Reason shown to the user
      );

      if (isAuthenticated) {
        try {

          //if a passkey exists, just populate the calling istance without registering a new one
          final bool passkeyExists = await retrievePasskey(relyingPartyId);
          if(passkeyExists) {
            return false;
          }

          //navigator.credentials.create() uses publicKeyCredentialCreationOptions to create the key pair in standard webauthn
          AsymmetricKeyPair<RSAPublicKey,
              RSAPrivateKey> passkeyPair = generateRSAkeyPair(
              getSecureRandom());
          passkeyPublicKey = passkeyPair.publicKey;
          passkeyPrivateKey = passkeyPair.privateKey;

          //creating end-to-end key -> AES-256
          endToEndKey = generateAesKey(32);

          // creating passkey identifier
          passkeyId = getCredentialId();
          final credentialCreationOption = getCredentialCreationOption();

          // storing passkeyId under Relying party identifier for greater ease of use
          await storeKeyValue(relyingPartyId, passkeyId);

          // storing credentialCreationOption under a new generated passkey Identifier
          await storeKeyValue(passkeyId, credentialCreationOption);

          //storing end-to-end key
          final endToEndKeyId = "${passkeyId}_e2e";
          await storeKeyValue(endToEndKeyId, encodeCryptoMaterial(endToEndKey!));

          // storing key-pair
          final passkeyPublicKeyId = "${passkeyId}_public";
          final passkeyPrivateKeyId = "${passkeyId}_private";
          await storeKeyPair(passkeyPublicKeyId, passkeyPublicKey!, passkeyPrivateKeyId, passkeyPrivateKey!);

          // passkeys material must be sent server-side at this point
          passkeyIV = generateAesIV();
          final pemPrivateKey = encodePrivateKeyInPem(passkeyPrivateKey!);
          final passkeySecretKey = Uint8List.fromList(utf8.encode(pemPrivateKey));

          //must be sent to server
          encryptedSecretKey = aesCbcEncrypt(endToEndKey!, passkeyIV, passkeySecretKey);

          return true;

        } catch (e) {
          return false;
        }
      } else {
        // Fingerprint authentication failed or was canceled
        // Handle accordingly
        return false;
      }
    } catch (e) {
      // Handle any exceptions that occurred during authentication
      return false;
    }
  }

  String getCredentialId() {
    return getUuid();
  }


  Future<String?> authenticate(String challenge) async {
    try {
      final LocalAuthentication localAuth = LocalAuthentication();
      bool isAuthenticated = await localAuth.authenticate(
        localizedReason: 'Confirm to authenticate as $username to $relyingPartyName', // Reason shown to the user
      );

      if (isAuthenticated) {
        // Fingerprint authentication succeeded
        // Proceed with the protected operation
        return rsaSign(challenge, passkeyPrivateKey!);
      } else {
        // Fingerprint authentication failed or was canceled
        // Handle accordingly
        return null;
      }
    } catch (e) {
      // Handle any exceptions that occurred during authentication
      return null;
    }
  }
}
