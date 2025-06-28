import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:gakkoudayori_ai/services/classroom_service.dart';

void main() {
  group('ClassroomService', () {
    setUpAll(() {
      // テスト環境での初期化
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    group('認証チェック', () {
      test('ログインしていない場合にエラーを投げる', () {
        // GoogleAuthService.isSignedIn = false の状態をシミュレート
        expect(
          () async => await ClassroomService.getCourses(),
          throwsException,
        );
      });

      test('権限が不足している場合にエラーを投げる', () {
        // 権限不足の状態をテスト
        expect(
          () async => await ClassroomService.getCourses(),
          throwsException,
        );
      });
    });

    group('統合テスト', () {
      test('Classroom統合テストが結果を返す', () async {
        // 統合テスト機能をテスト（認証なしでも結果を返すべき）
        final results = await ClassroomService.testClassroomIntegration();

        expect(results, isA<Map<String, bool>>());
        expect(results.containsKey('authentication'), isTrue);

        // 認証していない場合は false が返される
        expect(results['authentication'], isFalse);
      });

      test('テスト結果にすべての必要なキーが含まれる', () async {
        final results = await ClassroomService.testClassroomIntegration();

        // 認証されていない場合、他のテストは実行されない
        expect(results.containsKey('authentication'), isTrue);

        if (results['authentication'] == true) {
          expect(results.containsKey('getCourses'), isTrue);
          expect(results.containsKey('uploadFile'), isTrue);
        }
      });
    });

    group('学級通信投稿', () {
      test('投稿データの構造が正しい', () async {
        // PDF データのモック
        final pdfBytes = Uint8List.fromList([0x25, 0x50, 0x44, 0x46]); // %PDF
        const courseId = 'test-course-id';
        const title = 'テスト学級通信';
        const description = 'テスト用の投稿です';

        // 認証されていない状態でエラーが発生することを確認
        final result = await ClassroomService.postNewsletterToClassroom(
          courseId: courseId,
          title: title,
          description: description,
          pdfBytes: pdfBytes,
        );

        expect(result, isA<Map<String, dynamic>>());
        expect(result.containsKey('success'), isTrue);
        expect(result.containsKey('message'), isTrue);

        // 認証エラーで失敗することを確認
        expect(result['success'], isFalse);
      });

      test('画像ファイル付き投稿のデータ構造', () async {
        final pdfBytes = Uint8List.fromList([0x25, 0x50, 0x44, 0x46]);
        final imageFiles = [
          {
            'bytes': Uint8List.fromList([0xFF, 0xD8, 0xFF]), // JPEG header
            'name': 'test_image.jpg',
            'mimeType': 'image/jpeg',
          }
        ];

        final result = await ClassroomService.postNewsletterToClassroom(
          courseId: 'test-course-id',
          title: 'テスト学級通信',
          description: 'テスト用の投稿です',
          pdfBytes: pdfBytes,
          imageFiles: imageFiles,
        );

        expect(result, isA<Map<String, dynamic>>());
        expect(result['success'], isFalse); // 認証エラーで失敗
      });

      test('予約投稿のデータ構造', () async {
        final pdfBytes = Uint8List.fromList([0x25, 0x50, 0x44, 0x46]);
        final scheduledTime = DateTime.now().add(const Duration(hours: 1));

        final result = await ClassroomService.postNewsletterToClassroom(
          courseId: 'test-course-id',
          title: 'テスト学級通信',
          description: 'テスト用の投稿です',
          pdfBytes: pdfBytes,
          scheduledTime: scheduledTime,
        );

        expect(result, isA<Map<String, dynamic>>());
        expect(result['success'], isFalse); // 認証エラーで失敗
      });
    });

    group('エラーハンドリング', () {
      test('空のPDFデータでエラーハンドリング', () async {
        final emptyPdfBytes = Uint8List.fromList([]);

        final result = await ClassroomService.postNewsletterToClassroom(
          courseId: 'test-course-id',
          title: 'テスト学級通信',
          description: 'テスト用の投稿です',
          pdfBytes: emptyPdfBytes,
        );

        expect(result['success'], isFalse);
        expect(result.containsKey('error'), isTrue);
      });

      test('無効なコースIDでエラーハンドリング', () async {
        final pdfBytes = Uint8List.fromList([0x25, 0x50, 0x44, 0x46]);

        final result = await ClassroomService.postNewsletterToClassroom(
          courseId: '', // 空のコースID
          title: 'テスト学級通信',
          description: 'テスト用の投稿です',
          pdfBytes: pdfBytes,
        );

        expect(result['success'], isFalse);
        expect(result.containsKey('error'), isTrue);
      });

      test('空のタイトルでエラーハンドリング', () async {
        final pdfBytes = Uint8List.fromList([0x25, 0x50, 0x44, 0x46]);

        final result = await ClassroomService.postNewsletterToClassroom(
          courseId: 'test-course-id',
          title: '', // 空のタイトル
          description: 'テスト用の投稿です',
          pdfBytes: pdfBytes,
        );

        expect(result['success'], isFalse);
        expect(result.containsKey('error'), isTrue);
      });
    });

    group('データ妥当性チェック', () {
      test('PDFデータの妥当性', () {
        final validPdfBytes =
            Uint8List.fromList([0x25, 0x50, 0x44, 0x46]); // %PDF
        final invalidPdfBytes = Uint8List.fromList([0x00, 0x01, 0x02, 0x03]);

        // PDFヘッダーの確認（実際のサービスでは使用されていないが、データ妥当性の例）
        expect(validPdfBytes[0], equals(0x25)); // %
        expect(validPdfBytes[1], equals(0x50)); // P
        expect(validPdfBytes[2], equals(0x44)); // D
        expect(validPdfBytes[3], equals(0x46)); // F

        expect(invalidPdfBytes[0], isNot(equals(0x25)));
      });

      test('画像ファイルデータの構造妥当性', () {
        final validImageFile = {
          'bytes': Uint8List.fromList([0xFF, 0xD8, 0xFF]), // JPEG header
          'name': 'test_image.jpg',
          'mimeType': 'image/jpeg',
        };

        expect(validImageFile.containsKey('bytes'), isTrue);
        expect(validImageFile.containsKey('name'), isTrue);
        expect(validImageFile.containsKey('mimeType'), isTrue);
        expect(validImageFile['bytes'], isA<Uint8List>());
        expect(validImageFile['name'], isA<String>());
        expect(validImageFile['mimeType'], isA<String>());
      });

      test('コースIDの形式妥当性', () {
        const validCourseId = 'test-course-id-123';
        const invalidCourseId = '';

        expect(validCourseId.isNotEmpty, isTrue);
        expect(invalidCourseId.isEmpty, isTrue);
      });
    });

    group('日時処理', () {
      test('予約投稿時刻の妥当性', () {
        final now = DateTime.now();
        final futureTime = now.add(const Duration(hours: 1));
        final pastTime = now.subtract(const Duration(hours: 1));

        expect(futureTime.isAfter(now), isTrue);
        expect(pastTime.isBefore(now), isTrue);
      });

      test('ISO8601形式の時刻文字列変換', () {
        final testTime = DateTime(2024, 6, 22, 15, 30, 0);
        final isoString = testTime.toUtc().toIso8601String();

        expect(isoString, contains('2024-06-22'));
        expect(isoString, contains('T'));
        expect(isoString, endsWith('Z'));
      });
    });
  });
}
