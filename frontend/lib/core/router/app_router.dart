import 'package:flutter/material.dart';
import 'package:yutori_kyoshitu/features/home/presentation/pages/home_page.dart';
import 'package:yutori_kyoshitu/features/layout/presentation/pages/main_layout_page.dart';
import 'package:yutori_kyoshitu/features/splash/presentation/pages/splash_page.dart';

/// アプリケーションのルーティングを管理するクラス
class AppRouter {
  /// 利用可能なルートのマップ
  final Map<String, WidgetBuilder> routes = {
    '/': (context) => const SplashPage(),
    '/home': (context) => const MainLayoutPage(), // メインレイアウトページを使用
    '/legacy-home': (context) => const HomePage(), // 古い実装はlegacyとしてアクセス可能に
    '/not-found': (context) => const _NotFoundPage(),
  };

  /// ルート生成ハンドラ
  Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final builder = routes[settings.name];
    
    if (builder != null) {
      return MaterialPageRoute(
        builder: builder,
        settings: settings,
      );
    }
    
    // 存在しないルートの場合は404ページを表示
    return MaterialPageRoute(
      builder: routes['/not-found']!,
      settings: RouteSettings(name: '/not-found'),
    );
  }
}

/// 404ページ
class _NotFoundPage extends StatelessWidget {
  const _NotFoundPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ページが見つかりません'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'お探しのページが見つかりませんでした',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pushReplacementNamed('/home'),
              child: const Text('ホームに戻る'),
            ),
          ],
        ),
      ),
    );
  }
}
