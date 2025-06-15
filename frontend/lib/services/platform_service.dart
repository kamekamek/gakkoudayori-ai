import 'package:flutter/foundation.dart';

/// プラットフォーム判定サービス
/// Web版とMobile版で異なる機能を提供
class PlatformService {
  /// 現在のプラットフォームがWebかどうか
  static bool get isWeb => kIsWeb;

  /// 現在のプラットフォームがMobileかどうか
  static bool get isMobile => !kIsWeb;

  /// 現在のプラットフォームがiOSかどうか
  static bool get isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// 現在のプラットフォームがAndroidかどうか
  static bool get isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// プラットフォーム名を取得
  static String get platformName {
    if (isWeb) return 'Web';
    if (isIOS) return 'iOS';
    if (isAndroid) return 'Android';
    return 'Unknown';
  }

  /// WebViewが利用可能かどうか
  static bool get isWebViewAvailable {
    return !isWeb; // Webブラウザ以外でWebViewが利用可能
  }

  /// デバッグ情報を取得
  static Map<String, dynamic> get debugInfo {
    return {
      'isWeb': isWeb,
      'isMobile': isMobile,
      'isIOS': isIOS,
      'isAndroid': isAndroid,
      'platformName': platformName,
      'isWebViewAvailable': isWebViewAvailable,
      'kDebugMode': kDebugMode,
      'kReleaseMode': kReleaseMode,
      'kProfileMode': kProfileMode,
    };
  }

  /// プラットフォーム固有の設定を取得
  static Map<String, dynamic> get platformConfig {
    if (isWeb) {
      return {
        'editorType': 'html_widget',
        'audioRecording': 'web_audio_api',
        'fileUpload': 'web_file_picker',
        'allowInlineEdit': true,
      };
    } else {
      return {
        'editorType': 'inapp_webview',
        'audioRecording': 'native_recorder',
        'fileUpload': 'native_file_picker', 
        'allowInlineEdit': true,
      };
    }
  }
}