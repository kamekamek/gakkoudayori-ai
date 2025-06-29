# 📚 Google Classroom連携・画像アップロード機能仕様

## 🎯 概要

学校だよりAIにGoogle Classroom投稿機能と画像アップロード機能を統合し、学級通信の作成から配信までを一元化するシステムを設計します。

## 📱 UI設計

### 1. プレビュー画面の拡張（ボタン追加）

#### デスクトップ版
```
┌─────────────────────────────────────────────────────────────┐
│ 🏫 学校だよりAI                               [⚙️] [❓]     │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│ ┌─────────────────────────┬─────────────────────────────┐   │
│ │     💬 AI アシスタント   │        📄 プレビュー         │   │
│ ├─────────────────────────┼─────────────────────────────┤   │
│ │                         │ [編集] [印刷] [PDF] [📚] [🔄] │   │
│ │ 🤖 写真も追加しますか？ │  ┌─────────────────────────┐ │   │
│ │    ・運動会の写真       │  │                         │ │   │
│ │    ・子どもたちの様子   │  │ 〇〇小学校 1年1組       │ │   │
│ │    ・表彰の瞬間         │  │ ─────────────────────── │ │   │
│ │                         │  │                         │ │   │
│ │ 👨‍🏫 [📷] 運動会の写真を  │  │ 🏃‍♂️ 運動会頑張りました  │ │   │
│ │    3枚アップロードします │  │                         │ │   │
│ │                         │  │ 今日は素晴らしい運動会  │ │   │
│ │ 🤖 素敵ですね！         │  │ でした。               │ │   │
│ │    レイアウトを調整して │  │                         │ │   │
│ │    Classroomに投稿      │  │ ┌─────────────────────┐ │ │   │
│ │    しますか？           │  │ │ [アップロード画像]  │ │ │   │
│ │                         │  │ │   運動会の様子      │ │ │   │
│ │ ┌─────────────────────┐ │  │ └─────────────────────┘ │ │   │
│ │ │ メッセージを入力... │ │  │                         │ │   │
│ │ └─────────────────────┘ │  │ 保護者の皆様も...       │ │   │
│ │      [🎤] [📷] [送信]   │  └─────────────────────────┘ │   │
│ └─────────────────────────┴─────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```
**新しいボタン**: `[📚]` = Classroom投稿、`[📷]` = 画像アップロード

#### モバイル版
```
┌─────────────────────────┐
│ 🏫 学校だよりAI    [⚙️] │
├─────────────────────────┤
│ [💬チャット] [📄プレビュー] │
├─────────────────────────┤
│ [編集] [📚] [PDF] [🔄]   │
├─────────────────────────┤
│                         │
│ ┌─────────────────────┐ │
│ │  A4学級通信プレビュー │ │
│ │                     │ │
│ │ 〇〇小学校 1年1組   │ │
│ │ ─────────────────── │ │
│ │                     │ │
│ │ 🏃‍♂️ 運動会頑張りました │ │
│ │                     │ │
│ │ ┌─────────────────┐ │ │
│ │ │ [📷 アップロード]  │ │ │
│ │ │   画像エリア       │ │ │
│ │ └─────────────────┘ │ │
│ │                     │ │
│ │ 今日は素晴らしい... │ │
│ │                     │ │
│ └─────────────────────┘ │
│                         │
└─────────────────────────┘
```

### 2. 画像アップロード画面

```
┌─────────────────────────────────────────────────────────────┐
│ ← 戻る  📷 画像アップロード                                  │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │                 📷 画像を追加                        │    │
│  │                                                     │    │
│  │     ┌─────────────────┐    ┌─────────────────┐      │    │
│  │     │   📁 ファイル    │    │   📱 カメラ     │      │    │
│  │     │   から選択      │    │   で撮影       │      │    │
│  │     │                 │    │                 │      │    │
│  │     │ [ファイル選択]   │    │ [カメラ起動]    │      │    │
│  │     └─────────────────┘    └─────────────────┘      │    │
│  │                                                     │    │
│  │     ┌─────────────────┐    ┌─────────────────┐      │    │
│  │     │  🌐 URL から     │    │  🎨 AI画像生成  │      │    │
│  │     │   取得          │    │   (将来機能)    │      │    │
│  │     │                 │    │                 │      │    │
│  │     │ [URL入力]       │    │ [生成依頼]      │      │    │
│  │     └─────────────────┘    └─────────────────┘      │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │                アップロード済み画像                 │    │
│  │                                                     │    │
│  │  ┌───────────────┬───────────────┬───────────────┐  │    │
│  │  │   画像1       │   画像2       │   画像3       │  │    │
│  │  │ ┌───────────┐ │ ┌───────────┐ │ ┌───────────┐ │  │    │
│  │  │ │[サムネイル]│ │ │[サムネイル]│ │ │[サムネイル]│ │  │    │
│  │  │ └───────────┘ │ └───────────┘ │ └───────────┘ │  │    │
│  │  │ [編集] [削除] │ │ [編集] [削除] │ │ [編集] [削除] │  │    │
│  │  └───────────────┴───────────────┴───────────────┘  │    │
│  │                                                     │    │
│  │             [🎨 レイアウトを調整] [✅ 完了]          │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 3. Google Classroom投稿画面

```
┌─────────────────────────────────────────────────────────────┐
│ ← 戻る  📚 Google Classroom に投稿                           │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │                 🔗 Classroom連携                    │    │
│  │                                                     │    │
│  │  アカウント: teacher@example.school.jp  [変更]      │    │
│  │  状態: ✅ 認証済み                                   │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │                 📝 投稿設定                          │    │
│  │                                                     │    │
│  │  投稿先クラス: [1年1組 ▼]                           │    │
│  │                                                     │    │
│  │  タイトル: [運動会の学級通信                   ]     │    │
│  │                                                     │    │
│  │  説明文:                                            │    │
│  │  ┌─────────────────────────────────────────────┐    │    │
│  │  │今日の運動会の様子をお伝えします。            │    │    │
│  │  │子どもたちの頑張りをぜひご覧ください。        │    │    │
│  │  │                                                 │    │    │
│  │  └─────────────────────────────────────────────┘    │    │
│  │                                                     │    │
│  │  添付ファイル:                                      │    │
│  │  ✅ 学級通信PDF (GakkyuTsuushin_20240622.pdf)       │    │
│  │  ✅ 画像3枚 (運動会の写真)                          │    │
│  │                                                     │    │
│  │  投稿設定:                                          │    │
│  │  ◯ すぐに投稿  ◯ 予約投稿 [2024/06/22 17:00 ▼]    │    │
│  │  ☑️ 保護者にメール通知                              │    │
│  │  ☑️ 学級通信アーカイブに保存                        │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │                 📋 プレビュー                        │    │
│  │                                                     │    │
│  │  Classroomでの表示プレビュー:                       │    │
│  │  ┌─────────────────────────────────────────────┐    │    │
│  │  │ 📚 運動会の学級通信                          │    │    │
│  │  │ 投稿者: 田中先生  2024/06/22 17:00          │    │    │
│  │  │                                             │    │    │
│  │  │ 今日の運動会の様子をお伝えします。          │    │    │
│  │  │ 子どもたちの頑張りをぜひご覧ください。      │    │    │
│  │  │                                             │    │    │
│  │  │ 📎 GakkyuTsuushin_20240622.pdf             │    │    │
│  │  │ 📷 運動会写真 (3枚)                        │    │    │
│  │  └─────────────────────────────────────────────┘    │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│              [📋 下書き保存] [📚 Classroomに投稿]           │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## 🔧 技術仕様

### 1. 画像アップロード機能

#### 対応ファイル形式
```dart
static const List<String> supportedImageTypes = [
  'image/jpeg',
  'image/png', 
  'image/gif',
  'image/webp',
  'image/svg+xml'
];

static const int maxFileSize = 10 * 1024 * 1024; // 10MB
static const int maxImageCount = 10; // 最大10枚
```

#### 推奨ライブラリ
```yaml
dependencies:
  # ファイルアップロード
  file_picker: ^8.0.0+1          # マルチプラットフォーム対応
  image_picker: ^1.0.7           # カメラ・ギャラリー選択
  
  # 画像処理・最適化
  image: ^4.1.7                  # 画像リサイズ・圧縮
  flutter_image_compress: ^2.2.0 # 高度な圧縮
  
  # ドラッグ&ドロップ
  desktop_drop: ^0.4.4           # デスクトップでのD&D
  flutter_dropzone: ^4.0.1       # Web版D&D
  
  # プログレス表示
  percent_indicator: ^4.2.3      # アップロード進捗
```

#### 実装例
```dart
class ImageUploadService {
  static Future<List<ImageFile>> pickImages() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp'],
    );
    
    if (result != null) {
      return result.files.map((file) => ImageFile(
        name: file.name,
        bytes: file.bytes!,
        size: file.size,
      )).toList();
    }
    
    return [];
  }
  
  static Future<ImageFile> takePhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    
    if (image != null) {
      final bytes = await image.readAsBytes();
      return ImageFile(
        name: image.name,
        bytes: bytes,
        size: bytes.length,
      );
    }
    
    throw Exception('写真の撮影をキャンセルしました');
  }
  
  static Future<String> compressAndUpload(ImageFile image) async {
    // 画像圧縮
    final compressedBytes = await FlutterImageCompress.compressWithList(
      image.bytes,
      minWidth: 800,
      minHeight: 600,
      quality: 85,
    );
    
    // Cloud Storageにアップロード
    final ref = FirebaseStorage.instance
        .ref()
        .child('newsletters/${DateTime.now().millisecondsSinceEpoch}');
    
    final uploadTask = ref.putData(compressedBytes);
    final snapshot = await uploadTask;
    
    return await snapshot.ref.getDownloadURL();
  }
}
```

### 2. Google Classroom連携

#### 必要なAPI
```yaml
dependencies:
  # Google APIs
  googleapis: ^13.1.0
  googleapis_auth: ^1.6.0
  
  # OAuth認証
  google_sign_in: ^6.2.1
  
  # HTTPクライアント
  http: ^1.2.1
```

#### スコープ設定
```dart
static const List<String> classroomScopes = [
  'https://www.googleapis.com/auth/classroom.courses.readonly',
  'https://www.googleapis.com/auth/classroom.coursework.students',
  'https://www.googleapis.com/auth/classroom.announcements',
  'https://www.googleapis.com/auth/drive.file', // ファイルアップロード用
];
```

#### 実装例
```dart
class ClassroomService {
  late ClassroomApi _classroomApi;
  late DriveApi _driveApi;
  
  Future<void> authenticate() async {
    final googleSignIn = GoogleSignIn(scopes: classroomScopes);
    final account = await googleSignIn.signIn();
    
    if (account != null) {
      final headers = await account.authHeaders;
      final client = authenticatedClient(http.Client(), 
          AccessCredentials.fromJson(headers));
      
      _classroomApi = ClassroomApi(client);
      _driveApi = DriveApi(client);
    }
  }
  
  Future<List<Course>> getCourses() async {
    final response = await _classroomApi.courses.list();
    return response.courses ?? [];
  }
  
  Future<String> uploadPdfToDrive(Uint8List pdfBytes, String fileName) async {
    final media = Media(Stream.fromIterable([pdfBytes]), pdfBytes.length);
    final file = File()
      ..name = fileName
      ..parents = ['classroom_attachments']; // フォルダー指定
    
    final createdFile = await _driveApi.files.create(file, uploadMedia: media);
    return createdFile.id!;
  }
  
  Future<void> createAnnouncement({
    required String courseId,
    required String title,
    required String description,
    required List<String> attachmentIds,
    DateTime? scheduledTime,
  }) async {
    final announcement = Announcement()
      ..text = description
      ..materials = attachmentIds.map((id) => Material()
        ..driveFile = (DriveFile()..driveFile = (File()..id = id))
      ).toList();
    
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

### 3. 状態管理

```dart
class ContentProvider extends ChangeNotifier {
  List<ImageFile> _uploadedImages = [];
  ClassroomSettings? _classroomSettings;
  bool _isUploadingToClassroom = false;
  
  List<ImageFile> get uploadedImages => _uploadedImages;
  ClassroomSettings? get classroomSettings => _classroomSettings;
  bool get isUploadingToClassroom => _isUploadingToClassroom;
  
  Future<void> addImages(List<ImageFile> images) async {
    for (final image in images) {
      if (_uploadedImages.length < 10) { // 最大10枚制限
        final compressedUrl = await ImageUploadService.compressAndUpload(image);
        _uploadedImages.add(image.copyWith(url: compressedUrl));
      }
    }
    notifyListeners();
  }
  
  void removeImage(int index) {
    _uploadedImages.removeAt(index);
    notifyListeners();
  }
  
  Future<void> postToClassroom({
    required String courseId,
    required String title,
    required String description,
    required Uint8List pdfBytes,
    DateTime? scheduledTime,
  }) async {
    _isUploadingToClassroom = true;
    notifyListeners();
    
    try {
      final classroomService = ClassroomService();
      await classroomService.authenticate();
      
      // PDFをDriveにアップロード
      final pdfId = await classroomService.uploadPdfToDrive(
        pdfBytes, 
        '${title}_${DateTime.now().millisecondsSinceEpoch}.pdf'
      );
      
      // 画像をDriveにアップロード
      final imageIds = <String>[];
      for (final image in _uploadedImages) {
        final imageId = await classroomService.uploadPdfToDrive(
          image.bytes, 
          image.name
        );
        imageIds.add(imageId);
      }
      
      // Classroomに投稿
      await classroomService.createAnnouncement(
        courseId: courseId,
        title: title,
        description: description,
        attachmentIds: [pdfId, ...imageIds],
        scheduledTime: scheduledTime,
      );
      
    } finally {
      _isUploadingToClassroom = false;
      notifyListeners();
    }
  }
}

class ClassroomSettings {
  final String courseId;
  final String courseName;
  final bool enableEmailNotification;
  final bool saveToArchive;
  
  ClassroomSettings({
    required this.courseId,
    required this.courseName,
    this.enableEmailNotification = true,
    this.saveToArchive = true,
  });
}
```

## 🎨 UIコンポーネント

### 画像アップロードウィジェット
```dart
class ImageUploadWidget extends StatelessWidget {
  final List<ImageFile> images;
  final Function(List<ImageFile>) onImagesAdded;
  final Function(int) onImageRemoved;
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // アップロードボタン群
        Row(
          children: [
            UploadButton(
              icon: Icons.folder,
              label: 'ファイル選択',
              onPressed: () async {
                final images = await ImageUploadService.pickImages();
                onImagesAdded(images);
              },
            ),
            UploadButton(
              icon: Icons.camera_alt,
              label: 'カメラ撮影',
              onPressed: () async {
                final image = await ImageUploadService.takePhoto();
                onImagesAdded([image]);
              },
            ),
          ],
        ),
        
        // アップロード済み画像一覧
        if (images.isNotEmpty)
          ImageGrid(
            images: images,
            onImageRemoved: onImageRemoved,
          ),
      ],
    );
  }
}
```

### Classroom投稿ウィジェット
```dart
class ClassroomPostWidget extends StatefulWidget {
  final Uint8List pdfBytes;
  final List<ImageFile> images;
  
  @override
  _ClassroomPostWidgetState createState() => _ClassroomPostWidgetState();
}

class _ClassroomPostWidgetState extends State<ClassroomPostWidget> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedCourseId;
  DateTime? _scheduledTime;
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Classroom認証状態
        ClassroomAuthCard(),
        
        // 投稿設定フォーム
        ClassroomPostForm(
          titleController: _titleController,
          descriptionController: _descriptionController,
          onCourseSelected: (courseId) => _selectedCourseId = courseId,
          onScheduledTimeSet: (time) => _scheduledTime = time,
        ),
        
        // プレビュー
        ClassroomPostPreview(
          title: _titleController.text,
          description: _descriptionController.text,
          attachments: [widget.pdfBytes, ...widget.images],
        ),
        
        // 投稿ボタン
        ElevatedButton.icon(
          icon: Icon(Icons.send),
          label: Text('Classroomに投稿'),
          onPressed: _canPost ? _postToClassroom : null,
        ),
      ],
    );
  }
}
```

## 🚀 実装フェーズ

### Phase 1: 画像アップロード基本機能
- [ ] ファイル選択・カメラ撮影
- [ ] 画像圧縮・最適化
- [ ] Cloud Storage連携
- [ ] プレビュー表示

### Phase 2: Classroom連携基本機能
- [ ] Google OAuth認証
- [ ] コース一覧取得
- [ ] PDF・画像のDriveアップロード
- [ ] 基本的な投稿機能

### Phase 3: 高度な機能
- [ ] 予約投稿
- [ ] 画像編集（回転・クロップ）
- [ ] ドラッグ&ドロップ
- [ ] バッチアップロード

### Phase 4: UX改善
- [ ] プログレス表示
- [ ] エラーハンドリング
- [ ] オフライン対応
- [ ] アニメーション

## 🧪 テスト戦略

### 単体テスト
```dart
testWidgets('画像アップロード機能テスト', (tester) async {
  await tester.pumpWidget(MyApp());
  
  // ファイル選択ボタンをタップ
  await tester.tap(find.byIcon(Icons.folder));
  await tester.pump();
  
  // 画像が追加されたことを確認
  expect(find.byType(ImageGrid), findsOneWidget);
});
```

### 統合テスト
- 画像アップロード → プレビュー表示
- Classroom認証 → 投稿
- PDF生成 → Classroom投稿

### E2Eテスト
- 完全な学級通信作成フロー
- Classroomでの表示確認

この仕様により、学級通信の作成から配信まで、教師が一つのアプリで完結できる包括的なシステムが実現できます。