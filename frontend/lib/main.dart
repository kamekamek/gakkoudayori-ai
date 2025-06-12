import 'package:flutter/material.dart';
import 'services/audio_service.dart';

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
  bool _isRecording = false;
  String _recordedAudio = '';
  String _transcribedText = '';
  String _statusMessage = 'Phase R2: 音声録音機能実装完了';

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
        _statusMessage = '✅ 文字起こし完了！次のステップ：AI生成';
      });
      print('📝 文字起こし結果: $transcript');
    });
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
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
                      SizedBox(height: 8),
                      Text(
                        '🤖 次のステップ：Gemini AIで学級通信生成',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[600],
                          fontStyle: FontStyle.italic,
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
