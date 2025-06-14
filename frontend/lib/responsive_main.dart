import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'services/audio_service.dart';
import 'services/ai_service.dart';
import 'services/graphical_record_service.dart';
import 'widgets/html_preview_widget.dart';
import 'widgets/quill_editor_widget.dart';

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
  final GraphicalRecordService _graphicalRecordService =
      GraphicalRecordService();

  // フロー切り替え
  bool _isGraphicalRecordMode = false; // false: 学級通信, true: グラレコ

  // 共通状態
  bool _isRecording = false;
  String _transcribedText = '';
  bool _isProcessing = false;
  String _inputText = '';
  final TextEditingController _textController = TextEditingController();
  String _statusMessage = '🎤 音声録音または文字入力で学級通信を作成してください';

  // 学級通信モード用
  String _generatedHtml = '';
  String _editorHtml = '';
  bool _isGenerating = false;
  bool _showEditor = false;
  AIGenerationResult? _aiResult;

  // グラレコモード用
  Map<String, dynamic>? _jsonData;
  String _graphicalRecordHtml = '';
  String _selectedTemplate = 'colorful';
  bool _showJsonEditor = false;

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
        if (_isGraphicalRecordMode) {
          _statusMessage = '✅ 文字起こし完了！「JSON変換」ボタンを押してください';
        } else {
          _statusMessage = '✅ 文字起こし完了！「学級通信を作成する」ボタンを押してください';
        }
      });
    });

    // sample.htmlの内容をプレビューに表示
    print('🚀 [Init] initState完了 - sample.html読み込み開始');
    _loadSampleHtml();
  }

  /// sample.htmlの内容を読み込んでプレビューに表示
  Future<void> _loadSampleHtml() async {
    try {
      print('🚀 [Sample] _loadSampleHtml開始');

      // Flutterアセットからsample.htmlを読み込み（UTF-8保証）
      final String sampleHtml = await rootBundle.loadString('web/sample.html');
      print('✅ [Sample] sample.htmlアセット読み込み成功');

      setState(() {
        _generatedHtml = sampleHtml;
        _statusMessage = '📄 サンプル学級通信を表示しています';
      });

      print('✅ [Sample] sample.htmlをプレビューに読み込み完了');
      print('📊 [Sample] _generatedHtml長さ: ${sampleHtml.length}文字');
    } catch (e) {
      print('❌ [Sample] sample.html読み込みエラー: $e');

      // フォールバック: HTTP経由で読み込み
      try {
        print('🔄 [Sample] HTTP経由でフォールバック読み込み開始');
        final response = await http.get(
          Uri.parse('sample.html'),
          headers: {
            'Accept':
                'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
            'Accept-Charset': 'UTF-8',
          },
        );

        if (response.statusCode == 200) {
          final String sampleHtml = utf8.decode(response.bodyBytes);
          print('✅ [Sample] HTTP経由でsample.html読み込み成功');

          setState(() {
            _generatedHtml = sampleHtml;
            _statusMessage = '📄 サンプル学級通信を表示しています';
          });

          print('✅ [Sample] HTTP経由sample.html読み込み完了');
          print('📊 [Sample] _generatedHtml長さ: ${sampleHtml.length}文字');
        } else {
          throw Exception('HTTP Status: ${response.statusCode}');
        }
      } catch (httpError) {
        print('❌ [Sample] HTTP経由読み込みも失敗: $httpError');
        setState(() {
          _statusMessage = '❌ サンプル読み込みエラー: $e';
        });
      }
    }
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
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: _buildPreviewEditorSection(),
          ),
        ),
      ],
    );
  }

  Widget _buildVoiceInputSection({required bool isCompact}) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // フロー切り替えボタン
          Container(
            width: double.infinity,
            margin: EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() {
                      _isGraphicalRecordMode = false;
                      _statusMessage = '🎤 音声録音または文字入力で学級通信を作成してください';
                    }),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !_isGraphicalRecordMode
                          ? Colors.blue[600]
                          : Colors.grey[300],
                      foregroundColor: !_isGraphicalRecordMode
                          ? Colors.white
                          : Colors.grey[600],
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text('📄 学級通信'),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() {
                      _isGraphicalRecordMode = true;
                      _statusMessage = '🎤 音声録音または文字入力でグラレコを作成してください';
                    }),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isGraphicalRecordMode
                          ? Colors.purple[600]
                          : Colors.grey[300],
                      foregroundColor: _isGraphicalRecordMode
                          ? Colors.white
                          : Colors.grey[600],
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text('🎨 グラレコ'),
                  ),
                ),
              ],
            ),
          ),

          // タイトル
          Text(
            _isGraphicalRecordMode ? '🎨 グラレコ作成' : '🎤 音声入力',
            style: TextStyle(
              fontSize: isCompact ? 16 : 18,
              fontWeight: FontWeight.bold,
              color: _isGraphicalRecordMode
                  ? Colors.purple[700]
                  : Colors.blue[700],
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

          // 生成ボタン（フロー別）
          if (!_isGraphicalRecordMode) ...[
            // 学級通信モード
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
                      fontSize: isCompact ? 14 : 16,
                      fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ] else ...[
            // グラレコモード
            Column(
              children: [
                // JSON変換ボタン
                SizedBox(
                  width: double.infinity,
                  height: isCompact ? 44 : 50,
                  child: ElevatedButton.icon(
                    onPressed: (_isProcessing ||
                            _inputText.isEmpty ||
                            _jsonData != null)
                        ? null
                        : _convertSpeechToJson,
                    icon: _isProcessing
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Icon(Icons.data_object),
                    label: Text(_isProcessing ? 'JSON変換中...' : 'JSON変換'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple[600],
                      foregroundColor: Colors.white,
                      textStyle: TextStyle(
                          fontSize: isCompact ? 14 : 16,
                          fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                if (_jsonData != null) ...[
                  SizedBox(height: 8),
                  // グラレコ生成ボタン
                  SizedBox(
                    width: double.infinity,
                    height: isCompact ? 44 : 50,
                    child: ElevatedButton.icon(
                      onPressed:
                          (_isProcessing || _graphicalRecordHtml.isNotEmpty)
                              ? null
                              : _generateGraphicalRecord,
                      icon: _isProcessing
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Icon(Icons.palette),
                      label: Text(_isProcessing ? 'グラレコ生成中...' : 'グラレコ生成'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal[600],
                        foregroundColor: Colors.white,
                        textStyle: TextStyle(
                            fontSize: isCompact ? 14 : 16,
                            fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],

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

          // グラレコモード専用UI
          if (_isGraphicalRecordMode) ...[
            // テンプレート選択
            if (_jsonData != null) ...[
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.palette,
                            size: 16, color: Colors.purple[600]),
                        SizedBox(width: 4),
                        Text(
                          'テンプレート選択',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.purple[700],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTemplateButton(
                              'colorful', 'カラフル', Colors.red[300]!),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: _buildTemplateButton(
                              'monochrome', 'モノクロ', Colors.grey[600]!),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: _buildTemplateButton(
                              'pastel', 'パステル', Colors.pink[200]!),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            // JSON表示エリア
            if (_jsonData != null) ...[
              SizedBox(height: 16),
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
                        Icon(Icons.data_object,
                            size: 16, color: Colors.blue[600]),
                        SizedBox(width: 4),
                        Text(
                          'JSON構造化データ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                        Spacer(),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _showJsonEditor = !_showJsonEditor;
                            });
                          },
                          child: Text(_showJsonEditor ? '閉じる' : '詳細表示'),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    if (_showJsonEditor) ...[
                      Container(
                        width: double.infinity,
                        height: 200,
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: SingleChildScrollView(
                          child: Text(
                            const JsonEncoder.withIndent('  ')
                                .convert(_jsonData),
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      Text(
                        'タイトル: ${_jsonData!['title'] ?? 'なし'}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                      Text(
                        'セクション数: ${(_jsonData!['sections'] as List?)?.length ?? 0}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],

          // デスクトップでのみ表示する詳細情報とボタン
          if (!isCompact) ...[
            SizedBox(height: 16),
            if (_aiResult != null && !_isGraphicalRecordMode)
              ..._buildAIResultInfo(),
          ],
        ],
      ),
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
                        style:
                            TextStyle(fontSize: 11, color: Colors.grey[600])),
                  ],
                ),
                Column(
                  children: [
                    Text(_aiResult!.processingTimeDisplay,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('処理時間',
                        style:
                            TextStyle(fontSize: 11, color: Colors.grey[600])),
                  ],
                ),
                Column(
                  children: [
                    Text(_aiResult!.season,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('季節',
                        style:
                            TextStyle(fontSize: 11, color: Colors.grey[600])),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          // ヘッダー
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
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
                SizedBox(width: 16),
                // デスクトップ用の切り替えボタン（1セットのみ）
                if (!isMobile) ...[
                  ElevatedButton.icon(
                    onPressed: () {
                      _saveEditorContent();
                      setState(() {
                        _showEditor = false;
                      });
                    },
                    icon: Icon(Icons.preview, size: 16),
                    label: Text('プレビュー'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          !_showEditor ? Colors.blue[600] : Colors.grey[300],
                      foregroundColor:
                          !_showEditor ? Colors.white : Colors.grey[700],
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _showEditor = true;
                      });
                    },
                    icon: Icon(Icons.edit, size: 16),
                    label: Text('編集'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _showEditor ? Colors.blue[600] : Colors.grey[300],
                      foregroundColor:
                          _showEditor ? Colors.white : Colors.grey[700],
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _loadSampleHtml,
                    icon: Icon(Icons.article, size: 16),
                    label: Text('サンプル'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // モバイルでのタブ切り替え
          if (isMobile) ...[
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // 編集モードから戻る前に、最新の編集内容を保存
                      _saveEditorContent();
                      setState(() {
                        _showEditor = false;
                      });
                    },
                    icon: Icon(Icons.preview, size: 16),
                    label: Text('プレビュー'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          !_showEditor ? Colors.blue[600] : Colors.grey[300],
                      foregroundColor:
                          !_showEditor ? Colors.white : Colors.grey[700],
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
                      backgroundColor:
                          _showEditor ? Colors.blue[600] : Colors.grey[300],
                      foregroundColor:
                          _showEditor ? Colors.white : Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _loadSampleHtml,
              icon: Icon(Icons.article, size: 16),
              label: Text('サンプル学級通信を読み込み'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 40),
              ),
            ),
          ],

          SizedBox(height: 16),

          // プレビュー/エディター表示エリア
          Container(
            width: double.infinity,
            constraints: BoxConstraints(
              minHeight: isMobile ? 300 : 400,
              maxHeight: isMobile ? 600 : 700,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Builder(
              builder: (context) {
                print(
                    '🔍 [Preview] 表示判定: _generatedHtml.isEmpty=${_generatedHtml.isEmpty}, _graphicalRecordHtml.isEmpty=${_graphicalRecordHtml.isEmpty}');
                print(
                    '🔍 [Preview] _generatedHtml長さ: ${_generatedHtml.length}');
                print(
                    '🔍 [Preview] _graphicalRecordHtml長さ: ${_graphicalRecordHtml.length}');
                final isEmpty =
                    (_generatedHtml.isEmpty && _graphicalRecordHtml.isEmpty);

                if (isEmpty) {
                  return Container(
                    height: isMobile ? 300 : 400,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isGraphicalRecordMode
                                ? Icons.palette_outlined
                                : Icons.article_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 16),
                          Text(
                            _isGraphicalRecordMode
                                ? 'グラレコを作成してください'
                                : '学級通信を作成してください',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            _isGraphicalRecordMode
                                ? '音声入力またはテキスト入力で\nグラレコの内容を入力してください'
                                : '音声入力またはテキスト入力で\n学級通信の内容を入力してください',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                } else {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Builder(
                      builder: (context) {
                        final htmlContent = _isGraphicalRecordMode
                            ? _graphicalRecordHtml
                            : (_showEditor
                                ? (_editorHtml.isNotEmpty
                                    ? _editorHtml
                                    : _generatedHtml)
                                : _generatedHtml);
                        print(
                            '🔍 [Preview] QuillEditorWidgetに渡すhtmlContent長さ: ${htmlContent.length}');
                        print(
                            '🔍 [Preview] _isGraphicalRecordMode: $_isGraphicalRecordMode');
                        print('🔍 [Preview] _showEditor: $_showEditor');
                        // 編集モードかつグラレコモードでない場合のみQuillEditorWidgetを使用
                        if (_showEditor && !_isGraphicalRecordMode) {
                          return QuillEditorWidget(
                            initialContent: htmlContent,
                            contentFormat: 'html',
                            height: isMobile ? 600 : 700,
                            onContentChanged: (html) {
                              print(
                                  '🔔 [QuillEditor] 編集内容変更: ${html.length}文字');
                              setState(() {
                                _editorHtml = html;
                                _generatedHtml = html; // プレビューにも即座に反映
                                _statusMessage =
                                    '📝 編集内容を保存しました（${html.length}文字）';
                              });
                            },
                            onEditorReady: () {
                              print('✅ [QuillEditor] エディタ準備完了');
                            },
                          );
                        } else {
                          // プレビューモードまたはグラレコモードの場合はHtmlPreviewWidgetを使用
                          return HtmlPreviewWidget(
                            htmlContent: htmlContent,
                            height: isMobile ? 600 : 700,
                          );
                        }
                      },
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // AI生成機能（既存のものを移植）
  /// 編集モードから戻る前に最新の編集内容を保存
  void _saveEditorContent() {
    // 編集モードの時に、最新のHTMLコンテンツを確実に保存
    if (_showEditor) {
      if (_editorHtml.isNotEmpty) {
        setState(() {
          _generatedHtml = _editorHtml;
          _statusMessage = '💾 編集内容をプレビューに反映しました（${_editorHtml.length}文字）';
        });
        print('🔄 [状態管理] 編集内容をプレビューに反映: ${_editorHtml.length}文字');
      } else {
        // 編集内容が空の場合でも、InlineEditablePreviewWidgetから最新の内容を取得を試行
        print('⚠️ [状態管理] 編集内容が空です。現在の表示内容を保持します。');
        setState(() {
          _statusMessage = '⚠️ 編集内容が検出されませんでした。プレビューモードに切り替えます。';
        });
      }
    } else {
      print('ℹ️ [状態管理] 編集モードではないため保存をスキップ');
    }
  }

  Future<void> _generateNewsletter() async {
    if (_isGenerating || _isProcessing) return;

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
      final result =
          await _aiService.generateNewsletter(transcribedText: inputText);
      setState(() {
        _aiResult = result;
        _generatedHtml = _createStylishHtml(result.newsletterHtml);
        _editorHtml = ''; // 新しいAI生成時は編集状態をリセット
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
      _editorHtml = ''; // 再生成時も編集状態をリセット
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
    max-width: 100%;
    overflow-x: hidden;
  }
  
  .newsletter-header {
    flex-direction: column;
    text-align: center;
    padding: 15px !important;
  }
  
  .date-info {
    text-align: center !important;
    margin-top: 10px;
  }
  
  .newsletter-content {
    padding: 15px !important;
    overflow-wrap: break-word;
    word-wrap: break-word;
  }
  
  .footer-content {
    flex-direction: column !important;
    text-align: center;
    padding: 15px !important;
  }
  
  .signature {
    text-align: center !important;
    margin-top: 10px;
  }
  
  /* モバイルでの読みやすさ向上 */
  .newsletter-content h1 {
    font-size: 18px !important;
  }
  
  .newsletter-content h2 {
    font-size: 16px !important;
  }
  
  .newsletter-content h3 {
    font-size: 14px !important;
  }
  
  .newsletter-content p, .newsletter-content li {
    font-size: 14px !important;
    line-height: 1.6 !important;
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

          final fileName =
              '学級通信_${DateTime.now().toString().substring(0, 10)}.pdf';
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

  // ==============================================================================
  // 新フロー: グラフィックレコーディング関連メソッド
  // ==============================================================================

  /// 音声認識結果をJSON構造化データに変換
  Future<void> _convertSpeechToJson() async {
    if (_inputText.trim().isEmpty) {
      setState(() {
        _statusMessage = '❌ 入力テキストが空です';
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _statusMessage = '🤖 音声をJSON構造化データに変換中...';
    });

    try {
      final result = await _graphicalRecordService.convertSpeechToJson(
        transcribedText: _inputText,
        customContext: '',
      );

      if (result.success && result.jsonData != null) {
        setState(() {
          _jsonData = result.jsonData!;
          _statusMessage = '✅ JSON変換完了！内容を確認して「グラレコ生成」ボタンを押してください';
          _showJsonEditor = true;
        });
      } else {
        setState(() {
          _statusMessage = '❌ JSON変換エラー: ${result.error ?? "Unknown error"}';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = '❌ JSON変換エラー: $e';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  /// JSON構造化データからHTMLグラレコを生成
  Future<void> _generateGraphicalRecord() async {
    if (_jsonData == null) {
      setState(() {
        _statusMessage = '❌ JSON構造化データがありません';
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _statusMessage = '🎨 HTMLグラレコ生成中...';
    });

    try {
      final result = await _graphicalRecordService.convertJsonToGraphicalRecord(
        jsonData: _jsonData!,
        template: _selectedTemplate,
        customStyle: '',
      );

      if (result.success && result.htmlContent != null) {
        setState(() {
          _graphicalRecordHtml = result.htmlContent!;
          _statusMessage = '✅ グラレコ生成完了！右側でプレビューを確認してください';
        });
      } else {
        setState(() {
          _statusMessage = '❌ グラレコ生成エラー: ${result.error ?? "Unknown error"}';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = '❌ グラレコ生成エラー: $e';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  /// グラレコHTMLをダウンロード
  void _downloadGraphicalRecord() {
    if (_graphicalRecordHtml.isEmpty) return;

    try {
      final bytes = utf8.encode(_graphicalRecordHtml);
      final blob = html.Blob([bytes], 'text/html');
      final url = html.Url.createObjectUrlFromBlob(blob);

      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download',
            'グラレコ_${DateTime.now().toString().substring(0, 10)}.html')
        ..click();

      html.Url.revokeObjectUrl(url);

      setState(() {
        _statusMessage = '📄 グラレコHTMLファイルをダウンロードしました';
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ ダウンロードエラー: $e';
      });
    }
  }

  /// テンプレート選択ボタンを構築
  Widget _buildTemplateButton(
      String templateId, String templateName, Color color) {
    final isSelected = _selectedTemplate == templateId;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTemplate = templateId;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.3) : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            SizedBox(height: 4),
            Text(
              templateName,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
