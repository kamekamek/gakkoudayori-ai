import 'package:flutter_test/flutter_test.dart';
import 'package:yutori_kyoshitu/features/editor/services/javascript_bridge.dart';

void main() {
  group('JavaScriptBridge Tests', () {
    late JavaScriptBridge bridge;

    setUp(() {
      bridge = JavaScriptBridge();
    });

    test('should create bridge instance', () {
      expect(bridge, isNotNull);
      expect(bridge, isA<JavaScriptBridge>());
    });

    test('should handle command serialization', () {
      final command = JavaScriptCommand(
        method: 'getHTML',
        params: {},
      );
      
      final serialized = bridge.serializeCommand(command);
      expect(serialized, isA<String>());
      expect(serialized, contains('getHTML'));
    });

    test('should handle response deserialization', () {
      const jsonResponse = '{"success": true, "data": "<p>test</p>"}';
      
      final response = bridge.deserializeResponse(jsonResponse);
      expect(response, isA<JavaScriptResponse>());
      expect(response.success, true);
      expect(response.data, '<p>test</p>');
    });

    test('should handle error responses', () {
      const jsonResponse = '{"success": false, "error": "Test error"}';
      
      final response = bridge.deserializeResponse(jsonResponse);
      expect(response, isA<JavaScriptResponse>());
      expect(response.success, false);
      expect(response.error, 'Test error');
    });

    test('should handle malformed JSON', () {
      const malformedJson = 'invalid json';
      
      expect(() => bridge.deserializeResponse(malformedJson), 
        throwsA(isA<FormatException>()));
    });

    group('Command Validation', () {
      test('should validate required method', () {
        expect(() => JavaScriptCommand(method: '', params: {}),
          throwsA(isA<ArgumentError>()));
      });

      test('should accept valid commands', () {
        final command = JavaScriptCommand(
          method: 'setHTML',
          params: {'html': '<p>test</p>'},
        );
        expect(command.method, 'setHTML');
        expect(command.params['html'], '<p>test</p>');
      });
    });

    group('Response Validation', () {
      test('should handle empty data', () {
        const jsonResponse = '{"success": true, "data": null}';
        
        final response = bridge.deserializeResponse(jsonResponse);
        expect(response.success, true);
        expect(response.data, null);
      });

      test('should handle complex data structures', () {
        const jsonResponse = '{"success": true, "data": {"ops": [{"insert": "Hello\\n"}]}}';
        
        final response = bridge.deserializeResponse(jsonResponse);
        expect(response.success, true);
        expect(response.data, isA<Map>());
        expect((response.data as Map)['ops'], isA<List>());
      });
    });
  });
}