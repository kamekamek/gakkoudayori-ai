import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:yutori_kyoshitu/app/app.dart';
import 'package:yutori_kyoshitu/core/services/firebase_service.dart';
import 'package:yutori_kyoshitu/core/utils/firebase_web_patch.dart';

/// アプリケーションのエントリーポイント
void main() async {
  // Flutterウィジェットバインディングの初期化
  WidgetsFlutterBinding.ensureInitialized();
  
  // Web環境の場合はパッチを適用
  if (kIsWeb) {
    FirebaseWebPatch.applyPatches();
  }
  
  // エラーハンドリングの設定
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    // 本番環境では、ここでエラーログをサーバーに送信するなどの処理を追加
  };

  // E2Eテスト用に一時的にFirebase初期化をスキップ
  debugPrint('E2Eテスト用に一時的にFirebase初期化をスキップします');

  // アプリケーションの実行
  runApp(YutoriKyoshituApp());
}
