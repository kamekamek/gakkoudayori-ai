import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gakkoudayori_ai/features/auth/auth_provider.dart';
import 'package:gakkoudayori_ai/services/google_auth_service.dart';
import '../../providers/newsletter_provider.dart';
import '../../../ai_assistant/presentation/widgets/adk_chat_widget.dart';
import '../../../editor/providers/preview_provider.dart';
import '../widgets/preview_interface.dart';
import '../widgets/mobile_tab_layout.dart';
import '../../../ai_assistant/providers/adk_chat_provider.dart';
import 'package:provider/provider.dart' as legacy_provider;

/// メインのホーム画面（チャットボット形式）
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
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
    final newsletterProvider =
        legacy_provider.Provider.of<NewsletterProvider>(context, listen: false);
    newsletterProvider.updateSchoolInfo(
      schoolName: '〇〇小学校',
      className: '1年1組',
      teacherName: '担任の先生',
    );

    // ADKチャットプロバイダーにプレビュープロバイダーを設定
    final adkChatProvider = context.read<AdkChatProvider>();
    final previewProvider = context.read<PreviewProvider>();
    
    adkChatProvider.setPreviewProvider(previewProvider);
    print('[HomePage] AdkChatProvider に PreviewProvider を設定しました');
  }

  @override
  Widget build(BuildContext context) {
    // AdkChatProviderを監視して、変更があったらUIを再ビルド
    final adkChatProvider =
        legacy_provider.Provider.of<AdkChatProvider>(context);

    // ビルド完了後にプロバイダー間のデータ連携を行う
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final newHtml = adkChatProvider.generatedHtml;
      final previewProvider =
          legacy_provider.Provider.of<PreviewProvider>(context, listen: false);

      // 無限ループを防ぐため、現在のプレビュー内容と異なる場合のみ更新
      if (newHtml != null &&
          newHtml.isNotEmpty &&
          newHtml != previewProvider.htmlContent) {
        previewProvider.updateHtmlContent(newHtml);
      }
    });

    final user = ref.watch(authStateChangesProvider).asData?.value;

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
          if (user != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Center(
                  child: Text(user.email ?? 'No email',
                      style: const TextStyle(fontSize: 12))),
            ),
          if (user != null)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await GoogleAuthService.signOut();
              },
              tooltip: 'ログアウト',
            ),
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
          // レスポンシブレイアウト（デザインモックアッ���準拠）
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

/// デスクトップレイアウト（左右分割・デザインモックアップ準拠）
class DesktopLayout extends StatelessWidget {
  const DesktopLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 左側：チャットインターフェース
        Expanded(
          flex: 1,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: '記事のタイトル',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.image_outlined),
                    tooltip: '画像を追加',
                    onPressed: () async {
                      // (画像アップロードのロジックは省略)
                    },
                  ),
                ],
              ),
              Expanded(
                child: user != null
                    ? AdkChatWidget(userId: user.uid)
                    : const Center(child: Text("ログインしてください")),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        const Expanded(
          flex: 1,
          child: Container(
            color: const Color(0xFFFAFAFA),
            child: const PreviewInterface(),
          ),
        ),
      ],
    );
  }
}

