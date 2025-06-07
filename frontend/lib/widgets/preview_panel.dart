import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../theme/app_theme.dart';

class PreviewPanel extends StatefulWidget {
  const PreviewPanel({super.key});

  @override
  State<PreviewPanel> createState() => _PreviewPanelState();
}

class _PreviewPanelState extends State<PreviewPanel> {
  bool _isWebView = true; // true: Web表示, false: PDF表示
  double _scale = 1.0;
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 16),
          Expanded(
            child: _buildPreviewArea(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        const Icon(
          LucideIcons.eye,
          size: 24,
          color: AppTheme.primaryColor,
        ),
        const SizedBox(width: 8),
        Text(
          'プレビュー',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        
        // 表示切り替えボタン
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment<bool>(
              value: true,
              label: Text('Web'),
              icon: Icon(LucideIcons.globe, size: 16),
            ),
            ButtonSegment<bool>(
              value: false,
              label: Text('PDF'),
              icon: Icon(LucideIcons.fileText, size: 16),
            ),
          ],
          selected: {_isWebView},
          onSelectionChanged: (Set<bool> newSelection) {
            setState(() {
              _isWebView = newSelection.first;
            });
          },
        ),
        
        const SizedBox(width: 8),
        
        // ズームコントロール
        Row(
          children: [
            IconButton(
              icon: const Icon(LucideIcons.zoomOut, size: 16),
              onPressed: _scale > 0.5 ? () => _updateScale(_scale - 0.1) : null,
              tooltip: 'ズームアウト',
            ),
            Text(
              '${(_scale * 100).round()}%',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            IconButton(
              icon: const Icon(LucideIcons.zoomIn, size: 16),
              onPressed: _scale < 2.0 ? () => _updateScale(_scale + 0.1) : null,
              tooltip: 'ズームイン',
            ),
          ],
        ),
        
        // その他のアクション
        PopupMenuButton<String>(
          icon: const Icon(LucideIcons.moreVertical),
          onSelected: (value) => _handlePreviewAction(context, value),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'refresh',
              child: Row(
                children: [
                  Icon(LucideIcons.refreshCw, size: 16),
                  SizedBox(width: 8),
                  Text('更新'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'fullscreen',
              child: Row(
                children: [
                  Icon(LucideIcons.maximize, size: 16),
                  SizedBox(width: 8),
                  Text('全画面'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'export',
              child: Row(
                children: [
                  Icon(LucideIcons.download, size: 16),
                  SizedBox(width: 8),
                  Text('エクスポート'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPreviewArea(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.white,
          child: Transform.scale(
            scale: _scale,
            child: _isWebView ? _buildWebPreview() : _buildPDFPreview(),
          ),
        ),
      ),
    );
  }

  Widget _buildWebPreview() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ヘッダー部分
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: AppTheme.springColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      '🌸',
                      style: TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '○○小学校 △年△組',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '学級通信「○○○」',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '2024年6月6日（木）第○号',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // メインコンテンツ
          _buildSampleContent(),
          
          const SizedBox(height: 24),
          
          // フッター
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  '担任: ○○先生',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '何かご質問等ございましたら、お気軽にお声かけください。',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPDFPreview() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // PDF用のヘッダー（よりシンプル）
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '○○小学校 △年△組 学級通信「○○○」',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '2024年6月6日（木）第○号',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const Text(
                '🌸',
                style: TextStyle(fontSize: 32),
              ),
            ],
          ),
          
          const Divider(height: 24),
          
          // PDFコンテンツ
          Expanded(
            child: SingleChildScrollView(
              child: _buildSampleContent(),
            ),
          ),
          
          const Divider(height: 24),
          
          // PDF用フッター
          Text(
            '担任: ○○先生　　○○小学校　TEL: 000-000-0000',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSampleContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 見出し1
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            '🏃‍♂️ 今日の運動会練習',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // 本文
        Text(
          'みなさん、こんにちは！今日は運動会の練習日でした。\n'
          '子どもたちはとても元気いっぱいで、特にリレーの練習では白熱した競争が繰り広げられました。',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        
        const SizedBox(height: 16),
        
        // 吹き出し
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.accentColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.accentColor.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              const Text(
                '💪',
                style: TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'みんなで力を合わせて、素晴らしい運動会にしましょう！',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // 見出し2
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.secondaryColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            '📚 来週の予定',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // リスト
        Column(
          children: [
            _buildListItem('月曜日', '算数テスト'),
            _buildListItem('火曜日', '図書館見学'),
            _buildListItem('水曜日', '運動会リハーサル'),
            _buildListItem('木曜日', '運動会準備'),
            _buildListItem('金曜日', '運動会本番'),
          ],
        ),
        
        const SizedBox(height: 20),
        
        // 画像プレースホルダー
        Container(
          width: double.infinity,
          height: 150,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.image,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 8),
              Text(
                '運動会練習の様子',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildListItem(String day, String event) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$day: ',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            event,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  void _updateScale(double newScale) {
    setState(() {
      _scale = newScale.clamp(0.5, 2.0);
    });
  }

  void _handlePreviewAction(BuildContext context, String action) {
    switch (action) {
      case 'refresh':
        setState(() {
          // プレビューを更新
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('プレビューを更新しました'),
            duration: Duration(seconds: 1),
          ),
        );
        break;
      case 'fullscreen':
        _showFullscreenPreview(context);
        break;
      case 'export':
        _showExportDialog(context);
        break;
    }
  }

  void _showFullscreenPreview(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('フルスクリーンプレビュー'),
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(LucideIcons.download),
                onPressed: () => _showExportDialog(context),
              ),
            ],
          ),
          backgroundColor: Colors.black,
          body: Center(
            child: InteractiveViewer(
              child: Container(
                color: Colors.white,
                child: _isWebView ? _buildWebPreview() : _buildPDFPreview(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('エクスポート'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.fileText),
              title: const Text('PDF形式'),
              subtitle: const Text('印刷・配布用'),
              onTap: () {
                Navigator.of(context).pop();
                _exportToPDF();
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.globe),
              title: const Text('HTML形式'),
              subtitle: const Text('Web表示用'),
              onTap: () {
                Navigator.of(context).pop();
                _exportToHTML();
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.image),
              title: const Text('画像形式'),
              subtitle: const Text('SNS投稿用'),
              onTap: () {
                Navigator.of(context).pop();
                _exportToImage();
              },
            ),
          ],
        ),
      ),
    );
  }

void _exportToPDF() {
   // TODO: Implement actual PDF generation using WeasyPrint or similar
   // For now, simulate PDF export process
   showDialog(
     context: context,
     barrierDismissible: false,
     builder: (context) => const AlertDialog(
       content: Column(
         mainAxisSize: MainAxisSize.min,
         children: [
           CircularProgressIndicator(),
           SizedBox(height: 16),
           Text('PDFを生成中...'),
         ],
       ),
     ),
   );
   
   // Simulate PDF generation delay
   Future.delayed(const Duration(seconds: 2), () {
     Navigator.of(context).pop();
     ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(
         content: const Text('PDFエクスポートが完了しました'),
         backgroundColor: AppTheme.successColor,
         action: SnackBarAction(
           label: 'ダウンロード',
           textColor: Colors.white,
           onPressed: () {
             // TODO: Trigger actual download
           },
         ),
       ),
     );
   });
 }

  void _exportToHTML() {
    // TODO: Implement actual HTML generation with proper styling
    // For now, simulate HTML export process
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppTheme.accentColor),
            SizedBox(height: 16),
            Text('HTMLファイルを生成中...'),
          ],
        ),
      ),
    );
    
    // Simulate HTML generation delay
    Future.delayed(const Duration(seconds: 1), () {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('HTMLエクスポートが完了しました'),
          backgroundColor: AppTheme.accentColor,
          action: SnackBarAction(
            label: 'プレビュー',
            textColor: Colors.white,
            onPressed: () {
              // TODO: Open HTML preview in browser or WebView
            },
          ),
        ),
      );
    });
  }

  void _exportToImage() {
    // TODO: Implement actual image generation using RepaintBoundary or similar
    // For now, simulate image export process
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppTheme.secondaryColor),
            SizedBox(height: 16),
            Text('画像を生成中...'),
          ],
        ),
      ),
    );
    
    // Simulate image generation delay
    Future.delayed(const Duration(milliseconds: 1500), () {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('PNG画像のエクスポートが完了しました'),
          backgroundColor: AppTheme.secondaryColor,
          action: SnackBarAction(
            label: 'ギャラリーで表示',
            textColor: Colors.white,
            onPressed: () {
              // TODO: Open image in gallery or file viewer
            },
          ),
        ),
      );
    });
  }
}