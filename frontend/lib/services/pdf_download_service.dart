import 'dart:convert';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/foundation.dart';

/// PDF保存・ダウンロードサービス
///
/// バックエンドで生成されたPDFをフロントエンドでダウンロード可能にする
/// WebブラウザでのBlobURLダウンロード機能を提供
class PdfDownloadService {
  /// PDFをダウンロードする
  ///
  /// [pdfBase64] バックエンドから取得したBase64エンコードされたPDF
  /// [fileName] ダウンロードファイル名（自動生成される場合は省略可）
  /// [title] 学級通信のタイトル（ファイル名生成に使用）
  static Future<void> downloadPdf({
    required String pdfBase64,
    String? fileName,
    String? title,
  }) async {
    try {
      // ファイル名の生成
      final downloadFileName = fileName ?? _generateFileName(title);

      // Base64をUint8Listに変換
      final pdfBytes = base64Decode(pdfBase64);

      if (kIsWeb) {
        // Web環境でのダウンロード
        await _downloadPdfWeb(pdfBytes, downloadFileName);
      } else {
        // モバイル環境（将来対応）
        throw UnsupportedError('モバイル環境でのPDF保存は現在未対応です');
      }
    } catch (e) {
      throw Exception('PDFダウンロードに失敗しました: $e');
    }
  }

  /// WebブラウザでPDFをダウンロード
  static Future<void> _downloadPdfWeb(
      Uint8List pdfBytes, String fileName) async {
    try {
      // BlobオブジェクトとしてPDFデータを作成
      final blob = html.Blob([pdfBytes], 'application/pdf');

      // Blob URLを生成
      final url = html.Url.createObjectUrlFromBlob(blob);

      // ダウンロードリンクを作成して自動クリック
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..style.display = 'none';

      // DOMに追加して自動クリック
      html.document.body?.children.add(anchor);
      anchor.click();

      // クリーンアップ
      html.document.body?.children.remove(anchor);
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      throw Exception('Webブラウザでのダウンロードに失敗しました: $e');
    }
  }

  /// ファイル名を自動生成
  ///
  /// [title] 学級通信のタイトル
  /// Returns: 「学級通信_YYYYMMDD_HHMMSS.pdf」形式のファイル名
  static String _generateFileName(String? title) {
    final now = DateTime.now();
    final dateString = now
        .toIso8601String()
        .substring(0, 19)
        .replaceAll(RegExp(r'[:-]'), '')
        .replaceAll('T', '_');

    if (title != null && title.isNotEmpty) {
      // タイトルを安全なファイル名に変換
      final safeTitle = title
          .replaceAll(RegExp(r'[\\/:*?"<>|]'), '') // 無効な文字を除去
          .replaceAll(' ', '_') // スペースをアンダースコアに
          .substring(0, title.length > 20 ? 20 : title.length); // 長さ制限

      return '${safeTitle}_$dateString.pdf';
    } else {
      return '学級通信_$dateString.pdf';
    }
  }

  /// PDFのプレビュー用URLを生成
  ///
  /// [pdfBase64] Base64エンコードされたPDF
  /// Returns: プレビュー表示用のBlob URL
  static String createPreviewUrl(String pdfBase64) {
    try {
      final pdfBytes = base64Decode(pdfBase64);
      final blob = html.Blob([pdfBytes], 'application/pdf');
      return html.Url.createObjectUrlFromBlob(blob);
    } catch (e) {
      throw Exception('PDFプレビューURL生成に失敗しました: $e');
    }
  }

  /// プレビューURLをクリーンアップ
  ///
  /// [previewUrl] createPreviewUrlで生成されたURL
  static void revokePreviewUrl(String previewUrl) {
    try {
      html.Url.revokeObjectUrl(previewUrl);
    } catch (e) {
      // ログ出力のみ、エラーとして扱わない
      if (kDebugMode) {
        print('プレビューURLのクリーンアップに失敗: $e');
      }
    }
  }

  /// PDFサイズを人間が読みやすい形式で返す
  ///
  /// [pdfBase64] Base64エンコードされたPDF
  /// Returns: "1.2 MB" のような形式の文字列
  static String getPdfSizeFormatted(String pdfBase64) {
    try {
      final pdfBytes = base64Decode(pdfBase64);
      final sizeInBytes = pdfBytes.length;

      if (sizeInBytes < 1024) {
        return '$sizeInBytes B';
      } else if (sizeInBytes < 1024 * 1024) {
        return '${(sizeInBytes / 1024).toStringAsFixed(1)} KB';
      } else {
        return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
      }
    } catch (e) {
      return '不明';
    }
  }

  /// Base64データの妥当性をチェック
  ///
  /// [pdfBase64] チェック対象のBase64文字列
  /// Returns: true if valid, false otherwise
  static bool isValidPdfBase64(String pdfBase64) {
    try {
      if (pdfBase64.isEmpty) return false;

      // Base64デコードテスト
      final bytes = base64Decode(pdfBase64);

      // PDFヘッダーの確認（%PDF-で始まるかチェック）
      if (bytes.length < 4) return false;

      final headerString = String.fromCharCodes(bytes.take(4));
      return headerString == '%PDF';
    } catch (e) {
      return false;
    }
  }

  /// ダウンロード進捗を管理するための設定
  static const int maxRetryCount = 3;
  static const Duration retryDelay = Duration(seconds: 1);

  /// エラーハンドリング付きダウンロード
  ///
  /// リトライ機能付きのダウンロード処理
  static Future<void> downloadPdfWithRetry({
    required String pdfBase64,
    String? fileName,
    String? title,
    int retryCount = 0,
  }) async {
    try {
      await downloadPdf(
        pdfBase64: pdfBase64,
        fileName: fileName,
        title: title,
      );
    } catch (e) {
      if (retryCount < maxRetryCount) {
        await Future.delayed(retryDelay);
        await downloadPdfWithRetry(
          pdfBase64: pdfBase64,
          fileName: fileName,
          title: title,
          retryCount: retryCount + 1,
        );
      } else {
        rethrow;
      }
    }
  }
}
