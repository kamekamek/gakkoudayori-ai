import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;
import '../core/models/image_file.dart';
import 'web_image_upload_service.dart';

// Webでない場合のみインポート
import 'dart:io' if (dart.library.html) 'dart:html' as html;
import 'package:file_picker/file_picker.dart' if (dart.library.html) '';
import 'package:image_picker/image_picker.dart' if (dart.library.html) '';

/// 画像アップロード・処理サービス
class ImageUploadService {
  static const List<String> supportedMimeTypes = [
    'image/jpeg',
    'image/png',
    'image/gif',
    'image/webp',
  ];

  static const List<String> supportedExtensions = [
    'jpg', 'jpeg', 'png', 'gif', 'webp'
  ];

  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const int maxImageCount = 10;

  /// ファイル選択から画像をアップロード
  static Future<List<ImageFile>> pickImagesFromDevice() async {
    // Web環境の場合はWeb専用サービスを使用
    if (kIsWeb) {
      return await WebImageUploadService.pickImagesFromDevice();
    }

    try {
      if (kDebugMode) debugPrint('📁 [ImageUpload] ファイル選択開始（モバイル/デスクトップ）');

      // モバイル/デスクトップ環境での実装
      // この部分は実際のプラットフォームでテストする必要があります
      throw UnimplementedError('モバイル/デスクトップ版は後日実装予定です');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [ImageUpload] ファイル選択エラー: $e');
      throw Exception('ファイル選択中にエラーが発生しました: $e');
    }
  }

  /// カメラ撮影から画像をアップロード
  static Future<ImageFile?> captureImageFromCamera() async {
    // Web環境の場合はWeb専用サービスを使用
    if (kIsWeb) {
      return await WebImageUploadService.captureImageFromCamera();
    }

    try {
      if (kDebugMode) debugPrint('📷 [ImageUpload] カメラ撮影開始（モバイル/デスクトップ）');

      // モバイル/デスクトップ環境での実装
      throw UnimplementedError('モバイル/デスクトップ版は後日実装予定です');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [ImageUpload] カメラ撮影エラー: $e');
      throw Exception('カメラ撮影中にエラーが発生しました: $e');
    }
  }

  /// URLから画像を取得
  static Future<ImageFile?> fetchImageFromUrl(String url) async {
    // Web環境の場合はWeb専用サービスを使用
    if (kIsWeb) {
      return await WebImageUploadService.fetchImageFromUrl(url);
    }

    try {
      if (kDebugMode) debugPrint('🌐 [ImageUpload] URL取得開始（モバイル/デスクトップ）: $url');

      // モバイル/デスクトップ環境での実装
      throw UnimplementedError('モバイル/デスクトップ版は後日実装予定です');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [ImageUpload] URL取得エラー: $e');
      throw Exception('URL画像の取得に失敗しました: $e');
    }
  }

  /// 画像圧縮・最適化
  static Future<ImageFile> compressImage(ImageFile originalImage) async {
    // Web環境の場合はWeb専用サービスを使用
    if (kIsWeb) {
      return await WebImageUploadService.compressImage(originalImage);
    }

    try {
      if (kDebugMode) debugPrint('🗜️ [ImageUpload] 圧縮開始（モバイル/デスクトップ）: ${originalImage.name}');

      // 既に小さい場合はスキップ
      if (originalImage.size <= 1024 * 1024) { // 1MB以下
        if (kDebugMode) debugPrint('⏭️ [ImageUpload] 圧縮スキップ（サイズ小）: ${originalImage.sizeDisplay}');
        return originalImage;
      }

      // モバイル/デスクトップ環境での実装
      final compressedBytes = await FlutterImageCompress.compressWithList(
        originalImage.bytes,
        minWidth: 800,
        minHeight: 600,
        quality: 85,
        format: CompressFormat.jpeg,
      );

      final compressedImage = originalImage.copyWith(
        bytes: compressedBytes,
        size: compressedBytes.length,
        isCompressed: true,
        originalSize: originalImage.size,
        mimeType: 'image/jpeg',
      );

      if (kDebugMode) {
        debugPrint('✅ [ImageUpload] 圧縮完了: ${originalImage.sizeDisplay} → ${compressedImage.sizeDisplay}');
        debugPrint('📊 [ImageUpload] ${compressedImage.compressionDisplay}');
      }

      return compressedImage;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [ImageUpload] 圧縮エラー: $e');
      // 圧縮に失敗した場合は元の画像を返す
      return originalImage;
    }
  }

  /// 画像のリサイズ（代替圧縮方法）
  static Future<ImageFile> resizeImage(ImageFile originalImage, {
    int maxWidth = 800,
    int maxHeight = 600,
  }) async {
    try {
      if (kDebugMode) debugPrint('📏 [ImageUpload] リサイズ開始: ${originalImage.name}');

      final originalImageDecoded = img.decodeImage(originalImage.bytes);
      if (originalImageDecoded == null) {
        throw Exception('画像のデコードに失敗しました');
      }

      // アスペクト比を保持しながらリサイズ
      final resized = img.copyResize(
        originalImageDecoded,
        width: originalImageDecoded.width > maxWidth ? maxWidth : null,
        height: originalImageDecoded.height > maxHeight ? maxHeight : null,
        interpolation: img.Interpolation.cubic,
      );

      // JPEG形式でエンコード
      final resizedBytes = Uint8List.fromList(img.encodeJpg(resized, quality: 85));

      final resizedImage = originalImage.copyWith(
        bytes: resizedBytes,
        size: resizedBytes.length,
        isCompressed: true,
        originalSize: originalImage.size,
        mimeType: 'image/jpeg',
      );

      if (kDebugMode) {
        debugPrint('✅ [ImageUpload] リサイズ完了: ${originalImage.sizeDisplay} → ${resizedImage.sizeDisplay}');
      }

      return resizedImage;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [ImageUpload] リサイズエラー: $e');
      return originalImage;
    }
  }

  /// 画像の回転
  static Future<ImageFile> rotateImage(ImageFile originalImage, int degrees) async {
    try {
      if (kDebugMode) debugPrint('🔄 [ImageUpload] 回転開始: ${originalImage.name} (${degrees}度)');

      final originalImageDecoded = img.decodeImage(originalImage.bytes);
      if (originalImageDecoded == null) {
        throw Exception('画像のデコードに失敗しました');
      }

      final rotated = img.copyRotate(originalImageDecoded, angle: degrees.toDouble());
      final rotatedBytes = Uint8List.fromList(img.encodeJpg(rotated, quality: 90));

      final rotatedImage = originalImage.copyWith(
        bytes: rotatedBytes,
        size: rotatedBytes.length,
      );

      if (kDebugMode) debugPrint('✅ [ImageUpload] 回転完了: ${rotatedImage.sizeDisplay}');
      return rotatedImage;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [ImageUpload] 回転エラー: $e');
      return originalImage;
    }
  }

  /// 拡張子からMIMEタイプを取得
  static String _getMimeTypeFromExtension(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  /// ファイルサイズの検証
  static bool validateFileSize(int size) {
    return size <= maxFileSize;
  }

  /// MIMEタイプの検証
  static bool validateMimeType(String mimeType) {
    return supportedMimeTypes.contains(mimeType);
  }

  /// 一括処理：選択→圧縮→準備完了
  static Future<List<ImageFile>> processImages(List<ImageFile> originalImages) async {
    final processedImages = <ImageFile>[];

    for (final originalImage in originalImages) {
      try {
        // 圧縮処理
        final compressed = await compressImage(originalImage);
        processedImages.add(compressed);
        
        if (kDebugMode) {
          debugPrint('✅ [ImageUpload] 処理完了: ${compressed.name}');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ [ImageUpload] 処理失敗: ${originalImage.name} - $e');
        }
        // エラーの場合は元画像をそのまま追加
        processedImages.add(originalImage);
      }
    }

    return processedImages;
  }
}