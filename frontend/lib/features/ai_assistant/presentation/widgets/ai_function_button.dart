import 'package:flutter/material.dart';

// AI機能タイプの定義
enum AIFunctionType {
  addGreeting,
  addSchedule,
  rewrite,
  generateHeading,
  summarize,
  expand,
}

/// AI機能ボタンコンポーネント
///
/// 各AI機能（挨拶文生成、予定作成、文章改善など）を実行するためのボタン
///
/// 特徴:
/// - アイコンとタイトルを含む縦型レイアウト
/// - 処理中はローディング表示
/// - 6種類のAI機能に対応
class AIFunctionButton extends StatelessWidget {
  /// ボタンのタイトル
  final String title;

  /// ボタンのアイコン
  final IconData icon;

  /// AI機能のタイプ
  final AIFunctionType functionType;

  /// ボタンが押されたときのコールバック
  final VoidCallback onPressed;

  /// 処理中かどうか
  final bool isProcessing;

  const AIFunctionButton({
    Key? key,
    required this.title,
    required this.icon,
    required this.functionType,
    required this.onPressed,
    this.isProcessing = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 80,
      child: ElevatedButton(
        onPressed: isProcessing ? null : onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          backgroundColor: Colors.white,
          foregroundColor: Colors.blue.shade700,
          side: BorderSide(
            color: Colors.blue.shade200,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isProcessing)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              )
            else
              Icon(
                icon,
                size: 24,
                color: Colors.blue.shade700,
              ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isProcessing ? Colors.grey : Colors.blue.shade700,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// AI機能ボタンの設定情報を保持するクラス
class AIFunctionConfig {
  final String title;
  final IconData icon;
  final AIFunctionType type;

  const AIFunctionConfig({
    required this.title,
    required this.icon,
    required this.type,
  });

  /// 定義済みAI機能の設定一覧
  static const List<AIFunctionConfig> defaultConfigs = [
    AIFunctionConfig(
      title: '挨拶文生成',
      icon: Icons.waving_hand_outlined,
      type: AIFunctionType.addGreeting,
    ),
    AIFunctionConfig(
      title: '予定作成',
      icon: Icons.event_note_outlined,
      type: AIFunctionType.addSchedule,
    ),
    AIFunctionConfig(
      title: '文章改善',
      icon: Icons.auto_fix_high_outlined,
      type: AIFunctionType.rewrite,
    ),
    AIFunctionConfig(
      title: '見出し生成',
      icon: Icons.title_outlined,
      type: AIFunctionType.generateHeading,
    ),
    AIFunctionConfig(
      title: '要約作成',
      icon: Icons.summarize_outlined,
      type: AIFunctionType.summarize,
    ),
    AIFunctionConfig(
      title: '詳細展開',
      icon: Icons.unfold_more_outlined,
      type: AIFunctionType.expand,
    ),
  ];
}
