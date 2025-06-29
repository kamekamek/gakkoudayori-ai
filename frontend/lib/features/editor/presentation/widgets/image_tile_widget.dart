import 'package:flutter/material.dart';
import '../../../../core/models/image_file.dart';

/// 画像タイル（個別画像表示・操作）ウィジェット
class ImageTileWidget extends StatefulWidget {
  final ImageFile image;
  final VoidCallback onRemove;
  final Function(int degrees) onRotate;
  final bool showIndex;
  final int? index;
  final bool showDetails;

  const ImageTileWidget({
    super.key,
    required this.image,
    required this.onRemove,
    required this.onRotate,
    this.showIndex = false,
    this.index,
    this.showDetails = true,
  });

  @override
  State<ImageTileWidget> createState() => _ImageTileWidgetState();
}

class _ImageTileWidgetState extends State<ImageTileWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Card(
          elevation: _isHovered ? 8 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 画像表示エリア
              SizedBox(
                height: 120, // 固定高さを設定
                child: _buildImageDisplay(),
              ),

              // 情報・操作エリア
              if (widget.showDetails) _buildInfoArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageDisplay() {
    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Stack(
        children: [
          // 画像本体
          Positioned.fill(
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.memory(
                widget.image.bytes,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildErrorDisplay();
                },
              ),
            ),
          ),

          // インデックス表示（左上）
          if (widget.showIndex && widget.index != null)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${widget.index}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ),

          // 圧縮済みマーク（右上）
          if (widget.image.isCompressed)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.compress,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSecondary,
                ),
              ),
            ),

          // ホバー時の操作ボタン
          if (_isHovered)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: _buildActionButtons(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorDisplay() {
    return Container(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.broken_image,
              size: 32,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 8),
            Text(
              '画像の表示に\n失敗しました',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Center(
      child: Wrap(
        spacing: 8,
        children: [
          // プレビューボタン
          _buildActionButton(
            icon: Icons.fullscreen,
            tooltip: 'プレビュー',
            onPressed: () => _showImagePreview(),
          ),

          // 左回転ボタン
          _buildActionButton(
            icon: Icons.rotate_left,
            tooltip: '左に90度回転',
            onPressed: () => widget.onRotate(-90),
          ),

          // 右回転ボタン
          _buildActionButton(
            icon: Icons.rotate_right,
            tooltip: '右に90度回転',
            onPressed: () => widget.onRotate(90),
          ),

          // 削除ボタン
          _buildActionButton(
            icon: Icons.delete,
            tooltip: '削除',
            onPressed: () => _showDeleteConfirmation(),
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    bool isDestructive = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: isDestructive
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              size: 20,
              color: isDestructive
                  ? Theme.of(context).colorScheme.onError
                  : Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ファイル名
          Text(
            widget.image.name,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 4),

          // ファイルサイズ・形式
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.image.sizeDisplay,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
              Text(
                widget.image.extension.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),

          // 圧縮情報
          if (widget.image.isCompressed &&
              widget.image.compressionRatio != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.compress,
                    size: 12,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    widget.image.compressionDisplay,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showImagePreview() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.memory(widget.image.bytes),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.image.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${widget.image.sizeDisplay} • ${widget.image.extension.toUpperCase()}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
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

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('画像削除'),
        content: Text('「${widget.image.name}」を削除しますか？\nこの操作は元に戻せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onRemove();
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
