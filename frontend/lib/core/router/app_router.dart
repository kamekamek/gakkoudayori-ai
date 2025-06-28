import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gakkoudayori_ai/features/auth/login_screen.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/newsletter/presentation/pages/newsletter_page.dart';

/// アプリケーションのルーティング設定
class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    refreshListenable:
        GoRouterRefreshStream(FirebaseAuth.instance.authStateChanges()),
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/newsletter',
        name: 'newsletter',
        builder: (context, state) => const NewsletterPage(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      // このリダイレクトロジックを機能させるには、MaterialApp.routerの上位に
      // ProviderScopeが存在し、authStateChangesProviderが利用可能である必要がある。
      // main.dartでProviderScopeがGakkouDayoriAiAppをラップしているため、
      // ここでref.watchを使うには、GoRouterのインスタンスをProviderにする必要がある。
      // 今回は、よりシンプルなアプローチとして、リダイレクト内でFirebaseAuthのインスタンスを直接使用する。
      // よりクリーンな方法は、ルーター自体をProviderにすること。
      final loggedIn = FirebaseAuth.instance.currentUser != null;
      final loggingIn = state.matchedLocation == '/login';

      if (!loggedIn) {
        // ログインしていない場合、ログインページにリダイレクト
        return loggingIn ? null : '/login';
      }

      if (loggingIn) {
        // ログインしている状態でログインページにアクセスしようとした場合、ホームにリダイレクト
        return '/';
      }

      return null; // リダイレクトなし
    },
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(
        title: const Text('エラー'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'ページが見つかりません',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.error?.toString() ?? '不明なエラーが発生しました',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go('/'),
              icon: const Icon(Icons.home),
              label: const Text('ホームに戻る'),
            ),
          ],
        ),
      ),
    ),
  );
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (dynamic _) => notifyListeners(),
        );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

