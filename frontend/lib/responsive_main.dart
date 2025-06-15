import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/audio_service.dart';
import 'services/graphical_record_service.dart';
import 'services/user_dictionary_service.dart';
import 'widgets/print_preview_widget.dart';
import 'widgets/user_dictionary_widget.dart';

import 'dart:html' as html;

/// 学級通信AI - レスポンシブ対応版
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(YutoriKyoshituApp());
}

class YutoriKyoshituApp extends StatelessWidget {
  const YutoriKyoshituApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '学級通信エディタ',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Noto Sans JP',
      ),
      home: ResponsiveHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ResponsiveHomePage extends StatefulWidget {
  const ResponsiveHomePage({super.key});

  @override
  ResponsiveHomePageState createState() => ResponsiveHomePageState();
}

class ResponsiveHomePageState extends State<ResponsiveHomePage> {
  final AudioService _audioService = AudioService();
  final GraphicalRecordService _graphicalRecordService =
      GraphicalRecordService();
  final UserDictionaryService _userDictionaryService = UserDictionaryService();

  // --- 状態変数 ---
  // 共通
  bool _isRecording = false;
  String _transcribedText = '';
  bool _isProcessing = false;
  String _inputText = '';
  final TextEditingController _textController = TextEditingController();
  String _statusMessage = '🎤 音声録音または文字入力で学級通信を作成してください';

  // 学級通信モード用 (2エージェント対応)
  String _generatedHtml = '';
  bool _isGenerating = false;
  String _selectedStyle = ''; // 初期状態では何も選択されていない
  Map<String, dynamic>? _structuredJsonData; // 第1エージェントの出力
  bool _showStyleButtons = false; // スタイル選択ボタンの表示制御

  @override
  void initState() {
    super.initState();
    _audioService.initializeJavaScriptBridge();

    _audioService.setOnRecordingStateChanged((isRecording) {
      setState(() {
        _isRecording = isRecording;
        _statusMessage = isRecording ? '🎤 録音中...' : '⏹️ 録音停止';
      });
    });

    _audioService.setOnAudioRecorded((base64Audio) {
      setState(() {
        _statusMessage = '🎙️ 文字起こし処理中...';
      });
    });

    _audioService.setOnTranscriptionCompleted((transcript) async {
      setState(() {
        _statusMessage = '🔧 ユーザー辞書で誤変換を修正中...';
      });

      // ユーザー辞書で文字起こし結果を修正
      final correctionResult =
          await _userDictionaryService.correctTranscription(
        transcript: transcript,
      );

      setState(() {
        _transcribedText = correctionResult.correctedText;
        _textController.text = correctionResult.correctedText;
        _inputText = correctionResult.correctedText.trim();
        _showStyleButtons = true; // 文字起こし完了後にスタイル選択ボタンを表示

        if (correctionResult.hasCorrections) {
          _statusMessage =
              '✅ 文字起こし完了！${correctionResult.correctionCount}件の誤変換を修正しました。スタイルを選択して「学級通信を作成する」ボタンを押してください';
        } else {
          _statusMessage = '✅ 文字起こし完了！スタイルを選択して「学級通信を作成する」ボタンを押してください';
        }
      });
    });

    // sample.htmlの内容をプレビューに表示
    debugPrint('🚀 [Init] initState完了 - sample.html読み込み開始');
    _loadSampleHtml();
  }

  /// sample.htmlの内容を読み込んでプレビューに表示
  Future<void> _loadSampleHtml() async {
    try {
      debugPrint('🚀 [Sample] _loadSampleHtml開始');
      final String sampleHtml = await rootBundle.loadString('web/sample.html');
      debugPrint('✅ [Sample] sample.htmlアセット読み込み成功');
      setState(() {
        _generatedHtml = sampleHtml;
        _statusMessage = '📄 サンプル学級通信を表示しています';
      });
      debugPrint('✅ [Sample] sample.htmlをプレビューに読み込み完了');
    } catch (e) {
      debugPrint('❌ [Sample] sample.html読み込みエラー: $e');
      setState(() {
        _statusMessage = '❌ サンプル読み込みエラー: $e';
      });
    }
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('学級通信エディタ'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            onPressed: _openUserDictionary,
            icon: Icon(Icons.book),
            tooltip: 'ユーザー辞書管理',
          ),
          SizedBox(width: 8),
        ],
      ),
      body: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
      floatingActionButton: isMobile && _generatedHtml.isNotEmpty
          ? Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton(
                  onPressed: _downloadPdf,
                  backgroundColor: Colors.purple[600],
                  heroTag: "pdf",
                  child: Icon(Icons.picture_as_pdf, color: Colors.white),
                ),
                SizedBox(height: 8),
                FloatingActionButton(
                  onPressed: _regenerateNewsletter,
                  backgroundColor: Colors.orange[600],
                  heroTag: "regenerate",
                  child: Icon(Icons.refresh, color: Colors.white),
                ),
              ],
            )
          : null,
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Container(
          width: 400,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(right: BorderSide(color: Colors.grey[300]!)),
          ),
          child: _buildVoiceInputSection(isCompact: false),
        ),
        Expanded(
          child: _buildPreviewEditorSection(),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
          ),
          child: _buildVoiceInputSection(isCompact: true),
        ),
        Expanded(
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: _buildPreviewEditorSection(),
          ),
        ),
      ],
    );
  }

  Widget _buildVoiceInputSection({required bool isCompact}) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            margin: EdgeInsets.only(bottom: 16),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[100]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[600]),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _statusMessage,
                    style: TextStyle(color: Colors.blue[800], fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          Center(
            child: InkWell(
              onTap: _isProcessing ? null : _toggleRecording,
              borderRadius: BorderRadius.circular(60),
              child: AnimatedContainer(
                duration: Duration(milliseconds: 300),
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color:
                      (_isRecording ? Colors.red : Colors.blue).withAlpha(30),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _isRecording ? Colors.red[300]! : Colors.blue[300]!,
                    width: 4,
                  ),
                ),
                child: Center(
                  child: Icon(
                    _isRecording ? Icons.mic_off : Icons.mic,
                    size: 60,
                    color: _isRecording ? Colors.red[600] : Colors.blue[600],
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 16),
          TextField(
            controller: _textController,
            maxLines: 6,
            onChanged: (text) {
              setState(() {
                _inputText = text;
                _showStyleButtons = text.trim().isNotEmpty;
                if (text.trim().isNotEmpty) {
                  _statusMessage =
                      '📝 テキスト入力完了！スタイルを選択して「学級通信を作成する」ボタンを押してください';
                } else {
                  _statusMessage = '🎤 音声録音または文字入力で学級通信を作成してください';
                }
              });
            },
            decoration: InputDecoration(
              hintText: 'または、学級通信の内容をここに入力してください...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
          ),
          SizedBox(height: 16),
          if (_showStyleButtons) _buildStyleSelection(),
          if (!isCompact) ...[
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: (_isGenerating || _isProcessing)
                        ? null
                        : _regenerateNewsletter,
                    icon: Icon(Icons.refresh, size: 16),
                    label: Text('再生成'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[600],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _downloadPdf,
                    icon: Icon(Icons.picture_as_pdf, size: 16),
                    label: Text('PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple[600],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStyleSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'スタイルを選択してください',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _styleButton(
                label: '📜 クラシック',
                style: 'classic',
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _styleButton(
                label: '🌟 モダン',
                style: 'modern',
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        // 明示的な生成ボタンを追加
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: (_isGenerating ||
                    _isProcessing ||
                    _inputText.trim().isEmpty ||
                    _selectedStyle.isEmpty)
                ? null
                : _generateNewsletterTwoAgent,
            icon: Icon(Icons.auto_awesome, size: 20),
            label: Text(
              '学級通信を作成する',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _styleButton({required String label, required String style}) {
    final isSelected = _selectedStyle == style;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedStyle = style;
          if (_inputText.trim().isNotEmpty) {
            _statusMessage = '✅ スタイル選択完了！「学級通信を作成する」ボタンを押してください';
          }
        });
        // スタイル選択のみで、生成は明示的なボタンで行う
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue[700] : Colors.grey[300],
        foregroundColor: isSelected ? Colors.white : Colors.black,
        padding: EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(label),
    );
  }

  Widget _buildPreviewEditorSection() {
    final isMobile = MediaQuery.of(context).size.width < 768;
    return Container(
      color: Colors.grey[200],
      padding: EdgeInsets.all(isMobile ? 8 : 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Icon(Icons.preview, color: Colors.blue[600]),
                SizedBox(width: 8),
                Text(
                  'プレビュー',
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                Spacer(),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _openUserDictionary,
                      icon: Icon(Icons.book, size: 16),
                      label: Text('辞書管理'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[600],
                        foregroundColor: Colors.white,
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _loadSampleHtml,
                      icon: Icon(Icons.description, size: 16),
                      label: Text('サンプル表示'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          Flexible(
            child: Container(
              width: double.infinity,
              height: isMobile ? 600 : 700,
              padding: EdgeInsets.all(isMobile ? 0 : 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  )
                ],
              ),
              child: _isProcessing
                  ? Center(child: CircularProgressIndicator())
                  : Builder(
                      builder: (context) {
                        return PrintPreviewWidget(
                          htmlContent: _generatedHtml,
                          height: isMobile ? 600 : 700,
                          enableMobilePrintView: true,
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleRecording() async {
    if (_isRecording) {
      await _audioService.stopRecording();
    } else {
      await _audioService.startRecording();
    }
  }

  // 新しい2エージェント処理フロー
  Future<void> _generateNewsletterTwoAgent() async {
    if (_isGenerating || _isProcessing) return;

    final inputText =
        _inputText.isNotEmpty ? _inputText : _textController.text.trim();
    if (inputText.isEmpty) {
      setState(() {
        _statusMessage = '❌ 入力テキストが空です。音声録音または文字入力をしてください。';
      });
      return;
    }

    _isGenerating = true;
    setState(() {
      _isProcessing = true;
      _statusMessage = '🤖 AI生成中... (2エージェント処理)';
    });

    try {
      final jsonResult = await _graphicalRecordService.convertSpeechToJson(
        transcribedText: inputText,
        customContext: 'style:$_selectedStyle',
      );

      if (!jsonResult.success || jsonResult.jsonData == null) {
        throw Exception(jsonResult.error ?? 'Failed to convert speech to JSON');
      }

      setState(() {
        _structuredJsonData = jsonResult.jsonData;
        _statusMessage = '🤖 1/2: 内容の構造化完了。レイアウトを生成中...';
      });

      final htmlResult =
          await _graphicalRecordService.convertJsonToGraphicalRecord(
        jsonData: _structuredJsonData!,
        template: _selectedStyle == 'classic'
            ? 'classic_newsletter'
            : 'modern_newsletter',
        customStyle: 'newsletter_optimized_for_print',
      );

      setState(() {
        _generatedHtml = htmlResult.htmlContent!;
        _statusMessage = '🎉 2エージェント処理完了！印刷最適化された学級通信をプレビューで確認してください';
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ AI生成でエラーが発生しました: $e';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
      _isGenerating = false;
    }
  }

  Future<void> _regenerateNewsletter() async {
    if (_transcribedText.isEmpty && _textController.text.trim().isEmpty) return;
    if (_isGenerating || _isProcessing) return;

    setState(() {
      _statusMessage = '🔄 再生成中...';
      _generatedHtml = '';
    });

    await _generateNewsletterTwoAgent();
  }

  Future<void> _downloadPdf() async {
    setState(() {
      _statusMessage = '📄 PDFを生成中...';
    });
    try {
      final String htmlContent = _generatedHtml;
      final result =
          await _graphicalRecordService.convertHtmlToPdf(htmlContent);

      if (result.success && result.pdfData != null) {
        final blob = html.Blob([result.pdfData!], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute("download", "GakkyuTsuushin.pdf")
          ..click();
        html.Url.revokeObjectUrl(url);
        setState(() {
          _statusMessage = '✅ PDFのダウンロードを開始しました';
        });
      } else {
        throw Exception(result.error ?? 'PDF data is null.');
      }
    } catch (e) {
      debugPrint('❌ PDF生成/ダウンロードエラー: $e');
      setState(() {
        _statusMessage = '❌ PDFの生成に失敗しました: $e';
      });
    }
  }

  /// ユーザー辞書管理画面を開く
  void _openUserDictionary() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UserDictionaryWidget(
          userId: 'default', // 現在はデフォルトユーザー
          onDictionaryUpdated: () {
            // 辞書更新時の処理（必要に応じて）
            setState(() {
              _statusMessage = '✅ ユーザー辞書が更新されました';
            });
          },
        ),
      ),
    );
  }
}
