import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/services.dart';

/// アプリケーション全体の状態管理
class AppProvider extends ChangeNotifier {
  // アプリ設定
  bool _isDarkMode = false;
  String _language = 'ja';
  bool _isInitialized = false;
  
  // ユーザー情報
  String? _userId;
  String? _userEmail;
  String? _userName;
  
  // エラー状態
  String? _globalError;
  bool _hasNetworkConnection = true;

  // Getters
  bool get isDarkMode => _isDarkMode;
  String get language => _language;
  bool get isInitialized => _isInitialized;
  String? get userId => _userId;
  String? get userEmail => _userEmail;
  String? get userName => _userName;
  String? get globalError => _globalError;
  bool get hasNetworkConnection => _hasNetworkConnection;
  bool get isAuthenticated => _userId != null;

  /// アプリ初期化
  Future<void> initialize() async {
    try {
      // TODO: SharedPreferencesから設定を読み込み
      // TODO: Firebase認証状態をチェック
      // TODO: ネットワーク接続状態をチェック
      
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      _globalError = 'アプリの初期化に失敗しました: $e';
      notifyListeners();
    }
  }

  /// ダークモード切り替え
  void setDarkMode(bool isDark) {
    _isDarkMode = isDark;
    notifyListeners();
    // TODO: SharedPreferencesに保存
  }

  /// 言語設定
  void setLanguage(String lang) {
    _language = lang;
    notifyListeners();
    // TODO: SharedPreferencesに保存
  }

  /// ユーザー情報設定
  void setUser({
    required String? userId,
    String? email,
    String? name,
  }) {
    _userId = userId;
    _userEmail = email;
    _userName = name;
    notifyListeners();
  }

  /// ログアウト
  void logout() {
    _userId = null;
    _userEmail = null;
    _userName = null;
    notifyListeners();
  }

  /// グローバルエラー設定
  void setGlobalError(String? error) {
    _globalError = error;
    notifyListeners();
  }

  /// グローバルエラークリア
  void clearGlobalError() {
    _globalError = null;
    notifyListeners();
  }

  /// ネットワーク接続状態設定
  void setNetworkConnection(bool hasConnection) {
    _hasNetworkConnection = hasConnection;
    notifyListeners();
  }
}