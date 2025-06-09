import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yutori_kyoshitu/core/router/app_router.dart';
import 'package:yutori_kyoshitu/core/theme/app_theme.dart';
import 'package:yutori_kyoshitu/core/services/firebase_service.dart';

/// 学校だよりAIのメインアプリケーションウィジェット
class YutoriKyoshituApp extends StatelessWidget {
  final AppRouter _router = AppRouter();

  YutoriKyoshituApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '学校だよりAI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      initialRoute: '/',
      onGenerateRoute: _router.onGenerateRoute,
      // Firebase初期化確認用
      builder: (context, child) {
        // Firebaseが初期化されているか確認
        final isFirebaseInitialized = FirebaseService.isInitialized;
        debugPrint('Firebase初期化状態: $isFirebaseInitialized');
        
        return child!;
      },
    );
  }
}
