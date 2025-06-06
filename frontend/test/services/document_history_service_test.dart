import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../lib/models/document.dart';
import '../../lib/services/document_history_service.dart';

// Mockクラス生成のためのアノテーション
@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  DocumentReference,
  DocumentSnapshot
])
import 'document_history_service_test.mocks.dart';

void main() {
  group('DocumentHistoryService Tests', () {
    late DocumentHistoryService service;
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference<Map<String, dynamic>> mockCollection;
    late MockDocumentReference<Map<String, dynamic>> mockDocumentRef;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockCollection = MockCollectionReference<Map<String, dynamic>>();
      mockDocumentRef = MockDocumentReference<Map<String, dynamic>>();
      service = DocumentHistoryService(firestore: mockFirestore);
    });

    group('🔴 Red: 下書き保存機能のテスト', () {
      test('ドキュメントを下書きとして保存できる', () async {
        // Arrange
        final testDocument = Document(
          id: 'test-doc-1',
          userId: 'user123',
          title: 'テスト通信',
          content: 'テスト内容',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          thumbnail: '📄',
          status: DocumentStatus.draft,
        );

        when(mockFirestore.collection('documents')).thenReturn(mockCollection);
        when(mockCollection.doc(testDocument.id)).thenReturn(mockDocumentRef);
        when(mockDocumentRef.set(any)).thenAnswer((_) async => {});

        // Act
        final result = await service.saveDraft(testDocument);

        // Assert
        expect(result, isTrue);
        verify(mockDocumentRef.set(testDocument.toFirestore())).called(1);
      });

      test('保存に失敗した場合はfalseを返す', () async {
        // Arrange
        final testDocument = Document(
          id: 'test-doc-1',
          userId: 'user123',
          title: 'テスト通信',
          content: 'テスト内容',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          thumbnail: '📄',
          status: DocumentStatus.draft,
        );

        when(mockFirestore.collection('documents')).thenReturn(mockCollection);
        when(mockCollection.doc(testDocument.id)).thenReturn(mockDocumentRef);
        when(mockDocumentRef.set(any)).thenThrow(Exception('Firestore error'));

        // Act
        final result = await service.saveDraft(testDocument);

        // Assert
        expect(result, isFalse);
      });
    });

    group('🔴 Red: 下書き読み込み機能のテスト', () {
      test('ユーザーの下書き一覧を取得できる', () async {
        // Arrange
        const userId = 'user123';
        final testDocuments = [
          {
            'id': 'doc1',
            'user_id': userId,
            'title': 'テスト通信1',
            'content': 'テスト内容1',
            'status': 'draft',
            'created_at': Timestamp.now(),
            'updated_at': Timestamp.now(),
          },
          {
            'id': 'doc2',
            'user_id': userId,
            'title': 'テスト通信2',
            'content': 'テスト内容2',
            'status': 'draft',
            'created_at': Timestamp.now(),
            'updated_at': Timestamp.now(),
          },
        ];

        // TODO: Queryのモック設定（複雑なため実装時に調整）

        // Act
        final result = await service.getUserDrafts(userId);

        // Assert
        expect(result, isA<List<Document>>());
        expect(result.length, equals(2));
        expect(
            result.every((doc) => doc.status == DocumentStatus.draft), isTrue);
      });

      test('特定のドキュメントを取得できる', () async {
        // Arrange
        const documentId = 'test-doc-1';
        final testData = {
          'user_id': 'user123',
          'title': 'テスト通信',
          'content': 'テスト内容',
          'status': 'draft',
          'created_at': Timestamp.now(),
          'updated_at': Timestamp.now(),
        };

        final mockSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();
        when(mockFirestore.collection('documents')).thenReturn(mockCollection);
        when(mockCollection.doc(documentId)).thenReturn(mockDocumentRef);
        when(mockDocumentRef.get()).thenAnswer((_) async => mockSnapshot);
        when(mockSnapshot.exists).thenReturn(true);
        when(mockSnapshot.data()).thenReturn(testData);
        when(mockSnapshot.id).thenReturn(documentId);

        // Act
        final result = await service.getDocument(documentId);

        // Assert
        expect(result, isNotNull);
        expect(result!.id, equals(documentId));
        expect(result.title, equals('テスト通信'));
      });
    });

    group('🔴 Red: 削除機能のテスト', () {
      test('ドキュメントを削除できる', () async {
        // Arrange
        const documentId = 'test-doc-1';

        when(mockFirestore.collection('documents')).thenReturn(mockCollection);
        when(mockCollection.doc(documentId)).thenReturn(mockDocumentRef);
        when(mockDocumentRef.delete()).thenAnswer((_) async => {});

        // Act
        final result = await service.deleteDocument(documentId);

        // Assert
        expect(result, isTrue);
        verify(mockDocumentRef.delete()).called(1);
      });

      test('削除に失敗した場合はfalseを返す', () async {
        // Arrange
        const documentId = 'test-doc-1';

        when(mockFirestore.collection('documents')).thenReturn(mockCollection);
        when(mockCollection.doc(documentId)).thenReturn(mockDocumentRef);
        when(mockDocumentRef.delete()).thenThrow(Exception('Firestore error'));

        // Act
        final result = await service.deleteDocument(documentId);

        // Assert
        expect(result, isFalse);
      });
    });

    group('🔴 Red: 完了(Done)機能のテスト', () {
      test('ドキュメントを配信済みステータスに変更できる', () async {
        // Arrange
        const documentId = 'test-doc-1';
        final completionData = {
          'status': 'published',
          'updated_at': FieldValue.serverTimestamp(),
          'completed_at': FieldValue.serverTimestamp(),
        };

        when(mockFirestore.collection('documents')).thenReturn(mockCollection);
        when(mockCollection.doc(documentId)).thenReturn(mockDocumentRef);
        when(mockDocumentRef.update(any)).thenAnswer((_) async => {});

        // Act
        final result = await service.markAsCompleted(documentId);

        // Assert
        expect(result, isTrue);
        verify(mockDocumentRef
                .update(argThat(containsPair('status', 'published'))))
            .called(1);
      });

      test('完了マークに失敗した場合はfalseを返す', () async {
        // Arrange
        const documentId = 'test-doc-1';

        when(mockFirestore.collection('documents')).thenReturn(mockCollection);
        when(mockCollection.doc(documentId)).thenReturn(mockDocumentRef);
        when(mockDocumentRef.update(any))
            .thenThrow(Exception('Firestore error'));

        // Act
        final result = await service.markAsCompleted(documentId);

        // Assert
        expect(result, isFalse);
      });
    });

    group('🔴 Red: 復元機能のテスト', () {
      test('アーカイブされたドキュメントを下書きに復元できる', () async {
        // Arrange
        const documentId = 'test-doc-1';

        when(mockFirestore.collection('documents')).thenReturn(mockCollection);
        when(mockCollection.doc(documentId)).thenReturn(mockDocumentRef);
        when(mockDocumentRef.update(any)).thenAnswer((_) async => {});

        // Act
        final result = await service.restoreFromArchive(documentId);

        // Assert
        expect(result, isTrue);
        verify(mockDocumentRef.update(argThat(containsPair('status', 'draft'))))
            .called(1);
      });
    });
  });
}
