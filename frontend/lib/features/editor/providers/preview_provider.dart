import 'package:flutter/material.dart';
import '../../../services/pdf_api_service.dart';
import '../../../services/pdf_download_service.dart';
import '../../../core/exceptions/app_exceptions.dart';
import '../../../core/providers/error_provider.dart';

/// プレビューモードの種類
enum PreviewMode {
  preview,    // 読み取り専用プレビュー
  edit,       // 編集モード
  printView,  // 印刷ビューモード
}

/// プレビュー・編集機能の状態管理
class PreviewProvider extends ChangeNotifier {
  final ErrorProvider _errorProvider;
  
  PreviewMode _currentMode = PreviewMode.preview;
  String _htmlContent = '';
  bool _isEditing = false;
  bool _isGeneratingPdf = false;
  String _selectedStyle = 'classic';

  PreviewProvider({required ErrorProvider errorProvider})
      : _errorProvider = errorProvider;

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
    try {
      if (html.trim().isEmpty) {
        throw ValidationException.required('HTML content');
      }
      
      // 基本的なHTMLバリデーション
      _validateHtmlContent(html);
      
      _htmlContent = html;
      notifyListeners();
    } catch (error, stackTrace) {
      _errorProvider.reportError(
        error,
        stackTrace: stackTrace,
        context: 'Updating HTML content',
      );
      rethrow;
    }
  }

  /// HTMLコンテンツのバリデーション
  void _validateHtmlContent(String html) {
    // 基本的なHTMLタグの存在確認
    if (!html.contains('<') || !html.contains('>')) {
      throw ValidationException.invalidFormat('HTML', 'Missing HTML tags');
    }
    
    // 潜在的に危険なタグの検出
    final dangerousTags = ['<script', '<iframe', '<object', '<embed'];
    for (final tag in dangerousTags) {
      if (html.toLowerCase().contains(tag)) {
        throw ValidationException.invalidFormat('HTML', 'Dangerous tag detected: $tag');
      }
    }
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
    await _errorProvider.retryOperation(
      () => _generatePdfWithRetry(),
      context: 'PDF generation',
    );
  }

  /// リトライ機能付きPDF生成の実装
  Future<void> _generatePdfWithRetry() async {
    if (_htmlContent.isEmpty) {
      throw ContentException.generationFailed('No content to generate PDF');
    }

    setPdfGenerating(true);
    
    try {
      // HTMLコンテンツの妥当性チェック
      final validation = PdfApiService.validateHtmlForPdf(_htmlContent);
      if (!validation['isValid']) {
        final issues = validation['issues'] as List<String>;
        throw ContentException.invalidFormat();
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
        final errorMessage = result['error'] ?? 'PDF生成に失敗しました';
        throw ContentException.generationFailed(errorMessage);
      }
    } catch (error, stackTrace) {
      debugPrint('PDF生成エラー: $error');
      
      // エラーを適切な例外に変換
      final exception = error is AppException
          ? error
          : ContentException.generationFailed(error.toString());
      
      _errorProvider.reportError(
        exception,
        stackTrace: stackTrace,
        context: 'PDF generation process',
      );
      
      rethrow;
    } finally {
      setPdfGenerating(false);
    }
  }

  // 印刷プレビューの表示
  Future<void> showPrintPreview() async {
    try {
      if (_htmlContent.isEmpty) {
        throw ContentException.generationFailed('No content to print');
      }

      // 印刷ビューモードに切り替え
      switchMode(PreviewMode.printView);
      
      // Web環境での印刷プレビュー実装
      debugPrint('印刷プレビューモードに切り替えました');
      
      // 印刷用のCSSスタイルを適用したHTMLを生成
      final printHtml = _generatePrintHtml(_htmlContent);
      
      // ブラウザの印刷ダイアログを開く場合
      // html.window.print(); // 必要に応じてコメントアウト解除
      
      debugPrint('印刷プレビュー準備完了');
    } catch (error, stackTrace) {
      debugPrint('印刷プレビューエラー: $error');
      
      final exception = error is AppException
          ? error
          : ContentException.generationFailed(error.toString());
      
      _errorProvider.reportError(
        exception,
        stackTrace: stackTrace,
        context: 'Print preview display',
      );
      
      rethrow;
    }
  }
  
  // 印刷用のHTMLを生成
  String _generatePrintHtml(String html) {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <title>学級通信 - 印刷用</title>
      <style>
        @media print {
          body { 
            font-family: 'Noto Sans JP', 'Yu Gothic', 'Hiragino Sans', sans-serif;
            font-size: 12pt;
            line-height: 1.5;
            margin: 0;
            padding: 20mm;
          }
          h1 { 
            font-size: 18pt;
            color: #000;
            border-bottom: 2px solid #000;
            padding-bottom: 10px;
            margin-bottom: 20px;
          }
          h2 { 
            font-size: 14pt;
            color: #000;
            margin-top: 20px;
            margin-bottom: 10px;
          }
          .no-print { display: none !important; }
          .page-break { page-break-before: always; }
        }
        body { 
          font-family: 'Noto Sans JP', 'Yu Gothic', 'Hiragino Sans', sans-serif;
          max-width: 210mm;
          margin: 0 auto;
          padding: 20mm;
          background: white;
        }
      </style>
    </head>
    <body>
      $html
    </body>
    </html>
    ''';
  }

  // コンテンツの再生成
  Future<void> regenerateContent() async {
    if (_htmlContent.isEmpty) {
      debugPrint('再生成するコンテンツがありません');
      return;
    }
    
    // 再生成中状態に設定
    _isGeneratingPdf = true; // 生成中フラグを再利用
    notifyListeners();
    
    try {
      // 既存のHTMLコンテンツから要素を抽出して再生成のヒントとする
      final contentSummary = extractContentSummary(_htmlContent);
      debugPrint('コンテンツ再生成: $contentSummary');
      
      // 実際の再生成は外部から実行される
      // この関数は状態管理のみ行う
    } catch (e) {
      debugPrint('コンテンツ再生成エラー: $e');
    } finally {
      _isGeneratingPdf = false;
      notifyListeners();
    }
  }
  
  // HTMLコンテンツから要約を抽出
  String extractContentSummary(String html) {
    // 簡単なHTMLパース（タイトルと主要セクションを抽出）
    final titleMatch = RegExp(r'<h1[^>]*>(.*?)</h1>').firstMatch(html);
    final title = titleMatch?.group(1)?.replaceAll(RegExp(r'<[^>]*>'), '') ?? '';
    
    final h2Matches = RegExp(r'<h2[^>]*>(.*?)</h2>').allMatches(html);
    final sections = h2Matches
        .map((match) => match.group(1)?.replaceAll(RegExp(r'<[^>]*>'), '') ?? '')
        .where((section) => section.isNotEmpty)
        .toList();
    
    return '${title.isNotEmpty ? "タイトル: $title" : ""}'
           '${sections.isNotEmpty ? "\nセクション: ${sections.join(", ")}" : ""}';
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