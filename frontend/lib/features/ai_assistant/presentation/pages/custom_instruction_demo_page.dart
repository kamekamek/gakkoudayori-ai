import 'package:flutter/material.dart';
import '../widgets/custom_instruction_field.dart';

/// カスタム指示入力フィールドのデモページ
///
/// T3-UI-003-A実装完了後の動作確認用ページ
class CustomInstructionDemoPage extends StatefulWidget {
  const CustomInstructionDemoPage({Key? key}) : super(key: key);

  @override
  State<CustomInstructionDemoPage> createState() =>
      _CustomInstructionDemoPageState();
}

class _CustomInstructionDemoPageState extends State<CustomInstructionDemoPage> {
  String _instruction = '';
  bool _isProcessing = false;
  bool _showSamples = true;
  final List<String> _submissionHistory = [];

  void _handleSubmit() {
    if (_instruction.trim().isEmpty) return;

    setState(() {
      _isProcessing = true;
    });

    // 模擬AI処理（2秒のローディング）
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _submissionHistory.insert(0, _instruction);
          _instruction = ''; // 送信後にクリア
        });

        // 送信完了のスナックバー表示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('指示を送信しました: "${_submissionHistory.first}"'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });
  }

  void _clearHistory() {
    setState(() {
      _submissionHistory.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('カスタム指示デモ'),
        backgroundColor: Colors.blue.shade50,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // デモ説明
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'カスタム指示入力デモ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'AIへの具体的な指示を入力して学級通信の内容を調整できます。\n'
                      'サンプル指示をタップするか、自由に文章を入力してください。\n'
                      '最大200文字まで入力できます。',
                      style: TextStyle(fontSize: 14, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // カスタム指示入力フィールド
            Text(
              'AI指示入力',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),

            CustomInstructionField(
              instruction: _instruction,
              onChanged: (value) {
                setState(() {
                  _instruction = value;
                });
              },
              onSubmit: _handleSubmit,
              isProcessing: _isProcessing,
              showSamples: _showSamples,
              maxLength: 200,
            ),

            const SizedBox(height: 24),

            // 現在の状態表示
            Row(
              children: [
                Text(
                  '現在の状態: ',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _isProcessing
                        ? Colors.orange.shade100
                        : Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _isProcessing ? '処理中...' : '待機中',
                    style: TextStyle(
                      fontSize: 12,
                      color: _isProcessing
                          ? Colors.orange.shade700
                          : Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Text(
              '入力中: "${_instruction.isEmpty ? '(なし)' : _instruction}"',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),

            // 送信履歴
            if (_submissionHistory.isNotEmpty) ...[
              const SizedBox(height: 32),
              Text(
                '送信履歴 (${_submissionHistory.length}件)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 12),
              ...List.generate(_submissionHistory.length, (index) {
                final instruction = _submissionHistory[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          instruction,
                          style: const TextStyle(fontSize: 14, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
