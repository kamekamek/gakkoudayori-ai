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
      usageCount: (json['usageCount'] as num?)?.toInt() ?? 0,
      lastUsed: json['lastUsed'] == null
          ? null
          : DateTime.parse(json['lastUsed'] as String),
    );

Map<String, dynamic> _$TitleTemplateToJson(TitleTemplate instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'pattern': instance.pattern,
      'category': instance.category,
      'usageCount': instance.usageCount,
      'lastUsed': instance.lastUsed?.toIso8601String(),
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
      defaultPattern: json['defaultPattern'] as String? ?? '○年○組 学級通信',
      autoNumbering: json['autoNumbering'] as bool? ?? true,
      currentNumber: (json['currentNumber'] as num?)?.toInt() ?? 1,
    );

Map<String, dynamic> _$TitleTemplatesToJson(TitleTemplates instance) =>
    <String, dynamic>{
      'primary': instance.primary,
      'seasonal': instance.seasonal,
      'custom': instance.custom,
      'defaultPattern': instance.defaultPattern,
      'autoNumbering': instance.autoNumbering,
      'currentNumber': instance.currentNumber,
    };

UIPreferences _$UIPreferencesFromJson(Map<String, dynamic> json) =>
    UIPreferences(
      showTitleField: json['showTitleField'] as bool? ?? false,
      autoGenerateTitle: json['autoGenerateTitle'] as bool? ?? true,
      imageUploadLocation: json['imageUploadLocation'] as String? ?? 'chat',
      theme: json['theme'] as String? ?? 'default',
      language: json['language'] as String? ?? 'ja',
    );

Map<String, dynamic> _$UIPreferencesToJson(UIPreferences instance) =>
    <String, dynamic>{
      'showTitleField': instance.showTitleField,
      'autoGenerateTitle': instance.autoGenerateTitle,
      'imageUploadLocation': instance.imageUploadLocation,
      'theme': instance.theme,
      'language': instance.language,
    };

NotificationSettings _$NotificationSettingsFromJson(
        Map<String, dynamic> json) =>
    NotificationSettings(
      emailNotifications: json['emailNotifications'] as bool? ?? true,
      browserNotifications: json['browserNotifications'] as bool? ?? false,
      reminderFrequency: json['reminderFrequency'] as String? ?? 'weekly',
      quietHoursStart: json['quietHoursStart'] as String? ?? '22:00',
      quietHoursEnd: json['quietHoursEnd'] as String? ?? '08:00',
    );

Map<String, dynamic> _$NotificationSettingsToJson(
        NotificationSettings instance) =>
    <String, dynamic>{
      'emailNotifications': instance.emailNotifications,
      'browserNotifications': instance.browserNotifications,
      'reminderFrequency': instance.reminderFrequency,
      'quietHoursStart': instance.quietHoursStart,
      'quietHoursEnd': instance.quietHoursEnd,
    };

WorkflowSettings _$WorkflowSettingsFromJson(Map<String, dynamic> json) =>
    WorkflowSettings(
      autoSaveInterval: (json['autoSaveInterval'] as num?)?.toInt() ?? 30,
      draftRetentionDays: (json['draftRetentionDays'] as num?)?.toInt() ?? 30,
      backupEnabled: json['backupEnabled'] as bool? ?? true,
      collaborationMode: json['collaborationMode'] as bool? ?? false,
    );

Map<String, dynamic> _$WorkflowSettingsToJson(WorkflowSettings instance) =>
    <String, dynamic>{
      'autoSaveInterval': instance.autoSaveInterval,
      'draftRetentionDays': instance.draftRetentionDays,
      'backupEnabled': instance.backupEnabled,
      'collaborationMode': instance.collaborationMode,
    };

UserSettings _$UserSettingsFromJson(Map<String, dynamic> json) => UserSettings(
      schoolName: json['schoolName'] as String,
      className: json['className'] as String,
      teacherName: json['teacherName'] as String,
      titleTemplates: TitleTemplates.fromJson(
          json['titleTemplates'] as Map<String, dynamic>),
      uiPreferences:
          UIPreferences.fromJson(json['uiPreferences'] as Map<String, dynamic>),
      notificationSettings: NotificationSettings.fromJson(
          json['notificationSettings'] as Map<String, dynamic>),
      workflowSettings: WorkflowSettings.fromJson(
          json['workflowSettings'] as Map<String, dynamic>),
      version: json['version'] as String? ?? '2.0',
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$UserSettingsToJson(UserSettings instance) =>
    <String, dynamic>{
      'schoolName': instance.schoolName,
      'className': instance.className,
      'teacherName': instance.teacherName,
      'titleTemplates': instance.titleTemplates,
      'uiPreferences': instance.uiPreferences,
      'notificationSettings': instance.notificationSettings,
      'workflowSettings': instance.workflowSettings,
      'version': instance.version,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

UserSettingsResponse _$UserSettingsResponseFromJson(
        Map<String, dynamic> json) =>
    UserSettingsResponse(
      settings: json['settings'] == null
          ? null
          : UserSettings.fromJson(json['settings'] as Map<String, dynamic>),
      isComplete: json['isComplete'] as bool,
      missingFields: (json['missingFields'] as List<dynamic>?)
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
      'isComplete': instance.isComplete,
      'missingFields': instance.missingFields,
      'suggestions': instance.suggestions,
    };

TitleSuggestion _$TitleSuggestionFromJson(Map<String, dynamic> json) =>
    TitleSuggestion(
      title: json['title'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      source: json['source'] as String,
      templateUsed: json['templateUsed'] as String?,
    );

Map<String, dynamic> _$TitleSuggestionToJson(TitleSuggestion instance) =>
    <String, dynamic>{
      'title': instance.title,
      'confidence': instance.confidence,
      'source': instance.source,
      'templateUsed': instance.templateUsed,
    };

TitleSuggestionRequest _$TitleSuggestionRequestFromJson(
        Map<String, dynamic> json) =>
    TitleSuggestionRequest(
      contentHint: json['contentHint'] as String?,
      eventType: json['eventType'] as String?,
      season: json['season'] as String?,
      urgency: json['urgency'] as String? ?? 'normal',
    );

Map<String, dynamic> _$TitleSuggestionRequestToJson(
        TitleSuggestionRequest instance) =>
    <String, dynamic>{
      'contentHint': instance.contentHint,
      'eventType': instance.eventType,
      'season': instance.season,
      'urgency': instance.urgency,
    };
