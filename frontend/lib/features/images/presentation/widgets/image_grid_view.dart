import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/image_provider.dart';
import '../../../../core/models/models.dart';
import '../../../../core/utils/utils.dart';
import 'image_preview_card.dart';

/// アップロード済み画像の一覧表示グリッド
class ImageGridView extends StatelessWidget {
  final bool selectionMode;
  final Function(ImageFile)? onImageTap;
  final Function(ImageFile)? onImageLongPress;
  final bool showActions;
  final int crossAxisCount;

  const ImageGridView({
    super.key,
    this.selectionMode = false,
    this.onImageTap,
    this.onImageLongPress,
    this.showActions = true,
    this.crossAxisCount = 0, // 0 = auto
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ImageUploadProvider>(
      builder: (context, imageProvider, child) {
        if (imageProvider.images.isEmpty) {
          return _buildEmptyState(context);
        }

        final images = imageProvider.filteredImages;
        final crossAxisCountActual = _calculateCrossAxisCount(context);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showActions) ...[
              _buildActionBar(context, imageProvider),
              const SizedBox(height: 16),
            ],
            
            if (imageProvider.searchQuery.isNotEmpty) ...[
              _buildSearchInfo(context, images.length, imageProvider.images.length),
              const SizedBox(height: 8),
            ],
            
            Flexible(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCountActual,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1,
                ),
                itemCount: images.length,
                itemBuilder: (context, index) {
                  final image = images[index];
                  final isSelected = imageProvider.selectedImageIds.contains(image.id);
                  final isPrimary = imageProvider.primaryImage?.id == image.id;

                  return ImagePreviewCard(
                    image: image,
                    isSelected: isSelected,
                    isPrimary: isPrimary,
                    selectionMode: selectionMode,
                    onTap: () => _handleImageTap(context, image, imageProvider),
                    onLongPress: () => _handleImageLongPress(context, image, imageProvider),
                    onDelete: showActions ? () => _handleImageDelete(context, image, imageProvider) : null,
                    onSetPrimary: showActions ? () => imageProvider.setPrimaryImage(image.id) : null,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'まだ画像がありません',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '上のボタンから画像を追加してください',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar(BuildContext context, ImageUploadProvider imageProvider) {
    final hasSelectedImages = imageProvider.hasSelectedImages;
    final selectedCount = imageProvider.selectedCount;

    return Row(
      children: [
        // 検索バー
        Expanded(
          child: SizedBox(
            height: 48,
            child: TextField(
              decoration: InputDecoration(
                hintText: '画像を検索...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: imageProvider.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => imageProvider.setSearchQuery(''),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: imageProvider.setSearchQuery,
            ),
          ),
        ),
        
        const SizedBox(width: 12),
        
        // ソートボタン
        PopupMenuButton<ImageSortType>(
          icon: const Icon(Icons.sort),
          tooltip: 'ソート',
          onSelected: imageProvider.setSortType,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: ImageSortType.dateDesc,
              child: Row(
                children: [
                  Icon(Icons.date_range),
                  SizedBox(width: 8),
                  Text('新しい順'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: ImageSortType.dateAsc,
              child: Row(
                children: [
                  Icon(Icons.date_range),
                  SizedBox(width: 8),
                  Text('古い順'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: ImageSortType.nameAsc,
              child: Row(
                children: [
                  Icon(Icons.sort_by_alpha),
                  SizedBox(width: 8),
                  Text('名前順'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: ImageSortType.sizeDesc,
              child: Row(
                children: [
                  Icon(Icons.data_usage),
                  SizedBox(width: 8),
                  Text('サイズ順'),
                ],
              ),
            ),
          ],
        ),
        
        // 選択関連ボタン
        if (hasSelectedImages) ...[
          IconButton(
            icon: Icon(
              Icons.delete,
              color: Theme.of(context).colorScheme.error,
            ),
            tooltip: '選択した画像を削除 ($selectedCount)',
            onPressed: () => _handleBatchDelete(context, imageProvider),
          ),
          IconButton(
            icon: const Icon(Icons.deselect),
            tooltip: '選択解除',
            onPressed: imageProvider.deselectAllImages,
          ),
        ] else ...[
          IconButton(
            icon: const Icon(Icons.select_all),
            tooltip: '全選択',
            onPressed: imageProvider.images.isNotEmpty ? imageProvider.selectAllImages : null,
          ),
        ],
      ],
    );
  }

  Widget _buildSearchInfo(BuildContext context, int filteredCount, int totalCount) {
    return Text(
      '$filteredCount件 / $totalCount件',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  int _calculateCrossAxisCount(BuildContext context) {
    if (crossAxisCount > 0) return crossAxisCount;
    
    final width = context.screenWidth;
    if (width >= 1200) return 6;
    if (width >= 800) return 4;
    if (width >= 600) return 3;
    return 2;
  }

  void _handleImageTap(BuildContext context, ImageFile image, ImageUploadProvider imageProvider) {
    if (selectionMode) {
      imageProvider.toggleImageSelection(image.id);
    } else if (onImageTap != null) {
      onImageTap!(image);
    } else {
      // デフォルト: 画像詳細を表示
      _showImageDetail(context, image);
    }
  }

  void _handleImageLongPress(BuildContext context, ImageFile image, ImageUploadProvider imageProvider) {
    if (onImageLongPress != null) {
      onImageLongPress!(image);
    } else {
      // デフォルト: 選択モード開始
      imageProvider.toggleImageSelection(image.id);
    }
  }

  Future<void> _handleImageDelete(BuildContext context, ImageFile image, ImageUploadProvider imageProvider) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('画像を削除'),
        content: Text('「${image.name}」を削除しますか？\nこの操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (result == true) {
      await imageProvider.deleteImage(image.id);
    }
  }

  Future<void> _handleBatchDelete(BuildContext context, ImageUploadProvider imageProvider) async {
    final selectedCount = imageProvider.selectedCount;
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('選択した画像を削除'),
        content: Text('$selectedCount枚の画像を削除しますか？\nこの操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (result == true) {
      await imageProvider.deleteSelectedImages();
    }
  }

  void _showImageDetail(BuildContext context, ImageFile image) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 600,
            maxHeight: 600,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: Text(image.name),
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                backgroundColor: Theme.of(context).colorScheme.surface,
                foregroundColor: Theme.of(context).colorScheme.onSurface,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 画像表示
                      Center(
                        child: Container(
                          constraints: const BoxConstraints(
                            maxHeight: 300,
                          ),
                          child: Image.memory(
                            image.bytes,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // 画像情報
                      _buildImageInfoTile('ファイル名', image.name),
                      _buildImageInfoTile('サイズ', AppHelpers.formatFileSize(image.size)),
                      _buildImageInfoTile('アップロード日時', image.uploadedAt.toJapaneseDateTime()),
                      if (image.metadata != null) ...[
                        _buildImageInfoTile('画像サイズ', '${image.metadata!.width} × ${image.metadata!.height}'),
                        if (image.metadata!.isCompressed) ...[
                          _buildImageInfoTile('圧縮率', '${((image.metadata!.compressionRatio ?? 1.0) * 100).toStringAsFixed(1)}%'),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageInfoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}