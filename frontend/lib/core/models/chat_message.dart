/// チャットメッセージのモデル
class MutableChatMessage {
  String role;
  String content;
  DateTime timestamp;
  String? id;
  Map<String, dynamic>? metadata;

  MutableChatMessage({
    required this.role,
    required this.content,
    DateTime? timestamp,
    this.id,
    this.metadata,
  }) : timestamp = timestamp ?? DateTime.now();

  /// ユーザーメッセージを作成
  MutableChatMessage.user(this.content)
      : role = 'user',
        timestamp = DateTime.now();

  /// アシスタントメッセージを作成
  MutableChatMessage.assistant(this.content)
      : role = 'assistant',
        timestamp = DateTime.now();

  /// システムメッセージを作成
  MutableChatMessage.system(this.content)
      : role = 'system',
        timestamp = DateTime.now();

  /// エラーメッセージを作成
  MutableChatMessage.error(this.content)
      : role = 'error',
        timestamp = DateTime.now();

  /// JSONから作成
  factory MutableChatMessage.fromJson(Map<String, dynamic> json) {
    return MutableChatMessage(
      role: json['role'] ?? 'assistant',
      content: json['content'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      id: json['id'],
      metadata: json['metadata'],
    );
  }

  /// JSONに変換
  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'id': id,
      'metadata': metadata,
    };
  }

  /// コピーを作成
  MutableChatMessage copyWith({
    String? role,
    String? content,
    DateTime? timestamp,
    String? id,
    Map<String, dynamic>? metadata,
  }) {
    return MutableChatMessage(
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      id: id ?? this.id,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'MutableChatMessage(role: $role, content: ${content.length > 50 ? '${content.substring(0, 50)}...' : content})';
  }
}
