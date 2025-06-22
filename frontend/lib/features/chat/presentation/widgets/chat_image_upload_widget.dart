import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../images/providers/image_provider.dart';
import '../../../images/presentation/widgets/image_upload_button_grid.dart';
import '../../../images/presentation/widgets/image_grid_view.dart';
import '../../../images/presentation/pages/image_management_page.dart';
import '../../../../core/models/models.dart';

/// チャット内での画像アップロード機能
class ChatImageUploadWidget extends StatelessWidget {
  final Function(List<ImageFile>)? onImagesSelected;
  final bool isCompact;

  const ChatImageUploadWidget({
    super.key,
    this.onImagesSelected,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ImageUploadProvider>(
      builder: (context, imageProvider, child) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).dividerColor,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ヘッダー
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      Icons.photo_library,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '画像を追加',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (imageProvider.hasImages)
                      TextButton(
                        onPressed: () => _showImageManager(context),
                        child: const Text('管理'),
                      ),
                  ],
                ),
              ),

              // アップロードボタン（コンパクト版）
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: ImageUploadButtonGrid(
                  isCompact: true,
                  onUploadComplete: () {
                    if (onImagesSelected != null) {
                      final images = imageProvider.getSelectedImages();
                      if (images.isNotEmpty) {
                        onImagesSelected!(images);
                      }
                    }
                  },
                ),
              ),

              // 選択された画像のプレビュー
              if (imageProvider.hasSelectedImages) ...[
                const SizedBox(height: 12),
                _buildSelectedImagesPreview(context, imageProvider),
              ],

              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSelectedImagesPreview(BuildContext context, ImageUploadProvider imageProvider) {
    final selectedImages = imageProvider.getSelectedImages();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '選択された画像 (${selectedImages.length}枚)',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (selectedImages.isNotEmpty)
                TextButton(
                  onPressed: () => imageProvider.deselectAllImages(),
                  child: const Text('選択解除'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: selectedImages.length,
              itemBuilder: (context, index) {
                final image = selectedImages[index];
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: _buildSelectedImageThumbnail(context, image, imageProvider),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: selectedImages.isNotEmpty 
                    ? () => onImagesSelected?.call(selectedImages)
                    : null,
                icon: const Icon(Icons.check, size: 18),
                label: const Text('選択確定'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _showImageManager(context),
                icon: const Icon(Icons.photo_library, size: 18),
                label: const Text('画像管理'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedImageThumbnail(BuildContext context, ImageFile image, ImageUploadProvider imageProvider) {
    return Stack(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary,
              width: 2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.memory(
              image.bytes,
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: -4,
          right: -4,
          child: GestureDetector(
            onTap: () => imageProvider.deselectImage(image.id),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.close,
                size: 12,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showImageManager(BuildContext context) async {
    final result = await Navigator.of(context).push<List<ImageFile>>(
      MaterialPageRoute(
        builder: (context) => const ImageManagementPage(
          isSelectionMode: true,
        ),
      ),
    );

    if (result != null && result.isNotEmpty && onImagesSelected != null) {
      onImagesSelected!(result);
    }
  }
}