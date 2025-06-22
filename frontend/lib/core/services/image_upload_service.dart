import 'dart:async';
import 'dart:typed_data';
import 'dart:math';
import 'dart:html' as html;
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import '../models/models.dart';

/// 画像アップロード関連のサービス
class ImageUploadService {
  static const List<String> supportedImageTypes = [
    'image/jpeg',
    'image/jpg', 
    'image/png',
    'image/gif',
    'image/webp',
  ];

  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const int maxImageCount = 10; // 最大10枚
  static const int maxImageWidth = 1920;
  static const int maxImageHeight = 1080;
  static const int compressionQuality = 85;

  /// ファイル選択からの画像アップロード
  static Future<List<ImageUploadResult>> pickImagesFromDevice() async {
    try {
      if (kDebugMode) {
        print('📁 [ImageUploadService] ファイル選択を開始...');
      }
      
      if (kIsWeb) {
        return await _pickImagesFromDeviceWeb();
      } else {
        // モバイル環境ではFilePicker使用
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: true,
          allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp'],
          withData: true,
        );

        if (kDebugMode) {
          print('📁 [ImageUploadService] FilePicker結果: ${result?.files.length ?? 0}ファイル');
        }

        if (result == null || result.files.isEmpty) {
          if (kDebugMode) {
            print('📁 [ImageUploadService] ファイル選択がキャンセルされました');
          }
          return [];
        }

        final List<ImageUploadResult> results = [];
        for (final file in result.files) {
          if (file.bytes == null) {
            results.add(ImageUploadResult(
              status: ImageUploadStatus.failed,
              error: 'ファイルデータを読み込めませんでした: ${file.name}',
            ));
            continue;
          }

          // ファイルサイズチェック
          if (file.size > maxFileSize) {
            results.add(ImageUploadResult(
              status: ImageUploadStatus.failed,
              error: 'ファイルサイズが大きすぎます (${_formatFileSize(file.size)}): ${file.name}',
            ));
            continue;
          }

          // MIMEタイプチェック
          if (!supportedImageTypes.contains(file.extension?.toLowerCase())) {
            results.add(ImageUploadResult(
              status: ImageUploadStatus.failed,
              error: 'サポートされていないファイル形式です: ${file.name}',
            ));
            continue;
          }

          final uploadResult = await _processAndUploadImage(
            bytes: file.bytes!,
            fileName: file.name,
            mimeType: _getMimeTypeFromExtension(file.extension ?? ''),
          );
          
          results.add(uploadResult);
        }

        return results;
      }
    } catch (e) {
      return [ImageUploadResult(
        status: ImageUploadStatus.failed,
        error: 'ファイル選択中にエラーが発生しました: $e',
      )];
    }
  }

  /// カメラ撮影からの画像アップロード
  static Future<ImageUploadResult> captureFromCamera() async {
    try {
      if (kIsWeb) {
        return await _captureFromCameraWeb();
      } else {
        // モバイルアプリの場合
        final picker = ImagePicker();
        final image = await picker.pickImage(
          source: ImageSource.camera,
          maxWidth: maxImageWidth.toDouble(),
          maxHeight: maxImageHeight.toDouble(),
          imageQuality: compressionQuality,
        );

        if (image == null) {
          return ImageUploadResult(
            status: ImageUploadStatus.failed,
            error: '写真の撮影をキャンセルしました',
          );
        }

        final bytes = await image.readAsBytes();
        return await _processAndUploadImage(
          bytes: bytes,
          fileName: 'camera_${DateTime.now().millisecondsSinceEpoch}.jpg',
          mimeType: 'image/jpeg',
        );
      }
    } catch (e) {
      return ImageUploadResult(
        status: ImageUploadStatus.failed,
        error: 'カメラ撮影中にエラーが発生しました: $e',
      );
    }
  }

  /// URLからの画像アップロード
  static Future<ImageUploadResult> fetchFromUrl(String imageUrl) async {
    try {
      final uri = Uri.tryParse(imageUrl);
      if (uri == null || !uri.hasAbsolutePath) {
        return ImageUploadResult(
          status: ImageUploadStatus.failed,
          error: '無効なURLです',
        );
      }

      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) {
        return ImageUploadResult(
          status: ImageUploadStatus.failed,
          error: '画像の取得に失敗しました (${response.statusCode})',
        );
      }

      final contentType = response.headers['content-type'] ?? '';
      if (!supportedImageTypes.any((type) => contentType.contains(type.split('/')[1]))) {
        return ImageUploadResult(
          status: ImageUploadStatus.failed,
          error: 'サポートされていない画像形式です',
        );
      }

      if (response.bodyBytes.length > maxFileSize) {
        return ImageUploadResult(
          status: ImageUploadStatus.failed,
          error: 'ファイルサイズが大きすぎます (${_formatFileSize(response.bodyBytes.length)})',
        );
      }

      final fileName = imageUrl.split('/').last.split('?').first;
      return await _processAndUploadImage(
        bytes: response.bodyBytes,
        fileName: fileName.isNotEmpty ? fileName : 'url_image_${DateTime.now().millisecondsSinceEpoch}.jpg',
        mimeType: contentType,
      );
    } catch (e) {
      return ImageUploadResult(
        status: ImageUploadStatus.failed,
        error: 'URL画像の取得中にエラーが発生しました: $e',
      );
    }
  }

  /// 画像処理とアップロードのメイン処理
  static Future<ImageUploadResult> _processAndUploadImage({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) async {
    try {
      if (kDebugMode) {
        print('🔄 [ImageUploadService] 画像処理開始: $fileName (${bytes.length} bytes, $mimeType)');
      }

      // 1. 画像メタデータの取得
      final imageData = img.decodeImage(bytes);
      if (imageData == null) {
        if (kDebugMode) {
          print('❌ [ImageUploadService] 画像デコード失敗: $fileName');
        }
        return ImageUploadResult(
          status: ImageUploadStatus.failed,
          error: '画像データの解析に失敗しました',
        );
      }

      if (kDebugMode) {
        print('📊 [ImageUploadService] 画像情報: ${imageData.width}x${imageData.height}');
      }

      final originalSize = bytes.length;
      final metadata = ImageMetadata(
        width: imageData.width,
        height: imageData.height,
        originalSize: originalSize,
      );

      // 2. 画像圧縮（必要に応じて）
      Uint8List finalBytes = bytes;
      bool isCompressed = false;
      double? compressionRatio;

      if (originalSize > 1024 * 1024 || // 1MB以上
          imageData.width > maxImageWidth ||
          imageData.height > maxImageHeight) {
        
        final compressedBytes = await FlutterImageCompress.compressWithList(
          bytes,
          minWidth: maxImageWidth,
          minHeight: maxImageHeight,
          quality: compressionQuality,
          format: _getCompressFormat(mimeType),
        );

        finalBytes = compressedBytes;
        isCompressed = true;
        compressionRatio = finalBytes.length / originalSize;
      }

      final finalMetadata = metadata.copyWith(
        isCompressed: isCompressed,
        compressionRatio: compressionRatio,
      );

      // 3. Firebase Storageにアップロード
      final storageUrl = await _uploadToFirebaseStorage(finalBytes, fileName);

      // 4. ImageFileオブジェクトの作成
      final imageFile = ImageFile(
        id: _generateImageId(),
        name: fileName,
        bytes: finalBytes,
        size: finalBytes.length,
        url: storageUrl,
        mimeType: mimeType,
        uploadedAt: DateTime.now(),
        metadata: finalMetadata,
      );

      return ImageUploadResult(
        imageFile: imageFile,
        status: ImageUploadStatus.completed,
        progress: 1.0,
      );
    } catch (e) {
      return ImageUploadResult(
        status: ImageUploadStatus.failed,
        error: '画像処理中にエラーが発生しました: $e',
      );
    }
  }

  /// Firebase Storageへのアップロード
  static Future<String> _uploadToFirebaseStorage(Uint8List bytes, String fileName) async {
    try {
      if (kDebugMode) {
        print('☁️ [ImageUploadService] Firebase Storageにアップロード開始: $fileName');
      }

      final storage = FirebaseStorage.instance;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storageRef = storage.ref().child('newsletters/images/$timestamp/$fileName');

      if (kDebugMode) {
        print('☁️ [ImageUploadService] アップロードパス: newsletters/images/$timestamp/$fileName');
      }

      final uploadTask = storageRef.putData(
        bytes,
        SettableMetadata(
          contentType: _getMimeTypeFromExtension(fileName.split('.').last),
          customMetadata: {
            'uploadedAt': DateTime.now().toIso8601String(),
            'source': 'newsletter_ai',
          },
        ),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      if (kDebugMode) {
        print('✅ [ImageUploadService] Firebase Storageアップロード完了: $downloadUrl');
      }
      
      return downloadUrl;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [ImageUploadService] Firebase Storageアップロード失敗: $e');
      }
      rethrow;
    }
  }

  /// ユーティリティメソッド

  static String _generateImageId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(999999);
    return 'img_${timestamp}_$random';
  }

  static String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

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

  static CompressFormat _getCompressFormat(String mimeType) {
    switch (mimeType) {
      case 'image/png':
        return CompressFormat.png;
      case 'image/webp':
        return CompressFormat.webp;
      default:
        return CompressFormat.jpeg;
    }
  }

  /// 画像の削除
  static Future<bool> deleteImage(ImageFile imageFile) async {
    try {
      if (imageFile.url != null) {
        final ref = FirebaseStorage.instance.refFromURL(imageFile.url!);
        await ref.delete();
      }
      return true;
    } catch (e) {
      // TODO: Use proper logging framework instead of print
      print('画像削除エラー: $e');
      return false;
    }
  }

  /// Web環境でのファイル選択
  static Future<List<ImageUploadResult>> _pickImagesFromDeviceWeb() async {
    try {
      if (kDebugMode) {
        print('📁 [ImageUploadService] Web環境でファイル選択を開始...');
      }

      // HTML input要素を作成
      final html.InputElement uploadInput = html.InputElement();
      uploadInput.type = 'file';
      uploadInput.accept = 'image/*';
      uploadInput.multiple = true; // 複数選択可能
      
      final completer = Completer<List<ImageUploadResult>>();
      
      uploadInput.onChange.listen((e) async {
        final files = uploadInput.files;
        if (files == null || files.isEmpty) {
          if (kDebugMode) {
            print('📁 [ImageUploadService] ファイル選択がキャンセルされました');
          }
          completer.complete(<ImageUploadResult>[]);
          return;
        }

        if (kDebugMode) {
          print('📁 [ImageUploadService] ${files.length}ファイルが選択されました');
        }

        final List<ImageUploadResult> results = [];
        
        for (final file in files) {
          if (!supportedImageTypes.contains(file.type)) {
            results.add(ImageUploadResult(
              status: ImageUploadStatus.failed,
              error: 'サポートされていないファイル形式です: ${file.type}',
            ));
            continue;
          }

          if (file.size > maxFileSize) {
            results.add(ImageUploadResult(
              status: ImageUploadStatus.failed,
              error: 'ファイルサイズが大きすぎます: ${file.name}',
            ));
            continue;
          }

          try {
            final reader = html.FileReader();
            final fileCompleter = Completer<ImageUploadResult>();
            
            reader.readAsArrayBuffer(file);
            
            reader.onLoadEnd.listen((e) async {
              try {
                final bytes = reader.result as List<int>;
                final uint8bytes = Uint8List.fromList(bytes);
                
                final result = await _processAndUploadImage(
                  bytes: uint8bytes,
                  fileName: file.name,
                  mimeType: file.type,
                );
                
                fileCompleter.complete(result);
              } catch (e) {
                fileCompleter.complete(ImageUploadResult(
                  status: ImageUploadStatus.failed,
                  error: '画像処理中にエラーが発生しました: $e',
                ));
              }
            });
            
            reader.onError.listen((e) {
              fileCompleter.complete(ImageUploadResult(
                status: ImageUploadStatus.failed,
                error: 'ファイル読み込み中にエラーが発生しました',
              ));
            });

            final result = await fileCompleter.future;
            results.add(result);
          } catch (e) {
            results.add(ImageUploadResult(
              status: ImageUploadStatus.failed,
              error: 'ファイル処理中にエラーが発生しました: $e',
            ));
          }
        }
        
        completer.complete(results);
      });

      // ファイル選択ダイアログを開く
      uploadInput.click();
      
      return completer.future;
    } catch (e) {
      if (kDebugMode) {
        print('📁 [ImageUploadService] Web環境ファイル選択エラー: $e');
      }
      return [ImageUploadResult(
        status: ImageUploadStatus.failed,
        error: 'ファイル選択中にエラーが発生しました: $e',
      )];
    }
  }

  /// Web環境でのカメラ撮影
  static Future<ImageUploadResult> _captureFromCameraWeb() async {
    try {
      if (kDebugMode) {
        print('📷 [ImageUploadService] カメラ撮影を開始...');
      }

      // HTML input要素を作成してカメラアクセス
      final html.InputElement uploadInput = html.InputElement();
      uploadInput.type = 'file';
      uploadInput.accept = 'image/*';
      uploadInput.setAttribute('capture', 'environment'); // 背面カメラ優先
      uploadInput.setAttribute('multiple', 'false'); // 単一ファイルのみ
      
      final completer = Completer<ImageUploadResult>();
      
      uploadInput.onChange.listen((e) async {
        final files = uploadInput.files;
        if (files == null || files.isEmpty) {
          completer.complete(ImageUploadResult(
            status: ImageUploadStatus.failed,
            error: '写真の撮影をキャンセルしました',
          ));
          return;
        }

        final file = files[0];
        if (!supportedImageTypes.contains(file.type)) {
          completer.complete(ImageUploadResult(
            status: ImageUploadStatus.failed,
            error: 'サポートされていないファイル形式です: ${file.type}',
          ));
          return;
        }

        try {
          final reader = html.FileReader();
          reader.readAsArrayBuffer(file);
          
          reader.onLoadEnd.listen((e) async {
            try {
              final bytes = reader.result as List<int>;
              final uint8bytes = Uint8List.fromList(bytes);
              
              final result = await _processAndUploadImage(
                bytes: uint8bytes,
                fileName: 'camera_${DateTime.now().millisecondsSinceEpoch}.${_getFileExtension(file.name)}',
                mimeType: file.type,
              );
              
              completer.complete(result);
            } catch (e) {
              completer.complete(ImageUploadResult(
                status: ImageUploadStatus.failed,
                error: '画像処理中にエラーが発生しました: $e',
              ));
            }
          });
          
          reader.onError.listen((e) {
            completer.complete(ImageUploadResult(
              status: ImageUploadStatus.failed,
              error: 'ファイル読み込み中にエラーが発生しました',
            ));
          });
        } catch (e) {
          completer.complete(ImageUploadResult(
            status: ImageUploadStatus.failed,
            error: 'ファイル処理中にエラーが発生しました: $e',
          ));
        }
      });

      // ファイル選択ダイアログを開く
      uploadInput.click();
      
      return completer.future;
    } catch (e) {
      return ImageUploadResult(
        status: ImageUploadStatus.failed,
        error: 'カメラアクセス中にエラーが発生しました: $e',
      );
    }
  }

  /// ファイル拡張子を取得
  static String _getFileExtension(String fileName) {
    final parts = fileName.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : 'jpg';
  }

  /// 複数画像の一括削除
  static Future<Map<String, bool>> deleteImages(List<ImageFile> images) async {
    final results = <String, bool>{};
    
    for (final image in images) {
      results[image.id] = await deleteImage(image);
    }
    
    return results;
  }
}

/// ImageMetadata の copyWith メソッドの拡張
extension ImageMetadataExtension on ImageMetadata {
  ImageMetadata copyWith({
    int? width,
    int? height,
    bool? isCompressed,
    int? originalSize,
    double? compressionRatio,
  }) {
    return ImageMetadata(
      width: width ?? this.width,
      height: height ?? this.height,
      isCompressed: isCompressed ?? this.isCompressed,
      originalSize: originalSize ?? this.originalSize,
      compressionRatio: compressionRatio ?? this.compressionRatio,
    );
  }
}