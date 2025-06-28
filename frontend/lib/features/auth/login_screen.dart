import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gakkoudayori_ai/features/auth/auth_provider.dart';
import 'package:gakkoudayori_ai/services/google_auth_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  @override
  Widget build(BuildContext context) {
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
            _buildSignInButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSignInButton() {
    return ElevatedButton.icon(
      icon: const Icon(Icons.login),
      label: const Text('Googleでサインイン'),
      onPressed: () async {
        try {
          await GoogleAuthService.signIn();
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('ログインエラー: $e')),
            );
          }
        }
      },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: const TextStyle(fontSize: 16),
      ),
    );
  }
}