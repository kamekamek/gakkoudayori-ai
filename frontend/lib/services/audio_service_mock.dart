import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../mock/sample_data.dart';

/// AudioServiceのモック実装（デモ用）
class AudioServiceMock {
  static final AudioServiceMock _instance = AudioServiceMock._internal();
  factory AudioServiceMock() => _instance;
  AudioServiceMock._internal();

  // 録音状態管理
  bool _isRecording = false;
  Timer? _recordingTimer;
  Timer? _audioLevelTimer;
  
  Function(String)? _onAudioRecorded;
  Function(bool)? _onRecordingStateChanged;
  Function(String)? _onTranscriptionCompleted;
  Function(double)? _onAudioLevelChanged;

  bool get isRecording => _isRecording;

  /// 音声録音完了時のコールバック設定
  void setOnAudioRecorded(Function(String base64Audio) callback) {
    _onAudioRecorded = callback;
  }

  /// 録音状態変更時のコールバック設定
  void setOnRecordingStateChanged(Function(bool isRecording) callback) {
    _onRecordingStateChanged = callback;
  }

  /// 文字起こし完了時のコールバック設定
  void setOnTranscriptionCompleted(Function(String transcript) callback) {
    _onTranscriptionCompleted = callback;
  }

  /// 音声レベル変更時のコールバック設定（波形表示用）
  void setOnAudioLevelChanged(Function(double level) callback) {
    _onAudioLevelChanged = callback;
  }

  /// JavaScript Bridge初期化（モックでは何もしない）
  void initializeJavaScriptBridge() {
    debugPrint('[AudioServiceMock] JavaScript Bridge initialized (mock)');
  }

  /// 録音開始（モック）
  Future<bool> startRecording() async {
    debugPrint('[AudioServiceMock] 録音開始');
    
    if (_isRecording) {
      debugPrint('[AudioServiceMock] 既に録音中です');
      return false;
    }

    _isRecording = true;
    _onRecordingStateChanged?.call(true);

    // モック用の音声レベルアニメーション
    _startAudioLevelAnimation();

    return true;
  }

  /// 録音停止（モック）
  Future<bool> stopRecording() async {
    debugPrint('[AudioServiceMock] 録音停止');
    
    if (!_isRecording) {
      debugPrint('[AudioServiceMock] 録音していません');
      return false;
    }

    _isRecording = false;
    _onRecordingStateChanged?.call(false);

    // アニメーション停止
    _stopAudioLevelAnimation();

    // モック文字起こし実行
    await _simulateTranscription();

    return true;
  }

  /// 音声の送信（モック）
  Future<Map<String, dynamic>> sendAudioForTranscription(String base64Audio) async {
    await Future.delayed(const Duration(milliseconds: 1500)); // リアルな処理時間

    // ダミーの文字起こし結果
    final transcript = MockSampleData.getRandomVoiceRecognitionSample();
    
    return {
      'success': true,
      'transcript': transcript,
      'confidence': 0.95,
      'language': 'ja-JP',
    };
  }

  /// 音声レベルアニメーション開始
  void _startAudioLevelAnimation() {
    _audioLevelTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!_isRecording) {
        timer.cancel();
        return;
      }

      // 自然な音声レベルの変化をシミュレート
      final random = Random();
      final baseLevel = 0.3 + (random.nextDouble() * 0.4); // 0.3-0.7の範囲
      final spike = random.nextDouble() < 0.2 ? random.nextDouble() * 0.3 : 0; // 20%の確率でスパイク
      final level = (baseLevel + spike).clamp(0.0, 1.0);

      _onAudioLevelChanged?.call(level);
    });
  }

  /// 音声レベルアニメーション停止
  void _stopAudioLevelAnimation() {
    _audioLevelTimer?.cancel();
    _audioLevelTimer = null;
    _onAudioLevelChanged?.call(0.0);
  }

  /// 文字起こしシミュレーション
  Future<void> _simulateTranscription() async {
    debugPrint('[AudioServiceMock] 文字起こし開始');

    // 処理中の状態を少し維持
    await Future.delayed(const Duration(milliseconds: 800));

    // ランダムな文字起こし結果を選択
    final transcript = MockSampleData.getRandomVoiceRecognitionSample();
    
    debugPrint('[AudioServiceMock] 文字起こし完了: $transcript');
    _onTranscriptionCompleted?.call(transcript);
  }

  /// ブラウザサポートチェック（モック）
  Future<bool> checkBrowserSupport() async {
    // モックでは常にサポートありとする
    return true;
  }

  /// マイクアクセス許可チェック（モック）
  Future<bool> requestMicrophonePermission() async {
    // モックでは常に許可されているとする
    await Future.delayed(const Duration(milliseconds: 300));
    return true;
  }

  /// 録音データクリア
  void clearRecording() {
    debugPrint('[AudioServiceMock] 録音データクリア');
    _stopAudioLevelAnimation();
    _isRecording = false;
    _onRecordingStateChanged?.call(false);
  }

  /// リソース解放
  void dispose() {
    _audioLevelTimer?.cancel();
    _recordingTimer?.cancel();
    _isRecording = false;
  }

  /// デバッグ用：手動で文字起こし結果を設定
  void setMockTranscriptionResult(String transcript) {
    _onTranscriptionCompleted?.call(transcript);
  }

  /// デバッグ用：手動で音声レベルを設定
  void setMockAudioLevel(double level) {
    _onAudioLevelChanged?.call(level.clamp(0.0, 1.0));
  }

  /// デバッグ用：ランダム音声レベルアニメーションを開始
  void startRandomAudioLevelAnimation() {
    _startAudioLevelAnimation();
  }

  /// デバッグ用：音声レベルアニメーションを停止
  void stopRandomAudioLevelAnimation() {
    _stopAudioLevelAnimation();
  }
}