import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/image_provider.dart';
import 'image_grid_widget.dart';
import 'url_input_dialog.dart';

/// 画像アップロードメインウィジェット
class ImageUploadWidget extends StatelessWidget {
  final VoidCallback? onImagesChanged;
  final bool showHeader;
  final int maxImages;

  const ImageUploadWidget({
    super.key,
    this.onImagesChanged,
    this.showHeader = true,
    this.maxImages = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ImageManagementProvider>(
      builder: (context, imageProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ヘッダー（任意）
            if (showHeader) _buildHeader(context, imageProvider),
            
            // アップロードボタン群
            _buildUploadButtons(context, imageProvider),
            
            // ステータス表示
            if (imageProvider.isUploading || imageProvider.isProcessing)
              _buildStatusIndicator(context, imageProvider),
            
            // エラー表示
            if (imageProvider.lastError != null)
              _buildErrorCard(context, imageProvider),
            
            const SizedBox(height: 16),
            
            // 画像グリッド
            if (imageProvider.hasImages)
              SizedBox(
                height: 300, // 固定高さを設定
                child: ImageGridWidget(
                  images: imageProvider.uploadedImages,
                  onImageRemoved: (imageId) {
                    imageProvider.removeImage(imageId);
                    onImagesChanged?.call();
                  },
                  onImageRotated: (imageId, degrees) {
                    imageProvider.rotateImage(imageId, degrees);
                    onImagesChanged?.call();
                  },
                  onImagesReordered: (oldIndex, newIndex) {
                    imageProvider.reorderImages(oldIndex, newIndex);
                    onImagesChanged?.call();
                  },
                ),
              )
            else
              _buildEmptyState(context),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, ImageManagementProvider imageProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.photo_library,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '画像アップロード',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (imageProvider.hasImages)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${imageProvider.imageCount}/$maxImages',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUploadButtons(BuildContext context, ImageManagementProvider imageProvider) {
    final canAdd = imageProvider.canAddMore;
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          // ファイル選択ボタン
          _buildUploadButton(
            context: context,
            icon: Icons.folder_open,
            label: 'ファイル選択',
            tooltip: 'デバイスから画像ファイルを選択',
            enabled: canAdd && !imageProvider.isUploading && !imageProvider.isProcessing,
            onPressed: () => imageProvider.addImagesFromDevice(),
          ),
          
          // カメラ撮影ボタン
          _buildUploadButton(
            context: context,
            icon: Icons.camera_alt,
            label: 'カメラ撮影',
            tooltip: 'カメラで写真を撮影',
            enabled: canAdd && !imageProvider.isUploading && !imageProvider.isProcessing,
            onPressed: () => imageProvider.addImageFromCamera(),
          ),
          
          // URL指定ボタン
          _buildUploadButton(
            context: context,
            icon: Icons.link,
            label: 'URL指定',
            tooltip: 'URLから画像を取得',
            enabled: canAdd && !imageProvider.isUploading && !imageProvider.isProcessing,
            onPressed: () => _showUrlInputDialog(context, imageProvider),
          ),
          
          // 全削除ボタン（画像がある場合のみ）
          if (imageProvider.hasImages)
            _buildUploadButton(
              context: context,
              icon: Icons.clear_all,
              label: '全削除',
              tooltip: '全ての画像を削除',
              enabled: !imageProvider.isUploading && !imageProvider.isProcessing,
              onPressed: () => _showClearConfirmDialog(context, imageProvider),
              isDestructive: true,
            ),
        ],
      ),
    );
  }

  Widget _buildUploadButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String tooltip,
    required bool enabled,
    required VoidCallback onPressed,
    bool isDestructive = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: ElevatedButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: isDestructive 
              ? Theme.of(context).colorScheme.error
              : Theme.of(context).colorScheme.primary,
          foregroundColor: isDestructive
              ? Theme.of(context).colorScheme.onError
              : Theme.of(context).colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(BuildContext context, ImageManagementProvider imageProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              imageProvider.statusMessage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, ImageManagementProvider imageProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.error,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              imageProvider.lastError!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
          IconButton(
            onPressed: () => imageProvider.clearError(),
            icon: Icon(
              Icons.close,
              color: Theme.of(context).colorScheme.error,
              size: 18,
            ),
            tooltip: 'エラーを閉じる',
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              '画像が追加されていません',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '上のボタンから画像を追加してください',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUrlInputDialog(BuildContext context, ImageManagementProvider imageProvider) {
    showDialog(
      context: context,
      builder: (context) => UrlInputDialog(
        onUrlSubmitted: (url) {
          imageProvider.addImageFromUrl(url);
          onImagesChanged?.call();
        },
      ),
    );
  }

  void _showClearConfirmDialog(BuildContext context, ImageManagementProvider imageProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('全画像削除'),
        content: Text(
          '${imageProvider.imageCount}枚の画像を全て削除しますか？\nこの操作は元に戻せません。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              imageProvider.clearAllImages();
              onImagesChanged?.call();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }
}