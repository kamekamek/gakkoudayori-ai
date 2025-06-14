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

/// 学級通信AI - レスポンシブ対応版
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
        fontFamily: 'Noto Sans JP',
      ),
      home: ResponsiveHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ResponsiveHomePage extends StatefulWidget {
  const ResponsiveHomePage({Key? key}) : super(key: key);

  @override
  ResponsiveHomePageState createState() => ResponsiveHomePageState();
}

class ResponsiveHomePageState extends State<ResponsiveHomePage> {
  final AudioService _audioService = AudioService();
  final AIService _aiService = AIService();
  bool _isRecording = false;
  String _transcribedText = '';
  String _generatedHtml = '';
  String _editorHtml = '';
  bool _isProcessing = false;
  bool _isGenerating = false;
  bool _showEditor = false;
  String _inputText = '';

  final TextEditingController _textController = TextEditingController();
  AIGenerationResult? _aiResult;
  String _statusMessage = '🎤 音声録音または文字入力で学級通信を作成してください';

  final GlobalKey _editorKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _audioService.initializeJavaScriptBridge();

    _audioService.setOnRecordingStateChanged((isRecording) {
      setState(() {
        _isRecording = isRecording;
        _statusMessage = isRecording ? '🎤 録音中...' : '⏹️ 録音停止';
      });
    });

    _audioService.setOnAudioRecorded((base64Audio) {
      setState(() {
        _statusMessage = '🎙️ 文字起こし処理中...';
      });
    });

    _audioService.setOnTranscriptionCompleted((transcript) {
      setState(() {
        _transcribedText = transcript;
        _textController.text = transcript;
        _inputText = transcript.trim();
        _statusMessage = '✅ 文字起こし完了！「学級通信を作成する」ボタンを押してください';
      });
    });
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('学級通信エディタ'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
      floatingActionButton: isMobile && _generatedHtml.isNotEmpty 
        ? Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FloatingActionButton(
                onPressed: _downloadPdf,
                backgroundColor: Colors.purple[600],
                heroTag: "pdf",
                child: Icon(Icons.picture_as_pdf, color: Colors.white),
              ),
              SizedBox(height: 8),
              FloatingActionButton(
                onPressed: _regenerateNewsletter,
                backgroundColor: Colors.orange[600],
                heroTag: "regenerate",
                child: Icon(Icons.refresh, color: Colors.white),
              ),
            ],
          )
        : null,
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Container(
          width: 400,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(right: BorderSide(color: Colors.grey[300]!)),
          ),
          child: _buildVoiceInputSection(isCompact: false),
        ),
        Expanded(
          child: _buildPreviewEditorSection(),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
          ),
          child: _buildVoiceInputSection(isCompact: true),
        ),
        Expanded(
          child: _buildPreviewEditorSection(),
        ),
      ],
    );
  }

  Widget _buildVoiceInputSection({required bool isCompact}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // タイトル
        Text(
          '🎤 音声入力',
          style: TextStyle(
            fontSize: isCompact ? 16 : 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue[700],
          ),
        ),
        SizedBox(height: isCompact ? 12 : 16),

        // 録音ボタン
        Center(
          child: GestureDetector(
            onTap: _isRecording
                ? _audioService.stopRecording
                : _audioService.startRecording,
            child: Container(
              width: isCompact ? 80 : 120,
              height: isCompact ? 80 : 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isRecording ? Colors.red[500] : Colors.blue[500],
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
                size: isCompact ? 35 : 50,
                color: Colors.white,
              ),
            ),
          ),
        ),

        SizedBox(height: 8),
        Center(
          child: Text(
            _isRecording ? '録音中...' : 'タップで録音開始',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ),

        SizedBox(height: isCompact ? 16 : 24),

        // テキスト入力
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
                  Icon(Icons.edit_note, size: 16, color: Colors.blue[600]),
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
                maxLines: isCompact ? 3 : 6,
                onChanged: (text) {
                  setState(() {
                    _inputText = text.trim();
                  });
                },
                decoration: InputDecoration(
                  hintText: '学級通信の内容を入力してください...',
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
        SizedBox(
          width: double.infinity,
          height: isCompact ? 44 : 50,
          child: ElevatedButton.icon(
            onPressed: (_isProcessing || _inputText.isEmpty)
                ? null
                : _generateNewsletter,
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
                  fontSize: isCompact ? 14 : 16, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
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

        // デスクトップでのみ表示する詳細情報とボタン
        if (!isCompact) ...[
          SizedBox(height: 16),
          if (_aiResult != null) ..._buildAIResultInfo(),
        ],
      ],
    );
  }

  List<Widget> _buildAIResultInfo() {
    return [
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
                Icon(Icons.check_circle, color: Colors.green[600], size: 16),
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
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('文字',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                  ],
                ),
                Column(
                  children: [
                    Text(_aiResult!.processingTimeDisplay,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('処理時間',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                  ],
                ),
                Column(
                  children: [
                    Text(_aiResult!.season,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('季節',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      SizedBox(height: 12),
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
    ];
  }

  Widget _buildPreviewEditorSection() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ヘッダー
          Row(
            children: [
              Icon(_showEditor ? Icons.edit : Icons.preview,
                  color: Colors.blue[600]),
              SizedBox(width: 8),
              Text(
                _showEditor ? 'インライン編集' : 'プレビュー',
                style: TextStyle(
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
              if (!isMobile) ...[
                SizedBox(width: 16),
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
              ],
              Spacer(),
              if (!isMobile) ..._buildToolbar(),
            ],
          ),

          // モバイルでのタブ切り替え
          if (isMobile) ...[
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _showEditor = false;
                      });
                    },
                    icon: Icon(Icons.preview, size: 16),
                    label: Text('プレビュー'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !_showEditor ? Colors.blue[600] : Colors.grey[300],
                      foregroundColor: !_showEditor ? Colors.white : Colors.grey[700],
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _showEditor = true;
                      });
                    },
                    icon: Icon(Icons.edit, size: 16),
                    label: Text('編集'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _showEditor ? Colors.blue[600] : Colors.grey[300],
                      foregroundColor: _showEditor ? Colors.white : Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          ],

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
                            '学級通信を作成してください',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '音声入力またはテキスト入力で\n学級通信の内容を入力してください',
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
    );
  }

  List<Widget> _buildToolbar() {
    return [
      IconButton(
        onPressed: () {},
        icon: Icon(Icons.undo, color: Colors.grey[600]),
        tooltip: '元に戻す',
      ),
      IconButton(
        onPressed: () {},
        icon: Icon(Icons.redo, color: Colors.grey[600]),
        tooltip: 'やり直し',
      ),
      SizedBox(width: 8),
      ElevatedButton.icon(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => UserDictionaryWidget(
                userId: 'default',
                onDictionaryUpdated: () {
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
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
    ];
  }

  // AI生成機能（既存のものを移植）
  Future<void> _generateNewsletter() async {
    if (_isGenerating || _isProcessing) return;

    final inputText = _inputText.isNotEmpty ? _inputText : _textController.text.trim();
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
      final result = await _aiService.generateNewsletter(transcribedText: inputText);
      setState(() {
        _aiResult = result;
        _generatedHtml = _createStylishHtml(result.newsletterHtml);
        _statusMessage = '🎉 AI生成完了！プレビューまたはエディターで確認してください';
        _showEditor = false;
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

  Future<void> _regenerateNewsletter() async {
    if (_transcribedText.isEmpty && _textController.text.trim().isEmpty) return;
    if (_isGenerating || _isProcessing) return;

    setState(() {
      _statusMessage = '🔄 再生成中...';
      _aiResult = null;
      _generatedHtml = '';
    });

    await _generateNewsletter();
  }

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

@media (max-width: 768px) {
  .newsletter-container {
    margin: 0;
    border-radius: 0;
  }
  
  .newsletter-header {
    flex-direction: column;
    text-align: center;
    padding: 20px !important;
  }
  
  .date-info {
    text-align: center !important;
    margin-top: 10px;
  }
  
  .newsletter-content {
    padding: 20px !important;
  }
  
  .footer-content {
    flex-direction: column !important;
    text-align: center;
  }
  
  .signature {
    text-align: center !important;
    margin-top: 10px;
  }
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

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true) {
          final pdfBase64 = responseData['data']['pdf_base64'];
          final fileSize = responseData['data']['file_size_mb'];
          final pdfBytes = base64Decode(pdfBase64);
          final blob = html.Blob([pdfBytes], 'application/pdf');
          final url = html.Url.createObjectUrlFromBlob(blob);

          final fileName = '学級通信_${DateTime.now().toString().substring(0, 10)}.pdf';
          final anchor = html.AnchorElement(href: url)
            ..setAttribute('download', fileName)
            ..click();

          html.Url.revokeObjectUrl(url);

          setState(() {
            _statusMessage = '📄 PDFファイルをダウンロードしました (${fileSize}MB)';
          });
        } else {
          throw Exception('PDF生成失敗: ${responseData['error']}');
        }
      } else {
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
      setState(() {
        _statusMessage = '❌ PDF生成エラー: $e';
      });
      _downloadHtml();
    }
  }

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
}