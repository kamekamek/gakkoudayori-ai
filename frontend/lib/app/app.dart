import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as legacy;

import '../core/router/app_router.dart';
import '../core/router/demo_router.dart';
import '../core/theme/app_theme.dart';
import '../core/providers/error_provider.dart';
import '../features/ai_assistant/providers/adk_chat_provider.dart';
import '../features/auth/auth_provider.dart';
import '../features/editor/providers/image_provider.dart';
import '../features/editor/providers/preview_provider.dart';
import '../features/home/providers/newsletter_provider_v2.dart';
import '../services/user_settings_service.dart';
import '../services/adk_agent_service.dart';
import '../main.dart';

class GakkouDayoriAiApp extends ConsumerWidget {
  const GakkouDayoriAiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDemoMode = ref.watch(demoModeProvider);
    
    // デモモードの場合はFirebaseを使わない軽量版
    if (isDemoMode) {
      return MaterialApp.router(
        title: '学校だよりAI',
        theme: AppTheme.lightTheme,
        routerConfig: DemoRouter.router,
        debugShowCheckedModeBanner: false,
      );
    }

    // 通常モード：認証状態を監視し、変更があればGoRouterを再評価させる
    ref.watch(authStateChangesProvider);

    return legacy.MultiProvider(
      providers: [
        // Services
        legacy.Provider(create: (_) => AdkAgentService()),
        legacy.Provider(create: (_) => userSettingsService),

        // Error handling
        legacy.ChangeNotifierProvider(create: (_) => ErrorProvider()),

        // Providers
        legacy.ChangeNotifierProvider(
          create: (context) => AdkChatProvider(
            adkService: legacy.Provider.of<AdkAgentService>(context, listen: false),
            errorProvider: legacy.Provider.of<ErrorProvider>(context, listen: false),
            userId: 'user_12345', // This will be replaced with the actual user ID
          ),
        ),
        legacy.ChangeNotifierProvider(
          create: (context) => NewsletterProviderV2(
            adkAgentService: legacy.Provider.of<AdkAgentService>(context, listen: false),
            adkChatProvider: legacy.Provider.of<AdkChatProvider>(context, listen: false),
            userSettingsService: legacy.Provider.of<UserSettingsService>(context, listen: false),
          ),
        ),
        legacy.ChangeNotifierProvider(create: (_) => ImageManagementProvider()),
        legacy.ChangeNotifierProvider(
          create: (context) => PreviewProvider(
            errorProvider: legacy.Provider.of<ErrorProvider>(context, listen: false),
          ),
        ),
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
