import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../editor/providers/demo_preview_provider.dart';
import '../../../ai_assistant/providers/demo_chat_provider.dart'; 
import '../../../../services/demo_data_service.dart';
import 'dart:html' as html;

/// デモ用のプレビューインターフェース
class DemoPreviewInterface extends StatefulWidget {
  const DemoPreviewInterface({super.key});

  @override
  State<DemoPreviewInterface> createState() => _DemoPreviewInterfaceState();
}

class _DemoPreviewInterfaceState extends State<DemoPreviewInterface> {
  @override
  void initState() {
    super.initState();
    
    // デモコンテンツを監視してプレビューを更新
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatProvider = context.read<DemoChatProvider>();
      final previewProvider = context.read<DemoPreviewProvider>();
      
      // チャットプロバイダーからHTMLが生成されたらプレビューに反映
      chatProvider.addListener(() {
        if (chatProvider.generatedHtml != null && 
            chatProvider.generatedHtml!.isNotEmpty) {
          previewProvider.updateHtmlContent(chatProvider.generatedHtml!);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DemoPreviewProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            // ツールバー
            _buildToolbar(provider),
            
            // プレビューエリア
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _buildPreviewContent(provider),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildToolbar(DemoPreviewProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Column(
        children: [
          
          // ツールバー（実際のUIと同じスタイル）
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: Color(0xFFE0E0E0),
                  width: 1,
                ),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // プレビューモード切り替えボタン
                  _buildModeButton(
                    icon: Icons.visibility,
                    label: 'プレビュー',
                    isSelected: provider.currentMode == 'preview',
                    onPressed: () => provider.setMode('preview'),
                  ),
                  
                  const SizedBox(width: 6),
                  
                  _buildModeButton(
                    icon: Icons.edit,
                    label: '編集',
                    isSelected: provider.currentMode == 'edit',
                    onPressed: () => provider.setMode('edit'),
                  ),
                  
                  const SizedBox(width: 6),
                  
                  _buildModeButton(
                    icon: Icons.print,
                    label: '印刷',
                    isSelected: provider.currentMode == 'printView',
                    onPressed: () => provider.setMode('printView'),
                  ),
                  
                  const SizedBox(width: 6),
                  
                  _buildModeButton(
                    icon: Icons.picture_as_pdf,
                    label: 'PDF',
                    isSelected: false,
                    onPressed: () => _generatePdf(provider),
                  ),
                  
                  const SizedBox(width: 6),
                  
                  _buildModeButton(
                    icon: Icons.school,
                    label: '📚Classroom',
                    isSelected: false,
                    onPressed: () => _showClassroomDialog(provider),
                  ),
                  
                  const SizedBox(width: 6),
                  
                  _buildModeButton(
                    icon: Icons.refresh,
                    label: '🔄',
                    isSelected: false,
                    onPressed: () => _showSnackBar('学級通信を再生成しました'),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // サンプル読み込みボタン
                  _buildActionButton(
                    icon: Icons.article,
                    tooltip: 'サンプル読み込み',
                    onPressed: () => _showSnackBar('サンプル学級通信を読み込みました'),
                    color: const Color(0xFFFF6B35),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onPressed,
  }) {
    return Material(
      borderRadius: BorderRadius.circular(6),
      color: isSelected
          ? const Color(0xFF2c5aa0).withOpacity(0.1)
          : Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? const Color(0xFF2c5aa0)
                    : const Color(0xFF616161),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected
                      ? const Color(0xFF2c5aa0)
                      : const Color(0xFF616161),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Material(
      borderRadius: BorderRadius.circular(8),
      color: color.withOpacity(0.1),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 20,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewContent(DemoPreviewProvider provider) {
    // 印刷モードの場合
    if (provider.currentMode == 'printView') {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.print, color: Colors.blue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '印刷プレビューモード\nブラウザの印刷機能をご利用ください',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(child: _buildNewsletterContent(provider)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 600),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: _buildNewsletterContent(provider),
      ),
    );
  }

  Widget _buildNewsletterContent(DemoPreviewProvider provider) {
    if (provider.title.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.article_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'AIが学級通信を生成します...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'チャットでAIと会話を始めてください',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return _buildHtmlPreview(provider);
  }

  Widget _buildHtmlPreview(DemoPreviewProvider provider) {
    return Consumer<DemoPreviewProvider>(
      builder: (context, providerWatch, child) {
        final isEditMode = provider.currentMode == 'edit';
        
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // タイトル
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.green, width: 3),
                  ),
                ),
                child: Column(
                  children: [
                    _buildEditableText(
                      text: provider.title,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                      isEditable: isEditMode,
                      textAlign: TextAlign.center,
                      onChanged: (newText) {
                        provider.updateTitle(newText);
                        _showSnackBar('タイトルが更新されました');
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildEditableText(
                      text: provider.date,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                      isEditable: isEditMode,
                      textAlign: TextAlign.center,
                      onChanged: (newText) {
                        provider.updateDate(newText);
                        _showSnackBar('日付が更新されました');
                      },
                    ),
                  ],
                ),
              ),
          
              const SizedBox(height: 30),
              
              // セクション1: エイサーの演技について
              _buildEditableSection(
                title: provider.section1Title,
                content: provider.section1Content,
                isEditable: isEditMode,
                onTitleChanged: (newTitle) {
                  provider.updateSection1Title(newTitle);
                  _showSnackBar('セクションタイトルが更新されました');
                },
                onContentChanged: (newContent) {
                  provider.updateSection1Content(newContent);
                  _showSnackBar('セクション内容が更新されました');
                },
              ),
              
              // セクション2: 徒競走での頑張り
              _buildEditableSection(
                title: provider.section2Title,
                content: provider.section2Content,
                isEditable: isEditMode,
                onTitleChanged: (newTitle) {
                  provider.updateSection2Title(newTitle);
                  _showSnackBar('セクションタイトルが更新されました');
                },
                onContentChanged: (newContent) {
                  provider.updateSection2Content(newContent);
                  _showSnackBar('セクション内容が更新されました');
                },
              ),
              
              // セクション3: 困難を乗り越えて
              _buildEditableSection(
                title: provider.section3Title,
                content: provider.section3Content,
                isEditable: isEditMode,
                onTitleChanged: (newTitle) {
                  provider.updateSection3Title(newTitle);
                  _showSnackBar('セクションタイトルが更新されました');
                },
                onContentChanged: (newContent) {
                  provider.updateSection3Content(newContent);
                  _showSnackBar('セクション内容が更新されました');
                },
              ),
              
              // セクション4: 今後の予定
              _buildEditableSection(
                title: provider.section4Title,
                content: provider.section4Content,
                isEditable: isEditMode,
                onTitleChanged: (newTitle) {
                  provider.updateSection4Title(newTitle);
                  _showSnackBar('セクションタイトルが更新されました');
                },
                onContentChanged: (newContent) {
                  provider.updateSection4Content(newContent);
                  _showSnackBar('セクション内容が更新されました');
                },
              ),
          
              const SizedBox(height: 40),
              
              // フッター
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey, width: 1),
                  ),
                ),
                child: Column(
                  children: [
                    _buildEditableText(
                      text: provider.schoolInfo,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                      isEditable: isEditMode,
                      textAlign: TextAlign.center,
                      onChanged: (newText) {
                        provider.updateSchoolInfo(newText);
                        _showSnackBar('学校・担任情報が更新されました');
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildEditableText(
                      text: provider.contactInfo,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                      isEditable: isEditMode,
                      textAlign: TextAlign.center,
                      onChanged: (newText) {
                        provider.updateContactInfo(newText);
                        _showSnackBar('連絡先が更新されました');
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEditableText({
    required String text,
    required TextStyle? style,
    required bool isEditable,
    required Function(String) onChanged,
    TextAlign? textAlign,
    int maxLines = 1,
  }) {
    if (!isEditable) {
      return Text(
        text,
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      );
    }

    return InkWell(
      onTap: () => _showEditDialog(text, onChanged, maxLines > 1),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blue.shade300, width: 1),
          borderRadius: BorderRadius.circular(4),
          color: Colors.blue.shade50,
        ),
        child: Text(
          text,
          style: style,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildEditableSection({
    required String title,
    required String content,
    required bool isEditable,
    required Function(String) onTitleChanged,
    required Function(String) onContentChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.only(left: 10, bottom: 15),
            decoration: const BoxDecoration(
              border: Border(
                left: BorderSide(color: Colors.green, width: 4),
              ),
            ),
            child: _buildEditableText(
              text: title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.green.shade700,
                fontWeight: FontWeight.bold,
              ),
              isEditable: isEditable,
              onChanged: onTitleChanged,
            ),
          ),
          _buildEditableText(
            text: content,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              height: 1.8,
              color: Colors.black87,
            ),
            isEditable: isEditable,
            maxLines: 10,
            onChanged: onContentChanged,
          ),
        ],
      ),
    );
  }

  void _showEditDialog(String currentText, Function(String) onChanged, bool isMultiLine) {
    final controller = TextEditingController(text: currentText);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📝 テキストを編集'),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: TextField(
            controller: controller,
            maxLines: isMultiLine ? 5 : 1,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'テキストを入力してください',
            ),
            autofocus: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              onChanged(controller.text);
              Navigator.of(context).pop();
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _generatePdf(DemoPreviewProvider provider) async {
    try {
      final pdfUrl = await provider.generatePdf();
      
      if (mounted) {
        _showSuccessDialog(
          '✅ PDF生成完了',
          'デモ用PDFが生成されました。\n実際の環境では自動ダウンロードされます。',
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // デモ用のダウンロードシミュレート
                html.window.open(
                  'data:application/pdf;base64,demo-pdf-content',
                  'demo_newsletter.pdf',
                );
              },
              child: const Text('ダウンロード'),
            ),
          ],
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('PDF生成エラー', e.toString());
      }
    }
  }

  void _showPrintDialog(DemoPreviewProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🖨️ 印刷'),
        content: const Text('デモモードでは実際の印刷は行われません。\n印刷プレビューを表示しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              provider.printNewsletter();
              _showSuccessDialog(
                '✅ 印刷開始',
                'デモ用印刷処理を実行しました。',
              );
            },
            child: const Text('印刷'),
          ),
        ],
      ),
    );
  }

  void _showClassroomDialog(DemoPreviewProvider provider) {
    final classrooms = DemoDataService.getDemoClassrooms();
    DemoClassroomCourse? selectedClassroom;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('📚 Google Classroom投稿'),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          content: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: 300,
              maxWidth: 400,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('投稿先のクラスを選択してください:'),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<DemoClassroomCourse>(
                      value: selectedClassroom,
                      hint: const Text('クラス選択'),
                      isExpanded: true,
                      itemHeight: 64, // アイテムの高さを十分に確保
                      items: classrooms.map((classroom) {
                        return DropdownMenuItem(
                          value: classroom,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  classroom.name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${classroom.section} (${classroom.studentCount}名)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedClassroom = value;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: selectedClassroom == null ? null : () async {
                Navigator.of(context).pop();
                
                try {
                  final postUrl = await provider.postToClassroom(
                    '運動会特集 - 学級通信',
                    'AIで生成した学級通信です。運動会での子供たちの活躍をまとめました。',
                  );
                  
                  if (mounted) {
                    _showSuccessDialog(
                      '✅ Classroom投稿完了',
                      '${selectedClassroom!.name}に投稿されました。\n\nデモURL: $postUrl',
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            html.window.open(postUrl, '_blank');
                          },
                          child: const Text('Classroomで確認'),
                        ),
                      ],
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    _showErrorDialog('Classroom投稿エラー', e.toString());
                  }
                }
              },
              child: const Text('投稿'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog(String title, String message, {List<Widget>? actions}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: actions ?? [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }
}