import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
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
  static GoogleSignIn get googleSignIn {
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
      if (kDebugMode) {
        print('Google Sign-In 開始');
      }

      // サイレントサインイン試行
      _currentUser = await googleSignIn.signInSilently();

      // 明示的サインインが必要な場合
      if (_currentUser == null) {
        // Web環境では新しいAPI使用を推奨、但し既存実装との互換性を保つ
        if (kIsWeb) {
          // ポップアップブロッカー対策としてユーザーアクション内で実行
          _currentUser = await googleSignIn.signIn();
        } else {
          _currentUser = await googleSignIn.signIn();
        }
      }

      if (_currentUser != null) {
        final GoogleSignInAuthentication googleAuth =
            await _currentUser!.authentication;
        final fb_auth.AuthCredential credential =
            fb_auth.GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await fb_auth.FirebaseAuth.instance.signInWithCredential(credential);
        // 認証済みHTTPクライアントを作成
        await _createAuthClient();

        if (kDebugMode) {
          print('Google Sign-In 成功: ${_currentUser!.email}');
          print('付与されたスコープ: ${_scopes.join(', ')}');
        }
      }

      return _currentUser;
    } catch (e) {
      if (kDebugMode) {
        print('Google Sign-In エラー: $e');
      }

      // Web特有のエラーハンドリング
      if (e.toString().contains('popup_closed')) {
        throw Exception('サインインがキャンセルされました。もう一度お試しください。');
      } else if (e.toString().contains('popup_blocked')) {
        throw Exception('ポップアップがブロックされました。ブラウザの設���をご確認ください。');
      }

      throw Exception('Googleアカウントへのログインに失敗しました: $e');
    }
  }

  /// Google アカウントからログアウト
  static Future<void> signOut() async {
    try {
      // FirebaseとGoogleの両方からサインアウトする
      await fb_auth.FirebaseAuth.instance.signOut();
      await googleSignIn.signOut();
      await fb_auth.FirebaseAuth.instance.signOut();
      _currentUser = null;
      _authClient = null;
      if (kDebugMode) {
        print('Sign-Out successful from both Firebase and Google.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Sign-Out エラー: $e');
      }
      // エラーが発生しても、状態をクリアする試み
      _currentUser = null;
      _authClient = null;
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
      throw Exception('ユー��ーがログインしていません');
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

  /// 認証状態リスナーの設定
  ///
  /// [onSignedIn] ログイン時のコールバック
  /// [onSignedOut] ログアウト時のコールバック
  static void setAuthStateListener({
    required Function(GoogleSignInAccount) onSignedIn,
    required Function() onSignedOut,
  }) {
    googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
      _currentUser = account;

      if (account != null) {
        _createAuthClient().then((_) {
          onSignedIn(account);
        }).catchError((e) {
          if (kDebugMode) {
            print('認証状態リスナーエラー: $e');
          }
        });
      } else {
        _authClient = null;
        onSignedOut();
      }
    });
  }

  /// 初期認証状態の復元
  ///
  /// アプリ起動時に前回のログイン状態を復元
  static Future<void> restoreAuthState() async {
    try {
      _currentUser = await googleSignIn.signInSilently();

      if (_currentUser != null) {
        await _createAuthClient();

        if (kDebugMode) {
          print('認証状態復元完了: ${_currentUser!.email}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('認証状態復元エラー: $e');
      }
      // エラーが発生した場合はサイレントに失敗させる
      _currentUser = null;
      _authClient = null;
    }
  }
}

