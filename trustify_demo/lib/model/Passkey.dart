import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';
import 'package:local_auth/local_auth.dart';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:trustify_demo/model/Wallet.dart';
import '../utils/Crypto.dart' as crypto;
import '../utils/Server.dart' as server;
import '../demoData/demoPasskey.dart' as demo;

const apiBaseUrl = "http://192.168.1.6:3001";
const authenticateUrl = "/api/authenticate";
const registerUrl = "/api/register";

Wallet applicationWallet = Wallet();

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
    pubKeyCredParams =
        '[{"alg": -7, "type": "public-key"},{"alg": -257, "type": "public-key"}]';
    requireResidentKey = true;
    authenticatorAttachment = 'platform';
    this.excludeCredentialsId = '';
    this.excludeCredentialsType = 'public-key';
    this.excludeCredentialsTransports = '["internal"]';
  }

  Passkey({
    this.challenge = '',
    //This specifies support for ECDSA with P-256 and RSA PKCS#1 and supporting these gives complete coverage
    this.pubKeyCredParams =
        '[{"alg": -7, "type": "public-key"},{"alg": -257, "type": "public-key"}]',
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
    final endToEndKeyString = await crypto.readKeyValue(endToEndKeyId);
    endToEndKey = Uint8List.fromList(utf8.encode(endToEndKeyString!));
  }

  // set passkeys key-pair
  Future<bool> readPasskeyKeyPair(String passkeyId) async {
    final passkeyPublicKeyId = "${passkeyId}_public";
    final passkeyPrivateKeyId = "${passkeyId}_private";

    List<String?> passkeyKeyPair =
        await crypto.readKeyPair(passkeyPublicKeyId, passkeyPrivateKeyId);

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
      final passkeyId = await crypto.readKeyValue(relyingPartyId);
      final credentialOption = await crypto.readKeyValue(passkeyId!);
      final Map<String, dynamic> jsonCredentialOption =
          json.decode(credentialOption!);

      challenge = jsonCredentialOption['challenge'];
      relyingPartyName = jsonCredentialOption['rp']['name'];
      relyingPartyId = jsonCredentialOption['rp']['id'];
      userId = jsonCredentialOption['user']['id'];
      username = jsonCredentialOption['user']['name'];
      displayName = jsonCredentialOption['user']['displayName'];
      pubKeyCredParams = json.encode(jsonCredentialOption['pubKeyCredParams']);
      excludeCredentialsId =
          jsonCredentialOption['excludeCredentials'][0]['id'];
      excludeCredentialsType =
          jsonCredentialOption['excludeCredentials'][0]['type'];
      excludeCredentialsTransports = json
          .encode(jsonCredentialOption['excludeCredentials'][0]['transports']);
      authenticatorAttachment = jsonCredentialOption['authenticatorSelection']
          ['authenticatorAttachment'];
      requireResidentKey =
          jsonCredentialOption['authenticatorSelection']['requireResidentKey'];

      // set key-pair
      final passkeyExists = await readPasskeyKeyPair(passkeyId);

      if (!passkeyExists) {
        return false;
      }

      this.passkeyId = passkeyId;

      return true;
    } catch (e) {
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
        localizedReason:
            'Confirm to register a passkey for $relyingPartyId', // Reason shown to the user
      );

      if (isAuthenticated) {
        try {
          //if a passkey exists, just populate the calling istance without registering a new one
          final bool passkeyExists = await retrievePasskey(relyingPartyId);

          if (passkeyExists) {
            return false;
          }

          //navigator.credentials.create() uses publicKeyCredentialCreationOptions to create the key pair in standard webauthn
          AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> passkeyPair =
              crypto.generateRSAkeyPair(crypto.getSecureRandom());
          passkeyPublicKey = passkeyPair.publicKey;
          passkeyPrivateKey = passkeyPair.privateKey;

          //creating end-to-end key -> AES-256
          endToEndKey = crypto.generateAesKey(32);

          // creating passkey identifier
          passkeyId = getNewCredentialId();
          final credentialCreationOption = getCredentialCreationOption();

          // storing passkeyId under Relying party identifier for ease of use
          await crypto.storeKeyValue(relyingPartyId, passkeyId);

          // storing credentialCreationOption under a new generated passkey Identifier
          await crypto.storeKeyValue(passkeyId, credentialCreationOption);

          //storing end-to-end key
          final endToEndKeyId = "${passkeyId}_e2e";
          await crypto.storeKeyValue(
              endToEndKeyId, crypto.encodeCryptoMaterial(endToEndKey!));

          // storing key-pair
          final passkeyPublicKeyId = "${passkeyId}_public";
          final passkeyPrivateKeyId = "${passkeyId}_private";
          await crypto.storeKeyPair(passkeyPublicKeyId, passkeyPublicKey!,
              passkeyPrivateKeyId, passkeyPrivateKey!);

          // passkeys material must be sent server-side at this point
          passkeyIV = crypto.generateAesIV();
          final pemPrivateKey =
              crypto.encodePrivateKeyInPem(passkeyPrivateKey!);
          final passkeySecretKey =
              Uint8List.fromList(utf8.encode(pemPrivateKey));

          //must be sent to server
          final b64encryptedPemSecretKeyE2E = crypto.encodeCryptoMaterial(
              crypto.aesCbcEncrypt(endToEndKey!, passkeyIV, passkeySecretKey));

          final b64PemPublicKey = crypto.encodeCryptoMaterial(
              Uint8List.fromList(
                  crypto.encodePublicKeyInPem(passkeyPublicKey!).codeUnits));
          final passkeySignature =
              applicationWallet.walletSign(credentialCreationOption);
          final b64PemWalletPublicKey = crypto.encodeCryptoMaterial(
              Uint8List.fromList(crypto
                  .encodePublicKeyInPem(applicationWallet.walletPublicKey!)
                  .codeUnits));

          final requestBody = {
            "walletPublicKey": b64PemWalletPublicKey,
            "relyingPartyId": relyingPartyId,
            "relyingPartyName": relyingPartyName,
            "username": username,
            "passkeyPublicKey": b64PemPublicKey,
            "passkeySecretKeyE2E": b64encryptedPemSecretKeyE2E,
            "passkeySignature": passkeySignature
          };

          final isPasskeyStored = await server.registerPasskey(requestBody);

          if (isPasskeyStored) {
            return true;
          }
          return false;
        } catch (e) {
          return false;
        }
      } else {
        // Fingerprint authentication failed or was canceled
        // Handle accordingly
        return false;
      }
      return true;
    } catch (e) {
      // Handle any exceptions that occurred during authentication
      return false;
    }
  }

  String getNewCredentialId() {
    return crypto.getUuid();
  }

  Future<bool> synchronize(String relyingPartyName, String username) async {
    try {
      final LocalAuthentication localAuth = LocalAuthentication();
      bool isAuthenticated = await localAuth.authenticate(
        localizedReason:
            'Confirm to synchronize your passkey with username: $username, service: $relyingPartyName inside this wallet', // Reason shown to the user
      );

      if (isAuthenticated) {
        // Fingerprint authentication succeeded
        // Proceed with the protected operation

        final b64PemWalletPublicKey = crypto.encodeCryptoMaterial(
            Uint8List.fromList(crypto
                .encodePublicKeyInPem(applicationWallet.walletPublicKey!)
                .codeUnits));

        final queryParameters = {
          "walletPublicKey": b64PemWalletPublicKey,
          "relyingPartyName": relyingPartyName,
          "username": username
        };

        final passkeyParameters =
            await server.synchronizePasskey(queryParameters);

        if (passkeyParameters == null) {
          throw Error();
        }

        final relyingPartyId = passkeyParameters["relyingPartyId"];
        final b64PemPublicKey = passkeyParameters["passkeyPublicKey"];
        final b64encryptedPemSecretKeyE2E =
            passkeyParameters["passkeySecretKeyE2E"];

        //decode passkey public-key into an RSAPublicKey object
        final pemPublicKey = crypto.decodeCryptoMaterial(b64PemPublicKey!);
        final publicKey = RSAKeyParser()
            .parse(String.fromCharCodes(pemPublicKey)) as RSAPublicKey;

        //decrypt and decode the retrieved passkey secret-key into an RSAPrivateKey object
        final encryptedSecretKeyE2E =
            crypto.decodeCryptoMaterial(b64encryptedPemSecretKeyE2E!);

        //DEMO: end-to-end key and IV used are hardcoded assuming them to be received via bluetooth
        final pemSecretKey = crypto.aesCbcDecrypt(
            crypto.decodeCryptoMaterial(demo.demoKeyE2E),
            crypto.decodeCryptoMaterial(demo.demoIV),
            encryptedSecretKeyE2E);
        final privateKey = RSAKeyParser()
            .parse(String.fromCharCodes(pemSecretKey)) as RSAPrivateKey;

        //setting new values
        this.relyingPartyName = relyingPartyName;
        this.relyingPartyId = relyingPartyId!;
        this.username = username;
        this.passkeyPublicKey = publicKey;
        this.passkeyPrivateKey = privateKey;

        //saving locally the passkey under a new identifier
        this.passkeyId = getNewCredentialId();

        // storing passkeyId under Relying party identifier for ease of use
        await crypto.storeKeyValue(this.relyingPartyId, this.passkeyId);

        // storing new synchronized key-pair
        final passkeyPublicKeyId = "${this.passkeyId}_public";
        final passkeyPrivateKeyId = "${this.passkeyId}_private";
        await crypto.storeKeyPair(passkeyPublicKeyId, passkeyPublicKey!,
            passkeyPrivateKeyId, passkeyPrivateKey!);

        return true;
      } else {
        // Fingerprint authentication failed or was canceled
        // Handle accordingly
        return false;
      }
    } catch (e) {
      // Handle any exceptions that occurred
      return false;
    }
  }

  Future<bool> authenticate() async {
    try {
      final LocalAuthentication localAuth = LocalAuthentication();
      bool isAuthenticated = await localAuth.authenticate(
        localizedReason:
            'Confirm to authenticate as $username to $relyingPartyId', // Reason shown to the user
      );

      if (isAuthenticated) {
        // Fingerprint authentication succeeded
        // Proceed with the protected operation
        final b64PemWalletPublicKey = crypto.encodeCryptoMaterial(
            Uint8List.fromList(crypto
                .encodePublicKeyInPem(applicationWallet.walletPublicKey!)
                .codeUnits));

        final queryParameters = {
          "relyingPartyId": relyingPartyId,
          "walletPublicKey": b64PemWalletPublicKey
        };

        final challenge = await server.getChallenge(queryParameters);
        final signedChallenge = crypto.rsaSign(challenge!, passkeyPrivateKey!);

        final requestBody = {
          "walletPublicKey": b64PemWalletPublicKey,
          "relyingPartyId": relyingPartyId,
          "signature": signedChallenge,
          "challenge": challenge
        };

        final authenticationResult = await server.authenticate(requestBody);
        return authenticationResult;
      } else {
        // Fingerprint authentication failed or was canceled
        // Handle accordingly
        return false;
      }
    } catch (e) {
      // Handle any exceptions that occurred
      return false;
    }
  }
}
