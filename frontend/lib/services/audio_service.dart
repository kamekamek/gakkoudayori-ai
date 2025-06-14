import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:js_util' as js_util;
import 'dart:convert';
import 'package:http/http.dart' as http;

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

        // 自動的に文字起こし処理を実行
        _performSpeechToText(audioData);
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

      // JavaScript側の録音開始関数を呼び出し
      print('🔗 [AudioService] JavaScript関数呼び出し開始');
      final jsResult = js.context.callMethod('startRecording');
      print('🔗 [AudioService] Promise待機開始');

      // JavaScript関数の戻り値をチェック
      if (jsResult == null) {
        print('❌ [AudioService] JavaScript関数が null を返しました');
        return false;
      }

      // Promiseかどうか確認
      bool result;
      if (js_util.hasProperty(jsResult, 'then')) {
        // Promiseの場合
        print('🔗 [AudioService] Promise検出 - 非同期待機中');
        result = await js_util.promiseToFuture<bool>(jsResult);
      } else {
        // 同期的な戻り値の場合
        print('🔗 [AudioService] 同期的戻り値検出');
        result = jsResult as bool;
      }

      print('🔗 [AudioService] 最終結果: $result');

      if (result == true) {
        print('✅ [AudioService] 録音開始成功');
        return true;
      } else {
        print('❌ [AudioService] 録音開始失敗 - 戻り値: $result');
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
    _onTranscriptionCompleted = null;

    // JavaScript側のクリーンアップ
    try {
      js.context.callMethod('audioRecorder.cleanup');
      print('🧹 [AudioService] リソース解放完了');
    } catch (e) {
      print('⚠️ [AudioService] クリーンアップエラー: $e');
    }
  }

  /// 音声データを文字起こしAPIに送信
  Future<void> _performSpeechToText(String base64AudioData) async {
    try {
      print('🎙️ [AudioService] 文字起こし処理開始...');

      // Base64データをデコードしてバイナリデータに変換
      final audioBytes = base64Decode(base64AudioData);
      print('📄 [AudioService] 音声データサイズ: ${audioBytes.length} bytes');

      // バックエンドAPIのエンドポイント（本番環境では適切なURLに変更）
      const apiUrl = 'http://localhost:8081/api/v1/ai/transcribe';

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

      print('📤 [AudioService] Speech-to-Text API呼び出し中...');
      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(responseData);
        if (jsonData['success'] == true) {
          final transcript = jsonData['data']['transcript'] as String;
          final confidence = jsonData['data']['confidence'] as double;

          print('✅ [AudioService] 文字起こし成功');
          print('📝 [AudioService] 結果: $transcript');
          print(
              '🎯 [AudioService] 信頼度: ${(confidence * 100).toStringAsFixed(1)}%');

          // 文字起こし完了をコールバックで通知
          _onTranscriptionCompleted?.call(transcript);
        } else {
          print('❌ [AudioService] 文字起こしAPIエラー: ${jsonData['error']}');
        }
      } else {
        print('❌ [AudioService] HTTPエラー: ${response.statusCode}');
        print('📄 [AudioService] レスポンス: $responseData');
      }
    } catch (e) {
      print('❌ [AudioService] 文字起こし処理エラー: $e');
    }
  }
}
