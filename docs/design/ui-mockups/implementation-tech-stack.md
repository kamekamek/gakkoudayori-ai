# 🛠️ 実装技術スタック まとめ

## 📱 Flutter Web実装技術選定

### 1. 画像アップロード・管理

#### ファイル操作
```yaml
dependencies:
  file_picker: ^8.0.0+1          # マルチプラットフォーム・複数選択対応
  image_picker: ^1.0.7           # カメラ・ギャラリー（モバイル）
  desktop_drop: ^0.4.4           # ドラッグ&ドロップ（デスクトップ）
  flutter_dropzone: ^4.0.1       # D&D（Web）
```

#### 画像処理・最適化
```yaml
dependencies:
  image: ^4.1.7                  # 基本的な画像処理・リサイズ
  flutter_image_compress: ^2.2.0 # 高度な圧縮・最適化
  cached_network_image: ^3.3.1   # ネットワーク画像キャッシュ
```

#### 実装パターン
```dart
class ImageUploadWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // マルチ入力方式
        Row(
          children: [
            _buildUploadButton(
              icon: Icons.folder,
              label: 'ファイル選択',
              onTap: () => _pickFromDevice(),
            ),
            _buildUploadButton(
              icon: Icons.camera_alt, 
              label: 'カメラ撮影',
              onTap: () => _captureFromCamera(),
            ),
            _buildUploadButton(
              icon: Icons.link,
              label: 'URL指定',
              onTap: () => _inputFromUrl(),
            ),
          ],
        ),
        
        // アップロード済み画像管理
        GridView.builder(
          itemCount: uploadedImages.length,
          itemBuilder: (context, index) => ImageTile(
            image: uploadedImages[index],
            onEdit: () => _editImage(index),
            onDelete: () => _deleteImage(index),
          ),
        ),
      ],
    );
  }
}
```

### 2. リッチテキストエディタ

#### 推奨：Quill.js統合
```yaml
dependencies:
  flutter_quill: ^9.4.4          # Flutter用Quillエディタ
  flutter_quill_extensions: ^0.6.0 # 画像・リンク等拡張
  quill_html_editor: ^2.2.8      # HTML変換・Web最適化
```

#### 実装パターン
```dart
class NewsletterEditor extends StatefulWidget {
  @override
  _NewsletterEditorState createState() => _NewsletterEditorState();
}

class _NewsletterEditorState extends State<NewsletterEditor> {
  late QuillController _controller;
  bool _isReadOnly = true; // プレビューモード
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // モード切り替えツールバー
        PreviewModeToolbar(
          currentMode: _isReadOnly ? PreviewMode.preview : PreviewMode.edit,
          onModeChanged: (mode) {
            setState(() {
              _isReadOnly = mode == PreviewMode.preview;
            });
          },
        ),
        
        // Quillエディタ
        Expanded(
          child: QuillEditor(
            controller: _controller,
            readOnly: _isReadOnly,
            configurations: QuillEditorConfigurations(
              customStyles: _getNewsletterStyles(),
              embedBuilders: _getCustomEmbeds(), // 画像・カスタム要素
            ),
          ),
        ),
      ],
    );
  }
}
```

### 3. PDF生成・印刷プレビュー

#### 推奨：printing + pdf パッケージ
```yaml
dependencies:
  printing: ^5.12.0              # 印刷プレビュー・PDF出力
  pdf: ^3.10.7                   # PDF文書作成・カスタマイズ
  universal_html: ^2.2.4         # HTML解析（Web）
```

#### 実装パターン
```dart
class PrintPreviewService {
  static Future<void> showPrintPreview(String htmlContent) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async {
        return await _generatePdfFromHtml(htmlContent, format);
      },
      name: '学級通信_${DateTime.now().toString()}',
      format: PdfPageFormat.a4, // A4固定
    );
  }
  
  static Future<Uint8List> _generatePdfFromHtml(
    String htmlContent, 
    PdfPageFormat format
  ) async {
    final pdf = pw.Document();
    
    // HTMLをPDFウィジェットに変換
    final widgets = await _convertHtmlToWidgets(htmlContent);
    
    pdf.addPage(pw.MultiPage(
      pageFormat: format,
      margin: pw.EdgeInsets.all(32),
      build: (context) => widgets,
    ));
    
    return pdf.save();
  }
}
```

### 4. Google Classroom連携

#### Google APIs
```yaml
dependencies:
  googleapis: ^13.1.0            # Google APIs クライアント
  googleapis_auth: ^1.6.0        # OAuth認証
  google_sign_in: ^6.2.1         # Googleサインイン
  firebase_auth: ^4.19.5         # Firebase認証と統合
```

#### 必要なスコープ
```dart
static const List<String> requiredScopes = [
  'https://www.googleapis.com/auth/classroom.courses.readonly',
  'https://www.googleapis.com/auth/classroom.announcements',
  'https://www.googleapis.com/auth/drive.file',
];
```

#### 実装パターン
```dart
class ClassroomService {
  late ClassroomApi _classroomApi;
  late DriveApi _driveApi;
  
  Future<void> authenticate() async {
    final googleSignIn = GoogleSignIn(scopes: requiredScopes);
    final account = await googleSignIn.signIn();
    
    final authHeaders = await account!.authHeaders;
    final client = _createAuthenticatedClient(authHeaders);
    
    _classroomApi = ClassroomApi(client);
    _driveApi = DriveApi(client);
  }
  
  Future<void> postNewsletter({
    required String courseId,
    required String title,
    required String description,
    required Uint8List pdfBytes,
    required List<String> imageUrls,
    DateTime? scheduledTime,
  }) async {
    // 1. PDFをGoogle Driveにアップロード
    final pdfDriveFile = await _uploadPdfToDrive(pdfBytes, title);
    
    // 2. Classroomアナウンスメント作成
    final announcement = Announcement()
      ..text = description
      ..materials = [
        _createDriveFileMaterial(pdfDriveFile.id!),
        ...imageUrls.map(_createLinkMaterial),
      ];
    
    if (scheduledTime != null) {
      announcement.scheduledTime = scheduledTime.toIso8601String();
    }
    
    await _classroomApi.courses.announcements.create(
      announcement, 
      courseId,
    );
  }
}
```

### 5. 状態管理

#### Provider パターン（推奨）
```yaml
dependencies:
  provider: ^6.1.2               # 軽量・Flutterチーム公式
  flutter_riverpod: ^2.4.10      # 代替案：より高機能
```

#### 実装パターン
```dart
// メイン状態管理
class NewsletterProvider extends ChangeNotifier {
  String _chatContent = '';
  List<ImageFile> _uploadedImages = [];
  String _generatedHtml = '';
  PreviewMode _currentMode = PreviewMode.preview;
  
  // Getters
  String get chatContent => _chatContent;
  List<ImageFile> get uploadedImages => _uploadedImages;
  String get generatedHtml => _generatedHtml;
  PreviewMode get currentMode => _currentMode;
  
  // Actions
  void updateChatContent(String content) {
    _chatContent = content;
    notifyListeners();
  }
  
  Future<void> addImages(List<ImageFile> images) async {
    _uploadedImages.addAll(images);
    notifyListeners();
    
    // 自動的にHTMLを再生成
    await _regenerateHtmlWithImages();
  }
  
  void switchPreviewMode(PreviewMode mode) {
    _currentMode = mode;
    notifyListeners();
  }
  
  Future<void> postToClassroom(ClassroomPostSettings settings) async {
    final classroomService = ClassroomService();
    await classroomService.authenticate();
    
    await classroomService.postNewsletter(
      courseId: settings.courseId,
      title: settings.title,
      description: settings.description,
      pdfBytes: await _generatePdfBytes(),
      imageUrls: _uploadedImages.map((img) => img.url).toList(),
      scheduledTime: settings.scheduledTime,
    );
  }
}

// 使用方法
class NewsletterApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NewsletterProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => ImageProvider()),
      ],
      child: MaterialApp(
        home: NewsletterHomePage(),
      ),
    );
  }
}
```

### 6. レスポンシブデザイン

#### レイアウト管理
```yaml
dependencies:
  flutter_layout_grid: ^2.0.7    # CSS Gridライクなレイアウト
  responsive_framework: ^1.4.0    # レスポンシブヘルパー
```

#### 実装パターン
```dart
class ResponsiveNewsletterLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 768) {
          // モバイル：タブ切り替え
          return TabBarView(
            children: [
              ChatInterface(),
              PreviewInterface(),
            ],
          );
        } else {
          // デスクトップ：左右分割
          return Row(
            children: [
              Expanded(flex: 1, child: ChatInterface()),
              Expanded(flex: 1, child: PreviewInterface()),
            ],
          );
        }
      },
    );
  }
}
```

## 🎨 UIコンポーネント設計

### 1. チャットインターフェース
```dart
class ChatInterface extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // チャット履歴
        Expanded(
          child: ChatMessageList(),
        ),
        
        // 入力エリア
        ChatInputArea(
          supportVoice: true,
          supportImage: true,
          onMessageSent: (message) {
            context.read<ChatProvider>().sendMessage(message);
          },
        ),
      ],
    );
  }
}
```

### 2. プレビューインターフェース
```dart
class PreviewInterface extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // モード切り替えツールバー
        PreviewModeToolbar(),
        
        // プレビューコンテンツ
        Expanded(
          child: Consumer<NewsletterProvider>(
            builder: (context, provider, _) {
              switch (provider.currentMode) {
                case PreviewMode.preview:
                  return ReadOnlyPreview();
                case PreviewMode.edit:
                  return EditablePreview();
                case PreviewMode.printView:
                  return PrintViewPreview();
                default:
                  return ReadOnlyPreview();
              }
            },
          ),
        ),
      ],
    );
  }
}
```

## 🧪 テスト戦略

### 単体テスト
```dart
// Widget テスト
testWidgets('画像アップロード機能テスト', (tester) async {
  await tester.pumpWidget(
    MaterialApp(home: ImageUploadWidget()),
  );
  
  // ファイル選択ボタンをタップ
  await tester.tap(find.byIcon(Icons.folder));
  await tester.pump();
  
  // アップロード画面が表示されることを確認
  expect(find.byType(FilePickerDialog), findsOneWidget);
});

// Provider テスト
test('チャット内容更新テスト', () {
  final provider = NewsletterProvider();
  
  provider.updateChatContent('テスト内容');
  
  expect(provider.chatContent, equals('テスト内容'));
});
```

### 統合テスト
```dart
// integration_test/app_test.dart
void main() {
  group('学級通信作成フロー', () {
    testWidgets('チャット→プレビュー→PDF出力', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      
      // チャットでメッセージ送信
      await tester.enterText(find.byType(TextField), '運動会について');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();
      
      // プレビューが生成されることを確認
      expect(find.byType(PreviewWidget), findsOneWidget);
      
      // PDF出力ボタンをタップ
      await tester.tap(find.byIcon(Icons.picture_as_pdf));
      await tester.pumpAndSettle();
      
      // PDF生成が完了することを確認
      expect(find.text('PDF生成完了'), findsOneWidget);
    });
  });
}
```

## 🚀 パフォーマンス最適化

### 1. 画像最適化
```dart
class ImageOptimizer {
  static Future<Uint8List> optimizeForWeb(Uint8List imageBytes) async {
    return await FlutterImageCompress.compressWithList(
      imageBytes,
      minWidth: 800,
      minHeight: 600,
      quality: 85,
      format: CompressFormat.webp, // Web最適化
    );
  }
}
```

### 2. 遅延読み込み
```dart
class LazyLoadImageGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: images.length,
      itemBuilder: (context, index) {
        return Visibility(
          visible: _isVisible(index),
          child: CachedNetworkImage(
            imageUrl: images[index].url,
            placeholder: (context, url) => ShimmerPlaceholder(),
          ),
        );
      },
    );
  }
}
```

この技術スタックにより、教育現場で実用的な学校だよりAIアプリケーションを効率的に開発できます。