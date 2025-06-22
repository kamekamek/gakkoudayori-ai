import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/services/services.dart';
import '../../../editor/presentation/widgets/print_preview_widget.dart';
import '../../../settings/presentation/widgets/user_dictionary_widget.dart';
import '../../../images/presentation/pages/image_management_page.dart';
import '../../../../core/models/models.dart';
import 'dart:html' as html;

/// 学校だよりAI メイン作成画面
/// デザインモックアップに基づいたチャットボット形式UI
class NewsletterCreationPage extends StatefulWidget {
  const NewsletterCreationPage({super.key});

  @override
  NewsletterCreationPageState createState() => NewsletterCreationPageState();
}

class NewsletterCreationPageState extends State<NewsletterCreationPage> {
  final AudioService _audioService = AudioService();
  final GraphicalRecordService _graphicalRecordService = GraphicalRecordService();
  final UserDictionaryService _userDictionaryService = UserDictionaryService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();

  // Chat state
  final List<ChatMessage> _chatMessages = [];
  bool _isRecording = false;
  bool _isProcessing = false;
  bool _isGenerating = false;
  bool _isDownloadingPdf = false;
  
  // Content state
  String _generatedHtml = '';
  String _selectedStyle = '';
  Map<String, dynamic>? _structuredJsonData;
  
  // Preview mode state
  PreviewMode _previewMode = PreviewMode.preview;

  @override
  void initState() {
    super.initState();
    _audioService.initializeJavaScriptBridge();
    _setupAudioCallbacks();
    _initializeChat();
  }

  void _setupAudioCallbacks() {
    _audioService.setOnRecordingStateChanged((isRecording) {
      setState(() {
        _isRecording = isRecording;
      });
    });

    _audioService.setOnAudioRecorded((base64Audio) {
      _addChatMessage(
        sender: 'system',
        message: '🎙️ 文字起こし処理中...',
        type: MessageType.status,
      );
    });

    _audioService.setOnTranscriptionCompleted((transcript) async {
      // Add transcribed text as user message
      _addChatMessage(
        sender: 'user',
        message: transcript,
        type: MessageType.voice,
      );
      
      // Correct transcription with user dictionary
      final correctionResult = await _userDictionaryService.correctTranscription(
        transcript: transcript,
      );

      if (correctionResult.hasCorrections) {
        _addChatMessage(
          sender: 'ai',
          message: '✅ 文字起こし完了！${correctionResult.correctionCount}件の誤変換を修正しました。どんなスタイルの学級通信にしますか？',
          type: MessageType.text,
          options: ['📜 クラシック', '🌟 モダン'],
        );
      } else {
        _addChatMessage(
          sender: 'ai',
          message: '✅ 文字起こし完了！どんなスタイルの学級通信にしますか？',
          type: MessageType.text,
          options: ['📜 クラシック', '🌟 モダン'],
        );
      }
    });
  }

  void _initializeChat() {
    _addChatMessage(
      sender: 'ai',
      message: 'こんにちは！今日はどんな学級通信を作りますか？',
      type: MessageType.text,
    );
  }

  void _addChatMessage({
    required String sender,
    required String message,
    required MessageType type,
    List<String>? options,
  }) {
    setState(() {
      _chatMessages.add(ChatMessage(
        sender: sender,
        message: message,
        type: type,
        timestamp: DateTime.now(),
        options: options,
      ));
    });
    
    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.school, size: 24),
            SizedBox(width: 8),
            Text('学校だよりAI'),
          ],
        ),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: _openSettings,
          ),
          IconButton(
            icon: Icon(Icons.help_outline),
            onPressed: _openHelp,
          ),
        ],
      ),
      body: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Left: Chat Panel
        Expanded(
          flex: 1,
          child: _buildChatPanel(),
        ),
        // Right: Preview Panel
        Expanded(
          flex: 1,
          child: _buildPreviewPanel(),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: TabBar(
              labelColor: Colors.blue[700],
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: Colors.blue[600],
              indicatorWeight: 3,
              labelStyle: GoogleFonts.notoSansJp(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              tabs: [
                Tab(
                  icon: Icon(Icons.chat, size: 20),
                  text: 'チャット',
                ),
                Tab(
                  icon: Icon(Icons.preview, size: 20),
                  text: 'プレビュー',
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildChatPanel(),
                _buildPreviewPanel(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatPanel() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Chat messages area
          Expanded(
            child: ListView.builder(
              controller: _chatScrollController,
              padding: EdgeInsets.all(16),
              itemCount: _chatMessages.length,
              itemBuilder: (context, index) {
                return _buildChatMessage(_chatMessages[index]);
              },
            ),
          ),
          // Input area
          _buildChatInput(),
        ],
      ),
    );
  }

  Widget _buildChatMessage(ChatMessage message) {
    final isUser = message.sender == 'user';
    final isSystem = message.sender == 'system';
    
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              backgroundColor: isSystem ? Colors.grey[300] : Colors.blue[100],
              child: Icon(
                isSystem ? Icons.info_outline : Icons.smart_toy,
                color: isSystem ? Colors.grey[600] : Colors.blue[600],
                size: 20,
              ),
            ),
            SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUser
                        ? Colors.blue[500]
                        : isSystem
                            ? Colors.grey[100]
                            : Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message.type == MessageType.voice)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.mic, size: 16, color: isUser ? Colors.white : Colors.grey[600]),
                            SizedBox(width: 4),
                            Text(
                              '音声入力',
                              style: TextStyle(
                                fontSize: 12,
                                color: isUser ? Colors.white70 : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      if (message.type == MessageType.voice) SizedBox(height: 4),
                      Text(
                        message.message,
                        style: GoogleFonts.notoSansJp(
                          color: isUser ? Colors.white : Colors.grey[800],
                          fontSize: 16,
                        ),
                      ),
                      if (message.options != null && message.options!.isNotEmpty) ...[
                        SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: message.options!.map((option) {
                            return ElevatedButton(
                              onPressed: () => _handleOptionSelected(option),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[600],
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: Text(option),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  _formatTime(message.timestamp),
                  style: GoogleFonts.notoSansJp(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          if (isUser) ...[
            SizedBox(width: 12),
            CircleAvatar(
              backgroundColor: Colors.grey[300],
              child: Icon(Icons.person, color: Colors.grey[600], size: 20),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChatInput() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'メッセージを入力...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: _sendTextMessage,
                ),
              ),
              SizedBox(width: 8),
              FloatingActionButton(
                heroTag: "mic_button",
                onPressed: _isProcessing ? null : _toggleRecording,
                backgroundColor: _isRecording ? Colors.red[400] : Colors.blue[600],
                child: Icon(
                  _isRecording ? Icons.mic_off : Icons.mic,
                  color: Colors.white,
                ),
                mini: true,
              ),
              SizedBox(width: 8),
              FloatingActionButton(
                heroTag: "send_button",
                onPressed: _messageController.text.trim().isNotEmpty ? () => _sendTextMessage(_messageController.text) : null,
                backgroundColor: Colors.green[600],
                child: Icon(Icons.send, color: Colors.white),
                mini: true,
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _openUserDictionary,
                  icon: Icon(Icons.book, size: 20),
                  label: Text('📝 辞書管理'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _openImageManager,
                  icon: Icon(Icons.photo_library, size: 20),
                  label: Text('📷 画像管理'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewPanel() {
    return Container(
      color: Colors.grey[100],
      child: Column(
        children: [
          // Preview toolbar
          _buildPreviewToolbar(),
          // Preview content
          Expanded(
            child: _buildPreviewContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewToolbar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Icon(Icons.preview, color: Colors.blue[600]),
          SizedBox(width: 8),
          Text(
            'プレビュー',
            style: GoogleFonts.notoSansJp(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          Spacer(),
          if (_generatedHtml.isNotEmpty) ...[
            _previewToolbarButton(
              icon: Icons.edit,
              label: '編集',
              onPressed: () => _setPreviewMode(PreviewMode.edit),
              isSelected: _previewMode == PreviewMode.edit,
            ),
            SizedBox(width: 8),
            _previewToolbarButton(
              icon: Icons.print,
              label: '印刷ビュー',
              onPressed: () => _setPreviewMode(PreviewMode.printView),
              isSelected: _previewMode == PreviewMode.printView,
            ),
            SizedBox(width: 8),
            _previewToolbarButton(
              icon: Icons.picture_as_pdf,
              label: 'PDF',
              onPressed: _downloadPdf,
              color: Colors.purple[600],
            ),
            SizedBox(width: 8),
            _previewToolbarButton(
              icon: Icons.refresh,
              label: '再生成',
              onPressed: (_isGenerating || _isProcessing) ? null : _regenerateNewsletter,
              color: Colors.orange[600],
            ),
          ],
        ],
      ),
    );
  }

  Widget _previewToolbarButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    bool isSelected = false,
    Color? color,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected 
            ? Colors.blue[700] 
            : color ?? Colors.grey[600],
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: Size(0, 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }

  Widget _buildPreviewContent() {
    if (_generatedHtml.isEmpty && !_isGenerating) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              '学級通信を作成すると、\nここにプレビューが表示されます',
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSansJp(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        Container(
          margin: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: PrintPreviewWidget(
              htmlContent: _generatedHtml,
              height: double.infinity,
              enableMobilePrintView: true,
            ),
          ),
        ),
        if (_isGenerating || _isDownloadingPdf)
          Container(
            margin: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  SizedBox(height: 16),
                  Text(
                    _isDownloadingPdf ? 'PDFを生成中...' : 'AIが生成中...',
                    style: GoogleFonts.notoSansJp(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // Event handlers
  void _toggleRecording() async {
    if (_isRecording) {
      await _audioService.stopRecording();
    } else {
      await _audioService.startRecording();
    }
  }

  void _sendTextMessage(String message) {
    if (message.trim().isEmpty) return;
    
    _addChatMessage(
      sender: 'user',
      message: message.trim(),
      type: MessageType.text,
    );
    
    _messageController.clear();
    
    // AI response logic based on conversation state
    _handleUserMessage(message.trim());
  }

  void _handleUserMessage(String message) {
    // Simple conversation flow
    if (_selectedStyle.isEmpty) {
      _addChatMessage(
        sender: 'ai',
        message: 'ありがとうございます！どんなスタイルの学級通信にしますか？',
        type: MessageType.text,
        options: ['📜 クラシック', '🌟 モダン'],
      );
    } else {
      _addChatMessage(
        sender: 'ai',
        message: '学級通信を生成しますね！',
        type: MessageType.text,
      );
      _generateNewsletterFromChat(message);
    }
  }

  void _handleOptionSelected(String option) {
    _addChatMessage(
      sender: 'user',
      message: option,
      type: MessageType.text,
    );
    
    if (option.contains('クラシック')) {
      _selectedStyle = 'classic';
      _addChatMessage(
        sender: 'ai',
        message: 'クラシックスタイルを選択されました。学級通信を生成しますね！',
        type: MessageType.text,
      );
      _generateNewsletterFromLastUserMessage();
    } else if (option.contains('モダン')) {
      _selectedStyle = 'modern';
      _addChatMessage(
        sender: 'ai',
        message: 'モダンスタイルを選択されました。学級通信を生成しますね！',
        type: MessageType.text,
      );
      _generateNewsletterFromLastUserMessage();
    }
  }

  void _generateNewsletterFromLastUserMessage() {
    // Find the last user message with actual content
    final lastUserMessage = _chatMessages
        .where((msg) => msg.sender == 'user' && msg.type != MessageType.status)
        .lastOrNull;
    
    if (lastUserMessage != null) {
      _generateNewsletterFromChat(lastUserMessage.message);
    }
  }

  void _generateNewsletterFromChat(String content) async {
    setState(() {
      _isGenerating = true;
      _isProcessing = true;
    });

    _addChatMessage(
      sender: 'ai',
      message: '🤖 AI生成中...',
      type: MessageType.status,
    );

    try {
      final jsonResult = await _graphicalRecordService.convertSpeechToJson(
        transcribedText: content,
        customContext: 'style:$_selectedStyle',
      );

      if (!jsonResult.success || jsonResult.jsonData == null) {
        throw Exception(jsonResult.error ?? 'Failed to convert speech to JSON');
      }

      setState(() {
        _structuredJsonData = jsonResult.jsonData;
      });

      _addChatMessage(
        sender: 'ai',
        message: '🤖 1/2: 内容の構造化完了。レイアウトを生成中...',
        type: MessageType.status,
      );

      final htmlResult = await _graphicalRecordService.convertJsonToGraphicalRecord(
        jsonData: _structuredJsonData!,
        template: _selectedStyle == 'classic' ? 'classic_newsletter' : 'modern_newsletter',
        customStyle: 'newsletter_optimized_for_print',
      );

      setState(() {
        _generatedHtml = htmlResult.htmlContent ?? '';
      });

      _addChatMessage(
        sender: 'ai',
        message: '🎉 学級通信生成完了！プレビューで確認してください',
        type: MessageType.text,
      );
    } catch (e) {
      _addChatMessage(
        sender: 'ai',
        message: '❌ AI生成でエラーが発生しました: $e',
        type: MessageType.text,
      );
    } finally {
      setState(() {
        _isProcessing = false;
        _isGenerating = false;
      });
    }
  }

  void _setPreviewMode(PreviewMode mode) {
    setState(() {
      _previewMode = mode;
    });
  }

  Future<void> _regenerateNewsletter() async {
    final lastUserMessage = _chatMessages
        .where((msg) => msg.sender == 'user' && msg.type != MessageType.status)
        .lastOrNull;
    
    if (lastUserMessage != null) {
      _addChatMessage(
        sender: 'ai',
        message: '🔄 再生成中...',
        type: MessageType.status,
      );
      
      setState(() {
        _generatedHtml = '';
      });
      
      _generateNewsletterFromChat(lastUserMessage.message);
    }
  }

  Future<void> _downloadPdf() async {
    if (_generatedHtml.isEmpty) return;

    setState(() {
      _isDownloadingPdf = true;
    });

    try {
      final result = await _graphicalRecordService.convertHtmlToPdf(_generatedHtml);

      if (result.success && result.pdfData != null) {
        final blob = html.Blob([result.pdfData!], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', 'GakkyuTsuushin.pdf')
          ..click();
        html.Url.revokeObjectUrl(url);

        _addChatMessage(
          sender: 'ai',
          message: '✅ PDFのダウンロードを開始しました',
          type: MessageType.status,
        );
      } else {
        throw Exception(result.error ?? 'PDF data is null.');
      }
    } catch (e) {
      _addChatMessage(
        sender: 'ai',
        message: '❌ PDFの生成に失敗しました: $e',
        type: MessageType.text,
      );
    } finally {
      setState(() {
        _isDownloadingPdf = false;
      });
    }
  }

  void _openUserDictionary() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UserDictionaryWidget(
          userId: 'default',
          onDictionaryUpdated: () {
            _addChatMessage(
              sender: 'ai',
              message: '✅ ユーザー辞書が更新されました',
              type: MessageType.status,
            );
          },
        ),
      ),
    );
  }

  void _openImageManager() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ImageManagementPage(
          isSelectionMode: false,
        ),
      ),
    ).then((selectedImages) {
      if (selectedImages != null && selectedImages is List<ImageFile>) {
        _addChatMessage(
          sender: 'ai',
          message: '✅ ${selectedImages.length}枚の画像が選択されました',
          type: MessageType.status,
        );
        // TODO: 選択された画像を学級通信に統合する処理
      }
    });
  }

  void _openSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('設定画面は準備中です')),
    );
  }

  void _openHelp() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('ヘルプ画面は準備中です')),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _audioService.dispose();
    _messageController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }
}

// Data models
class ChatMessage {
  final String sender;
  final String message;
  final MessageType type;
  final DateTime timestamp;
  final List<String>? options;

  ChatMessage({
    required this.sender,
    required this.message,
    required this.type,
    required this.timestamp,
    this.options,
  });
}

enum MessageType {
  text,
  voice,
  status,
}

enum PreviewMode {
  preview,
  edit,
  printView,
}

extension ListExtension<T> on List<T> {
  T? get lastOrNull => isEmpty ? null : last;
}