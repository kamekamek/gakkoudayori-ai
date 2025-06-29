import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_settings.dart';
import '../config/app_config.dart';

class UserSettingsService {
  static String get baseUrl => AppConfig.apiV1BaseUrl;

  final http.Client _client;
  String? _authToken;

  UserSettingsService({http.Client? client}) : _client = client ?? http.Client();

  /// 認証トークンを設定
  void setAuthToken(String? token) {
    _authToken = token?.trim().isNotEmpty == true ? token : null;
  }

  /// 認証ヘッダーを取得
  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    final token = _authToken;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    // Firebase AuthのUIDをX-User-IDヘッダーに追加
    final currentUser = FirebaseAuth.instance.currentUser;
    final uid = currentUser?.uid ?? 'user_12345'; // デフォルト値
    headers['X-User-ID'] = uid;
    
    return headers;
  }

  /// 認証状態を確認
  bool get isAuthenticated => _authToken != null && _authToken!.isNotEmpty;

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
      // 認証状態を事前チェック
      if (!isAuthenticated) {
        if (kDebugMode) {
          debugPrint('❌ UserSettingsService: 認証トークンが設定されていません');
        }
        throw Exception('認証が必要です。ログインしてください。');
      }

      if (kDebugMode) {
        debugPrint('🔐 UserSettingsService: 認証済みでユーザー設定を取得中');
        final authHeader = _headers['Authorization'];
        if (authHeader != null && authHeader.length > 20) {
          debugPrint('🔐 Authorization header: ${authHeader.substring(0, 20)}...');
        }
      }
      
      final response = await _client.get(
        Uri.parse('$baseUrl/users/settings'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData == null) {
          if (kDebugMode) {
            debugPrint('⚠️ UserSettingsService: レスポンスが空です');
          }
          return null;
        }
        return UserSettingsResponse.fromJson(jsonData);
      } else if (response.statusCode == 404) {
        // 設定が存在しない場合は正常な状態として扱う
        if (kDebugMode) {
          debugPrint('📋 UserSettingsService: ユーザー設定が見つかりません（初回利用）');
        }
        return null;
      } else {
        throw _handleError('get user settings', response);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting user settings: $e');
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
      // 認証状態を事前チェック
      if (!isAuthenticated) {
        throw Exception('認証が必要です。ログインしてください。');
      }

      // 必須パラメータの検証
      if (schoolName.trim().isEmpty || className.trim().isEmpty || teacherName.trim().isEmpty) {
        throw Exception('学校名、クラス名、先生名は必須です。');
      }

      if (kDebugMode) {
        debugPrint('🔐 UserSettingsService (save): 認証済み');
      }
      
      // まず既存設定を確認（例外やnullの場合は新規作成として扱う）
      UserSettingsResponse? existingSettings;
      bool hasExistingSettings = false;
      
      try {
        existingSettings = await getUserSettings();
        hasExistingSettings = existingSettings?.settings != null;
        if (kDebugMode) {
          debugPrint('✅ 既存設定確認結果: hasExisting=$hasExistingSettings');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ 既存設定の確認でエラー。新規作成として処理: $e');
        }
        hasExistingSettings = false;
        existingSettings = null;
      }
      
      final isUpdate = hasExistingSettings;
      
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

      http.Response response;
      
      if (isUpdate) {
        // 更新を試行
        response = await _client.put(
          Uri.parse('$baseUrl/users/settings'),
          headers: _headers,
          body: json.encode(requestData),
        );
      } else {
        // 新規作成を試行
        response = await _client.post(
          Uri.parse('$baseUrl/users/settings'),
          headers: _headers,
          body: json.encode(requestData),
        );
        
        // 409エラー（既に存在）の場合は更新で再試行
        if (response.statusCode == 409) {
          if (kDebugMode) {
            debugPrint('🔄 409エラー発生。UPDATEで再試行');
          }
          response = await _client.put(
            Uri.parse('$baseUrl/users/settings'),
            headers: _headers,
            body: json.encode(requestData),
          );
        }
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = json.decode(response.body);
        if (jsonData == null) {
          throw Exception('サーバーから空のレスポンスが返されました');
        }
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
      // 認証状態を事前チェック
      if (!isAuthenticated) {
        throw Exception('認証が必要です。ログインしてください。');
      }

      final requestData = <String, dynamic>{};
      
      // nullでないかつ空文字でない値のみを追加
      if (schoolName?.trim().isNotEmpty == true) requestData['school_name'] = schoolName!.trim();
      if (className?.trim().isNotEmpty == true) requestData['class_name'] = className!.trim();
      if (teacherName?.trim().isNotEmpty == true) requestData['teacher_name'] = teacherName!.trim();
      if (titleTemplates != null) requestData['title_templates'] = titleTemplates.toJson();
      if (uiPreferences != null) requestData['ui_preferences'] = uiPreferences.toJson();
      if (notificationSettings != null) requestData['notification_settings'] = notificationSettings.toJson();
      if (workflowSettings != null) requestData['workflow_settings'] = workflowSettings.toJson();

      // 更新するデータがない場合はエラー
      if (requestData.isEmpty) {
        throw Exception('更新するデータがありません。');
      }

      final response = await _client.put(
        Uri.parse('$baseUrl/users/settings'),
        headers: _headers,
        body: json.encode(requestData),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData == null) {
          throw Exception('サーバーから空のレスポンスが返されました');
        }
        return UserSettingsResponse.fromJson(jsonData);
      } else {
        throw _handleError('update user settings', response);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error updating user settings: $e');
      }
      rethrow;
    }
  }

  /// ユーザー設定を削除
  Future<void> deleteUserSettings() async {
    try {
      // 認証状態を事前チェック
      if (!isAuthenticated) {
        throw Exception('認証が必要です。ログインしてください。');
      }

      final response = await _client.delete(
        Uri.parse('$baseUrl/users/settings'),
        headers: _headers,
      );

      if (response.statusCode != 204) {
        throw _handleError('delete user settings', response);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error deleting user settings: $e');
      }
      rethrow;
    }
  }

  /// タイトルテンプレートを追加
  Future<void> addTitleTemplate(TitleTemplate template) async {
    try {
      // 認証状態を事前チェック
      if (!isAuthenticated) {
        throw Exception('認証が必要です。ログインしてください。');
      }

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
        debugPrint('❌ Error adding title template: $e');
      }
      rethrow;
    }
  }

  /// タイトルテンプレートを削除
  Future<void> removeTitleTemplate(String templateId) async {
    try {
      // 認証状態を事前チェック
      if (!isAuthenticated) {
        throw Exception('認証が必要です。ログインしてください。');
      }

      if (templateId.trim().isEmpty) {
        throw Exception('テンプレートIDが指定されていません。');
      }

      final response = await _client.delete(
        Uri.parse('$baseUrl/users/settings/title-templates/${templateId.trim()}'),
        headers: _headers,
      );

      if (response.statusCode != 204) {
        throw _handleError('remove title template', response);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error removing title template: $e');
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
      // 認証状態を事前チェック
      if (!isAuthenticated) {
        throw Exception('認証が必要です。ログインしてください。');
      }

      final requestData = {
        if (contentHint?.trim().isNotEmpty == true) 'content_hint': contentHint!.trim(),
        if (eventType?.trim().isNotEmpty == true) 'event_type': eventType!.trim(),
        if (season?.trim().isNotEmpty == true) 'season': season!.trim(),
        'urgency': urgency.trim().isNotEmpty ? urgency.trim() : 'normal',
      };

      final response = await _client.post(
        Uri.parse('$baseUrl/users/settings/title-suggestions'),
        headers: _headers,
        body: json.encode(requestData),
      );

      if (response.statusCode == 200) {
        final responseBody = response.body;
        if (responseBody.isEmpty) {
          if (kDebugMode) {
            debugPrint('⚠️ タイトル提案のレスポンスが空です');
          }
          return [];
        }
        final dynamic jsonData = json.decode(responseBody);
        if (jsonData is! List) {
          if (kDebugMode) {
            debugPrint('⚠️ タイトル提案のレスポンスが期待した形式ではありません');
          }
          return [];
        }
        return jsonData.map((item) {
          try {
            return TitleSuggestion.fromJson(item);
          } catch (e) {
            if (kDebugMode) {
              debugPrint('⚠️ タイトル提案のパースエラー: $e');
            }
            return null;
          }
        }).where((item) => item != null).cast<TitleSuggestion>().toList();
      } else {
        throw _handleError('get title suggestions', response);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting title suggestions: $e');
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