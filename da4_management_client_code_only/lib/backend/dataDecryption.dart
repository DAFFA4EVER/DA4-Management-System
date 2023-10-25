import 'package:encrypt/encrypt.dart';

String decryptData(String encryptedData, String keyToken) {
  // Define your encryption key and IV (Initialization Vector)
  final keyString = keyToken;
  final iv = IV.fromLength(16);

  // Convert the key string to bytes and pad or truncate it to the desired length
  final key = Key.fromUtf8(keyString.padRight(32, '\0').substring(0, 32));

  // Create an encrypter with AES encryption algorithm and CBC block mode
  final encrypter = Encrypter(AES(key));

  try {
    // Decrypt the encrypted data
    Encrypted encrypted = Encrypted.fromBase64(encryptedData);

    String decryptedData = encrypter.decrypt(encrypted, iv: iv);

    return decryptedData;
  } catch (e) {
    return 'error';
  }
}
