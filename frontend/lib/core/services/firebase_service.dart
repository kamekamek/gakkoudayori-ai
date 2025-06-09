import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:yutori_kyoshitu/firebase_options.dart';

/// Firebaseサービスを管理するクラス
/// 
/// アプリケーション起動時に初期化する必要があります。
/// ```dart
/// await FirebaseService.initialize();
/// ```
class FirebaseService {
  // シングルトンインスタンス
  static FirebaseService? _instance;
  
  // Firebaseアプリインスタンス
  final FirebaseApp _firebaseApp;
  
  // 初期化フラグ
  static bool _initialized = false;
  
  // プライベートコンストラクタ
  FirebaseService._(this._firebaseApp);
  
  /// Firebaseを初期化する
  /// 
  /// アプリケーション起動時に一度だけ呼び出す必要があります。
  /// main.dart の中で呼び出すことを推奨します。
  static Future<void> initialize() async {
    if (_initialized) {
      debugPrint('FirebaseService: すでに初期化されています');
      return;
    }
    
    try {
      // Webプラットフォームの場合はオプションを指定して初期化
      final FirebaseApp app;
      if (kIsWeb) {
        app = await Firebase.initializeApp(
          options: DefaultFirebaseOptions.web,
        );
        debugPrint('FirebaseService: Webプラットフォーム用に初期化');
      } else {
        // ネイティブプラットフォームの場合は現在のプラットフォームに合わせて初期化
        app = await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        debugPrint('FirebaseService: ネイティブプラットフォーム用に初期化');
      }
      
      _instance = FirebaseService._(app);
      _initialized = true;
      debugPrint('FirebaseService: 初期化完了 - ${app.name}');
    } catch (e) {
      debugPrint('FirebaseService: 初期化エラー - $e');
      rethrow;
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
  
  /// FirebaseAppインスタンスを取得する
  FirebaseApp get app => _firebaseApp;
}
