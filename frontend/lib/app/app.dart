import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yutori_kyoshitu/core/router/app_router.dart';
import 'package:yutori_kyoshitu/core/theme/app_theme.dart';
import 'package:yutori_kyoshitu/core/services/firebase_service.dart';
import 'package:yutori_kyoshitu/features/editor/providers/quill_editor_provider.dart';

/// 学校だよりAIのメインアプリケーションウィジェット
class YutoriKyoshituApp extends StatelessWidget {
  final AppRouter _router = AppRouter();

  YutoriKyoshituApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => QuillEditorProvider()),
      ],
      child: MaterialApp(
        title: '学校だよりAI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        themeMode: ThemeMode.light,
        initialRoute: '/home',
        onGenerateRoute: _router.onGenerateRoute,
        // Firebase初期化確認
        builder: (context, child) {
          if (!FirebaseService.isInitialized) {
            debugPrint('Firebase初期化待機中...');
          }
          return child!;
        },
      ),
    );
  }
}
