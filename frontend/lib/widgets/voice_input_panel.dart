import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class VoiceInputPanel extends StatefulWidget {
  const VoiceInputPanel({super.key});

  @override
  State<VoiceInputPanel> createState() => _VoiceInputPanelState();
}

class _VoiceInputPanelState extends State<VoiceInputPanel>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    // 録音状態に応じてアニメーション制御
    if (appState.isRecording) {
      _pulseController.repeat();
      _waveController.repeat();
    } else {
      _pulseController.stop();
      _waveController.stop();
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 24),
          _buildRecordingArea(context, appState),
          const SizedBox(height: 24),
          _buildTranscriptionArea(context, appState),
          const SizedBox(height: 24),
          _buildQuickCommands(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        const Icon(
          LucideIcons.mic,
          size: 24,
          color: AppTheme.primaryColor,
        ),
        const SizedBox(width: 8),
        Text(
          '音声入力',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(LucideIcons.settings),
          onPressed: () => _showVoiceSettings(context),
          tooltip: '音声設定',
        ),
      ],
    );
  }

  Widget _buildRecordingArea(BuildContext context, AppState appState) {
    return Card(
      elevation: appState.isRecording ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: appState.isRecording
              ? LinearGradient(
                  colors: [
                    AppTheme.primaryColor.withOpacity(0.1),
                    AppTheme.accentColor.withOpacity(0.1),
                  ],
                )
              : null,
        ),
        child: Column(
          children: [
            // 録音ボタン
            GestureDetector(
              onTap: () => _toggleRecording(context, appState),
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: appState.isRecording
                          ? AppTheme.errorColor
                          : AppTheme.primaryColor,
                      boxShadow: appState.isRecording
                          ? [
                              BoxShadow(
                                color: AppTheme.errorColor.withOpacity(
                                    0.3 + _pulseController.value * 0.3),
                                blurRadius: 20 + _pulseController.value * 20,
                                spreadRadius: _pulseController.value * 10,
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: AppTheme.primaryColor.withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                    ),
                    child: Icon(
                      appState.isRecording
                          ? LucideIcons.square
                          : LucideIcons.mic,
                      size: 48,
                      color: Colors.white,
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // 状態テキスト
            Text(
              appState.isRecording ? '録音中...' : 'タップして録音開始',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: appState.isRecording
                        ? AppTheme.errorColor
                        : AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),

            if (appState.isRecording) ...[
              const SizedBox(height: 16),
              _buildVoiceWaveform(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceWaveform() {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final delay = index * 0.2;
            final animationValue = (_waveController.value + delay) % 1.0;
            final height = 4 + animationValue * 16;

            return Container(
              width: 4,
              height: height,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: AppTheme.errorColor,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildTranscriptionArea(BuildContext context, AppState appState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  LucideIcons.fileText,
                  size: 20,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'リアルタイム字幕',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const Spacer(),
                if (appState.currentTranscription.isNotEmpty)
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 16),
                    onPressed: () => appState.clearTranscription(),
                    tooltip: 'クリア',
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              height: 120,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: SingleChildScrollView(
                child: Text(
                  appState.currentTranscription.isEmpty
                      ? '音声認識されたテキストがここに表示されます'
                      : appState.currentTranscription,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: appState.currentTranscription.isEmpty
                            ? Colors.grey[500]
                            : Colors.black87,
                      ),
                ),
              ),
            ),
            if (appState.currentTranscription.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _addToEditor(context, appState.currentTranscription),
                      icon: const Icon(LucideIcons.plus, size: 16),
                      label: const Text('エディタに追加'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () =>
                        _improveWithAI(context, appState.currentTranscription),
                    icon: const Icon(LucideIcons.sparkles, size: 16),
                    label: const Text('AI改善'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickCommands(BuildContext context) {
    final commands = [
      {'title': '今日の出来事', 'command': '今日のクラスの様子について話してください'},
      {'title': '連絡事項', 'command': '保護者への連絡事項をお話しください'},
      {'title': '学習内容', 'command': '今日の学習内容について話してください'},
      {'title': 'お知らせ', 'command': '来週の予定やお知らせを話してください'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'クイックコマンド',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: commands.map((command) {
            return ActionChip(
              label: Text(command['title']!),
              onPressed: () => _useQuickCommand(context, command['command']!),
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              labelStyle: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _toggleRecording(BuildContext context, AppState appState) {
    if (appState.isRecording) {
      appState.stopRecording();
      // TODO: 実際の録音停止処理

      // サンプルの音声認識結果
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return; // ウィジェットが破棄されている場合は処理をスキップ
        appState.updateTranscription('今日は運動会の練習をしました。子どもたちはとても頑張っていて、'
            'リレーの練習では白熱した競争が繰り広げられました。'
            '本番までもう少しですが、みんなで力を合わせて素晴らしい運動会にしましょう。');
      });
    } else {
      appState.startRecording();
      // TODO: 実際の録音開始処理
    }
  }

  void _addToEditor(BuildContext context, String text) {
    // TODO: エディタにテキスト追加
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('エディタにテキストを追加しました'),
        backgroundColor: AppTheme.accentColor,
      ),
    );
  }

  void _improveWithAI(BuildContext context, String text) async {
    final apiService = Provider.of<ApiService>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        title: Row(
          children: [
            Icon(LucideIcons.sparkles, color: AppTheme.secondaryColor),
            SizedBox(width: 8),
            Text('AI改善中'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppTheme.secondaryColor),
            SizedBox(height: 16),
            Text('Gemini AIがテキストを改善しています...'),
          ],
        ),
      ),
    );

    try {
      // 実際のAI API呼び出し
      final result = await apiService.enhanceText(
        text: text,
        style: 'friendly',
        gradeLevel: 'elementary',
      );

      if (mounted) {
        Navigator.of(context).pop();

        // APIレスポンスから改善されたテキストを取得
        final improvedText = result['data']['enhanced_text'] ?? text;
        context.read<AppState>().updateTranscription(improvedText);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AIがテキストを改善しました！'),
            backgroundColor: AppTheme.secondaryColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('AI改善に失敗しました: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _useQuickCommand(BuildContext context, String command) {
    // TODO: クイックコマンドの実装
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('「$command」でプロンプトを設定しました'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _showVoiceSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('音声設定'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('ノイズ抑制'),
              subtitle: const Text('背景雑音を軽減'),
              value: true,
              onChanged: (value) {
                // TODO: ノイズ抑制設定
              },
            ),
            SwitchListTile(
              title: const Text('自動句読点'),
              subtitle: const Text('話し方に応じて自動で句読点を挿入'),
              value: true,
              onChanged: (value) {
                // TODO: 自動句読点設定
              },
            ),
            ListTile(
              title: const Text('ユーザー辞書'),
              subtitle: const Text('カスタム用語を登録'),
              trailing: const Icon(LucideIcons.chevronRight),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: ユーザー辞書画面へ
              },
            ),
          ],
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
