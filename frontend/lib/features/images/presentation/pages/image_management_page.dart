import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/image_provider.dart';
import '../widgets/image_upload_button_grid.dart';
import '../widgets/image_grid_view.dart';
import '../../../../core/models/models.dart';

/// 画像管理メイン画面
class ImageManagementPage extends StatefulWidget {
  final bool isSelectionMode;
  final Function(List<ImageFile>)? onImagesSelected;

  const ImageManagementPage({
    super.key,
    this.isSelectionMode = false,
    this.onImagesSelected,
  });

  @override
  State<ImageManagementPage> createState() => _ImageManagementPageState();
}

class _ImageManagementPageState extends State<ImageManagementPage> {
  @override
  void initState() {
    super.initState();
    // 初期化時に画像データをリセット（必要に応じて）
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isSelectionMode ? '画像を選択' : '画像管理'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        actions: widget.isSelectionMode ? _buildSelectionActions() : null,
      ),
      body: Consumer<ImageUploadProvider>(
        builder: (context, imageProvider, child) {
          return Column(
            children: [
              // 画像アップロード
              Container(
                padding: const EdgeInsets.all(16),
                child: ImageUploadButtonGrid(
                  onUploadComplete: () {
                    // アップロード完了時の処理
                    setState(() {});
                  },
                  showAiGeneration: !widget.isSelectionMode,
                  isCompact: widget.isSelectionMode,
                ),
              ),

              // 区切り線
              if (imageProvider.hasImages)
                const Divider(height: 1),

              // 画像一覧
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: ImageGridView(
                    selectionMode: widget.isSelectionMode,
                    showActions: !widget.isSelectionMode,
                    onImageTap: widget.isSelectionMode 
                        ? (image) => _handleImageSelection(imageProvider, image)
                        : null,
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: widget.isSelectionMode 
          ? _buildSelectionFab()
          : null,
    );
  }

  List<Widget> _buildSelectionActions() {
    return [
      Consumer<ImageUploadProvider>(
        builder: (context, imageProvider, child) {
          return TextButton(
            onPressed: imageProvider.hasSelectedImages 
                ? () => _confirmSelection(imageProvider) 
                : null,
            child: Text(
              '選択完了 (${imageProvider.selectedCount})',
              style: TextStyle(
                color: imageProvider.hasSelectedImages 
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).disabledColor,
              ),
            ),
          );
        },
      ),
    ];
  }

  Widget? _buildSelectionFab() {
    return Consumer<ImageUploadProvider>(
      builder: (context, imageProvider, child) {
        if (!imageProvider.hasSelectedImages) return const SizedBox.shrink();

        return FloatingActionButton.extended(
          onPressed: () => _confirmSelection(imageProvider),
          icon: const Icon(Icons.check),
          label: Text('${imageProvider.selectedCount}枚選択'),
        );
      },
    );
  }

  void _handleImageSelection(ImageUploadProvider imageProvider, ImageFile image) {
    imageProvider.toggleImageSelection(image.id);
  }

  void _confirmSelection(ImageUploadProvider imageProvider) {
    final selectedImages = imageProvider.getSelectedImages();
    widget.onImagesSelected?.call(selectedImages);
    Navigator.of(context).pop(selectedImages);
  }
}