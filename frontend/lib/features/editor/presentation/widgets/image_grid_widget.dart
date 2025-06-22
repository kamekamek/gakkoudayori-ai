import 'package:flutter/material.dart';
import '../../../../core/models/image_file.dart';
import 'image_tile_widget.dart';

/// 画像一覧グリッド表示ウィジェット
class ImageGridWidget extends StatelessWidget {
  final List<ImageFile> images;
  final Function(String imageId) onImageRemoved;
  final Function(String imageId, int degrees) onImageRotated;
  final Function(int oldIndex, int newIndex) onImagesReordered;
  final int crossAxisCount;
  final double childAspectRatio;

  const ImageGridWidget({
    super.key,
    required this.images,
    required this.onImageRemoved,
    required this.onImageRotated,
    required this.onImagesReordered,
    this.crossAxisCount = 2,
    this.childAspectRatio = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return _buildEmptyState(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 統計情報
        _buildStatsHeader(context),
        
        const SizedBox(height: 12),
        
        // 画像グリッド
        Expanded(
          child: ReorderableGridView.count(
            crossAxisCount: _calculateCrossAxisCount(context),
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: images.asMap().entries.map((entry) {
              final index = entry.key;
              final image = entry.value;
              
              return ReorderableDragStartListener(
                key: ValueKey(image.id),
                index: index,
                child: ImageTileWidget(
                  image: image,
                  onRemove: () => onImageRemoved(image.id),
                  onRotate: (degrees) => onImageRotated(image.id, degrees),
                  showIndex: true,
                  index: index + 1,
                ),
              );
            }).toList(),
            onReorder: onImagesReordered,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsHeader(BuildContext context) {
    final totalSize = images.fold(0, (sum, img) => sum + img.size);
    final compressedCount = images.where((img) => img.isCompressed).length;
    
    String totalSizeDisplay;
    if (totalSize < 1024) {
      totalSizeDisplay = '${totalSize}B';
    } else if (totalSize < 1024 * 1024) {
      totalSizeDisplay = '${(totalSize / 1024).toStringAsFixed(1)}KB';
    } else {
      totalSizeDisplay = '${(totalSize / (1024 * 1024)).toStringAsFixed(1)}MB';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${images.length}枚の画像 • $totalSizeDisplay',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (compressedCount > 0)
                  Text(
                    '$compressedCount枚が圧縮済み',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          // ドラッグ&ドロップヒント
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.drag_indicator,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  '順序変更可能',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              '画像がありません',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '画像を追加して学級通信を華やかにしましょう',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  int _calculateCrossAxisCount(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // レスポンシブ対応
    if (screenWidth < 600) {
      return 1; // モバイル：1列
    } else if (screenWidth < 900) {
      return 2; // タブレット：2列
    } else {
      return crossAxisCount; // デスクトップ：指定値（デフォルト2列）
    }
  }
}

/// ReorderableGridViewの簡易実装
/// 実際のプロジェクトでは flutter_reorderable_grid_view パッケージを使用することを推奨
class ReorderableGridView extends StatefulWidget {
  final List<Widget> children;
  final Function(int oldIndex, int newIndex) onReorder;
  final int crossAxisCount;
  final double childAspectRatio;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final EdgeInsets padding;

  const ReorderableGridView.count({
    super.key,
    required this.children,
    required this.onReorder,
    required this.crossAxisCount,
    this.childAspectRatio = 1.0,
    this.crossAxisSpacing = 0.0,
    this.mainAxisSpacing = 0.0,
    this.padding = EdgeInsets.zero,
  });

  @override
  State<ReorderableGridView> createState() => _ReorderableGridViewState();
}

class _ReorderableGridViewState extends State<ReorderableGridView> {
  @override
  Widget build(BuildContext context) {
    // 簡単な実装：ReorderableListViewを使用
    // より高度な並び替えが必要な場合は専用パッケージを使用
    return ReorderableListView(
      padding: widget.padding,
      onReorder: widget.onReorder,
      children: widget.children,
    );
  }
}

class ReorderableDragStartListener extends StatelessWidget {
  final int index;
  final Widget child;

  const ReorderableDragStartListener({
    super.key,
    required this.index,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return child;
  }
}