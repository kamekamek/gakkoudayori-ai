import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

class VoiceRecordingService {
  static final VoiceRecordingService _instance =
      VoiceRecordingService._internal();
  factory VoiceRecordingService() => _instance;
  VoiceRecordingService._internal();

  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  String? _currentRecordingPath;

  // 権限状態の変更を通知するストリーム
  final StreamController<PermissionStatus> _permissionController =
      StreamController<PermissionStatus>.broadcast();
  Stream<PermissionStatus> get permissionStream => _permissionController.stream;

  // 録音状態の変更を通知するストリーム
  final StreamController<bool> _recordingController =
      StreamController<bool>.broadcast();
  Stream<bool> get recordingStream => _recordingController.stream;

  // 音声レベルの変更を通知するストリーム
  final StreamController<double> _amplitudeController =
      StreamController<double>.broadcast();
  Stream<double> get amplitudeStream => _amplitudeController.stream;

  bool get isRecording => _isRecording;
  String? get currentRecordingPath => _currentRecordingPath;

  /// マイク権限をチェックする
  Future<PermissionStatus> checkMicrophonePermission() async {
    try {
      final status = await Permission.microphone.status;
      _permissionController.add(status);
      return status;
    } catch (e) {
      debugPrint('マイク権限チェックエラー: $e');
      _permissionController.add(PermissionStatus.denied);
      return PermissionStatus.denied;
    }
  }

  /// マイク権限をリクエストする
  Future<PermissionStatus> requestMicrophonePermission() async {
    try {
      final status = await Permission.microphone.request();
      _permissionController.add(status);
      return status;
    } catch (e) {
      debugPrint('マイク権限リクエストエラー: $e');
      _permissionController.add(PermissionStatus.denied);
      return PermissionStatus.denied;
    }
  }

  /// 権限が許可されているかチェック
  Future<bool> hasPermission() async {
    final status = await checkMicrophonePermission();
    return status == PermissionStatus.granted;
  }

  /// 録音を開始する
  Future<bool> startRecording({String? outputPath}) async {
    try {
      // 権限チェック
      if (!await hasPermission()) {
        final status = await requestMicrophonePermission();
        if (status != PermissionStatus.granted) {
          throw Exception('マイク権限が許可されていません');
        }
      }

      // 既に録音中の場合は停止
      if (_isRecording) {
        await stopRecording();
      }

      // 録音設定
      const config = RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
        numChannels: 1,
        autoGain: true,
        echoCancel: true,
        noiseSuppress: true,
      );

      // 出力パスの設定
      _currentRecordingPath = outputPath ?? await _generateRecordingPath();

      // 録音開始
      await _recorder.start(config, path: _currentRecordingPath!);
      _isRecording = true;
      _recordingController.add(true);

      // 音声レベル監視を開始
      _startAmplitudeMonitoring();

      debugPrint('録音開始: $_currentRecordingPath');
      return true;
    } catch (e) {
      debugPrint('録音開始エラー: $e');
      _isRecording = false;
      _recordingController.add(false);
      return false;
    }
  }

  /// 録音を停止する
  Future<String?> stopRecording() async {
    try {
      if (!_isRecording) {
        return null;
      }

      final path = await _recorder.stop();
      _isRecording = false;
      _recordingController.add(false);

      debugPrint('録音停止: $path');
      return path;
    } catch (e) {
      debugPrint('録音停止エラー: $e');
      _isRecording = false;
      _recordingController.add(false);
      return null;
    }
  }

  /// 録音をキャンセルする（ファイルを削除）
  Future<void> cancelRecording() async {
    try {
      await stopRecording();

      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
          debugPrint('録音ファイル削除: $_currentRecordingPath');
        }
      }

      _currentRecordingPath = null;
    } catch (e) {
      debugPrint('録音キャンセルエラー: $e');
    }
  }

  /// 音声レベル監視を開始
  void _startAmplitudeMonitoring() {
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!_isRecording) {
        timer.cancel();
        return;
      }

      _recorder.getAmplitude().then((amplitude) {
        // 振幅を0-1の範囲に正規化
        final normalizedAmplitude = amplitude.current.clamp(-50.0, 0.0) / -50.0;
        _amplitudeController.add(normalizedAmplitude);
      }).catchError((e) {
        debugPrint('音声レベル取得エラー: $e');
      });
    });
  }

  /// 録音ファイルのパスを生成
  Future<String> _generateRecordingPath() async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    if (kIsWeb) {
      // Web環境では一時的なパスを使用
      return 'recording_$timestamp.m4a';
    } else {
      // モバイル環境では一時ディレクトリを使用
      final directory = Directory.systemTemp;
      return '${directory.path}/recording_$timestamp.m4a';
    }
  }

  /// 権限設定画面を開く
  Future<void> openAppSettings() async {
    try {
      await Permission.microphone.request();
    } catch (e) {
      debugPrint('設定画面オープンエラー: $e');
    }
  }

  /// リソースを解放
  void dispose() {
    _recorder.dispose();
    _permissionController.close();
    _recordingController.close();
    _amplitudeController.close();
  }
}
