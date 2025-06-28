import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gakkoudayori_ai/features/auth/auth_provider.dart';
import 'package:gakkoudayori_ai/services/google_auth_service.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 認証状態を監視し、変更があればGoRouterが自動的にリダイレクトする
    ref.watch(authStateChangesProvider);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '学校だよりAIへようこそ',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 40),
            // プラットフォームに応じて適切なボタンを表示
            _buildSignInButton(),
          ],
        ),
      ),
    );
  }

  /// サインインボタン
  Widget _buildSignInButton() {
    return ElevatedButton.icon(
      icon: const Icon(Icons.login),
      label: const Text('Googleでサインイン'),
      onPressed: () async {
        await GoogleAuthService.signIn();
      },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: const TextStyle(fontSize: 16),
      ),
    );
  }
}