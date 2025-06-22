import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:js_util' as js_util;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

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

  /// JavaScript Bridge初期化
  void initializeJavaScriptBridge() {
    // JavaScript側からの録音開始通知
    js.context['onRecordingStarted'] = js.allowInterop(() {
      if (kDebugMode) debugPrint('🎤 [AudioService] 録音開始通知受信');
      _isRecording = true;
      _onRecordingStateChanged?.call(true);
    });

    // JavaScript側からの録音停止通知
    js.context['onRecordingStopped'] = js.allowInterop(() {
      if (kDebugMode) debugPrint('⏹️ [AudioService] 録音停止通知受信');
      _isRecording = false;
      _onRecordingStateChanged?.call(false);
    });

    // JavaScript側からの音声データ受信
    js.context['onAudioRecorded'] = js.allowInterop((data) {
      if (kDebugMode) debugPrint('✅ [AudioService] 音声データ受信');
      try {
        final audioData = data['audioData'] as String;
        final size = data['size'] as num;
        final duration = data['duration'] as num;

        if (kDebugMode) debugPrint('📊 音声データ: ${size}bytes, ${duration}ms');
        _onAudioRecorded?.call(audioData);

        // 自動的に文字起こし処理を実行
        _performSpeechToText(audioData);
      } catch (e) {
        if (kDebugMode) debugPrint('❌ [AudioService] 音声データ処理エラー: $e');
      }
    });

    // JavaScript側からの音声レベル受信（波形表示用）
    js.context['onAudioLevelChanged'] = js.allowInterop((level) {
      try {
        final audioLevel = (level as num).toDouble();
        _onAudioLevelChanged?.call(audioLevel);
      } catch (e) {
        if (kDebugMode) debugPrint('❌ [AudioService] 音声レベル処理エラー: $e');
      }
    });

    if (kDebugMode) debugPrint('🔗 [AudioService] JavaScript Bridge初期化完了');
  }

  /// 録音開始
  Future<bool> startRecording() async {
    try {
      if (kDebugMode) debugPrint('🎤 [AudioService] 録音開始要求');

      // JavaScript環境チェック
      if (js.context['startRecording'] == null) {
        if (kDebugMode) debugPrint('❌ [AudioService] startRecording関数がJavaScriptで利用できません');
        return false;
      }

      if (js.context['audioRecorder'] == null) {
        if (kDebugMode) debugPrint('❌ [AudioService] audioRecorderインスタンスがJavaScriptで利用できません');
        return false;
      }

      // JavaScript側の録音開始関数を呼び出し
      if (kDebugMode) debugPrint('🔗 [AudioService] JavaScript関数呼び出し開始');
      final jsResult = js.context.callMethod('startRecording');
      if (kDebugMode) debugPrint('🔗 [AudioService] Promise待機開始');

      // JavaScript関数の戻り値をチェック
      if (jsResult == null) {
        if (kDebugMode) debugPrint('❌ [AudioService] JavaScript関数が null を返しました');
        return false;
      }

      // Promiseかどうか確認
      bool result;
      if (js_util.hasProperty(jsResult, 'then')) {
        // Promiseの場合
        if (kDebugMode) debugPrint('🔗 [AudioService] Promise検出 - 非同期待機中');
        try {
          final promiseResult = await js_util.promiseToFuture(jsResult);
          if (kDebugMode) debugPrint('🔗 [AudioService] Promise結果: $promiseResult (${promiseResult.runtimeType})');
          result = promiseResult == true || promiseResult == 'true' || promiseResult == 1;
        } catch (promiseError) {
          if (kDebugMode) debugPrint('❌ [AudioService] Promise実行エラー: $promiseError');
          return false;
        }
      } else {
        // 同期的な戻り値の場合
        if (kDebugMode) debugPrint('🔗 [AudioService] 同期的戻り値検出: $jsResult (${jsResult.runtimeType})');
        result = jsResult == true || jsResult == 'true' || jsResult == 1;
      }

      if (kDebugMode) debugPrint('🔗 [AudioService] 最終結果: $result');

      if (result == true) {
        if (kDebugMode) debugPrint('✅ [AudioService] 録音開始成功');
        return true;
      } else {
        if (kDebugMode) debugPrint('❌ [AudioService] 録音開始失敗 - 戻り値: $result');
        return false;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [AudioService] 録音開始エラー: $e');
      if (kDebugMode) debugPrint('  エラー詳細: ${e.runtimeType}');
      return false;
    }
  }

  /// 録音停止
  Future<bool> stopRecording() async {
    try {
      if (kDebugMode) debugPrint('⏹️ [AudioService] 録音停止要求');

      // JavaScript側の録音停止関数を呼び出し（同期処理なのでそのまま）
      final result = js.context.callMethod('stopRecording');

      if (result == true) {
        if (kDebugMode) debugPrint('✅ [AudioService] 録音停止成功');
        return true;
      } else {
        if (kDebugMode) debugPrint('❌ [AudioService] 録音停止失敗');
        return false;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [AudioService] 録音停止エラー: $e');
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
        if (kDebugMode) debugPrint('✅ [AudioService] マイクアクセス許可済み');
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [AudioService] マイクアクセス許可なし: $e');
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
      if (kDebugMode) debugPrint('💾 [AudioService] 音声ファイルダウンロード: $filename');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [AudioService] ファイルダウンロードエラー: $e');
    }
  }

  /// リソース解放
  void dispose() {
    _isRecording = false;
    _onAudioRecorded = null;
    _onRecordingStateChanged = null;
    _onTranscriptionCompleted = null;
    _onAudioLevelChanged = null;

    // JavaScript側のクリーンアップ
    try {
      js.context.callMethod('audioRecorder.cleanup');
      if (kDebugMode) debugPrint('🧹 [AudioService] リソース解放完了');
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ [AudioService] クリーンアップエラー: $e');
    }
  }

  /// 音声データを文字起こしAPIに送信
  Future<void> _performSpeechToText(String base64AudioData) async {
    try {
      if (kDebugMode) debugPrint('🎙️ [AudioService] 文字起こし処理開始...');

      // Base64データをデコードしてバイナリデータに変換
      final audioBytes = base64Decode(base64AudioData);
      if (kDebugMode) debugPrint('📄 [AudioService] 音声データサイズ: ${audioBytes.length} bytes');

      // バックエンドAPIのエンドポイント（環境変数から取得）
      final apiUrl = '${AppConfig.apiBaseUrl}/transcribe';

      // マルチパートフォームデータとして送信
      final request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      request.files.add(
        http.MultipartFile.fromBytes(
          'audio_file',
          audioBytes,
          filename: 'recording.webm',
        ),
      );
      request.fields['language'] = 'ja-JP';
      request.fields['sample_rate'] = '48000'; // WebM Opus形式に合わせて48kHzに変更
      request.fields['user_dictionary'] = '学級通信,運動会,学習発表会,子どもたち,先生,授業';

      if (kDebugMode) debugPrint('📤 [AudioService] Speech-to-Text API呼び出し中...');
      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(responseData);
        if (jsonData['success'] == true) {
          final transcript = jsonData['data']['transcript'] as String;
          final confidence = jsonData['data']['confidence'] as double;

          if (kDebugMode) debugPrint('✅ [AudioService] 文字起こし成功');
          if (kDebugMode) debugPrint('📝 [AudioService] 結果: $transcript');
          if (kDebugMode) debugPrint(
              '🎯 [AudioService] 信頼度: ${(confidence * 100).toStringAsFixed(1)}%');

          // 文字起こし完了をコールバックで通知
          _onTranscriptionCompleted?.call(transcript);
        } else {
          if (kDebugMode) debugPrint('❌ [AudioService] 文字起こしAPIエラー: ${jsonData['error']}');
        }
      } else {
        if (kDebugMode) debugPrint('❌ [AudioService] HTTPエラー: ${response.statusCode}');
        if (kDebugMode) debugPrint('📄 [AudioService] レスポンス: $responseData');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [AudioService] 文字起こし処理エラー: $e');
    }
  }
}
