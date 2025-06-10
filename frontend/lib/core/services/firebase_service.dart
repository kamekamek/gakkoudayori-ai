import 'package:flutter/foundation.dart';

/// Firebaseサービスを管理するクラス（Web専用）
///
/// アプリケーション起動時に初期化する必要があります。
/// ```dart
/// await FirebaseService.initialize();
/// ```
class FirebaseService {
  // シングルトンインスタンス
  static FirebaseService? _instance;

  // 初期化フラグ
  static bool _initialized = false;

  // プライベートコンストラクタ
  FirebaseService._();

  /// Firebaseを初期化する（Web専用モック実装）
  ///
  /// アプリケーション起動時に一度だけ呼び出す必要があります。
  /// main.dart の中で呼び出すことを推奨します。
  static Future<void> initialize() async {
    if (_initialized) {
      debugPrint('FirebaseService: すでに初期化されています');
      return;
    }

    try {
      // Web環境でのモック初期化
      debugPrint('FirebaseService: Web環境用にモック初期化開始');

      // モック初期化処理
      await Future.delayed(Duration(milliseconds: 100));

      _instance = FirebaseService._();
      _initialized = true;
      debugPrint('FirebaseService: モック初期化完了');
    } catch (e) {
      debugPrint('FirebaseService: 初期化エラー - $e');
      // エラーをスローせず、モック状態で続行
      _initialized = true;
      _instance = FirebaseService._();
      debugPrint('FirebaseService: フォールバックモック初期化完了');
    }
  }

  /// FirebaseServiceのインスタンスを取得する
  ///
  /// 初期化前にこのゲッターを呼び出すとエラーが発生します。
  static FirebaseService get instance {
    if (!_initialized) {
      throw StateError('FirebaseService: initialize()を先に呼び出してください');
    }
    return _instance!;
  }

  /// Firebaseが初期化されているかどうかを返す
  static bool get isInitialized => _initialized;

  /// Authentication関連のモック実装
  Future<bool> signInAnonymously() async {
    debugPrint('FirebaseService: 匿名サインイン（モック）');
    await Future.delayed(Duration(milliseconds: 200));
    return true;
  }

  /// データベース保存のモック実装
  Future<void> saveData(String collection, Map<String, dynamic> data) async {
    debugPrint('FirebaseService: データ保存（モック） - $collection: $data');
    await Future.delayed(Duration(milliseconds: 100));
  }

  /// ファイルアップロードのモック実装
  Future<String> uploadFile(String fileName, List<int> data) async {
    debugPrint('FirebaseService: ファイルアップロード（モック） - $fileName');
    await Future.delayed(Duration(milliseconds: 300));
    return 'mock://uploaded/$fileName';
  }
}
