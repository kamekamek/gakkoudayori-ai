import 'package:flutter/material.dart';
import '../widgets/ai_functions_grid.dart';
import '../widgets/ai_function_button.dart';

/// AI機能ボタンのデモページ
///
/// T3-UI-002-A実装完了後の動作確認用ページ
class AIFunctionsDemoPage extends StatefulWidget {
  const AIFunctionsDemoPage({Key? key}) : super(key: key);

  @override
  State<AIFunctionsDemoPage> createState() => _AIFunctionsDemoPageState();
}

class _AIFunctionsDemoPageState extends State<AIFunctionsDemoPage> {
  AIFunctionType? _processingType;
  String _lastExecutedFunction = '未実行';
  final List<String> _executionLog = [];

  void _onFunctionPressed(AIFunctionType type) {
    setState(() {
      _processingType = type;
    });

    // 模擬AI処理
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _processingType = null;
          _lastExecutedFunction = _getFunctionName(type);
          _executionLog.insert(0,
              '${DateTime.now().toString().substring(11, 19)} - $_lastExecutedFunction実行完了');

          // ログを最大10件に制限
          if (_executionLog.length > 10) {
            _executionLog.removeLast();
          }
        });

        // 実行完了をスナックバーで通知
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$_lastExecutedFunction が完了しました'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  String _getFunctionName(AIFunctionType type) {
    switch (type) {
      case AIFunctionType.addGreeting:
        return '挨拶文生成';
      case AIFunctionType.addSchedule:
        return '予定作成';
      case AIFunctionType.rewrite:
        return '文章改善';
      case AIFunctionType.generateHeading:
        return '見出し生成';
      case AIFunctionType.summarize:
        return '要約作成';
      case AIFunctionType.expand:
        return '詳細展開';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI機能ボタン デモ'),
        backgroundColor: Colors.blue.shade100,
        foregroundColor: Colors.blue.shade800,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // デモ説明
            _buildDemoDescription(),
            const SizedBox(height: 16),

            // AI機能ボタングリッド
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: AIFunctionsGrid(
                processingType: _processingType,
                onFunctionPressed: _onFunctionPressed,
              ),
            ),

            const SizedBox(height: 20),

            // 実行状態表示
            _buildStatusDisplay(),

            const SizedBox(height: 20),

            // 実行ログ
            _buildExecutionLog(),
          ],
        ),
      ),
    );
  }

  Widget _buildDemoDescription() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🚀 T3-UI-002-A 実装完了',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'AI機能ボタンが正常に実装されました。各ボタンをクリックして動作を確認できます。',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            '✅ 6種類のAI機能ボタン\n'
            '✅ ローディング状態表示\n'
            '✅ グリッドレイアウト\n'
            '✅ アイコン・ラベル配置',
            style: TextStyle(
              fontSize: 12,
              color: Colors.green.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDisplay() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(
            _processingType != null
                ? Icons.hourglass_empty
                : Icons.check_circle,
            color: _processingType != null ? Colors.orange : Colors.green,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '現在の状態',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  _processingType != null
                      ? '${_getFunctionName(_processingType!)}実行中...'
                      : '待機中',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (_processingType != null)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }

  Widget _buildExecutionLog() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '実行ログ',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          if (_executionLog.isEmpty)
            Text(
              'まだ実行履歴がありません',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            )
          else
            ...(_executionLog.map((log) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    log,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontFamily: 'monospace',
                    ),
                  ),
                ))),
        ],
      ),
    );
  }
}
