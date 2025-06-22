/// アプリケーション全体で使用する定数
class AppConstants {
  // API関連
  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const Duration apiTimeout = Duration(seconds: 30);
  
  // 画像関連
  static const List<String> supportedImageTypes = [
    'image/jpeg',
    'image/jpg', 
    'image/png',
    'image/gif',
    'image/webp',
  ];
  
  static const int maxImageSize = 10 * 1024 * 1024; // 10MB
  static const int maxImageCount = 10;
  
  // UI関連
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration debounceDelay = Duration(milliseconds: 500);
  
  // Classroom関連
  static const List<String> classroomScopes = [
    'https://www.googleapis.com/auth/classroom.courses.readonly',
    'https://www.googleapis.com/auth/classroom.announcements',
    'https://www.googleapis.com/auth/drive.file',
  ];
  
  // レスポンシブ関連
  static const double tabletBreakpoint = 768.0;
  static const double desktopBreakpoint = 1024.0;
}

/// テーマ色定数
class AppColors {
  static const primary = 0xFF2196F3;
  static const secondary = 0xFF03DAC6;
  static const error = 0xFFB00020;
  static const background = 0xFFFFFBFE;
  static const surface = 0xFFFFFBFE;
}

/// 文字列定数
class AppStrings {
  static const String appName = '学校だよりAI';
  static const String defaultTitle = '学級通信';
  static const String aiAssistantName = 'AIアシスタント';
  
  // エラーメッセージ
  static const String networkError = 'ネットワークエラーが発生しました';
  static const String unknownError = '予期しないエラーが発生しました';
  static const String fileUploadError = 'ファイルのアップロードに失敗しました';
}