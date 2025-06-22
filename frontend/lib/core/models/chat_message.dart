/// チャットメッセージのデータモデル
class ChatMessage {
  final String id;
  final String sender; // 'user', 'ai', 'system'
  final String message;
  final MessageType type;
  final DateTime timestamp;
  final List<String>? options; // AIからの選択肢
  final Map<String, dynamic>? metadata; // 追加データ

  ChatMessage({
    required this.id,
    required this.sender,
    required this.message,
    required this.type,
    required this.timestamp,
    this.options,
    this.metadata,
  });

  bool get isUser => sender == 'user';
  bool get isAI => sender == 'ai';
  bool get isSystem => sender == 'system';
  bool get hasOptions => options != null && options!.isNotEmpty;

  ChatMessage copyWith({
    String? id,
    String? sender,
    String? message,
    MessageType? type,
    DateTime? timestamp,
    List<String>? options,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      message: message ?? this.message,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      options: options ?? this.options,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender': sender,
      'message': message,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'options': options,
      'metadata': metadata,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      sender: json['sender'],
      message: json['message'],
      type: MessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MessageType.text,
      ),
      timestamp: DateTime.parse(json['timestamp']),
      options: json['options']?.cast<String>(),
      metadata: json['metadata'],
    );
  }
}

/// メッセージの種類
enum MessageType {
  text,    // テキストメッセージ
  voice,   // 音声入力
  image,   // 画像
  status,  // ステータスメッセージ
  options, // 選択肢付きメッセージ
  error,   // エラーメッセージ
}

/// チャットの会話フロー状態
enum ChatFlowState {
  initial,           // 初期状態
  gatheringContent,  // 内容収集中
  selectingStyle,    // スタイル選択中
  addingImages,      // 画像追加中
  generating,        // 生成中
  reviewing,         // レビュー中
  completed,         // 完了
}

/// チャット設定
class ChatSettings {
  final bool enableVoiceInput;
  final bool enableImageUpload;
  final bool enableAutoScroll;
  final Duration typingDelay;

  const ChatSettings({
    this.enableVoiceInput = true,
    this.enableImageUpload = true,
    this.enableAutoScroll = true,
    this.typingDelay = const Duration(milliseconds: 1000),
  });

  ChatSettings copyWith({
    bool? enableVoiceInput,
    bool? enableImageUpload,
    bool? enableAutoScroll,
    Duration? typingDelay,
  }) {
    return ChatSettings(
      enableVoiceInput: enableVoiceInput ?? this.enableVoiceInput,
      enableImageUpload: enableImageUpload ?? this.enableImageUpload,
      enableAutoScroll: enableAutoScroll ?? this.enableAutoScroll,
      typingDelay: typingDelay ?? this.typingDelay,
    );
  }
}