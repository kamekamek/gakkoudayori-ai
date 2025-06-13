import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

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
  
  // 辞書データ
  Map<String, dynamic> _dictionaryData = {};
  Map<String, dynamic> _stats = {};
  List<dynamic> _customTerms = [];
  
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
      final apiUrl = kDebugMode 
          ? 'http://localhost:8081/api/v1/dictionary/${widget.userId}'
          : 'https://asia-northeast1-yutori-kyoshitu.cloudfunctions.net/main/api/v1/dictionary/${widget.userId}';
      
      final response = await http.get(Uri.parse(apiUrl));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          setState(() {
            _dictionaryData = data['data']['dictionary'];
            _stats = data['data']['stats'];
            
            // カスタム用語のリストを作成
            _customTerms = [];
            _dictionaryData.forEach((term, variations) {
              if (variations is Map && variations.containsKey('category')) {
                _customTerms.add({
                  'term': term,
                  'variations': variations['variations'] ?? [],
                  'category': variations['category'] ?? 'custom',
                  'usage_count': variations['usage_count'] ?? 0,
                });
              }
            });
          });
        } else {
          setState(() {
            _errorMessage = data['error'] ?? '辞書の読み込みに失敗しました';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'サーバーエラー: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '通信エラー: $e';
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
      final apiUrl = kDebugMode 
          ? 'http://localhost:8081/api/v1/dictionary/${widget.userId}/terms'
          : 'https://asia-northeast1-yutori-kyoshitu.cloudfunctions.net/main/api/v1/dictionary/${widget.userId}/terms';
      
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'term': term,
          'variations': variations,
          'category': _selectedCategory,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          // 成功時の処理
          _termController.clear();
          _variationsController.clear();
          _loadDictionary(); // 辞書を再読み込み
          widget.onDictionaryUpdated?.call();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('「$term」を辞書に追加しました'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          _showErrorDialog(data['error'] ?? '用語の追加に失敗しました');
        }
      } else {
        _showErrorDialog('サーバーエラー: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorDialog('通信エラー: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 手動修正を記録
  Future<void> _recordCorrection(String original, String corrected) async {
    try {
      final apiUrl = kDebugMode 
          ? 'http://localhost:8081/api/v1/dictionary/${widget.userId}/correct'
          : 'https://asia-northeast1-yutori-kyoshitu.cloudfunctions.net/main/api/v1/dictionary/${widget.userId}/correct';
      
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
      print('修正記録エラー: $e');
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
                                              backgroundColor: _getCategoryColor(term['category']),
                                              child: Text(
                                                _getCategoryIcon(term['category']),
                                                style: TextStyle(color: Colors.white),
                                              ),
                                            ),
                                            title: Text(
                                              term['term'],
                                              style: TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            subtitle: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                if (term['variations'].isNotEmpty)
                                                  Text('読み: ${term['variations'].join(', ')}'),
                                                Text(
                                                  '${_categories[term['category']] ?? 'その他'} • 使用回数: ${term['usage_count']}回',
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
                                                if (value == 'delete') {
                                                  // 削除確認ダイアログ
                                                  showDialog(
                                                    context: context,
                                                    builder: (context) => AlertDialog(
                                                      title: Text('削除確認'),
                                                      content: Text('「${term['term']}」を削除しますか？'),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () => Navigator.pop(context),
                                                          child: Text('キャンセル'),
                                                        ),
                                                        TextButton(
                                                          onPressed: () {
                                                            Navigator.pop(context);
                                                            // TODO: 削除API呼び出し
                                                          },
                                                          child: Text('削除', style: TextStyle(color: Colors.red)),
                                                        ),
                                                      ],
                                                    ),
                                                  );
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