import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gakkoudayori_ai/services/google_auth_service.dart';
import 'dart:html' as html;
import 'dart:ui' as ui;

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final String _viewTypeId = 'google-signin-button';

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      // ignore: undefined_prefixed_name
      ui.platformViewRegistry.registerViewFactory(
        _viewTypeId,
        (int viewId) => html.DivElement()
          ..id = 'g_id_signin'
          ..style.border = 'none',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ログイン状態を監視し、ログイン済みならすぐにGoogleボタンを描画
    // これにより、自動サインイン後の再描画がトリガーされる
    ref.watch(authStateChangesProvider);

    // ビルドの直後にGoogleボタンのレンダリングをトリガー
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (kIsWeb && mounted) {
        GoogleAuthService.googleSignIn.renderButton();
      }
    });

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
            kIsWeb
                ? _buildWebSignInButton()
                : _buildMobileSignInButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildWebSignInButton() {
    return SizedBox(
      height: 50,
      width: 240,
      child: HtmlElementView(viewType: _viewTypeId),
    );
  }

  Widget _buildMobileSignInButton() {
    return ElevatedButton.icon(
      icon: const Icon(Icons.login), // TODO: Googleアイコンに差し替え
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