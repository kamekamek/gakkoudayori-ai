import 'dart:typed_data';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../core/models/image_file.dart';

/// Web専用画像アップロードサービス
class WebImageUploadService {
  static const List<String> supportedMimeTypes = [
    'image/jpeg',
    'image/png',
    'image/gif',
    'image/webp',
  ];

  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const int maxImageCount = 10;

  /// Web用ファイル選択（HTML Input Element使用）
  static Future<List<ImageFile>> pickImagesFromDevice() async {
    try {
      if (kDebugMode) debugPrint('📁 [WebImageUpload] Web用ファイル選択開始');

      // HTML Input Element を作成
      final input = html.FileUploadInputElement()
        ..accept = 'image/*'
        ..multiple = true;

      // ファイル選択ダイアログを表示
      input.click();

      // ファイル選択完了を待機
      await for (final event in input.onChange) {
        if (input.files?.isNotEmpty == true) {
          break;
        }
      }

      final files = input.files;
      if (files == null || files.isEmpty) {
        if (kDebugMode) debugPrint('📁 [WebImageUpload] ファイル選択キャンセル');
        return [];
      }

      final imageFiles = <ImageFile>[];

      for (final file in files) {
        try {
          // ファイルサイズチェック
          if (file.size > maxFileSize) {
            if (kDebugMode) debugPrint('⚠️ [WebImageUpload] ファイルサイズ超過: ${file.name}');
            continue;
          }

          // MIMEタイプチェック
          if (!supportedMimeTypes.contains(file.type)) {
            if (kDebugMode) debugPrint('⚠️ [WebImageUpload] 非対応形式: ${file.name}');
            continue;
          }

          // ファイルをUint8Listに変換
          final bytes = await _fileToBytes(file);

          final imageFile = ImageFile(
            id: '${DateTime.now().millisecondsSinceEpoch}_${file.name}',
            name: file.name,
            bytes: bytes,
            size: file.size,
            mimeType: file.type,
            uploadedAt: DateTime.now(),
          );

          imageFiles.add(imageFile);
          if (kDebugMode) debugPrint('✅ [WebImageUpload] 追加: ${file.name} (${imageFile.sizeDisplay})');
        } catch (e) {
          if (kDebugMode) debugPrint('❌ [WebImageUpload] ファイル処理エラー: ${file.name} - $e');
        }
      }

      if (kDebugMode) debugPrint('📁 [WebImageUpload] 完了: ${imageFiles.length}件');
      return imageFiles;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [WebImageUpload] ファイル選択エラー: $e');
      throw Exception('ファイル選択中にエラーが発生しました: $e');
    }
  }

  /// Web用カメラ撮影（MediaDevices API使用）
  static Future<ImageFile?> captureImageFromCamera() async {
    try {
      if (kDebugMode) debugPrint('📷 [WebImageUpload] Web用カメラ撮影開始');

      // ブラウザがカメラをサポートしているかチェック
      if (!_isCameraSupported()) {
        throw Exception('このブラウザはカメラ機能をサポートしていません');
      }

      // MediaStream を取得
      final mediaStream = await html.window.navigator.mediaDevices!.getUserMedia({
        'video': {'width': 1280, 'height': 720},
        'audio': false,
      });

      // カメラキャプチャダイアログを表示
      final imageFile = await _showCameraDialog(mediaStream);

      // MediaStream を停止
      for (final track in mediaStream.getTracks()) {
        track.stop();
      }

      if (kDebugMode && imageFile != null) {
        debugPrint('✅ [WebImageUpload] カメラ撮影完了: ${imageFile.sizeDisplay}');
      }

      return imageFile;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [WebImageUpload] カメラ撮影エラー: $e');
      throw Exception('カメラ撮影中にエラーが発生しました: $e');
    }
  }

  /// URLから画像を取得
  static Future<ImageFile?> fetchImageFromUrl(String url) async {
    try {
      if (kDebugMode) debugPrint('🌐 [WebImageUpload] URL取得開始: $url');

      // URLの検証
      final uri = Uri.tryParse(url);
      if (uri == null || !uri.hasScheme) {
        throw Exception('無効なURLです');
      }

      // CORS対応のHTTPリクエスト
      final response = await html.HttpRequest.request(
        url,
        method: 'GET',
        responseType: 'arraybuffer',
        requestHeaders: {
          'Accept': 'image/*',
        },
      );

      if (response.status != 200) {
        throw Exception('画像の取得に失敗しました (HTTP ${response.status})');
      }

      final result = response.response;
      final bytes = result is Uint8List 
          ? result 
          : result is ByteBuffer 
              ? Uint8List.view(result)
              : Uint8List.fromList(List<int>.from(result as dynamic));

      // ファイル名を生成
      final fileName = url.split('/').last.split('?').first;
      final extension = fileName.split('.').last.toLowerCase();
      final mimeType = _getMimeTypeFromExtension(extension);

      if (!supportedMimeTypes.contains(mimeType)) {
        throw Exception('対応していない画像形式です');
      }

      final imageFile = ImageFile(
        id: '${DateTime.now().millisecondsSinceEpoch}_url',
        name: fileName.isNotEmpty ? fileName : 'image_${DateTime.now().millisecondsSinceEpoch}.$extension',
        bytes: bytes,
        size: bytes.length,
        mimeType: mimeType,
        uploadedAt: DateTime.now(),
      );

      if (kDebugMode) debugPrint('✅ [WebImageUpload] URL取得完了: ${imageFile.sizeDisplay}');
      return imageFile;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [WebImageUpload] URL取得エラー: $e');
      throw Exception('URL画像の取得に失敗しました: $e');
    }
  }

  /// ドラッグ&ドロップ対応
  static Future<List<ImageFile>> handleDroppedFiles(List<html.File> files) async {
    try {
      if (kDebugMode) debugPrint('📦 [WebImageUpload] ドロップファイル処理開始: ${files.length}件');

      final imageFiles = <ImageFile>[];

      for (final file in files) {
        try {
          // ファイルサイズチェック
          if (file.size > maxFileSize) {
            if (kDebugMode) debugPrint('⚠️ [WebImageUpload] ファイルサイズ超過: ${file.name}');
            continue;
          }

          // MIMEタイプチェック
          if (!supportedMimeTypes.contains(file.type)) {
            if (kDebugMode) debugPrint('⚠️ [WebImageUpload] 非対応形式: ${file.name}');
            continue;
          }

          // ファイルをUint8Listに変換
          final bytes = await _fileToBytes(file);

          final imageFile = ImageFile(
            id: '${DateTime.now().millisecondsSinceEpoch}_${file.name}',
            name: file.name,
            bytes: bytes,
            size: file.size,
            mimeType: file.type,
            uploadedAt: DateTime.now(),
          );

          imageFiles.add(imageFile);
          if (kDebugMode) debugPrint('✅ [WebImageUpload] ドロップ追加: ${file.name}');
        } catch (e) {
          if (kDebugMode) debugPrint('❌ [WebImageUpload] ドロップファイル処理エラー: ${file.name} - $e');
        }
      }

      if (kDebugMode) debugPrint('📦 [WebImageUpload] ドロップ処理完了: ${imageFiles.length}件');
      return imageFiles;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [WebImageUpload] ドロップ処理エラー: $e');
      throw Exception('ドロップファイル処理中にエラーが発生しました: $e');
    }
  }

  /// HTML File を Uint8List に変換
  static Future<Uint8List> _fileToBytes(html.File file) async {
    final reader = html.FileReader();
    reader.readAsArrayBuffer(file);

    await reader.onLoad.first;
    
    final result = reader.result;
    if (result is Uint8List) {
      return result;
    } else if (result is ByteBuffer) {
      return Uint8List.view(result);
    } else {
      // NativeUint8List等の場合は新しいUint8Listを作成
      final buffer = result as dynamic;
      return Uint8List.fromList(List<int>.from(buffer));
    }
  }

  /// カメラサポートチェック
  static bool _isCameraSupported() {
    return html.window.navigator.mediaDevices != null;
  }

  /// カメラキャプチャダイアログ
  static Future<ImageFile?> _showCameraDialog(html.MediaStream stream) async {
    // 簡易実装：実際のプロジェクトではより高度なカメラUIを実装
    // ここでは基本的なcanvas撮影のみ実装
    
    final video = html.VideoElement()
      ..srcObject = stream
      ..autoplay = true;

    // ビデオが準備できるまで待機
    await video.onLoadedMetadata.first;

    // Canvas で撮影
    final canvas = html.CanvasElement(width: video.videoWidth, height: video.videoHeight);
    final context = canvas.context2D;
    
    context.drawImage(video, 0, 0);

    // Canvas を Blob に変換
    final blob = await canvas.toBlob('image/jpeg', 0.8);
    final bytes = await _blobToBytes(blob);

    return ImageFile(
      id: '${DateTime.now().millisecondsSinceEpoch}_camera',
      name: 'camera_${DateTime.now().millisecondsSinceEpoch}.jpg',
      bytes: bytes,
      size: bytes.length,
      mimeType: 'image/jpeg',
      uploadedAt: DateTime.now(),
    );
  }

  /// Blob を Uint8List に変換
  static Future<Uint8List> _blobToBytes(html.Blob blob) async {
    final reader = html.FileReader();
    reader.readAsArrayBuffer(blob);

    await reader.onLoad.first;
    
    final result = reader.result;
    if (result is Uint8List) {
      return result;
    } else if (result is ByteBuffer) {
      return Uint8List.view(result);
    } else {
      // NativeUint8List等の場合は新しいUint8Listを作成
      final buffer = result as dynamic;
      return Uint8List.fromList(List<int>.from(buffer));
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

  /// 画像圧縮（Web最適化）- Canvas使用
  static Future<ImageFile> compressImage(ImageFile originalImage) async {
    try {
      if (kDebugMode) debugPrint('🗜️ [WebImageUpload] Web用圧縮開始: ${originalImage.name}');

      // 既に小さい場合はスキップ
      if (originalImage.size <= 1024 * 1024) { // 1MB以下
        if (kDebugMode) debugPrint('⏭️ [WebImageUpload] 圧縮スキップ（サイズ小）: ${originalImage.sizeDisplay}');
        return originalImage;
      }

      // Canvas を使用してWeb用に圧縮
      final compressedBytes = await _compressWithCanvas(originalImage.bytes, quality: 0.8);

      final compressedImage = originalImage.copyWith(
        bytes: compressedBytes,
        size: compressedBytes.length,
        isCompressed: true,
        originalSize: originalImage.size,
        mimeType: 'image/jpeg',
      );

      if (kDebugMode) {
        debugPrint('✅ [WebImageUpload] 圧縮完了: ${originalImage.sizeDisplay} → ${compressedImage.sizeDisplay}');
        debugPrint('📊 [WebImageUpload] ${compressedImage.compressionDisplay}');
      }

      return compressedImage;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [WebImageUpload] 圧縮エラー: $e');
      // 圧縮に失敗した場合は元の画像を返す
      return originalImage;
    }
  }

  /// Canvas を使用したWeb専用圧縮
  static Future<Uint8List> _compressWithCanvas(Uint8List imageBytes, {double quality = 0.8}) async {
    // Blob を作成
    final blob = html.Blob([imageBytes]);
    
    // Image Element を作成
    final img = html.ImageElement();
    final url = html.Url.createObjectUrl(blob);
    
    // 画像読み込みを待機
    img.src = url;
    await img.onLoad.first;
    
    // Canvas でリサイズ・圧縮
    final canvas = html.CanvasElement();
    final context = canvas.context2D;
    
    // アスペクト比を保持してリサイズ
    final maxWidth = 800;
    final maxHeight = 600;
    
    double newWidth = img.naturalWidth!.toDouble();
    double newHeight = img.naturalHeight!.toDouble();
    
    if (newWidth > maxWidth) {
      newHeight = (newHeight * maxWidth) / newWidth;
      newWidth = maxWidth.toDouble();
    }
    
    if (newHeight > maxHeight) {
      newWidth = (newWidth * maxHeight) / newHeight;
      newHeight = maxHeight.toDouble();
    }
    
    canvas.width = newWidth.toInt();
    canvas.height = newHeight.toInt();
    
    // 高品質設定
    context.imageSmoothingEnabled = true;
    context.imageSmoothingQuality = 'high';
    
    // 描画
    context.drawImageScaled(img, 0, 0, newWidth, newHeight);
    
    // JPEG として圧縮出力
    final compressedBlob = await canvas.toBlob('image/jpeg', quality);
    final compressedBytes = await _blobToBytes(compressedBlob);
    
    // URL をクリーンアップ
    html.Url.revokeObjectUrl(url);
    
    return compressedBytes;
  }
}