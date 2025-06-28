import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:googleapis/classroom/v1.dart' as classroom;
import '../../../../services/google_auth_service.dart';
import '../../../../services/classroom_service.dart';

/// Google Classroom投稿ダイアログ
/// 
/// 学級通信をClassroomに投稿するためのUI
class ClassroomPostDialog extends StatefulWidget {
  final Uint8List pdfBytes;
  final String htmlContent;
  final String title;

  const ClassroomPostDialog({
    super.key,
    required this.pdfBytes,
    required this.htmlContent,
    required this.title,
  });

  @override
  State<ClassroomPostDialog> createState() => _ClassroomPostDialogState();
}

class _ClassroomPostDialogState extends State<ClassroomPostDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _selectedCourseId;
  List<classroom.Course> _courses = [];
  DateTime? _scheduledTime;
  final bool _enableEmailNotification = true;
  final bool _saveToArchive = true;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.title.isNotEmpty ? widget.title : 'AI学級通信';
    _descriptionController.text = '今日の学級通信をお送りします。\n添付のPDFファイルをご確認ください。';
    _checkAuthenticationStatus();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// 認証状態をチェック
  Future<void> _checkAuthenticationStatus() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      _isAuthenticated = GoogleAuthService.isSignedIn;
      
      if (_isAuthenticated) {
        await _loadCourses();
      }
    } catch (e) {
      setState(() {
        _errorMessage = '認証状態の確認に失敗しました: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// コース一覧を読み込み
  Future<void> _loadCourses() async {
    try {
      _courses = await ClassroomService.getCourses();
      
      if (_courses.isNotEmpty) {
        _selectedCourseId = _courses.first.id;
      }
      
      setState(() {});
    } catch (e) {
      setState(() {
        _errorMessage = 'コース一覧の取得に失敗しました: $e';
      });
    }
  }

  /// Google アカウントでログイン
  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await GoogleAuthService.signIn();
      
      if (user != null) {
        _isAuthenticated = true;
        await _loadCourses();
        setState(() {
          _successMessage = 'ログインしました: ${user.email}';
        });
      } else {
        setState(() {
          _errorMessage = 'ログインがキャンセルされました。';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '$e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 予約投稿時刻を設定
  Future<void> _pickScheduledTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 7)),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        setState(() {
          _scheduledTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  /// Classroomに投稿
  Future<void> _postToClassroom() async {
    if (_selectedCourseId == null) {
      setState(() {
        _errorMessage = 'コースを選択してください';
      });
      return;
    }

    if (_titleController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'タイトルを入力してください';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final result = await ClassroomService.postNewsletterToClassroom(
        courseId: _selectedCourseId!,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        pdfBytes: widget.pdfBytes,
        scheduledTime: _scheduledTime,
      );

      if (result['success'] == true) {
        setState(() {
          _successMessage = result['message'];
        });

        // 成功時は少し待ってからダイアログを閉じる
        await Future.delayed(const Duration(seconds: 2));
        
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        setState(() {
          _errorMessage = result['error'] ?? '投稿に失敗しました';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '投稿に失敗しました: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダー
            Row(
              children: [
                Icon(
                  Icons.school,
                  color: Colors.green,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Google Classroom に投稿',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            
            const SizedBox(height: 24),

            // メッセージ表示
            if (_errorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),

            if (_successMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  border: Border.all(color: Colors.green.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _successMessage!,
                        style: TextStyle(color: Colors.green.shade700),
                      ),
                    ),
                  ],
                ),
              ),

            // コンテンツ
            Expanded(
              child: _isLoading
                  ? _buildLoadingView()
                  : !_isAuthenticated
                      ? _buildSignInView()
                      : _buildPostFormView(),
            ),

            // ボタン
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('キャンセル'),
                ),
                const SizedBox(width: 16),
                if (_isAuthenticated && !_isLoading)
                  ElevatedButton.icon(
                    onPressed: _postToClassroom,
                    icon: const Icon(Icons.send),
                    label: Text(_scheduledTime != null ? '予約投稿' : '投稿'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('読み込み中...'),
        ],
      ),
    );
  }

  Widget _buildSignInView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_circle,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 24),
          Text(
            'Google Classroom に投稿するには\nGoogleアカウントでログインしてください',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _signInWithGoogle,
            icon: const Icon(Icons.login),
            label: const Text('Googleアカウントでログイン'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostFormView() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 認証情報
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              border: Border.all(color: Colors.green.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.verified_user, color: Colors.green.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    GoogleAuthService.getAuthStatusText(),
                    style: TextStyle(color: Colors.green.shade700),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // コース選択
          Text(
            'コース選択',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedCourseId,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: '投稿先のコースを選択',
            ),
            items: _courses.map((course) {
              return DropdownMenuItem<String>(
                value: course.id,
                child: Text(course.name ?? 'Unknown Course'),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCourseId = value;
              });
            },
          ),

          const SizedBox(height: 24),

          // タイトル入力
          Text(
            'タイトル',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: '投稿のタイトルを入力',
            ),
          ),

          const SizedBox(height: 24),

          // 説明文入力
          Text(
            '説明文',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: '投稿の説明を入力',
            ),
          ),

          const SizedBox(height: 24),

          // 投稿設定
          Text(
            '投稿設定',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // 予約投稿
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.schedule, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text(
                        '予約投稿',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _pickScheduledTime,
                        child: Text(_scheduledTime != null ? '変更' : '設定'),
                      ),
                    ],
                  ),
                  if (_scheduledTime != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.schedule, size: 16, color: Colors.orange.shade700),
                          const SizedBox(width: 8),
                          Text(
                            '投稿予定: ${_scheduledTime!.month}/${_scheduledTime!.day} ${_scheduledTime!.hour}:${_scheduledTime!.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(color: Colors.orange.shade700),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => setState(() => _scheduledTime = null),
                            icon: Icon(Icons.clear, size: 16, color: Colors.orange.shade700),
                          ),
                        ],
                      ),
                    ),
                  ] else
                    Text(
                      'すぐに投稿する',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 添付ファイル情報
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.attach_file, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        '添付ファイル',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.picture_as_pdf, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_titleController.text.trim()}.pdf',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'サイズ: ${(widget.pdfBytes.length / 1024 / 1024).toStringAsFixed(1)} MB',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}