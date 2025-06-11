import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

/// 音声入力から学級通信自動生成ウィジェット
///
/// 完全なフロー:
/// 1. 音声ファイルアップロード/録音
/// 2. Speech-to-Text API で文字起こし
/// 3. Gemini API で学級通信生成
/// 4. エディタに自動挿入
class VoiceInputWidget extends StatefulWidget {
  final Function(String) onContentGenerated;

  const VoiceInputWidget({
    Key? key,
    required this.onContentGenerated,
  }) : super(key: key);

  @override
  State<VoiceInputWidget> createState() => _VoiceInputWidgetState();
}

class _VoiceInputWidgetState extends State<VoiceInputWidget>
    with TickerProviderStateMixin {
  // 状態管理
  bool _isProcessing = false;
  String _currentStep = '';
  String _speechResult = '';
  String _generatedContent = '';
  double _progressValue = 0.0;

  // アニメーション
  late AnimationController _waveController;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _waveAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildMainContent(),
          if (_isProcessing) ...[
            const SizedBox(height: 20),
            _buildProgressIndicator(),
          ],
          if (_speechResult.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildSpeechResult(),
          ],
          if (_generatedContent.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildGeneratedContent(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.auto_awesome,
            color: Colors.blue.shade700,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'AI学級通信生成',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '音声から自動で学級通信を作成します',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent() {
    if (_isProcessing) {
      return _buildProcessingView();
    }

    return Column(
      children: [
        // 音声ファイルアップロードボタン
        Container(
          width: double.infinity,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.blue.shade200,
              width: 2,
              style: BorderStyle.solid,
            ),
          ),
          child: InkWell(
            onTap: _pickAudioFile,
            borderRadius: BorderRadius.circular(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.upload_file,
                  size: 32,
                  color: Colors.blue.shade600,
                ),
                const SizedBox(height: 8),
                Text(
                  '音声ファイルをアップロード',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade700,
                  ),
                ),
                Text(
                  'WAV, MP3, M4A対応',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // 使用例
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: Colors.orange.shade700,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '使用例',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '「今日は運動会の練習をしました。子どもたちは一生懸命頑張っていて、本番が楽しみです。保護者の皆様もぜひ応援してください。」',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange.shade800,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProcessingView() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _waveAnimation,
          builder: (context, child) {
            return Container(
              height: 80,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return Container(
                      width: 4,
                      height: 20 +
                          (20 *
                              _waveAnimation.value *
                              (index % 2 == 0 ? 1 : -1)),
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        Text(
          _currentStep,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return Column(
      children: [
        LinearProgressIndicator(
          value: _progressValue,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade400),
        ),
        const SizedBox(height: 8),
        Text(
          '${(_progressValue * 100).toInt()}% 完了',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildSpeechResult() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.record_voice_over,
                color: Colors.green.shade700,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                '音声認識結果',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _speechResult,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneratedContent() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: Colors.purple.shade700,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'AI生成学級通信',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple.shade700,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  widget.onContentGenerated(_generatedContent);
                  _resetState();
                },
                child: const Text('エディタに挿入'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _generatedContent,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAudioFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['wav', 'mp3', 'm4a', 'aac'],
      );

      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _isProcessing = true;
          _currentStep = '音声ファイルを処理中...';
          _progressValue = 0.1;
        });

        _waveController.repeat();

        final audioBytes = result.files.single.bytes!;
        await _processAudioToNewsletter(audioBytes);
      }
    } catch (e) {
      _showErrorDialog('ファイル選択エラー', 'ファイルの選択中にエラーが発生しました: $e');
    }
  }

  Future<void> _processAudioToNewsletter(Uint8List audioBytes) async {
    try {
      // ステップ1: 音声文字起こし
      await _transcribeAudio(audioBytes);

      // ステップ2: Gemini APIで学級通信生成
      await _generateNewsletter();

      setState(() {
        _isProcessing = false;
        _currentStep = '';
        _progressValue = 1.0;
      });

      _waveController.stop();
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _currentStep = '';
      });
      _waveController.stop();
      _showErrorDialog('処理エラー', '音声処理中にエラーが発生しました: $e');
    }
  }

  Future<void> _transcribeAudio(Uint8List audioBytes) async {
    setState(() {
      _currentStep = '音声を文字に変換中...';
      _progressValue = 0.3;
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://localhost:8080/api/v1/ai/transcribe'),
      );

      request.files.add(
        http.MultipartFile.fromBytes(
          'audio_file',
          audioBytes,
          filename: 'audio.wav',
        ),
      );

      request.fields['language'] = 'ja-JP';
      request.fields['user_dictionary'] = '運動会,学習発表会,子どもたち,頑張っていました,保護者,先生';

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonData = json.decode(responseData);

      if (jsonData['success']) {
        setState(() {
          _speechResult = jsonData['data']['transcript'];
          _progressValue = 0.6;
        });
      } else {
        throw Exception(jsonData['error']);
      }
    } catch (e) {
      throw Exception('音声認識エラー: $e');
    }
  }

  Future<void> _generateNewsletter() async {
    setState(() {
      _currentStep = 'AI学級通信を生成中...';
      _progressValue = 0.8;
    });

    try {
      final response = await http.post(
        Uri.parse('http://localhost:8080/api/v1/ai/generate-newsletter'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'speech_text': _speechResult,
          'template_type': 'daily_report',
          'include_greeting': true,
          'target_audience': 'parents',
        }),
      );

      if (response.statusCode == 200) {
        var jsonData = json.decode(response.body);
        if (jsonData['success']) {
          setState(() {
            _generatedContent = jsonData['data']['newsletter_html'];
            _progressValue = 1.0;
          });
        } else {
          throw Exception(jsonData['error']);
        }
      } else {
        throw Exception('サーバーエラー: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('学級通信生成エラー: $e');
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _resetState() {
    setState(() {
      _speechResult = '';
      _generatedContent = '';
      _progressValue = 0.0;
      _currentStep = '';
    });
  }
}
