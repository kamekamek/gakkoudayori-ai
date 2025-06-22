import 'package:flutter/foundation.dart';
import '../../../core/models/models.dart';
import '../../../core/services/services.dart';
import '../../../core/utils/utils.dart';

/// 学級通信の編集・管理状態
class NewsletterProvider extends ChangeNotifier {
  Newsletter? _currentNewsletter;
  List<Newsletter> _savedNewsletters = [];
  
  // 編集状態
  bool _isEditing = false;
  bool _hasUnsavedChanges = false;
  PreviewMode _previewMode = PreviewMode.preview;
  
  // HTML/コンテンツ状態
  String _htmlContent = '';
  String _plainTextContent = '';
  
  // PDF生成状態
  bool _isGeneratingPdf = false;
  PdfGenerationResult? _lastPdfResult;
  
  // 画像管理
  final List<ImageFile> _images = [];
  bool _isUploadingImages = false;
  
  // エラー状態
  String? _error;

  // Getters
  Newsletter? get currentNewsletter => _currentNewsletter;
  List<Newsletter> get savedNewsletters => List.unmodifiable(_savedNewsletters);
  bool get isEditing => _isEditing;
  bool get hasUnsavedChanges => _hasUnsavedChanges;
  PreviewMode get previewMode => _previewMode;
  String get htmlContent => _htmlContent;
  String get plainTextContent => _plainTextContent;
  bool get isGeneratingPdf => _isGeneratingPdf;
  PdfGenerationResult? get lastPdfResult => _lastPdfResult;
  List<ImageFile> get images => List.unmodifiable(_images);
  bool get isUploadingImages => _isUploadingImages;
  String? get error => _error;
  
  // 計算プロパティ
  bool get hasCurrentNewsletter => _currentNewsletter != null;
  bool get canEdit => hasCurrentNewsletter && !_isGeneratingPdf;
  bool get canSave => hasCurrentNewsletter && _hasUnsavedChanges;
  bool get canGeneratePdf => hasCurrentNewsletter && _htmlContent.isNotEmpty;
  int get imageCount => _images.length;
  bool get hasImages => _images.isNotEmpty;

  /// 新しい学級通信を作成
  void createNewNewsletter({
    required String title,
    required NewsletterMetadata metadata,
    NewsletterStyle style = NewsletterStyle.classic,
  }) {
    final now = DateTime.now();
    _currentNewsletter = Newsletter(
      id: AppHelpers.generateId(12),
      title: title,
      content: '',
      style: style,
      metadata: metadata,
      createdAt: now,
      updatedAt: now,
      status: NewsletterStatus.draft,
    );
    
    _resetEditingState();
    _isEditing = true;
    _clearError();
    notifyListeners();
  }

  /// 既存の学級通信を読み込み
  void loadNewsletter(Newsletter newsletter) {
    _currentNewsletter = newsletter;
    _htmlContent = newsletter.content;
    _images.clear();
    _images.addAll(newsletter.images);
    _resetEditingState();
    _clearError();
    notifyListeners();
  }

  /// 編集モード切り替え
  void setEditingMode(bool editing) {
    _isEditing = editing;
    notifyListeners();
  }

  /// プレビューモード変更
  void setPreviewMode(PreviewMode mode) {
    _previewMode = mode;
    notifyListeners();
  }

  /// HTMLコンテンツ更新
  void updateHtmlContent(String html) {
    if (_htmlContent != html) {
      _htmlContent = html;
      _plainTextContent = html.stripHtmlTags();
      _setUnsavedChanges(true);
      
      // 現在の学級通信のコンテンツも更新
      if (_currentNewsletter != null) {
        _currentNewsletter = _currentNewsletter!.copyWith(
          content: html,
          updatedAt: DateTime.now(),
        );
      }
      
      notifyListeners();
    }
  }

  /// タイトル更新
  void updateTitle(String title) {
    if (_currentNewsletter != null && _currentNewsletter!.title != title) {
      _currentNewsletter = _currentNewsletter!.copyWith(
        title: title,
        updatedAt: DateTime.now(),
      );
      _setUnsavedChanges(true);
      notifyListeners();
    }
  }

  /// スタイル変更
  void updateStyle(NewsletterStyle style) {
    if (_currentNewsletter != null && _currentNewsletter!.style != style) {
      _currentNewsletter = _currentNewsletter!.copyWith(
        style: style,
        updatedAt: DateTime.now(),
      );
      _setUnsavedChanges(true);
      notifyListeners();
    }
  }

  /// ステータス更新
  void updateStatus(NewsletterStatus status) {
    if (_currentNewsletter != null && _currentNewsletter!.status != status) {
      _currentNewsletter = _currentNewsletter!.copyWith(
        status: status,
        updatedAt: DateTime.now(),
      );
      _setUnsavedChanges(true);
      notifyListeners();
    }
  }

  /// 画像追加
  Future<void> addImage(ImageFile image) async {
    _images.add(image);
    
    // 現在の学級通信の画像リストも更新
    if (_currentNewsletter != null) {
      _currentNewsletter = _currentNewsletter!.copyWith(
        images: List.from(_images),
        updatedAt: DateTime.now(),
      );
    }
    
    _setUnsavedChanges(true);
    notifyListeners();
  }

  /// 複数画像追加
  Future<void> addImages(List<ImageFile> newImages) async {
    _setUploadingImages(true);
    
    try {
      for (final image in newImages) {
        await addImage(image);
      }
    } catch (e) {
      _error = '画像の追加中にエラーが発生しました: $e';
    } finally {
      _setUploadingImages(false);
    }
  }

  /// 画像削除
  Future<void> removeImage(String imageId) async {
    final imageIndex = _images.indexWhere((img) => img.id == imageId);
    if (imageIndex != -1) {
      final image = _images[imageIndex];
      
      // Firebase Storageから削除
      final deleteSuccess = await ImageUploadService.deleteImage(image);
      if (deleteSuccess) {
        _images.removeAt(imageIndex);
        
        // 現在の学級通信の画像リストも更新
        if (_currentNewsletter != null) {
          _currentNewsletter = _currentNewsletter!.copyWith(
            images: List.from(_images),
            updatedAt: DateTime.now(),
          );
        }
        
        _setUnsavedChanges(true);
        notifyListeners();
      } else {
        _error = '画像の削除に失敗しました';
        notifyListeners();
      }
    }
  }

  /// 画像並び替え
  void reorderImages(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    
    final image = _images.removeAt(oldIndex);
    _images.insert(newIndex, image);
    
    // 現在の学級通信の画像リストも更新
    if (_currentNewsletter != null) {
      _currentNewsletter = _currentNewsletter!.copyWith(
        images: List.from(_images),
        updatedAt: DateTime.now(),
      );
    }
    
    _setUnsavedChanges(true);
    notifyListeners();
  }

  /// PDF生成
  Future<void> generatePdf({
    PdfGenerationSettings? settings,
  }) async {
    if (!canGeneratePdf) return;
    
    _setGeneratingPdf(true);
    _clearError();
    
    try {
      // TODO: PDF生成サービスとの統合
      await Future.delayed(const Duration(seconds: 2)); // シミュレーション
      
      // 仮のPDF結果を作成
      _lastPdfResult = PdfGenerationResult(
        success: true,
        fileName: '${_currentNewsletter!.title}_${DateTime.now().millisecondsSinceEpoch}.pdf',
        fileSize: 1024 * 1024, // 1MB
      );
      
      // ステータスを完成に更新
      updateStatus(NewsletterStatus.completed);
    } catch (e) {
      _error = 'PDF生成中にエラーが発生しました: $e';
      _lastPdfResult = PdfGenerationResult(
        success: false,
        error: e.toString(),
      );
    } finally {
      _setGeneratingPdf(false);
    }
  }

  /// 学級通信保存
  Future<void> saveNewsletter() async {
    if (!canSave) return;
    
    try {
      // TODO: Firebase/ローカルストレージに保存
      
      // 保存済みリストに追加/更新
      final existingIndex = _savedNewsletters.indexWhere(
        (n) => n.id == _currentNewsletter!.id,
      );
      
      if (existingIndex != -1) {
        _savedNewsletters[existingIndex] = _currentNewsletter!;
      } else {
        _savedNewsletters.add(_currentNewsletter!);
      }
      
      _setUnsavedChanges(false);
      _clearError();
      notifyListeners();
    } catch (e) {
      _error = '保存中にエラーが発生しました: $e';
      notifyListeners();
    }
  }

  /// 自動保存
  Future<void> autoSave() async {
    if (hasUnsavedChanges && hasCurrentNewsletter) {
      await saveNewsletter();
    }
  }

  /// 学級通信削除
  Future<void> deleteNewsletter(String newsletterId) async {
    try {
      // 画像も削除
      final newsletter = _savedNewsletters.firstWhere(
        (n) => n.id == newsletterId,
        orElse: () => throw StateError('Newsletter not found'),
      );
      
      await ImageUploadService.deleteImages(newsletter.images);
      
      // リストから削除
      _savedNewsletters.removeWhere((n) => n.id == newsletterId);
      
      // 現在の学級通信だった場合はクリア
      if (_currentNewsletter?.id == newsletterId) {
        _currentNewsletter = null;
        _resetEditingState();
      }
      
      notifyListeners();
    } catch (e) {
      _error = '削除中にエラーが発生しました: $e';
      notifyListeners();
    }
  }

  /// 学級通信複製
  Future<void> duplicateNewsletter(String newsletterId) async {
    try {
      final original = _savedNewsletters.firstWhere(
        (n) => n.id == newsletterId,
        orElse: () => throw StateError('Newsletter not found'),
      );
      
      final now = DateTime.now();
      final duplicate = Newsletter(
        id: AppHelpers.generateId(12),
        title: '${original.title} (コピー)',
        content: original.content,
        style: original.style,
        images: original.images, // 同じ画像を参照
        metadata: original.metadata,
        createdAt: now,
        updatedAt: now,
        status: NewsletterStatus.draft,
      );
      
      _savedNewsletters.add(duplicate);
      notifyListeners();
    } catch (e) {
      _error = '複製中にエラーが発生しました: $e';
      notifyListeners();
    }
  }

  /// 保存済み学級通信読み込み
  Future<void> loadSavedNewsletters() async {
    try {
      // TODO: Firebase/ローカルストレージから読み込み
      _clearError();
      notifyListeners();
    } catch (e) {
      _error = '学級通信の読み込み中にエラーが発生しました: $e';
      notifyListeners();
    }
  }

  /// ヘルパーメソッド

  void _resetEditingState() {
    _isEditing = false;
    _hasUnsavedChanges = false;
    _htmlContent = _currentNewsletter?.content ?? '';
    _plainTextContent = _htmlContent.stripHtmlTags();
  }

  void _setUnsavedChanges(bool hasChanges) {
    _hasUnsavedChanges = hasChanges;
  }

  void _setGeneratingPdf(bool generating) {
    _isGeneratingPdf = generating;
    notifyListeners();
  }

  void _setUploadingImages(bool uploading) {
    _isUploadingImages = uploading;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  /// リセット
  void reset() {
    _currentNewsletter = null;
    _savedNewsletters.clear();
    _images.clear();
    _resetEditingState();
    _previewMode = PreviewMode.preview;
    _lastPdfResult = null;
    _clearError();
    notifyListeners();
  }
}