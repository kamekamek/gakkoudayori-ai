import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/router/app_router.dart';
import '../features/home/providers/newsletter_provider.dart';
import '../features/ai_assistant/providers/chat_provider.dart';
import '../features/editor/providers/preview_provider.dart';
import '../features/editor/providers/image_provider.dart';

/// 学校だよりAIアプリのメインアプリケーション
class GakkouDayoriAiApp extends StatelessWidget {
  const GakkouDayoriAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 状態管理Providerの設定
        ChangeNotifierProvider(create: (_) => NewsletterProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => PreviewProvider()),
        ChangeNotifierProvider(create: (_) => ImageManagementProvider()),
      ],
      child: MaterialApp.router(
        title: '学校だよりAI',
        theme: AppTheme.lightTheme,
        routerConfig: AppRouter.router,
        debugShowCheckedModeBanner: false,
        // アクセシビリティ設定
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              // 文字サイズのアクセシビリティ対応
              textScaleFactor: MediaQuery.of(context).textScaleFactor.clamp(0.8, 1.2),
            ),
            child: child!,
          );
        },
      ),
    );
  }
}