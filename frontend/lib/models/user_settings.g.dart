// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TitleTemplate _$TitleTemplateFromJson(Map<String, dynamic> json) =>
    TitleTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      pattern: json['pattern'] as String,
      category: json['category'] as String? ?? 'custom',
      usageCount: (json['usage_count'] as num?)?.toInt() ?? 0,
      lastUsed: json['last_used'] == null
          ? null
          : DateTime.parse(json['last_used'] as String),
    );

Map<String, dynamic> _$TitleTemplateToJson(TitleTemplate instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'pattern': instance.pattern,
      'category': instance.category,
      'usage_count': instance.usageCount,
      'last_used': instance.lastUsed?.toIso8601String(),
    };

TitleTemplates _$TitleTemplatesFromJson(Map<String, dynamic> json) =>
    TitleTemplates(
      primary: json['primary'] as String? ?? '学級だより○号',
      seasonal: (json['seasonal'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const ['夏休み号', '冬休み号', '運動会号'],
      custom: (json['custom'] as List<dynamic>?)
              ?.map((e) => TitleTemplate.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      defaultPattern: json['default_pattern'] as String? ?? '○年○組 学級通信',
      autoNumbering: json['auto_numbering'] as bool? ?? true,
      currentNumber: (json['current_number'] as num?)?.toInt() ?? 1,
    );

Map<String, dynamic> _$TitleTemplatesToJson(TitleTemplates instance) =>
    <String, dynamic>{
      'primary': instance.primary,
      'seasonal': instance.seasonal,
      'custom': instance.custom,
      'default_pattern': instance.defaultPattern,
      'auto_numbering': instance.autoNumbering,
      'current_number': instance.currentNumber,
    };

UIPreferences _$UIPreferencesFromJson(Map<String, dynamic> json) =>
    UIPreferences(
      showTitleField: json['show_title_field'] as bool? ?? false,
      autoGenerateTitle: json['auto_generate_title'] as bool? ?? true,
      imageUploadLocation: json['image_upload_location'] as String? ?? 'chat',
      theme: json['theme'] as String? ?? 'default',
      language: json['language'] as String? ?? 'ja',
    );

Map<String, dynamic> _$UIPreferencesToJson(UIPreferences instance) =>
    <String, dynamic>{
      'show_title_field': instance.showTitleField,
      'auto_generate_title': instance.autoGenerateTitle,
      'image_upload_location': instance.imageUploadLocation,
      'theme': instance.theme,
      'language': instance.language,
    };

NotificationSettings _$NotificationSettingsFromJson(
        Map<String, dynamic> json) =>
    NotificationSettings(
      emailNotifications: json['email_notifications'] as bool? ?? true,
      browserNotifications: json['browser_notifications'] as bool? ?? false,
      reminderFrequency: json['reminder_frequency'] as String? ?? 'weekly',
      quietHoursStart: json['quiet_hours_start'] as String? ?? '22:00',
      quietHoursEnd: json['quiet_hours_end'] as String? ?? '08:00',
    );

Map<String, dynamic> _$NotificationSettingsToJson(
        NotificationSettings instance) =>
    <String, dynamic>{
      'email_notifications': instance.emailNotifications,
      'browser_notifications': instance.browserNotifications,
      'reminder_frequency': instance.reminderFrequency,
      'quiet_hours_start': instance.quietHoursStart,
      'quiet_hours_end': instance.quietHoursEnd,
    };

WorkflowSettings _$WorkflowSettingsFromJson(Map<String, dynamic> json) =>
    WorkflowSettings(
      autoSaveInterval: (json['auto_save_interval'] as num?)?.toInt() ?? 30,
      draftRetentionDays: (json['draft_retention_days'] as num?)?.toInt() ?? 30,
      backupEnabled: json['backup_enabled'] as bool? ?? true,
      collaborationMode: json['collaboration_mode'] as bool? ?? false,
    );

Map<String, dynamic> _$WorkflowSettingsToJson(WorkflowSettings instance) =>
    <String, dynamic>{
      'auto_save_interval': instance.autoSaveInterval,
      'draft_retention_days': instance.draftRetentionDays,
      'backup_enabled': instance.backupEnabled,
      'collaboration_mode': instance.collaborationMode,
    };

UserSettings _$UserSettingsFromJson(Map<String, dynamic> json) => UserSettings(
      schoolName: json['school_name'] as String,
      className: json['class_name'] as String,
      teacherName: json['teacher_name'] as String,
      titleTemplates: TitleTemplates.fromJson(
          json['title_templates'] as Map<String, dynamic>),
      uiPreferences: UIPreferences.fromJson(
          json['ui_preferences'] as Map<String, dynamic>),
      notificationSettings: NotificationSettings.fromJson(
          json['notification_settings'] as Map<String, dynamic>),
      workflowSettings: WorkflowSettings.fromJson(
          json['workflow_settings'] as Map<String, dynamic>),
      version: json['version'] as String? ?? '2.0',
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$UserSettingsToJson(UserSettings instance) =>
    <String, dynamic>{
      'school_name': instance.schoolName,
      'class_name': instance.className,
      'teacher_name': instance.teacherName,
      'title_templates': instance.titleTemplates,
      'ui_preferences': instance.uiPreferences,
      'notification_settings': instance.notificationSettings,
      'workflow_settings': instance.workflowSettings,
      'version': instance.version,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };

UserSettingsResponse _$UserSettingsResponseFromJson(
        Map<String, dynamic> json) =>
    UserSettingsResponse(
      settings: json['settings'] == null
          ? null
          : UserSettings.fromJson(json['settings'] as Map<String, dynamic>),
      isComplete: json['is_complete'] as bool,
      missingFields: (json['missing_fields'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      suggestions: (json['suggestions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$UserSettingsResponseToJson(
        UserSettingsResponse instance) =>
    <String, dynamic>{
      'settings': instance.settings,
      'is_complete': instance.isComplete,
      'missing_fields': instance.missingFields,
      'suggestions': instance.suggestions,
    };

TitleSuggestion _$TitleSuggestionFromJson(Map<String, dynamic> json) =>
    TitleSuggestion(
      title: json['title'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      source: json['source'] as String,
      templateUsed: json['template_used'] as String?,
    );

Map<String, dynamic> _$TitleSuggestionToJson(TitleSuggestion instance) =>
    <String, dynamic>{
      'title': instance.title,
      'confidence': instance.confidence,
      'source': instance.source,
      'template_used': instance.templateUsed,
    };

TitleSuggestionRequest _$TitleSuggestionRequestFromJson(
        Map<String, dynamic> json) =>
    TitleSuggestionRequest(
      contentHint: json['content_hint'] as String?,
      eventType: json['event_type'] as String?,
      season: json['season'] as String?,
      urgency: json['urgency'] as String? ?? 'normal',
    );

Map<String, dynamic> _$TitleSuggestionRequestToJson(
        TitleSuggestionRequest instance) =>
    <String, dynamic>{
      'content_hint': instance.contentHint,
      'event_type': instance.eventType,
      'season': instance.season,
      'urgency': instance.urgency,
    };
