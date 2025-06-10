import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yutori_kyoshitu/core/router/app_router.dart';

void main() {
  group('ルーティングテスト', () {
    late AppRouter router;

    setUp(() {
      router = AppRouter();
    });

    test('初期ルートが設定されていること', () {
      expect(router.routes['/'], isNotNull);
    });

    test('ホームルートが設定されていること', () {
      expect(router.routes['/home'], isNotNull);
    });

    test('存在しないルートの場合、NotFoundページが表示されること', () {
      final route = router.onGenerateRoute(
        RouteSettings(name: '/non-existent'),
      );
      expect(route, isNotNull);
      expect(route!.settings.name, '/not-found');
    });

    test('ルート間の遷移が正しく動作すること', () {
      final homeRoute = router.onGenerateRoute(
        RouteSettings(name: '/home'),
      );
      expect(homeRoute, isNotNull);
      expect(homeRoute!.settings.name, '/home');
    });
  });
}
