import 'package:flutter_test/flutter_test.dart';
import 'package:yutori_kyoshitu/app/app.dart';
import 'package:yutori_kyoshitu/core/router/app_router.dart';
import 'package:yutori_kyoshitu/core/theme/app_theme.dart';
import 'package:yutori_kyoshitu/features/home/presentation/pages/home_page.dart';
import 'package:yutori_kyoshitu/features/splash/presentation/pages/splash_page.dart';

void main() {
  group('アプリ構造テスト', () {
    test('アプリが正しく初期化されること', () {
      final app = YutoriKyoshituApp();
      expect(app, isNotNull);
    });

    test('AppRouterが正しくルートを提供すること', () {
      final router = AppRouter();
      expect(router.routes, isNotEmpty);
      expect(router.routes.keys.contains('/'), isTrue);
      expect(router.routes.keys.contains('/home'), isTrue);
    });

    test('AppThemeが正しくテーマを提供すること', () {
      final theme = AppTheme.light();
      expect(theme, isNotNull);
      expect(theme.primaryColor, isNotNull);
    });

    test('SplashPageが存在すること', () {
      final splashPage = SplashPage();
      expect(splashPage, isNotNull);
    });

    test('HomePageが存在すること', () {
      final homePage = HomePage();
      expect(homePage, isNotNull);
    });
  });
}
