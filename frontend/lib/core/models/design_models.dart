/// デザイン修正タイプ
enum DesignModificationType {
  color,    // 色変更
  layout,   // レイアウト変更
  font,     // フォント変更
  content,  // コンテンツ変更
}

/// デザイン修正要求
class DesignModificationRequest {
  final String id;
  final String description;
  final DesignModificationType? modificationType;
  final Map<String, dynamic> parameters;
  final DateTime createdAt;

  DesignModificationRequest({
    required this.id,
    required this.description,
    this.modificationType,
    this.parameters = const {},
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'modification_type': modificationType?.name,
      'parameters': parameters,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory DesignModificationRequest.fromJson(Map<String, dynamic> json) {
    return DesignModificationRequest(
      id: json['id'],
      description: json['description'],
      modificationType: _parseModificationType(json['modification_type']),
      parameters: json['parameters'] ?? {},
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  static DesignModificationType? _parseModificationType(String? type) {
    if (type == null) return null;
    switch (type.toLowerCase()) {
      case 'color':
        return DesignModificationType.color;
      case 'layout':
        return DesignModificationType.layout;
      case 'font':
        return DesignModificationType.font;
      case 'content':
        return DesignModificationType.content;
      default:
        return null;
    }
  }
}

/// デザインサジェスチョン
class DesignSuggestion {
  final String id;
  final String title;
  final String description;
  final DesignModificationType type;
  final Map<String, dynamic> changes;
  final String previewImageUrl;

  DesignSuggestion({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.changes,
    required this.previewImageUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.name,
      'changes': changes,
      'preview_image_url': previewImageUrl,
    };
  }

  factory DesignSuggestion.fromJson(Map<String, dynamic> json) {
    return DesignSuggestion(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      type: DesignModificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => DesignModificationType.layout,
      ),
      changes: json['changes'],
      previewImageUrl: json['preview_image_url'],
    );
  }
}

/// デザイン修正結果
class DesignModificationResult {
  final String id;
  final bool success;
  final String? modifiedHtml;
  final List<DesignSuggestion> suggestions;
  final String? error;
  final DesignModificationType modificationType;

  DesignModificationResult({
    required this.id,
    required this.success,
    this.modifiedHtml,
    this.suggestions = const [],
    this.error,
    required this.modificationType,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'success': success,
      'modified_html': modifiedHtml,
      'suggestions': suggestions.map((s) => s.toJson()).toList(),
      'error': error,
      'modification_type': modificationType.name,
    };
  }

  factory DesignModificationResult.fromJson(Map<String, dynamic> json) {
    return DesignModificationResult(
      id: json['id'],
      success: json['success'],
      modifiedHtml: json['modified_html'],
      suggestions: (json['suggestions'] as List<dynamic>?)
          ?.map((s) => DesignSuggestion.fromJson(s))
          .toList() ?? [],
      error: json['error'],
      modificationType: DesignModificationType.values.firstWhere(
        (e) => e.name == json['modification_type'],
        orElse: () => DesignModificationType.layout,
      ),
    );
  }
}