import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'services/audio_service.dart';
import 'services/ai_service.dart';
import 'widgets/html_preview_widget.dart';
import 'widgets/inline_editable_preview_widget.dart';
import 'widgets/user_dictionary_widget.dart';
import 'dart:html' as html;
import 'package:http/http.dart' as http;

/// 学級通信AI - 音声入力システム（完全版）
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(YutoriKyoshituApp());
}

class YutoriKyoshituApp extends StatelessWidget {
  const YutoriKyoshituApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '学級通信エディタ',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final AudioService _audioService = AudioService();
  final AIService _aiService = AIService();
  bool _isRecording = false;
  String _transcribedText = '';
  String _generatedHtml = '';
  String _editorHtml = ''; // エディタから受信したHTML
  bool _isProcessing = false;
  bool _isGenerating = false;
  bool _showEditor = false; // プレビュー(false) / エディター(true) 切り替え
  String _inputText = ''; // テキスト入力の状態を明示的に管理

  final TextEditingController _textController = TextEditingController();
  AIGenerationResult? _aiResult;
  String _statusMessage = '🎤 音声録音または文字入力で学級通信を作成してください';

  // インライン編集エディタへの参照
  final GlobalKey _editorKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    // JavaScript Bridge初期化
    _audioService.initializeJavaScriptBridge();

    // 録音状態変更コールバック
    _audioService.setOnRecordingStateChanged((isRecording) {
      setState(() {
        _isRecording = isRecording;
        _statusMessage = isRecording ? '🎤 録音中...' : '⏹️ 録音停止';
      });
    });

    // 音声録音完了コールバック
    _audioService.setOnAudioRecorded((base64Audio) {
      setState(() {
        _statusMessage = '🎙️ 文字起こし処理中...';
      });
    });

    // 文字起こし完了コールバック
    _audioService.setOnTranscriptionCompleted((transcript) {
      setState(() {
        _transcribedText = transcript;
        _textController.text = transcript;
        _inputText = transcript.trim(); // 音声入力時も_inputTextを更新
        _statusMessage = '✅ 文字起こし完了！「学級通信を作成する」ボタンを押してください';
      });
    });
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }

  // AI学級通信生成
  Future<void> _generateNewsletter() async {
    if (_isGenerating || _isProcessing) {
      print('⚠️ [DUPLICATE_PREVENTION] 既に処理中のため生成をスキップ');
      return;
    }

    final inputText =
        _inputText.isNotEmpty ? _inputText : _textController.text.trim();
    if (inputText.isEmpty) {
      setState(() {
        _statusMessage = '❌ 入力テキストが空です。音声録音または文字入力をしてください。';
      });
      return;
    }

    _isGenerating = true;
    setState(() {
      _isProcessing = true;
      _statusMessage = '🤖 AI生成中...（約5秒）';
    });

    try {
      final result = await _aiService.generateNewsletter(
        transcribedText: inputText,
      );

      setState(() {
        _aiResult = result;
        _generatedHtml = _createStylishHtml(result.newsletterHtml);
        _statusMessage = '🎉 AI生成完了！プレビューまたはエディターで確認してください';
        _showEditor = false; // 生成完了後はプレビューを表示
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ AI生成でエラーが発生しました: $e';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
      _isGenerating = false;
    }
  }

  // おしゃれなHTMLテンプレートを作成
  String _createStylishHtml(String content) {
    final now = DateTime.now();
    final dateStr = '${now.year}年${now.month}月${now.day}日';

    return '''
<div class="newsletter-container">
  <header class="newsletter-header">
    <div class="school-info">
      <h1 class="school-name">○○小学校</h1>
      <div class="class-info">○年○組 学級通信</div>
    </div>
    <div class="date-info">
      <div class="date">${dateStr}</div>
      <div class="season-badge ${_getSeason()}">${_getSeasonText()}</div>
    </div>
  </header>
  
  <main class="newsletter-content">
    ${_cleanHtmlContent(content)}
  </main>
  
  <footer class="newsletter-footer">
    <div class="footer-content">
      <div class="contact-info">
        <p>何かご質問がございましたら、お気軽にお声がけください。</p>
      </div>
      <div class="signature">
        <p>担任：○○　○○</p>
      </div>
    </div>
  </footer>
</div>

<style>
.newsletter-container {
  max-width: 800px;
  margin: 0 auto;
  background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
  border-radius: 15px;
  box-shadow: 0 10px 30px rgba(0,0,0,0.1);
  overflow: hidden;
  font-family: 'Hiragino Sans', 'Yu Gothic', sans-serif;
}

.newsletter-header {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  padding: 30px;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.school-name {
  font-size: 24px;
  font-weight: bold;
  margin: 0;
  text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
}

.class-info {
  font-size: 16px;
  margin-top: 5px;
  opacity: 0.9;
}

.date-info {
  text-align: right;
}

.date {
  font-size: 18px;
  font-weight: bold;
  margin-bottom: 8px;
}

.season-badge {
  padding: 5px 15px;
  border-radius: 20px;
  font-size: 12px;
  font-weight: bold;
  text-transform: uppercase;
}

.season-badge.spring {
  background: linear-gradient(45deg, #ff9a9e 0%, #fecfef 100%);
}

.season-badge.summer {
  background: linear-gradient(45deg, #a8edea 0%, #fed6e3 100%);
}

.season-badge.autumn {
  background: linear-gradient(45deg, #ffecd2 0%, #fcb69f 100%);
}

.season-badge.winter {
  background: linear-gradient(45deg, #e0c3fc 0%, #9bb5ff 100%);
}

.newsletter-content {
  padding: 40px;
  background: white;
  line-height: 1.8;
}

.newsletter-content h1 {
  color: #2c3e50;
  border-bottom: 3px solid #3498db;
  padding-bottom: 10px;
  margin-bottom: 20px;
}

.newsletter-content h2 {
  color: #34495e;
  margin-top: 30px;
  margin-bottom: 15px;
}

.newsletter-content h3 {
  color: #7f8c8d;
  margin-top: 25px;
  margin-bottom: 12px;
}

.newsletter-content p {
  margin-bottom: 15px;
  color: #2c3e50;
}

.newsletter-content ul, .newsletter-content ol {
  margin-bottom: 20px;
  padding-left: 30px;
}

.newsletter-content li {
  margin-bottom: 8px;
  color: #34495e;
}

.newsletter-footer {
  background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
  color: white;
  padding: 25px 40px;
}

.footer-content {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.contact-info p, .signature p {
  margin: 0;
  font-size: 14px;
}

.signature {
  text-align: right;
  font-weight: bold;
}

@media print {
  .newsletter-container {
    box-shadow: none;
    background: white;
  }
  
  .newsletter-header {
    background: #667eea !important;
    -webkit-print-color-adjust: exact;
    color-adjust: exact;
  }
}
</style>
''';
  }

  String _getSeason() {
    final month = DateTime.now().month;
    if (month >= 3 && month <= 5) return 'spring';
    if (month >= 6 && month <= 8) return 'summer';
    if (month >= 9 && month <= 11) return 'autumn';
    return 'winter';
  }

  String _getSeasonText() {
    final month = DateTime.now().month;
    if (month >= 3 && month <= 5) return '春';
    if (month >= 6 && month <= 8) return '夏';
    if (month >= 9 && month <= 11) return '秋';
    return '冬';
  }

  String _cleanHtmlContent(String content) {
    return content.replaceAll('```html', '').replaceAll('```', '').trim();
  }

  // AI学級通信再生成
  Future<void> _regenerateNewsletter() async {
    if (_transcribedText.isEmpty && _textController.text.trim().isEmpty) return;

    if (_isGenerating || _isProcessing) {
      print('⚠️ [REGENERATE_SKIP] 既に処理中のため再生成をスキップ');
      return;
    }

    setState(() {
      _statusMessage = '🔄 再生成中...';
      _aiResult = null;
      _generatedHtml = '';
    });

    await _generateNewsletter();
  }

  // PDFダウンロード機能（バックエンドAPI使用）
  Future<void> _downloadPdf() async {
    if (_generatedHtml.isEmpty) {
      setState(() {
        _statusMessage = '❌ 生成されたコンテンツがありません';
      });
      return;
    }

    setState(() {
      _statusMessage = '📄 PDF生成中...';
    });

    try {
      print('📄 [PDF] PDF生成開始 - HTMLサイズ: ${_generatedHtml.length}文字');

      // バックエンドPDF生成API呼び出し
      final apiUrl = kDebugMode
          ? 'http://localhost:8081/api/v1/ai/generate-pdf'
          : 'https://asia-northeast1-yutori-kyoshitu.cloudfunctions.net/main/api/v1/ai/generate-pdf';

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'html_content': _generatedHtml,
          'title': '学級通信',
          'page_size': 'A4',
          'margin': '20mm',
          'include_header': true,
          'include_footer': true,
        }),
      );

      print('📄 [PDF] API応答 - ステータス: ${response.statusCode}');
      print('📄 [PDF] API応答本文: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true) {
          // Base64エンコードされたPDFデータを取得
          final pdfBase64 = responseData['data']['pdf_base64'];
          final fileSize = responseData['data']['file_size_mb'];

          print('📄 [PDF] PDF生成成功 - ファイルサイズ: ${fileSize}MB');

          // Base64をバイナリに変換
          final pdfBytes = base64Decode(pdfBase64);

          // Blobを作成してダウンロード
          final blob = html.Blob([pdfBytes], 'application/pdf');
          final url = html.Url.createObjectUrlFromBlob(blob);

          final fileName =
              '学級通信_${DateTime.now().toString().substring(0, 10)}.pdf';
          final anchor = html.AnchorElement(href: url)
            ..setAttribute('download', fileName)
            ..click();

          html.Url.revokeObjectUrl(url);

          setState(() {
            _statusMessage = '📄 PDFファイルをダウンロードしました (${fileSize}MB)';
          });

          print('📄 [PDF] ダウンロード完了: $fileName');
        } else {
          throw Exception('PDF生成失敗: ${responseData['error']}');
        }
      } else {
        // エラー詳細を取得
        String errorDetails = 'ステータス: ${response.statusCode}';
        try {
          final errorResponse = jsonDecode(response.body);
          errorDetails += ', 詳細: ${errorResponse['error'] ?? response.body}';
        } catch (e) {
          errorDetails += ', レスポンス: ${response.body}';
        }
        throw Exception('API呼び出し失敗 - $errorDetails');
      }
    } catch (e) {
      print('❌ [PDF] PDF生成エラー: $e');
      setState(() {
        _statusMessage = '❌ PDF生成エラー: $e';
      });

      // PDFが失敗した場合はHTMLダウンロード
      _downloadHtml();
    }
  }

  // HTMLファイルダウンロード
  void _downloadHtml() {
    if (_generatedHtml.isEmpty) return;

    try {
      final fullHtml = '''
<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>学級通信 - ${DateTime.now().toString().substring(0, 10)}</title>
</head>
<body>
    $_generatedHtml
</body>
</html>
''';

      final bytes = utf8.encode(fullHtml);
      final blob = html.Blob([bytes], 'text/html');
      final url = html.Url.createObjectUrlFromBlob(blob);

      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download',
            '学級通信_${DateTime.now().toString().substring(0, 10)}.html')
        ..click();

      html.Url.revokeObjectUrl(url);

      setState(() {
        _statusMessage = '📄 HTMLファイルをダウンロードしました';
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ ダウンロードエラー: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('学級通信エディタ'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Row(
        children: [
          // 🎤 左サイド: 音声入力エリア
          Container(
            width: 400,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(right: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 音声入力セクション
                Text(
                  '🎤 音声入力',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
                SizedBox(height: 16),

                // 録音ボタン
                Center(
                  child: GestureDetector(
                    onTap: _isRecording
                        ? _audioService.stopRecording
                        : _audioService.startRecording,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            _isRecording ? Colors.red[500] : Colors.blue[500],
                        boxShadow: [
                          BoxShadow(
                            color: (_isRecording ? Colors.red : Colors.blue)
                                .withOpacity(0.3),
                            spreadRadius: 4,
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Icon(
                        _isRecording ? Icons.stop : Icons.mic,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 12),
                Center(
                  child: Text(
                    _isRecording ? '録音中...' : 'タップで録音開始',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ),

                SizedBox(height: 24),

                // リアルタイム字幕
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.edit_note,
                              size: 16, color: Colors.blue[600]),
                          SizedBox(width: 4),
                          Text(
                            'テキスト入力',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      TextField(
                        controller: _textController,
                        maxLines: 6,
                        onChanged: (text) {
                          setState(() {
                            _inputText = text.trim();
                            print(
                                '📝 [TextField] テキスト変更: "$_inputText" (長さ: ${_inputText.length})');
                            print(
                                '📝 [TextField] ボタン有効性: ${!(_isProcessing || _inputText.isEmpty)}');
                          });
                        },
                        decoration: InputDecoration(
                          hintText:
                              '学級通信の内容を入力してください...\n音声入力からテキストを追加することもできます。',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.all(12),
                        ),
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 16),

                // 生成ボタン
                Builder(
                  builder: (context) {
                    final isButtonEnabled =
                        !(_isProcessing || _inputText.isEmpty);
                    print(
                        '🔘 [Button] ビルド時 - テキスト: "$_inputText", 有効: $isButtonEnabled');
                    return SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: (_isProcessing || _inputText.isEmpty)
                            ? null
                            : () {
                                print('🔘 [Button] 学級通信作成ボタンが押されました');
                                _generateNewsletter();
                              },
                        icon: _isProcessing
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : Icon(Icons.auto_awesome),
                        label: Text(_isProcessing ? 'AI生成中...' : '学級通信を作成する'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[600],
                          foregroundColor: Colors.white,
                          textStyle: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    );
                  },
                ),

                SizedBox(height: 12),

                // ステータス表示
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _statusMessage,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                SizedBox(height: 16),

                // AI生成結果情報
                if (_aiResult != null) ...[
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.check_circle,
                                color: Colors.green[600], size: 16),
                            SizedBox(width: 4),
                            Text(
                              'AI生成完了',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                                fontSize: 14,
                              ),
                            ),
                            Spacer(),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _aiResult!.qualityScore,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.green[800],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Text('${_aiResult!.characterCount}',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                Text('文字',
                                    style: TextStyle(
                                        fontSize: 11, color: Colors.grey[600])),
                              ],
                            ),
                            Column(
                              children: [
                                Text(_aiResult!.processingTimeDisplay,
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                Text('処理時間',
                                    style: TextStyle(
                                        fontSize: 11, color: Colors.grey[600])),
                              ],
                            ),
                            Column(
                              children: [
                                Text(_aiResult!.season,
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                Text('季節',
                                    style: TextStyle(
                                        fontSize: 11, color: Colors.grey[600])),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 12),

                  // アクションボタン
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: (_isGenerating || _isProcessing)
                              ? null
                              : _regenerateNewsletter,
                          icon: Icon(Icons.refresh, size: 16),
                          label: Text('再生成'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange[600],
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _downloadPdf,
                          icon: Icon(Icons.picture_as_pdf, size: 16),
                          label: Text('PDF'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple[600],
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // 📝 右サイド: プレビュー/エディターエリア
          Expanded(
            child: Container(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ヘッダーとツールバー
                  Row(
                    children: [
                      Icon(_showEditor ? Icons.edit : Icons.preview,
                          color: Colors.blue[600]),
                      SizedBox(width: 8),
                      Text(
                        _showEditor ? 'インライン編集' : 'プレビュー',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                      SizedBox(width: 16),
                      // プレビュー/エディター切り替えボタン
                      ToggleButtons(
                        isSelected: [!_showEditor, _showEditor],
                        onPressed: (index) {
                          setState(() {
                            _showEditor = index == 1;
                          });
                        },
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              children: [
                                Icon(Icons.preview, size: 16),
                                SizedBox(width: 4),
                                Text('プレビュー'),
                              ],
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 16),
                                SizedBox(width: 4),
                                Text('編集'),
                              ],
                            ),
                          ),
                        ],
                        borderRadius: BorderRadius.circular(8),
                        selectedColor: Colors.white,
                        fillColor: Colors.blue[600],
                        color: Colors.blue[600],
                        borderColor: Colors.blue[300],
                        selectedBorderColor: Colors.blue[600],
                      ),
                      Spacer(),
                      // ツールバー
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {/* 元に戻す */},
                            icon: Icon(Icons.undo, color: Colors.grey[600]),
                            tooltip: '元に戻す',
                          ),
                          IconButton(
                            onPressed: () {/* やり直し */},
                            icon: Icon(Icons.redo, color: Colors.grey[600]),
                            tooltip: 'やり直し',
                          ),
                          SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => UserDictionaryWidget(
                                    userId: 'default', // TODO: 実際のユーザーIDを使用
                                    onDictionaryUpdated: () {
                                      // 辞書更新時のコールバック
                                      setState(() {
                                        _statusMessage = 'ユーザー辞書が更新されました';
                                      });
                                    },
                                  ),
                                ),
                              );
                            },
                            icon: Icon(Icons.book, size: 16),
                            label: Text('辞書'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo[600],
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                          ),
                          SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: _downloadHtml,
                            icon: Icon(Icons.code, size: 16),
                            label: Text('HTML'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[200],
                              foregroundColor: Colors.grey[700],
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  SizedBox(height: 16),

                  // プレビュー/エディター表示エリア
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _generatedHtml.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.article_outlined,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    '学級通信のタイトルを入力してください',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'ここに学級通信の内容を入力してください...\n\n音声入力からテキストを追加することもできます。',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[500],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final availableHeight = constraints.maxHeight;
                                  return _showEditor
                                      ? InlineEditablePreviewWidget(
                                          key: _editorKey,
                                          htmlContent: _generatedHtml,
                                          height: availableHeight,
                                          onContentChanged: (html) {
                                            if (_editorHtml != html) {
                                              setState(() {
                                                _editorHtml = html;
                                                // エディタの変更をプレビューにも反映
                                                _generatedHtml = html;
                                              });
                                            }
                                          },
                                        )
                                      : HtmlPreviewWidget(
                                          key: ValueKey(
                                              'html_preview_${_generatedHtml.hashCode}'),
                                          htmlContent: _generatedHtml,
                                          height: availableHeight,
                                        );
                                },
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
