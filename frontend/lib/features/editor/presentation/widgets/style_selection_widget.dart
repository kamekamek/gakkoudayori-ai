import 'package:flutter/material.dart';
import '../../../../core/models/models.dart';

/// スタイル選択ウィジェット
/// 
/// 音声入力直後に表示される従来のスタイル選択UI
/// ADKマルチエージェントシステムとの統合対応
class StyleSelectionWidget extends StatefulWidget {
  final NewsletterStyle? selectedStyle;
  final Function(NewsletterStyle)? onStyleSelected;
  final Function()? onCreateNewsletter;
  final bool isProcessing;
  final String transcribedText;

  const StyleSelectionWidget({
    Key? key,
    this.selectedStyle,
    this.onStyleSelected,
    this.onCreateNewsletter,
    this.isProcessing = false,
    this.transcribedText = '',
  }) : super(key: key);

  @override
  State<StyleSelectionWidget> createState() => _StyleSelectionWidgetState();
}

class _StyleSelectionWidgetState extends State<StyleSelectionWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              if (widget.transcribedText.isNotEmpty) ...[
                _buildTranscribedTextPreview(),
                const SizedBox(height: 20),
              ],
              _buildStyleOptions(),
              const SizedBox(height: 24),
              _buildCreateButton(),
              const SizedBox(height: 12),
              _buildADKInfo(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.palette,
          color: Theme.of(context).primaryColor,
          size: 28,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🎨 スタイル選択',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '学級通信のスタイルを選択してください',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTranscribedTextPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.transcribe,
                size: 16,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                '音声認識結果',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.transcribedText.length > 200
                ? '${widget.transcribedText.substring(0, 200)}...'
                : widget.transcribedText,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (widget.transcribedText.length > 200)
            Text(
              '（${widget.transcribedText.length}文字）',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStyleOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📋 学級通信のスタイルを選択:',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStyleOption(
                style: NewsletterStyle.classic,
                title: 'クラシック',
                description: '伝統的で読みやすい\n信頼性重視',
                icon: Icons.article,
                color: const Color(0xFF1976D2),
                promptInfo: 'CLASSIC_TENSAKU.md\nCLASSIC_LAYOUT.md',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStyleOption(
                style: NewsletterStyle.modern,
                title: 'モダン',
                description: 'インフォグラフィック的\n視覚的美しさ重視',
                icon: Icons.auto_awesome,
                color: const Color(0xFFFF9800),
                promptInfo: 'MODERN_TENSAKU.md\nMODERN_LAYOUT.md',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStyleOption({
    required NewsletterStyle style,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required String promptInfo,
  }) {
    final isSelected = widget.selectedStyle == style;
    
    return GestureDetector(
      onTap: () => widget.onStyleSelected?.call(style),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 28,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isSelected ? color : Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                height: 1.4,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                promptInfo,
                style: const TextStyle(
                  fontSize: 9,
                  fontFamily: 'monospace',
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: 8),
              Icon(
                Icons.check_circle,
                color: color,
                size: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCreateButton() {
    final canCreate = widget.selectedStyle != null && !widget.isProcessing;
    
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: canCreate ? widget.onCreateNewsletter : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.selectedStyle != null
              ? (widget.selectedStyle == NewsletterStyle.classic
                  ? const Color(0xFF1976D2)
                  : const Color(0xFFFF9800))
              : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: widget.isProcessing
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('ADKエージェント処理中...'),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.psychology, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    '学級通信を作成する',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildADKInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: Colors.blue.shade700,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'ADKマルチエージェントシステムが7つの専門エージェントで高品質な学級通信を生成します',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// スタイル比較ダイアログ
class StyleComparisonDialog extends StatelessWidget {
  const StyleComparisonDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('📋 スタイル比較'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildComparisonTable(),
            const SizedBox(height: 16),
            _buildPromptInfo(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('閉じる'),
        ),
      ],
    );
  }

  Widget _buildComparisonTable() {
    return Table(
      border: TableBorder.all(color: Colors.grey.shade300),
      children: [
        const TableRow(
          decoration: BoxDecoration(color: Colors.grey),
          children: [
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('項目', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('クラシック', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('モダン', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        _buildTableRow('デザイン', '伝統的・シンプル', 'インフォグラフィック的'),
        _buildTableRow('レイアウト', 'シングルカラム', 'ビジュアル重視'),
        _buildTableRow('カラー', '落ち着いたトーン', '鮮やかなトーン'),
        _buildTableRow('適用場面', '公式文書・保護者配布', 'イベント・特別号'),
      ],
    );
  }

  TableRow _buildTableRow(String item, String classic, String modern) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(item, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(classic),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(modern),
        ),
      ],
    );
  }

  Widget _buildPromptInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🤖 使用されるAIプロンプト',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('クラシック: CLASSIC_TENSAKU.md + CLASSIC_LAYOUT.md'),
          const Text('モダン: MODERN_TENSAKU.md + MODERN_LAYOUT.md'),
          const SizedBox(height: 8),
          Text(
            '各プロンプトは教育現場の慣習に特化して最適化されています。',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}