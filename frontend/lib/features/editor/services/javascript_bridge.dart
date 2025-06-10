import 'dart:convert';

/// JavaScript Bridge サービス - FlutterとQuill.js間の通信を管理
class JavaScriptBridge {
  /// コマンドをJSON文字列にシリアライズ
  String serializeCommand(JavaScriptCommand command) {
    return jsonEncode({
      'method': command.method,
      'params': command.params,
      'id': command.id,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// JSON文字列からレスポンスをデシリアライズ
  JavaScriptResponse deserializeResponse(String jsonString) {
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return JavaScriptResponse.fromJson(json);
    } catch (e) {
      throw FormatException('Invalid JSON response: $jsonString', e);
    }
  }

  /// エラーレスポンスを作成
  JavaScriptResponse createErrorResponse(String error, {String? id}) {
    return JavaScriptResponse(
      success: false,
      error: error,
      data: null,
      id: id,
    );
  }

  /// 成功レスポンスを作成
  JavaScriptResponse createSuccessResponse(dynamic data, {String? id}) {
    return JavaScriptResponse(
      success: true,
      data: data,
      error: null,
      id: id,
    );
  }

  /// バッチコマンドをシリアライズ
  String serializeBatchCommands(List<JavaScriptCommand> commands) {
    return jsonEncode({
      'batch': true,
      'commands': commands.map((cmd) => {
        'method': cmd.method,
        'params': cmd.params,
        'id': cmd.id,
      }).toList(),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }
}

/// JavaScriptコマンドのデータクラス
class JavaScriptCommand {
  final String method;
  final Map<String, dynamic> params;
  final String id;

  JavaScriptCommand({
    required this.method,
    required this.params,
    String? id,
  }) : id = id ?? _generateId() {
    if (method.isEmpty) {
      throw ArgumentError('Method cannot be empty');
    }
  }

  static String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + 
           (DateTime.now().microsecond % 1000).toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'method': method,
      'params': params,
      'id': id,
    };
  }

  @override
  String toString() {
    return 'JavaScriptCommand(method: $method, params: $params, id: $id)';
  }
}

/// JavaScriptレスポンスのデータクラス
class JavaScriptResponse {
  final bool success;
  final dynamic data;
  final String? error;
  final String? id;
  final int? timestamp;

  const JavaScriptResponse({
    required this.success,
    this.data,
    this.error,
    this.id,
    this.timestamp,
  });

  factory JavaScriptResponse.fromJson(Map<String, dynamic> json) {
    return JavaScriptResponse(
      success: json['success'] as bool? ?? false,
      data: json['data'],
      error: json['error'] as String?,
      id: json['id'] as String?,
      timestamp: json['timestamp'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': data,
      'error': error,
      'id': id,
      'timestamp': timestamp,
    };
  }

  @override
  String toString() {
    return 'JavaScriptResponse(success: $success, data: $data, error: $error, id: $id)';
  }
}

/// Quill.js固有のコマンドヘルパー
class QuillCommands {
  static JavaScriptCommand getHTML({String? id}) {
    return JavaScriptCommand(
      method: 'getHTML',
      params: {},
      id: id,
    );
  }

  static JavaScriptCommand setHTML(String html, {String? id}) {
    return JavaScriptCommand(
      method: 'setHTML',
      params: {'html': html},
      id: id,
    );
  }

  static JavaScriptCommand getDelta({String? id}) {
    return JavaScriptCommand(
      method: 'getDelta',
      params: {},
      id: id,
    );
  }

  static JavaScriptCommand setDelta(String deltaJson, {String? id}) {
    return JavaScriptCommand(
      method: 'setDelta',
      params: {'deltaJson': deltaJson},
      id: id,
    );
  }

  static JavaScriptCommand getText({String? id}) {
    return JavaScriptCommand(
      method: 'getText',
      params: {},
      id: id,
    );
  }

  static JavaScriptCommand insertText(String text, {int? index, String? id}) {
    return JavaScriptCommand(
      method: 'insertText',
      params: {
        'text': text,
        if (index != null) 'index': index,
      },
      id: id,
    );
  }

  static JavaScriptCommand focus({String? id}) {
    return JavaScriptCommand(
      method: 'focus',
      params: {},
      id: id,
    );
  }

  static JavaScriptCommand setTheme(String themeName, {String? id}) {
    return JavaScriptCommand(
      method: 'setTheme',
      params: {'themeName': themeName},
      id: id,
    );
  }

  static JavaScriptCommand getSelection({String? id}) {
    return JavaScriptCommand(
      method: 'getSelection',
      params: {},
      id: id,
    );
  }

  static JavaScriptCommand setSelection(int index, int length, {String? id}) {
    return JavaScriptCommand(
      method: 'setSelection',
      params: {'index': index, 'length': length},
      id: id,
    );
  }

  static JavaScriptCommand ping({String? id}) {
    return JavaScriptCommand(
      method: 'ping',
      params: {},
      id: id,
    );
  }
}

/// Bridge通信のエラークラス
class BridgeException implements Exception {
  final String message;
  final String? originalError;
  final JavaScriptCommand? command;

  const BridgeException(
    this.message, {
    this.originalError,
    this.command,
  });

  @override
  String toString() {
    return 'BridgeException: $message${originalError != null ? ' (Original: $originalError)' : ''}';
  }
}