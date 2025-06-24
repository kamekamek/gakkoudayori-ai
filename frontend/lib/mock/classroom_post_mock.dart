import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'sample_data.dart';

/// Google Classroom投稿のモック機能
class ClassroomPostMock {
  static const String _classId = 'mock_class_12345';
  static const String _teacherId = 'teacher_67890';
  
  /// 学級通信をGoogle Classroomに投稿（モック）
  static Future<ClassroomPostResult> postNewsletter({
    required String htmlContent,
    required String title,
    String? description,
    bool scheduledPost = false,
    DateTime? scheduledDateTime,
  }) async {
    debugPrint('[ClassroomPostMock] 投稿開始: $title');
    
    // リアルな投稿処理時間をシミュレート
    await Future.delayed(const Duration(milliseconds: 1500));
    
    final result = ClassroomPostResult(
      success: true,
      postId: 'mock_post_${DateTime.now().millisecondsSinceEpoch}',
      classId: _classId,
      title: title,
      description: description ?? 'AI生成学級通信',
      postUrl: 'https://classroom.google.com/c/$_classId/p/mock_post_123',
      postedAt: scheduledPost ? scheduledDateTime! : DateTime.now(),
      viewCount: 0,
      isScheduled: scheduledPost,
    );
    
    debugPrint('[ClassroomPostMock] 投稿完了: ${result.postId}');
    return result;
  }
  
  /// 投稿プレビューを表示
  static void showPostPreviewDialog(
    BuildContext context, {
    required String htmlContent,
    required String title,
    String? description,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) => ClassroomPostPreviewDialog(
        htmlContent: htmlContent,
        title: title,
        description: description,
        onConfirm: onConfirm,
      ),
    );
  }
  
  /// 投稿成功ダイアログを表示
  static void showPostSuccessDialog(
    BuildContext context,
    ClassroomPostResult result,
  ) {
    showDialog(
      context: context,
      builder: (context) => ClassroomPostSuccessDialog(result: result),
    );
  }
}

/// Classroom投稿結果モデル
class ClassroomPostResult {
  final bool success;
  final String? postId;
  final String? classId;
  final String title;
  final String description;
  final String? postUrl;
  final DateTime postedAt;
  final int viewCount;
  final bool isScheduled;
  final String? error;
  
  const ClassroomPostResult({
    required this.success,
    this.postId,
    this.classId,
    required this.title,
    required this.description,
    this.postUrl,
    required this.postedAt,
    this.viewCount = 0,
    this.isScheduled = false,
    this.error,
  });
}

/// Classroom投稿プレビューダイアログ
class ClassroomPostPreviewDialog extends StatefulWidget {
  final String htmlContent;
  final String title;
  final String? description;
  final VoidCallback onConfirm;
  
  const ClassroomPostPreviewDialog({
    super.key,
    required this.htmlContent,
    required this.title,
    this.description,
    required this.onConfirm,
  });
  
  @override
  State<ClassroomPostPreviewDialog> createState() => _ClassroomPostPreviewDialogState();
}

class _ClassroomPostPreviewDialogState extends State<ClassroomPostPreviewDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  bool _scheduledPost = false;
  DateTime? _scheduledDateTime;
  
  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.title);
    _descriptionController = TextEditingController(
      text: widget.description ?? 'AI生成学級通信をお送りします。ご確認ください。',
    );
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.school, color: Colors.green.shade600),
          const SizedBox(width: 8),
          const Text('Google Classroom投稿'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // クラス情報表示
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.class_, color: Colors.blue.shade600),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '1年1組 クラスルーム',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade600,
                          ),
                        ),
                        Text(
                          '生徒数: 25名 • 保護者数: 50名',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // タイトル入力
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: '投稿タイトル',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                maxLines: 1,
              ),
              
              const SizedBox(height: 16),
              
              // 説明文入力
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: '投稿説明文',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                  hintText: '保護者の皆様へのメッセージを入力してください',
                ),
                maxLines: 3,
              ),
              
              const SizedBox(height: 16),
              
              // 添付ファイル情報
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.attach_file, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '学級通信.pdf',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            'AI生成PDF • 約125KB',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.picture_as_pdf, color: Colors.red.shade400),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // スケジュール投稿オプション
              CheckboxListTile(
                title: const Text('スケジュール投稿'),
                subtitle: const Text('指定した日時に投稿'),
                value: _scheduledPost,
                onChanged: (value) {
                  setState(() {
                    _scheduledPost = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),
              
              if (_scheduledPost) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _selectScheduleDateTime(context),
                  icon: const Icon(Icons.schedule),
                  label: Text(
                    _scheduledDateTime != null
                        ? '${_scheduledDateTime!.month}/${_scheduledDateTime!.day} ${_scheduledDateTime!.hour}:${_scheduledDateTime!.minute.toString().padLeft(2, '0')}'
                        : '日時を選択',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
            widget.onConfirm();
          },
          icon: const Icon(Icons.send),
          label: Text(_scheduledPost ? 'スケジュール設定' : '投稿'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade600,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
  
  Future<void> _selectScheduleDateTime(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    
    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
          DateTime.now().add(const Duration(hours: 1)),
        ),
      );
      
      if (time != null && mounted) {
        setState(() {
          _scheduledDateTime = DateTime(
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
}

/// Classroom投稿成功ダイアログ
class ClassroomPostSuccessDialog extends StatelessWidget {
  final ClassroomPostResult result;
  
  const ClassroomPostSuccessDialog({
    super.key,
    required this.result,
  });
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green.shade600),
          const SizedBox(width: 8),
          const Text('投稿完了'),
        ],
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            result.isScheduled
                ? 'スケジュール投稿が設定されました！'
                : 'Google Classroomへの投稿が完了しました！',
            style: const TextStyle(fontSize: 16),
          ),
          
          const SizedBox(height: 16),
          
          // 投稿情報
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('タイトル', result.title),
                const SizedBox(height: 8),
                _buildInfoRow(
                  '投稿日時',
                  result.isScheduled
                      ? '${result.postedAt.month}/${result.postedAt.day} ${result.postedAt.hour}:${result.postedAt.minute.toString().padLeft(2, '0')} (予約)'
                      : '投稿済み',
                ),
                const SizedBox(height: 8),
                _buildInfoRow('クラス', '1年1組 クラスルーム'),
                const SizedBox(height: 8),
                _buildInfoRow('通知対象', '生徒・保護者（約75名）'),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 次のステップ
          Text(
            '📱 通知は自動で生徒・保護者に送信されます\n📊 投稿の閲覧状況は後でClassroomで確認できます\n✉️ 重要な連絡事項は追加でメールでもお知らせすることをお勧めします',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
        ],
      ),
      actions: [
        TextButton.icon(
          onPressed: () {
            // モックなので実際のURLは開かない
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('📝 デモモードのため、実際のClassroomは開きません'),
                duration: Duration(seconds: 2),
              ),
            );
          },
          icon: const Icon(Icons.open_in_new),
          label: const Text('Classroomで確認'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('完了'),
        ),
      ],
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }
}