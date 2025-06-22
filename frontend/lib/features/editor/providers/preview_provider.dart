import 'package:flutter/material.dart';

/// プレビューモードの種類
enum PreviewMode {
  preview,    // 読み取り専用プレビュー
  edit,       // 編集モード
  printView,  // 印刷ビューモード
}

/// プレビュー・編集機能の状態管理
class PreviewProvider extends ChangeNotifier {
  PreviewMode _currentMode = PreviewMode.preview;
  String _htmlContent = '';
  bool _isEditing = false;
  bool _isGeneratingPdf = false;
  String _selectedStyle = 'classic';

  // Getters
  PreviewMode get currentMode => _currentMode;
  String get htmlContent => _htmlContent;
  bool get isEditing => _isEditing;
  bool get isGeneratingPdf => _isGeneratingPdf;
  String get selectedStyle => _selectedStyle;

  // プレビューモードの切り替え
  void switchMode(PreviewMode mode) {
    _currentMode = mode;
    _isEditing = mode == PreviewMode.edit;
    notifyListeners();
  }

  // HTMLコンテンツの更新
  void updateHtmlContent(String html) {
    _htmlContent = html;
    notifyListeners();
  }

  // スタイルの選択
  void selectStyle(String style) {
    _selectedStyle = style;
    notifyListeners();
  }

  // 編集状態の設定
  void setEditing(bool isEditing) {
    _isEditing = isEditing;
    if (isEditing) {
      _currentMode = PreviewMode.edit;
    } else {
      _currentMode = PreviewMode.preview;
    }
    notifyListeners();
  }

  // PDF生成状態の管理
  void setPdfGenerating(bool isGenerating) {
    _isGeneratingPdf = isGenerating;
    notifyListeners();
  }

  // PDF生成
  Future<void> generatePdf() async {
    if (_htmlContent.isEmpty) {
      throw Exception('生成するコンテンツがありません');
    }

    setPdfGenerating(true);
    
    try {
      // TODO: 実際のPDF生成処理を実装
      await Future.delayed(const Duration(seconds: 2)); // 模擬処理
      
      // PDF生成成功
    } catch (e) {
      throw Exception('PDF生成に失敗しました: $e');
    } finally {
      setPdfGenerating(false);
    }
  }

  // 印刷プレビューの表示
  Future<void> showPrintPreview() async {
    if (_htmlContent.isEmpty) {
      throw Exception('印刷するコンテンツがありません');
    }

    // 印刷ビューモードに切り替え
    switchMode(PreviewMode.printView);
    
    // TODO: 実際の印刷プレビュー処理を実装
  }

  // コンテンツの再生成
  Future<void> regenerateContent() async {
    // TODO: 既存の入力内容を使ってコンテンツを再生成
    notifyListeners();
  }

  // プレビューのリセット
  void resetPreview() {
    _currentMode = PreviewMode.preview;
    _htmlContent = '';
    _isEditing = false;
    _isGeneratingPdf = false;
    _selectedStyle = 'classic';
    notifyListeners();
  }

  // 編集内容の保存
  void saveEditedContent(String editedHtml) {
    _htmlContent = editedHtml;
    // 編集モードから通常プレビューに戻る
    switchMode(PreviewMode.preview);
  }

  // プレビューモードの文字列表現
  String get currentModeDisplayName {
    switch (_currentMode) {
      case PreviewMode.preview:
        return 'プレビュー';
      case PreviewMode.edit:
        return '編集';
      case PreviewMode.printView:
        return '印刷ビュー';
    }
  }

  // モードに応じたアイコン
  IconData get currentModeIcon {
    switch (_currentMode) {
      case PreviewMode.preview:
        return Icons.preview;
      case PreviewMode.edit:
        return Icons.edit;
      case PreviewMode.printView:
        return Icons.print;
    }
  }
}