import 'package:flutter/material.dart';
import 'package:yutori_kyoshitu/app/app.dart';
import 'package:yutori_kyoshitu/core/services/firebase_service.dart';

/// アプリケーションのエントリーポイント
void main() async {
  // Flutterウィジェットバインディングの初期化
  WidgetsFlutterBinding.ensureInitialized();
  
  // エラーハンドリングの設定
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    // 本番環境では、ここでエラーログをサーバーに送信するなどの処理を追加
  };

  // Firebase初期化
  try {
    await FirebaseService.initialize();
    debugPrint('Firebase初期化成功');
  } catch (e) {
    debugPrint('Firebase初期化エラー: $e');
    // エラーハンドリング（必要に応じて）
  }

  // アプリケーションの実行
  runApp(YutoriKyoshituApp());
}
