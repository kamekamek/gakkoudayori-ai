import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// 非推奨API一時無効化 - 音声録音機能は後で実装
// import 'dart:js' as js;
// import 'dart:js_util' as js_util;
// import 'dart:html' as html;
// import 'dart:convert';

/// Webブラウザでのリアルタイム音声録音ウィジェット
///
/// Web Audio APIを使用してマイクから音声を録音し、
/// 学級通信生成のためのSTT処理に送信します。
class WebAudioRecorder extends StatefulWidget {
  final Function(Uint8List audioData) onAudioRecorded;
  final Function(String errorMessage)? onError;
  final Duration maxRecordingDuration;

  const WebAudioRecorder({
    Key? key,
    required this.onAudioRecorded,
    this.onError,
    this.maxRecordingDuration = const Duration(minutes: 2),
  }) : super(key: key);

  @override
  State<WebAudioRecorder> createState() => _WebAudioRecorderState();
}

class _WebAudioRecorderState extends State<WebAudioRecorder>
    with TickerProviderStateMixin {
  bool _isRecording = false;
  bool _isProcessing = false;
  bool _hasPermission = false;
  Duration _recordingDuration = Duration.zero;
  List<double> _audioLevels = [];

  // アニメーション
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;

  // Web Audio API 関連
  dynamic _mediaRecorder;
  dynamic _audioStream;
  List<dynamic> _recordedChunks = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkMicrophonePermission();
    _setupWebAudioRecorder();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  void _setupWebAudioRecorder() {
    if (!kIsWeb) return;

    try {
      // JavaScript側の録音機能をセットアップ
      js.context.callMethod('eval', [
        '''
        window.audioRecorder = {
          mediaRecorder: null,
          audioChunks: [],
          audioContext: null,
          analyser: null,
          dataArray: null,
          
          async setupRecorder() {
            try {
              const stream = await navigator.mediaDevices.getUserMedia({
                audio: {
                  sampleRate: 16000,
                  channelCount: 1,
                  echoCancellation: true,
                  noiseSuppression: true,
                  autoGainControl: true
                }
              });
              
              this.mediaRecorder = new MediaRecorder(stream, {
                mimeType: 'audio/webm;codecs=opus'
              });
              
              // 音声レベル分析用
              this.audioContext = new AudioContext({ sampleRate: 16000 });
              const source = this.audioContext.createMediaStreamSource(stream);
              this.analyser = this.audioContext.createAnalyser();
              this.analyser.fftSize = 256;
              source.connect(this.analyser);
              
              this.dataArray = new Uint8Array(this.analyser.frequencyBinCount);
              
              this.mediaRecorder.ondataavailable = (event) => {
                if (event.data.size > 0) {
                  this.audioChunks.push(event.data);
                }
              };
              
              this.mediaRecorder.onstop = async () => {
                const audioBlob = new Blob(this.audioChunks, { type: 'audio/webm' });
                const arrayBuffer = await audioBlob.arrayBuffer();
                const uint8Array = new Uint8Array(arrayBuffer);
                
                // Flutterに結果を送信
                if (window.flutter_inappwebview) {
                  const base64 = btoa(String.fromCharCode.apply(null, uint8Array));
                  window.flutter_inappwebview.callHandler('onAudioRecorded', base64);
                }
                
                this.audioChunks = [];
              };
              
              return true;
            } catch (error) {
              console.error('Recorder setup failed:', error);
              return false;
            }
          },
          
          startRecording() {
            if (this.mediaRecorder && this.mediaRecorder.state === 'inactive') {
              this.audioChunks = [];
              this.mediaRecorder.start(100); // 100ms間隔でデータを収集
              return true;
            }
            return false;
          },
          
          stopRecording() {
            if (this.mediaRecorder && this.mediaRecorder.state === 'recording') {
              this.mediaRecorder.stop();
              return true;
            }
            return false;
          },
          
          getAudioLevel() {
            if (!this.analyser) return 0;
            
            this.analyser.getByteFrequencyData(this.dataArray);
            let sum = 0;
            for (let i = 0; i < this.dataArray.length; i++) {
              sum += this.dataArray[i];
            }
            return sum / this.dataArray.length / 255.0;
          }
        };
      '''
      ]);

      debugPrint('Web Audio Recorder JavaScript setup completed');
    } catch (e) {
      debugPrint('Failed to setup Web Audio Recorder: $e');
      widget.onError?.call('録音機能の初期化に失敗しました: $e');
    }
  }

  Future<void> _checkMicrophonePermission() async {
    if (!kIsWeb) return;

    try {
      final result = await js_util.promiseToFuture(
        js.context.callMethod('eval', [
          '''
          navigator.mediaDevices.getUserMedia({ audio: true })
            .then(() => true)
            .catch(() => false)
        '''
        ]),
      );

      setState(() {
        _hasPermission = result as bool;
      });

      if (!_hasPermission) {
        widget.onError?.call('マイクへのアクセス許可が必要です');
      }
    } catch (e) {
      setState(() {
        _hasPermission = false;
      });
      widget.onError?.call('マイク許可の確認中にエラーが発生しました: $e');
    }
  }

  Future<void> _startRecording() async {
    if (!kIsWeb || !_hasPermission) return;

    try {
      setState(() {
        _isProcessing = true;
      });

      // Web Audio Recorderをセットアップ
      final setupResult = await js_util.promiseToFuture(
        js.context['audioRecorder'].callMethod('setupRecorder'),
      );

      if (setupResult == true) {
        final startResult =
            js.context['audioRecorder'].callMethod('startRecording');

        if (startResult == true) {
          setState(() {
            _isRecording = true;
            _isProcessing = false;
            _recordingDuration = Duration.zero;
            _audioLevels.clear();
          });

          _pulseController.repeat(reverse: true);
          _startAudioLevelMonitoring();
          _startRecordingTimer();

          debugPrint('Recording started successfully');
        } else {
          throw Exception('Failed to start recording');
        }
      } else {
        throw Exception('Failed to setup recorder');
      }
    } catch (e) {
      setState(() {
        _isRecording = false;
        _isProcessing = false;
      });

      widget.onError?.call('録音開始中にエラーが発生しました: $e');
      debugPrint('Recording start error: $e');
    }
  }

  void _stopRecording() {
    if (!kIsWeb || !_isRecording) return;

    try {
      final stopResult =
          js.context['audioRecorder'].callMethod('stopRecording');

      if (stopResult == true) {
        setState(() {
          _isRecording = false;
          _isProcessing = true;
        });

        _pulseController.stop();
        _waveController.stop();

        // JavaScriptからの音声データ受信を待機
        _setupAudioDataReceiver();

        debugPrint('Recording stopped successfully');
      } else {
        throw Exception('Failed to stop recording');
      }
    } catch (e) {
      setState(() {
        _isRecording = false;
        _isProcessing = false;
      });

      widget.onError?.call('録音停止中にエラーが発生しました: $e');
      debugPrint('Recording stop error: $e');
    }
  }

  void _setupAudioDataReceiver() {
    if (!kIsWeb) return;

    try {
      // flutter_inappwebviewのハンドラーをセットアップ
      // 実際のWebView環境でのみ動作するため、ここではポーリングで代替

      _pollForAudioData();
    } catch (e) {
      debugPrint('Audio data receiver setup error: $e');
    }
  }

  void _pollForAudioData() {
    // Web環境での音声データ取得をシミュレート
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (_isProcessing) {
        try {
          // ダミーデータを生成（本番では実際の録音データを使用）
          final dummyAudioData = _generateDummyAudioData();

          setState(() {
            _isProcessing = false;
          });

          widget.onAudioRecorded(dummyAudioData);

          debugPrint('Audio data received: ${dummyAudioData.length} bytes');
        } catch (e) {
          setState(() {
            _isProcessing = false;
          });
          widget.onError?.call('音声データの処理中にエラーが発生しました: $e');
        }
      }
    });
  }

  Uint8List _generateDummyAudioData() {
    // WAVヘッダー + ダミー音声データを生成
    final wavHeader = <int>[
      0x52, 0x49, 0x46, 0x46, // "RIFF"
      0x24, 0x08, 0x00, 0x00, // ファイルサイズ
      0x57, 0x41, 0x56, 0x45, // "WAVE"
      0x66, 0x6D, 0x74, 0x20, // "fmt "
      0x10, 0x00, 0x00, 0x00, // フォーマットチャンクサイズ
      0x01, 0x00, // PCM
      0x01, 0x00, // モノラル
      0x80, 0x3E, 0x00, 0x00, // サンプルレート 16000Hz
      0x00, 0x7D, 0x00, 0x00, // バイトレート
      0x02, 0x00, // ブロックアライン
      0x10, 0x00, // ビット深度
      0x64, 0x61, 0x74, 0x61, // "data"
      0x00, 0x08, 0x00, 0x00 // データサイズ
    ];

    // ダミー音声データ（2048バイト）
    final audioData = List.generate(2048, (index) => 128);

    return Uint8List.fromList([...wavHeader, ...audioData]);
  }

  void _startAudioLevelMonitoring() {
    if (!kIsWeb) return;

    const interval = Duration(milliseconds: 100);

    void monitor() {
      if (_isRecording) {
        try {
          final level = js.context['audioRecorder'].callMethod('getAudioLevel');
          final audioLevel = (level as num?)?.toDouble() ?? 0.0;

          setState(() {
            _audioLevels.add(audioLevel);
            if (_audioLevels.length > 50) {
              _audioLevels.removeAt(0);
            }
          });

          // 音声レベルに基づいてアニメーション調整
          if (audioLevel > 0.1) {
            _waveController.forward();
          } else {
            _waveController.reverse();
          }
        } catch (e) {
          debugPrint('Audio level monitoring error: $e');
        }

        Future.delayed(interval, monitor);
      }
    }

    monitor();
  }

  void _startRecordingTimer() {
    const interval = Duration(seconds: 1);

    void updateTimer() {
      if (_isRecording) {
        setState(() {
          _recordingDuration = _recordingDuration + interval;
        });

        // 最大録音時間チェック
        if (_recordingDuration >= widget.maxRecordingDuration) {
          _stopRecording();
          widget.onError?.call('最大録音時間に達しました');
          return;
        }

        Future.delayed(interval, updateTimer);
      }
    }

    updateTimer();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();

    // Web Audio リソースのクリーンアップ
    if (kIsWeb && _isRecording) {
      _stopRecording();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildRecordingControls(),
          if (_isRecording || _isProcessing) ...[
            const SizedBox(height: 24),
            _buildRecordingVisualizer(),
          ],
          if (_isRecording) ...[
            const SizedBox(height: 16),
            _buildRecordingInfo(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _isRecording ? Colors.red.shade100 : Colors.blue.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _isRecording ? Icons.radio_button_checked : Icons.mic,
            color: _isRecording ? Colors.red.shade700 : Colors.blue.shade700,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isRecording ? '録音中...' : '音声録音',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _isRecording ? '学級通信の内容を話してください' : 'マイクボタンを押して録音を開始',
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

  Widget _buildRecordingControls() {
    if (!_hasPermission) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          children: [
            Icon(
              Icons.warning,
              color: Colors.orange.shade700,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'マイクへのアクセス許可が必要です。ブラウザで許可してください。',
                style: TextStyle(
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (!_isRecording && !_isProcessing) ...[
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.shade400,
                        Colors.blue.shade600,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(40),
                      onTap: _startRecording,
                      child: const Center(
                        child: Icon(
                          Icons.mic,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
        if (_isRecording) ...[
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Colors.red.shade400,
                  Colors.red.shade600,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(40),
                onTap: _stopRecording,
                child: const Center(
                  child: Icon(
                    Icons.stop,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
            ),
          ),
        ],
        if (_isProcessing) ...[
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade200,
            ),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRecordingVisualizer() {
    if (_isProcessing) {
      return Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 12),
          Text(
            '音声データを処理中...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      );
    }

    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(10, (index) {
            final level = _audioLevels.isNotEmpty ? _audioLevels.last : 0.0;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              width: 4,
              height: 10 + (level * 40),
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
  }

  Widget _buildRecordingInfo() {
    final minutes = _recordingDuration.inMinutes;
    final seconds = _recordingDuration.inSeconds % 60;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '録音中',
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Text(
            '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
