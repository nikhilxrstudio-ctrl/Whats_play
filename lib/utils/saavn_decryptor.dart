import 'dart:convert';
import 'package:dart_des/dart_des.dart';

class SaavnDecryptor {
  static const String _desKey = '38346591';

  /// Decrypts the high-definition 320kbps full track stream URL from JioSaavn encrypted_media_url
  static String decryptMediaUrl(String encryptedUrl) {
    if (encryptedUrl.isEmpty) return '';
    try {
      final key = utf8.encode(_desKey);
      final des = DES(
        key: key,
        mode: DESMode.ECB,
        paddingType: DESPaddingType.PKCS5,
      );
      final decryptedBytes = des.decrypt(base64.decode(encryptedUrl.trim()));
      final decryptedUrl = utf8.decode(decryptedBytes).trim();

      // Upgrade to 320kbps for crystal-clear full audio playback
      return decryptedUrl.replaceAll('_96.mp4', '_320.mp4');
    } catch (_) {
      return '';
    }
  }
}
