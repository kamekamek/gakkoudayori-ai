import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:yutori_kyoshitu/app/app.dart';
import 'package:yutori_kyoshitu/core/services/firebase_service.dart';

/// アプリケーションのエントリーポイント
void main() async {
  // Flutterウィジェットバインディングの初期化
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase初期化
  if (kIsWeb) {
    await FirebaseService.initialize();
  }
  
  // エラーハンドリングの設定
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    // 本番環境では、ここでエラーログをサーバーに送信するなどの処理を追加
  };

  // アプリケーションの実行
  runApp(YutoriKyoshituApp());
}
