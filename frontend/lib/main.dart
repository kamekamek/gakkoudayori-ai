import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'firebase_options.dart';
import 'providers/auth_provider.dart' as auth;
import 'providers/app_state.dart';
import 'services/api_service.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/editor_screen.dart';
import 'screens/settings_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase初期化
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const YutoriKyoshitsuApp());
}

class YutoriKyoshitsuApp extends StatelessWidget {
  const YutoriKyoshitsuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => auth.AuthProvider()),
        ChangeNotifierProvider(create: (_) => AppState()),
        ProxyProvider<auth.AuthProvider, ApiService>(
          update: (_, authProvider, __) => ApiService(authProvider),
        ),
      ],
      child: Consumer<auth.AuthProvider>(
        builder: (context, authProvider, _) {
          return MaterialApp.router(
            title: 'ゆとり職員室',
            theme: AppTheme.lightTheme,
            routerConfig: _createRouter(authProvider),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }

  GoRouter _createRouter(auth.AuthProvider authProvider) {
    return GoRouter(
      initialLocation: '/',
      redirect: (context, state) {
        // 🚧 開発用：認証を一時的にスキップ
        // TODO: 認証機能が完成したら以下のコメントアウトを解除
        /*
        final isLoggedIn = authProvider.isAuthenticated;
        final isLoginRoute = state.fullPath == '/login';

        if (!isLoggedIn && !isLoginRoute) {
          return '/login';
        }
        if (isLoggedIn && isLoginRoute) {
          return '/';
        }
        */
        return null; // 認証チェックをスキップ
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/editor',
          builder: (context, state) => const EditorScreen(),
        ),
        GoRoute(
          path: '/editor/:documentId',
          builder: (context, state) {
            final documentId = state.pathParameters['documentId']!;
            return EditorScreen(documentId: documentId);
          },
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    );
  }
}
