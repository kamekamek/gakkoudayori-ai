import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gakkoudayori_ai/features/auth/auth_provider.dart';
import 'package:gakkoudayori_ai/services/google_auth_service.dart';
import '../../../ai_assistant/presentation/widgets/adk_chat_widget.dart';
import '../../../ai_assistant/presentation/widgets/demo_chat_widget.dart';
import '../../../editor/providers/preview_provider.dart';
import '../../../editor/providers/demo_preview_provider.dart';
import '../widgets/preview_interface.dart';
import '../widgets/demo_preview_interface.dart';
import '../widgets/mobile_tab_layout.dart';
import '../../../ai_assistant/providers/adk_chat_provider.dart';
import '../../../ai_assistant/providers/demo_chat_provider.dart';
import '../../../../main.dart';
import 'package:provider/provider.dart' as legacy_provider;

/// メインのホーム画面（チャットボット形式）
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late final TextEditingController titleController;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController();
    // 初期設定
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProviders();
    });
  }

  void _initializeProviders() {
    final isDemoMode = ref.read(demoModeProvider);
    
    // デモモードでは初期化をスキップ
    if (isDemoMode) {
      debugPrint('[HomePage] デモモードのため初期化をスキップ');
      return;
    }
    
    // 通常モードのみ：NewsletterProviderV2は自動的にユーザー設定を読み込むため、手動初期化は不要

    // ADKチャットプロバイダーにプレビュープロバイダーを設定
    try {
      final adkChatProvider = context.read<AdkChatProvider>();
      final previewProvider = context.read<PreviewProvider>();
      
      adkChatProvider.setPreviewProvider(previewProvider);
      debugPrint('[HomePage] AdkChatProvider に PreviewProvider を設定しました');
    } catch (e) {
      debugPrint('[HomePage] Provider初期化エラー（通常モード用プロバイダーが見つからない場合があります）: $e');
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDemoMode = ref.watch(demoModeProvider);
    final user = ref.watch(authStateChangesProvider).asData?.value;
    
    // デモモードの場合は認証状態をチェックしない
    if (isDemoMode) {
      return _buildDemoLayout();
    }

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
          if (user != null && MediaQuery.of(context).size.width > 600)
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
                try {
                  await GoogleAuthService.signOut();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ログアウトしました')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('ログアウトエラー: $e')),
                    );
                  }
                }
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

  Widget _buildDemoLayout() {
    return legacy_provider.MultiProvider(
      providers: [
        legacy_provider.ChangeNotifierProvider(create: (_) => DemoChatProvider()),
        legacy_provider.ChangeNotifierProvider(create: (_) => DemoPreviewProvider()),
      ],
      child: Scaffold(
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
            // スマホでは表示を簡素化
            if (MediaQuery.of(context).size.width > 600)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Center(
                  child: Text(
                    'demo@school.example.com',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
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
            // レスポンシブレイアウト
            if (constraints.maxWidth < 768) {
              // モバイル：タブ切り替え
              return const DemoMobileTabLayout();
            } else {
              // デスクトップ：左右分割
              return const DemoDesktopLayout();
            }
          },
        ),
      ),
    );
  }
}

/// デモ用デスクトップレイアウト
class DemoDesktopLayout extends StatelessWidget {
  const DemoDesktopLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 左側：デモチャットインターフェース
        const Expanded(
          flex: 1,
          child: DemoChatWidget(),
        ),
        const VerticalDivider(width: 1),
        // 右側：デモプレビューインターフェース
        Expanded(
          flex: 1,
          child: Container(
            color: const Color(0xFFFAFAFA),
            child: const DemoPreviewInterface(),
          ),
        ),
      ],
    );
  }
}

/// デモ用モバイルタブレイアウト
class DemoMobileTabLayout extends StatefulWidget {
  const DemoMobileTabLayout({super.key});

  @override
  State<DemoMobileTabLayout> createState() => _DemoMobileTabLayoutState();
}

class _DemoMobileTabLayoutState extends State<DemoMobileTabLayout>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.chat),
              text: 'チャット',
            ),
            Tab(
              icon: Icon(Icons.preview),
              text: 'プレビュー',
            ),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              DemoChatWidget(),
              DemoPreviewInterface(),
            ],
          ),
        ),
      ],
    );
  }
}

/// デスクトップレイアウト（左右分割・デザインモックアップ準拠）
class DesktopLayout extends StatefulWidget {
  const DesktopLayout({super.key});

  @override
  State<DesktopLayout> createState() => _DesktopLayoutState();
}

class _DesktopLayoutState extends State<DesktopLayout> {

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 左側：チャットインターフェース（冗長UI削除済み）
        Expanded(
          flex: 1,
          child: Consumer(
            builder: (context, ref, child) {
              final authState = ref.watch(authStateChangesProvider);
              return authState.when(
                data: (user) => user != null
                    ? AdkChatWidget(userId: user.uid)
                    : const Center(child: Text("ログインしてください")),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text("エラー: $error")),
              );
            },
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
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

