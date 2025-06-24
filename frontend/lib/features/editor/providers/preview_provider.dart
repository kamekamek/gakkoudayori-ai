import 'package:flutter/material.dart';
import '../../../services/pdf_api_service.dart';
import '../../../services/pdf_download_service.dart';

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

  // テスト用サンプルHTMLの設定
  void loadSampleContent() {
    const sampleHtml = '''
<h1>🌸 1年1組 学級通信 🌸</h1>
<p><strong>日付:</strong> 2024年6月22日</p>

<h2>📚 今日の学習</h2>
<ul>
  <li><strong>国語:</strong> ひらがなの練習をしました</li>
  <li><strong>算数:</strong> 数の数え方を学びました</li>
  <li><strong>図工:</strong> クレヨンで絵を描きました</li>
</ul>

<h2>🎯 今日のできごと</h2>
<p>今日は朝の会で<span style="color: #e60000;"><strong>みんなで元気よく挨拶</strong></span>ができました。
休み時間には校庭で<em>ドッジボール</em>をして楽しく過ごしました。</p>

<h2>📢 明日の予定</h2>
<ol>
  <li>体育の授業があります → <strong>体操服を忘れずに</strong></li>
  <li>図書の時間があります</li>
  <li>給食は<span style="background-color: #ffeaa7;">カレーライス</span>です</li>
</ol>

<h2>🏠 お家の方へ</h2>
<p>今週も子どもたちはよく頑張りました。宿題の音読を一緒に聞いていただけると嬉しいです。</p>

<p style="text-align: right;"><em>担任: 田中先生</em></p>
''';
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
  Future<void> generatePdf() async {
    if (_htmlContent.isEmpty) {
      throw Exception('生成するコンテンツがありません');
    }

    setPdfGenerating(true);
    
    try {
      // HTMLコンテンツの妥当性チェック
      final validation = PdfApiService.validateHtmlForPdf(_htmlContent);
      if (!validation['isValid']) {
        throw Exception('PDF生成エラー: ${validation['issues'].join(', ')}');
      }

      // バックエンドでPDF生成
      final result = await PdfApiService.generatePdf(
        htmlContent: _htmlContent,
        title: 'AI学級通信',
        pageSize: 'A4',
        margin: '15mm',
        includeHeader: false,
        includeFooter: true,
      );

      // PDF生成成功時にダウンロード
      if (result['success'] == true) {
        final pdfBase64 = result['data']['pdf_base64'];
        final fileSize = result['data']['file_size_mb'];
        
        // PDFをダウンロード
        await PdfDownloadService.downloadPdf(
          pdfBase64: pdfBase64,
          title: 'AI学級通信',
        );

        debugPrint('PDF生成・ダウンロード成功: ${fileSize} MB');
      } else {
        throw Exception(result['error'] ?? 'PDF生成に失敗しました');
      }
    } catch (e) {
      debugPrint('PDF生成エラー: $e');
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