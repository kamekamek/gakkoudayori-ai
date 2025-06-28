import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:html_editor_enhanced/html_editor.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

// WebSocketサーバーのURL
// TODO: 設定ファイルから読み込むようにする
const String wsBaseUrl = "ws://localhost:8081/api/v1";

class NewsletterPage extends ConsumerStatefulWidget {
  const NewsletterPage({Key? key}) : super(key: key);

  @override
  ConsumerState<NewsletterPage> createState() => _NewsletterPageState();
}

class _NewsletterPageState extends ConsumerState<NewsletterPage> {
  String _html = '<h1>学級通信</h1><p>左のチャット欄から「/create」と入力して開始してください。</p>';
  bool _editMode = false;
  final HtmlEditorController _editorController = HtmlEditorController();
  final _chatController = TextEditingController();

  late final String _sid;
  WebSocketChannel? _channel;

  final List<String> _chatHistory = [];

  @override
  void initState() {
    super.initState();
    _sid = const Uuid().v4();
    _connectWebSocket();
  }

  void _connectWebSocket() {
    final wsUrl = '$wsBaseUrl/ws/$_sid?user_id=flutter_client';
    _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

    _channel!.stream.listen(
      (data) {
        if (mounted) {
          final decoded = jsonDecode(data);
          setState(() {
            if (decoded['type'] == 'html') {
              _html = decoded['html'];
              if (_editMode) {
                _editorController.setText(_html);
              }
              _chatHistory.add("AI: HTMLを更新しました。");
            } else if (decoded['type'] == 'audit') {
              final errorText =
                  'HTML Validation: ${decoded['valid'] ? "OK" : decoded['errors'].join(", ")}';
              _chatHistory.add("AI: $errorText");
            } else if (decoded['type'] == 'error') {
              final errorText = 'Agent Error: ${decoded['message']}';
              _chatHistory.add("AI: $errorText");
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(errorText),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 5),
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.only(top: 50, left: 16, right: 16),
                  action: SnackBarAction(
                    label: '✕',
                    textColor: Colors.white,
                    onPressed: () {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    },
                  ),
                ),
              );
            }
          });
        }
      },
      onDone: () {
        if (mounted) {
          setState(() => _chatHistory.add("System: サーバーとの接続が切れました。"));
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() => _chatHistory.add("System: 接続エラー: $error"));
        }
      },
    );
    setState(() => _chatHistory.add("System: サーバーに接続しました。"));
  }

  void _sendMessage(String message) {
    final trimmedMessage = message.trim();
    if (trimmedMessage.isEmpty || _channel == null) return;

    setState(() {
      _chatHistory.add("You: $trimmedMessage");
    });

    _channel!.sink.add(jsonEncode({"message": trimmedMessage}));
    _chatController.clear();
  }

  void _toggleEditMode() async {
    if (_editMode) {
      final newHtml = await _editorController.getText();
      setState(() => _html = newHtml);
      _sendMessage("/edit\n$newHtml");
    } else {
      _editorController.setText(_html);
    }
    setState(() => _editMode = !_editMode);
  }

  @override
  void dispose() {
    _channel?.sink.close(status.goingAway);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('学級通信ジェネレーター (WebSocket)'),
        actions: [
          IconButton(
            icon: Icon(
                _editMode ? Icons.visibility_outlined : Icons.edit_outlined),
            tooltip: _editMode ? 'プレビュー' : '編集',
            onPressed: _toggleEditMode,
          ),
        ],
      ),
      body: Row(
        children: [
          Expanded(
            flex: 4,
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: _chatHistory.length,
                    itemBuilder: (context, index) => ListTile(
                      title: Text(_chatHistory[index]),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _chatController,
                          decoration: const InputDecoration(
                            hintText: '「/create」と入力...',
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: _sendMessage,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: () => _sendMessage(_chatController.text),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            flex: 6,
            child: _editMode
                ? HtmlEditor(
                    controller: _editorController,
                    htmlEditorOptions: HtmlEditorOptions(initialText: _html),
                    htmlToolbarOptions: const HtmlToolbarOptions(
                        toolbarPosition: ToolbarPosition.aboveEditor),
                  )
                : SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Html(data: _html),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
