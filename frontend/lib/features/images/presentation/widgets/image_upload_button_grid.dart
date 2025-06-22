import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/image_provider.dart';
import '../../../../core/utils/utils.dart';

/// 4つの画像入力方法を提供するボタングリッド
class ImageUploadButtonGrid extends StatelessWidget {
  final VoidCallback? onUploadComplete;
  final bool showAiGeneration;
  final bool isCompact;

  const ImageUploadButtonGrid({
    super.key,
    this.onUploadComplete,
    this.showAiGeneration = false,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ImageUploadProvider>(
      builder: (context, imageProvider, child) {
        return Container(
          padding: EdgeInsets.all(isCompact ? 12 : 16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).dividerColor,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '📷 画像を追加',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              if (context.isDesktop)
                _buildDesktopLayout(context, imageProvider)
              else
                _buildMobileLayout(context, imageProvider),
              
              if (imageProvider.isUploading) ...[
                const SizedBox(height: 16),
                _buildUploadProgress(context, imageProvider),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildDesktopLayout(BuildContext context, ImageUploadProvider imageProvider) {
    return Row(
      children: [
        Expanded(
          child: _buildUploadButton(
            context: context,
            icon: Icons.folder_open,
            label: 'ファイル選択',
            description: 'デバイスから画像を選択',
            onPressed: imageProvider.isUploading ? null : () => _handleFileUpload(context, imageProvider),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildUploadButton(
            context: context,
            icon: Icons.camera_alt,
            label: 'カメラ撮影',
            description: 'カメラで写真を撮影',
            onPressed: imageProvider.isUploading ? null : () => _handleCameraUpload(context, imageProvider),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildUploadButton(
            context: context,
            icon: Icons.link,
            label: 'URL取得',
            description: 'インターネットから取得',
            onPressed: imageProvider.isUploading ? null : () => _handleUrlUpload(context, imageProvider),
          ),
        ),
        if (showAiGeneration) ...[
          const SizedBox(width: 12),
          Expanded(
            child: _buildUploadButton(
              context: context,
              icon: Icons.auto_awesome,
              label: 'AI生成',
              description: '将来対応予定',
              onPressed: null, // 将来実装
              isDisabled: true,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context, ImageUploadProvider imageProvider) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildUploadButton(
                context: context,
                icon: Icons.folder_open,
                label: 'ファイル',
                description: null,
                onPressed: imageProvider.isUploading ? null : () => _handleFileUpload(context, imageProvider),
                isCompact: true,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildUploadButton(
                context: context,
                icon: Icons.camera_alt,
                label: 'カメラ',
                description: null,
                onPressed: imageProvider.isUploading ? null : () => _handleCameraUpload(context, imageProvider),
                isCompact: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildUploadButton(
                context: context,
                icon: Icons.link,
                label: 'URL',
                description: null,
                onPressed: imageProvider.isUploading ? null : () => _handleUrlUpload(context, imageProvider),
                isCompact: true,
              ),
            ),
            if (showAiGeneration) ...[
              const SizedBox(width: 8),
              Expanded(
                child: _buildUploadButton(
                  context: context,
                  icon: Icons.auto_awesome,
                  label: 'AI生成',
                  description: null,
                  onPressed: null,
                  isCompact: true,
                  isDisabled: true,
                ),
              ),
            ] else
              const Expanded(child: SizedBox()),
          ],
        ),
      ],
    );
  }

  Widget _buildUploadButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    String? description,
    VoidCallback? onPressed,
    bool isCompact = false,
    bool isDisabled = false,
  }) {
    final theme = Theme.of(context);
    final isEnabled = onPressed != null && !isDisabled;
    
    return SizedBox(
      height: isCompact ? 80 : 100,
      child: Material(
        color: isEnabled 
            ? theme.colorScheme.surfaceVariant.withOpacity(0.5)
            : theme.disabledColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,
          child: Padding(
            padding: EdgeInsets.all(isCompact ? 8 : 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: isCompact ? 24 : 32,
                  color: isEnabled 
                      ? theme.colorScheme.primary
                      : theme.disabledColor,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: isEnabled 
                        ? theme.colorScheme.onSurface
                        : theme.disabledColor,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (description != null && !isCompact) ...[
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isEnabled 
                          ? theme.colorScheme.onSurfaceVariant
                          : theme.disabledColor,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadProgress(BuildContext context, ImageUploadProvider imageProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: imageProvider.uploadProgress,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'アップロード中... ${imageProvider.uploadedCount}/${imageProvider.totalUploadCount}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: imageProvider.uploadProgress,
          backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
        ),
      ],
    );
  }

  Future<void> _handleFileUpload(BuildContext context, ImageUploadProvider imageProvider) async {
    try {
      await imageProvider.uploadFromDevice();
      onUploadComplete?.call();
      _showSuccessMessage(context, '画像のアップロードが完了しました');
    } catch (e) {
      _showErrorMessage(context, '画像のアップロードに失敗しました: $e');
    }
  }

  Future<void> _handleCameraUpload(BuildContext context, ImageUploadProvider imageProvider) async {
    try {
      await imageProvider.uploadFromCamera();
      onUploadComplete?.call();
      _showSuccessMessage(context, '写真の撮影とアップロードが完了しました');
    } catch (e) {
      _showErrorMessage(context, '写真の撮影に失敗しました: $e');
    }
  }

  Future<void> _handleUrlUpload(BuildContext context, ImageUploadProvider imageProvider) async {
    final urlController = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🌐 URLから画像を取得'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('画像のURLを入力してください'),
            const SizedBox(height: 16),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                hintText: 'https://example.com/image.jpg',
                prefixIcon: Icon(Icons.link),
              ),
              keyboardType: TextInputType.url,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(urlController.text),
            child: const Text('取得'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        await imageProvider.uploadFromUrl(result);
        onUploadComplete?.call();
        _showSuccessMessage(context, 'URLから画像を取得しました');
      } catch (e) {
        _showErrorMessage(context, 'URL画像の取得に失敗しました: $e');
      }
    }
  }

  void _showSuccessMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: '閉じる',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}