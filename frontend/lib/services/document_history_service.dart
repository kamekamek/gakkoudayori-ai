import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/document.dart';

/// ドキュメント履歴管理サービス
/// 下書き保存・復元・削除・完了機能を提供
class DocumentHistoryService {
  final FirebaseFirestore _firestore;

  /// コンストラクタ（テスト用にFirestoreを注入可能）
  DocumentHistoryService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// 下書きとして保存
  Future<bool> saveDraft(Document document) async {
    try {
      await _firestore
          .collection('documents')
          .doc(document.id)
          .set(document.toFirestore());
      return true;
    } catch (e) {
      print('下書き保存エラー: $e');
      return false;
    }
  }

  /// ユーザーの下書き一覧を取得
  Future<List<Document>> getUserDrafts(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('documents')
          .where('user_id', isEqualTo: userId)
          .where('status', isEqualTo: 'draft')
          .orderBy('updated_at', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Document.fromFirestore(doc.id, doc.data()))
          .toList();
    } catch (e) {
      print('下書き一覧取得エラー: $e');
      return [];
    }
  }

  /// 特定のドキュメントを取得
  Future<Document?> getDocument(String documentId) async {
    try {
      final docSnapshot =
          await _firestore.collection('documents').doc(documentId).get();

      if (docSnapshot.exists) {
        return Document.fromFirestore(docSnapshot.id, docSnapshot.data()!);
      }
      return null;
    } catch (e) {
      print('ドキュメント取得エラー: $e');
      return null;
    }
  }

  /// ドキュメントを削除
  Future<bool> deleteDocument(String documentId) async {
    try {
      await _firestore.collection('documents').doc(documentId).delete();
      return true;
    } catch (e) {
      print('ドキュメント削除エラー: $e');
      return false;
    }
  }

  /// ドキュメントを完了済みにマーク
  Future<bool> markAsCompleted(String documentId) async {
    try {
      await _firestore.collection('documents').doc(documentId).update({
        'status': 'published',
        'updated_at': FieldValue.serverTimestamp(),
        'completed_at': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('ドキュメント完了マークエラー: $e');
      return false;
    }
  }

  /// アーカイブから復元
  Future<bool> restoreFromArchive(String documentId) async {
    try {
      await _firestore.collection('documents').doc(documentId).update({
        'status': 'draft',
        'updated_at': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('ドキュメント復元エラー: $e');
      return false;
    }
  }

  /// ユーザーのすべてのドキュメント（ステータス別）を取得
  Future<List<Document>> getUserDocuments(
    String userId, {
    DocumentStatus? status,
    int limit = 20,
  }) async {
    try {
      Query query = _firestore
          .collection('documents')
          .where('user_id', isEqualTo: userId);

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      final querySnapshot = await query
          .orderBy('updated_at', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => Document.fromFirestore(
              doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('ドキュメント一覧取得エラー: $e');
      return [];
    }
  }

  /// ドキュメントを更新
  Future<bool> updateDocument(
      String documentId, Map<String, dynamic> updates) async {
    try {
      updates['updated_at'] = FieldValue.serverTimestamp();
      await _firestore.collection('documents').doc(documentId).update(updates);
      return true;
    } catch (e) {
      print('ドキュメント更新エラー: $e');
      return false;
    }
  }

  /// 自動保存（一定間隔で下書き保存）
  Future<bool> autoSave(Document document) async {
    // 自動保存は silent fail で実装
    try {
      final updates = {
        'content': document.content,
        'html_content': document.htmlContent,
        'title': document.title,
        'updated_at': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('documents').doc(document.id).update(updates);
      return true;
    } catch (e) {
      // 自動保存エラーはログのみ（UIに影響しない）
      print('自動保存エラー: $e');
      return false;
    }
  }
}
