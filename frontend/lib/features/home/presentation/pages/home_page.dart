import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/newsletter_provider.dart';
import '../../../ai_assistant/presentation/widgets/adk_chat_widget.dart';
import '../../../editor/providers/preview_provider.dart';
import '../widgets/preview_interface.dart';
import '../widgets/mobile_tab_layout.dart';

/// メインのホーム画面（チャットボット形式）
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // 初期設定
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProviders();
    });
  }

  void _initializeProviders() {
    // デフォルトの学校情報を設定（後で設定画面から変更可能）
    final newsletterProvider = context.read<NewsletterProvider>();
    newsletterProvider.updateSchoolInfo(
      schoolName: '〇〇小学校',
      className: '1年1組',
      teacherName: '担任の先生',
    );

    // final chatProvider = context.read<ChatProvider>();
    // final previewProvider = context.read<PreviewProvider>();

    // chatProvider.onNewsletterGenerated = (htmlContent) {
    //   previewProvider.updateHtmlContent(htmlContent);
    // };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.school, size: 24),
            const SizedBox(width: 8),
            const Text('学校だよりAI'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
            tooltip: '設定',
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showHelpDialog(),
            tooltip: 'ヘルプ',
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // レスポンシブレイアウト
          if (constraints.maxWidth < 768) {
            // モバイル：タブ切り替え
            return const MobileTabLayout();
          } else {
            // デスクトップ：左右分割
            return const DesktopLayout();
          }
        },
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('学校だよりAIの使い方'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '1. チャットでAIと会話',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('左側のチャットエリアでAIと会話しながら、学級通信の内容を決めていきます。'),
              SizedBox(height: 16),
              Text(
                '2. リアルタイムプレビュー',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('右側に学級通信のプレビューがリアルタイムで表示されます。'),
              SizedBox(height: 16),
              Text(
                '3. 編集・出力',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('プレビューエリアの上部ボタンで編集・印刷・PDF出力・Classroom投稿ができます。'),
              SizedBox(height: 16),
              Text(
                '4. 音声入力',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('マイクボタンを押して音声で入力することもできます。'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }
}

/// デスクトップレイアウト（左右分割）
class DesktopLayout extends StatelessWidget {
  const DesktopLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 左側：チャットインターフェース
        Expanded(
          flex: 1,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                right: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: const AdkChatWidget(userId: 'user_12345'),
          ),
        ),

        // 右側：プレビューインターフェース
        Expanded(
          flex: 1,
          child: Container(
            color: Theme.of(context).colorScheme.background,
            child: const PreviewInterface(),
          ),
        ),
      ],
    );
  }
}
