import "package:flutter/material.dart";

/// カスタム指示入力フィールドコンポーネント
///
/// AIへの具体的な指示を入力するためのテキストフィールド
///
/// 特徴:
/// - プレースホルダーテキスト表示
/// - 最大文字数制限とバリデーション
/// - サンプル指示の表示・選択機能
/// - 処理中状態の表示
class CustomInstructionField extends StatefulWidget {
  /// 現在の指示内容
  final String instruction;

  /// 指示内容変更時のコールバック
  final Function(String) onChanged;

  /// 生成ボタン押下時のコールバック
  final VoidCallback onSubmit;

  /// 処理中かどうか
  final bool isProcessing;

  /// サンプル指示を表示するかどうか
  final bool showSamples;

  /// 最大文字数
  final int maxLength;

  const CustomInstructionField({
    Key? key,
    required this.instruction,
    required this.onChanged,
    required this.onSubmit,
    this.isProcessing = false,
    this.showSamples = false,
    this.maxLength = 200,
  }) : super(key: key);

  @override
  State<CustomInstructionField> createState() => _CustomInstructionFieldState();
}

class _CustomInstructionFieldState extends State<CustomInstructionField> {
  late TextEditingController _controller;
  bool _showError = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.instruction);
  }

  @override
  void didUpdateWidget(CustomInstructionField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.instruction != widget.instruction) {
      _controller.text = widget.instruction;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (!widget.isProcessing && _controller.text.trim().isNotEmpty) {
      widget.onSubmit();
    }
  }

  void _validateInput(String value) {
    final isOverLength = value.length > widget.maxLength;
    if (_showError != isOverLength) {
      setState(() {
        _showError = isOverLength;
      });
    }
  }

  bool get _hasError => _controller.text.length > widget.maxLength;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // メイン入力フィールド
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: _hasError
                ? Border.all(color: Colors.red, width: 2)
                : Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: '例：もっと親しみやすい文章にして',
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  maxLines: 3,
                  minLines: 1,
                  onChanged: (value) {
                    widget.onChanged(value);
                    _validateInput(value);
                  },
                  onSubmitted: (_) {
                    if (!widget.isProcessing) {
                      widget.onSubmit();
                    }
                  },
                  textInputAction: TextInputAction.done,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: widget.isProcessing ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: widget.isProcessing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('生成'),
              ),
            ],
          ),
        ),

        // 文字数表示・エラーメッセージ
        Padding(
          padding: const EdgeInsets.only(top: 4, left: 8),
          child: Row(
            children: [
              Text(
                '${_controller.text.length}/${widget.maxLength}',
                style: TextStyle(
                  fontSize: 12,
                  color: _hasError ? Colors.red : Colors.grey.shade600,
                ),
              ),
              if (_hasError) ...[
                const SizedBox(width: 8),
                Text(
                  '${widget.maxLength}文字以内で入力してください',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.red,
                  ),
                ),
              ],
            ],
          ),
        ),

        // サンプル指示
        if (widget.showSamples) ...[
          const SizedBox(height: 12),
          _buildSampleInstructions(),
        ],
      ],
    );
  }

  Widget _buildSampleInstructions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'サンプル指示',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: CustomInstructionSamples.defaultSamples
              .map((sample) => _buildSampleChip(sample))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildSampleChip(String sample) {
    return GestureDetector(
      onTap: () {
        _controller.text = sample;
        widget.onChanged(sample);
        _validateInput(sample);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Text(
          sample,
          style: TextStyle(
            fontSize: 12,
            color: Colors.blue.shade700,
          ),
        ),
      ),
    );
  }
}

/// カスタム指示のサンプル集
class CustomInstructionSamples {
  /// デフォルトのサンプル指示一覧
  static const List<String> defaultSamples = [
    'もっと親しみやすい文章にして',
    '丁寧で正式な表現に変更',
    '短くまとめて',
    '具体例を追加して',
    '保護者向けの説明を追加',
    '子どもたちの様子を詳しく',
    '季節の要素を入れて',
    'より明るい表現に変更',
  ];

  /// カテゴリ別サンプル指示
  static const Map<String, List<String>> categorizedSamples = {
    '文体調整': [
      'もっと親しみやすい文章にして',
      '丁寧で正式な表現に変更',
      'より明るい表現に変更',
      'カジュアルな表現に変更',
    ],
    '内容調整': [
      '短くまとめて',
      '具体例を追加して',
      'より詳しく説明して',
      '重要なポイントを強調して',
    ],
    '対象別': [
      '保護者向けの説明を追加',
      '子どもたちの様子を詳しく',
      '教職員向けの内容に調整',
      '地域の方向けの表現に',
    ],
    '季節・イベント': [
      '季節の要素を入れて',
      '行事の雰囲気を表現して',
      '学期末の振り返りを追加',
      '新学期の期待を込めて',
    ],
  };

  /// カテゴリ名を取得
  static List<String> getCategories() {
    return categorizedSamples.keys.toList();
  }

  /// 指定カテゴリのサンプルを取得
  static List<String> getSamplesByCategory(String category) {
    return categorizedSamples[category] ?? [];
  }
}
