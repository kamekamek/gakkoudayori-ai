import 'package:flutter/material.dart';
import '../../../../core/models/models.dart';
import '../../../../core/utils/utils.dart';

/// 個別画像のプレビューカード
class ImagePreviewCard extends StatelessWidget {
  final ImageFile image;
  final bool isSelected;
  final bool isPrimary;
  final bool selectionMode;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onDelete;
  final VoidCallback? onSetPrimary;

  const ImagePreviewCard({
    super.key,
    required this.image,
    this.isSelected = false,
    this.isPrimary = false,
    this.selectionMode = false,
    this.onTap,
    this.onLongPress,
    this.onDelete,
    this.onSetPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isSelected ? 8 : 2,
      shadowColor: isSelected 
          ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected 
              ? Theme.of(context).colorScheme.primary
              : isPrimary
                  ? Theme.of(context).colorScheme.secondary
                  : Colors.transparent,
          width: isSelected ? 2 : isPrimary ? 1.5 : 0,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            // 画像表示
            Positioned.fill(
              child: GestureDetector(
                onTap: onTap,
                onLongPress: onLongPress,
                child: Image.memory(
                  image.bytes,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Theme.of(context).colorScheme.errorContainer,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image,
                            color: Theme.of(context).colorScheme.onErrorContainer,
                            size: 32,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'エラー',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onErrorContainer,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

            // 選択状態オーバーレイ
            if (isSelected)
              Positioned.fill(
                child: Container(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  child: const Center(
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 32,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // プライマリ画像バッジ
            if (isPrimary && !isSelected)
              Positioned(
                top: 4,
                left: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'メイン',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

            // アクションボタン
            if (!selectionMode)
              Positioned(
                top: 4,
                right: 4,
                child: _buildActionMenu(context),
              ),

            // 画像情報オーバーレイ
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black54,
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      image.name,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          AppHelpers.formatFileSize(image.size),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                        if (image.metadata != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '${image.metadata!.width}×${image.metadata!.height}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionMenu(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(20),
      ),
      child: PopupMenuButton<String>(
        icon: const Icon(
          Icons.more_vert,
          color: Colors.white,
          size: 18,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        onSelected: (value) {
          switch (value) {
            case 'primary':
              onSetPrimary?.call();
              break;
            case 'delete':
              onDelete?.call();
              break;
          }
        },
        itemBuilder: (context) => [
          if (!isPrimary && onSetPrimary != null)
            const PopupMenuItem(
              value: 'primary',
              child: Row(
                children: [
                  Icon(Icons.star_border),
                  SizedBox(width: 8),
                  Text('メイン画像に設定'),
                ],
              ),
            ),
          if (onDelete != null)
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(
                    Icons.delete,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '削除',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}