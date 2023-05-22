import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/asn1/primitives/asn1_integer.dart';
import 'package:pointycastle/asn1/primitives/asn1_sequence.dart';
import 'package:pointycastle/src/platform_check/platform_check.dart';
import "package:pointycastle/export.dart";

AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> generateRSAkeyPair(
    SecureRandom secureRandom,
    {int bitLength = 2048}) {
  // Create an RSA key generator and initialize it

  // final keyGen = KeyGenerator('RSA'); // Get using registry
  final keyGen = RSAKeyGenerator();

  keyGen.init(ParametersWithRandom(
      RSAKeyGeneratorParameters(BigInt.parse('65537'), bitLength, 64),
      secureRandom));

  // Use the generator
  final pair = keyGen.generateKeyPair();

  // Cast the generated key pair into the RSA key types
  final publicKey = pair.publicKey as RSAPublicKey;
  final privateKey = pair.privateKey as RSAPrivateKey;

  return AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>(publicKey, privateKey);
}

SecureRandom getSecureRandom() {

  final secureRandom = SecureRandom('Fortuna')
    ..seed(KeyParameter(
        Platform.instance.platformEntropySource().getBytes(32)));
  return secureRandom;
}

Future<void> storeKeyPair(String publicId, RSAPublicKey publicKey, String privateId, RSAPrivateKey privateKey) async {
  const storage = FlutterSecureStorage();

  final pemPublicKey = encodePublicKeyInPem(publicKey);
  final pemPrivateKey = encodePrivateKeyInPem(privateKey);

  await storage.write(key: publicId, value: pemPublicKey);
  await storage.write(key: privateId, value: pemPrivateKey);
}

String encrypt(String plaintext, RSAPublicKey publicKey) {
  final cipher = RSAEngine()
    ..init(true, PublicKeyParameter<RSAPublicKey>(publicKey));
  final cipherText = cipher.process(Uint8List.fromList(plaintext.codeUnits));

  return String.fromCharCodes(cipherText);
}

String decrypt(String ciphertext, RSAPrivateKey privateKey) {
  final cipher = RSAEngine()
    ..init(false, PrivateKeyParameter<RSAPrivateKey>(privateKey));
  final decrypted = cipher.process(Uint8List.fromList(ciphertext.codeUnits));

  return String.fromCharCodes(decrypted);
}

String sign(String message, RSAPrivateKey privateKey) {
  var signer = RSASigner(SHA256Digest(), '0609608648016503040201')
    ..init(true, PrivateKeyParameter<RSAPrivateKey>(privateKey));
  final signed = signer.generateSignature(Uint8List.fromList(message.codeUnits));

  return String.fromCharCodes(signed.bytes);
}

bool verify(String signature, String message, RSAPublicKey publicKey) {

  final sig = RSASignature(Uint8List.fromList(signature.codeUnits));

  final verifier = RSASigner(SHA256Digest(), '0609608648016503040201');

  verifier.init(false, PublicKeyParameter<RSAPublicKey>(publicKey)); // false=verify

  try {
    return verifier.verifySignature(Uint8List.fromList(message.codeUnits), sig);
  } on ArgumentError {
    return false;
  }
}


Future<List<String?>> readKeyPair(String publicId, String privateId) async {
  const storage = FlutterSecureStorage();

  String? publicKey = await storage.read(key: publicId);
  String? privateKey = await storage.read(key: privateId);

  return [publicKey, privateKey];
}


// coding/encoding keys
String encodePublicKeyInPem(RSAPublicKey key) {
  final asn = ASN1Sequence();

  // convert and add the two attributes of the key
  asn.add(ASN1Integer(key.modulus));
  asn.add(ASN1Integer(key.exponent));

  final bytes = asn.encode();
  final base64Data = base64.encode(bytes);
  return '-----BEGIN RSA PUBLIC KEY-----\n$base64Data\n-----END RSA PUBLIC KEY-----';
}

String encodePrivateKeyInPem(RSAPrivateKey key) {
  final asn = ASN1Sequence();

  asn.add(ASN1Integer(BigInt.zero)); // version
  asn.add(ASN1Integer(key.n)); // modulus
  asn.add(ASN1Integer(key.exponent)); // public exponent
  asn.add(ASN1Integer(key.privateExponent));
  asn.add(ASN1Integer(key.p));
  asn.add(ASN1Integer(key.q));
  asn.add(ASN1Integer(key.privateExponent! % (key.p! - BigInt.one))); // exp1
  asn.add(ASN1Integer(key.privateExponent! % (key.q! - BigInt.one))); // exp2
  asn.add(ASN1Integer(key.q?.modInverse(key.p!))); // coefficient

  final base64Data = base64.encode(asn.encode());
  return '-----BEGIN RSA PRIVATE KEY-----\n$base64Data\n-----END RSA PRIVATE KEY-----';
}

