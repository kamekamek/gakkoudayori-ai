import 'package:flutter/material.dart';
import '../models/document.dart';

class AppState extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  int _currentSeasonIndex = 0; // 0: spring, 1: summer, 2: autumn, 3: winter
  bool _isRecording = false;
  String _currentTranscription = '';
  List<Document> _recentDocuments = [];
  bool _isLoadingDocuments = false;
  String _editorText = '';
  
  // Getters
  ThemeMode get themeMode => _themeMode;
  int get currentSeasonIndex => _currentSeasonIndex;
  bool get isRecording => _isRecording;
  String get currentTranscription => _currentTranscription;
  List<Document> get recentDocuments => _recentDocuments;
  bool get isLoadingDocuments => _isLoadingDocuments;
  String get editorText => _editorText;
  
  // Theme management
  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light 
        ? ThemeMode.dark 
        : ThemeMode.light;
    notifyListeners();
  }
  
  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }
  
  // Season management
  void setSeason(int seasonIndex) {
    if (seasonIndex < 0 || seasonIndex > 3) {
      throw ArgumentError('Season index must be between 0 and 3');
    }
    _currentSeasonIndex = seasonIndex;
    notifyListeners();
  }
  
  void nextSeason() {
    _currentSeasonIndex = (_currentSeasonIndex + 1) % 4;
    notifyListeners();
  }
  
  String get currentSeasonName {
    switch (_currentSeasonIndex) {
      case 0: return '春';
      case 1: return '夏';
      case 2: return '秋';
      case 3: return '冬';
      default: return '春';
    }
  }
  
    // Recording management
  Future<bool> ensureMicPermission() async {
    // TODO: 実際のマイク権限チェック実装
    // 現在はモック実装
    await Future.delayed(const Duration(milliseconds: 100));
    return true; // 実際はpermission_handlerパッケージなどを使用
  }

  void startRecording() {
    _isRecording = true;
    notifyListeners();
  }

  void stopRecording() {
    _isRecording = false;
    notifyListeners();
  }
  
  void updateTranscription(String text) {
    _currentTranscription = text;
    notifyListeners();
  }
  
  void clearTranscription() {
    _currentTranscription = '';
    notifyListeners();
  }
  
  void setEditorText(String text) {
    _editorText = text;
    notifyListeners();
  }
  
  void clearEditorText() {
    _editorText = '';
    notifyListeners();
  }
  
  // Document management
  void addRecentDocument(Document document) {
    _recentDocuments.removeWhere((d) => d.id == document.id);
    _recentDocuments.insert(0, document);
    if (_recentDocuments.length > 10) {
      _recentDocuments = _recentDocuments.take(10).toList();
    }
    notifyListeners();
  }
  
  void removeRecentDocument(String documentId) {
    _recentDocuments.removeWhere((d) => d.id == documentId);
    notifyListeners();
  }

  Future<void> loadRecentDocuments() async {
    _isLoadingDocuments = true;
    notifyListeners();

    try {
      // TODO: 実際はFirestoreから取得
      // 現在はサンプルデータを使用
      await Future.delayed(const Duration(milliseconds: 500));
      
      final now = DateTime.now();
      _recentDocuments = [
        Document(
          id: '1',
          title: '運動会の振り返り',
          createdAt: now.subtract(const Duration(days: 2)),
          updatedAt: now.subtract(const Duration(days: 2)),
          thumbnail: '🏃‍♂️',
          status: DocumentStatus.published,
          content: '今日は運動会でした...',
          views: 45,
        ),
        Document(
          id: '2',
          title: '梅雨の過ごし方',
          createdAt: now.subtract(const Duration(days: 4)),
          updatedAt: now.subtract(const Duration(days: 4)),
          thumbnail: '☔',
          status: DocumentStatus.draft,
          content: '梅雨の季節がやってきました...',
          views: 0,
        ),
        Document(
          id: '3',
          title: '5月の学級だより',
          createdAt: now.subtract(const Duration(days: 7)),
          updatedAt: now.subtract(const Duration(days: 7)),
          thumbnail: '🌸',
          status: DocumentStatus.published,
          content: '新学期が始まって1ヶ月...',
          views: 78,
        ),
      ];
    } catch (e) {
      // エラーハンドリング
      _recentDocuments = [];
    } finally {
      _isLoadingDocuments = false;
      notifyListeners();
    }
  }

  void updateDocument(Document document) {
    final index = _recentDocuments.indexWhere((d) => d.id == document.id);
    if (index != -1) {
      _recentDocuments[index] = document;
      notifyListeners();
    }
  }
}