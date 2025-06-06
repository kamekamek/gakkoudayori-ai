import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
// import 'package:flutter_html/flutter_html.dart';

import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class HtmlEditorPanel extends StatefulWidget {
  const HtmlEditorPanel({super.key});

  @override
  State<HtmlEditorPanel> createState() => _HtmlEditorPanelState();
}

class _HtmlEditorPanelState extends State<HtmlEditorPanel> {
  final TextEditingController _htmlController = TextEditingController();
  String _currentContent = '';
  bool _isPreviewMode = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeEditor();
  }

  void _initializeEditor() {
    // デフォルトのグラレコ風HTMLテンプレートを設定
    const initialContent =
        '''<div style="font-family: 'Comic Sans MS', cursive; padding: 20px; background: linear-gradient(45deg, #fff9e6, #f0f8ff); border-radius: 15px;">
  <div style="text-align: center; margin-bottom: 30px;">
    <div style="background: #ffeb3b; border-radius: 20px; padding: 15px; box-shadow: 3px 3px 10px rgba(0,0,0,0.1); margin: 0 auto; max-width: 300px; position: relative;">
      <h1 style="margin: 0; color: #333; font-size: 24px; font-weight: bold;">📢 今日のお知らせ</h1>
    </div>
  </div>
  
  <div style="background: white; border-radius: 15px; padding: 20px; margin-bottom: 20px; box-shadow: 2px 2px 8px rgba(0,0,0,0.05); border: 3px solid #e0e0e0;">
    <h2 style="color: #4caf50; font-size: 20px; margin-bottom: 15px;">
      🌸 運動会の練習について
    </h2>
    <p style="line-height: 1.8; color: #333; font-size: 16px;">
      今日は運動会の練習を行いました。みんな一生懸命頑張っていました！
    </p>
  </div>
  
  <div style="text-align: center; margin-top: 30px;">
    <div style="background: #f8f9fa; border-radius: 10px; padding: 15px; border: 2px dashed #ccc;">
      <p style="margin: 0; color: #666; font-size: 14px;">✏️ ここをクリックして内容を編集できます</p>
    </div>
  </div>
</div>''';

    _currentContent = initialContent;
    _htmlController.text = initialContent;
    setState(() => _isInitialized = true);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildToolbar(),
        Expanded(
          child: Row(
            children: [
              // HTMLエディタ（左）
              Expanded(
                flex: 1,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          border: Border(
                            bottom: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.code, size: 16),
                            const SizedBox(width: 8),
                            const Text('HTMLコード',
                                style: TextStyle(fontWeight: FontWeight.w600)),
                            const Spacer(),
                            IconButton(
                              onPressed: () => setState(
                                  () => _isPreviewMode = !_isPreviewMode),
                              icon: Icon(_isPreviewMode
                                  ? LucideIcons.edit
                                  : LucideIcons.eye),
                              iconSize: 16,
                              tooltip: _isPreviewMode ? 'エディタ表示' : 'プレビュー表示',
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: TextField(
                            controller: _htmlController,
                            maxLines: null,
                            expands: true,
                            style: const TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 12,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'HTMLコードを入力してください...',
                              border: InputBorder.none,
                            ),
                            onChanged: (value) {
                              setState(() => _currentContent = value);
                              _notifyContentChange(value);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // プレビュー（右）
              Expanded(
                flex: 1,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          border: Border(
                            bottom: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(LucideIcons.eye, size: 16),
                            SizedBox(width: 8),
                            Text('プレビュー',
                                style: TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(8),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Text(
                              'HTMLプレビュー\n\n' +
                                  _currentContent.replaceAll(
                                      RegExp(r'<[^>]*>'), '\n'),
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        _buildStatusBar(),
      ],
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        children: [
          // グラレコ風テンプレート適用ボタン
          ElevatedButton.icon(
            onPressed: _applyGraphicalTemplate,
            icon: const Icon(LucideIcons.palette, size: 16),
            label: const Text('グラレコ風'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              textStyle: const TextStyle(fontSize: 12),
            ),
          ),

          const SizedBox(width: 8),

          // 季節テーマ適用ボタン
          ElevatedButton.icon(
            onPressed: _applySeasonalTheme,
            icon: const Icon(LucideIcons.leaf, size: 16),
            label: const Text('季節テーマ'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              textStyle: const TextStyle(fontSize: 12),
            ),
          ),

          const SizedBox(width: 8),

          // 吹き出し挿入ボタン
          IconButton(
            onPressed: _insertSpeechBubble,
            icon: const Icon(LucideIcons.messageCircle),
            tooltip: '吹き出し挿入',
            iconSize: 18,
          ),

          // アイコン挿入ボタン
          IconButton(
            onPressed: _insertIcon,
            icon: const Icon(LucideIcons.smile),
            tooltip: 'アイコン挿入',
            iconSize: 18,
          ),

          const Spacer(),

          // HTMLモード表示
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  LucideIcons.code,
                  size: 12,
                  color: Colors.blue,
                ),
                const SizedBox(width: 4),
                Text(
                  'HTMLモード',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        children: [
          Text(
            '文字数: ${_countWords(_currentContent)}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            _isInitialized ? '準備完了' : '初期化中...',
            style: TextStyle(
              fontSize: 12,
              color: _isInitialized ? Colors.green : Colors.orange,
            ),
          ),
          const Spacer(),
          Text(
            'グラレコ風編集モード',
            style: TextStyle(
              fontSize: 12,
              color: Colors.green[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _notifyContentChange(String content) {
    // AppStateに内容変更を通知
    // TODO: HTMLコンテンツをAppStateに保存
    debugPrint('HTML content updated: ${content.length} characters');
  }

  void _applyGraphicalTemplate() {
    const graphicalTemplate = '''
      <div style="font-family: 'Comic Sans MS', cursive; background: linear-gradient(135deg, #ff9a9e 0%, #fecfef 50%, #fecfef 100%); padding: 30px; border-radius: 20px; position: relative;">
        <div style="position: absolute; top: 10px; right: 10px; font-size: 30px;">✨</div>
        <h1 style="text-align: center; color: #333; background: #fff; border-radius: 50px; padding: 15px; box-shadow: 0 4px 15px rgba(0,0,0,0.1); margin-bottom: 25px;">
          🌟 今日の学級通信 🌟
        </h1>
        <div style="background: white; border-radius: 15px; padding: 20px; margin: 20px 0; box-shadow: 0 5px 20px rgba(0,0,0,0.1); border: 3px solid #ffeb3b;">
          <p>ここに内容を入力してください... 🎈</p>
        </div>
      </div>
    ''';

    _insertTextAtCursor(graphicalTemplate);
  }

  void _applySeasonalTheme() {
    final appState = context.read<AppState>();
    final season = appState.currentSeasonName;

    Map<String, String> seasonalStyles = {
      '春':
          'background: linear-gradient(45deg, #ffb6c1, #98fb98); color: #2e7d32;',
      '夏':
          'background: linear-gradient(45deg, #87ceeb, #ffeb3b); color: #1565c0;',
      '秋':
          'background: linear-gradient(45deg, #daa520, #cd853f); color: #5d4037;',
      '冬':
          'background: linear-gradient(45deg, #b0c4de, #ffffff); color: #1976d2;',
    };

    final style = seasonalStyles[season] ?? seasonalStyles['春']!;

    final seasonalTemplate = '''
      <div style="$style padding: 25px; border-radius: 15px; box-shadow: 0 8px 25px rgba(0,0,0,0.15);">
        <h2>${_getSeasonEmoji(season)} ${season}のお知らせ ${_getSeasonEmoji(season)}</h2>
        <p>季節に合わせたデザインが適用されました。</p>
      </div>
    ''';

    _insertTextAtCursor(seasonalTemplate);
  }

  String _getSeasonEmoji(String season) {
    switch (season) {
      case '春':
        return '🌸';
      case '夏':
        return '🌻';
      case '秋':
        return '🍁';
      case '冬':
        return '⛄';
      default:
        return '🌟';
    }
  }

  void _insertSpeechBubble() {
    const speechBubbleHtml = '''
      <div style="position: relative; background: #ffeb3b; border-radius: 20px; padding: 15px; margin: 15px 0; max-width: 300px; box-shadow: 0 3px 10px rgba(0,0,0,0.2);">
        <p style="margin: 0; font-weight: bold;">💬 ここに重要なメッセージを入力</p>
        <div style="position: absolute; bottom: -8px; left: 30px; width: 0; height: 0; border-left: 8px solid transparent; border-right: 8px solid transparent; border-top: 8px solid #ffeb3b;"></div>
      </div>
    ''';

    _insertTextAtCursor(speechBubbleHtml);
  }

  void _insertIcon() {
    // アイコン選択ダイアログを表示
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('アイコンを選択'),
        content: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            '📚',
            '✏️',
            '🎓',
            '🏫',
            '👨‍🏫',
            '👩‍🏫',
            '🧑‍🎓',
            '📝',
            '🎨',
            '🎵',
            '⚽',
            '🏃‍♀️',
            '🎭',
            '🔬',
            '📐',
            '🖥️'
          ]
              .map((emoji) => GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      _insertTextAtCursor(
                          '<span style="font-size: 24px; margin: 0 5px;">$emoji</span>');
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 24)),
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }

  void _insertTextAtCursor(String text) {
    final currentPosition = _htmlController.selection.baseOffset;
    final currentText = _htmlController.text;

    final newText = currentText.substring(0, currentPosition) +
        text +
        currentText.substring(currentPosition);

    _htmlController.text = newText;
    _htmlController.selection = TextSelection.collapsed(
      offset: currentPosition + text.length,
    );

    setState(() => _currentContent = newText);
    _notifyContentChange(newText);
  }

  int _countWords(String content) {
    // HTML タグを除去して文字数をカウント
    final text = content.replaceAll(RegExp(r'<[^>]*>'), '');
    return text.trim().length;
  }

  @override
  void dispose() {
    _htmlController.dispose();
    super.dispose();
  }
}
