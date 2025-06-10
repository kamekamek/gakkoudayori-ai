import 'package:flutter/material.dart';

/// レイアウトモードの定義
enum LayoutMode {
  desktop, // デスクトップモード（3カラム表示）
  tablet, // タブレットモード（2カラム表示、プレビューは折りたたみ可能）
  mobile, // モバイルモード（1カラム表示、ナビゲーションはドロワー）
}

/// レスポンシブブレークポイントの定義
class Breakpoints {
  static const double mobile = 768;
  static const double tablet = 1024;
  static const double desktop = 1280;
}

/// AppShell - アプリケーションの基本レイアウトを提供するウィジェット
///
/// 3カラム構成のレスポンシブデザインを実装し、画面サイズに応じて自動的にレイアウトを調整します。
/// - デスクトップ: 3カラム表示（ナビゲーション、コンテンツ、プレビュー）
/// - タブレット: 2カラム表示（ナビゲーション、コンテンツ）、プレビューは折りたたみ可能
/// - モバイル: 1カラム表示（コンテンツのみ）、ナビゲーションはドロワー、プレビューはボタンで表示
class AppShell extends StatefulWidget {
  /// 左側のナビゲーション列に表示するウィジェット
  final Widget navigationColumn;

  /// 中央の主要コンテンツ列に表示するウィジェット
  final Widget centerColumn;

  /// 右側のプレビュー列に表示するウィジェット
  final Widget previewColumn;

  /// アプリバータイトル
  final String title;

  /// デスクトップモード時のナビゲーション幅の割合（0.0〜1.0）
  final double navWidthFactor;

  /// デスクトップモード時のプレビュー幅の割合（0.0〜1.0）
  final double previewWidthFactor;

  const AppShell({
    super.key,
    required this.navigationColumn,
    required this.centerColumn,
    required this.previewColumn,
    this.title = 'ゆとり教室',
    this.navWidthFactor = 0.2,
    this.previewWidthFactor = 0.25,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _isPreviewVisible = true;
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

  @override
  Widget build(BuildContext context) {
    final layoutMode = _getLayoutMode(context);

    // モバイルモード時はドロワースタイルのナビゲーション
    if (layoutMode == LayoutMode.mobile) {
      return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text(widget.title),
          leading: IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.visibility),
              onPressed: () => _showPreviewDialog(context),
            ),
          ],
        ),
        drawer: Drawer(
          child: widget.navigationColumn,
        ),
        body: widget.centerColumn,
      );
    }

    // タブレットモード時は2カラムレイアウト
    if (layoutMode == LayoutMode.tablet) {
      return Scaffold(
        body: Row(
          children: [
            // ナビゲーション列
            SizedBox(
              width: MediaQuery.of(context).size.width * widget.navWidthFactor,
              child: Scaffold(
                appBar: AppBar(
                  title: Text(widget.title),
                  automaticallyImplyLeading: false,
                ),
                body: widget.navigationColumn,
              ),
            ),

            // 中央コンテンツ列
            Expanded(
              child: Scaffold(
                appBar: AppBar(
                  automaticallyImplyLeading: false,
                  title: const Text('編集'),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.visibility),
                      onPressed: () => _showPreviewDialog(context),
                    ),
                  ],
                ),
                body: widget.centerColumn,
              ),
            ),
          ],
        ),
      );
    }

    // デスクトップモード時は3カラムレイアウト
    return Scaffold(
      body: Row(
        children: [
          // ナビゲーション列
          SizedBox(
            width: MediaQuery.of(context).size.width * widget.navWidthFactor,
            child: Scaffold(
              appBar: AppBar(
                title: Text(widget.title),
                automaticallyImplyLeading: false,
              ),
              body: widget.navigationColumn,
            ),
          ),

          // 中央コンテンツ列
          Expanded(
            child: Scaffold(
              appBar: AppBar(
                automaticallyImplyLeading: false,
                title: const Text('編集'),
              ),
              body: widget.centerColumn,
            ),
          ),

          // プレビュー列
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
                      onPressed: () =>
                          setState(() => _isPreviewVisible = false),
                    ),
                  ],
                ),
                body: widget.previewColumn,
              ),
            ),

          // プレビュー表示ボタン（プレビューが非表示の場合）
          if (!_isPreviewVisible)
            IconButton(
              icon: const Icon(Icons.visibility),
              onPressed: () => setState(() => _isPreviewVisible = true),
            ),
        ],
      ),
    );
  }

  /// モバイルモード時のプレビューダイアログを表示
  void _showPreviewDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('プレビュー'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Expanded(child: widget.previewColumn),
          ],
        ),
      ),
    );
  }
}
