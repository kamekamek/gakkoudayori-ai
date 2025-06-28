import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

// FirebaseAuthのインスタンスを提供するプロバイダ
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

// 認証状態の変更を監視するStreamProvider
final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

// GoogleSignInのインスタンスを提供するプロバイダ
final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  return GoogleSignIn(
    // 必要に応じてスコープを追加
    // scopes: [
    //   'email',
    //   'https://www.googleapis.com/auth/classroom.coursework.students',
    // ],
  );
});

// 認証ロジックをカプセル化するStateNotifierProvider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    ref.watch(firebaseAuthProvider),
    ref.watch(googleSignInProvider),
  );
});

class AuthService {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  AuthService(this._firebaseAuth, this._googleSignIn);

  // Googleでサインイン
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Googleサインインフローを開始
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // ユーザーがフローをキャンセルした場合
        return null;
      }

      // Googleユーザーから認証情報を取得
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Firebase用のクレデンシャルを作成
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Firebaseにサインイン
      final userCredential = await _firebaseAuth.signInWithCredential(credential);

      // バックエンドにユーザー情報を同期
      if (userCredential.user != null) {
        await _syncUserWithBackend();
      }

      return userCredential;
    } on FirebaseAuthException catch (e, s) {
      // Firebase関連のエラー処理
      debugPrint('Firebase Auth Exception: ${e.code} - ${e.message}');
      debugPrint('Stack trace: $s');
      return null;
    } catch (e, s) {
      // その他のエラー処理
      debugPrint('An unexpected error occurred during Google Sign-In: $e');
      debugPrint('Stack trace: $s');
      return null;
    }
  }

  // サインアウト
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    await _googleSignIn.signOut();
  }

  // 現��のユーザーを取得
  User? get currentUser => _firebaseAuth.currentUser;

  // IDトークンを取得
  Future<String?> getIdToken() async {
    final user = currentUser;
    if (user == null) return null;
    return await user.getIdToken();
  }

  Future<void> _syncUserWithBackend() async {
    final token = await getIdToken();
    if (token == null) return;

    try {
      final response = await http.get(
        // TODO: 環境変数からAPIベースURLを取得する
        Uri.parse('http://localhost:8082/api/v1/users/me'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        debugPrint('User synced with backend successfully.');
      } else {
        debugPrint('Failed to sync user with backend: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error syncing user with backend: $e');
    }
  }
}
