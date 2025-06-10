import 'package:flutter/material.dart';
import 'ai_function_button.dart';

/// AI機能ボタンのグリッド表示ウィジェット
///
/// 6つのAI機能ボタンを3列2行のグリッドで配置
///
/// 特徴:
/// - レスポンシブなグリッドレイアウト
/// - 各ボタンの処理状態を管理
/// - 統一されたボタンコールバック処理
class AIFunctionsGrid extends StatelessWidget {
  /// 現在処理中の機能タイプ（null = 処理なし）
  final AIFunctionType? processingType;

  /// AI機能実行時のコールバック
  final Function(AIFunctionType) onFunctionPressed;

  const AIFunctionsGrid({
    Key? key,
    this.processingType,
    required this.onFunctionPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI機能',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),
          const SizedBox(height: 8),
          _buildButtonGrid(),
        ],
      ),
    );
  }

  /// ボタンのグリッドを構築
  Widget _buildButtonGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: AIFunctionConfig.defaultConfigs.length,
      itemBuilder: (context, index) {
        final config = AIFunctionConfig.defaultConfigs[index];
        final isProcessing = processingType == config.type;

        return AIFunctionButton(
          title: config.title,
          icon: config.icon,
          functionType: config.type,
          isProcessing: isProcessing,
          onPressed: () => onFunctionPressed(config.type),
        );
      },
    );
  }
}

/// AI機能ボタン群の説明テキスト表示
class AIFunctionsDescription extends StatelessWidget {
  const AIFunctionsDescription({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ワンクリックAI機能',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '各ボタンをクリックしてAI機能を実行できます。'
            'エディタ内のテキストを選択してから実行すると、'
            'より具体的な結果が得られます。',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// AI機能の詳細説明
class AIFunctionDescriptions {
  static const Map<AIFunctionType, String> descriptions = {
    AIFunctionType.addGreeting: '季節に応じた適切な挨拶文を生成し、エディタに挿入します',
    AIFunctionType.addSchedule: '学校行事やイベントの予定を箇条書きで生成します',
    AIFunctionType.rewrite: '選択したテキストをより読みやすく改善します',
    AIFunctionType.generateHeading: '内容に適した見出しを自動生成します',
    AIFunctionType.summarize: '長い文章を簡潔にまとめます',
    AIFunctionType.expand: '内容をより詳しく展開し、具体例を追加します',
  };

  /// 機能タイプの説明テキストを取得
  static String getDescription(AIFunctionType type) {
    return descriptions[type] ?? '未定義の機能です';
  }
}
