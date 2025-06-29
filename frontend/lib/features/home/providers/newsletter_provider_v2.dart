import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/adk_agent_service.dart';
import '../../../services/user_settings_service.dart';
import '../../../models/user_settings.dart';
import '../../ai_assistant/providers/adk_chat_provider.dart';
import '../../../core/providers/error_provider.dart';

/// 学級通信全体の状態管理（v2 - ユーザー設定統合版）
class NewsletterProviderV2 extends ChangeNotifier {
  final AdkAgentService adkAgentService;
  final AdkChatProvider adkChatProvider;
  final UserSettingsService userSettingsService;

  // ユーザー設定
  UserSettings? _userSettings;
  bool _isSettingsLoaded = false;
  bool _isSettingsLoading = false;

  // 学級通信の内容
  String _title = '';
  String _content = '';
  String _generatedHtml = '';

  // 処理状態
  bool _isGenerating = false;
  bool _isProcessing = false;
  String _statusMessage = '🎤 音声録音または文字入力で学級通信を作成してください';
  String? _error;

  // 自動保存関連
  Timer? _autoSaveTimer;
  bool _hasUnsavedChanges = false;

  // Getters
  UserSettings? get userSettings => _userSettings;
  bool get isSettingsLoaded => _isSettingsLoaded;
  bool get isSettingsLoading => _isSettingsLoading;
  
  // 基本情報（設定から取得、フォールバック付き）
  String get schoolName {
    final settings = _userSettings;
    return settings?.schoolName.trim().isNotEmpty == true ? settings!.schoolName : '';
  }
  
  String get className {
    final settings = _userSettings;
    return settings?.className.trim().isNotEmpty == true ? settings!.className : '';
  }
  
  String get teacherName {
    final settings = _userSettings;
    return settings?.teacherName.trim().isNotEmpty == true ? settings!.teacherName : '';
  }
  
  String get title => _title;
  String get content => _content;
  String get generatedHtml => _generatedHtml;
  bool get isGenerating => _isGenerating;
  bool get isProcessing => _isProcessing;
  String get statusMessage => _statusMessage;
  String? get error => _error;
  bool get hasUnsavedChanges => _hasUnsavedChanges;

  NewsletterProviderV2({
    required this.adkAgentService,
    required this.adkChatProvider,
    required this.userSettingsService,
  }) {
    // 初期化時にユーザー設定を読み込み
    _initializeSettings();
    _setupAutoSave();
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    super.dispose();
  }

  /// Firebase認証トークンをUserSettingsServiceに設定
  Future<void> _ensureAuthTokenSet() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final token = await user.getIdToken();
        if (token != null) {
          userSettingsService.setAuthToken(token);
          if (kDebugMode) {
            debugPrint('✅ 認証トークンをUserSettingsServiceに設定しました');
          }
        } else {
          if (kDebugMode) {
            debugPrint('⚠️ 認証トークンの取得に失敗しました');
          }
        }
      } else {
        if (kDebugMode) {
          debugPrint('⚠️ Firebase認証ユーザーが見つかりません');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ 認証トークン設定エラー: $e');
      }
    }
  }

  /// ユーザー設定の初期化
  Future<void> _initializeSettings() async {
    if (_isSettingsLoading) return;

    _isSettingsLoading = true;
    notifyListeners();

    try {
      // Firebase認証トークンを取得してUserSettingsServiceに設定
      await _ensureAuthTokenSet();
      
      final response = await userSettingsService.getUserSettings();
      _userSettings = response?.settings;
      _isSettingsLoaded = true;
      
      if (_userSettings != null) {
        _statusMessage = '${_userSettings!.teacherName}先生、今日も学級通信を作成しましょう！';
      } else {
        _statusMessage = '初期設定を完了して、学級通信作成を始めましょう';
      }
      
      if (kDebugMode) {
        print('ユーザー設定読み込み完了: ${_userSettings?.schoolName}');
      }
    } catch (e) {
      _error = 'ユーザー設定の読み込みに失敗しました: $e';
      if (kDebugMode) {
        print('ユーザー設定読み込みエラー: $e');
      }
    } finally {
      _isSettingsLoading = false;
      notifyListeners();
    }
  }

  /// 自動保存の設定
  void _setupAutoSave() {
    final interval = _userSettings?.workflowSettings.autoSaveInterval ?? 30;
    _autoSaveTimer = Timer.periodic(Duration(seconds: interval), (timer) {
      if (_hasUnsavedChanges) {
        _autoSave();
      }
    });
  }

  /// 自動保存の実行
  Future<void> _autoSave() async {
    if (!_hasUnsavedChanges || _userSettings == null) return;

    try {
      // 現在の状態を保存（実装は必要に応じて）
      _hasUnsavedChanges = false;
      if (kDebugMode) {
        print('自動保存完了');
      }
    } catch (e) {
      if (kDebugMode) {
        print('自動保存エラー: $e');
      }
    }
  }

  /// ユーザー設定を保存（作成または更新を自動判定）
  Future<bool> saveUserSettings({
    required String schoolName,
    required String className,
    required String teacherName,
    TitleTemplates? titleTemplates,
    UIPreferences? uiPreferences,
  }) async {
    try {
      _isSettingsLoading = true;
      _error = null;
      notifyListeners();

      // 認証トークンを設定
      await _ensureAuthTokenSet();

      final response = await userSettingsService.saveUserSettings(
        schoolName: schoolName.trim(),
        className: className.trim(),
        teacherName: teacherName.trim(),
        titleTemplates: titleTemplates,
        uiPreferences: uiPreferences,
      );

      if (response.settings == null) {
        throw Exception('ユーザー設定の保存に失敗しました。サーバーから空のレスポンスが返されました。');
      }

      _userSettings = response.settings;
      _isSettingsLoaded = true;
      _statusMessage = '${teacherName.trim()}先生、設定が完了しました！学級通信を作成しましょう';

      if (kDebugMode) {
        print('ユーザー設定作成完了: $schoolName $className');
      }

      notifyListeners();
      return true;
    } catch (e) {
      _error = 'ユーザー設定の保存に失敗しました: $e';
      if (kDebugMode) {
        debugPrint('ユーザー設定保存エラー: $e');
      }
      notifyListeners();
      return false;
    } finally {
      _isSettingsLoading = false;
    }
  }

  /// ユーザー設定を作成（後方互換性のため）
  Future<bool> createUserSettings({
    required String schoolName,
    required String className,
    required String teacherName,
    TitleTemplates? titleTemplates,
    UIPreferences? uiPreferences,
  }) async {
    return saveUserSettings(
      schoolName: schoolName,
      className: className,
      teacherName: teacherName,
      titleTemplates: titleTemplates,
      uiPreferences: uiPreferences,
    );
  }

  /// ユーザー設定を更新
  Future<bool> updateUserSettings({
    String? schoolName,
    String? className,
    String? teacherName,
    TitleTemplates? titleTemplates,
    UIPreferences? uiPreferences,
    NotificationSettings? notificationSettings,
    WorkflowSettings? workflowSettings,
  }) async {
    try {
      _isSettingsLoading = true;
      _error = null;
      notifyListeners();

      // 認証トークンを設定
      await _ensureAuthTokenSet();

      final response = await userSettingsService.updateUserSettings(
        schoolName: schoolName?.trim(),
        className: className?.trim(),
        teacherName: teacherName?.trim(),
        titleTemplates: titleTemplates,
        uiPreferences: uiPreferences,
        notificationSettings: notificationSettings,
        workflowSettings: workflowSettings,
      );

      if (response.settings == null) {
        throw Exception('ユーザー設定の更新に失敗しました。サーバーから空のレスポンスが返されました。');
      }

      _userSettings = response.settings;
      _hasUnsavedChanges = true;

      if (kDebugMode) {
        print('ユーザー設定更新完了');
      }

      notifyListeners();
      return true;
    } catch (e) {
      _error = 'ユーザー設定の更新に失敗しました: $e';
      if (kDebugMode) {
        print('ユーザー設定更新エラー: $e');
      }
      notifyListeners();
      return false;
    } finally {
      _isSettingsLoading = false;
    }
  }

  /// 基本情報の更新（後方互換性のため）
  void updateSchoolInfo({
    String? schoolName,
    String? className,
    String? teacherName,
  }) {
    // 新しいAPIを使用して更新
    updateUserSettings(
      schoolName: schoolName,
      className: className,
      teacherName: teacherName,
    );
  }

  /// タイトル提案を取得
  Future<List<TitleSuggestion>> getTitleSuggestions({
    String? contentHint,
    String? eventType,
    String? season,
  }) async {
    try {
      // 認証トークンを設定
      await _ensureAuthTokenSet();
      
      return await userSettingsService.getTitleSuggestions(
        contentHint: contentHint,
        eventType: eventType,
        season: season,
      );
    } catch (e) {
      if (kDebugMode) {
        print('タイトル提案取得エラー: $e');
      }
      return [];
    }
  }

  /// タイトル使用統計を更新
  Future<void> recordTitleUsage(String title) async {
    try {
      // 認証トークンを設定
      await _ensureAuthTokenSet();
      
      await userSettingsService.updateTitleUsage(title);
      if (kDebugMode) {
        print('タイトル使用統計更新: $title');
      }
    } catch (e) {
      if (kDebugMode) {
        print('タイトル使用統計更新エラー: $e');
      }
    }
  }

  /// 学級通信内容の更新
  void updateContent(String content) {
    _content = content;
    _hasUnsavedChanges = true;
    notifyListeners();
  }

  void updateTitle(String title) {
    _title = title;
    _hasUnsavedChanges = true;
    notifyListeners();
  }

  void updateGeneratedHtml(String html) {
    _generatedHtml = html;
    _hasUnsavedChanges = true;
    notifyListeners();
  }

  /// 処理状態の管理
  void setGenerating(bool isGenerating) {
    _isGenerating = isGenerating;
    notifyListeners();
  }

  void setProcessing(bool isProcessing) {
    _isProcessing = isProcessing;
    notifyListeners();
  }

  void updateStatus(String message) {
    _statusMessage = message;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// 学級通信のリセット
  void resetNewsletter() {
    _title = '';
    _content = '';
    _generatedHtml = '';
    _isGenerating = false;
    _isProcessing = false;
    _hasUnsavedChanges = false;
    
    if (_userSettings != null) {
      _statusMessage = '${_userSettings!.teacherName}先生、新しい学級通信を作成しましょう';
    } else {
      _statusMessage = '🎤 音声録音または文字入力で学級通信を作成してください';
    }
    
    notifyListeners();
  }

  /// 学級通信の生成
  Future<String?> generateNewsletter() async {
    if (_isGenerating) return null;

    final userId = adkChatProvider.userId;
    final sessionId = adkChatProvider.sessionId;

    // 入力検証
    if (userId.trim().isEmpty) {
      _error = 'ユーザーIDが設定されていません。';
      notifyListeners();
      return null;
    }
    
    if (sessionId == null || sessionId.trim().isEmpty) {
      _error = 'チャットセッションが開始されていません。';
      notifyListeners();
      return null;
    }

    _isGenerating = true;
    _error = null;
    notifyListeners();

    try {
      final htmlContent = await adkAgentService.generateNewsletter(
        userId: userId.trim(),
        sessionId: sessionId.trim(),
      );
      
      if (htmlContent.trim().isEmpty) {
        throw Exception('生成されたHTMLコンテンツが空です。');
      }
      
      updateGeneratedHtml(htmlContent);
      
      // タイトル使用統計を更新
      final currentTitle = _title.trim();
      if (currentTitle.isNotEmpty) {
        try {
          await recordTitleUsage(currentTitle);
        } catch (e) {
          // 統計更新の失敗は致命的ではないため、ログのみ
          if (kDebugMode) {
            debugPrint('⚠️ タイトル使用統計更新でエラー: $e');
          }
        }
      }
      
      return htmlContent;
    } catch (e) {
      _error = '学級通信の生成に失敗しました: $e';
      return null;
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  /// 設定の完了状況を取得
  bool get isUserSettingsComplete {
    final settings = _userSettings;
    return settings?.isComplete ?? false;
  }

  /// 設定の不足フィールドを取得
  List<String> get missingSettingsFields {
    final settings = _userSettings;
    if (settings == null) {
      return ['schoolName', 'className', 'teacherName'];
    }
    return settings.missingFields;
  }

  /// 次回の号数を取得
  int get nextIssueNumber {
    final settings = _userSettings;
    return settings?.titleTemplates.currentNumber ?? 1;
  }

  /// デフォルトタイトルパターンを取得
  String get defaultTitlePattern {
    final settings = _userSettings;
    final pattern = settings?.titleTemplates.primary;
    return (pattern?.trim().isNotEmpty == true) ? pattern! : '学級だより○号';
  }

  /// UI設定を取得
  UIPreferences get uiPreferences {
    final settings = _userSettings;
    return settings?.uiPreferences ?? UIPreferences();
  }

  /// UI設定を更新する専用メソッド
  Future<bool> updateUiPreferences(UIPreferences newPreferences) async {
    return await updateUserSettings(uiPreferences: newPreferences);
  }

  /// 設定の再読み込み
  Future<void> reloadSettings() async {
    _isSettingsLoaded = false;
    await _initializeSettings();
  }

  /// 設定が変更されたときの通知
  void onSettingsChanged() {
    reloadSettings();
  }
}

/// Riverpod Provider
/// 注意: このプロバイダーはapp.dartで実際の依存関係と置き換える必要があります
final newsletterProviderV2 = ChangeNotifierProvider<NewsletterProviderV2>((ref) {
  // 各サービスのインスタンスを作成
  final adkAgentService = AdkAgentService();
  
  // FirebaseAuth経由でユーザーIDを取得
  final currentUser = FirebaseAuth.instance.currentUser;
  final userId = currentUser?.uid ?? 'anonymous_user';
  
  // ErrorProviderは実際の実装で置き換える
  final errorProvider = ErrorProvider();
  
  final adkChatProvider = AdkChatProvider(
    adkService: adkAgentService,
    errorProvider: errorProvider,
    userId: userId,
  );
  
  return NewsletterProviderV2(
    adkAgentService: adkAgentService,
    adkChatProvider: adkChatProvider,
    userSettingsService: userSettingsService,
  );
});