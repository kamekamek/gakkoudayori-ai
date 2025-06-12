import 'package:flutter/foundation.dart';
import '../services/delta_converter.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/models/ai_suggestion.dart';
import '../../../core/models/document_data.dart';
import '../../ai_assistant/presentation/widgets/ai_function_button.dart';

/// Quill エディタの状態管理プロバイダー
/// エディタの内容、テーマ、履歴、AI補助機能などを管理
class QuillEditorProvider extends ChangeNotifier {
  // エディタの状態
  bool _isReady = false;
  bool _isLoading = false;
  String? _errorMessage;

  // コンテンツ関連
  String _content = '';
  String _plainText = '';
  Map<String, dynamic> _currentSelection = {};

  // AI補助パネルの表示状態
  bool _isAiAssistVisible = false;
  String _selectedText = '';
  int _cursorPosition = 0;
  bool _isProcessing = false;

  // テーマ管理
  String _currentTheme = 'default';
  static const _validThemes = [
    'default',
    'spring',
    'summer',
    'autumn',
    'winter',
  ];

  // 履歴管理
  final List<String> _history = [];
  int _historyIndex = -1;
  static const int _maxHistorySize = 20;
  bool _hasUnsavedChanges = false;

  // ドキュメント管理
  final Map<String, String> _savedDocuments = {};
  String? _currentDocumentId;
  String _title = '学級通信';
  String _author = '';
  String _grade = '';
  DocumentData? _currentDocument;

  // サービス
  final DeltaConverter _deltaConverter = DeltaConverter();
  dynamic bridgeService;

  // AI補助関連の状態
  String _customInstruction = '';
  List<AISuggestion> _suggestions = [];
  String? _currentSeason = 'spring';
  ApiService? _apiService;

  // AI補助関連のgetters
  String get customInstruction => _customInstruction;
  List<AISuggestion> get suggestions => _suggestions;
  String? get currentSeason => _currentSeason;

  // Getters - エディタ基本状態
  bool get isReady => _isReady;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get content => _content;
  String get plainText => _plainText;
  Map<String, dynamic> get currentSelection => _currentSelection;
  String get currentTheme => _currentTheme;
  bool get hasUnsavedChanges => _hasUnsavedChanges;

  // Getters - AI補助関連
  bool get isAiAssistVisible => _isAiAssistVisible;
  String get selectedText => _selectedText;
  int get cursorPosition => _cursorPosition;
  bool get isProcessing => _isProcessing;

  // Getters - 履歴関連
  bool get canUndo => _historyIndex > 0;
  bool get canRedo => _historyIndex < _history.length - 1;
  int get historySize => _history.length;

  // Getters - 統計情報
  int get wordCount => _plainText.isEmpty
      ? 0
      : _plainText
          .split(RegExp(r'\s+'))
          .where((word) => word.isNotEmpty)
          .length;
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

  /// AI補助パネルを表示
  void showAiAssist({
    required String selectedText,
    required int cursorPosition,
  }) {
    _isAiAssistVisible = true;
    _selectedText = selectedText;
    _cursorPosition = cursorPosition;
    _errorMessage = null;
    notifyListeners();
  }

  /// AI補助パネルを非表示
  void hideAiAssist() {
    _isAiAssistVisible = false;
    _selectedText = '';
    _cursorPosition = 0;
    _errorMessage = null;
    notifyListeners();
  }

  /// 処理中状態を設定
  void setProcessing(bool processing) {
    _isProcessing = processing;
    notifyListeners();
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

  /// ドキュメントを保存（Firebase連携）
  Future<bool> saveDocument({
    String? documentId,
    String? title,
    String? author,
    String? grade,
    List<String>? sections,
  }) async {
    try {
      setLoading(true);
      clearError();

      // ドキュメントデータを作成
      final docId = documentId ?? _currentDocumentId ?? _generateDocumentId();
      final docTitle = title ?? _title;
      final docAuthor = author ?? _author;
      final docGrade = grade ?? _grade;
      
      // Delta形式でコンテンツを取得
      final deltaContent = getDeltaContent();
      
      // DocumentDataを作成または更新
      DocumentData document;
      if (_currentDocument != null) {
        document = _currentDocument!.updated(
          title: docTitle,
          author: docAuthor,
          grade: docGrade,
          sections: sections,
          htmlContent: _content,
          deltaContent: deltaContent,
        );
      } else {
        document = DocumentDataFactory.createNew(
          documentId: docId,
          title: docTitle,
          author: docAuthor,
          grade: docGrade,
          sections: sections ?? [],
        ).copyWith(
          htmlContent: _content,
          deltaContent: deltaContent,
        );
      }

      // Firebaseに保存
      await FirebaseService.instance.saveDocument(document);
      
      // 状態を更新
      _currentDocument = document;
      _currentDocumentId = docId;
      _title = docTitle;
      _author = docAuthor;
      _grade = docGrade;
      _hasUnsavedChanges = false;

      setLoading(false);
      debugPrint('ドキュメント保存成功: $docId');
      return true;
    } catch (e) {
      setError('保存に失敗しました: $e');
      setLoading(false);
      debugPrint('ドキュメント保存エラー: $e');
      return false;
    }
  }

  /// ドキュメントを読み込み（Firebase連携）
  Future<bool> loadDocument(String documentId) async {
    try {
      if (documentId.isEmpty) {
        setError('ドキュメントIDが無効です');
        return false;
      }

      setLoading(true);
      clearError();

      // Firebaseからドキュメントを読み込み
      final document = await FirebaseService.instance.loadDocument(documentId);
      
      if (document != null) {
        // ドキュメントデータを状態に反映
        _currentDocument = document;
        _currentDocumentId = document.documentId;
        _title = document.title;
        _author = document.author;
        _grade = document.grade;
        
        // コンテンツを更新（HTMLがあればそれを使用、なければDeltaから変換）
        if (document.htmlContent?.isNotEmpty == true) {
          updateContent(document.htmlContent!);
        } else if (document.deltaContent?.isNotEmpty == true) {
          setDeltaContent(document.deltaContent!);
        } else {
          updateContent(''); // 空のドキュメント
        }
        
        _hasUnsavedChanges = false;
        setLoading(false);
        debugPrint('ドキュメント読み込み成功: $documentId');
        return true;
      } else {
        setError('ドキュメントが見つかりません');
        setLoading(false);
        return false;
      }
    } catch (e) {
      setError('読み込みに失敗しました: $e');
      setLoading(false);
      debugPrint('ドキュメント読み込みエラー: $e');
      return false;
    }
  }

  /// 新しいドキュメントを作成
  void createNewDocument({
    String? title,
    String? author,
    String? grade,
    List<String>? sections,
  }) {
    _content = '';
    _plainText = '';
    _currentDocumentId = null;
    _currentDocument = null;
    _title = title ?? '学級通信';
    _author = author ?? '';
    _grade = grade ?? '';
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
    // AI補助関連もリセット
    _isAiAssistVisible = false;
    _selectedText = '';
    _cursorPosition = 0;
    _isProcessing = false;
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

  /// API サービスを設定
  void setApiService(ApiService? apiService) {
    _apiService = apiService;
  }

  /// Bridge サービスを設定
  void setBridgeService(dynamic service) {
    bridgeService = service;
  }

  /// カスタム指示を設定
  void setCustomInstruction(String instruction) {
    _customInstruction = instruction;
    notifyListeners();
  }

  /// 季節テーマを設定
  void setCurrentSeason(String season) {
    _currentSeason = season;
    notifyListeners();
  }

  /// AI機能を実行
  Future<void> executeAIFunction(
      AIFunctionType type, ApiService? apiService) async {
    setProcessing(true);

    try {
      final response = await apiService?.callAIAssist(
        action: _getFunctionAction(type),
        selectedText: _selectedText,
        instruction: _customInstruction,
        context: {
          'document_title': _title,
          'season_theme': _currentSeason,
          'cursor_position': _cursorPosition,
        },
      );

      if (response != null && response['success'] == true) {
        _suggestions = (response['suggestions'] as List<dynamic>?)
                ?.map((s) => AISuggestion.fromMap(s as Map<String, dynamic>))
                .toList() ??
            [];
        notifyListeners();
      }
    } catch (e) {
      setError('AI処理でエラーが発生しました: $e');
    } finally {
      setProcessing(false);
    }
  }

  /// カスタム指示を実行
  Future<void> executeCustomInstruction(ApiService? apiService) async {
    if (_customInstruction.trim().isEmpty) return;

    setProcessing(true);

    try {
      final response = await apiService?.callAIAssist(
        action: 'custom_instruction',
        selectedText: _selectedText,
        instruction: _customInstruction,
        context: {
          'document_title': _title,
          'season_theme': _currentSeason,
          'cursor_position': _cursorPosition,
        },
      );

      if (response != null && response['success'] == true) {
        _suggestions = (response['suggestions'] as List<dynamic>?)
                ?.map((s) => AISuggestion.fromMap(s as Map<String, dynamic>))
                .toList() ??
            [];
        notifyListeners();
      }
    } catch (e) {
      setError('AI処理でエラーが発生しました: $e');
    } finally {
      setProcessing(false);
    }
  }

  /// AI提案をエディタに適用
  void applySuggestion(AISuggestion suggestion) {
    if (bridgeService != null) {
      bridgeService!.insertAiContent(
        suggestion.text,
        _cursorPosition,
      );
    }

    // 提案パネルをクリア
    _suggestions.clear();
    notifyListeners();
  }

  /// AI機能タイプからアクション名を取得
  String _getFunctionAction(AIFunctionType type) {
    switch (type) {
      case AIFunctionType.addGreeting:
        return 'add_greeting';
      case AIFunctionType.addSchedule:
        return 'add_schedule';
      case AIFunctionType.rewrite:
        return 'rewrite';
      case AIFunctionType.generateHeading:
        return 'generate_heading';
      case AIFunctionType.summarize:
        return 'summarize';
      case AIFunctionType.expand:
        return 'expand';
    }
  }

  /// ユーザーのドキュメント一覧を取得
  Future<List<DocumentData>> getUserDocuments() async {
    try {
      setLoading(true);
      final documents = await FirebaseService.instance.getUserDocuments();
      setLoading(false);
      return documents;
    } catch (e) {
      setError('ドキュメント一覧の取得に失敗しました: $e');
      setLoading(false);
      return [];
    }
  }

  /// ドキュメントの状態を更新
  Future<bool> updateDocumentStatus(DocumentStatus status) async {
    try {
      if (_currentDocumentId == null) {
        setError('保存されていないドキュメントです');
        return false;
      }

      await FirebaseService.instance.updateDocumentStatus(_currentDocumentId!, status);
      
      if (_currentDocument != null) {
        _currentDocument = _currentDocument!.copyWith(status: status);
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      setError('ステータス更新に失敗しました: $e');
      return false;
    }
  }

  /// ドキュメントを削除
  Future<bool> deleteDocument(String documentId) async {
    try {
      await FirebaseService.instance.deleteDocument(documentId);
      
      // 現在のドキュメントが削除対象なら状態をクリア
      if (_currentDocumentId == documentId) {
        createNewDocument();
      }
      
      return true;
    } catch (e) {
      setError('削除に失敗しました: $e');
      return false;
    }
  }

  /// 現在のドキュメントデータを取得
  DocumentData? get currentDocument => _currentDocument;
  
  /// ドキュメントのタイトルを取得
  String get title => _title;
  
  /// ドキュメントの作成者を取得
  String get author => _author;
  
  /// ドキュメントの学年・クラスを取得
  String get grade => _grade;
  
  /// ドキュメントのタイトルを設定
  void setTitle(String title) {
    _title = title;
    _hasUnsavedChanges = true;
    notifyListeners();
  }
  
  /// ドキュメントの作成者を設定
  void setAuthor(String author) {
    _author = author;
    _hasUnsavedChanges = true;
    notifyListeners();
  }
  
  /// ドキュメントの学年・クラスを設定
  void setGrade(String grade) {
    _grade = grade;
    _hasUnsavedChanges = true;
    notifyListeners();
  }

  /// ドキュメントIDを生成
  String _generateDocumentId() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'doc_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_$random';
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
