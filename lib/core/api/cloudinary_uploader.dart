import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';
import 'dio_client.dart';

class CloudinaryUploader {
  /// Uploads a file directly to Cloudinary using a signed signature from the backend.
  /// If the signature request fails or anything fails, it falls back to the backend direct upload endpoint.
  static Future<String> upload({
    required List<int> bytes,
    required String filename,
    required String mimeType,
    required String resourceType, // 'image' or 'video'
    String folder = 'properties',
    String fallbackEndpoint = '/properties/upload-media',
  }) async {
    try {
      // 1. Get Signed Signature from backend
      final sigResponse = await DioClient.dio.post(
        '/properties/cloudinary-signature',
        data: {
          'resource_type': resourceType,
          'folder': folder,
        },
      );

      if (sigResponse.data != null && sigResponse.data['success'] == true) {
        final data = sigResponse.data['data'] as Map<String, dynamic>;
        final String signature = data['signature'];
        final int timestamp = data['timestamp'];
        final String apiKey = data['apiKey'];
        final String cloudName = data['cloudName'];
        final String targetFolder = data['folder'];
        final String transformation = data['transformation'] ?? 'q_70';

        // 2. Upload directly to Cloudinary
        final cloudinaryUrl = 'https://api.cloudinary.com/v1_1/$cloudName/$resourceType/upload';
        
        final multipartFile = MultipartFile.fromBytes(
          bytes,
          filename: filename,
          contentType: MediaType.parse(mimeType),
        );

        final formData = FormData.fromMap({
          'file': multipartFile,
          'api_key': apiKey,
          'timestamp': timestamp,
          'signature': signature,
          'folder': targetFolder,
          'transformation': transformation,
        });

        // Use a clean Dio instance to bypass our local JWT auth interceptor headers (so we don't leak cookies/tokens)
        final cleanDio = Dio();
        final cloudResponse = await cleanDio.post(
          cloudinaryUrl,
          data: formData,
        );

        if (cloudResponse.statusCode == 200 || cloudResponse.statusCode == 201) {
          final secureUrl = cloudResponse.data['secure_url'] as String?;
          if (secureUrl != null && secureUrl.isNotEmpty) {
            return secureUrl;
          }
        }
        throw Exception('Cloudinary upload returned status ${cloudResponse.statusCode}');
      }
      throw Exception('Backend signature generation failed.');
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Cloudinary Signed Upload failed, falling back to direct backend upload: $e');
      }
      
      // Fallback: direct upload to backend
      final multipartFile = MultipartFile.fromBytes(
        bytes,
        filename: filename,
        contentType: MediaType.parse(mimeType),
      );

      final formData = FormData.fromMap({
        'file': multipartFile,
      });

      final response = await DioClient.dio.post(
        fallbackEndpoint,
        data: formData,
      );

      if (response.data != null && response.data['success'] == true) {
        return response.data['data']['url'] as String;
      }
      throw Exception(response.data?['message'] ?? 'Upload failed.');
    }
  }
}
