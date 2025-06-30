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
  static bool _isInitialized = false;

  /// Google Sign-Inクライアントを初期化し、認証状態の監視を開始します。
  /// このメソッドはアプリの起動時に一度だけ呼び出してください。
  static void initialize() {
    if (_isInitialized) {
      if (kDebugMode) {
        debugPrint('⚠️ GoogleAuthService: 既に初期化済みです');
      }
      return;
    }

    try {
      if (kDebugMode) {
        debugPrint('🔑 GoogleSignIn初期化開始...');
      }

      _googleSignIn = GoogleSignIn(
        scopes: _scopes,
      );

      if (kDebugMode) {
        debugPrint('🔑 GoogleSignInインスタンス作成完了');
      }

      _listenToAuthChanges(); // 認証監視を有効化
      _isInitialized = true;

      if (kDebugMode) {
        debugPrint('✅ GoogleAuthService: 初期化完了');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ GoogleAuthService: 初期化エラー: $e');
        debugPrint('❌ 一時的にGoogle Sign-Inなしで続行します');
      }
      _isInitialized = false;
      // エラーが発生してもアプリの起動は続行
    }
  }

  /// Googleの認証状態の変更を監視し、Firebaseの認証状態を同期させます。
  static void _listenToAuthChanges() {
    try {
      _googleSignIn?.onCurrentUserChanged
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
              print(
                  'Firebase Sign-In successful via listener: ${account.email}');
            }
          } catch (e) {
            if (kDebugMode) {
              print('Error during Firebase sign-in via listener: $e');
            }
            // エラーが発生した場合は、認証クライアントをクリアして状態をリセット
            _authClient = null;
            _currentUser = null;
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
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ 認証状態監視の設定でエラー: $e');
      }
    }
  }

  /// 現在のGoogle Sign-Inクライアントを取得
  static GoogleSignIn get googleSignIn {
    _googleSignIn ??= GoogleSignIn(scopes: _scopes);
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
      // Firebase からサインアウト
      if (fb_auth.FirebaseAuth.instance.currentUser != null) {
        await fb_auth.FirebaseAuth.instance.signOut();
        if (kDebugMode) {
          print('Firebase からサインアウトしました');
        }
      }

      // Google からサインアウト
      await googleSignIn.signOut();

      // 認証クライアントをクリア
      _authClient = null;
      _currentUser = null;

      if (kDebugMode) {
        print('Google からサインアウトしました');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Sign-Out エラー: $e');
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
      final user = _currentUser;
      if (user == null) {
        throw Exception('現在のユーザーが取得できません');
      }

      final authHeaders = await user.authHeaders;
      if (authHeaders.isEmpty) {
        throw Exception('認証ヘッダーが取得できません');
      }

      final authHeader = authHeaders['Authorization'];
      if (authHeader == null || authHeader.isEmpty) {
        throw Exception('Authorizationヘッダーが見つかりません');
      }

      final accessToken = authHeader.startsWith('Bearer ')
          ? authHeader.replaceFirst('Bearer ', '').trim()
          : authHeader.trim();

      if (accessToken.isNotEmpty) {
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
        throw Exception('アクセストークンが空です');
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
    // ユーザーがログインしており、認証クライアントが利用可能であるかチェック
    return _currentUser != null && _authClient != null;
  }

  static DateTime? _lastPermissionCheck;
  static bool _lastPermissionResult = false;

  /// Classroom権限を非同期で確認（キャッシュ付き）
  static Future<bool> verifyClassroomPermissions() async {
    if (!hasClassroomPermissions()) {
      return false;
    }

    // 5分以内の結果はキャッシュを使用
    final now = DateTime.now();
    if (_lastPermissionCheck != null &&
        now.difference(_lastPermissionCheck!).inMinutes < 5 &&
        _lastPermissionResult) {
      return _lastPermissionResult;
    }

    try {
      // 実際にClassroom APIにアクセスしてテスト
      final auth.AuthClient? client = _authClient;
      if (client == null) return false;

      final response = await http.get(
        Uri.parse('https://classroom.googleapis.com/v1/courses?pageSize=1'),
        headers: await _currentUser!.authHeaders,
      );

      _lastPermissionResult = response.statusCode == 200;
      _lastPermissionCheck = now;
      return _lastPermissionResult;
    } catch (e) {
      if (kDebugMode) {
        print('Classroom権限確認エラー: $e');
      }
      _lastPermissionResult = false;
      _lastPermissionCheck = now;
      return false;
    }
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
