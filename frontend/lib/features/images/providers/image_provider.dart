import 'package:flutter/foundation.dart';
import '../../../core/models/models.dart';
import '../../../core/services/services.dart';
import '../../../core/utils/utils.dart';

/// 画像管理の状態管理
class ImageUploadProvider extends ChangeNotifier {
  final List<ImageFile> _images = [];
  final List<ImageUploadResult> _uploadResults = [];
  
  // アップロード状態
  bool _isUploading = false;
  int _uploadedCount = 0;
  int _totalUploadCount = 0;
  
  // 選択状態
  final Set<String> _selectedImageIds = {};
  ImageFile? _primaryImage;
  
  // フィルター・ソート
  String _searchQuery = '';
  ImageSortType _sortType = ImageSortType.dateDesc;
  
  // エラー状態
  String? _error;

  // Getters
  List<ImageFile> get images => List.unmodifiable(_images);
  List<ImageUploadResult> get uploadResults => List.unmodifiable(_uploadResults);
  bool get isUploading => _isUploading;
  int get uploadedCount => _uploadedCount;
  int get totalUploadCount => _totalUploadCount;
  Set<String> get selectedImageIds => Set.unmodifiable(_selectedImageIds);
  ImageFile? get primaryImage => _primaryImage;
  String get searchQuery => _searchQuery;
  ImageSortType get sortType => _sortType;
  String? get error => _error;
  
  // 計算プロパティ
  bool get hasImages => _images.isNotEmpty;
  bool get hasSelectedImages => _selectedImageIds.isNotEmpty;
  int get selectedCount => _selectedImageIds.length;
  bool get isUploadInProgress => _isUploading && _uploadedCount < _totalUploadCount;
  double get uploadProgress => _totalUploadCount > 0 ? _uploadedCount / _totalUploadCount : 0.0;
  
  List<ImageFile> get filteredImages {
    var filtered = _images.where((image) {
      if (_searchQuery.isEmpty) return true;
      return image.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
    
    // ソート
    switch (_sortType) {
      case ImageSortType.dateAsc:
        filtered.sort((a, b) => a.uploadedAt.compareTo(b.uploadedAt));
        break;
      case ImageSortType.dateDesc:
        filtered.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
        break;
      case ImageSortType.nameAsc:
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case ImageSortType.nameDesc:
        filtered.sort((a, b) => b.name.compareTo(a.name));
        break;
      case ImageSortType.sizeAsc:
        filtered.sort((a, b) => a.size.compareTo(b.size));
        break;
      case ImageSortType.sizeDesc:
        filtered.sort((a, b) => b.size.compareTo(a.size));
        break;
    }
    
    return filtered;
  }

  /// ファイルピッカーから画像をアップロード
  Future<void> uploadFromDevice() async {
    _setUploading(true);
    _clearError();
    
    try {
      final results = await ImageUploadService.pickImagesFromDevice();
      await _processUploadResults(results);
    } catch (e) {
      _error = 'ファイル選択中にエラーが発生しました: $e';
    } finally {
      _setUploading(false);
    }
  }

  /// カメラから画像をアップロード（モバイル専用）
  Future<void> uploadFromCamera() async {
    _setUploading(true);
    _clearError();
    
    try {
      final result = await ImageUploadService.captureFromCamera();
      await _processUploadResults([result]);
    } catch (e) {
      _error = 'カメラ撮影中にエラーが発生しました: $e';
    } finally {
      _setUploading(false);
    }
  }

  /// URLから画像をアップロード
  Future<void> uploadFromUrl(String imageUrl) async {
    if (!AppHelpers.isValidUrl(imageUrl)) {
      _error = '無効なURLです';
      notifyListeners();
      return;
    }
    
    _setUploading(true);
    _clearError();
    
    try {
      final result = await ImageUploadService.fetchFromUrl(imageUrl);
      await _processUploadResults([result]);
    } catch (e) {
      _error = 'URL画像の取得中にエラーが発生しました: $e';
    } finally {
      _setUploading(false);
    }
  }

  /// アップロード結果の処理
  Future<void> _processUploadResults(List<ImageUploadResult> results) async {
    _uploadResults.clear();
    _uploadResults.addAll(results);
    
    _totalUploadCount = results.length;
    _uploadedCount = 0;
    
    for (final result in results) {
      if (result.status == ImageUploadStatus.completed && result.imageFile != null) {
        _images.add(result.imageFile!);
        
        // 最初の画像をプライマリに設定
        _primaryImage ??= result.imageFile!;
      }
      
      _uploadedCount++;
      notifyListeners();
    }
    
    // 失敗した画像があればエラーメッセージを設定
    final failedResults = results.where((r) => r.status == ImageUploadStatus.failed);
    if (failedResults.isNotEmpty) {
      _error = '${failedResults.length}枚の画像アップロードに失敗しました';
    }
  }

  /// 画像削除
  Future<void> deleteImage(String imageId) async {
    final image = _images.firstWhere(
      (img) => img.id == imageId,
      orElse: () => throw StateError('Image not found'),
    );
    
    try {
      final success = await ImageUploadService.deleteImage(image);
      if (success) {
        _images.removeWhere((img) => img.id == imageId);
        _selectedImageIds.remove(imageId);
        
        // プライマリ画像だった場合はクリア
        if (_primaryImage?.id == imageId) {
          _primaryImage = _images.isNotEmpty ? _images.first : null;
        }
        
        notifyListeners();
      } else {
        _error = '画像の削除に失敗しました';
        notifyListeners();
      }
    } catch (e) {
      _error = '画像削除中にエラーが発生しました: $e';
      notifyListeners();
    }
  }

  /// 選択された画像を一括削除
  Future<void> deleteSelectedImages() async {
    if (_selectedImageIds.isEmpty) return;
    
    final imagesToDelete = _images
        .where((img) => _selectedImageIds.contains(img.id))
        .toList();
    
    try {
      final results = await ImageUploadService.deleteImages(imagesToDelete);
      
      // 削除成功した画像をリストから除去
      for (final image in imagesToDelete) {
        if (results[image.id] == true) {
          _images.removeWhere((img) => img.id == image.id);
          
          // プライマリ画像だった場合はクリア
          if (_primaryImage?.id == image.id) {
            _primaryImage = _images.isNotEmpty ? _images.first : null;
          }
        }
      }
      
      _selectedImageIds.clear();
      
      // 失敗した削除があればエラーメッセージ
      final failedCount = results.values.where((success) => !success).length;
      if (failedCount > 0) {
        _error = '${failedCount}枚の画像削除に失敗しました';
      }
      
      notifyListeners();
    } catch (e) {
      _error = '画像削除中にエラーが発生しました: $e';
      notifyListeners();
    }
  }

  /// 画像選択
  void selectImage(String imageId) {
    _selectedImageIds.add(imageId);
    notifyListeners();
  }

  /// 画像選択解除
  void deselectImage(String imageId) {
    _selectedImageIds.remove(imageId);
    notifyListeners();
  }

  /// 画像選択切り替え
  void toggleImageSelection(String imageId) {
    if (_selectedImageIds.contains(imageId)) {
      deselectImage(imageId);
    } else {
      selectImage(imageId);
    }
  }

  /// 全選択
  void selectAllImages() {
    _selectedImageIds.clear();
    _selectedImageIds.addAll(_images.map((img) => img.id));
    notifyListeners();
  }

  /// 全選択解除
  void deselectAllImages() {
    _selectedImageIds.clear();
    notifyListeners();
  }

  /// プライマリ画像設定
  void setPrimaryImage(String imageId) {
    _primaryImage = _images.firstWhere(
      (img) => img.id == imageId,
      orElse: () => throw StateError('Image not found'),
    );
    notifyListeners();
  }

  /// 検索クエリ設定
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// ソートタイプ設定
  void setSortType(ImageSortType sortType) {
    _sortType = sortType;
    notifyListeners();
  }

  /// 画像メタデータ更新
  void updateImageMetadata(String imageId, Map<String, dynamic> metadata) {
    final index = _images.indexWhere((img) => img.id == imageId);
    if (index != -1) {
      // TODO: ImageFileにメタデータ更新メソッドを追加
      // _images[index] = _images[index].copyWith(metadata: metadata);
      notifyListeners();
    }
  }

  /// 特定の画像を取得
  ImageFile? getImageById(String imageId) {
    try {
      return _images.firstWhere((img) => img.id == imageId);
    } catch (e) {
      return null;
    }
  }

  /// 画像をURLから取得
  ImageFile? getImageByUrl(String url) {
    try {
      return _images.firstWhere((img) => img.url == url);
    } catch (e) {
      return null;
    }
  }

  /// 選択された画像を取得
  List<ImageFile> getSelectedImages() {
    return _images.where((img) => _selectedImageIds.contains(img.id)).toList();
  }

  /// ヘルパーメソッド

  void _setUploading(bool uploading) {
    _isUploading = uploading;
    if (!uploading) {
      _uploadedCount = 0;
      _totalUploadCount = 0;
    }
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  /// リセット
  void reset() {
    _images.clear();
    _uploadResults.clear();
    _selectedImageIds.clear();
    _primaryImage = null;
    _searchQuery = '';
    _sortType = ImageSortType.dateDesc;
    _setUploading(false);
    _clearError();
    notifyListeners();
  }

  /// 画像データをエクスポート（学級通信に使用するため）
  List<ImageFile> exportSelectedImages() {
    return getSelectedImages();
  }

  /// 画像データをインポート（学級通信から読み込むため）
  void importImages(List<ImageFile> importedImages) {
    _images.clear();
    _images.addAll(importedImages);
    _selectedImageIds.clear();
    _primaryImage = importedImages.isNotEmpty ? importedImages.first : null;
    notifyListeners();
  }
}

/// 画像ソートタイプ
enum ImageSortType {
  dateAsc,    // 日付昇順
  dateDesc,   // 日付降順
  nameAsc,    // 名前昇順
  nameDesc,   // 名前降順
  sizeAsc,    // サイズ昇順
  sizeDesc,   // サイズ降順
}