import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 🚀 Revolutionary Innovation 1: スワイプ操作による直感的編集システム
/// プレビュー画面での左右スワイプによる内容編集とタッチジェスチャー対応
class SwipeGestureEditor extends StatefulWidget {
  final Widget child;
  final String htmlContent;
  final Function(String) onContentChanged;
  final Function(double) onFontSizeChanged;
  final Function(String) onEditModeActivated;

  const SwipeGestureEditor({
    Key? key,
    required this.child,
    required this.htmlContent,
    required this.onContentChanged,
    required this.onFontSizeChanged,
    required this.onEditModeActivated,
  }) : super(key: key);

  @override
  State<SwipeGestureEditor> createState() => _SwipeGestureEditorState();
}

class _SwipeGestureEditorState extends State<SwipeGestureEditor>
    with TickerProviderStateMixin {
  
  // ジェスチャー状態管理
  double _currentScale = 1.0;
  double _baseFontSize = 14.0;
  bool _isEditMode = false;
  final String _selectedText = '';
  Offset _tapPosition = Offset.zero;
  
  // アニメーション
  late AnimationController _pulseController;
  late AnimationController _swipeController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _swipeAnimation;
  
  // 編集状態
  bool _showEditingHint = false;
  String _currentEditingSection = '';

  @override
  void initState() {
    super.initState();
    
    // パルスアニメーション（編集可能な要素を示す）
    _pulseController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // スワイプアニメーション
    _swipeController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _swipeAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(0.1, 0),
    ).animate(CurvedAnimation(
      parent: _swipeController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _swipeController.dispose();
    super.dispose();
  }

  /// 🎯 左右スワイプによる編集モード切り替え
  void _handleSwipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    
    if (velocity > 500) {
      // 右スワイプ: 編集モード開始
      _activateEditMode('右スワイプで編集モードを開始');
      _swipeController.forward().then((_) => _swipeController.reverse());
    } else if (velocity < -500) {
      // 左スワイプ: 編集完了・保存
      _finishEditMode();
      _swipeController.forward().then((_) => _swipeController.reverse());
    }
  }

  /// 🎯 ピンチジェスチャーによるフォントサイズ調整
  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (details.scale != 1.0) {
      setState(() {
        _currentScale = details.scale;
        final newFontSize = _baseFontSize * _currentScale;
        widget.onFontSizeChanged(newFontSize.clamp(10.0, 24.0));
      });
    }
  }

  /// 🎯 ダブルタップによる要素選択・編集
  void _handleDoubleTap(TapDownDetails details) {
    setState(() {
      _tapPosition = details.globalPosition;
    });
    
    // タップ領域から編集対象を推測
    final section = _detectEditingSection(details.localPosition);
    _activateEditMode('ダブルタップで「$section」を編集');
    
    // 実際の編集処理を開始
    Future.delayed(Duration(milliseconds: 500), () {
      _editHtmlSection(section, widget.htmlContent);
    });
  }

  /// 🎯 編集対象セクションの検出
  String _detectEditingSection(Offset position) {
    final screenHeight = MediaQuery.of(context).size.height;
    final relativeY = position.dy / screenHeight;
    
    if (relativeY < 0.2) return 'タイトル';
    if (relativeY < 0.4) return '見出し';
    if (relativeY < 0.8) return '本文';
    return 'フッター';
  }

  /// 🎯 HTML要素の実際の編集処理
  void _editHtmlSection(String section, String currentHtml) {
    // セクション別の編集処理
    final Map<String, String> sectionSelectors = {
      'タイトル': 'h1, .title, .newsletter-title',
      '見出し': 'h2, h3, .heading, .section-title',
      '本文': 'p, .content, .main-text',
      'フッター': '.footer, .footer-note, .signature',
    };
    
    final selector = sectionSelectors[section] ?? 'p';
    _showQuickEditDialog(section, selector, currentHtml);
  }

  /// 🎯 クイック編集ダイアログ
  void _showQuickEditDialog(String section, String selector, String currentHtml) {
    final TextEditingController editController = TextEditingController();
    
    // 現在のテキストを抽出（簡易版）
    final RegExp htmlPattern = RegExp(r'<[^>]*>([^<]*)</[^>]*>');
    final matches = htmlPattern.allMatches(currentHtml);
    String extractedText = '';
    if (matches.isNotEmpty) {
      extractedText = matches.first.group(1) ?? '';
    }
    editController.text = extractedText;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.edit, color: Colors.blue[600]),
            SizedBox(width: 8),
            Text('$section を編集'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: editController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: '新しい内容を入力してください',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'スワイプジェスチャーで素早く編集できます',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              final newText = editController.text.trim();
              if (newText.isNotEmpty) {
                // 簡易的なHTML更新（実際の実装ではより堅牢な処理が必要）
                final updatedHtml = _updateHtmlSection(widget.htmlContent, section, newText);
                widget.onContentChanged(updatedHtml);
                Navigator.pop(context);
                HapticFeedback.lightImpact();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
            ),
            child: Text('更新'),
          ),
        ],
      ),
    );
  }

  /// 🎯 HTML内容の部分更新
  String _updateHtmlSection(String htmlContent, String section, String newText) {
    // セクション別の更新パターン
    switch (section) {
      case 'タイトル':
        return htmlContent.replaceFirst(
          RegExp(r'<h1[^>]*>([^<]*)</h1>'),
          '<h1>$newText</h1>',
        );
      case '見出し':
        return htmlContent.replaceFirst(
          RegExp(r'<h[23][^>]*>([^<]*)</h[23]>'),
          '<h2>$newText</h2>',
        );
      case '本文':
        return htmlContent.replaceFirst(
          RegExp(r'<p[^>]*>([^<]*)</p>'),
          '<p>$newText</p>',
        );
      case 'フッター':
        return htmlContent.replaceAll(
          RegExp(r'<div[^>]*class="footer[^"]*"[^>]*>([^<]*)</div>'),
          '<div class="footer">$newText</div>',
        );
      default:
        return htmlContent;
    }
  }

  /// 🎯 編集モード開始
  void _activateEditMode(String message) {
    setState(() {
      _isEditMode = true;
      _showEditingHint = true;
      _currentEditingSection = message;
    });
    
    // ハプティックフィードバック
    HapticFeedback.mediumImpact();
    
    // パルスアニメーション開始
    _pulseController.repeat(reverse: true);
    
    // コールバック呼び出し
    widget.onEditModeActivated(message);
    
    // 3秒後にヒント非表示
    Future.delayed(Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showEditingHint = false;
        });
      }
    });
  }

  /// 🎯 編集モード終了
  void _finishEditMode() {
    setState(() {
      _isEditMode = false;
      _showEditingHint = false;
    });
    
    _pulseController.stop();
    _pulseController.reset();
    
    // ハプティックフィードバック
    HapticFeedback.lightImpact();
  }

  /// 🎯 長押しによるコンテキストメニュー
  void _handleLongPress(LongPressStartDetails details) {
    _showContextMenu(details.globalPosition);
  }

  /// 🎯 コンテキストメニュー表示
  void _showContextMenu(Offset position) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 100,
        position.dy + 100,
      ),
      items: [
        PopupMenuItem(
          child: Row(
            children: [
              Icon(Icons.edit, size: 18),
              SizedBox(width: 8),
              Text('編集'),
            ],
          ),
          onTap: () {
            _activateEditMode('コンテキストメニューから編集');
            // タップ位置から編集対象を特定して編集開始
            Future.delayed(Duration(milliseconds: 300), () {
              final section = _detectEditingSection(_tapPosition);
              _editHtmlSection(section, widget.htmlContent);
            });
          },
        ),
        PopupMenuItem(
          child: Row(
            children: [
              Icon(Icons.format_size, size: 18),
              SizedBox(width: 8),
              Text('文字サイズ'),
            ],
          ),
          onTap: () => _showFontSizeDialog(),
        ),
        PopupMenuItem(
          child: Row(
            children: [
              Icon(Icons.color_lens, size: 18),
              SizedBox(width: 8),
              Text('スタイル変更'),
            ],
          ),
          onTap: () => _showStyleDialog(),
        ),
      ],
    );
  }

  /// 🎯 フォントサイズ調整ダイアログ
  void _showFontSizeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('フォントサイズ調整'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('現在のサイズ: ${_baseFontSize.toInt()}px'),
              Slider(
                value: _baseFontSize,
                min: 10,
                max: 24,
                divisions: 14,
                onChanged: (value) {
                  setState(() {
                    _baseFontSize = value;
                  });
                  widget.onFontSizeChanged(value);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('完了'),
          ),
        ],
      ),
    );
  }

  /// 🎯 スタイル変更ダイアログ
  void _showStyleDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('スタイル変更'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.article),
              title: Text('クラシック'),
              onTap: () {
                widget.onContentChanged('classic_style');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.auto_awesome),
              title: Text('モダン'),
              onTap: () {
                widget.onContentChanged('modern_style');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // スケールジェスチャー（ピンチとパンの両方を処理）
      onScaleUpdate: _handleScaleUpdate,
      onScaleEnd: (details) {
        // スケールが1.0の場合はスワイプとして処理
        if (_currentScale == 1.0 && details.velocity.pixelsPerSecond.dx.abs() > 100) {
          _handleSwipe(DragEndDetails(
            velocity: details.velocity,
            primaryVelocity: details.velocity.pixelsPerSecond.dx,
          ));
        }
      },
      
      // タップジェスチャー
      onTapDown: _handleDoubleTap,
      onDoubleTap: () {}, // onTapDownで処理済み
      
      // 長押しジェスチャー
      onLongPressStart: _handleLongPress,
      
      child: Stack(
        children: [
          // メインコンテンツ
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) => Transform.scale(
              scale: _isEditMode ? _pulseAnimation.value : 1.0,
              child: SlideTransition(
                position: _swipeAnimation,
                child: widget.child,
              ),
            ),
          ),
          
          // 編集ヒント表示
          if (_showEditingHint)
            Positioned(
              top: 50,
              left: 20,
              right: 20,
              child: AnimatedOpacity(
                opacity: _showEditingHint ? 1.0 : 0.0,
                duration: Duration(milliseconds: 300),
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[600],
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.touch_app, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _currentEditingSection,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          
          // ジェスチャーガイド（初回表示時）
          if (_isEditMode && _showEditingHint)
            Positioned(
              bottom: 100,
              left: 20,
              right: 20,
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[300]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.swipe, color: Colors.blue[600]),
                        SizedBox(width: 8),
                        Text(
                          'ジェスチャーガイド',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• 右スワイプ: 編集開始\n'
                      '• 左スワイプ: 編集完了\n'
                      '• ピンチ: 文字サイズ調整\n'
                      '• ダブルタップ: 要素選択\n'
                      '• 長押し: メニュー表示',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 🎯 スワイプ可能なプレビューウィジェット
class SwipeablePreviewWidget extends StatefulWidget {
  final String htmlContent;
  final double height;
  final Function(String)? onContentEdited;

  const SwipeablePreviewWidget({
    Key? key,
    required this.htmlContent,
    required this.height,
    this.onContentEdited,
  }) : super(key: key);

  @override
  State<SwipeablePreviewWidget> createState() => _SwipeablePreviewWidgetState();
}

class _SwipeablePreviewWidgetState extends State<SwipeablePreviewWidget> {
  double _fontSize = 14.0;
  String _currentContent = '';

  @override
  void initState() {
    super.initState();
    _currentContent = widget.htmlContent;
  }

  @override
  Widget build(BuildContext context) {
    return SwipeGestureEditor(
      htmlContent: _currentContent,
      onContentChanged: (newContent) {
        setState(() {
          _currentContent = newContent;
        });
        widget.onContentEdited?.call(newContent);
      },
      onFontSizeChanged: (newSize) {
        setState(() {
          _fontSize = newSize;
        });
      },
      onEditModeActivated: (message) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.blue[600],
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '🚀 スワイプ操作対応プレビュー\n\n'
              '現在のフォントサイズ: ${_fontSize.toInt()}px\n\n'
              'ジェスチャー操作:\n'
              '• 右スワイプで編集開始\n'
              '• ピンチで文字サイズ調整\n'
              '• ダブルタップで要素選択\n'
              '• 長押しでメニュー表示\n\n'
              '${_currentContent.isNotEmpty ? _currentContent : "コンテンツを生成してください"}',
              style: TextStyle(
                fontSize: _fontSize,
                height: 1.5,
                color: Colors.grey[800],
              ),
            ),
          ),
        ),
      ),
    );
  }
}