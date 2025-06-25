import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../mock/sample_data.dart';
import '../../../services/adk_agent_service.dart';
import '../../../services/graphical_record_service.dart';
import 'dart:html' as html;

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
  String? _lastUsedPrompt; // 最後に使用されたプロンプトを保存
  final AdkAgentService _adkService = AdkAgentService();

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

  // テスト用サンプルHTMLの設定
  void loadSampleContent() {
    // ランダムにモダンかクラシックかを選択
    final useModern = DateTime.now().millisecond % 2 == 0;
    final style = useModern ? 'modern' : 'classic';
    
    final sampleHtml = MockSampleData.generateNewsletterHtml(
      style: style,
      month: DateTime.now().month.toString(),
      day: DateTime.now().day.toString(),
      eventDate: '${DateTime.now().month}月${DateTime.now().add(Duration(days: 7)).day}日（土）',
      schoolName: '〇〇小学校',
      className: '1年1組',
      teacherName: '田中先生',
    );
    
    _selectedStyle = style;
    updateHtmlContent(sampleHtml);
  }

  // コンテンツをクリア
  void clearContent() {
    _htmlContent = '';
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
  Future<void> generatePdf(BuildContext context) async {
    if (_htmlContent.isEmpty) {
      throw Exception('PDFを生成するコンテンツがありません。');
    }
    setPdfGenerating(true);
    try {
      final result = await context.read<GraphicalRecordService>().convertHtmlToPdf(_htmlContent);
      if (result.success && result.pdfData != null) {
        final blob = html.Blob([result.pdfData!], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', 'GakkyuTsuushin.pdf')
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        throw Exception(result.error ?? 'PDF data is null.');
      }
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
    
    // ブラウザの印刷プレビューを表示
    html.window.print();
  }

  // コンテンツの再生成
  Future<void> regenerateContent() async {
    if (_lastUsedPrompt == null || _lastUsedPrompt!.isEmpty) {
      // 最初の生成時はサンプルプロンプトを使用
      _lastUsedPrompt = '今月の学級通信を作成してください。子どもたちの様子や最近の行事について盛り込んでください。';
    }
    
    try {
      final response = await _adkService.startNewsletterGeneration(
        initialRequest: _lastUsedPrompt!,
        userId: 'demo-user', // TODO: 実際のユーザーIDを使用
      );
      
      if (response.htmlContent != null) {
        updateHtmlContent(response.htmlContent!);
      }
    } catch (e) {
      throw Exception('コンテンツの再生成に失敗しました: $e');
    }
    notifyListeners();
  }
  
  // プロンプトを設定してコンテンツを生成
  Future<void> generateContentFromPrompt(String prompt) async {
    _lastUsedPrompt = prompt;
    await regenerateContent();
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