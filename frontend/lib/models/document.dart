class Document {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String thumbnail;
  final DocumentStatus status;
  final String? content;
  final int? views;

  Document({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.thumbnail,
    required this.status,
    this.content,
    this.views,
  });

  Document copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? thumbnail,
    DocumentStatus? status,
    String? content,
    int? views,
  }) {
    return Document(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      thumbnail: thumbnail ?? this.thumbnail,
      status: status ?? this.status,
      content: content ?? this.content,
      views: views ?? this.views,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'thumbnail': thumbnail,
      'status': status.name,
      'content': content,
      'views': views,
    };
  }

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'],
      title: json['title'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      thumbnail: json['thumbnail'],
      status: DocumentStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => DocumentStatus.draft,
      ),
      content: json['content'],
      views: json['views'],
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
  draft,     // 下書き
  published, // 配信済み
  scheduled, // 配信予約
  archived,  // アーカイブ
} 