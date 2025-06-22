import 'package:flutter/material.dart';
import '../../../../core/models/models.dart';
import '../../../../core/utils/utils.dart';

/// 画像付きチャットメッセージのウィジェット
class ChatMessageImageWidget extends StatelessWidget {
  final ChatMessage message;
  final List<ImageFile> attachedImages;
  final Function(ImageFile)? onImageTap;

  const ChatMessageImageWidget({
    super.key,
    required this.message,
    this.attachedImages = const [],
    this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // アバター
          CircleAvatar(
            radius: 16,
            backgroundColor: message.isUser 
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.secondary,
            child: Icon(
              message.isUser ? Icons.person : Icons.smart_toy,
              size: 16,
              color: message.isUser 
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSecondary,
            ),
          ),
          
          const SizedBox(width: 8),
          
          // メッセージコンテンツ
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 送信者
                Text(
                  message.isUser ? 'あなた' : 'AIアシスタント',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                
                const SizedBox(height: 4),
                
                // メッセージ本体
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: message.isUser 
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // テキストメッセージ
                      if (message.message.isNotEmpty)
                        Text(
                          message.message,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: message.isUser 
                                ? Theme.of(context).colorScheme.onPrimaryContainer
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      
                      // 画像表示
                      if (attachedImages.isNotEmpty) ...[
                        if (message.message.isNotEmpty) const SizedBox(height: 8),
                        _buildImagesGrid(),
                      ],
                    ],
                  ),
                ),
                
                // タイムスタンプ
                const SizedBox(height: 4),
                Text(
                  message.timestamp.toRelativeTime(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagesGrid() {
    if (attachedImages.isEmpty) return const SizedBox.shrink();
    
    if (attachedImages.length == 1) {
      return _buildSingleImage(attachedImages.first);
    } else if (attachedImages.length <= 4) {
      return _buildMultipleImages();
    } else {
      return _buildManyImages();
    }
  }

  Widget _buildSingleImage(ImageFile image) {
    return GestureDetector(
      onTap: () => onImageTap?.call(image),
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 300,
          maxHeight: 200,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            image.bytes,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _buildMultipleImages() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: attachedImages.length == 2 ? 2 : 2,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
        childAspectRatio: 1,
      ),
      itemCount: attachedImages.length,
      itemBuilder: (context, index) {
        final image = attachedImages[index];
        return GestureDetector(
          onTap: () => onImageTap?.call(image),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.memory(
              image.bytes,
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    );
  }

  Widget _buildManyImages() {
    final displayImages = attachedImages.take(3).toList();
    final remainingCount = attachedImages.length - 3;
    
    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
            childAspectRatio: 1,
          ),
          itemCount: 3,
          itemBuilder: (context, index) {
            if (index < 2) {
              final image = displayImages[index];
              return GestureDetector(
                onTap: () => onImageTap?.call(image),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.memory(
                    image.bytes,
                    fit: BoxFit.cover,
                  ),
                ),
              );
            } else {
              // 残り枚数表示
              return GestureDetector(
                onTap: () => _showAllImages(),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.memory(
                          displayImages[2].bytes,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            '+$remainingCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
          },
        ),
      ],
    );
  }

  void _showAllImages() {
    // 全画像表示のダイアログを実装
    // TODO: 画像ギャラリーダイアログ
  }
}