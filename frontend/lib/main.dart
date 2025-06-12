import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import 'dart:convert';
import 'services/audio_service.dart';
import 'services/ai_service.dart';

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
  AIGenerationResult? _aiResult;
  String _statusMessage = 'Phase R4: AI生成機能統合完了';

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
        _statusMessage = '✅ 文字起こし完了！AI生成中...';
      });
      print('📝 文字起こし結果: $transcript');

      // 自動的にAI生成を開始
      _generateNewsletter(transcript);
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
      });

      print(
          '🎉 AI生成完了 - 文字数: ${result.characterCount}, 時間: ${result.processingTimeDisplay}');
    } catch (e) {
      setState(() {
        _statusMessage = '❌ AI生成に失敗しました: $e';
      });
      print('❌ AI生成エラー: $e');
    }
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
        title: Text('🎤 学級通信AI - 音声入力システム'),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '音声→AI→学級通信の自動生成',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40),

              // Phase R2: 録音ボタン実装
              ElevatedButton.icon(
                onPressed: _toggleRecording,
                icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                label: Text(_isRecording ? '⏹️ 録音停止' : '🎤 録音開始'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(200, 60),
                  backgroundColor: _isRecording ? Colors.red : Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),

              SizedBox(height: 20),

              // ステータス表示
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _statusMessage,
                  style: TextStyle(
                    color: _isRecording ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              SizedBox(height: 20),

              // デバッグ情報
              if (_recordedAudio.isNotEmpty)
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '🎵 録音データあり',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '次のPhase: AI音声認識へ',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ],
                  ),
                ),

              // 文字起こし結果表示
              if (_transcribedText.isNotEmpty)
                Container(
                  padding: EdgeInsets.all(16),
                  margin: EdgeInsets.only(top: 20),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📝 文字起こし結果',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green[700],
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Text(
                          _transcribedText,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                            height: 1.4,
                          ),
                        ),
                      ),
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
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Column(
                              children: [
                                Text('処理時間',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.purple[600])),
                                Text(_aiResult!.processingTimeDisplay,
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Column(
                              children: [
                                Text('季節',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.purple[600])),
                                Text(_aiResult!.season,
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 12),

                      // ダウンロードボタン
                      ElevatedButton.icon(
                        onPressed: _downloadHtml,
                        icon: Icon(Icons.download),
                        label: Text('📄 学級通信をダウンロード'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple[600],
                          foregroundColor: Colors.white,
                          minimumSize: Size(double.infinity, 45),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
