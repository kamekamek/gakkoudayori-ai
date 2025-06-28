import 'package:flutter/material.dart';

/// URL入力ダイアログ
class UrlInputDialog extends StatefulWidget {
  final Function(String url) onUrlSubmitted;

  const UrlInputDialog({
    super.key,
    required this.onUrlSubmitted,
  });

  @override
  State<UrlInputDialog> createState() => _UrlInputDialogState();
}

class _UrlInputDialogState extends State<UrlInputDialog> {
  final _urlController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isValidUrl = false;

  @override
  void initState() {
    super.initState();
    _urlController.addListener(_validateUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _validateUrl() {
    final url = _urlController.text.trim();
    final isValid = _isValidImageUrl(url);

    if (isValid != _isValidUrl) {
      setState(() {
        _isValidUrl = isValid;
      });
    }
  }

  bool _isValidImageUrl(String url) {
    if (url.isEmpty) return false;

    try {
      final uri = Uri.parse(url);

      // スキームチェック
      if (!uri.hasScheme || (!uri.scheme.startsWith('http'))) {
        return false;
      }

      // 画像拡張子チェック
      final path = uri.path.toLowerCase();
      final supportedExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];

      return supportedExtensions.any((ext) => path.endsWith(ext));
    } catch (e) {
      return false;
    }
  }

  void _submitUrl() {
    if (_formKey.currentState?.validate() == true && _isValidUrl) {
      widget.onUrlSubmitted(_urlController.text.trim());
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.link,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          const Text('URLから画像を追加'),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 説明文
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '対応形式',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'JPEG, PNG, GIF, WebP',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // URL入力フィールド
              TextFormField(
                controller: _urlController,
                decoration: InputDecoration(
                  labelText: '画像URL',
                  hintText: 'https://example.com/image.jpg',
                  prefixIcon: const Icon(Icons.link),
                  suffixIcon: _isValidUrl
                      ? Icon(
                          Icons.check_circle,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : null,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.url,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'URLを入力してください';
                  }

                  if (!_isValidImageUrl(value.trim())) {
                    return '有効な画像URLを入力してください';
                  }

                  return null;
                },
                onFieldSubmitted: (_) => _submitUrl(),
              ),

              const SizedBox(height: 16),

              // 使用例
              ExpansionTile(
                title: Text(
                  '使用例',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildExampleUrl('https://example.com/photo.jpg'),
                        _buildExampleUrl(
                            'https://cdn.example.com/images/school.png'),
                        _buildExampleUrl(
                            'https://photos.google.com/share/image.webp'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        ElevatedButton.icon(
          onPressed: _isValidUrl ? _submitUrl : null,
          icon: const Icon(Icons.download, size: 18),
          label: const Text('追加'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildExampleUrl(String url) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: GestureDetector(
        onTap: () {
          _urlController.text = url;
          _validateUrl();
        },
        child: Text(
          url,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                decoration: TextDecoration.underline,
              ),
        ),
      ),
    );
  }
}
