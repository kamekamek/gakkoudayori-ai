import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/conversational_ai_service.dart';
import '../widgets/chat_message_widget.dart';
import '../widgets/conversation_input_widget.dart';
import '../widgets/step_indicator_widget.dart';

/// 対話式学級通信作成ページ
class ConversationalNewsletterPage extends StatefulWidget {
  final String? initialTranscript;
  final Map<String, dynamic>? teacherProfile;

  const ConversationalNewsletterPage({
    Key? key,
    this.initialTranscript,
    this.teacherProfile,
  }) : super(key: key);

  @override
  State<ConversationalNewsletterPage> createState() =>
      _ConversationalNewsletterPageState();
}

class _ConversationalNewsletterPageState
    extends State<ConversationalNewsletterPage> {
  final ConversationalAIService _aiService = ConversationalAIService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _inputController = TextEditingController();

  String? _sessionId;
  List<ChatMessage> _messages = [];
  String _currentStep = 'audio_input';
  bool _isProcessing = false;
  Map<String, dynamic>? _currentStepData;

  @override
  void initState() {
    super.initState();
    if (widget.initialTranscript != null &&
        widget.initialTranscript!.isNotEmpty) {
      _startConversation();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _startConversation() async {
    if (widget.initialTranscript == null || widget.initialTranscript!.isEmpty) {
      return;
    }

    setState(() {
      _isProcessing = true;
      _messages.add(ChatMessage(
        id: 'user_audio',
        sender: 'user',
        content: '音声入力: \"${widget.initialTranscript}\"',
        timestamp: DateTime.now(),
        isUser: true,
      ));
    });

    try {
      final result = await _aiService.startConversation(
        audioTranscript: widget.initialTranscript!,
        teacherProfile: widget.teacherProfile ?? {},
      );

      if (result['success']) {
        _sessionId = result['session_id'];
        final stepData = result['current_step'];
        
        await _handleNewStep(stepData);
      } else {
        _showError('対話開始に失敗しました: ${result['error']}');
      }
    } catch (e) {
      _showError('対話開始エラー: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _handleNewStep(Map<String, dynamic> stepData) async {
    setState(() {
      _currentStep = stepData['step_type'] ?? 'unknown';
      _currentStepData = stepData['data'];
    });

    // AIメッセージを追加
    final aiMessage = ChatMessage(
      id: stepData['step_id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      sender: stepData['agent_name'] ?? 'AI Assistant',
      content: stepData['message'] ?? '',
      timestamp: DateTime.parse(stepData['timestamp'] ?? DateTime.now().toIso8601String()),
      isUser: false,
      stepType: stepData['step_type'],
      options: List<Map<String, dynamic>>.from(stepData['options'] ?? []),
      data: stepData['data'],
    );

    setState(() {
      _messages.add(aiMessage);
    });

    // スクロールを最下部に移動
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendResponse(Map<String, dynamic> response) async {
    if (_sessionId == null) return;

    setState(() {
      _isProcessing = true;
    });

    // ユーザーメッセージを追加
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sender: 'user',
      content: _formatUserResponse(response),
      timestamp: DateTime.now(),
      isUser: true,
    );

    setState(() {
      _messages.add(userMessage);
    });

    try {
      final result = await _aiService.respondToConversation(
        sessionId: _sessionId!,
        userResponse: response,
      );

      if (result['success']) {
        if (result.containsKey('step')) {
          await _handleNewStep(result['step']);
        }
        
        // セッション完了チェック
        if (result['session_complete'] == true) {
          _handleSessionComplete(result);
        }
      } else {
        _showError('応答処理に失敗しました: ${result['error']}');
      }
    } catch (e) {
      _showError('応答エラー: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _handleSessionComplete(Map<String, dynamic> result) {
    final completionMessage = ChatMessage(
      id: 'completion',
      sender: 'System',
      content: '🎉 学級通信が完成しました！',
      timestamp: DateTime.now(),
      isUser: false,
      stepType: 'complete',
      data: result,
    );

    setState(() {
      _messages.add(completionMessage);
      _currentStep = 'complete';
    });

    // 完成ダイアログ表示
    _showCompletionDialog(result);
  }

  void _showCompletionDialog(Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('🎉 学級通信完成'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('学級通信の作成が完了しました！'),
              const SizedBox(height: 16),
              if (result['download_url'] != null)
                ElevatedButton.icon(
                  onPressed: () {
                    // PDF ダウンロード処理
                    _downloadPDF(result['download_url']);
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('PDF ダウンロード'),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // 新しい通信作成
                _startNewNewsletter();
              },
              child: const Text('新しい通信を作成'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('完了'),
            ),
          ],
        );
      },
    );
  }

  void _downloadPDF(String downloadUrl) {
    // PDF ダウンロード実装
    if (kDebugMode) {
      print('PDF download: $downloadUrl');
    }
    // TODO: 実際のダウンロード処理を実装
  }

  void _startNewNewsletter() {
    setState(() {
      _sessionId = null;
      _messages.clear();
      _currentStep = 'audio_input';
      _currentStepData = null;
    });
  }

  String _formatUserResponse(Map<String, dynamic> response) {
    final action = response['action'];
    
    switch (action) {
      case 'approve':
        return '✅ 承認しました';
      case 'modify':
        return '📝 修正要求: ${response['modification_request'] ?? ''}';
      case 'regenerate':
        return '🔄 再生成をリクエストしました';
      case 'selected_design':
        return '🎨 デザインを選択: ${response['selected_design_id']}';
      case 'generate_pdf':
        return '📄 PDF生成をリクエスト';
      default:
        return '選択: $action';
    }
  }

  void _showError(String message) {
    final errorMessage = ChatMessage(
      id: 'error_${DateTime.now().millisecondsSinceEpoch}',
      sender: 'System',
      content: '❌ $message',
      timestamp: DateTime.now(),
      isUser: false,
      stepType: 'error',
    );

    setState(() {
      _messages.add(errorMessage);
    });

    // エラーダイアログも表示
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('エラー'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '対話式学級通信作成',
          style: GoogleFonts.notoSansJp(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          if (_sessionId != null)
            IconButton(
              onPressed: _startNewNewsletter,
              icon: const Icon(Icons.refresh),
              tooltip: '新しい通信を作成',
            ),
        ],
      ),
      body: Column(
        children: [
          // ステップインジケーター
          StepIndicatorWidget(
            currentStep: _currentStep,
            completedSteps: _getCompletedSteps(),
          ),
          
          // チャットエリア
          Expanded(
            child: Container(
              color: Colors.grey[50],
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length + (_isProcessing ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length && _isProcessing) {
                    // ローディングインジケーター
                    return Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.blue[100],
                            child: Icon(Icons.smart_toy, color: Colors.blue[600]),
                          ),
                          const SizedBox(width: 12),
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '処理中...',
                            style: GoogleFonts.notoSansJp(
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  return ChatMessageWidget(
                    message: _messages[index],
                    onOptionSelected: _sendResponse,
                  );
                },
              ),
            ),
          ),
          
          // 入力エリア
          if (_currentStep != 'complete' && !_isProcessing)
            ConversationInputWidget(
              currentStep: _currentStep,
              stepData: _currentStepData,
              controller: _inputController,
              onSendResponse: _sendResponse,
            ),
        ],
      ),
    );
  }

  List<String> _getCompletedSteps() {
    // 現在のメッセージから完了ステップを推定
    final completedSteps = <String>[];
    
    for (final message in _messages) {
      if (!message.isUser && message.stepType != null) {
        final stepType = message.stepType!;
        if (stepType == 'content_review' && !completedSteps.contains('content_generation')) {
          completedSteps.add('content_generation');
        } else if (stepType == 'design_selection' && !completedSteps.contains('content_review')) {
          completedSteps.add('content_review');
        } else if (stepType == 'html_review' && !completedSteps.contains('design_selection')) {
          completedSteps.add('design_selection');
        } else if (stepType == 'final_approval' && !completedSteps.contains('html_generation')) {
          completedSteps.add('html_generation');
        } else if (stepType == 'complete') {
          completedSteps.addAll(['content_generation', 'content_review', 'design_selection', 'html_generation', 'final_approval']);
        }
      }
    }
    
    return completedSteps;
  }
}

/// チャットメッセージデータクラス
class ChatMessage {
  final String id;
  final String sender;
  final String content;
  final DateTime timestamp;
  final bool isUser;
  final String? stepType;
  final List<Map<String, dynamic>>? options;
  final Map<String, dynamic>? data;

  ChatMessage({
    required this.id,
    required this.sender,
    required this.content,
    required this.timestamp,
    required this.isUser,
    this.stepType,
    this.options,
    this.data,
  });
}