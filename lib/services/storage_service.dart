import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  // API key from https://api.imgbb.com/
  static const String _imgBbApiKey = 'a2ef585828daa87debe575b9eca682d3';

  /// Uploads an image file to ImgBB.
  /// Returns the download URL if successful.
  Future<String> _uploadImageToImgBB(File file) async {
    if (_imgBbApiKey == 'YOUR_IMGBB_API_KEY_HERE') {
      throw Exception('Please create a free API key at api.imgbb.com and paste it in lib/services/storage_service.dart');
    }

    try {
      final url = Uri.parse('https://api.imgbb.com/1/upload');
      
      final request = http.MultipartRequest('POST', url)
        ..fields['key'] = _imgBbApiKey
        ..files.add(await http.MultipartFile.fromPath('image', file.path));

      final responseStream = await request.send();
      final response = await http.Response.fromStream(responseStream);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data']['url'];
        } else {
          throw Exception('ImgBB API error: ${data['error']['message']}');
        }
      } else {
        throw Exception('Failed to upload image. Status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[StorageService] Error: $e');
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// Uploads a gym cover image and returns its public URL.
  Future<String> uploadGymCoverImage(String gymId, File imageFile) async {
    return await _uploadImageToImgBB(imageFile);
  }

  /// Uploads a user avatar image and returns its public URL.
  Future<String> uploadUserAvatar(String userId, File imageFile) async {
    return await _uploadImageToImgBB(imageFile);
  }
}

// Global instance for easy access
final storageService = StorageService();
