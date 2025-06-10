// E2Eテスト用のメインファイル
// Firebase依存関係を使用せずにアプリを起動します

import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // エラーハンドリングの設定
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };
  
  debugPrint('E2Eテスト用に最小限のアプリを起動します');
  
  // 最小限のアプリを実行
  runApp(E2ETestApp());
}

/// E2Eテスト用の最小限のアプリ
class E2ETestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '学校だよりAI',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomeScreen(),
    );
  }
}

/// シンプルなホーム画面
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('学校だよりAI - E2Eテスト'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'E2Eテスト用ホーム画面',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('ボタンがクリックされました')),
                );
              },
              child: Text('テストボタン'),
            ),
          ],
        ),
      ),
    );
  }
}
