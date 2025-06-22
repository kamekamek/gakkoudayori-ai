import 'dart:typed_data';

import 'image_file.dart';

/// 学級通信のデータモデル
class Newsletter {
  final String id;
  final String title;
  final String content; // HTML content
  final NewsletterStyle style;
  final List<ImageFile> images;
  final NewsletterMetadata metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
  final NewsletterStatus status;

  Newsletter({
    required this.id,
    required this.title,
    required this.content,
    required this.style,
    this.images = const [],
    required this.metadata,
    required this.createdAt,
    required this.updatedAt,
    this.status = NewsletterStatus.draft,
  });

  Newsletter copyWith({
    String? id,
    String? title,
    String? content,
    NewsletterStyle? style,
    List<ImageFile>? images,
    NewsletterMetadata? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    NewsletterStatus? status,
  }) {
    return Newsletter(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      style: style ?? this.style,
      images: images ?? this.images,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'style': style.name,
      'images': images.map((img) => img.toJson()).toList(),
      'metadata': metadata.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'status': status.name,
    };
  }

  factory Newsletter.fromJson(Map<String, dynamic> json) {
    return Newsletter(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      style: NewsletterStyle.values.firstWhere(
        (e) => e.name == json['style'],
        orElse: () => NewsletterStyle.classic,
      ),
      images: (json['images'] as List<dynamic>?)
          ?.map((img) => ImageFile.fromJson(img))
          .toList() ?? [],
      metadata: NewsletterMetadata.fromJson(json['metadata']),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      status: NewsletterStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => NewsletterStatus.draft,
      ),
    );
  }
}

/// 学級通信のスタイル
enum NewsletterStyle {
  classic,  // クラシック（伝統的な学校スタイル）
  modern,   // モダン（現代的でスタイリッシュ）
}

/// 学級通信のステータス
enum NewsletterStatus {
  draft,      // 下書き
  generating, // AI生成中
  review,     // レビュー中
  completed,  // 完成
  published,  // 公開済み（Classroom投稿済み）
  archived,   // アーカイブ済み
}

/// 学級通信のメタデータ
class NewsletterMetadata {
  final String schoolName;
  final String className;
  final String teacherName;
  final String? topic; // 主要なトピック
  final List<String> tags; // タグ
  final String? originalText; // 元の音声入力テキスト

  NewsletterMetadata({
    required this.schoolName,
    required this.className,
    required this.teacherName,
    this.topic,
    this.tags = const [],
    this.originalText,
  });

  NewsletterMetadata copyWith({
    String? schoolName,
    String? className,
    String? teacherName,
    String? topic,
    List<String>? tags,
    String? originalText,
  }) {
    return NewsletterMetadata(
      schoolName: schoolName ?? this.schoolName,
      className: className ?? this.className,
      teacherName: teacherName ?? this.teacherName,
      topic: topic ?? this.topic,
      tags: tags ?? this.tags,
      originalText: originalText ?? this.originalText,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'schoolName': schoolName,
      'className': className,
      'teacherName': teacherName,
      'topic': topic,
      'tags': tags,
      'originalText': originalText,
    };
  }

  factory NewsletterMetadata.fromJson(Map<String, dynamic> json) {
    return NewsletterMetadata(
      schoolName: json['schoolName'],
      className: json['className'],
      teacherName: json['teacherName'],
      topic: json['topic'],
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      originalText: json['originalText'],
    );
  }
}

/// プレビューモード
enum PreviewMode {
  preview,    // 読み取り専用プレビュー
  edit,       // 編集モード
  printView,  // 印刷ビュー
  classroom,  // Classroom投稿プレビュー
}

/// PDF生成の設定
class PdfGenerationSettings {
  final String pageSize; // A4, A3, etc.
  final bool includeImages;
  final bool highQuality;
  final String? watermark;

  const PdfGenerationSettings({
    this.pageSize = 'A4',
    this.includeImages = true,
    this.highQuality = true,
    this.watermark,
  });
}

/// PDF生成結果
class PdfGenerationResult {
  final bool success;
  final Uint8List? pdfData;
  final String? fileName;
  final String? error;
  final int? fileSize;

  PdfGenerationResult({
    required this.success,
    this.pdfData,
    this.fileName,
    this.error,
    this.fileSize,
  });

  String? get formattedFileSize {
    if (fileSize == null) return null;
    if (fileSize! < 1024) return '${fileSize!}B';
    if (fileSize! < 1024 * 1024) return '${(fileSize! / 1024).toStringAsFixed(1)}KB';
    return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}