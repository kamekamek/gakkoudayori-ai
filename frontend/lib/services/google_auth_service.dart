import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Google認証サービス
///
/// Google Classroom APIアクセスに必要な認証機能を提供
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

  /// Google Sign-Inクライアントを初期化
  static void initialize() {
    _googleSignIn = GoogleSignIn(
      scopes: _scopes,
      // Web用の設定は firebase_options.dart で管理される
    );

    // Web環境での初期化（google_sign_in_web v0.12.4+では自動的に初期化される）
    if (kIsWeb) {
      // google_sign_in_web の最新版では明示的な登録は不要
      if (kDebugMode) {
        print('Web環境でのGoogle Sign-In初期化完了');
      }
    }
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
  static bool get isSignedIn => _currentUser != null;

  /// Google アカウントでログイン
  ///
  /// Returns: ログインに成功したユーザー情報、失敗時はnull
  static Future<GoogleSignInAccount?> signIn() async {
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
      await googleSignIn.signOut();
      await fb_auth.FirebaseAuth.instance.signOut();
      _currentUser = null;
      _authClient = null;

      if (kDebugMode) {
        print('Google Sign-Out 完了');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Google Sign-Out エラー: $e');
      }
      throw Exception('ログアウトに失敗しました: $e');
    }
  }

  /// アカウント接続を切断
  static Future<void> disconnect() async {
    try {
      await googleSignIn.disconnect();
      _currentUser = null;
      _authClient = null;

      if (kDebugMode) {
        print('Google アカウント接続切断完了');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Google アカウント接続切断エラー: $e');
      }
      throw Exception('アカウント接続の切断に失敗しました: $e');
    }
  }

  /// 認証済みHTTPクライアントを作成
  static Future<void> _createAuthClient() async {
    if (_currentUser == null) {
      throw Exception('ユーザーがログインしていません');
    }

    try {
      // アクセストークンを取得
      final authHeaders = await _currentUser!.authHeaders;

      // GoogleサインインからOAuth2認証情報を作成
      final accessToken =
          authHeaders['Authorization']?.replaceFirst('Bearer ', '');

      if (accessToken != null) {
        final credentials = auth.AccessCredentials(
          auth.AccessToken('Bearer', accessToken,
              DateTime.now().toUtc().add(const Duration(hours: 1))),
          null, // リフレッシュトークンは不要
          _scopes,
        );

        _authClient = auth.authenticatedClient(
          http.Client(),
          credentials,
        );

        if (kDebugMode) {
          print('認証済みHTTPクライアント作成完了');
        }
      } else {
        throw Exception('アクセストークンの取得に失敗しました');
      }
    } catch (e) {
      if (kDebugMode) {
        print('認証済みHTTPクライアント作成エラー: $e');
      }
      throw Exception('認証クライアントの作成に失敗しました: $e');
    }
  }

  /// トークンを更新
  static Future<void> refreshToken() async {
    if (_currentUser == null) {
      throw Exception('ユー��ーがログインしていません');
    }

    try {
      // トークンを再取得
      await _createAuthClient();

      if (kDebugMode) {
        print('トークン更新完了');
      }
    } catch (e) {
      if (kDebugMode) {
        print('トークン更新エラー: $e');
      }
      // トークン更新に失敗した場合は再ログインを促す
      await signOut();
      throw Exception('トークンの更新に失敗しました。再ログインが必要です: $e');
    }
  }

  /// 現在のユーザー情報を取得
  static Map<String, dynamic>? getUserInfo() {
    if (_currentUser == null) return null;

    return {
      'id': _currentUser!.id,
      'email': _currentUser!.email,
      'displayName': _currentUser!.displayName,
      'photoUrl': _currentUser!.photoUrl,
    };
  }

  /// 権限チェック
  ///
  /// [requiredScopes] チェックしたいスコープのリスト
  /// Returns: すべての権限が付与されている場合はtrue
  static bool hasPermissions(List<String> requiredScopes) {
    // 現在のスコープと要求されたスコープを比較
    for (final scope in requiredScopes) {
      if (!_scopes.contains(scope)) {
        return false;
      }
    }
    return isSignedIn;
  }

  /// Classroom関連の権限チェック
  static bool hasClassroomPermissions() {
    return hasPermissions([
      'https://www.googleapis.com/auth/classroom.courses.readonly',
      'https://www.googleapis.com/auth/classroom.announcements',
      'https://www.googleapis.com/auth/drive.file',
    ]);
  }

  /// 認証状態の文字列表現
  static String getAuthStatusText() {
    if (!isSignedIn) {
      return 'ログインしていません';
    }

    return 'ログイン済み: ${_currentUser!.email}';
  }

  /// 認証エラーハンドリング
  ///
  /// API呼び出し時の認証エラーを処理
  static Future<void> handleAuthError(dynamic error) async {
    if (kDebugMode) {
      print('認証エラーハンドリング: $error');
    }

    final errorString = error.toString();

    if (errorString.contains('401') || errorString.contains('unauthorized')) {
      // 認証エラーの場合はトークン更新を試行
      try {
        await refreshToken();
      } catch (e) {
        // トークン更新にも失敗した場合は再ログインが必要
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

