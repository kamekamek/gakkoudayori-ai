import 'package:cloud_firestore/cloud_firestore.dart';

/// 学級通信ドキュメントのデータモデル
/// 
/// 設計書「docs/01_REQUIREMENT_overview.md」の
/// Firestore: `/letters/{documentId}` 仕様に準拠
class DocumentData {
  final String documentId;
  final String title;
  final String author;
  final String grade;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DocumentStatus status;
  final String aiVersion;
  final List<String> sections;
  final String? htmlContent; // Storage URL or content
  final String? deltaContent; // Quill Delta JSON

  const DocumentData({
    required this.documentId,
    required this.title,
    required this.author,
    required this.grade,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
    required this.aiVersion,
    required this.sections,
    this.htmlContent,
    this.deltaContent,
  });

  /// Firestoreドキュメントから DocumentData を作成
  factory DocumentData.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data()!;
    return DocumentData(
      documentId: snapshot.id,
      title: data['title'] as String,
      author: data['author'] as String,
      grade: data['grade'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      status: DocumentStatus.fromString(data['status'] as String),
      aiVersion: data['aiVersion'] as String,
      sections: List<String>.from(data['sections'] as List),
      htmlContent: data['htmlContent'] as String?,
      deltaContent: data['deltaContent'] as String?,
    );
  }

  /// Firestore保存用のMap形式に変換
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'author': author,
      'grade': grade,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'status': status.value,
      'aiVersion': aiVersion,
      'sections': sections,
      if (htmlContent != null) 'htmlContent': htmlContent,
      if (deltaContent != null) 'deltaContent': deltaContent,
    };
  }

  /// JSON形式から DocumentData を作成（API通信用）
  factory DocumentData.fromJson(Map<String, dynamic> json) {
    return DocumentData(
      documentId: json['documentId'] as String,
      title: json['title'] as String,
      author: json['author'] as String,
      grade: json['grade'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      status: DocumentStatus.fromString(json['status'] as String),
      aiVersion: json['aiVersion'] as String,
      sections: List<String>.from(json['sections'] as List),
      htmlContent: json['htmlContent'] as String?,
      deltaContent: json['deltaContent'] as String?,
    );
  }

  /// JSON形式に変換（API通信用）
  Map<String, dynamic> toJson() {
    return {
      'documentId': documentId,
      'title': title,
      'author': author,
      'grade': grade,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'status': status.value,
      'aiVersion': aiVersion,
      'sections': sections,
      if (htmlContent != null) 'htmlContent': htmlContent,
      if (deltaContent != null) 'deltaContent': deltaContent,
    };
  }

  /// コピーコンストラクタ
  DocumentData copyWith({
    String? documentId,
    String? title,
    String? author,
    String? grade,
    DateTime? createdAt,
    DateTime? updatedAt,
    DocumentStatus? status,
    String? aiVersion,
    List<String>? sections,
    String? htmlContent,
    String? deltaContent,
  }) {
    return DocumentData(
      documentId: documentId ?? this.documentId,
      title: title ?? this.title,
      author: author ?? this.author,
      grade: grade ?? this.grade,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      aiVersion: aiVersion ?? this.aiVersion,
      sections: sections ?? this.sections,
      htmlContent: htmlContent ?? this.htmlContent,
      deltaContent: deltaContent ?? this.deltaContent,
    );
  }

  /// ドキュメント更新（updatedAtを自動更新）
  DocumentData updated({
    String? title,
    String? author,
    String? grade,
    DocumentStatus? status,
    String? aiVersion,
    List<String>? sections,
    String? htmlContent,
    String? deltaContent,
  }) {
    return copyWith(
      title: title,
      author: author,
      grade: grade,
      status: status,
      aiVersion: aiVersion,
      sections: sections,
      htmlContent: htmlContent,
      deltaContent: deltaContent,
      updatedAt: DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is DocumentData &&
            runtimeType == other.runtimeType &&
            documentId == other.documentId &&
            title == other.title &&
            author == other.author &&
            grade == other.grade &&
            createdAt == other.createdAt &&
            updatedAt == other.updatedAt &&
            status == other.status &&
            aiVersion == other.aiVersion &&
            _listEquals(sections, other.sections) &&
            htmlContent == other.htmlContent &&
            deltaContent == other.deltaContent;
  }

  @override
  int get hashCode {
    return Object.hash(
      documentId,
      title,
      author,
      grade,
      createdAt,
      updatedAt,
      status,
      aiVersion,
      Object.hashAll(sections),
      htmlContent,
      deltaContent,
    );
  }

  @override
  String toString() {
    return 'DocumentData{'
        'documentId: $documentId, '
        'title: $title, '
        'author: $author, '
        'grade: $grade, '
        'status: $status, '
        'sections: ${sections.length}, '
        'updatedAt: $updatedAt'
        '}';
  }

  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }
}

/// ドキュメントの状態を表すEnum
enum DocumentStatus {
  draft('draft'),
  published('published'),
  archived('archived');

  const DocumentStatus(this.value);

  final String value;

  static DocumentStatus fromString(String value) {
    return DocumentStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => DocumentStatus.draft,
    );
  }

  @override
  String toString() => value;
}

/// 新規ドキュメント作成用のファクトリ
class DocumentDataFactory {
  /// 新規学級通信ドキュメントを作成
  static DocumentData createNew({
    String? documentId,
    required String title,
    required String author,
    required String grade,
    List<String>? sections,
    String aiVersion = 'gemini-pro-v1.5',
  }) {
    final now = DateTime.now();
    return DocumentData(
      documentId: documentId ?? _generateDocumentId(),
      title: title,
      author: author,
      grade: grade,
      createdAt: now,
      updatedAt: now,
      status: DocumentStatus.draft,
      aiVersion: aiVersion,
      sections: sections ?? [],
    );
  }

  /// ドキュメントIDを生成（UUID風）
  static String _generateDocumentId() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'doc_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_$random';
  }

  /// テンプレートから学級通信を作成
  static DocumentData fromTemplate({
    required String title,
    required String author,
    required String grade,
    required DocumentTemplate template,
  }) {
    return createNew(
      title: title,
      author: author,
      grade: grade,
      sections: template.defaultSections,
    );
  }
}

/// 学級通信テンプレート
enum DocumentTemplate {
  monthly('月刊通信', ['今月の振り返り', '来月の予定', 'お知らせ']),
  event('行事通信', ['行事概要', '準備物', '当日のスケジュール', '注意事項']),
  weekly('週刊通信', ['今週の学習', '来週の予定', '連絡事項']),
  seasonal('季節通信', ['季節の話題', '学習活動', '家庭でのお願い']);

  const DocumentTemplate(this.displayName, this.defaultSections);

  final String displayName;
  final List<String> defaultSections;
}