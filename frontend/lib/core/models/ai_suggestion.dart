/// AI提案のデータモデル
class AISuggestion {
  /// 提案されたテキスト内容
  final String text;

  /// 提案の信頼度（0.0～1.0）
  final double confidence;

  /// 提案の説明・理由
  final String explanation;

  /// 提案のタイプ
  final String? type;

  /// 提案の作成日時
  final DateTime createdAt;

  AISuggestion({
    required this.text,
    required this.confidence,
    required this.explanation,
    this.type,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Map からAISuggestionを作成
  factory AISuggestion.fromMap(Map<String, dynamic> map) {
    return AISuggestion(
      text: map['text'] as String? ?? '',
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0.0,
      explanation: map['explanation'] as String? ?? '',
      type: map['type'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
    );
  }

  /// AISuggestionをMapに変換
  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'confidence': confidence,
      'explanation': explanation,
      'type': type,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// JSON文字列からAISuggestionを作成
  factory AISuggestion.fromJson(String source) {
    return AISuggestion.fromMap(Map<String, dynamic>.from(
        Map<String, dynamic>.from(Map<String, dynamic>.from(source as Map))));
  }

  /// AISuggestionをJSON文字列に変換
  String toJson() {
    return toMap().toString();
  }

  /// コピーを作成（一部のフィールドを変更）
  AISuggestion copyWith({
    String? text,
    double? confidence,
    String? explanation,
    String? type,
    DateTime? createdAt,
  }) {
    return AISuggestion(
      text: text ?? this.text,
      confidence: confidence ?? this.confidence,
      explanation: explanation ?? this.explanation,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'AISuggestion(text: $text, confidence: $confidence, explanation: $explanation, type: $type, createdAt: $createdAt)';
  }

  @override
  bool operator ==(covariant AISuggestion other) {
    if (identical(this, other)) return true;

    return other.text == text &&
        other.confidence == confidence &&
        other.explanation == explanation &&
        other.type == type &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return text.hashCode ^
        confidence.hashCode ^
        explanation.hashCode ^
        type.hashCode ^
        createdAt.hashCode;
  }
}
