/// システムメッセージのタイプ
enum SystemMessageType {
  pdfGenerated,        // PDF生成完了
  classroomPosted,     // Classroom投稿完了
  error,               // エラー発生
  info,                // 一般的な情報
  success,             // 成功通知
  warning,             // 警告
}

/// チャットメッセージのモデル
class MutableChatMessage {
  String role;
  String content;
  DateTime timestamp;
  String? id;
  Map<String, dynamic>? metadata;
  
  /// システムメッセージのタイプ（role='system'の場合のみ使用）
  SystemMessageType? systemMessageType;

  MutableChatMessage({
    required this.role,
    required this.content,
    DateTime? timestamp,
    this.id,
    this.metadata,
    this.systemMessageType,
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
  MutableChatMessage.system(this.content, {this.systemMessageType})
      : role = 'system',
        timestamp = DateTime.now();

  /// 成功通知のシステムメッセージを作成
  MutableChatMessage.success(this.content)
      : role = 'system',
        systemMessageType = SystemMessageType.success,
        timestamp = DateTime.now();

  /// PDF生成完了通知のシステムメッセージを作成  
  MutableChatMessage.pdfGenerated(this.content)
      : role = 'system',
        systemMessageType = SystemMessageType.pdfGenerated,
        timestamp = DateTime.now();

  /// Classroom投稿完了通知のシステムメッセージを作成
  MutableChatMessage.classroomPosted(this.content)
      : role = 'system',
        systemMessageType = SystemMessageType.classroomPosted,
        timestamp = DateTime.now();

  /// エラーメッセージを作成
  MutableChatMessage.error(this.content)
      : role = 'error',
        systemMessageType = SystemMessageType.error,
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
      systemMessageType: json['systemMessageType'] != null
          ? SystemMessageType.values.firstWhere(
              (e) => e.name == json['systemMessageType'],
              orElse: () => SystemMessageType.info,
            )
          : null,
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
      'systemMessageType': systemMessageType?.name,
    };
  }

  /// コピーを作成
  MutableChatMessage copyWith({
    String? role,
    String? content,
    DateTime? timestamp,
    String? id,
    Map<String, dynamic>? metadata,
    SystemMessageType? systemMessageType,
  }) {
    return MutableChatMessage(
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      id: id ?? this.id,
      metadata: metadata ?? this.metadata,
      systemMessageType: systemMessageType ?? this.systemMessageType,
    );
  }

  @override
  String toString() {
    return 'MutableChatMessage(role: $role, content: ${content.length > 50 ? '${content.substring(0, 50)}...' : content})';
  }
}
