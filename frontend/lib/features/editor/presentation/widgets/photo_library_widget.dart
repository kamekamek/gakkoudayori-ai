import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:html' as html;

/// 写真ライブラリと挿入機能ウィジェット
///
/// 画像フローの「写真を選択」機能に対応
/// - ローカルファイル選択
/// - 画像プレビュー表示
/// - エディタへの挿入機能
class PhotoLibraryWidget extends StatefulWidget {
  final Function(String imagePath)? onImageSelected;

  const PhotoLibraryWidget({
    super.key,
    this.onImageSelected,
  });

  @override
  State<PhotoLibraryWidget> createState() => _PhotoLibraryWidgetState();
}

class _PhotoLibraryWidgetState extends State<PhotoLibraryWidget> {
  List<ImageItem> _selectedImages = [];
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ヘッダー
          Row(
            children: [
              Icon(Icons.photo_library, color: Colors.blue.shade600),
              const SizedBox(width: 8),
              const Text(
                '写真ライブラリ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _isUploading ? null : _selectImages,
                icon: _isUploading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_photo_alternate),
                label: Text(_isUploading ? 'アップロード中...' : '写真追加'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade500,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 画像グリッド
          Expanded(
            child: _selectedImages.isEmpty
                ? _buildEmptyState()
                : _buildImageGrid(),
          ),
        ],
      ),
    );
  }

  /// 空の状態表示
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(
              Icons.photo_library_outlined,
              size: 40,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '写真がありません',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '「写真追加」ボタンから画像を選択してください',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 画像グリッド表示
  Widget _buildImageGrid() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: _selectedImages.length,
      itemBuilder: (context, index) {
        final image = _selectedImages[index];
        return _buildImageTile(image, index);
      },
    );
  }

  /// 画像タイル表示
  Widget _buildImageTile(ImageItem image, int index) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Stack(
        children: [
          // 画像プレビュー
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: image.isUrl
                ? Image.network(
                    image.path,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade200,
                        child: Icon(
                          Icons.broken_image,
                          color: Colors.grey.shade400,
                        ),
                      );
                    },
                  )
                : Container(
                    color: Colors.grey.shade200,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image,
                            color: Colors.grey.shade400,
                            size: 32,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            image.name,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
          ),

          // アクションボタン
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.add_circle_outline,
                      color: Colors.white,
                      size: 18,
                    ),
                    onPressed: () => _insertImageToEditor(image),
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                    tooltip: 'エディタに挿入',
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.white,
                      size: 18,
                    ),
                    onPressed: () => _removeImage(index),
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                    tooltip: '削除',
                  ),
                ],
              ),
            ),
          ),

          // 名前表示
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Text(
                image.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 画像選択処理
  Future<void> _selectImages() async {
    setState(() {
      _isUploading = true;
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: true,
      );

      if (result != null) {
        for (var file in result.files) {
          if (file.bytes != null) {
            // Web環境でのファイル処理
            final blob = html.Blob([file.bytes!]);
            final url = html.Url.createObjectUrlFromBlob(blob);

            final imageItem = ImageItem(
              name: file.name,
              path: url,
              isUrl: true,
              size: file.size,
            );

            setState(() {
              _selectedImages.add(imageItem);
            });
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('画像の選択に失敗しました: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  /// エディタに画像挿入
  void _insertImageToEditor(ImageItem image) {
    widget.onImageSelected?.call(image.path);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('「${image.name}」をエディタに挿入しました'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 画像削除
  void _removeImage(int index) {
    final image = _selectedImages[index];

    // URLの解放（メモリリーク防止）
    if (image.isUrl) {
      html.Url.revokeObjectUrl(image.path);
    }

    setState(() {
      _selectedImages.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('「${image.name}」を削除しました'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  void dispose() {
    // URLの解放
    for (var image in _selectedImages) {
      if (image.isUrl) {
        html.Url.revokeObjectUrl(image.path);
      }
    }
    super.dispose();
  }
}

/// 画像アイテムクラス
class ImageItem {
  final String name;
  final String path;
  final bool isUrl;
  final int size;

  ImageItem({
    required this.name,
    required this.path,
    required this.isUrl,
    required this.size,
  });

  /// ファイルサイズを人間が読める形式に変換
  String get formattedSize {
    if (size < 1024) return '${size}B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}
