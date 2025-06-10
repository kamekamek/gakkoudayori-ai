import 'package:flutter/foundation.dart';

/// Quillエディターの状態管理を行うProvider
class QuillEditorProvider extends ChangeNotifier {
  // AI補助パネルの表示状態
  bool _isAiAssistVisible = false;
  bool get isAiAssistVisible => _isAiAssistVisible;

  // 選択されたテキスト
  String _selectedText = '';
  String get selectedText => _selectedText;

  // カーソル位置
  int _cursorPosition = 0;
  int get cursorPosition => _cursorPosition;

  // 処理中フラグ
  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  // エラーメッセージ
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

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

  /// エラーを設定
  void setError(String error) {
    _errorMessage = error;
    _isProcessing = false;
    notifyListeners();
  }

  /// エラーをクリア
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}