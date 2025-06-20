import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 対話入力ウィジェット
class ConversationInputWidget extends StatefulWidget {
  final String currentStep;
  final Map<String, dynamic>? stepData;
  final TextEditingController controller;
  final Function(Map<String, dynamic>) onSendResponse;

  const ConversationInputWidget({
    Key? key,
    required this.currentStep,
    this.stepData,
    required this.controller,
    required this.onSendResponse,
  }) : super(key: key);

  @override
  State<ConversationInputWidget> createState() => _ConversationInputWidgetState();
}

class _ConversationInputWidgetState extends State<ConversationInputWidget> {
  String? _selectedOption;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ステップ別入力UI
          _buildStepSpecificInput(),
          
          const SizedBox(height: 12),
          
          // 送信ボタン
          if (_canSendResponse())
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _sendResponse,
                icon: const Icon(Icons.send),
                label: Text(
                  _getSendButtonLabel(),
                  style: GoogleFonts.notoSansJp(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStepSpecificInput() {
    switch (widget.currentStep) {
      case 'content_review':
        return _buildContentReviewInput();
      case 'design_selection':
        return _buildDesignSelectionInput();
      case 'html_review':
        return _buildHtmlReviewInput();
      case 'final_approval':
        return _buildFinalApprovalInput();
      default:
        return _buildGenericInput();
    }
  }

  Widget _buildContentReviewInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'コンテンツの確認',
          style: GoogleFonts.notoSansJp(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        _buildRadioOptions([
          {'id': 'approve', 'label': '✅ この内容で進める'},
          {'id': 'modify', 'label': '📝 内容を修正する'},
          {'id': 'regenerate', 'label': '🔄 内容を再生成する'},
        ]),
        
        // 修正要求の場合のテキスト入力
        if (_selectedOption == 'modify') ...[
          const SizedBox(height: 12),
          TextField(
            controller: widget.controller,
            decoration: InputDecoration(
              labelText: '修正内容を入力してください',
              hintText: '例: もう少し具体的なエピソードを追加してください',
              border: const OutlineInputBorder(),
              labelStyle: GoogleFonts.notoSansJp(fontSize: 12),
              hintStyle: GoogleFonts.notoSansJp(fontSize: 10),
            ),
            maxLines: 3,
            style: GoogleFonts.notoSansJp(fontSize: 14),
          ),
        ],
      ],
    );
  }

  Widget _buildDesignSelectionInput() {
    final designOptions = widget.stepData?['design_options'] as List<dynamic>? ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'デザインの選択',
          style: GoogleFonts.notoSansJp(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        if (designOptions.isNotEmpty)
          Column(
            children: designOptions.map<Widget>((option) {
              final optionMap = option as Map<String, dynamic>;
              final optionId = optionMap['id'] as String;
              final optionName = optionMap['name'] as String;
              
              return RadioListTile<String>(
                value: optionId,
                groupValue: _selectedOption,
                onChanged: (value) {
                  setState(() {
                    _selectedOption = value;
                  });
                },
                title: Text(
                  optionName,
                  style: GoogleFonts.notoSansJp(fontSize: 12),
                ),
                dense: true,
              );
            }).toList(),
          )
        else
          Text(
            'デザインオプションを読み込み中...',
            style: GoogleFonts.notoSansJp(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
      ],
    );
  }

  Widget _buildHtmlReviewInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'プレビューの確認',
          style: GoogleFonts.notoSansJp(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        _buildRadioOptions([
          {'id': 'approve', 'label': '✅ 完璧です！'},
          {'id': 'minor_changes', 'label': '📝 少し修正したい'},
          {'id': 'major_changes', 'label': '🔄 大幅に変更したい'},
        ]),
        
        // 修正要求の場合のテキスト入力
        if (_selectedOption == 'minor_changes') ...[
          const SizedBox(height: 12),
          TextField(
            controller: widget.controller,
            decoration: InputDecoration(
              labelText: '修正点を入力してください',
              hintText: '例: もう少し色を明るくしてください',
              border: const OutlineInputBorder(),
              labelStyle: GoogleFonts.notoSansJp(fontSize: 12),
              hintStyle: GoogleFonts.notoSansJp(fontSize: 10),
            ),
            maxLines: 3,
            style: GoogleFonts.notoSansJp(fontSize: 14),
          ),
        ],
      ],
    );
  }

  Widget _buildFinalApprovalInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '最終確認',
          style: GoogleFonts.notoSansJp(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        _buildRadioOptions([
          {'id': 'generate_pdf', 'label': '📄 PDF生成・ダウンロード'},
          {'id': 'save_draft', 'label': '💾 下書き保存'},
          {'id': 'back_to_edit', 'label': '📝 編集に戻る'},
        ]),
      ],
    );
  }

  Widget _buildGenericInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'メッセージを入力',
          style: GoogleFonts.notoSansJp(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: widget.controller,
          decoration: InputDecoration(
            hintText: 'メッセージを入力してください...',
            border: const OutlineInputBorder(),
            hintStyle: GoogleFonts.notoSansJp(fontSize: 12),
          ),
          maxLines: 2,
          style: GoogleFonts.notoSansJp(fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildRadioOptions(List<Map<String, String>> options) {
    return Column(
      children: options.map((option) {
        return RadioListTile<String>(
          value: option['id']!,
          groupValue: _selectedOption,
          onChanged: (value) {
            setState(() {
              _selectedOption = value;
            });
          },
          title: Text(
            option['label']!,
            style: GoogleFonts.notoSansJp(fontSize: 12),
          ),
          dense: true,
        );
      }).toList(),
    );
  }

  bool _canSendResponse() {
    if (_selectedOption == null) return false;
    
    // 修正要求の場合はテキスト入力も必要
    if ((_selectedOption == 'modify' || _selectedOption == 'minor_changes') &&
        widget.controller.text.trim().isEmpty) {
      return false;
    }
    
    return true;
  }

  String _getSendButtonLabel() {
    switch (_selectedOption) {
      case 'approve':
        return '承認して次へ';
      case 'modify':
      case 'minor_changes':
        return '修正要求を送信';
      case 'regenerate':
      case 'major_changes':
        return '再生成を依頼';
      case 'generate_pdf':
        return 'PDF生成開始';
      case 'save_draft':
        return '下書き保存';
      case 'back_to_edit':
        return '編集に戻る';
      default:
        return '送信';
    }
  }

  void _sendResponse() {
    final response = <String, dynamic>{
      'action': _selectedOption!,
    };
    
    // デザイン選択の場合
    if (widget.currentStep == 'design_selection') {
      response['selected_design_id'] = _selectedOption!;
    }
    
    // 修正要求の場合
    if ((_selectedOption == 'modify' || _selectedOption == 'minor_changes') &&
        widget.controller.text.trim().isNotEmpty) {
      response['modification_request'] = widget.controller.text.trim();
    }
    
    // 入力をクリア
    widget.controller.clear();
    setState(() {
      _selectedOption = null;
    });
    
    widget.onSendResponse(response);
  }
}