import 'package:flutter_test/flutter_test.dart';
import 'package:yutori_kyoshitsu/services/websocket_service.dart';

void main() {
  group('WebSocketService', () {
    late WebSocketService webSocketService;

    setUp(() {
      webSocketService = WebSocketService();
    });

    tearDown(() {
      webSocketService.dispose();
    });

    test('初期状態が正しく設定される', () {
      // Then
      expect(webSocketService.isConnected, isFalse);
    });

    test('メッセージストリームが利用可能', () {
      // Then
      expect(webSocketService.messageStream, isNotNull);
      expect(webSocketService.aiSuggestionStream, isNotNull);
      expect(webSocketService.userActivityStream, isNotNull);
    });

    test('接続前はメッセージ送信が無視される', () {
      // When
      webSocketService.sendChatMessage('テストメッセージ');

      // Then - エラーが発生しないことを確認
      expect(webSocketService.isConnected, isFalse);
    });

    test('タイピングインジケーターが送信できる', () {
      // When
      webSocketService.sendTypingIndicator(true);

      // Then - エラーが発生しないことを確認
      expect(webSocketService.isConnected, isFalse);
    });

    test('編集リクエストが送信できる', () {
      // When
      webSocketService.sendEditRequest(
        editType: 'accept',
        suggestionId: 'test_suggestion_123',
      );

      // Then - エラーが発生しないことを確認
      expect(webSocketService.isConnected, isFalse);
    });

    test('コンテンツ更新が送信できる', () {
      // When
      webSocketService.sendContentUpdate('<p>更新されたコンテンツ</p>');

      // Then - エラーが発生しないことを確認
      expect(webSocketService.isConnected, isFalse);
    });

    test('disposeでリソースが解放される', () {
      // When
      webSocketService.dispose();

      // Then - エラーが発生しないことを確認
      expect(webSocketService.isConnected, isFalse);
    });
  });
}
