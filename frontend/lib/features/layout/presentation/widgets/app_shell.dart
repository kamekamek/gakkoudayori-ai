import 'package:flutter/material.dart';

/// レイアウトモードの定義
enum LayoutMode {
  desktop, // デスクトップモード（3カラム表示）
  tablet, // タブレットモード（2カラム表示、プレビューは折りたたみ可能）
  mobile, // モバイルモード（1カラム表示、統合ナビゲーション）
}

/// レスポンシブブレークポイントの定義
class Breakpoints {
  static const double mobile = 768;
  static const double tablet = 1024;
  static const double desktop = 1280;
}

/// ナビゲーション項目データモデル
class NavigationItem {
  final String title;
  final IconData icon;
  final Widget page;
  final String tooltip;
  final bool showInMobile;

  NavigationItem({
    required this.title,
    required this.icon,
    required this.page,
    required this.tooltip,
    this.showInMobile = true,
  });
}

/// AppShell - アプリケーションの統合ナビゲーションレイアウトを提供するウィジェット
///
/// 要件に基づく統合ナビゲーション設計を実装：
/// - デスクトップ: 3カラム表示（サイドバー、コンテンツ、プレビュー）
/// - タブレット: 2カラム表示（折りたたみサイドバー、コンテンツ）、タブナビゲーション
/// - モバイル: 1カラム表示（ボトムナビゲーション）、音声入力FAB中心
class AppShell extends StatefulWidget {
  /// ナビゲーション項目リスト
  final List<NavigationItem> navigationItems;

  /// 右側のプレビュー列に表示するウィジェット
  final Widget previewColumn;

  /// アプリバータイトル
  final String title;

  /// デスクトップモード時のナビゲーション幅の割合（0.0〜1.0）
  final double navWidthFactor;

  /// デスクトップモード時のプレビュー幅の割合（0.0〜1.0）
  final double previewWidthFactor;

  /// 音声入力ボタンを表示するかどうか
  final bool showVoiceInput;

  /// 音声入力コールバック
  final VoidCallback? onVoiceInputPressed;

  const AppShell({
    super.key,
    required this.navigationItems,
    required this.previewColumn,
    this.title = 'ゆとり職員室',
    this.navWidthFactor = 0.2,
    this.previewWidthFactor = 0.25,
    this.showVoiceInput = true,
    this.onVoiceInputPressed,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _isPreviewVisible = true;
  bool _isSidebarCollapsed = false;
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  /// 現在の画面サイズに基づいてレイアウトモードを判断する
  LayoutMode _getLayoutMode(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= Breakpoints.tablet) {
      return width >= Breakpoints.desktop
          ? LayoutMode.desktop
          : LayoutMode.tablet;
    }
    return LayoutMode.mobile;
  }

  /// 現在選択されているページを取得
  Widget get _currentPage => widget.navigationItems[_selectedIndex].page;

  @override
  Widget build(BuildContext context) {
    final layoutMode = _getLayoutMode(context);

    switch (layoutMode) {
      case LayoutMode.mobile:
        return _buildMobileLayout(context);
      case LayoutMode.tablet:
        return _buildTabletLayout(context);
      case LayoutMode.desktop:
        return _buildDesktopLayout(context);
    }
  }

  /// モバイルレイアウト: ボトムナビゲーション + 音声入力FAB
  Widget _buildMobileLayout(BuildContext context) {
    final mobileItems =
        widget.navigationItems.where((item) => item.showInMobile).toList();

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.visibility),
            tooltip: 'プレビュー表示',
            onPressed: () => _showPreviewDialog(context),
          ),
        ],
      ),
      body: _currentPage,
      bottomNavigationBar: _buildBottomNavigationBar(mobileItems),
      floatingActionButton:
          widget.showVoiceInput ? _buildVoiceInputFAB(context) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  /// タブレットレイアウト: 折りたたみサイドバー + タブナビゲーション
  Widget _buildTabletLayout(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // 折りたたみ可能サイドバー
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _isSidebarCollapsed
                ? 80
                : MediaQuery.of(context).size.width * widget.navWidthFactor,
            child: _buildSidebar(context, _isSidebarCollapsed),
          ),

          // メインコンテンツエリア
          Expanded(
            child: Scaffold(
              appBar: AppBar(
                automaticallyImplyLeading: false,
                title: Text(widget.navigationItems[_selectedIndex].title),
                actions: [
                  IconButton(
                    icon: Icon(
                        _isSidebarCollapsed ? Icons.menu_open : Icons.menu),
                    tooltip: _isSidebarCollapsed ? 'サイドバーを展開' : 'サイドバーを折りたたみ',
                    onPressed: () => setState(
                        () => _isSidebarCollapsed = !_isSidebarCollapsed),
                  ),
                  IconButton(
                    icon: const Icon(Icons.visibility),
                    tooltip: 'プレビュー表示',
                    onPressed: () => _showPreviewDialog(context),
                  ),
                ],
              ),
              body: _currentPage,
            ),
          ),
        ],
      ),
      floatingActionButton:
          widget.showVoiceInput ? _buildVoiceInputFAB(context) : null,
    );
  }

  /// デスクトップレイアウト: 3カラム構成
  Widget _buildDesktopLayout(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // サイドバーナビゲーション
          SizedBox(
            width: MediaQuery.of(context).size.width * widget.navWidthFactor,
            child: _buildSidebar(context, false),
          ),

          // メインコンテンツエリア
          Expanded(
            child: Scaffold(
              appBar: AppBar(
                automaticallyImplyLeading: false,
                title: Text(widget.navigationItems[_selectedIndex].title),
                actions: [
                  if (!_isPreviewVisible)
                    IconButton(
                      icon: const Icon(Icons.visibility),
                      tooltip: 'プレビューを表示',
                      onPressed: () => setState(() => _isPreviewVisible = true),
                    ),
                ],
              ),
              body: _currentPage,
            ),
          ),

          // プレビューパネル
          if (_isPreviewVisible)
            SizedBox(
              width:
                  MediaQuery.of(context).size.width * widget.previewWidthFactor,
              child: Scaffold(
                appBar: AppBar(
                  automaticallyImplyLeading: false,
                  title: const Text('プレビュー'),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: 'プレビューを閉じる',
                      onPressed: () =>
                          setState(() => _isPreviewVisible = false),
                    ),
                  ],
                ),
                body: widget.previewColumn,
              ),
            ),
        ],
      ),
      floatingActionButton:
          widget.showVoiceInput ? _buildVoiceInputFAB(context) : null,
    );
  }

  /// サイドバーナビゲーションを構築
  Widget _buildSidebar(BuildContext context, bool isCollapsed) {
    return Scaffold(
      appBar: AppBar(
        title: isCollapsed ? null : Text(widget.title),
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 1,
      ),
      body: Column(
        children: [
          if (!isCollapsed) ...[
            // アプリ説明
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                '教師のためのAI通信作成ツール',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
          ],

          // ナビゲーション項目
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              itemCount: widget.navigationItems.length,
              itemBuilder: (context, index) {
                final item = widget.navigationItems[index];
                final isSelected = _selectedIndex == index;

                if (isCollapsed) {
                  return Tooltip(
                    message: item.tooltip,
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          vertical: 4.0, horizontal: 12.0),
                      child: IconButton(
                        icon: Icon(
                          item.icon,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                        onPressed: () => setState(() => _selectedIndex = index),
                        style: IconButton.styleFrom(
                          backgroundColor: isSelected
                              ? Theme.of(context).colorScheme.primaryContainer
                              : null,
                        ),
                      ),
                    ),
                  );
                }

                return Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 2.0),
                  child: InkWell(
                    onTap: () => setState(() => _selectedIndex = index),
                    borderRadius: BorderRadius.circular(8.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 12.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.0),
                        color: isSelected
                            ? Theme.of(context).colorScheme.primaryContainer
                            : null,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item.icon,
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              item.title,
                              style: TextStyle(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 新規作成ボタン
          if (!isCollapsed) ...[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // エディタページ（インデックス1と仮定）に切り替え
                    final editorIndex = widget.navigationItems
                        .indexWhere((item) => item.title == 'エディタ');
                    if (editorIndex != -1) {
                      setState(() => _selectedIndex = editorIndex);
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('新規作成'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                  ),
                ),
              ),
            ),
          ] else ...[
            Tooltip(
              message: '新規作成',
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: FloatingActionButton.small(
                  onPressed: () {
                    final editorIndex = widget.navigationItems
                        .indexWhere((item) => item.title == 'エディタ');
                    if (editorIndex != -1) {
                      setState(() => _selectedIndex = editorIndex);
                    }
                  },
                  child: const Icon(Icons.add),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// ボトムナビゲーションバーを構築
  Widget _buildBottomNavigationBar(List<NavigationItem> items) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _selectedIndex.clamp(0, items.length - 1),
      onTap: (index) => setState(() => _selectedIndex = index),
      items: items
          .map((item) => BottomNavigationBarItem(
                icon: Icon(item.icon),
                label: item.title,
                tooltip: item.tooltip,
              ))
          .toList(),
    );
  }

  /// 音声入力FABを構築（要件に基づく設計）
  Widget _buildVoiceInputFAB(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton.large(
        onPressed: widget.onVoiceInputPressed,
        tooltip: '音声入力を開始',
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        child: const Icon(
          Icons.mic,
          size: 32,
        ),
      ),
    );
  }

  /// プレビューダイアログを表示
  void _showPreviewDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            title: const Text('プレビュー'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: widget.previewColumn,
        ),
      ),
    );
  }
}
