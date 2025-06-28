import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:http/http.dart' as http;

/// Google認証サービス
///
/// Google Classroom APIアクセスに必要な認証機能と、Firebase Authenticationとの連携を提供します。
class GoogleAuthService {
  static const List<String> _scopes = [
    'https://www.googleapis.com/auth/classroom.courses.readonly',
    'https://www.googleapis.com/auth/classroom.announcements',
    'https://www.googleapis.com/auth/drive.file',
    'email',
    'profile',
  ];

  static GoogleSignIn? _googleSignIn;
  static GoogleSignInAccount? _currentUser;
  static auth.AuthClient? _authClient;

  /// Google Sign-Inクライアントを初期化し、認証状態の監視を開始します。
  /// このメソッドはアプリの起動時に一度だけ呼び出してください。
  static void initialize() {
    _googleSignIn = GoogleSignIn(scopes: _scopes);
    _listenToAuthChanges();
  }

  /// Googleの認証状態の変更を監視し、Firebaseの認証状��を同期させます。
  static void _listenToAuthChanges() {
    googleSignIn.onCurrentUserChanged
        .listen((GoogleSignInAccount? account) async {
      _currentUser = account;

      if (account != null) {
        try {
          final GoogleSignInAuthentication googleAuth =
              await account.authentication;
          final fb_auth.AuthCredential credential =
              fb_auth.GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );
          await fb_auth.FirebaseAuth.instance
              .signInWithCredential(credential);
          await _createAuthClient();
          if (kDebugMode) {
            print('Firebase Sign-In successful via listener: ${account.email}');
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error during Firebase sign-in via listener: $e');
          }
          signOut();
        }
      } else {
        if (fb_auth.FirebaseAuth.instance.currentUser != null) {
          await fb_auth.FirebaseAuth.instance.signOut();
          if (kDebugMode) {
            print('Firebase Sign-Out successful via listener.');
          }
        }
        _authClient = null;
      }
    });
  }

  /// 現在のGoogle Sign-Inクライアントを取得
  static dynamic get googleSignIn {
    if (_googleSignIn == null) {
      initialize();
    }
    return _googleSignIn!;
  }

  /// 現在のログインユーザー
  static GoogleSignInAccount? get currentUser => _currentUser;

  /// 認証済みHTTPクライアント
  static auth.AuthClient? get authClient => _authClient;

  /// ログイン状態の確認
  static bool get isSignedIn =>
      fb_auth.FirebaseAuth.instance.currentUser != null;

  /// Google アカウントでログイン
  static Future<void> signIn() async {
    try {
      await googleSignIn.signIn();
    } catch (e) {
      if (kDebugMode) {
        print('Google Sign-In エラー: $e');
      }
      throw Exception('Googleアカウントへのログインに失敗しました: $e');
    }
  }

  /// Google アカウントからログアウト
  static Future<void> signOut() async {
    try {
      await googleSignIn.signOut();
    } catch (e) {
      if (kDebugMode) {
        print('Google Sign-Out エラー: $e');
      }
      throw Exception('ログアウトに失敗しました: $e');
    }
  }

  /// 認証済みHTTPクライアントを作成
  static Future<void> _createAuthClient() async {
    if (_currentUser == null) {
      if (kDebugMode) {
        print('Cannot create auth client: Google user is null.');
      }
      return;
    }

    try {
      final authHeaders = await _currentUser!.authHeaders;
      final accessToken =
          authHeaders['Authorization']?.replaceFirst('Bearer ', '');

      if (accessToken != null) {
        final credentials = auth.AccessCredentials(
          auth.AccessToken('Bearer', accessToken,
              DateTime.now().toUtc().add(const Duration(hours: 1))),
          null,
          _scopes,
        );
        _authClient = auth.authenticatedClient(
          http.Client(),
          credentials,
        );
      } else {
        throw Exception('アクセストークンの取得に失敗しました');
      }
    } catch (e) {
      if (kDebugMode) {
        print('認証済みHTTPクライアント作成エラー: $e');
      }
      _authClient = null;
    }
  }

  /// トークンを更新
  static Future<void> refreshToken() async {
    if (_currentUser == null) {
      throw Exception('ユーザーがログインしていません');
    }
    try {
      await _createAuthClient();
      if (kDebugMode) {
        print('トークン更新完了');
      }
    } catch (e) {
      if (kDebugMode) {
        print('トークン更新エラー: $e');
      }
      await signOut();
      throw Exception('トークンの更新に失敗しました。再ログインが必要です: $e');
    }
  }

  /// Classroom関連の権限チェック
  static bool hasClassroomPermissions() {
    return _currentUser != null &&
        _scopes.contains('https://www.googleapis.com/auth/classroom.courses.readonly') &&
        _scopes.contains('https://www.googleapis.com/auth/classroom.announcements') &&
        _scopes.contains('https://www.googleapis.com/auth/drive.file');
  }

  /// 認証状態の文字列表現
  static String getAuthStatusText() {
    if (!isSignedIn) {
      return 'ログインしていません';
    }
    return 'ログイン済み: ${fb_auth.FirebaseAuth.instance.currentUser?.email ?? ''}';
  }

  /// 認証エラーハンドリング
  static Future<void> handleAuthError(dynamic error) async {
    if (kDebugMode) {
      print('認証エラーハンドリング: $error');
    }
    final errorString = error.toString();
    if (errorString.contains('401') || errorString.contains('unauthorized')) {
      try {
        await refreshToken();
      } catch (e) {
        throw Exception('認証エラー: 再ログインが必要です');
      }
    } else if (errorString.contains('403') ||
        errorString.contains('forbidden')) {
      throw Exception('権限エラー: 必要な権限が不足しています');
    } else {
      throw Exception('認証エラー: $error');
    }
  }
}