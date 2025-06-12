import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:js_util' as js_util;
import 'dart:convert';

/// 音声録音サービス (Phase R2)
/// JavaScript の Web Audio API と連携
class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  // 録音状態管理
  bool _isRecording = false;
  Function(String)? _onAudioRecorded;
  Function(bool)? _onRecordingStateChanged;

  bool get isRecording => _isRecording;

  /// 音声録音完了時のコールバック設定
  void setOnAudioRecorded(Function(String base64Audio) callback) {
    _onAudioRecorded = callback;
  }

  /// 録音状態変更時のコールバック設定
  void setOnRecordingStateChanged(Function(bool isRecording) callback) {
    _onRecordingStateChanged = callback;
  }

  /// JavaScript Bridge初期化
  void initializeJavaScriptBridge() {
    // JavaScript側からの録音開始通知
    js.context['onRecordingStarted'] = js.allowInterop(() {
      print('🎤 [AudioService] 録音開始通知受信');
      _isRecording = true;
      _onRecordingStateChanged?.call(true);
    });

    // JavaScript側からの録音停止通知
    js.context['onRecordingStopped'] = js.allowInterop(() {
      print('⏹️ [AudioService] 録音停止通知受信');
      _isRecording = false;
      _onRecordingStateChanged?.call(false);
    });

    // JavaScript側からの音声データ受信
    js.context['onAudioRecorded'] = js.allowInterop((data) {
      print('✅ [AudioService] 音声データ受信');
      try {
        final audioData = data['audioData'] as String;
        final size = data['size'] as num;
        final duration = data['duration'] as num;

        print('📊 音声データ: ${size}bytes, ${duration}ms');
        _onAudioRecorded?.call(audioData);
      } catch (e) {
        print('❌ [AudioService] 音声データ処理エラー: $e');
      }
    });

    print('🔗 [AudioService] JavaScript Bridge初期化完了');
  }

  /// 録音開始
  Future<bool> startRecording() async {
    try {
      print('🎤 [AudioService] 録音開始要求');

      // JavaScript側の録音開始関数を呼び出し（Promiseを適切に処理）
      final jsResult = js.context.callMethod('startRecording');
      final result = await js_util.promiseToFuture<bool>(jsResult);

      if (result == true) {
        print('✅ [AudioService] 録音開始成功');
        return true;
      } else {
        print('❌ [AudioService] 録音開始失敗');
        return false;
      }
    } catch (e) {
      print('❌ [AudioService] 録音開始エラー: $e');
      return false;
    }
  }

  /// 録音停止
  Future<bool> stopRecording() async {
    try {
      print('⏹️ [AudioService] 録音停止要求');

      // JavaScript側の録音停止関数を呼び出し（同期処理なのでそのまま）
      final result = js.context.callMethod('stopRecording');

      if (result == true) {
        print('✅ [AudioService] 録音停止成功');
        return true;
      } else {
        print('❌ [AudioService] 録音停止失敗');
        return false;
      }
    } catch (e) {
      print('❌ [AudioService] 録音停止エラー: $e');
      return false;
    }
  }

  /// マイクアクセス許可確認
  Future<bool> checkMicrophonePermission() async {
    try {
      // ブラウザのマイクアクセス許可状態を確認
      final mediaDevices = html.window.navigator.mediaDevices;
      if (mediaDevices != null) {
        await mediaDevices.getUserMedia({'audio': true});
        print('✅ [AudioService] マイクアクセス許可済み');
        return true;
      }
      return false;
    } catch (e) {
      print('❌ [AudioService] マイクアクセス許可なし: $e');
      return false;
    }
  }

  /// 音声データをWAVファイルとしてダウンロード（デバッグ用）
  void downloadAudioAsFile(String base64Audio, String filename) {
    try {
      final bytes = base64Decode(base64Audio);
      final blob = html.Blob([bytes], 'audio/wav');
      final url = html.Url.createObjectUrlFromBlob(blob);

      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..click();

      html.Url.revokeObjectUrl(url);
      print('💾 [AudioService] 音声ファイルダウンロード: $filename');
    } catch (e) {
      print('❌ [AudioService] ファイルダウンロードエラー: $e');
    }
  }

  /// リソース解放
  void dispose() {
    _isRecording = false;
    _onAudioRecorded = null;
    _onRecordingStateChanged = null;

    // JavaScript側のクリーンアップ
    try {
      js.context.callMethod('audioRecorder.cleanup');
      print('🧹 [AudioService] リソース解放完了');
    } catch (e) {
      print('⚠️ [AudioService] クリーンアップエラー: $e');
    }
  }
}
