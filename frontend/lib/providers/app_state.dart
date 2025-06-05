import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  int _currentSeasonIndex = 0; // 0: spring, 1: summer, 2: autumn, 3: winter
  bool _isRecording = false;
  String _currentTranscription = '';
  List<String> _recentDocuments = [];
  
  // Getters
  ThemeMode get themeMode => _themeMode;
  int get currentSeasonIndex => _currentSeasonIndex;
  bool get isRecording => _isRecording;
  String get currentTranscription => _currentTranscription;
  List<String> get recentDocuments => _recentDocuments;
  
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
  
  // Document management
  void addRecentDocument(String documentId) {
    _recentDocuments.insert(0, documentId);
    if (_recentDocuments.length > 10) {
      _recentDocuments = _recentDocuments.take(10).toList();
    }
    notifyListeners();
  }
  
  void removeRecentDocument(String documentId) {
    _recentDocuments.remove(documentId);
    notifyListeners();
  }
}