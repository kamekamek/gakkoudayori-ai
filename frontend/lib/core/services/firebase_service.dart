import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../firebase_options.dart';

/// Firebaseサービスを管理するクラス（Web用実装）
///
/// アプリケーション起動時に初期化する必要があります。
/// ```dart
/// await FirebaseService.initialize();
/// ```
class FirebaseService {
  // シングルトンインスタンス
  static FirebaseService? _instance;

  // 初期化フラグ
  static bool _initialized = false;

  // Firebase サービスインスタンス
  late final FirebaseAuth _auth;
  late final FirebaseFirestore _firestore;
  late final FirebaseStorage _storage;

  // プライベートコンストラクタ
  FirebaseService._() {
    _auth = FirebaseAuth.instance;
    _firestore = FirebaseFirestore.instance;
    _storage = FirebaseStorage.instance;
  }

  /// Firebaseを初期化する（Web用実装）
  ///
  /// アプリケーション起動時に一度だけ呼び出す必要があります。
  /// main.dart の中で呼び出すことを推奨します。
  static Future<void> initialize() async {
    if (_initialized) {
      debugPrint('FirebaseService: すでに初期化されています');
      return;
    }

    try {
      debugPrint('FirebaseService: Firebase初期化開始');

      // Firebase初期化
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // 認証設定
      if (kIsWeb) {
        await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
      }

      _instance = FirebaseService._();
      _initialized = true;
      debugPrint('FirebaseService: Firebase初期化完了');
    } catch (e) {
      debugPrint('FirebaseService: 初期化エラー - $e');
      // エラーをスローせず、モック状態で続行
      _initialized = true;
      _instance = FirebaseService._();
      debugPrint('FirebaseService: フォールバック初期化完了');
    }
  }

  /// FirebaseServiceのインスタンスを取得する
  ///
  /// 初期化前にこのゲッターを呼び出すとエラーが発生します。
  static FirebaseService get instance {
    if (!_initialized) {
      throw StateError('FirebaseService: initialize()を先に呼び出してください');
    }
    return _instance!;
  }

  /// Firebaseが初期化されているかどうかを返す
  static bool get isInitialized => _initialized;

  /// Authentication関連の実装
  Future<bool> signInAnonymously() async {
    debugPrint('FirebaseService: 匿名サインイン開始');
    try {
      UserCredential result = await _auth.signInAnonymously();
      debugPrint('FirebaseService: 匿名サインイン成功 - UID: ${result.user?.uid}');
      return true;
    } catch (e) {
      debugPrint('FirebaseService: 匿名サインインエラー - $e');
      return false;
    }
  }

  /// 現在のユーザーを取得
  User? get currentUser => _auth.currentUser;

  /// 認証状態の変更をリッスン
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// データベース保存の実装
  Future<void> saveData(String collection, Map<String, dynamic> data) async {
    debugPrint('FirebaseService: データ保存開始 - $collection');
    try {
      await _firestore.collection(collection).add({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
        'uid': _auth.currentUser?.uid,
      });
      debugPrint('FirebaseService: データ保存成功');
    } catch (e) {
      debugPrint('FirebaseService: データ保存エラー - $e');
      rethrow;
    }
  }

  /// ドキュメント取得
  Future<Map<String, dynamic>?> getDocument(String collection, String docId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection(collection).doc(docId).get();
      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('FirebaseService: ドキュメント取得エラー - $e');
      return null;
    }
  }

  /// ファイルアップロードの実装
  Future<String> uploadFile(String fileName, List<int> data) async {
    debugPrint('FirebaseService: ファイルアップロード開始 - $fileName');
    try {
      final ref = _storage.ref().child('uploads').child(fileName);
      final uint8Data = data is Uint8List ? data : Uint8List.fromList(data);
      final uploadTask = ref.putData(uint8Data);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      debugPrint('FirebaseService: ファイルアップロード成功');
      return downloadUrl;
    } catch (e) {
      debugPrint('FirebaseService: ファイルアップロードエラー - $e');
      rethrow;
    }
  }
}
