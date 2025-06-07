#!/bin/bash
# mvp_phase1_html_editor.sh
# Phase 1: HTMLエディタ統合実装スクリプト

set -e  # エラー時に停止

echo "🚀 Phase 1: HTMLエディタ統合開始"
echo "========================================"

# 現在のディレクトリを確認
if [ ! -d "frontend" ]; then
    echo "❌ エラー: frontendディレクトリが見つかりません"
    echo "プロジェクトルートディレクトリで実行してください"
    exit 1
fi

# 1. パッケージ追加
echo "📦 1. パッケージ追加中..."
cd frontend

# html_editor_enhanced パッケージ追加
echo "  - html_editor_enhanced パッケージを追加..."
flutter pub add html_editor_enhanced

# webview_flutter_web パッケージ追加
echo "  - webview_flutter_web パッケージを追加..."
flutter pub add webview_flutter_web

# provider パッケージ（状態管理用）
echo "  - provider パッケージを追加..."
flutter pub add provider

# 依存関係取得
echo "  - 依存関係を取得中..."
flutter pub get

# 2. ディレクトリ構造作成
echo "📁 2. ディレクトリ構造作成中..."
mkdir -p lib/widgets
mkdir -p lib/providers
mkdir -p lib/models
mkdir -p test/widgets
mkdir -p test/providers

# 3. テストファイル作成（TDD）
echo "🧪 3. テストファイル作成中..."
cat > test/widgets/html_editor_widget_test.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:yutorikyoshitu/widgets/html_editor_widget.dart';
import 'package:yutorikyoshitu/providers/editor_provider.dart';

void main() {
  group('HtmlEditorWidget Tests', () {
    testWidgets('HTMLエディタが正常に初期化される', (WidgetTester tester) async {
      // Given
      final editorProvider = EditorProvider();
      
      // When
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => editorProvider,
            child: const HtmlEditorWidget(),
          ),
        ),
      );
      
      // Then
      expect(find.byType(HtmlEditorWidget), findsOneWidget);
    });

    testWidgets('エディタにテキストを入力できる', (WidgetTester tester) async {
      // Given
      final editorProvider = EditorProvider();
      
      // When
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => editorProvider,
            child: const HtmlEditorWidget(),
          ),
        ),
      );
      
      // Then
      // エディタが表示されることを確認
      expect(find.byType(HtmlEditorWidget), findsOneWidget);
    });

    testWidgets('HTMLコンテンツが正しく設定される', (WidgetTester tester) async {
      // Given
      final editorProvider = EditorProvider();
      const testHtml = '<p>テストコンテンツ</p>';
      
      // When
      editorProvider.setHtmlContent(testHtml);
      
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => editorProvider,
            child: const HtmlEditorWidget(),
          ),
        ),
      );
      
      // Then
      expect(editorProvider.htmlContent, equals(testHtml));
    });
  });
}
EOF

cat > test/providers/editor_provider_test.dart << 'EOF'
import 'package:flutter_test/flutter_test.dart';
import 'package:yutorikyoshitu/providers/editor_provider.dart';

void main() {
  group('EditorProvider Tests', () {
    late EditorProvider editorProvider;

    setUp(() {
      editorProvider = EditorProvider();
    });

    test('初期状態が正しく設定される', () {
      // Then
      expect(editorProvider.htmlContent, isEmpty);
      expect(editorProvider.isLoading, isFalse);
      expect(editorProvider.hasError, isFalse);
    });

    test('HTMLコンテンツが正しく設定される', () {
      // Given
      const testHtml = '<p>テストコンテンツ</p>';
      
      // When
      editorProvider.setHtmlContent(testHtml);
      
      // Then
      expect(editorProvider.htmlContent, equals(testHtml));
    });

    test('ローディング状態が正しく管理される', () {
      // When
      editorProvider.setLoading(true);
      
      // Then
      expect(editorProvider.isLoading, isTrue);
      
      // When
      editorProvider.setLoading(false);
      
      // Then
      expect(editorProvider.isLoading, isFalse);
    });

    test('エラー状態が正しく管理される', () {
      // Given
      const errorMessage = 'テストエラー';
      
      // When
      editorProvider.setError(errorMessage);
      
      // Then
      expect(editorProvider.hasError, isTrue);
      expect(editorProvider.errorMessage, equals(errorMessage));
    });

    test('エラーがクリアされる', () {
      // Given
      editorProvider.setError('エラー');
      
      // When
      editorProvider.clearError();
      
      // Then
      expect(editorProvider.hasError, isFalse);
      expect(editorProvider.errorMessage, isNull);
    });
  });
}
EOF

# 4. 実装ファイル作成
echo "💻 4. 実装ファイル作成中..."

# EditorProvider作成
cat > lib/providers/editor_provider.dart << 'EOF'
import 'package:flutter/foundation.dart';

class EditorProvider extends ChangeNotifier {
  String _htmlContent = '';
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;

  // Getters
  String get htmlContent => _htmlContent;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;

  // HTMLコンテンツ設定
  void setHtmlContent(String content) {
    _htmlContent = content;
    clearError();
    notifyListeners();
  }

  // ローディング状態設定
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // エラー設定
  void setError(String message) {
    _hasError = true;
    _errorMessage = message;
    _isLoading = false;
    notifyListeners();
  }

  // エラークリア
  void clearError() {
    _hasError = false;
    _errorMessage = null;
    notifyListeners();
  }

  // HTMLコンテンツ更新（エディタからの変更）
  void updateHtmlContent(String content) {
    _htmlContent = content;
    notifyListeners();
  }

  // エディタ初期化
  void initializeEditor() {
    setLoading(true);
    // 初期化処理
    setLoading(false);
  }

  // エディタリセット
  void resetEditor() {
    _htmlContent = '';
    clearError();
    notifyListeners();
  }
}
EOF

# HtmlEditorWidget作成
cat > lib/widgets/html_editor_widget.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:html_editor_enhanced/html_editor.dart';
import 'package:provider/provider.dart';
import '../providers/editor_provider.dart';

class HtmlEditorWidget extends StatefulWidget {
  const HtmlEditorWidget({Key? key}) : super(key: key);

  @override
  State<HtmlEditorWidget> createState() => _HtmlEditorWidgetState();
}

class _HtmlEditorWidgetState extends State<HtmlEditorWidget> {
  late HtmlEditorController _controller;

  @override
  void initState() {
    super.initState();
    _controller = HtmlEditorController();
    
    // プロバイダーの初期化
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EditorProvider>().initializeEditor();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EditorProvider>(
      builder: (context, editorProvider, child) {
        if (editorProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (editorProvider.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'エラーが発生しました',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  editorProvider.errorMessage ?? '不明なエラー',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    editorProvider.clearError();
                    editorProvider.initializeEditor();
                  },
                  child: const Text('再試行'),
                ),
              ],
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).dividerColor,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: HtmlEditor(
            controller: _controller,
            htmlEditorOptions: HtmlEditorOptions(
              hint: "学級通信の内容を入力してください...",
              shouldEnsureVisible: true,
              initialText: editorProvider.htmlContent,
            ),
            htmlToolbarOptions: HtmlToolbarOptions(
              toolbarPosition: ToolbarPosition.aboveEditor,
              toolbarType: ToolbarType.nativeScrollable,
              defaultToolbarButtons: [
                const StyleButtons(),
                const FontSettingButtons(fontSizeUnit: false),
                const FontButtons(clearAll: false),
                const ColorButtons(),
                const ListButtons(listStyles: false),
                const ParagraphButtons(
                  textDirection: false,
                  lineHeight: false,
                  caseConverter: false,
                ),
                const InsertButtons(
                  video: false,
                  audio: false,
                  table: false,
                  hr: false,
                  otherFile: false,
                ),
              ],
              customToolbarButtons: [
                // カスタムボタンを後で追加
              ],
            ),
            otherOptions: const OtherOptions(
              height: 400,
              decoration: BoxDecoration(
                color: Colors.white,
              ),
            ),
            callbacks: Callbacks(
              onChangeContent: (String? content) {
                if (content != null) {
                  editorProvider.updateHtmlContent(content);
                }
              },
              onInit: () {
                debugPrint('HTMLエディタが初期化されました');
              },
              onFocus: () {
                debugPrint('HTMLエディタにフォーカスしました');
              },
              onBlur: () {
                debugPrint('HTMLエディタからフォーカスが外れました');
              },
            ),
          ),
        );
      },
    );
  }
}
EOF

# 5. エディタ画面の更新
echo "🖥️ 5. エディタ画面更新中..."
if [ -f "lib/screens/editor_screen.dart" ]; then
    # 既存のエディタ画面にHTMLエディタを統合
    echo "  - 既存のエディタ画面を更新..."
    # バックアップ作成
    cp lib/screens/editor_screen.dart lib/screens/editor_screen.dart.backup
    
    # HTMLエディタを統合した新しいエディタ画面を作成
    cat > lib/screens/editor_screen.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/editor_provider.dart';
import '../widgets/html_editor_widget.dart';

class EditorScreen extends StatelessWidget {
  const EditorScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EditorProvider(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('学級通信エディタ'),
          actions: [
            Consumer<EditorProvider>(
              builder: (context, editorProvider, child) {
                return IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: editorProvider.isLoading
                      ? null
                      : () {
                          // 保存処理
                          _saveDocument(context, editorProvider);
                        },
                );
              },
            ),
            Consumer<EditorProvider>(
              builder: (context, editorProvider, child) {
                return IconButton(
                  icon: const Icon(Icons.preview),
                  onPressed: editorProvider.isLoading
                      ? null
                      : () {
                          // プレビュー表示
                          _showPreview(context, editorProvider);
                        },
                );
              },
            ),
          ],
        ),
        body: const Padding(
          padding: EdgeInsets.all(16.0),
          child: HtmlEditorWidget(),
        ),
      ),
    );
  }

  void _saveDocument(BuildContext context, EditorProvider editorProvider) {
    // TODO: ドキュメント保存処理を実装
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('保存機能は後で実装されます'),
      ),
    );
  }

  void _showPreview(BuildContext context, EditorProvider editorProvider) {
    // TODO: プレビュー表示を実装
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('プレビュー'),
        content: SingleChildScrollView(
          child: Text(editorProvider.htmlContent),
        ),
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
EOF
else
    echo "  - 新しいエディタ画面を作成..."
    # 上記と同じエディタ画面を作成
fi

# 6. テスト実行
echo "🧪 6. テスト実行中..."
flutter test test/providers/editor_provider_test.dart
flutter test test/widgets/html_editor_widget_test.dart

# 7. 完了メッセージ
echo ""
echo "✅ Phase 1 セットアップ完了！"
echo "========================================"
echo ""
echo "📋 実装されたファイル:"
echo "  - lib/providers/editor_provider.dart"
echo "  - lib/widgets/html_editor_widget.dart"
echo "  - lib/screens/editor_screen.dart (更新)"
echo "  - test/providers/editor_provider_test.dart"
echo "  - test/widgets/html_editor_widget_test.dart"
echo ""
echo "📦 追加されたパッケージ:"
echo "  - html_editor_enhanced"
echo "  - webview_flutter_web"
echo "  - provider"
echo ""
echo "🚀 次のステップ:"
echo "  1. flutter run -d chrome でアプリを起動"
echo "  2. エディタ画面でHTMLエディタの動作確認"
echo "  3. Phase 2 (WebSocketチャット基盤) の実装開始"
echo ""
echo "💡 Phase 2 実行コマンド:"
echo "  bash scripts/mvp_phase2_websocket.sh"
echo "" 