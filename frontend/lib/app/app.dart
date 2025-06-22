import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../core/router/app_router.dart';
import '../core/theme/app_theme.dart';
import '../features/ai_assistant/providers/adk_chat_provider.dart';
import '../features/editor/providers/image_provider.dart';
import '../features/editor/providers/preview_provider.dart';
import '../features/home/providers/newsletter_provider.dart';
import '../services/adk_agent_service.dart';

class GakkouDayoriAiApp extends StatelessWidget {
  const GakkouDayoriAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Services
        Provider(create: (_) => AdkAgentService()),

        // Providers
        ChangeNotifierProvider(
          create: (context) => AdkChatProvider(
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
        title: '学校だよりAI', // Fallback title
        theme: AppTheme.lightTheme,
        routerConfig: AppRouter.router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
