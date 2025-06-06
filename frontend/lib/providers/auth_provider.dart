import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
      'https://www.googleapis.com/auth/drive.file',
      'https://www.googleapis.com/auth/classroom.courses',
      'https://www.googleapis.com/auth/classroom.rosters',
    ],
  );

  late final StreamSubscription<User?> _authSubscription;
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    // Firebase Auth の状態変化を監視
    _authSubscription = _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
    
    // 初期化時に現在のユーザーを取得
    _user = _auth.currentUser;
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  /// Google Sign-In でサインイン
  Future<bool> signInWithGoogle() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Google Sign-In フロー
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // ユーザーがサインインをキャンセル
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Google認証情報を取得
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Firebase認証用のクレデンシャルを作成
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Firebaseにサインイン
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      _user = userCredential.user;

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'サインインに失敗しました: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// メールアドレスとパスワードでサインイン
  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _user = userCredential.user;

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = _getErrorMessage(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'サインインに失敗しました: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// メールアドレスとパスワードでアカウント作成
  Future<bool> createUserWithEmailAndPassword(String email, String password, String displayName) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // 表示名を設定
      await userCredential.user?.updateDisplayName(displayName);
      _user = userCredential.user;

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = _getErrorMessage(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'アカウント作成に失敗しました: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// サインアウト
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      _user = null;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'サインアウトに失敗しました: ${e.toString()}';
      notifyListeners();
    }
  }

  /// パスワードリセットメール送信
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _auth.sendPasswordResetEmail(email: email);

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = _getErrorMessage(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'パスワードリセットメールの送信に失敗しました: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// IDトークンを取得（バックエンドAPI認証用）
  Future<String?> getIdToken() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        return await currentUser.getIdToken();
      }
      return null;
    } catch (e) {
      debugPrint('IDトークン取得エラー: $e');
      return null;
    }
  }

  /// Google Access Tokenを取得（Google API使用用）
  Future<String?> getGoogleAccessToken() async {
    try {
      final GoogleSignInAccount? googleUser = _googleSignIn.currentUser;
      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        return googleAuth.accessToken;
      }
      return null;
    } catch (e) {
      debugPrint('Google Access Token取得エラー: $e');
      return null;
    }
  }

  /// エラーコードを日本語メッセージに変換
  String _getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'このメールアドレスのアカウントが見つかりません。';
      case 'wrong-password':
        return 'パスワードが間違っています。';
      case 'email-already-in-use':
        return 'このメールアドレスは既に使用されています。';
      case 'weak-password':
        return 'パスワードが弱すぎます。6文字以上で設定してください。';
      case 'invalid-email':
        return 'メールアドレスの形式が正しくありません。';
      case 'operation-not-allowed':
        return 'この操作は許可されていません。';
      case 'user-disabled':
        return 'このアカウントは無効になっています。';
      case 'too-many-requests':
        return 'リクエストが多すぎます。しばらく待ってから再試行してください。';
      default:
        return '認証エラーが発生しました: $errorCode';
    }
  }

  /// エラーメッセージをクリア
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
} 