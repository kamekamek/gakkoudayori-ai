import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/quill_editor_provider.dart';

/// 文体選択ウィジェット（モダン/クラシック）
///
/// 画像フローの「テイストを選ぶ」機能に対応
/// AIによる文章生成時の文体を選択できる
class ToneSelectorWidget extends StatelessWidget {
  const ToneSelectorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<QuillEditorProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ヘッダー
              Row(
                children: [
                  Icon(
                    Icons.palette_outlined,
                    color: Theme.of(context).primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'テイスト選択',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'AI文章生成の文体を選択してください',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),

              // テイスト選択ボタン
              Row(
                children: [
                  Expanded(
                    child: _buildToneButton(
                      context: context,
                      tone: ToneType.modern,
                      title: 'モダン',
                      description: '親しみやすく現代的',
                      icon: Icons.trending_up,
                      isSelected: provider.selectedTone == ToneType.modern,
                      onTap: () => provider.setSelectedTone(ToneType.modern),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildToneButton(
                      context: context,
                      tone: ToneType.classic,
                      title: 'クラシック',
                      description: '丁寧で格調高い',
                      icon: Icons.menu_book,
                      isSelected: provider.selectedTone == ToneType.classic,
                      onTap: () => provider.setSelectedTone(ToneType.classic),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 選択中テイストの説明
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.blue.shade200,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue.shade600,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getToneDescription(provider.selectedTone),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildToneButton({
    required BuildContext context,
    required ToneType tone,
    required String title,
    required String description,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? Colors.white70 : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getToneDescription(ToneType tone) {
    switch (tone) {
      case ToneType.modern:
        return 'カジュアルで親しみやすい表現。保護者との距離感を縮めた現代的な文体です。';
      case ToneType.classic:
        return '格調高く丁寧な表現。伝統的で落ち着いた印象の文体です。';
    }
  }
}

/// テイストタイプ enum
enum ToneType {
  modern,
  classic,
}

/// テイスト選択ウィジェットの設定
class ToneConfig {
  static const Map<ToneType, Map<String, String>> tonePrompts = {
    ToneType.modern: {
      'style': 'カジュアル・親しみやすい・現代的',
      'prompt_suffix': 'フレンドリーで親しみやすい現代的な表現で、保護者の方との距離感を縮めるような文体でお書きください。',
      'example': '今日は子どもたちがとても頑張っていて、見ていて嬉しくなっちゃいました！',
    },
    ToneType.classic: {
      'style': '丁寧・格調高い・伝統的',
      'prompt_suffix': '格調高く丁寧な表現で、伝統的で落ち着いた印象を与える文体でお書きください。',
      'example': '本日の子どもたちの学習への取り組みは、誠に素晴らしいものでございました。',
    },
  };

  /// 指定されたテイストのプロンプト接尾辞を取得
  static String getPromptSuffix(ToneType tone) {
    return tonePrompts[tone]?['prompt_suffix'] ?? '';
  }

  /// 指定されたテイストのスタイル説明を取得
  static String getStyleDescription(ToneType tone) {
    return tonePrompts[tone]?['style'] ?? '';
  }

  /// 指定されたテイストの例文を取得
  static String getExample(ToneType tone) {
    return tonePrompts[tone]?['example'] ?? '';
  }
}
