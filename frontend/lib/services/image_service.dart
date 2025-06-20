import 'dart:convert';
import 'dart:typed_data';
import 'dart:html' as html;
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';

/// 画像アップロード結果
class ImageUploadResult {
  final String filename;
  final String url;
  final String blobPath;
  final String contentType;
  final int? size;

  const ImageUploadResult({
    required this.filename,
    required this.url,
    required this.blobPath,
    required this.contentType,
    this.size,
  });

  factory ImageUploadResult.fromJson(Map<String, dynamic> json) {
    return ImageUploadResult(
      filename: json['filename'] as String,
      url: json['url'] as String,
      blobPath: json['blob_path'] as String,
      contentType: json['content_type'] as String,
      size: json['size'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'filename': filename,
      'url': url,
      'blob_path': blobPath,
      'content_type': contentType,
      'size': size,
    };
  }

  @override
  String toString() {
    return 'ImageUploadResult(filename: $filename, url: $url, blobPath: $blobPath)';
  }
}

/// 画像サービス - Firebase Storage連携
class ImageService {
  static const String _baseUrl = AppConfig.apiBaseUrl;

  /// 複数画像の同時アップロード
  static Future<List<ImageUploadResult>> uploadImages(
    List<html.File> imageFiles,
    String userId, {
    String category = 'newsletter',
  }) async {
    try {
      if (imageFiles.isEmpty) {
        throw Exception('No image files provided');
      }

      final uri = Uri.parse('$_baseUrl/images/upload');
      final request = http.MultipartRequest('POST', uri);

      // フォームデータ追加
      request.fields['user_id'] = userId;
      request.fields['category'] = category;

      // 画像ファイル追加
      for (int i = 0; i < imageFiles.length; i++) {
        final file = imageFiles[i];
        final bytes = await _fileToBytes(file);

        // MIMEタイプの検証
        if (!_isValidImageType(file.type)) {
          if (kDebugMode) {
            debugPrint('Skipping invalid image type: ${file.type}');
          }
          continue;
        }

        request.files.add(
          http.MultipartFile.fromBytes(
            'image_files',
            bytes,
            filename: file.name,
          ),
        );
      }

      if (request.files.isEmpty) {
        throw Exception('No valid image files found');
      }

      if (kDebugMode) {
        debugPrint('Uploading ${request.files.length} images to $_baseUrl/images/upload');
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (kDebugMode) {
        debugPrint('Upload response status: ${response.statusCode}');
        debugPrint('Upload response body: $responseBody');
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(responseBody);
        
        if (data['success'] == true) {
          final List<dynamic> images = data['data']['images'] as List<dynamic>;
          return images
              .map((item) => ImageUploadResult.fromJson(item as Map<String, dynamic>))
              .toList();
        } else {
          throw Exception(data['error'] ?? 'Upload failed');
        }
      } else {
        final errorData = json.decode(responseBody);
        throw Exception(errorData['error'] ?? 'HTTP ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Image upload error: $e');
      }
      throw Exception('画像アップロードエラー: $e');
    }
  }

  /// 画像URLの更新（期限切れ対応）
  static Future<String> refreshImageUrl(
    String blobPath,
    String userId,
  ) async {
    try {
      final uri = Uri.parse('$_baseUrl/images/refresh-url');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'blob_path': blobPath,
          'user_id': userId,
        }),
      );

      if (kDebugMode) {
        debugPrint('Refresh URL response status: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        if (data['success'] == true) {
          return data['data']['url'] as String;
        } else {
          throw Exception(data['error'] ?? 'URL refresh failed');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'HTTP ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('URL refresh error: $e');
      }
      throw Exception('URL更新エラー: $e');
    }
  }

  /// 画像ファイル選択ダイアログを表示
  static Future<List<html.File>?> selectImages({
    bool multiple = true,
    List<String> acceptedTypes = const ['image/*'],
  }) async {
    try {
      final input = html.FileUploadInputElement()
        ..accept = acceptedTypes.join(',')
        ..multiple = multiple;

      input.click();

      await input.onChange.first;
      
      if (input.files?.isNotEmpty == true) {
        return input.files!.cast<html.File>();
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Image selection error: $e');
      }
      return null;
    }
  }

  /// バイト配列から画像を選択（将来的にカメラ対応用）
  static Future<List<ImageUploadResult>> uploadImageBytes(
    List<Uint8List> imageBytes,
    List<String> filenames,
    String userId, {
    String category = 'newsletter',
  }) async {
    try {
      if (imageBytes.length != filenames.length) {
        throw Exception('Image bytes and filenames length mismatch');
      }

      final uri = Uri.parse('$_baseUrl/images/upload');
      final request = http.MultipartRequest('POST', uri);

      // フォームデータ追加
      request.fields['user_id'] = userId;
      request.fields['category'] = category;

      // 画像ファイル追加
      for (int i = 0; i < imageBytes.length; i++) {
        final bytes = imageBytes[i];
        final filename = filenames[i];

        request.files.add(
          http.MultipartFile.fromBytes(
            'image_files',
            bytes,
            filename: filename,
          ),
        );
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(responseBody);
        
        if (data['success'] == true) {
          final List<dynamic> images = data['data']['images'] as List<dynamic>;
          return images
              .map((item) => ImageUploadResult.fromJson(item as Map<String, dynamic>))
              .toList();
        } else {
          throw Exception(data['error'] ?? 'Upload failed');
        }
      } else {
        final errorData = json.decode(responseBody);
        throw Exception(errorData['error'] ?? 'HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('画像アップロードエラー: $e');
    }
  }

  // プライベートヘルパーメソッド

  /// html.File を Uint8List に変換
  static Future<Uint8List> _fileToBytes(html.File file) async {
    final reader = html.FileReader();
    reader.readAsArrayBuffer(file);
    await reader.onLoad.first;
    return reader.result as Uint8List;
  }

  /// 有効な画像タイプかチェック
  static bool _isValidImageType(String mimeType) {
    const validTypes = [
      'image/jpeg',
      'image/jpg', 
      'image/png',
      'image/gif',
      'image/webp',
    ];
    return validTypes.contains(mimeType.toLowerCase());
  }

  /// ファイルサイズの検証（5MB上限）
  static bool isValidFileSize(int fileSize) {
    const maxSize = 5 * 1024 * 1024; // 5MB
    return fileSize <= maxSize;
  }

  /// サポートされている画像形式の一覧を取得
  static List<String> getSupportedImageTypes() {
    return [
      'image/jpeg',
      'image/png',
      'image/gif',
      'image/webp',
    ];
  }

  /// ファイル情報の取得
  static Map<String, dynamic> getFileInfo(html.File file) {
    return {
      'name': file.name,
      'size': file.size,
      'type': file.type,
      'lastModified': file.lastModified,
      'isValidType': _isValidImageType(file.type),
      'isValidSize': isValidFileSize(file.size),
    };
  }
}