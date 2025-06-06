import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'screens/dashboard_screen.dart';
import 'screens/editor_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/documents_screen.dart';
import 'providers/app_state.dart';
import 'theme/app_theme.dart';

class YutoriKyoshitsuApp extends StatelessWidget {
  const YutoriKyoshitsuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
      ],
      child: Consumer<AppState>(
        builder: (context, appState, child) {
          return MaterialApp.router(
            title: 'ゆとり職員室',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: appState.themeMode,
            routerConfig: _router,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/editor',
      builder: (context, state) => const EditorScreen(),
    ),
    GoRoute(
      path: '/editor/:id',
      builder: (context, state) {
        final documentId = state.pathParameters['id']!;
        return EditorScreen(documentId: documentId);
      },
    ),
    GoRoute(
      path: '/documents',
      builder: (context, state) => const DocumentsScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
