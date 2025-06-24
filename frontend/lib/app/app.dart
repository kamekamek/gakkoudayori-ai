import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/router/app_router.dart';
import '../core/theme/app_theme.dart';
import '../features/ai_assistant/providers/adk_chat_provider.dart';
import '../features/editor/providers/image_provider.dart';
import '../features/editor/providers/preview_provider.dart';
import '../features/home/providers/newsletter_provider.dart';
import '../services/adk_agent_service.dart';
import '../services/adk_agent_service_mock.dart';

class GakkouDayoriAiApp extends StatelessWidget {
  final bool isDemo;
  
  const GakkouDayoriAiApp({
    super.key,
    this.isDemo = false,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Services（デモモードに応じて切り替え）
        Provider<AdkAgentService>(
          create: (_) => isDemo ? AdkAgentServiceMock() : AdkAgentService(),
        ),

        // Providers（デモモードに応じて設定）
        ChangeNotifierProvider(
          create: (context) => isDemo
            ? AdkChatProvider.demo(userId: 'demo_user_12345')
            : AdkChatProvider(
                adkService: context.read<AdkAgentService>(),
                userId: 'user_12345',
              ),
        ),
        ChangeNotifierProvider(
          create: (context) => NewsletterProvider(
            adkAgentService: context.read<AdkAgentService>(),
            adkChatProvider: context.read<AdkChatProvider>(),
          ),
        ),
        ChangeNotifierProvider(create: (_) => ImageManagementProvider()),
        ChangeNotifierProvider(create: (_) => PreviewProvider()),
      ],
      child: MaterialApp.router(
        title: '学校だよりAI',
        theme: AppTheme.lightTheme,
        routerConfig: AppRouter.router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
