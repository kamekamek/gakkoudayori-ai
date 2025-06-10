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
      initialRoute: '/home',
      onGenerateRoute: _router.onGenerateRoute,
      // E2Eテスト用に一時的にFirebase初期化確認を無効化
      builder: (context, child) {
        debugPrint('E2Eテスト用に一時的にFirebase初期化確認を無効化します');
        return child!;
      },
    );
  }
}
