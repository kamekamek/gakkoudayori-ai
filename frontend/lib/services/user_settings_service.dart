import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/user_settings.dart';

class UserSettingsService {
  static const String baseUrl = kDebugMode 
      ? 'http://localhost:8081/api/v1' 
      : 'https://your-production-url.com/api/v1';

  final http.Client _client;
  String? _authToken;

  UserSettingsService({http.Client? client}) : _client = client ?? http.Client();

  /// 認証トークンを設定
  void setAuthToken(String token) {
    _authToken = token;
  }

  /// 認証ヘッダーを取得
  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  /// エラーハンドリング用のヘルパー
  Exception _handleError(String operation, http.Response response) {
    final errorMessage = 'Failed to $operation: ${response.statusCode} ${response.reasonPhrase}';
    if (kDebugMode) {
      print('UserSettingsService Error: $errorMessage');
      print('Response body: ${response.body}');
    }
    return Exception(errorMessage);
  }

  /// ユーザー設定を取得
  Future<UserSettingsResponse?> getUserSettings() async {
    try {
      if (kDebugMode) {
        debugPrint('🔐 UserSettingsService: 認証ヘッダー = ${_headers.containsKey('Authorization') ? 'あり' : 'なし'}');
        if (_headers.containsKey('Authorization')) {
          debugPrint('🔐 Authorization header: ${_headers['Authorization']?.substring(0, 20)}...');
        }
      }
      
      final response = await _client.get(
        Uri.parse('$baseUrl/users/settings'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return UserSettingsResponse.fromJson(jsonData);
      } else if (response.statusCode == 404) {
        // 設定が存在しない場合
        return null;
      } else {
        throw _handleError('get user settings', response);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user settings: $e');
      }
      rethrow;
    }
  }

  /// ユーザー設定を保存（存在しない場合は作成、存在する場合は更新）
  Future<UserSettingsResponse> saveUserSettings({
    required String schoolName,
    required String className,
    required String teacherName,
    TitleTemplates? titleTemplates,
    UIPreferences? uiPreferences,
    NotificationSettings? notificationSettings,
    WorkflowSettings? workflowSettings,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('🔐 UserSettingsService (save): 認証ヘッダー = ${_headers.containsKey('Authorization') ? 'あり' : 'なし'}');
      }
      
      // まず既存設定を確認
      final existingSettings = await getUserSettings();
      final isUpdate = existingSettings?.settings != null;
      
      final requestData = {
        'school_name': schoolName,
        'class_name': className,
        'teacher_name': teacherName,
        if (titleTemplates != null) 'title_templates': titleTemplates.toJson(),
        if (uiPreferences != null) 'ui_preferences': uiPreferences.toJson(),
        if (notificationSettings != null) 'notification_settings': notificationSettings.toJson(),
        if (workflowSettings != null) 'workflow_settings': workflowSettings.toJson(),
      };

      if (kDebugMode) {
        debugPrint('📝 UserSettingsService: ${isUpdate ? 'UPDATE' : 'CREATE'}を実行');
      }

      final response = isUpdate 
        ? await _client.put(
            Uri.parse('$baseUrl/users/settings'),
            headers: _headers,
            body: json.encode(requestData),
          )
        : await _client.post(
            Uri.parse('$baseUrl/users/settings'),
            headers: _headers,
            body: json.encode(requestData),
          );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = json.decode(response.body);
        return UserSettingsResponse.fromJson(jsonData);
      } else {
        throw _handleError('save user settings', response);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error saving user settings: $e');
      }
      rethrow;
    }
  }

  /// ユーザー設定を作成（従来のメソッド、後方互換性のため保持）
  Future<UserSettingsResponse> createUserSettings({
    required String schoolName,
    required String className,
    required String teacherName,
    TitleTemplates? titleTemplates,
    UIPreferences? uiPreferences,
    NotificationSettings? notificationSettings,
    WorkflowSettings? workflowSettings,
  }) async {
    return saveUserSettings(
      schoolName: schoolName,
      className: className,
      teacherName: teacherName,
      titleTemplates: titleTemplates,
      uiPreferences: uiPreferences,
      notificationSettings: notificationSettings,
      workflowSettings: workflowSettings,
    );
  }

  /// ユーザー設定を更新
  Future<UserSettingsResponse> updateUserSettings({
    String? schoolName,
    String? className,
    String? teacherName,
    TitleTemplates? titleTemplates,
    UIPreferences? uiPreferences,
    NotificationSettings? notificationSettings,
    WorkflowSettings? workflowSettings,
  }) async {
    try {
      final requestData = <String, dynamic>{};
      
      if (schoolName != null) requestData['school_name'] = schoolName;
      if (className != null) requestData['class_name'] = className;
      if (teacherName != null) requestData['teacher_name'] = teacherName;
      if (titleTemplates != null) requestData['title_templates'] = titleTemplates.toJson();
      if (uiPreferences != null) requestData['ui_preferences'] = uiPreferences.toJson();
      if (notificationSettings != null) requestData['notification_settings'] = notificationSettings.toJson();
      if (workflowSettings != null) requestData['workflow_settings'] = workflowSettings.toJson();

      final response = await _client.put(
        Uri.parse('$baseUrl/users/settings'),
        headers: _headers,
        body: json.encode(requestData),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return UserSettingsResponse.fromJson(jsonData);
      } else {
        throw _handleError('update user settings', response);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating user settings: $e');
      }
      rethrow;
    }
  }

  /// ユーザー設定を削除
  Future<void> deleteUserSettings() async {
    try {
      final response = await _client.delete(
        Uri.parse('$baseUrl/users/settings'),
        headers: _headers,
      );

      if (response.statusCode != 204) {
        throw _handleError('delete user settings', response);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting user settings: $e');
      }
      rethrow;
    }
  }

  /// タイトルテンプレートを追加
  Future<void> addTitleTemplate(TitleTemplate template) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/users/settings/title-templates'),
        headers: _headers,
        body: json.encode(template.toJson()),
      );

      if (response.statusCode != 201) {
        throw _handleError('add title template', response);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error adding title template: $e');
      }
      rethrow;
    }
  }

  /// タイトルテンプレートを削除
  Future<void> removeTitleTemplate(String templateId) async {
    try {
      final response = await _client.delete(
        Uri.parse('$baseUrl/users/settings/title-templates/$templateId'),
        headers: _headers,
      );

      if (response.statusCode != 204) {
        throw _handleError('remove title template', response);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error removing title template: $e');
      }
      rethrow;
    }
  }

  /// タイトル提案を取得
  Future<List<TitleSuggestion>> getTitleSuggestions({
    String? contentHint,
    String? eventType,
    String? season,
    String urgency = 'normal',
  }) async {
    try {
      final requestData = {
        if (contentHint != null) 'content_hint': contentHint,
        if (eventType != null) 'event_type': eventType,
        if (season != null) 'season': season,
        'urgency': urgency,
      };

      final response = await _client.post(
        Uri.parse('$baseUrl/users/settings/title-suggestions'),
        headers: _headers,
        body: json.encode(requestData),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((item) => TitleSuggestion.fromJson(item)).toList();
      } else {
        throw _handleError('get title suggestions', response);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting title suggestions: $e');
      }
      rethrow;
    }
  }

  /// タイトル使用統計を更新
  Future<void> updateTitleUsage(String title) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/users/settings/title-usage'),
        headers: _headers,
        body: json.encode({'title': title}),
      );

      // 統計更新は失敗しても致命的でないため、エラーレベルを下げる
      if (response.statusCode != 200 && kDebugMode) {
        debugPrint('Warning: Failed to update title usage: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Warning: Error updating title usage: $e');
      }
      // エラーを再スローしない（統計更新の失敗は致命的でない）
    }
  }

  /// 設定の完了状況を検証
  Future<Map<String, dynamic>> validateSettings() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/users/settings/validation'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw _handleError('validate settings', response);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error validating settings: $e');
      }
      rethrow;
    }
  }

  /// 設定をエクスポート
  Future<Map<String, dynamic>> exportSettings() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/users/settings/export'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw _handleError('export settings', response);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error exporting settings: $e');
      }
      rethrow;
    }
  }

  /// リソースを解放
  void dispose() {
    _client.close();
  }
}

/// シングルトンインスタンス
final UserSettingsService userSettingsService = UserSettingsService();