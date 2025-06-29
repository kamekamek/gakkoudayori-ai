import 'package:json_annotation/json_annotation.dart';

part 'user_settings.g.dart';

@JsonSerializable()
class TitleTemplate {
  final String id;
  final String name;
  final String pattern;
  final String category;
  @JsonKey(name: 'usage_count')
  final int usageCount;
  @JsonKey(name: 'last_used')
  final DateTime? lastUsed;

  TitleTemplate({
    required this.id,
    required this.name,
    required this.pattern,
    this.category = 'custom',
    this.usageCount = 0,
    this.lastUsed,
  });

  factory TitleTemplate.fromJson(Map<String, dynamic> json) =>
      _$TitleTemplateFromJson(json);
  Map<String, dynamic> toJson() => _$TitleTemplateToJson(this);

  TitleTemplate copyWith({
    String? id,
    String? name,
    String? pattern,
    String? category,
    int? usageCount,
    DateTime? lastUsed,
  }) {
    return TitleTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      pattern: pattern ?? this.pattern,
      category: category ?? this.category,
      usageCount: usageCount ?? this.usageCount,
      lastUsed: lastUsed ?? this.lastUsed,
    );
  }
}

@JsonSerializable()
class TitleTemplates {
  final String primary;
  final List<String> seasonal;
  final List<TitleTemplate> custom;
  @JsonKey(name: 'default_pattern')
  final String defaultPattern;
  @JsonKey(name: 'auto_numbering')
  final bool autoNumbering;
  @JsonKey(name: 'current_number')
  final int currentNumber;

  TitleTemplates({
    this.primary = '学級だより○号',
    this.seasonal = const ['夏休み号', '冬休み号', '運動会号'],
    this.custom = const [],
    this.defaultPattern = '○年○組 学級通信',
    this.autoNumbering = true,
    this.currentNumber = 1,
  });

  factory TitleTemplates.fromJson(Map<String, dynamic> json) =>
      _$TitleTemplatesFromJson(json);
  Map<String, dynamic> toJson() => _$TitleTemplatesToJson(this);

  TitleTemplates copyWith({
    String? primary,
    List<String>? seasonal,
    List<TitleTemplate>? custom,
    String? defaultPattern,
    bool? autoNumbering,
    int? currentNumber,
  }) {
    return TitleTemplates(
      primary: primary ?? this.primary,
      seasonal: seasonal ?? this.seasonal,
      custom: custom ?? this.custom,
      defaultPattern: defaultPattern ?? this.defaultPattern,
      autoNumbering: autoNumbering ?? this.autoNumbering,
      currentNumber: currentNumber ?? this.currentNumber,
    );
  }
}

@JsonSerializable()
class UIPreferences {
  @JsonKey(name: 'show_title_field')
  final bool showTitleField;
  @JsonKey(name: 'auto_generate_title')
  final bool autoGenerateTitle;
  @JsonKey(name: 'image_upload_location')
  final String imageUploadLocation;
  final String theme;
  final String language;

  UIPreferences({
    this.showTitleField = false,
    this.autoGenerateTitle = true,
    this.imageUploadLocation = 'chat',
    this.theme = 'default',
    this.language = 'ja',
  });

  factory UIPreferences.fromJson(Map<String, dynamic> json) =>
      _$UIPreferencesFromJson(json);
  Map<String, dynamic> toJson() => _$UIPreferencesToJson(this);

  UIPreferences copyWith({
    bool? showTitleField,
    bool? autoGenerateTitle,
    String? imageUploadLocation,
    String? theme,
    String? language,
  }) {
    return UIPreferences(
      showTitleField: showTitleField ?? this.showTitleField,
      autoGenerateTitle: autoGenerateTitle ?? this.autoGenerateTitle,
      imageUploadLocation: imageUploadLocation ?? this.imageUploadLocation,
      theme: theme ?? this.theme,
      language: language ?? this.language,
    );
  }
}

@JsonSerializable()
class NotificationSettings {
  @JsonKey(name: 'email_notifications')
  final bool emailNotifications;
  @JsonKey(name: 'browser_notifications')
  final bool browserNotifications;
  @JsonKey(name: 'reminder_frequency')
  final String reminderFrequency;
  @JsonKey(name: 'quiet_hours_start')
  final String? quietHoursStart;
  @JsonKey(name: 'quiet_hours_end')
  final String? quietHoursEnd;

  NotificationSettings({
    this.emailNotifications = true,
    this.browserNotifications = false,
    this.reminderFrequency = 'weekly',
    this.quietHoursStart = '22:00',
    this.quietHoursEnd = '08:00',
  });

  factory NotificationSettings.fromJson(Map<String, dynamic> json) =>
      _$NotificationSettingsFromJson(json);
  Map<String, dynamic> toJson() => _$NotificationSettingsToJson(this);
}

@JsonSerializable()
class WorkflowSettings {
  @JsonKey(name: 'auto_save_interval')
  final int autoSaveInterval;
  @JsonKey(name: 'draft_retention_days')
  final int draftRetentionDays;
  @JsonKey(name: 'backup_enabled')
  final bool backupEnabled;
  @JsonKey(name: 'collaboration_mode')
  final bool collaborationMode;

  WorkflowSettings({
    this.autoSaveInterval = 30,
    this.draftRetentionDays = 30,
    this.backupEnabled = true,
    this.collaborationMode = false,
  });

  factory WorkflowSettings.fromJson(Map<String, dynamic> json) =>
      _$WorkflowSettingsFromJson(json);
  Map<String, dynamic> toJson() => _$WorkflowSettingsToJson(this);
}

@JsonSerializable()
class UserSettings {
  @JsonKey(name: 'school_name')
  final String schoolName;
  @JsonKey(name: 'class_name')
  final String className;
  @JsonKey(name: 'teacher_name')
  final String teacherName;
  @JsonKey(name: 'title_templates')
  final TitleTemplates titleTemplates;
  @JsonKey(name: 'ui_preferences')
  final UIPreferences uiPreferences;
  @JsonKey(name: 'notification_settings')
  final NotificationSettings notificationSettings;
  @JsonKey(name: 'workflow_settings')
  final WorkflowSettings workflowSettings;
  final String version;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  UserSettings({
    required this.schoolName,
    required this.className,
    required this.teacherName,
    required this.titleTemplates,
    required this.uiPreferences,
    required this.notificationSettings,
    required this.workflowSettings,
    this.version = '2.0',
    this.createdAt,
    this.updatedAt,
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) =>
      _$UserSettingsFromJson(json);
  Map<String, dynamic> toJson() => _$UserSettingsToJson(this);

  UserSettings copyWith({
    String? schoolName,
    String? className,
    String? teacherName,
    TitleTemplates? titleTemplates,
    UIPreferences? uiPreferences,
    NotificationSettings? notificationSettings,
    WorkflowSettings? workflowSettings,
    String? version,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserSettings(
      schoolName: schoolName ?? this.schoolName,
      className: className ?? this.className,
      teacherName: teacherName ?? this.teacherName,
      titleTemplates: titleTemplates ?? this.titleTemplates,
      uiPreferences: uiPreferences ?? this.uiPreferences,
      notificationSettings: notificationSettings ?? this.notificationSettings,
      workflowSettings: workflowSettings ?? this.workflowSettings,
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 設定が完了しているかどうかを判定
  bool get isComplete {
    return schoolName.isNotEmpty &&
           className.isNotEmpty &&
           teacherName.isNotEmpty;
  }

  /// 不足している設定フィールドを取得
  List<String> get missingFields {
    List<String> missing = [];
    if (schoolName.isEmpty) missing.add('schoolName');
    if (className.isEmpty) missing.add('className');
    if (teacherName.isEmpty) missing.add('teacherName');
    return missing;
  }
}

@JsonSerializable()
class UserSettingsResponse {
  final UserSettings? settings;
  @JsonKey(name: 'is_complete')
  final bool isComplete;
  @JsonKey(name: 'missing_fields')
  final List<String> missingFields;
  final List<String> suggestions;

  UserSettingsResponse({
    this.settings,
    required this.isComplete,
    this.missingFields = const [],
    this.suggestions = const [],
  });

  factory UserSettingsResponse.fromJson(Map<String, dynamic> json) =>
      _$UserSettingsResponseFromJson(json);
  Map<String, dynamic> toJson() => _$UserSettingsResponseToJson(this);
}

@JsonSerializable()
class TitleSuggestion {
  final String title;
  final double confidence;
  final String source;
  @JsonKey(name: 'template_used')
  final String? templateUsed;

  TitleSuggestion({
    required this.title,
    required this.confidence,
    required this.source,
    this.templateUsed,
  });

  factory TitleSuggestion.fromJson(Map<String, dynamic> json) =>
      _$TitleSuggestionFromJson(json);
  Map<String, dynamic> toJson() => _$TitleSuggestionToJson(this);
}

@JsonSerializable()
class TitleSuggestionRequest {
  @JsonKey(name: 'content_hint')
  final String? contentHint;
  @JsonKey(name: 'event_type')
  final String? eventType;
  final String? season;
  final String urgency;

  TitleSuggestionRequest({
    this.contentHint,
    this.eventType,
    this.season,
    this.urgency = 'normal',
  });

  factory TitleSuggestionRequest.fromJson(Map<String, dynamic> json) =>
      _$TitleSuggestionRequestFromJson(json);
  Map<String, dynamic> toJson() => _$TitleSuggestionRequestToJson(this);
}