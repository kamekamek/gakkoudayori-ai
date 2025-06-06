class Document {
  final String id;
  final String userId;
  final String title;
  final String content;
  final String htmlContent;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String thumbnail;
  final DocumentStatus status;
  final List<String> tags;
  final String? templateId;
  final int version;
  final Map<String, dynamic> metadata;
  final int? views;

  Document({
    required this.id,
    this.userId = '',
    required this.title,
    this.content = '',
    this.htmlContent = '',
    required this.createdAt,
    required this.updatedAt,
    required this.thumbnail,
    required this.status,
    this.tags = const [],
    this.templateId,
    this.version = 1,
    this.metadata = const {},
    this.views,
  });

  Document copyWith({
    String? id,
    String? userId,
    String? title,
    String? content,
    String? htmlContent,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? thumbnail,
    DocumentStatus? status,
    List<String>? tags,
    String? templateId,
    int? version,
    Map<String, dynamic>? metadata,
    int? views,
  }) {
    return Document(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      content: content ?? this.content,
      htmlContent: htmlContent ?? this.htmlContent,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      thumbnail: thumbnail ?? this.thumbnail,
      status: status ?? this.status,
      tags: tags ?? this.tags,
      templateId: templateId ?? this.templateId,
      version: version ?? this.version,
      metadata: metadata ?? this.metadata,
      views: views ?? this.views,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'content': content,
      'html_content': htmlContent,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'thumbnail': thumbnail,
      'status': status.name,
      'tags': tags,
      'template_id': templateId,
      'version': version,
      'metadata': metadata,
      'views': views,
    };
  }

  /// Firestore用のデータ形式に変換（created_at, updated_atはFirestore Timestampに）
  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'title': title,
      'content': content,
      'html_content': htmlContent,
      'status': status.name,
      'tags': tags,
      'template_id': templateId,
      'version': version,
      'metadata': metadata,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? json['userId'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      htmlContent: json['html_content'] ?? json['htmlContent'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      thumbnail: json['thumbnail'] ?? '📄',
      status: DocumentStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => DocumentStatus.draft,
      ),
      tags: List<String>.from(json['tags'] ?? []),
      templateId: json['template_id'] ?? json['templateId'],
      version: json['version'] ?? 1,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      views: json['views'],
    );
  }

  /// Firestoreドキュメントから変換
  factory Document.fromFirestore(String documentId, Map<String, dynamic> data) {
    return Document(
      id: documentId,
      userId: data['user_id'] ?? '',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      htmlContent: data['html_content'] ?? '',
      createdAt: data['created_at']?.toDate() ?? DateTime.now(),
      updatedAt: data['updated_at']?.toDate() ?? DateTime.now(),
      thumbnail: data['thumbnail'] ?? '📄',
      status: DocumentStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => DocumentStatus.draft,
      ),
      tags: List<String>.from(data['tags'] ?? []),
      templateId: data['template_id'],
      version: data['version'] ?? 1,
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(updatedAt);

    if (difference.inDays == 0) {
      return '今日';
    } else if (difference.inDays == 1) {
      return '昨日';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}日前';
    } else {
      return '${updatedAt.year}年${updatedAt.month}月${updatedAt.day}日';
    }
  }

  String get statusText {
    switch (status) {
      case DocumentStatus.draft:
        return '下書き';
      case DocumentStatus.inReview:
        return 'レビュー中';
      case DocumentStatus.published:
        return '配信済み';
      case DocumentStatus.scheduled:
        return '配信予約';
      case DocumentStatus.archived:
        return 'アーカイブ';
    }
  }
}

enum DocumentStatus {
  draft, // 下書き
  inReview, // レビュー中
  published, // 配信済み
  scheduled, // 配信予約
  archived, // アーカイブ
}
