import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CloudinaryService
// Free photo uploads — no Firebase Storage needed.
// Uses unsigned upload preset so no API secret is exposed in the app.
// ─────────────────────────────────────────────────────────────────────────────
class CloudinaryService {
  // ── Your Cloudinary credentials ───────────────────────────────────────────
  // Get these from: cloudinary.com → Dashboard
  static const String _cloudName    = 'ddh6rmuoq';    // e.g. 'dxyz1234'
  static const String _uploadPreset = 'trashgo_claims';     // the preset you just created

  static const String _baseUrl =
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';

  // ─────────────────────────────────────────────────────────────────────────
  // Upload a claim photo
  // Returns the public HTTPS URL on success, null on failure.
  // Failure is non-fatal — the claim still saves without a photo.
  // ─────────────────────────────────────────────────────────────────────────
  static Future<String?> uploadClaimPhoto({
    required String localFilePath,
    required String claimId,
    required String userId,
  }) async {
    try {
      final file = File(localFilePath);
      if (!await file.exists()) {
        debugPrint('[Cloudinary] File not found: $localFilePath');
        return null;
      }

      final uri = Uri.parse(_baseUrl);
      final request = http.MultipartRequest('POST', uri);

      // Required fields
      request.fields['upload_preset'] = _uploadPreset;

      // Optional: tag by userId and claimId for easy filtering in dashboard
      request.fields['public_id']     = 'claims/$userId/$claimId';
      request.fields['tags']          = 'claim,$userId';

      // Image optimisation: Cloudinary auto-compresses on upload
      request.fields['quality']       = 'auto';
      request.fields['fetch_format']  = 'auto';

      // Attach the file
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          localFilePath,
        ),
      );

      final streamedResponse = await request.send()
          .timeout(const Duration(seconds: 30));
      final responseBody = await streamedResponse.stream.bytesToString();

      if (streamedResponse.statusCode == 200) {
        final json = jsonDecode(responseBody) as Map<String, dynamic>;
        final url  = json['secure_url'] as String?;
        debugPrint('[Cloudinary] Upload success: $url');
        return url;
      } else {
        debugPrint('[Cloudinary] Upload failed ${streamedResponse.statusCode}: $responseBody');
        return null;
      }
    } catch (e) {
      debugPrint('[Cloudinary] Upload error: $e');
      return null; // Never crash the app over a photo upload
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Upload a profile avatar photo
  // ─────────────────────────────────────────────────────────────────────────
  static Future<String?> uploadAvatar({
    required String localFilePath,
    required String userId,
  }) async {
    try {
      final file = File(localFilePath);
      if (!await file.exists()) return null;

      final uri = Uri.parse(_baseUrl);
      final request = http.MultipartRequest('POST', uri);

      request.fields['upload_preset'] = _uploadPreset;
      request.fields['public_id']     = 'avatars/$userId';
      // Overwrite previous avatar with same public_id
      request.fields['overwrite']     = 'true';
      // Auto crop to square face-centred thumbnail
      request.fields['transformation'] =
      'w_256,h_256,c_fill,g_face,q_auto,f_auto';

      request.files.add(
        await http.MultipartFile.fromPath('file', localFilePath),
      );

      final streamedResponse = await request.send()
          .timeout(const Duration(seconds: 30));
      final responseBody = await streamedResponse.stream.bytesToString();

      if (streamedResponse.statusCode == 200) {
        final json = jsonDecode(responseBody) as Map<String, dynamic>;
        return json['secure_url'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('[Cloudinary] Avatar upload error: $e');
      return null;
    }
  }
}