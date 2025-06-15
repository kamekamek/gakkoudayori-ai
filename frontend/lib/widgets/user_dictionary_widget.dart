import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_config.dart';
import '../services/user_dictionary_service.dart';

/// ユーザー辞書管理ウィジェット
/// 教師が固有名詞や学校専用用語を登録・管理できるUI
class UserDictionaryWidget extends StatefulWidget {
  final String userId;
  final VoidCallback? onDictionaryUpdated;

  const UserDictionaryWidget({
    Key? key,
    required this.userId,
    this.onDictionaryUpdated,
  }) : super(key: key);

  @override
  State<UserDictionaryWidget> createState() => _UserDictionaryWidgetState();
}

class _UserDictionaryWidgetState extends State<UserDictionaryWidget> {
  bool _isLoading = false;
  String _errorMessage = '';
  final UserDictionaryService _dictionaryService = UserDictionaryService();
  
  // 辞書データ
  Map<String, dynamic> _dictionaryData = {};
  Map<String, dynamic> _stats = {};
  List<UserDictionaryEntry> _customTerms = [];
  
  // 新規用語追加用
  final TextEditingController _termController = TextEditingController();
  final TextEditingController _variationsController = TextEditingController();
  String _selectedCategory = 'student_name';
  
  // カテゴリ定義
  final Map<String, String> _categories = {
    'student_name': '児童・生徒名',
    'teacher_name': '教師名',
    'school_event': '学校行事',
    'subject_term': '教科用語',
    'school_facility': '学校施設',
    'custom': 'その他',
  };

  @override
  void initState() {
    super.initState();
    _loadDictionary();
  }

  @override
  void dispose() {
    _termController.dispose();
    _variationsController.dispose();
    super.dispose();
  }

  /// 辞書データを読み込み
  Future<void> _loadDictionary() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final terms = await _dictionaryService.getTerms(widget.userId);
      // TODO: 統計情報の取得も行う場合は、別途 _dictionaryService.getDictionaryStats() を呼び出す
      // final stats = await _dictionaryService.getDictionaryStats(widget.userId);

      setState(() {
        _customTerms = terms;
        // if (stats != null) {
        //   _stats = stats;
        // }
      });
    } catch (e) {
      setState(() {
        _errorMessage = '辞書の読み込み中にエラーが発生しました: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 新規用語を追加
  Future<void> _addCustomTerm() async {
    final term = _termController.text.trim();
    final variationsText = _variationsController.text.trim();
    
    if (term.isEmpty) {
      _showErrorDialog('用語を入力してください');
      return;
    }

    // バリエーションを分割（カンマ区切り）
    final variations = variationsText.isNotEmpty 
        ? variationsText.split(',').map((v) => v.trim()).toList()
        : <String>[];

    setState(() {
      _isLoading = true;
    });

    try {
      final newEntry = UserDictionaryEntry(
        term: term,
        variations: variations,
        category: _selectedCategory,
      );

      await _dictionaryService.addTerm(widget.userId, newEntry);

      // 成功時の処理
      _termController.clear();
      _variationsController.clear();
      _loadDictionary(); // 辞書を再読み込み
      widget.onDictionaryUpdated?.call();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('「$term」を辞書に追加しました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error in _addCustomTerm: $e');
      }
      if (mounted) {
        _showErrorDialog('用語の追加中にエラーが発生しました: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 用語を削除
  Future<void> _deleteTerm(UserDictionaryEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('削除確認'),
        content: Text('「${entry.term}」を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('削除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });
      try {
        await _dictionaryService.deleteTerm(widget.userId, entry.term);
        _loadDictionary(); // 辞書を再読み込み
        widget.onDictionaryUpdated?.call();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('「${entry.term}」を削除しました'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error in _deleteTerm: $e');
        }
        if (mounted) {
          _showErrorDialog('用語の削除中にエラーが発生しました: $e');
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  /// 手動修正を記録
  Future<void> _recordCorrection(String original, String corrected) async {
    try {
      final apiUrl = '${AppConfig.apiBaseUrl.replaceAll('/api/v1/ai', '')}/api/v1/dictionary/${widget.userId}/correct';
      
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'original': original,
          'corrected': corrected,
          'context': '',
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('修正を学習しました: $original → $corrected'),
              backgroundColor: Colors.blue,
            ),
          );
          _loadDictionary(); // 統計を更新
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('修正記録エラー: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('エラー'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showEditTermDialog(UserDictionaryEntry entryToEdit) {
    _termController.text = entryToEdit.term;
    _variationsController.text = entryToEdit.variations.join(', ');
    _selectedCategory = entryToEdit.category;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('用語を編集'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _termController,
                decoration: InputDecoration(
                  labelText: '用語（例: 田中太郎）',
                  hintText: '正しい表記を入力してください',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _variationsController,
                decoration: InputDecoration(
                  labelText: '読み方・バリエーション（カンマ区切り）',
                  hintText: 'たなかたろう, タナカタロウ, 田中',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory, // entryToEdit.category should be used here if _selectedCategory is not updated before build
                decoration: InputDecoration(
                  labelText: 'カテゴリ',
                  border: OutlineInputBorder(),
                ),
                items: _categories.entries.map((entry) {
                  return DropdownMenuItem<String>(
                    value: entry.key,
                    child: Text(entry.value),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              // Call method to update term
              _updateTermInDialog(entryToEdit); 
              Navigator.of(context).pop();
            },
            child: Text('保存'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateTermInDialog(UserDictionaryEntry oldEntry) async {
    final term = _termController.text.trim();
    final variationsText = _variationsController.text.trim();

    if (term.isEmpty) {
      _showErrorDialog('用語を入力してください');
      return;
    }

    final variations = variationsText.isNotEmpty
        ? variationsText.split(',').map((v) => v.trim()).toList()
        : <String>[];

    final newEntry = UserDictionaryEntry(
      term: term,
      variations: variations,
      category: _selectedCategory,
    );

    setState(() {
      _isLoading = true;
    });

    try {
      await _dictionaryService.updateTerm(widget.userId, oldEntry.term, newEntry);
      _termController.clear();
      _variationsController.clear();
      _loadDictionary();
      widget.onDictionaryUpdated?.call();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('「${newEntry.term}」に更新しました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error in _updateTermInDialog: $e');
      }
      if (mounted) {
        _showErrorDialog('用語の更新中にエラーが発生しました: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showAddTermDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('新しい用語を追加'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _termController,
                decoration: InputDecoration(
                  labelText: '用語（例: 田中太郎）',
                  hintText: '正しい表記を入力してください',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _variationsController,
                decoration: InputDecoration(
                  labelText: '読み方・バリエーション（カンマ区切り）',
                  hintText: 'たなかたろう, タナカタロウ, 田中',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'カテゴリ',
                  border: OutlineInputBorder(),
                ),
                items: _categories.entries.map((entry) {
                  return DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _addCustomTerm();
            },
            child: Text('追加'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ユーザー辞書管理'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadDictionary,
            icon: Icon(Icons.refresh),
            tooltip: '再読み込み',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.red),
                      SizedBox(height: 16),
                      Text(_errorMessage, style: TextStyle(color: Colors.red)),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadDictionary,
                        child: Text('再試行'),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // 統計情報カード
                      Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '辞書統計',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildStatItem(
                                    '総用語数',
                                    '${_stats['total_terms'] ?? 0}',
                                    Icons.book,
                                  ),
                                  _buildStatItem(
                                    'カスタム用語',
                                    '${_stats['custom_terms'] ?? 0}',
                                    Icons.edit,
                                  ),
                                  _buildStatItem(
                                    '総修正回数',
                                    '${_stats['usage_stats']?['total_corrections'] ?? 0}',
                                    Icons.check_circle,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 16),
                      
                      // 用語追加ボタン
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _showAddTermDialog,
                          icon: Icon(Icons.add),
                          label: Text('新しい用語を追加'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[600],
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 16),
                      
                      // カスタム用語リスト
                      Expanded(
                        child: Card(
                          child: Column(
                            children: [
                              Padding(
                                padding: EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Icon(Icons.list, color: Colors.blue[600]),
                                    SizedBox(width: 8),
                                    Text(
                                      'カスタム用語一覧',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: _customTerms.isEmpty
                                    ? Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.library_books_outlined,
                                              size: 64,
                                              color: Colors.grey[400],
                                            ),
                                            SizedBox(height: 16),
                                            Text(
                                              'カスタム用語がありません',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 16,
                                              ),
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              '「新しい用語を追加」ボタンから\n生徒名や学校専用用語を登録してください',
                                              style: TextStyle(
                                                color: Colors.grey[500],
                                                fontSize: 14,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      )
                                    : ListView.builder(
                                        itemCount: _customTerms.length,
                                        itemBuilder: (context, index) {
                                          final term = _customTerms[index];
                                          return ListTile(
                                            leading: CircleAvatar(
                                              backgroundColor: _getCategoryColor(term.category),
                                              child: Text(
                                                _getCategoryIcon(term.category),
                                                style: TextStyle(color: Colors.white),
                                              ),
                                            ),
                                            title: Text(
                                              term.term,
                                              style: TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            subtitle: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                if (term.variations.isNotEmpty)
                                                  Text('読み: ${term.variations.join(', ')}'),
                                                Text(
                                                  // '${_categories[term.category] ?? 'その他'} • 使用回数: ${term.usageCount}回',
                                                  '${_categories[term.category] ?? 'その他'}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            trailing: PopupMenuButton(
                                              itemBuilder: (context) => [
                                                PopupMenuItem(
                                                  value: 'edit',
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.edit, size: 16),
                                                      SizedBox(width: 8),
                                                      Text('編集'),
                                                    ],
                                                  ),
                                                ),
                                                PopupMenuItem(
                                                  value: 'delete',
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.delete, size: 16, color: Colors.red),
                                                      SizedBox(width: 8),
                                                      Text('削除', style: TextStyle(color: Colors.red)),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                              onSelected: (value) {
                                                 if (value == 'edit') {
                                                   _showEditTermDialog(term);
                                                 } else if (value == 'delete') {
                                                   _deleteTerm(term);
                                                 }
                                               },
                                            ),
                                          );
                                        },
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTermDialog,
        child: Icon(Icons.add),
        backgroundColor: Colors.green[600],
        tooltip: '新しい用語を追加',
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Colors.blue[600]),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.blue[800],
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'student_name':
        return Colors.green;
      case 'teacher_name':
        return Colors.blue;
      case 'school_event':
        return Colors.orange;
      case 'subject_term':
        return Colors.purple;
      case 'school_facility':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  String _getCategoryIcon(String category) {
    switch (category) {
      case 'student_name':
        return '👦';
      case 'teacher_name':
        return '👨‍🏫';
      case 'school_event':
        return '🎉';
      case 'subject_term':
        return '📚';
      case 'school_facility':
        return '🏫';
      default:
        return '📝';
    }
  }
}