import 'package:flutter/foundation.dart';
import '../../../core/models/image_file.dart';
import '../../../services/image_upload_service.dart';

/// 画像管理の状態管理Provider
class ImageManagementProvider extends ChangeNotifier {
  final List<ImageFile> _uploadedImages = [];
  bool _isUploading = false;
  bool _isProcessing = false;
  String _statusMessage = '';
  String? _lastError;

  // Getters
  List<ImageFile> get uploadedImages => List.unmodifiable(_uploadedImages);
  bool get isUploading => _isUploading;
  bool get isProcessing => _isProcessing;
  String get statusMessage => _statusMessage;
  String? get lastError => _lastError;
  bool get hasImages => _uploadedImages.isNotEmpty;
  int get imageCount => _uploadedImages.length;
  bool get canAddMore =>
      _uploadedImages.length < ImageUploadService.maxImageCount;

  /// 総ファイルサイズを取得
  int get totalSize => _uploadedImages.fold(0, (sum, img) => sum + img.size);

  /// 総ファイルサイズの表示文字列
  String get totalSizeDisplay {
    final total = totalSize;
    if (total < 1024) return '${total}B';
    if (total < 1024 * 1024) return '${(total / 1024).toStringAsFixed(1)}KB';
    return '${(total / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  /// ファイル選択から画像を追加
  Future<void> addImagesFromDevice() async {
    if (!canAddMore) {
      _setError('画像は最大${ImageUploadService.maxImageCount}枚まで追加できます');
      return;
    }

    _setUploading(true, '画像を選択中...');
    _clearError();

    try {
      final selectedImages = await ImageUploadService.pickImagesFromDevice();

      if (selectedImages.isEmpty) {
        _setUploading(false, '');
        return;
      }

      await _processAndAddImages(selectedImages);
    } catch (e) {
      _setError('画像の選択に失敗しました: $e');
    } finally {
      _setUploading(false, '');
    }
  }

  /// カメラ撮影から画像を追加
  Future<void> addImageFromCamera() async {
    if (!canAddMore) {
      _setError('画像は最大${ImageUploadService.maxImageCount}枚まで追加できます');
      return;
    }

    _setUploading(true, 'カメラを起動中...');
    _clearError();

    try {
      final capturedImage = await ImageUploadService.captureImageFromCamera();

      if (capturedImage == null) {
        _setUploading(false, '');
        return;
      }

      await _processAndAddImages([capturedImage]);
    } catch (e) {
      _setError('カメラ撮影に失敗しました: $e');
    } finally {
      _setUploading(false, '');
    }
  }

  /// URLから画像を追加
  Future<void> addImageFromUrl(String url) async {
    if (!canAddMore) {
      _setError('画像は最大${ImageUploadService.maxImageCount}枚まで追加できます');
      return;
    }

    if (url.trim().isEmpty) {
      _setError('URLを入力してください');
      return;
    }

    _setUploading(true, 'URLから画像を取得中...');
    _clearError();

    try {
      final fetchedImage = await ImageUploadService.fetchImageFromUrl(url);

      if (fetchedImage == null) {
        _setError('URLから画像を取得できませんでした');
        return;
      }

      await _processAndAddImages([fetchedImage]);
    } catch (e) {
      _setError('URL画像の取得に失敗しました: $e');
    } finally {
      _setUploading(false, '');
    }
  }

  /// 画像を削除
  void removeImage(String imageId) {
    final index = _uploadedImages.indexWhere((img) => img.id == imageId);
    if (index != -1) {
      final removedImage = _uploadedImages.removeAt(index);
      if (kDebugMode)
        debugPrint('🗑️ [ImageProvider] 画像削除: ${removedImage.name}');
      notifyListeners();
    }
  }

  /// 画像を回転
  Future<void> rotateImage(String imageId, int degrees) async {
    final index = _uploadedImages.indexWhere((img) => img.id == imageId);
    if (index == -1) return;

    _setProcessing(true, '画像を回転中...');
    _clearError();

    try {
      final originalImage = _uploadedImages[index];
      final rotatedImage =
          await ImageUploadService.rotateImage(originalImage, degrees);
      _uploadedImages[index] = rotatedImage;

      if (kDebugMode)
        debugPrint('🔄 [ImageProvider] 画像回転完了: ${rotatedImage.name}');
      notifyListeners();
    } catch (e) {
      _setError('画像の回転に失敗しました: $e');
    } finally {
      _setProcessing(false, '');
    }
  }

  /// 全画像をクリア
  void clearAllImages() {
    _uploadedImages.clear();
    _clearError();
    if (kDebugMode) debugPrint('🧹 [ImageProvider] 全画像クリア');
    notifyListeners();
  }

  /// 画像の順序を変更
  void reorderImages(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = _uploadedImages.removeAt(oldIndex);
    _uploadedImages.insert(newIndex, item);

    if (kDebugMode)
      debugPrint('↕️ [ImageProvider] 画像順序変更: $oldIndex → $newIndex');
    notifyListeners();
  }

  /// 特定の画像を取得
  ImageFile? getImage(String imageId) {
    try {
      return _uploadedImages.firstWhere((img) => img.id == imageId);
    } catch (e) {
      return null;
    }
  }

  /// 画像のインデックスを取得
  int getImageIndex(String imageId) {
    return _uploadedImages.indexWhere((img) => img.id == imageId);
  }

  /// 画像を処理して追加
  Future<void> _processAndAddImages(List<ImageFile> images) async {
    _setProcessing(true, '画像を処理中...');

    try {
      final processedImages = await ImageUploadService.processImages(images);

      for (final image in processedImages) {
        if (_uploadedImages.length >= ImageUploadService.maxImageCount) {
          if (kDebugMode) debugPrint('⚠️ [ImageProvider] 画像数上限到達');
          break;
        }

        // 重複チェック
        if (_uploadedImages.any((existing) => existing.id == image.id)) {
          continue;
        }

        _uploadedImages.add(image);
        if (kDebugMode) debugPrint('✅ [ImageProvider] 画像追加: ${image.name}');
      }

      notifyListeners();
    } catch (e) {
      _setError('画像の処理に失敗しました: $e');
    } finally {
      _setProcessing(false, '');
    }
  }

  /// アップロード状態を設定
  void _setUploading(bool isUploading, String message) {
    _isUploading = isUploading;
    _statusMessage = message;
    notifyListeners();
  }

  /// 処理状態を設定
  void _setProcessing(bool isProcessing, String message) {
    _isProcessing = isProcessing;
    _statusMessage = message;
    notifyListeners();
  }

  /// エラーを設定
  void _setError(String error) {
    _lastError = error;
    if (kDebugMode) debugPrint('❌ [ImageProvider] エラー: $error');
    notifyListeners();
  }

  /// エラーをクリア
  void _clearError() {
    _lastError = null;
  }

  /// エラーを手動でクリア
  void clearError() {
    _clearError();
    notifyListeners();
  }

  /// 状態をリセット
  void reset() {
    _uploadedImages.clear();
    _isUploading = false;
    _isProcessing = false;
    _statusMessage = '';
    _lastError = null;
    notifyListeners();
  }

  /// デバッグ情報を出力
  void debugPrintStatus() {
    if (kDebugMode) {
      debugPrint('📊 [ImageProvider] Status:');
      debugPrint(
          '  - Images: ${_uploadedImages.length}/${ImageUploadService.maxImageCount}');
      debugPrint('  - Total size: $totalSizeDisplay');
      debugPrint('  - Uploading: $_isUploading');
      debugPrint('  - Processing: $_isProcessing');
      debugPrint('  - Last error: $_lastError');
      for (int i = 0; i < _uploadedImages.length; i++) {
        final img = _uploadedImages[i];
        debugPrint('  - [$i] ${img.name} (${img.sizeDisplay})');
      }
    }
  }
}
