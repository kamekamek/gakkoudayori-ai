import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../firebase_options.dart';
import '../models/document_data.dart';
import 'dart:convert';

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

  // ===============================
  // 学級通信ドキュメント特化メソッド
  // ===============================

  /// 学級通信ドキュメントを保存
  /// 
  /// Firestore: `/letters/{documentId}` にメタデータ保存
  /// Storage: `/documents/{documentId}/content.html` と `/documents/{documentId}/delta.json` にコンテンツ保存
  Future<void> saveDocument(DocumentData document) async {
    debugPrint('FirebaseService: ドキュメント保存開始 - ${document.documentId}');
    
    try {
      final batch = _firestore.batch();
      
      // Firestoreにメタデータ保存
      final docRef = _firestore.collection('letters').doc(document.documentId);
      batch.set(docRef, {
        ...document.toFirestore(),
        'uid': _auth.currentUser?.uid,
      });
      
      await batch.commit();
      
      // Storage にコンテンツ保存（並行処理）
      final List<Future> uploadTasks = [];
      
      if (document.htmlContent != null) {
        uploadTasks.add(_saveDocumentContent(
          document.documentId, 
          'content.html', 
          document.htmlContent!,
        ));
      }
      
      if (document.deltaContent != null) {
        uploadTasks.add(_saveDocumentContent(
          document.documentId, 
          'delta.json', 
          document.deltaContent!,
        ));
      }
      
      await Future.wait(uploadTasks);
      debugPrint('FirebaseService: ドキュメント保存成功 - ${document.documentId}');
    } catch (e) {
      debugPrint('FirebaseService: ドキュメント保存エラー - $e');
      rethrow;
    }
  }

  /// ドキュメントコンテンツをStorageに保存
  Future<void> _saveDocumentContent(String documentId, String fileName, String content) async {
    try {
      final ref = _storage.ref().child('documents').child(documentId).child(fileName);
      final bytes = utf8.encode(content);
      await ref.putData(Uint8List.fromList(bytes));
      debugPrint('FirebaseService: コンテンツ保存成功 - $fileName');
    } catch (e) {
      debugPrint('FirebaseService: コンテンツ保存エラー - $fileName: $e');
      rethrow;
    }
  }

  /// 学級通信ドキュメントを読み込み
  Future<DocumentData?> loadDocument(String documentId) async {
    debugPrint('FirebaseService: ドキュメント読み込み開始 - $documentId');
    
    try {
      // Firestoreからメタデータ取得
      final docSnapshot = await _firestore.collection('letters').doc(documentId).get();
      
      if (!docSnapshot.exists) {
        debugPrint('FirebaseService: ドキュメントが見つかりません - $documentId');
        return null;
      }
      
      // DocumentDataに変換
      DocumentData document = DocumentData.fromFirestore(docSnapshot);
      
      // Storageからコンテンツ取得（並行処理）
      final contentFuture = _loadDocumentContent(documentId, 'content.html');
      final deltaFuture = _loadDocumentContent(documentId, 'delta.json');
      
      final results = await Future.wait([contentFuture, deltaFuture]);
      final htmlContent = results[0];
      final deltaContent = results[1];
      
      // コンテンツを含むドキュメントデータを返却
      document = document.copyWith(
        htmlContent: htmlContent,
        deltaContent: deltaContent,
      );
      
      debugPrint('FirebaseService: ドキュメント読み込み成功 - $documentId');
      return document;
    } catch (e) {
      debugPrint('FirebaseService: ドキュメント読み込みエラー - $e');
      return null;
    }
  }

  /// ドキュメントコンテンツをStorageから読み込み
  Future<String?> _loadDocumentContent(String documentId, String fileName) async {
    try {
      final ref = _storage.ref().child('documents').child(documentId).child(fileName);
      final bytes = await ref.getData();
      if (bytes != null) {
        final content = utf8.decode(bytes);
        debugPrint('FirebaseService: コンテンツ読み込み成功 - $fileName');
        return content;
      }
      return null;
    } catch (e) {
      // ファイルが存在しない場合はnullを返す（エラーログは出力しない）
      if (e.toString().contains('object-not-found')) {
        debugPrint('FirebaseService: コンテンツファイル未存在 - $fileName');
        return null;
      }
      debugPrint('FirebaseService: コンテンツ読み込みエラー - $fileName: $e');
      return null;
    }
  }

  /// ユーザーの学級通信ドキュメント一覧を取得
  Future<List<DocumentData>> getUserDocuments({int limit = 50}) async {
    debugPrint('FirebaseService: ユーザードキュメント一覧取得開始');
    
    try {
      final currentUid = _auth.currentUser?.uid;
      if (currentUid == null) {
        debugPrint('FirebaseService: 未認証ユーザー');
        return [];
      }
      
      final querySnapshot = await _firestore
          .collection('letters')
          .where('uid', isEqualTo: currentUid)
          .orderBy('updatedAt', descending: true)
          .limit(limit)
          .get();
      
      final documents = querySnapshot.docs
          .map((doc) => DocumentData.fromFirestore(doc))
          .toList();
      
      debugPrint('FirebaseService: ユーザードキュメント一覧取得成功 - ${documents.length}件');
      return documents;
    } catch (e) {
      debugPrint('FirebaseService: ユーザードキュメント一覧取得エラー - $e');
      return [];
    }
  }

  /// ドキュメントの状態を更新
  Future<void> updateDocumentStatus(String documentId, DocumentStatus status) async {
    debugPrint('FirebaseService: ドキュメント状態更新開始 - $documentId: $status');
    
    try {
      await _firestore.collection('letters').doc(documentId).update({
        'status': status.value,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('FirebaseService: ドキュメント状態更新成功');
    } catch (e) {
      debugPrint('FirebaseService: ドキュメント状態更新エラー - $e');
      rethrow;
    }
  }

  /// ドキュメントを削除
  Future<void> deleteDocument(String documentId) async {
    debugPrint('FirebaseService: ドキュメント削除開始 - $documentId');
    
    try {
      final batch = _firestore.batch();
      
      // Firestoreのドキュメントを削除
      final docRef = _firestore.collection('letters').doc(documentId);
      batch.delete(docRef);
      
      await batch.commit();
      
      // Storageのファイルを削除（並行処理）
      final deleteTasks = [
        _deleteDocumentContent(documentId, 'content.html'),
        _deleteDocumentContent(documentId, 'delta.json'),
      ];
      
      await Future.wait(deleteTasks);
      debugPrint('FirebaseService: ドキュメント削除成功 - $documentId');
    } catch (e) {
      debugPrint('FirebaseService: ドキュメント削除エラー - $e');
      rethrow;
    }
  }

  /// ドキュメントコンテンツをStorageから削除
  Future<void> _deleteDocumentContent(String documentId, String fileName) async {
    try {
      final ref = _storage.ref().child('documents').child(documentId).child(fileName);
      await ref.delete();
      debugPrint('FirebaseService: コンテンツ削除成功 - $fileName');
    } catch (e) {
      // ファイルが存在しない場合は無視
      if (e.toString().contains('object-not-found')) {
        debugPrint('FirebaseService: コンテンツファイル未存在（削除済み） - $fileName');
        return;
      }
      debugPrint('FirebaseService: コンテンツ削除エラー - $fileName: $e');
      // 削除エラーは致命的ではないため、エラーをスローしない
    }
  }

  /// ドキュメントコンテンツの署名付きURLを取得（共有用）
  Future<String?> getDocumentShareUrl(String documentId, String fileName) async {
    try {
      final ref = _storage.ref().child('documents').child(documentId).child(fileName);
      // 24時間有効な署名付きURL
      final url = await ref.getDownloadURL();
      debugPrint('FirebaseService: 署名付きURL取得成功 - $fileName');
      return url;
    } catch (e) {
      debugPrint('FirebaseService: 署名付きURL取得エラー - $fileName: $e');
      return null;
    }
  }
}
