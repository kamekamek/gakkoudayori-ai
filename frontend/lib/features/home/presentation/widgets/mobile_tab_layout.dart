import 'package:flutter/material.dart';

import '../../../ai_assistant/presentation/widgets/adk_chat_widget.dart';
import 'preview_interface.dart';

/// モバイル用のタブレイアウト
class MobileTabLayout extends StatelessWidget {
  const MobileTabLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          toolbarHeight: 0,
          bottom: TabBar(
            tabs: const [
              Tab(icon: Icon(Icons.chat), text: 'チャット'),
              Tab(icon: Icon(Icons.preview), text: 'プレビュー'),
            ],
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
          ),
        ),
        body: const TabBarView(
          children: [
            // チャットタブ
            AdkChatWidget(userId: 'user_12345'),
            // プレビュータブ
            PreviewInterface(),
          ],
        ),
      ),
    );
  }
}
