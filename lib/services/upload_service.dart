import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/foundation.dart';

class UploadService {
  UploadService._();

  static const String _customerDesignUploadUrl =
      'https://jenishaonlineservice.com/printx/api/upload-design.php';

  static const String _customerDesignPublicBaseUrl =
      'https://jenishaonlineservice.com/printx/designs/';

  static String _fileNameFromPath(String path) {
    return path.split(Platform.pathSeparator).last;
  }

  static String? _inferExtension(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return lower.endsWith('.jpeg') ? 'jpeg' : 'jpg';
    }
    if (lower.endsWith('.webp')) return 'webp';
    return null;
  }

  static String _safeExtensionOrJpg(String? ext) {
    final e = (ext ?? '').toLowerCase();
    if (e == 'png') return 'png';
    if (e == 'jpg') return 'jpg';
    if (e == 'jpeg') return 'jpg';
    if (e == 'webp') return 'webp';
    return 'jpg';
  }

  static const String _profileUploadUrl =
      'https://jenishaonlineservice.com/printx/api/upload-profile.php';

  static const String _profilePublicBaseUrl =
      'https://jenishaonlineservice.com/printx/profiles/';

  /// Hostinger/PHP multipart upload for profile images.
  ///
  /// Endpoint must store files ONLY in:
  /// public_html/printx/profiles/
  ///
  /// Expected response JSON:
  /// {"success": true, "url": "https://jenishaonlineservice.com/printx/profiles/<filename>"}
  static Future<Map<String, String?>> uploadCustomerDesign({
    required File file,
    String? designFileNameOverride,
  }) async {
    final originalFileName = _fileNameFromPath(file.path);
    final ext = _inferExtension(originalFileName);

    if (ext == null) {
      throw Exception('Unsupported file extension for design upload');
    }

    final safeExt = _safeExtensionOrJpg(ext);

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw Exception('Cannot upload customer design: uid is null.');
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final finalName = (designFileNameOverride?.trim().isNotEmpty ?? false)
        ? designFileNameOverride!.trim()
        : 'design_${uid}_$timestamp.$safeExt';

    final uri = Uri.parse(_customerDesignUploadUrl);
    final request = await HttpClient().postUrl(uri);

    final boundary =
        '----PrintXBoundary${DateTime.now().microsecondsSinceEpoch}';

    request.headers
        .set('Content-Type', 'multipart/form-data; boundary=$boundary');

    void writeStringField(String name, String value) {
      request.write('--$boundary\r\n');
      request.write('Content-Disposition: form-data; name="$name"\r\n\r\n');
      request.write('$value\r\n');
    }

    void writeFileField(String name, File file, String fileName) {
      final bytes = file.readAsBytesSync();
      request.write('--$boundary\r\n');
      request.write(
          'Content-Disposition: form-data; name="$name"; filename="$fileName"\r\n');
      // PHP side will validate ext; we keep the content type generic by extension.
      request.write('Content-Type: application/octet-stream\r\n\r\n');
      request.add(bytes);
      request.write('\r\n');
    }

    writeStringField('filename', finalName);
    writeFileField('design', file, finalName);

    request.write('--$boundary--\r\n');

    final response = await request.close();

    final responseBodyBytes = await response.fold<List<int>>(
      <int>[],
      (prev, element) => prev..addAll(element),
    );

    final bodyString = String.fromCharCodes(responseBodyBytes);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Customer design upload failed (HTTP ${response.statusCode}): $bodyString',
      );
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(bodyString);
    } catch (_) {
      decoded = null;
    }

    // Expected: {"url":"...","filename":"..."}
    if (decoded is Map) {
      final url = decoded['url'];
      final filename = decoded['filename'];
      return {
        'url': url is String ? url : null,
        'filename': filename is String ? filename : null,
      };
    }

    return {
      'url': bodyString,
      'filename': finalName,
    };
  }

  static Future<String?> uploadProfileImage({
    required File imageFile,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw Exception('Cannot upload profile image: uid is null.');
    }

    final originalFileName = _fileNameFromPath(imageFile.path);
    final ext = _inferExtension(originalFileName);
    final safeExt = _safeExtensionOrJpg(ext);

    final timestamp = DateTime.now().millisecondsSinceEpoch;

    // Exact filename generation logic requested.
    // profile_<uid>_<timestamp>.jpg
    final generatedFileName = 'profile_${uid}_$timestamp.$safeExt';

    final uri = Uri.parse(_profileUploadUrl);
    final request = await HttpClient().postUrl(uri);

    final boundary =
        '----PrintXBoundary${DateTime.now().microsecondsSinceEpoch}';

    // IMPORTANT: Content-Type boundary must match the multipart boundary used in the body.
    // Otherwise PHP may not populate $_FILES / $_POST correctly.
    request.headers
        .set('Content-Type', 'multipart/form-data; boundary=$boundary');

    void writeStringField(String name, String value) {
      request.write('--$boundary\r\n');
      request.write('Content-Disposition: form-data; name="$name"\r\n\r\n');
      request.write('$value\r\n');
    }

    void writeFileField(String name, File file, String fileName) {
      final bytes = file.readAsBytesSync();
      request.write('--$boundary\r\n');
      request.write(
          'Content-Disposition: form-data; name="$name"; filename="$fileName"\r\n');
      request.write('Content-Type: image/$safeExt\r\n\r\n');
      request.add(bytes);
      request.write('\r\n');
    }

    writeStringField('filename', generatedFileName);
    writeFileField('image', imageFile, generatedFileName);

    request.write('--$boundary--\r\n');

    debugPrint('UPLOAD ENDPOINT: $_profileUploadUrl');
    debugPrint('UPLOAD GENERATED filename: $generatedFileName');

    final response = await request.close();
    debugPrint('UPLOAD RESPONSE STATUS: ${response.statusCode}');

    final responseBodyBytes = await response.fold<List<int>>(
      <int>[],
      (prev, element) => prev..addAll(element),
    );

    final bodyString = String.fromCharCodes(responseBodyBytes);
    debugPrint('UPLOAD RESPONSE BODY: $bodyString');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
          'Profile image upload failed (HTTP ${response.statusCode}): $bodyString');
    }

    // Parse endpoint response. If it doesn’t match expected JSON, fallback
    // to constructing the public URL.

    // DEBUG REQUIREMENTS
    // 1) Print raw response body (already printed above).
    // 2) Print decoded JSON object.
    // 3) Print URL before Firestore save (we do it right before returning).

    dynamic decoded;
    try {
      decoded = jsonDecode(bodyString);
    } catch (e) {
      debugPrint('UPLOAD RESPONSE JSON DECODE ERROR: $e');
      decoded = null;
    }

    debugPrint('UPLOAD RESPONSE DECODED JSON: $decoded');

    // Expected response: {"success": true, "url": "https:\/\/domain\/path\/file.jpg"}
    if (decoded is Map) {
      final rawUrl = decoded['url'];
      if (rawUrl is String) {
        // Fix escaping issue at the source.
        // If server returns escaped slashes (\/), normalize to plain (/).
        final normalizedUrl =
            rawUrl.replaceAll(r'\\/', '/').replaceAll(r'\/', '/');

        debugPrint('PROFILE IMAGE URL BEFORE FIRESTORE SAVE: $normalizedUrl');
        return normalizedUrl;
      }
    }

    // Last-resort extraction (kept for backward compatibility).
    final urlMatch = RegExp(r'"url"\s*:\s*"([^"]+)"').firstMatch(bodyString);
    if (urlMatch != null && urlMatch.groupCount >= 1) {
      final extracted = urlMatch.group(1) ?? '';
      final normalizedUrl =
          extracted.replaceAll(r'\\/', '/').replaceAll(r'\/', '/');

      debugPrint(
          'PROFILE IMAGE URL BEFORE FIRESTORE SAVE (regex fallback): $normalizedUrl');
      return normalizedUrl;
    }

    final fallbackUrl = '$_profilePublicBaseUrl$generatedFileName';
    debugPrint(
        'PROFILE IMAGE URL BEFORE FIRESTORE SAVE (fallback): $fallbackUrl');
    return fallbackUrl;
  }
}
