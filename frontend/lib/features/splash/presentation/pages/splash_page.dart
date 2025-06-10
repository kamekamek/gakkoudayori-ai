import 'package:flutter/material.dart';

/// スプラッシュ画面
/// アプリ起動時に表示され、初期化処理を行う
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  /// 初期化処理後、ホーム画面に遷移
  Future<void> _navigateToHome() async {
    // 実際のアプリでは、ここで初期化処理を行う
    // - 設定の読み込み
    // - 認証状態の確認
    // - 必要なデータの事前読み込み など

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primaryContainer,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ロゴ表示（実際のアプリではアセット画像を使用）
              Icon(
                Icons.school,
                size: 80,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              const SizedBox(height: 24),
              Text(
                '学校だよりAI',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '音声入力で学級通信を自動生成',
                style: TextStyle(
                  fontSize: 16,
                  color:
                      Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 48),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
