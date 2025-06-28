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
    _googleSignIn = GoogleSignIn(
      scopes: _scopes,
    );
    _listenToAuthChanges();
  }

  /// Googleの認証状態の変更を監視し、Firebaseの認証状態を同期させます。
  static void _listenToAuthChanges() {
    googleSignIn.onCurrentUserChanged
        .listen((GoogleSignInAccount? account) async {
      _currentUser = account;

      if (account != null) {
        // Googleアカウントでサインインした場合の処理
        try {
          final GoogleSignInAuthentication googleAuth =
              await account.authentication;
          final fb_auth.AuthCredential credential =
              fb_auth.GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );
          // Firebaseにサインイン
          await fb_auth.FirebaseAuth.instance
              .signInWithCredential(credential);
          // 認証済みHTTPクライアントを作成
          await _createAuthClient();
          if (kDebugMode) {
            print('Firebase Sign-In successful via listener: ${account.email}');
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error during Firebase sign-in via listener: $e');
          }
          // エラーが発生した場合は、不整合な状態を避けるためにサイン��ウトする
          signOut();
        }
      } else {
        // Googleアカウントからサインアウトした場合の処理
        // Firebaseからもサインアウトする
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
  static GoogleSignIn get googleSignIn {
    if (_googleSignIn == null) {
      // 初期化されていない場合はエラーを投げるか、再度初期化する
      // ここでは安全のために初期化を呼び出す
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

  /// Google アカウントでログイン（主にモバイルプラットフォーム用のフォールバック）
  static Future<void> signIn() async {
    try {
      await googleSignIn.signIn();
      // この後の処理は _listenToAuthChanges リスナーに任せる
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
      // Googleからサインアウトする。
      // これによりonCurrentUserChangedがnullイベントを発火し、
      // _listenToAuthChangesリスナーがFirebaseからのサインアウトを処理する。
      await googleSignIn.signOut();
      if (kDebugMode) {
        print('Google Sign-Out initiated.');
      }
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
}