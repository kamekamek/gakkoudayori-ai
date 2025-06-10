import 'package:flutter/foundation.dart';
import '../services/delta_converter.dart';

/// Quill エディタの状態管理プロバイダー
/// エディタの内容、テーマ、履歴などを管理
class QuillEditorProvider extends ChangeNotifier {
  // エディタの状態
  bool _isReady = false;
  bool _isLoading = false;
  String? _errorMessage;
  
  // コンテンツ関連
  String _content = '';
  String _plainText = '';
  Map<String, dynamic> _currentSelection = {};
  
  // テーマ管理
  String _currentTheme = 'default';
  static const _validThemes = ['default', 'spring', 'summer', 'autumn', 'winter'];
  
  // 履歴管理
  final List<String> _history = [];
  int _historyIndex = -1;
  static const int _maxHistorySize = 20;
  bool _hasUnsavedChanges = false;
  
  // ドキュメント管理
  final Map<String, String> _savedDocuments = {};
  String? _currentDocumentId;
  
  // サービス
  final DeltaConverter _deltaConverter = DeltaConverter();

  // Getters
  bool get isReady => _isReady;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get content => _content;
  String get plainText => _plainText;
  Map<String, dynamic> get currentSelection => _currentSelection;
  String get currentTheme => _currentTheme;
  bool get hasUnsavedChanges => _hasUnsavedChanges;
  
  // 履歴関連
  bool get canUndo => _historyIndex > 0;
  bool get canRedo => _historyIndex < _history.length - 1;
  int get historySize => _history.length;
  
  // 統計情報
  int get wordCount => _plainText.isEmpty ? 0 : _plainText.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
  int get characterCount => _plainText.length;

  /// エディタの準備完了状態を設定
  void setReady(bool ready) {
    if (_isReady != ready) {
      _isReady = ready;
      notifyListeners();
    }
  }

  /// ローディング状態を設定
  void setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  /// エラーメッセージを設定
  void setError(String? error) {
    if (_errorMessage != error) {
      _errorMessage = error;
      notifyListeners();
    }
  }

  /// エラーメッセージをクリア
  void clearError() {
    setError(null);
  }

  /// コンテンツを更新
  void updateContent(String newContent) {
    if (_content != newContent) {
      // 最初の更新または空でない場合のみ履歴に追加
      if (_content.isNotEmpty || _history.isEmpty) {
        _addToHistory(_content);
      }
      _content = newContent;
      _plainText = _extractPlainText(newContent);
      _hasUnsavedChanges = true;
      notifyListeners();
    }
  }

  /// プレーンテキストを抽出
  String _extractPlainText(String htmlContent) {
    try {
      // HTMLタグを除去してプレーンテキストを取得
      return htmlContent
          .replaceAll(RegExp(r'<[^>]*>'), '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
    } catch (e) {
      debugPrint('Error extracting plain text: $e');
      return htmlContent;
    }
  }

  /// 履歴に追加
  void _addToHistory(String content) {
    // 現在の位置より後の履歴を削除
    if (_historyIndex < _history.length - 1) {
      _history.removeRange(_historyIndex + 1, _history.length);
    }
    
    // 新しいエントリを追加
    _history.add(content);
    _historyIndex = _history.length - 1;
    
    // 履歴サイズ制限
    if (_history.length > _maxHistorySize) {
      _history.removeAt(0);
      _historyIndex--;
    }
  }

  /// アンドゥ操作
  void undo() {
    if (canUndo) {
      _historyIndex--;
      _content = _history[_historyIndex];
      _plainText = _extractPlainText(_content);
      _hasUnsavedChanges = true;
      notifyListeners();
    }
  }

  /// リドゥ操作
  void redo() {
    if (canRedo) {
      _historyIndex++;
      _content = _history[_historyIndex];
      _plainText = _extractPlainText(_content);
      _hasUnsavedChanges = true;
      notifyListeners();
    }
  }

  /// テーマを変更
  void changeTheme(String themeName) {
    if (_validThemes.contains(themeName) && _currentTheme != themeName) {
      _currentTheme = themeName;
      notifyListeners();
    }
  }

  /// ドキュメントを保存
  Future<bool> saveDocument(String documentId) async {
    try {
      if (documentId.isEmpty) {
        setError('ドキュメントIDが無効です');
        return false;
      }
      
      setLoading(true);
      clearError();
      
      // シミュレーション: 実際の実装ではFirestoreに保存
      await Future.delayed(const Duration(milliseconds: 500));
      
      _savedDocuments[documentId] = _content;
      _currentDocumentId = documentId;
      _hasUnsavedChanges = false;
      
      setLoading(false);
      return true;
    } catch (e) {
      setError('保存に失敗しました: $e');
      setLoading(false);
      return false;
    }
  }

  /// ドキュメントを読み込み
  Future<bool> loadDocument(String documentId) async {
    try {
      if (documentId.isEmpty) {
        setError('ドキュメントIDが無効です');
        return false;
      }
      
      setLoading(true);
      clearError();
      
      // シミュレーション: 実際の実装ではFirestoreから読み込み
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (_savedDocuments.containsKey(documentId)) {
        updateContent(_savedDocuments[documentId]!);
        _currentDocumentId = documentId;
        _hasUnsavedChanges = false;
        
        setLoading(false);
        return true;
      } else {
        setError('ドキュメントが見つかりません');
        setLoading(false);
        return false;
      }
    } catch (e) {
      setError('読み込みに失敗しました: $e');
      setLoading(false);
      return false;
    }
  }

  /// 新しいドキュメントを作成
  void createNewDocument() {
    _content = '';
    _plainText = '';
    _currentDocumentId = null;
    _hasUnsavedChanges = false;
    _history.clear();
    _historyIndex = -1;
    clearError();
    notifyListeners();
  }

  /// エディタからのコンテンツ変更通知
  void onEditorContentChanged(String newContent) {
    updateContent(newContent);
  }

  /// エディタからの選択範囲変更通知
  void onEditorSelectionChanged(Map<String, dynamic> selection) {
    _currentSelection = selection;
    notifyListeners();
  }

  /// Delta形式のコンテンツを設定
  void setDeltaContent(String deltaJson) {
    try {
      final htmlContent = _deltaConverter.deltaToHtml(deltaJson);
      updateContent(htmlContent);
    } catch (e) {
      setError('Delta変換に失敗しました: $e');
    }
  }

  /// Delta形式でコンテンツを取得
  String? getDeltaContent() {
    try {
      return _deltaConverter.htmlToDelta(_content);
    } catch (e) {
      setError('HTML変換に失敗しました: $e');
      return null;
    }
  }

  /// コンテンツをクリア
  void clearContent() {
    updateContent('');
  }

  /// 指定位置にテキストを挿入
  void insertTextAtPosition(String text, {int? position}) {
    // 簡易実装: HTMLの末尾に追加
    final newContent = _content + text;
    updateContent(newContent);
  }

  /// エディタの状態をリセット
  void reset() {
    _isReady = false;
    _isLoading = false;
    _errorMessage = null;
    _content = '';
    _plainText = '';
    _currentSelection = {};
    _currentTheme = 'default';
    _history.clear();
    _historyIndex = -1;
    _hasUnsavedChanges = false;
    _currentDocumentId = null;
    notifyListeners();
  }

  /// 統計情報を取得
  EditorStatistics getStatistics() {
    return EditorStatistics(
      wordCount: wordCount,
      characterCount: characterCount,
      characterCountWithSpaces: _content.length,
      lineCount: _content.split('\n').length,
      hasUnsavedChanges: _hasUnsavedChanges,
      currentTheme: _currentTheme,
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

/// エディタの統計情報
class EditorStatistics {
  final int wordCount;
  final int characterCount;
  final int characterCountWithSpaces;
  final int lineCount;
  final bool hasUnsavedChanges;
  final String currentTheme;

  const EditorStatistics({
    required this.wordCount,
    required this.characterCount,
    required this.characterCountWithSpaces,
    required this.lineCount,
    required this.hasUnsavedChanges,
    required this.currentTheme,
  });

  @override
  String toString() {
    return 'EditorStatistics(words: $wordCount, chars: $characterCount, lines: $lineCount, unsaved: $hasUnsavedChanges, theme: $currentTheme)';
  }
}