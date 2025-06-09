import 'package:flutter/material.dart';
import 'package:yutori_kyoshitu/app/app.dart';

/// アプリケーションのエントリーポイント
void main() {
  // Flutterウィジェットバインディングの初期化
  WidgetsFlutterBinding.ensureInitialized();
  
  // エラーハンドリングの設定
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    // 本番環境では、ここでエラーログをサーバーに送信するなどの処理を追加
  };

  // アプリケーションの実行
  runApp(YutoriKyoshituApp());
}
