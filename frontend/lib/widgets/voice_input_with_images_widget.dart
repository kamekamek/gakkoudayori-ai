import 'package:flutter/material.dart';
import 'dart:html' as html;
import '../services/image_service.dart';

class VoiceInputWithImagesWidget extends StatefulWidget {
  final VoidCallback? onImagesSelected;
  final Function(List<ImageUploadResult>)? onImagesUploaded;
  final String userId;

  const VoiceInputWithImagesWidget({
    super.key,
    this.onImagesSelected,
    this.onImagesUploaded,
    this.userId = 'anonymous',
  });

  @override
  State<VoiceInputWithImagesWidget> createState() => _VoiceInputWithImagesWidgetState();
}

class _VoiceInputWithImagesWidgetState extends State<VoiceInputWithImagesWidget> {
  List<html.File> _selectedImages = [];
  List<ImageUploadResult> _uploadedImages = [];
  bool _isUploading = false;

  /// 画像選択処理
  Future<void> _selectImages() async {
    try {
      final selectedFiles = await ImageService.selectImages(
        multiple: true,
        acceptedTypes: ['image/*'],
      );

      if (selectedFiles != null && selectedFiles.isNotEmpty) {
        setState(() {
          _selectedImages = selectedFiles;
        });

        if (widget.onImagesSelected != null) {
          widget.onImagesSelected!();
        }

        _showMessage('${selectedFiles.length}枚の画像が選択されました');
      }
    } catch (e) {
      _showError('画像選択エラー: $e');
    }
  }

  /// 選択された画像をアップロード
  Future<void> _uploadSelectedImages() async {
    if (_selectedImages.isEmpty) {
      _showError('アップロードする画像がありません');
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final uploadResults = await ImageService.uploadImages(
        _selectedImages,
        widget.userId,
        category: 'newsletter',
      );

      setState(() {
        _uploadedImages = uploadResults;
        _isUploading = false;
      });

      if (widget.onImagesUploaded != null) {
        widget.onImagesUploaded!(uploadResults);
      }

      _showMessage('${uploadResults.length}枚の画像をアップロードしました');
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      _showError('画像アップロードエラー: $e');
    }
  }

  /// 画像を削除
  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
    _showMessage('画像を削除しました');
  }

  /// アップロード済み画像をクリア
  void _clearUploadedImages() {
    setState(() {
      _uploadedImages.clear();
    });
    _showMessage('アップロード済み画像をクリアしました');
  }

  /// メッセージ表示
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// エラーメッセージ表示
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダー
            Row(
              children: [
                Icon(Icons.add_photo_alternate, color: Colors.blue[600]),
                SizedBox(width: 8),
                Text(
                  '📷 画像を追加',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),

            // 画像選択ボタン
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isUploading ? null : _selectImages,
                icon: Icon(Icons.add_photo_alternate),
                label: Text('画像を選択'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),

            // 選択された画像の表示
            if (_selectedImages.isNotEmpty) ...[
              SizedBox(height: 12),
              Text(
                '選択された画像: ${_selectedImages.length}枚',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 8),
              Container(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) {
                    final file = _selectedImages[index];
                    final fileInfo = ImageService.getFileInfo(file);
                    
                    return Container(
                      width: 120,
                      margin: EdgeInsets.only(right: 8),
                      child: Card(
                        child: Column(
                          children: [
                            Expanded(
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(4),
                                  ),
                                ),
                                child: Icon(
                                  Icons.image,
                                  color: Colors.grey[600],
                                  size: 40,
                                ),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.all(4),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      file.name,
                                      style: TextStyle(fontSize: 10),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => _removeImage(index),
                                    child: Icon(
                                      Icons.close,
                                      size: 16,
                                      color: Colors.red[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 12),

              // アップロードボタン
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isUploading ? null : _uploadSelectedImages,
                  icon: _isUploading
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Icon(Icons.upload),
                  label: Text(_isUploading ? 'アップロード中...' : 'アップロード'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],

            // アップロード済み画像の表示
            if (_uploadedImages.isNotEmpty) ...[
              SizedBox(height: 16),
              Divider(),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.cloud_done, color: Colors.green[600], size: 20),
                  SizedBox(width: 8),
                  Text(
                    'アップロード完了: ${_uploadedImages.length}枚',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.green[700],
                    ),
                  ),
                  Spacer(),
                  TextButton(
                    onPressed: _clearUploadedImages,
                    child: Text('クリア'),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Container(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _uploadedImages.length,
                  itemBuilder: (context, index) {
                    final image = _uploadedImages[index];
                    
                    return Container(
                      width: 100,
                      margin: EdgeInsets.only(right: 8),
                      child: Card(
                        child: Column(
                          children: [
                            Expanded(
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(4),
                                  ),
                                ),
                                child: Icon(
                                  Icons.cloud_done,
                                  color: Colors.green[600],
                                  size: 30,
                                ),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.all(4),
                              child: Text(
                                image.filename,
                                style: TextStyle(fontSize: 9),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],

            // 使用方法の説明
            if (_selectedImages.isEmpty && _uploadedImages.isEmpty) ...[
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[100]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📝 使用方法',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '1. 「画像を選択」ボタンで画像ファイルを選択\n'
                      '2. 「アップロード」ボタンでサーバーにアップロード\n'
                      '3. 学級通信作成時に画像を挿入できます',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 11,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 外部からアップロード済み画像を取得
  List<ImageUploadResult> getUploadedImages() {
    return List.from(_uploadedImages);
  }

  /// 外部から選択状態をリセット
  void resetSelection() {
    setState(() {
      _selectedImages.clear();
      _uploadedImages.clear();
    });
  }
}