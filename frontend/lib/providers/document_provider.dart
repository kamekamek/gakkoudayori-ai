import 'package:flutter/foundation.dart';
import '../models/document.dart';
import '../services/document_history_service.dart';

/// ドキュメント履歴管理Provider
/// UI の状態管理と DocumentHistoryService の統合
class DocumentProvider extends ChangeNotifier {
  final DocumentHistoryService _historyService;

  // 状態管理
  List<Document> _drafts = [];
  List<Document> _recentDocuments = [];
  Document? _currentDocument;
  bool _isLoading = false;
  bool _isAutoSaving = false;
  String? _errorMessage;

  // Getters
  List<Document> get drafts => _drafts;
  List<Document> get recentDocuments => _recentDocuments;
  Document? get currentDocument => _currentDocument;
  bool get isLoading => _isLoading;
  bool get isAutoSaving => _isAutoSaving;
  String? get errorMessage => _errorMessage;

  DocumentProvider({DocumentHistoryService? historyService})
      : _historyService = historyService ?? DocumentHistoryService();

  /// 下書き一覧を読み込み
  Future<void> loadDrafts(String userId) async {
    _setLoading(true);
    try {
      _drafts = await _historyService.getUserDrafts(userId);
      _clearError();
    } catch (e) {
      _setError('下書き読み込みに失敗しました: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 最近のドキュメント一覧を読み込み
  Future<void> loadRecentDocuments(String userId) async {
    _setLoading(true);
    try {
      _recentDocuments =
          await _historyService.getUserDocuments(userId, limit: 10);
      _clearError();
    } catch (e) {
      _setError('最近のドキュメント読み込みに失敗しました: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 新しいドキュメントを作成
  void createNewDocument(String userId) {
    _currentDocument = Document(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      title: '新しい通信',
      content: '',
      htmlContent: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      thumbnail: '📄',
      status: DocumentStatus.draft,
    );
    notifyListeners();
  }

  /// ドキュメントを開く
  void openDocument(Document document) {
    _currentDocument = document;
    notifyListeners();
  }

  /// 現在のドキュメントを更新
  void updateCurrentDocument({
    String? title,
    String? content,
    String? htmlContent,
  }) {
    if (_currentDocument == null) return;

    _currentDocument = _currentDocument!.copyWith(
      title: title,
      content: content,
      htmlContent: htmlContent,
      updatedAt: DateTime.now(),
    );
    notifyListeners();

    // 自動保存をトリガー
    _triggerAutoSave();
  }

  /// 下書き保存
  Future<bool> saveDraft() async {
    if (_currentDocument == null) return false;

    try {
      final success = await _historyService.saveDraft(_currentDocument!);
      if (success) {
        _clearError();
        // 下書き一覧を更新
        if (_currentDocument!.userId.isNotEmpty) {
          await loadDrafts(_currentDocument!.userId);
        }
      } else {
        _setError('下書き保存に失敗しました');
      }
      return success;
    } catch (e) {
      _setError('下書き保存エラー: $e');
      return false;
    }
  }

  /// ドキュメント削除
  Future<bool> deleteDocument(String documentId) async {
    try {
      final success = await _historyService.deleteDocument(documentId);
      if (success) {
        _drafts.removeWhere((doc) => doc.id == documentId);
        _recentDocuments.removeWhere((doc) => doc.id == documentId);

        // 現在開いているドキュメントが削除対象の場合はクリア
        if (_currentDocument?.id == documentId) {
          _currentDocument = null;
        }

        _clearError();
        notifyListeners();
      } else {
        _setError('ドキュメント削除に失敗しました');
      }
      return success;
    } catch (e) {
      _setError('削除エラー: $e');
      return false;
    }
  }

  /// 完了マーク（配信済みに変更）
  Future<bool> markAsCompleted(String documentId) async {
    try {
      final success = await _historyService.markAsCompleted(documentId);
      if (success) {
        // ローカル状態を更新
        _updateDocumentStatus(documentId, DocumentStatus.published);
        _clearError();
      } else {
        _setError('完了マークに失敗しました');
      }
      return success;
    } catch (e) {
      _setError('完了マークエラー: $e');
      return false;
    }
  }

  /// アーカイブから復元
  Future<bool> restoreFromArchive(String documentId) async {
    try {
      final success = await _historyService.restoreFromArchive(documentId);
      if (success) {
        _updateDocumentStatus(documentId, DocumentStatus.draft);
        _clearError();
      } else {
        _setError('復元に失敗しました');
      }
      return success;
    } catch (e) {
      _setError('復元エラー: $e');
      return false;
    }
  }

  /// 自動保存のトリガー（デバウンス処理）
  void _triggerAutoSave() {
    if (_isAutoSaving || _currentDocument == null) return;

    // 3秒後に自動保存（実際の実装ではタイマーを使用）
    Future.delayed(const Duration(seconds: 3), () async {
      if (_currentDocument != null) {
        _setAutoSaving(true);
        await _historyService.autoSave(_currentDocument!);
        _setAutoSaving(false);
      }
    });
  }

  /// ローカル状態でドキュメントステータスを更新
  void _updateDocumentStatus(String documentId, DocumentStatus newStatus) {
    // 下書き一覧を更新
    final draftIndex = _drafts.indexWhere((doc) => doc.id == documentId);
    if (draftIndex != -1) {
      _drafts[draftIndex] = _drafts[draftIndex].copyWith(
        status: newStatus,
        updatedAt: DateTime.now(),
      );
    }

    // 最近のドキュメント一覧を更新
    final recentIndex =
        _recentDocuments.indexWhere((doc) => doc.id == documentId);
    if (recentIndex != -1) {
      _recentDocuments[recentIndex] = _recentDocuments[recentIndex].copyWith(
        status: newStatus,
        updatedAt: DateTime.now(),
      );
    }

    // 現在のドキュメントを更新
    if (_currentDocument?.id == documentId) {
      _currentDocument = _currentDocument!.copyWith(
        status: newStatus,
        updatedAt: DateTime.now(),
      );
    }

    notifyListeners();
  }

  /// ローディング状態設定
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// 自動保存状態設定
  void _setAutoSaving(bool autoSaving) {
    _isAutoSaving = autoSaving;
    notifyListeners();
  }

  /// エラーメッセージ設定
  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  /// エラーメッセージクリア
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// エラーメッセージを手動でクリア
  void clearErrorMessage() {
    _clearError();
  }
}
