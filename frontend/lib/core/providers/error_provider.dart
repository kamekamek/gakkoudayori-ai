import 'package:flutter/foundation.dart';

/// シンプルなエラー管理Provider
class ErrorProvider extends ChangeNotifier {
  String? _lastError;
  final List<String> _errorHistory = [];

  String? get lastError => _lastError;
  List<String> get errorHistory => List.unmodifiable(_errorHistory);

  void setError(String error) {
    _lastError = error;
    _errorHistory.add(error);

    // 履歴は最大50件まで
    if (_errorHistory.length > 50) {
      _errorHistory.removeAt(0);
    }

    notifyListeners();
  }

  void clearError() {
    _lastError = null;
    notifyListeners();
  }

  void clearHistory() {
    _errorHistory.clear();
    notifyListeners();
  }
}
