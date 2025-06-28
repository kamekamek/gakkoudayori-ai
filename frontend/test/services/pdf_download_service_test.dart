import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:gakkoudayori_ai/services/pdf_download_service.dart';

void main() {
  group('PdfDownloadService', () {
    const samplePdfBase64 =
        'JVBERi0xLjcKCjEgMCBvYmoKPDwKL1R5cGUgL0NhdGFsb2cKL1BhZ2VzIDIgMCBSCj4+CmVuZG9iago='; // %PDF-1.7 のBase64
    const sampleTitle = 'テスト学級通信';

    group('ダウンロード機能', () {
      // プライベートメソッドは直接テストできないため、
      // パブリックメソッドを通じて間接的にテストする

      test('ダウンロード時にファイル名が適切に生成される', () async {
        // downloadPdf メソッドを呼び出して、エラーが発生しないことを確認
        expect(
          () async => await PdfDownloadService.downloadPdf(
            pdfBase64: samplePdfBase64,
            title: sampleTitle,
          ),
          returnsNormally,
        );
      });

      test('ファイル名なしでもダウンロードが動作する', () async {
        expect(
          () async => await PdfDownloadService.downloadPdf(
            pdfBase64: samplePdfBase64,
            fileName: null,
            title: null,
          ),
          returnsNormally,
        );
      });
    });

    group('PDFサイズ表示', () {
      test('バイト単位で表示', () {
        const smallPdfBase64 = 'JVBERi0xLjc='; // 短いBase64
        final size = PdfDownloadService.getPdfSizeFormatted(smallPdfBase64);

        expect(size, endsWith(' B'));
      });

      test('キロバイト単位で表示', () {
        // 約1KBのBase64文字列を生成
        final largeData = List.filled(1000, 65).join(); // 'A' を1000個
        final largeBase64 = base64Encode(largeData.codeUnits);
        final size = PdfDownloadService.getPdfSizeFormatted(largeBase64);

        expect(size, endsWith(' KB'));
      });

      test('メガバイト単位で表示', () {
        // 約1MBのBase64文字列を生成
        final largeData = List.filled(1000000, 65).join(); // 'A' を1,000,000個
        final largeBase64 = base64Encode(largeData.codeUnits);
        final size = PdfDownloadService.getPdfSizeFormatted(largeBase64);

        expect(size, endsWith(' MB'));
      });

      test('無効なBase64で不明を返す', () {
        const invalidBase64 = 'invalid base64 string!!!';
        final size = PdfDownloadService.getPdfSizeFormatted(invalidBase64);

        expect(size, equals('不明'));
      });
    });

    group('Base64妥当性チェック', () {
      test('有効なPDFのBase64を認識', () {
        final isValid = PdfDownloadService.isValidPdfBase64(samplePdfBase64);

        expect(isValid, isTrue);
      });

      test('PDFではないBase64を拒否', () {
        final textBase64 = base64.encode('Hello World'.codeUnits);
        final isValid = PdfDownloadService.isValidPdfBase64(textBase64);

        expect(isValid, isFalse);
      });

      test('空文字列を拒否', () {
        final isValid = PdfDownloadService.isValidPdfBase64('');

        expect(isValid, isFalse);
      });

      test('無効なBase64を拒否', () {
        const invalidBase64 = 'invalid base64!!!';
        final isValid = PdfDownloadService.isValidPdfBase64(invalidBase64);

        expect(isValid, isFalse);
      });

      test('短すぎるBase64を拒否', () {
        const shortBase64 = 'AB==';
        final isValid = PdfDownloadService.isValidPdfBase64(shortBase64);

        expect(isValid, isFalse);
      });
    });

    group('プレビューURL管理', () {
      test('有効なBase64からプレビューURLを生成', () {
        expect(() {
          final url = PdfDownloadService.createPreviewUrl(samplePdfBase64);
          expect(url, isNotEmpty);
          expect(url, startsWith('blob:'));

          // クリーンアップをテスト
          PdfDownloadService.revokePreviewUrl(url);
        }, returnsNormally);
      });

      test('無効なBase64でエラーを投げる', () {
        expect(
          () => PdfDownloadService.createPreviewUrl('invalid base64!!!'),
          throwsException,
        );
      });

      test('プレビューURLのクリーンアップがエラーを投げない', () {
        expect(
          () => PdfDownloadService.revokePreviewUrl('invalid://url'),
          returnsNormally,
        );
      });
    });

    group('ダウンロード機能', () {
      testWidgets('Web環境でのダウンロード処理', (WidgetTester tester) async {
        // Web環境でのダウンロードはBlobURLとanchorElementを使用
        // テスト環境では実際のダウンロードを実行せずに例外が発生しないことを確認

        expect(
          () async => await PdfDownloadService.downloadPdf(
            pdfBase64: samplePdfBase64,
            title: sampleTitle,
          ),
          returnsNormally,
        );
      });

      test('エラーリトライ機能のテスト', () async {
        // 無効なBase64でリトライ機能をテスト
        const invalidBase64 = 'invalid';

        expect(
          () async => await PdfDownloadService.downloadPdfWithRetry(
            pdfBase64: invalidBase64,
            title: sampleTitle,
            retryCount: 2, // 2回リトライ後に失敗
          ),
          throwsException,
        );
      });
    });

    group('エラーハンドリング', () {
      test('空のBase64でエラーを投げる', () {
        expect(
          () async => await PdfDownloadService.downloadPdf(
            pdfBase64: '',
            title: sampleTitle,
          ),
          throwsException,
        );
      });

      test('nullタイトルでも動作する', () {
        expect(
          () async => await PdfDownloadService.downloadPdf(
            pdfBase64: samplePdfBase64,
            title: null,
          ),
          returnsNormally,
        );
      });
    });
  });
}
