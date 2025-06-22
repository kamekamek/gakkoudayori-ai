import 'package:flutter/material.dart';
import 'chat_interface.dart';
import 'preview_interface.dart';

/// モバイル版タブレイアウト
class MobileTabLayout extends StatefulWidget {
  const MobileTabLayout({super.key});

  @override
  State<MobileTabLayout> createState() => _MobileTabLayoutState();
}

class _MobileTabLayoutState extends State<MobileTabLayout>
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
        // タブバー
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
            indicatorColor: Theme.of(context).colorScheme.primary,
            indicatorWeight: 3,
            labelStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: Theme.of(context).textTheme.titleMedium,
            tabs: const [
              Tab(
                icon: Icon(Icons.chat, size: 20),
                text: 'チャット',
              ),
              Tab(
                icon: Icon(Icons.preview, size: 20),
                text: 'プレビュー',
              ),
            ],
          ),
        ),

        // タブコンテンツ
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              // チャットタブ
              ChatInterface(),
              
              // プレビュータブ
              PreviewInterface(),
            ],
          ),
        ),
      ],
    );
  }
}