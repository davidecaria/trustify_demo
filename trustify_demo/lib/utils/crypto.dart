import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/asn1/primitives/asn1_integer.dart';
import 'package:pointycastle/asn1/primitives/asn1_sequence.dart';
import 'package:pointycastle/src/platform_check/platform_check.dart';
import "package:pointycastle/export.dart";
import 'package:uuid/uuid.dart';
import 'package:pointycastle/paddings/pkcs7.dart';

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

String rsaEncrypt(String plaintext, RSAPublicKey publicKey) {
  final cipher = RSAEngine()
    ..init(true, PublicKeyParameter<RSAPublicKey>(publicKey));
  final ciphertext = cipher.process(Uint8List.fromList(plaintext.codeUnits));

  return String.fromCharCodes(ciphertext);
}

String rsaDecrypt(String ciphertext, RSAPrivateKey privateKey) {
  final decodedCiphertext = base64.decode(ciphertext);

  final cipher = RSAEngine()
    ..init(false, PrivateKeyParameter<RSAPrivateKey>(privateKey));
  final decrypted = cipher.process(decodedCiphertext);

  return String.fromCharCodes(decrypted);
}

String rsaSign(String message, RSAPrivateKey privateKey) {
  var signer = RSASigner(SHA256Digest(), '0609608648016503040201')
    ..init(true, PrivateKeyParameter<RSAPrivateKey>(privateKey));
  final signed = signer.generateSignature(Uint8List.fromList(message.codeUnits));

  return base64.encode(signed.bytes);
}

bool rsaVerify(String signature, String message, RSAPublicKey publicKey) {

  final decodedSignature = base64.decode(signature);
  
  final sig = RSASignature(decodedSignature);

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

//coding/encoding keys to be stored in secure storage
String encodeCryptoMaterial(Uint8List crypto) {
  return base64.encode(crypto);
}

Uint8List decodeCryptoMaterial(String encodedCrypto) {
  return base64.decode(encodedCrypto);
}

// coding/encoding keys to be stored in secure storage
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

String getUuid() {
  const uuid = Uuid();

  return uuid.v1();
}

Future<void> storeKeyValue(String key, String value) async {
  const storage = FlutterSecureStorage();
  await storage.write(key: key, value: value);
}

Future<String?> readKeyValue(String key) async {
  const storage = FlutterSecureStorage();
  String? value = await storage.read(key: key);

  return value;
}


Uint8List? generateAesKey(int keyLength) {
  //wrong key length
  if(!(keyLength == 16 || keyLength == 24 || keyLength == 32)) {
    return null;
  }

  final secureRandom = getSecureRandom();
  final aesKey = secureRandom.nextBytes(keyLength);

  return aesKey;
}

Uint8List generateAesIV() {
  final secureRandom = getSecureRandom();
  final iv = secureRandom.nextBytes(16);

  return iv;
}

Uint8List aesCbcEncrypt(Uint8List key, Uint8List iv, Uint8List plaintext) {
  // Create a CBC block cipher with AES, and initialize with key and IV

  final cbc = CBCBlockCipher(AESEngine());
  final paddedBlockCipher = PaddedBlockCipherImpl(PKCS7Padding(), cbc);

  final cipherParameters = PaddedBlockCipherParameters(
    ParametersWithIV<KeyParameter>(KeyParameter(key), iv),
    null,
  );

  paddedBlockCipher.init(true, cipherParameters); // true=encrypt

  // Encrypt the plaintext block-by-block
  final ciphertext = paddedBlockCipher.process(plaintext);

  return ciphertext;
}

Uint8List aesCbcDecrypt(Uint8List key, Uint8List iv, Uint8List ciphertext) {
  // Create a CBC block cipher with AES, and initialize with key and IV

  final cbc = CBCBlockCipher(AESEngine());
  final paddedBlockCipher = PaddedBlockCipherImpl(PKCS7Padding(), cbc);

  final cipherParameters = PaddedBlockCipherParameters(
    ParametersWithIV<KeyParameter>(KeyParameter(key), iv),
    null,
  );

  paddedBlockCipher.init(false, cipherParameters); // false=decrypt

  // Encrypt the plaintext block-by-block
  final plaintext = paddedBlockCipher.process(ciphertext);

  return plaintext;
}
