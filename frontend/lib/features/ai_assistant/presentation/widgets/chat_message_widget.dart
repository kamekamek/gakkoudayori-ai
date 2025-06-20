import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../pages/conversational_newsletter_page.dart';

/// チャットメッセージウィジェット
class ChatMessageWidget extends StatelessWidget {
  final ChatMessage message;
  final Function(Map<String, dynamic>) onOptionSelected;

  const ChatMessageWidget({
    Key? key,
    required this.message,
    required this.onOptionSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            // AIアバター
            CircleAvatar(
              backgroundColor: _getAgentColor(message.sender),
              child: Icon(
                _getAgentIcon(message.sender),
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
          ],
          
          // メッセージ本体
          Expanded(
            child: Column(
              crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // 送信者名
                if (!message.isUser)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      message.sender,
                      style: GoogleFonts.notoSansJp(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getAgentColor(message.sender),
                      ),
                    ),
                  ),
                
                // メッセージバブル
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.8,
                  ),
                  decoration: BoxDecoration(
                    color: message.isUser ? Colors.blue[600] : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // メッセージテキスト
                      Text(
                        message.content,
                        style: GoogleFonts.notoSansJp(
                          fontSize: 14,
                          color: message.isUser ? Colors.white : Colors.black87,
                          height: 1.4,
                        ),
                      ),
                      
                      // データ表示（コンテンツプレビューなど）
                      if (message.data != null) ...[
                        const SizedBox(height: 12),
                        _buildDataDisplay(context, message.data!),
                      ],
                      
                      // 選択肢ボタン
                      if (message.options != null && message.options!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _buildOptionsWidget(context, message.options!),
                      ],
                    ],
                  ),
                ),
                
                // タイムスタンプ
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _formatTimestamp(message.timestamp),
                    style: GoogleFonts.notoSansJp(
                      fontSize: 10,
                      color: Colors.grey[500],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          if (message.isUser) ...[
            const SizedBox(width: 12),
            // ユーザーアバター
            CircleAvatar(
              backgroundColor: Colors.blue[600],
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDataDisplay(BuildContext context, Map<String, dynamic> data) {
    final stepType = message.stepType;
    
    if (stepType == 'content_review' && data.containsKey('generated_content')) {
      return _buildContentPreview(context, data['generated_content']);
    } else if (stepType == 'design_selection' && data.containsKey('design_options')) {
      return _buildDesignOptions(context, List<Map<String, dynamic>>.from(data['design_options']));
    } else if (stepType == 'html_review' && data.containsKey('html_content')) {
      return _buildHtmlPreview(context, data['html_content']);
    } else if (stepType == 'complete' && data.containsKey('completion_summary')) {
      return _buildCompletionSummary(context, data['completion_summary']);
    }
    
    return const SizedBox.shrink();
  }

  Widget _buildContentPreview(BuildContext context, String content) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.article, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '生成されたコンテンツ',
                style: GoogleFonts.notoSansJp(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content.length > 200 ? '${content.substring(0, 200)}...' : content,
            style: GoogleFonts.notoSansJp(
              fontSize: 12,
              color: Colors.grey[700],
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesignOptions(BuildContext context, List<Map<String, dynamic>> designOptions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'デザインオプション',
          style: GoogleFonts.notoSansJp(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: designOptions.length,
            itemBuilder: (context, index) {
              final option = designOptions[index];
              return Container(
                width: 150,
                margin: const EdgeInsets.only(right: 8),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          option['name'] ?? '',
                          style: GoogleFonts.notoSansJp(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Center(
                              child: Icon(Icons.palette, size: 24),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHtmlPreview(BuildContext context, String htmlContent) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.web, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                'HTMLプレビュー',
                style: GoogleFonts.notoSansJp(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  // プレビューモーダル表示
                  _showPreviewModal(context, htmlContent);
                },
                child: Text(
                  'プレビュー表示',
                  style: GoogleFonts.notoSansJp(fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: const Center(
              child: Icon(Icons.description, size: 32, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionSummary(BuildContext context, Map<String, dynamic> summary) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, size: 16, color: Colors.green[600]),
              const SizedBox(width: 4),
              Text(
                '完成サマリー',
                style: GoogleFonts.notoSansJp(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '総ステップ数: ${summary['total_steps'] ?? 0}',
            style: GoogleFonts.notoSansJp(fontSize: 11),
          ),
          Text(
            '所要時間: ${summary['total_time'] ?? '不明'}',
            style: GoogleFonts.notoSansJp(fontSize: 11),
          ),
          Text(
            '品質スコア: ${summary['quality_score'] ?? 0}/100',
            style: GoogleFonts.notoSansJp(fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsWidget(BuildContext context, List<Map<String, dynamic>> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: options.map((option) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 8),
          child: OutlinedButton.icon(
            onPressed: () => _handleOptionSelected(option),
            icon: Icon(_getOptionIcon(option['id'] ?? ''), size: 16),
            label: Text(
              option['label'] ?? '',
              style: GoogleFonts.notoSansJp(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              alignment: Alignment.centerLeft,
            ),
          ),
        );
      }).toList(),
    );
  }

  void _handleOptionSelected(Map<String, dynamic> option) {
    final optionId = option['id'] ?? '';
    
    if (optionId == 'modify') {
      // 修正要求の場合はテキスト入力ダイアログを表示
      _showModificationDialog(optionId);
    } else {
      // 通常の選択
      onOptionSelected({
        'action': optionId,
        if (optionId.startsWith('design_')) 'selected_design_id': optionId,
      });
    }
  }

  void _showModificationDialog(String optionId) {
    // TODO: 修正要求ダイアログの実装
    // 現在は簡易実装
    onOptionSelected({
      'action': optionId,
      'modification_request': '修正をお願いします',
    });
  }

  void _showPreviewModal(BuildContext context, String htmlContent) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('プレビュー'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: SingleChildScrollView(
              child: Text(
                htmlContent,
                style: GoogleFonts.notoSansJp(fontSize: 10),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('閉じる'),
            ),
          ],
        );
      },
    );
  }

  Color _getAgentColor(String agentName) {
    switch (agentName.toLowerCase()) {
      case 'content writer':
        return Colors.green[600]!;
      case 'layout designer':
        return Colors.purple[600]!;
      case 'html generator':
        return Colors.orange[600]!;
      case 'quality checker':
        return Colors.blue[600]!;
      case 'system':
        return Colors.grey[600]!;
      default:
        return Colors.blue[600]!;
    }
  }

  IconData _getAgentIcon(String agentName) {
    switch (agentName.toLowerCase()) {
      case 'content writer':
        return Icons.edit;
      case 'layout designer':
        return Icons.palette;
      case 'html generator':
        return Icons.code;
      case 'quality checker':
        return Icons.check_circle;
      case 'system':
        return Icons.info;
      default:
        return Icons.smart_toy;
    }
  }

  IconData _getOptionIcon(String optionId) {
    switch (optionId) {
      case 'approve':
        return Icons.check;
      case 'modify':
        return Icons.edit;
      case 'regenerate':
        return Icons.refresh;
      case 'generate_pdf':
        return Icons.picture_as_pdf;
      case 'save_draft':
        return Icons.save;
      default:
        return Icons.radio_button_unchecked;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'たった今';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}時間前';
    } else {
      return '${timestamp.month}/${timestamp.day} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}