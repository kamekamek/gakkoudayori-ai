import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import 'dart:convert';
import 'dart:ui_web' as ui_web;
import 'services/audio_service.dart';
import 'services/ai_service.dart';
import 'widgets/html_preview_widget.dart';
import 'package:flutter/services.dart';
import 'dart:html' as html;
import 'dart:js_interop' as js_interop;
import 'package:http/http.dart' as http;

/// 学級通信AI - 音声入力システム（リビルド版）
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(YutoriKyoshituApp());
}

class YutoriKyoshituApp extends StatelessWidget {
  const YutoriKyoshituApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '学級通信AI',
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
  String _recordedAudio = '';
  String _transcribedText = '';
  String _generatedHtml = '';
  String _textInput = ''; // 文字入力用
  bool _isProcessing = false; // 処理中フラグ
  bool _showTranscriptionConfirm = false; // 文字起こし確認表示

  final TextEditingController _textController = TextEditingController();
  AIGenerationResult? _aiResult;
  String _statusMessage = '🎤 音声録音または文字入力で学級通信を作成してください';

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
        _recordedAudio = base64Audio;
        _statusMessage = '🎙️ 文字起こし処理中...';
      });
      print('🎵 録音された音声データサイズ: ${base64Audio.length}文字');
    });

    // 文字起こし完了コールバック
    _audioService.setOnTranscriptionCompleted((transcript) {
      setState(() {
        _transcribedText = transcript;
        _textController.text = transcript; // テキストボックスに文字起こし結果を表示
        _statusMessage = '✅ 文字起こし完了！内容を確認して送信してください';
      });
      print('📝 文字起こし結果: $transcript');

      // 自動的にAI生成を開始は削除 - ユーザーが送信ボタンを押すまで待機
    });
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }

  // AI学級通信生成
  Future<void> _generateNewsletter(String transcript) async {
    try {
      setState(() {
        _statusMessage = '🤖 AI文章生成中...';
        _isProcessing = true;
      });

      final result = await _aiService.generateNewsletter(
        transcribedText: transcript,
        templateType: 'daily_report',
        includeGreeting: true,
        targetAudience: 'parents',
        season: 'auto',
      );

      setState(() {
        _aiResult = result;
        _generatedHtml = result.newsletterHtml;
        _statusMessage = '✅ 学級通信生成完了！(${result.qualityScore})';
        _isProcessing = false;
      });

      print(
          '🎉 AI生成完了 - 文字数: ${result.characterCount}, 時間: ${result.processingTimeDisplay}');
    } catch (e) {
      setState(() {
        _statusMessage = '❌ AI生成に失敗しました: $e';
        _isProcessing = false;
      });
      print('❌ AI生成エラー: $e');
    }
  }

  // AI学級通信再生成
  Future<void> _regenerateNewsletter() async {
    if (_transcribedText.isEmpty) return;

    setState(() {
      _statusMessage = '🔄 再生成中...';
      _aiResult = null;
      _generatedHtml = '';
    });

    // 同じ文字起こしテキストで再生成
    await _generateNewsletter(_transcribedText);
  }

  // HTMLファイルダウンロード (Phase R5)
  void _downloadHtml() {
    if (_generatedHtml.isEmpty) return;

    try {
      // HTMLファイル生成
      final htmlContent = '''
<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>学級通信 - ${DateTime.now().toString().substring(0, 10)}</title>
    <style>
        body { 
            font-family: 'Hiragino Sans', 'Yu Gothic', sans-serif; 
            max-width: 800px; 
            margin: 0 auto; 
            padding: 20px; 
            line-height: 1.6;
        }
        h1, h2, h3 { color: #2c3e50; }
        .header { text-align: center; border-bottom: 2px solid #3498db; padding-bottom: 10px; margin-bottom: 20px; }
        .footer { text-align: center; margin-top: 30px; font-size: 0.9em; color: #7f8c8d; }
        @media print { body { margin: 0; } }
    </style>
</head>
<body>
$_generatedHtml
    <div class="footer">
        <p>作成日: ${DateTime.now().toString().substring(0, 16)} | 学級通信AI生成システム</p>
    </div>
</body>
</html>''';

      // HTMLファイルダウンロード (Web Streams API対応)
      final bytes = utf8.encode(htmlContent);
      final anchor = web.HTMLAnchorElement();
      anchor.href =
          'data:text/html;charset=utf-8,${Uri.encodeComponent(htmlContent)}';
      anchor.download =
          '学級通信_${DateTime.now().toString().substring(0, 10)}.html';
      anchor.click();

      setState(() {
        _statusMessage = '📄 学級通信をダウンロードしました！';
      });

      print('✅ HTMLダウンロード成功');
    } catch (e) {
      setState(() {
        _statusMessage = '❌ ダウンロードに失敗しました: $e';
      });
      print('❌ ダウンロードエラー: $e');
    }
  }

  // 録音開始/停止ボタンハンドラ
  void _toggleRecording() async {
    if (_isRecording) {
      // 録音停止
      final success = await _audioService.stopRecording();
      if (!success) {
        setState(() {
          _statusMessage = '❌ 録音停止に失敗しました';
        });
      }
    } else {
      // 録音開始
      final success = await _audioService.startRecording();
      if (!success) {
        setState(() {
          _statusMessage = '❌ 録音開始に失敗しました。マイクの許可を確認してください。';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('🎓 学級通信AI'),
        backgroundColor: Colors.blue,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  kToolbarHeight -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(height: 20),

                  // シンプルなタイトル
                  Text(
                    '🎓 学級通信作成',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 40),

                  // 入力方法選択（シンプル化）
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 音声入力（中央寄せ）
                      SizedBox(
                        width: 300,
                        child: ElevatedButton.icon(
                          onPressed: _toggleRecording,
                          icon: Icon(_isRecording ? Icons.stop : Icons.mic,
                              size: 32),
                          label: Text(_isRecording ? '録音停止' : '音声で入力'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(double.infinity, 80),
                            backgroundColor:
                                _isRecording ? Colors.red : Colors.blue,
                            foregroundColor: Colors.white,
                            textStyle: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 30),

                  // ステータス表示（シンプル化）
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _statusMessage,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  SizedBox(height: 30),

                  // 文字入力フィールド（常時表示）
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '📝 内容を入力してください',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                        SizedBox(height: 12),
                        TextField(
                          controller: _textController,
                          maxLines: 6,
                          decoration: InputDecoration(
                            hintText:
                                '音声録音または文字入力で学級通信の内容を入力...\n例：今日は避難訓練がありました。',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: EdgeInsets.all(16),
                          ),
                          style: TextStyle(fontSize: 16),
                          onChanged: (value) {
                            setState(() {
                              _textInput = value;
                              _transcribedText = value; // テキスト入力内容を統一
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 30),

                  // 送信ボタン（明確化）
                  if (_textController.text.isNotEmpty && !_isProcessing)
                    Container(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _generateNewsletter(_textController.text),
                        icon: Icon(Icons.send, size: 24),
                        label: Text('学級通信を作成する'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, 60),
                          backgroundColor: Colors.orange[600],
                          foregroundColor: Colors.white,
                          textStyle: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

                  // 処理中表示
                  if (_isProcessing)
                    Container(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 12),
                          Text('AI が学級通信を作成中...',
                              style: TextStyle(
                                  fontSize: 16, color: Colors.orange[700])),
                        ],
                      ),
                    ),

                  // AI生成結果表示
                  if (_aiResult != null)
                    Container(
                      padding: EdgeInsets.all(16),
                      margin: EdgeInsets.only(top: 20),
                      decoration: BoxDecoration(
                        color: Colors.purple[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.purple[300]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '🤖 AI生成結果',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.purple[700],
                                ),
                              ),
                              Spacer(),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.purple[200],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _aiResult!.qualityScore,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.purple[800],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),

                          // 生成情報
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.purple[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Column(
                                  children: [
                                    Text('文字数',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.purple[600])),
                                    Text('${_aiResult!.characterCount}',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                Column(
                                  children: [
                                    Text('処理時間',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.purple[600])),
                                    Text(_aiResult!.processingTimeDisplay,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                Column(
                                  children: [
                                    Text('季節',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.purple[600])),
                                    Text(_aiResult!.season,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 16),

                          // HTMLプレビュー表示
                          Text(
                            '📄 学級通信プレビュー',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.purple[700],
                            ),
                          ),
                          SizedBox(height: 8),

                          // レスポンシブな高さ計算（画面高さの30%、最大400px、最小200px）
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final screenHeight =
                                  MediaQuery.of(context).size.height;
                              final previewHeight =
                                  (screenHeight * 0.3).clamp(200.0, 400.0);

                              return HtmlPreviewWidget(
                                htmlContent: _generatedHtml,
                                height: previewHeight,
                              );
                            },
                          ),

                          SizedBox(height: 16),

                          // アクションボタン
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _regenerateNewsletter(),
                                  icon: Icon(Icons.refresh),
                                  label: Text('🔄 再生成'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange[600],
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: ElevatedButton.icon(
                                  onPressed: _downloadHtml,
                                  icon: Icon(Icons.download),
                                  label: Text('📄 ダウンロード'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.purple[600],
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
