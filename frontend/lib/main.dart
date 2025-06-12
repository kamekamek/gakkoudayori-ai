import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:yutori_kyoshitu/app/app.dart';
// import 'package:yutori_kyoshitu/core/services/firebase_service.dart'; // 一時的に無効化

/// アプリケーションのエントリーポイント
void main() async {
  // Flutterウィジェットバインディングの初期化
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase初期化（一旦無効化）
  /*
  if (kIsWeb) {
    await FirebaseService.initialize();
    
    // 自動匿名認証
    try {
      if (FirebaseService.isInitialized) {
        await FirebaseService.instance.signInAnonymously();
        debugPrint('main: 匿名認証完了');
      }
    } catch (e) {
      debugPrint('main: 匿名認証エラー - $e');
    }
  }
  */
  debugPrint('main: Firebase初期化をスキップ（テスト用）');

  // エラーハンドリングの設定
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    // 本番環境では、ここでエラーログをサーバーに送信するなどの処理を追加
  };

  // アプリケーションの実行
  runApp(YutoriKyoshituApp());
}
