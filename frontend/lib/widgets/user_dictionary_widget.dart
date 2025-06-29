import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_config.dart';
import '../services/user_dictionary_service.dart';
import 'package:google_fonts/google_fonts.dart';

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
  final Map<String, dynamic> _dictionaryData = {};
  List<UserDictionaryEntry> _customTerms = [];
  List<UserDictionaryEntry> _filteredTerms = [];

  // 新規用語追加用
  final TextEditingController _termController = TextEditingController();
  final TextEditingController _variationsController = TextEditingController();

  // 検索用
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadDictionary();
    _searchController.addListener(_filterTerms);
  }

  @override
  void dispose() {
    _termController.dispose();
    _variationsController.dispose();
    _searchController.dispose();
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

      setState(() {
        _customTerms = terms;
        _filterTerms();
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

  /// 検索フィルタリング
  void _filterTerms() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredTerms = List.from(_customTerms);
      } else {
        _filteredTerms = _customTerms.where((term) {
          return term.term.toLowerCase().contains(query) ||
              term.variations.any((v) => v.toLowerCase().contains(query));
        }).toList();
      }
      // アルファベット順でソート
      _filteredTerms.sort((a, b) => a.term.compareTo(b.term));
    });
  }

  /// 新規用語を追加
  Future<void> _addCustomTerm() async {
    final term = _termController.text.trim();
    final variationsText = _variationsController.text.trim();

    if (term.isEmpty) {
      _showErrorDialog('用語を入力してください');
      return;
    }

    // 読み方を設定
    final variations =
        variationsText.isNotEmpty ? [variationsText.trim()] : <String>[];

    setState(() {
      _isLoading = true;
    });

    try {
      final newEntry = UserDictionaryEntry(
        term: term,
        variations: variations,
      );

      await _dictionaryService.addTerm(widget.userId, newEntry);

      // 成功時の処理
      _termController.clear();
      _variationsController.clear();
      await _loadDictionary(); // 辞書を再読み込み
      widget.onDictionaryUpdated?.call();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('「$term」を辞書に追加しました'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(top: 50, left: 16, right: 16),
            action: SnackBarAction(
              label: '✕',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
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
            child: Text('削除', style: GoogleFonts.notoSansJp(color: Colors.red)),
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
        await _loadDictionary(); // 辞書を再読み込み
        widget.onDictionaryUpdated?.call();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('「${entry.term}」を削除しました'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.only(top: 50, left: 16, right: 16),
              action: SnackBarAction(
                label: '✕',
                textColor: Colors.white,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
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
      final apiUrl =
          '${AppConfig.apiBaseUrl.replaceAll('/api/v1/ai', '')}/api/v1/dictionary/${widget.userId}/correct';

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
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.only(top: 50, left: 16, right: 16),
              action: SnackBarAction(
                label: '✕',
                textColor: Colors.white,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
            ),
          );
          await _loadDictionary(); // 統計を更新
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
    _variationsController.text =
        entryToEdit.variations.isNotEmpty ? entryToEdit.variations.first : '';

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
                  labelText: '読み方',
                  hintText: 'たなかたろう',
                  border: OutlineInputBorder(),
                ),
                maxLines: 1,
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

    final variations =
        variationsText.isNotEmpty ? [variationsText.trim()] : <String>[];

    final newEntry = UserDictionaryEntry(
      term: term,
      variations: variations,
    );

    setState(() {
      _isLoading = true;
    });

    try {
      await _dictionaryService.updateTerm(
          widget.userId, oldEntry.term, newEntry);
      _termController.clear();
      _variationsController.clear();
      await _loadDictionary();
      widget.onDictionaryUpdated?.call();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('「${newEntry.term}」に更新しました'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(top: 50, left: 16, right: 16),
            action: SnackBarAction(
              label: '✕',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
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
                  labelText: '読み方',
                  hintText: 'たなかたろう',
                  border: OutlineInputBorder(),
                ),
                maxLines: 1,
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
        backgroundColor: Colors.orange[800],
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
                      Text(_errorMessage,
                          style: GoogleFonts.notoSansJp(color: Colors.red)),
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
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.list,
                                            color: Colors.blue[600]),
                                        SizedBox(width: 8),
                                        Text(
                                          '登録用語一覧',
                                          style: GoogleFonts.notoSansJp(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Spacer(),
                                        Text(
                                          '${_filteredTerms.length}件',
                                          style: GoogleFonts.notoSansJp(
                                              fontSize: 14,
                                              color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 12),
                                    // 検索バー
                                    TextField(
                                      controller: _searchController,
                                      decoration: InputDecoration(
                                        hintText: '用語や読みで検索...',
                                        prefixIcon: Icon(Icons.search),
                                        suffixIcon: _searchQuery.isNotEmpty
                                            ? IconButton(
                                                icon: Icon(Icons.clear),
                                                onPressed: () {
                                                  _searchController.clear();
                                                },
                                              )
                                            : null,
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                      ),
                                      style:
                                          GoogleFonts.notoSansJp(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: _filteredTerms.isEmpty
                                    ? Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.library_books_outlined,
                                              size: 64,
                                              color: Colors.grey[400],
                                            ),
                                            SizedBox(height: 16),
                                            Text(
                                              '用語が登録されていません',
                                              style: GoogleFonts.notoSansJp(
                                                  fontSize: 16,
                                                  color: Colors.grey[600]),
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              '「新しい用語を追加」ボタンから\n生徒名や学校専用用語を登録してください',
                                              style: GoogleFonts.notoSansJp(
                                                  fontSize: 14,
                                                  color: Colors.grey[500]),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      )
                                    : ListView.builder(
                                        itemCount: _filteredTerms.length,
                                        itemBuilder: (context, index) {
                                          final term = _filteredTerms[index];
                                          // デフォルト用語かカスタム用語かを判定
                                          // variationsに2つ以上あり、最後がtermと同じ場合はデフォルト用語
                                          final isDefaultTerm =
                                              term.variations.length >= 2 &&
                                                  term.variations.last ==
                                                      term.term;

                                          return ListTile(
                                            leading: CircleAvatar(
                                              backgroundColor: isDefaultTerm
                                                  ? Colors.grey
                                                  : Colors.blue,
                                              child: Icon(
                                                isDefaultTerm
                                                    ? Icons.book
                                                    : Icons.text_fields,
                                                color: Colors.white,
                                              ),
                                            ),
                                            title: Text(
                                              term.term,
                                              style: GoogleFonts.notoSansJp(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            subtitle: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                if (term.variations.isNotEmpty)
                                                  Text(
                                                      '読み: ${term.variations.isNotEmpty ? term.variations.first : ''}'),
                                              ],
                                            ),
                                            trailing: isDefaultTerm
                                                ? null
                                                : PopupMenuButton(
                                                    itemBuilder: (context) => [
                                                      PopupMenuItem(
                                                        value: 'edit',
                                                        child: Row(
                                                          children: [
                                                            Icon(Icons.edit,
                                                                size: 16),
                                                            SizedBox(width: 8),
                                                            Text('編集'),
                                                          ],
                                                        ),
                                                      ),
                                                      PopupMenuItem(
                                                        value: 'delete',
                                                        child: Row(
                                                          children: [
                                                            Icon(Icons.delete,
                                                                size: 16,
                                                                color:
                                                                    Colors.red),
                                                            SizedBox(width: 8),
                                                            Text('削除',
                                                                style: GoogleFonts
                                                                    .notoSansJp(
                                                                        color: Colors
                                                                            .red)),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                    onSelected: (value) {
                                                      if (value == 'edit') {
                                                        _showEditTermDialog(
                                                            term);
                                                      } else if (value ==
                                                          'delete') {
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
}
