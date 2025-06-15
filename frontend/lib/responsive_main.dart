import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/audio_service.dart';
import 'services/graphical_record_service.dart';
import 'services/user_dictionary_service.dart';
import 'services/ai_voice_coaching_service.dart';
import 'services/seasonal_detection_service.dart';
import 'widgets/print_preview_widget.dart';
import 'widgets/user_dictionary_widget.dart';
import 'widgets/swipe_gesture_editor.dart';

import 'dart:html' as html;

/// 学校だよりAI - レスポンシブ対応版
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(GakkouDayoriAiApp());
}

class GakkouDayoriAiApp extends StatelessWidget {
  const GakkouDayoriAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '学校だよりAI',
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

class ResponsiveHomePageState extends State<ResponsiveHomePage> 
    with SingleTickerProviderStateMixin {
  final AudioService _audioService = AudioService();
  final GraphicalRecordService _graphicalRecordService =
      GraphicalRecordService();
  final UserDictionaryService _userDictionaryService = UserDictionaryService();
  final AIVoiceCoachingService _aiCoachingService = AIVoiceCoachingService();
  final SeasonalDetectionService _seasonalDetectionService = SeasonalDetectionService();
  
  // タブ状態管理
  TabController? _tabController;
  int _currentTabIndex = 0;

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
  double _aiProgress = 0.0;
  String _selectedStyle = ''; // 初期状態では何も選択されていない
  Map<String, dynamic>? _structuredJsonData; // 第1エージェントの出力
  bool _showStyleButtons = false; // スタイル選択ボタンの表示制御
  
  // AI音声コーチング関連
  bool _isAICoachingActive = false;
  String _realtimeTranscript = '';
  
  // 季節感検出システム関連
  SeasonalDetectionResult? _seasonalDetectionResult;
  SeasonalTemplate? _currentSeasonalTemplate;
  final bool _isSeasonalDetectionEnabled = true;

  @override
  void initState() {
    super.initState();
    
    // タブコントローラー初期化
    _tabController = TabController(length: 2, vsync: this);
    _tabController!.addListener(() {
      if (_tabController!.indexIsChanging) {
        setState(() {
          _currentTabIndex = _tabController!.index;
        });
      }
    });
    
    _audioService.initializeJavaScriptBridge();

    _audioService.setOnRecordingStateChanged((isRecording) {
      setState(() {
        _isRecording = isRecording;
        _statusMessage = isRecording ? '🎤 録音中...' : '⏹️ 録音停止';
        
        // AIコーチング連動
        if (isRecording && !_isAICoachingActive) {
          _startAICoaching();
        } else if (!isRecording && _isAICoachingActive) {
          _stopAICoaching();
        }
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
              '✅ 文字起こし完了！${correctionResult.correctionCount}件の誤変換を修正しました。季節感を自動検出中...';
        } else {
          _statusMessage = '✅ 文字起こし完了！季節感を自動検出中...';
        }
        
        // 季節感検出を実行
        _detectSeasonalTheme(correctionResult.correctedText);
      });
    });

    // リアルタイム文字起こしコールバック設定 (AIコーチング用)
    _audioService.setOnRealtimeTranscript((transcript) {
      setState(() {
        _realtimeTranscript = transcript;
      });
      
      // AIコーチングサービスにリアルタイム音声分析を依頼
      if (_isAICoachingActive) {
        _aiCoachingService.analyzeRealTimeVoice(transcript);
      }
    });
    
    // sample.htmlの内容をプレビューに表示
    _loadSampleHtml();
  }

  /// sample.htmlの内容を読み込んでプレビューに表示
  Future<void> _loadSampleHtml() async {
    try {
      final String sampleHtml = await rootBundle.loadString('web/sample.html');
      setState(() {
        _generatedHtml = sampleHtml;
        _statusMessage = '📄 サンプル学級通信を表示しています';
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ サンプル読み込みエラー: $e';
      });
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _audioService.dispose();
    _aiCoachingService.stopCoaching();
    super.dispose();
  }
  
  /// 🎤 AIコーチング開始
  Future<void> _startAICoaching() async {
    if (_isAICoachingActive) return;
    
    setState(() {
      _isAICoachingActive = true;
    });
    
    await _aiCoachingService.startCoaching();
    
    // メッセージストリームを監視
    _aiCoachingService.messageStream?.listen((message) {
      if (mounted && message.type != CoachingType.system) {
        // システムメッセージ以外はステータスに表示
        setState(() {
          _statusMessage = '🤖 AIコーチ: ${message.message}';
        });
      }
    });
  }
  
  /// 🎤 AIコーチング停止
  Future<void> _stopAICoaching() async {
    if (!_isAICoachingActive) return;
    
    setState(() {
      _isAICoachingActive = false;
    });
    
    await _aiCoachingService.stopCoaching();
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
      ),
      body: Stack(
        children: [
          isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
          // AI音声コーチング表示
          if (_isAICoachingActive)
            Positioned(
              top: 80,
              left: 16,
              right: 16,
              child: AIVoiceCoachingWidget(
                isVisible: _isAICoachingActive,
                onClose: () {
                  setState(() {
                    _isAICoachingActive = false;
                  });
                },
              ),
            ),
        ],
      ),
      floatingActionButton: null, // スマホではタブ内に移動
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
        // 固定タブバー
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.blue[700],
            unselectedLabelColor: Colors.grey[600],
            indicatorColor: Colors.blue[600],
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            tabs: [
              Tab(
                icon: Icon(Icons.mic, size: 20),
                text: '音声入力',
              ),
              Tab(
                icon: Icon(Icons.preview, size: 20),
                text: 'プレビュー',
              ),
            ],
          ),
        ),
        // タブコンテンツ
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // 音声入力タブ
              Container(
                color: Colors.white,
                padding: EdgeInsets.all(16),
                child: _buildVoiceInputSection(isCompact: true),
              ),
              // プレビュータブ
              Container(
                color: Colors.grey[50],
                child: _buildPreviewEditorSection(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayoutOld() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          // タブバー
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
              labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              tabs: [
                Tab(
                  icon: Icon(Icons.mic, size: 20),
                  text: '音声入力',
                ),
                Tab(
                  icon: Icon(Icons.preview, size: 20),
                  text: 'プレビュー',
                ),
              ],
            ),
          ),
          // タブコンテンツ
          Expanded(
            child: TabBarView(
              children: [
                // 音声入力タブ
                Container(
                  color: Colors.white,
                  padding: EdgeInsets.all(16),
                  child: _buildVoiceInputSection(isCompact: true),
                ),
                // プレビュータブ
                Container(
                  color: Colors.grey[50],
                  child: _buildPreviewEditorSection(),
                ),
              ],
            ),
          ),
        ],
      ),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                if (_isProcessing && _aiProgress > 0) ...[
                  SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: _aiProgress,
                    backgroundColor: Colors.blue[100],
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${(_aiProgress * 100).toInt()}% 完了',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Center(
            child: InkWell(
              onTap: _isProcessing ? null : _toggleRecording,
              borderRadius: BorderRadius.circular(60),
              child: AnimatedContainer(
                duration: Duration(milliseconds: 300),
                width: isCompact ? 120 : 140, // スマホでより大きく
                height: isCompact ? 120 : 140, // 44px最小タップサイズを大幅に上回る
                decoration: BoxDecoration(
                  color: (_isRecording ? Colors.red : Colors.blue).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _isRecording ? Colors.red[300]! : Colors.blue[300]!,
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (_isRecording ? Colors.red : Colors.blue).withValues(alpha: 0.3),
                      blurRadius: _isRecording ? 15 : 8,
                      spreadRadius: _isRecording ? 3 : 1,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    _isRecording ? Icons.mic_off : Icons.mic,
                    size: isCompact ? 56 : 70, // アイコンサイズも調整
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
                  _statusMessage = '📝 テキスト入力完了！季節感を自動検出中...';
                  // テキスト変更時も季節感検出を実行
                  _detectSeasonalTheme(text);
                } else {
                  _statusMessage = '🎤 音声録音または文字入力で学級通信を作成してください';
                  _seasonalDetectionResult = null;
                  _currentSeasonalTemplate = null;
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
          // 辞書管理ボタン
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openUserDictionary,
              icon: Icon(Icons.book, size: 20),
              label: Text('ユーザー辞書管理'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[600],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          SizedBox(height: 16),
          if (_seasonalDetectionResult != null) _buildSeasonalDetectionResult(),
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
                  isMobile ? 'スワイプ編集' : 'プレビュー',
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                if (isMobile) ...[
                  Icon(Icons.swipe, color: Colors.blue[600], size: 20),
                  SizedBox(width: 4),
                ],
                Spacer(),
                if (_generatedHtml.isNotEmpty && isMobile) ...[
                  IconButton(
                    onPressed: _downloadPdf,
                    icon: Icon(Icons.picture_as_pdf),
                    tooltip: 'PDF保存',
                    color: Colors.purple[600],
                  ),
                  IconButton(
                    onPressed: _regenerateNewsletter,
                    icon: Icon(Icons.refresh),
                    tooltip: '再生成',
                    color: Colors.orange[600],
                  ),
                ] else
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
                  : isMobile
                      ? _buildSwipeEnabledPreview()
                      : _buildDesktopPreview(),
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

  // 🚀 季節感統合処理フロー（革新的アップデート）
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
      _statusMessage = '🎨 季節感統合AI生成開始... (1/4)';
      _aiProgress = 0.1;
    });

    try {
      // 🎯 新機能：季節感統合ワークフローを使用
      final result = await _graphicalRecordService.generateSeasonalNewsletter(
        transcribedText: inputText,
        template: _selectedStyle,
        style: _selectedStyle,
      );

      if (!result.success || result.htmlContent == null) {
        throw Exception(result.error ?? 'Seasonal newsletter generation failed');
      }

      setState(() {
        _generatedHtml = result.htmlContent!;
        _structuredJsonData = result.jsonData;
        
        // 季節感検出結果を更新（既に検出済みの場合は上書き）
        if (result.seasonalDetection != null && result.seasonalTemplate != null) {
          _seasonalDetectionResult = result.seasonalDetection;
          _currentSeasonalTemplate = result.seasonalTemplate;
        }
        
        _statusMessage = '🎉 季節感統合学級通信生成完了！${_seasonalDetectionResult != null ? _getSeasonName(_seasonalDetectionResult!.primarySeason) : ''}テーマを適用しました';
        _aiProgress = 1.0;
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ 季節感統合AI生成でエラーが発生しました: $e';
      });
    } finally {
      setState(() {
        _isProcessing = false;
        _aiProgress = 0.0;
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
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', 'GakkyuTsuushin.pdf')
          ..click();
        html.Url.revokeObjectUrl(url);
        setState(() {
          _statusMessage = '✅ PDFのダウンロードを開始しました';
        });
      } else {
        throw Exception(result.error ?? 'PDF data is null.');
      }
    } catch (e) {
      setState(() {
        _statusMessage = '❌ PDFの生成に失敗しました: $e';
      });
    }
  }

  /// スワイプ対応プレビュー (モバイル用)
  Widget _buildSwipeEnabledPreview() {
    return SwipeGestureEditor(
      htmlContent: _generatedHtml,
      onContentChanged: (newContent) {
        setState(() {
          _generatedHtml = newContent;
          _statusMessage = '✏️ コンテンツを編集しました';
        });
      },
      onFontSizeChanged: (newSize) {
        setState(() {
          _statusMessage = '📝 フォントサイズを${newSize.toInt()}pxに変更';
        });
      },
      onEditModeActivated: (message) {
        setState(() {
          _statusMessage = message;
        });
      },
      child: PrintPreviewWidget(
        htmlContent: _generatedHtml,
        height: 600,
        enableMobilePrintView: true,
      ),
    );
  }

  /// デスクトップ用プレビュー
  Widget _buildDesktopPreview() {
    return PrintPreviewWidget(
      htmlContent: _generatedHtml,
      height: 700,
      enableMobilePrintView: true,
    );
  }

  /// 季節感検出を実行
  Future<void> _detectSeasonalTheme(String inputText) async {
    if (!_isSeasonalDetectionEnabled || inputText.trim().isEmpty) return;

    try {
      final detectionResult = await _seasonalDetectionService.detectSeasonFromText(inputText);
      final template = await _seasonalDetectionService.generateSeasonalTemplate(detectionResult);
      
      setState(() {
        _seasonalDetectionResult = detectionResult;
        _currentSeasonalTemplate = template;
        _statusMessage = '🎨 季節感検出完了！${_getSeasonName(detectionResult.primarySeason)}テーマを適用 - スタイルを選択してください';
      });
    } catch (e) {
      setState(() {
        _statusMessage = '⚠️ 季節感検出でエラーが発生しましたが、通常の処理を続行します';
      });
    }
  }

  /// 季節名取得
  String _getSeasonName(Season season) {
    switch (season) {
      case Season.spring:
        return '春🌸';
      case Season.summer:
        return '夏☀️';
      case Season.autumn:
        return '秋🍂';
      case Season.winter:
        return '冬❄️';
    }
  }

  /// 季節感検出結果表示ウィジェット
  Widget _buildSeasonalDetectionResult() {
    if (_seasonalDetectionResult == null) return SizedBox.shrink();

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.green[600]),
              SizedBox(width: 8),
              Text(
                '🎨 季節感自動検出',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                  fontSize: 16,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '検出された季節: ${_getSeasonName(_seasonalDetectionResult!.primarySeason)}',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (_seasonalDetectionResult!.detectedEvents.isNotEmpty) ...[
                      SizedBox(height: 4),
                      Text(
                        '学校行事: ${_seasonalDetectionResult!.detectedEvents.map((e) => e.name).join(', ')}',
                        style: TextStyle(color: Colors.green[700]),
                      ),
                    ],
                    if (_seasonalDetectionResult!.seasonalKeywords.isNotEmpty) ...[
                      SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: _seasonalDetectionResult!.seasonalKeywords.take(5).map((keyword) => 
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              keyword,
                              style: TextStyle(
                                color: Colors.green[800],
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Color(int.parse(_currentSeasonalTemplate?.primaryColor.replaceAll('#', '0xFF') ?? '0xFF4CAF50')),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _getSeasonalEmoji(_seasonalDetectionResult!.primarySeason),
                    style: TextStyle(fontSize: 24),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 季節絵文字取得
  String _getSeasonalEmoji(Season season) {
    switch (season) {
      case Season.spring:
        return '🌸';
      case Season.summer:
        return '☀️';
      case Season.autumn:
        return '🍂';
      case Season.winter:
        return '❄️';
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
