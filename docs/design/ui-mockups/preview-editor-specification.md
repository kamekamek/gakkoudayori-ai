# 📄 プレビュー・編集機能 詳細仕様

## 🎯 概要

学校だよりAIのプレビュー機能を拡張し、印刷ビュー・編集機能・PDF出力を統合した包括的なプレビューシステムを設計します。

## 📱 UI配置設計

### デスクトップ版レイアウト
```
┌─────────────────────────┬─────────────────────────────────┐
│     💬 AIチャット        │        📄 プレビュー            │
│                         │  ┌─────────────────────────────┐ │
│ 🤖 どんな学級通信を     │  │ [編集] [印刷ビュー] [PDF] [🔄] │ │
│    作りますか？         │  └─────────────────────────────┘ │
│                         │                                 │
│ 👨‍🏫 運動会について      │  ┌─────────────────────────────┐ │
│    書きたいです         │  │                             │ │
│                         │  │    〇〇小学校 1年1組        │ │
│ 🤖 どんな様子を         │  │    ─────────────────────    │ │
│    伝えたいですか？     │  │                             │ │
│                         │  │  🏃‍♂️ 運動会頑張りました     │ │
│ ┌─────────────────────┐ │  │                             │ │
│ │ メッセージを入力... │ │  │  今日は素晴らしい運動会で   │ │
│ └─────────────────────┘ │  │  した。子どもたちが一生懸   │ │
│      [🎤] [送信]        │  │  命に頑張る姿を見て、とて   │ │
│                         │  │  も感動しました。           │ │
│                         │  │                             │ │
│                         │  │  [編集可能エリア]           │ │
│                         │  │                             │ │
│                         │  └─────────────────────────────┘ │
└─────────────────────────┴─────────────────────────────────┘
```

### モバイル版レイアウト

#### プレビュータブ（修正版）
```
┌─────────────────────────┐
│ 🏫 学校だよりAI    [⚙️] │
├─────────────────────────┤
│ [💬チャット] [📄プレビュー] │
├─────────────────────────┤
│ [編集] [印刷ビュー] [PDF] [🔄] │
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
│ │ 今日は素晴らしい運動│ │
│ │ 会でした。子どもたち│ │
│ │ が一生懸命に頑張る姿│ │
│ │ を見て、とても感動し│ │
│ │ ました。            │ │
│ │                     │ │
│ │ [編集可能エリア]    │ │
│ │                     │ │
│ └─────────────────────┘ │
│                         │
└─────────────────────────┘
```

## 🔧 機能仕様

### 1. プレビューモード（デフォルト）
- **目的**: AI生成された学級通信の確認
- **表示**: A4サイズ比率でのレイアウト表示
- **操作**: 読み取り専用、スクロール可能
- **用途**: 生成内容の確認・検討

### 2. 編集モード
- **目的**: AI生成内容の手動調整・修正
- **表示**: インライン編集可能な状態
- **操作**: テキスト編集、フォーマット調整
- **用途**: 細かな修正・カスタマイズ

### 3. 印刷ビューモード
- **目的**: 実際の印刷時の見た目確認
- **表示**: 全画面表示、実寸A4レイアウト
- **操作**: ズーム・パン、印刷プレビュー
- **用途**: 印刷前の最終確認

### 4. PDF出力機能
- **目的**: 配布用ファイル生成
- **操作**: ワンクリックでPDF生成・ダウンロード
- **設定**: A4サイズ、高品質出力
- **用途**: 保護者配布・アーカイブ

## 📚 技術選定・ライブラリ調査

### 1. リッチテキストエディタ

#### 🥇 推奨: Quill.js + Flutter Web統合
```dart
// 既存の実装を活用・拡張
dependencies:
  flutter_quill: ^9.4.4  # Flutter用Quillライブラリ
  flutter_quill_extensions: ^0.6.0  # 拡張機能
```

**メリット**:
- ✅ 既存コードベースと互換性
- ✅ カスタマイズ性が高い
- ✅ 印刷向けHTML出力に最適
- ✅ プラグイン豊富

**実装例**:
```dart
QuillEditor(
  controller: _controller,
  readOnly: false, // 編集モード切り替え
  configurations: QuillEditorConfigurations(
    customStyles: DefaultStyles(
      // 学級通信向けスタイル設定
    ),
  ),
)
```

#### 🥈 代替案: flutter_html_editor
```dart
dependencies:
  flutter_html_editor: ^2.2.0
```

**メリット**:
- ✅ シンプルな実装
- ✅ HTMLベース
- ❌ カスタマイズ制限

### 2. 印刷プレビュー・PDF生成

#### 🥇 推奨: printing パッケージ
```dart
dependencies:
  printing: ^5.12.0  # PDF生成・印刷プレビュー
  pdf: ^3.10.7       # PDF文書作成
```

**機能**:
- ✅ 印刷プレビュー全画面表示
- ✅ PDF生成・ダウンロード
- ✅ A4サイズ対応
- ✅ 高品質レンダリング

**実装例**:
```dart
// 印刷プレビュー表示
await Printing.layoutPdf(
  onLayout: (PdfPageFormat format) async {
    return await generatePdf(htmlContent);
  },
);

// PDF保存・ダウンロード
final pdf = await generatePdf(htmlContent);
await Printing.sharePdf(
  bytes: pdf,
  filename: '学級通信_${DateTime.now().toString()}.pdf',
);
```

#### 🥈 代替案: 既存の html_to_pdf サービス
- バックエンドAPI経由でPDF生成
- 現在の実装を継続使用

### 3. レスポンシブ・レイアウト管理

#### 🥇 推奨: flutter_layout_grid
```dart
dependencies:
  flutter_layout_grid: ^2.0.7
```

**メリット**:
- ✅ CSS Grid ライクなレイアウト
- ✅ レスポンシブ対応
- ✅ 複雑なレイアウト管理

#### 🥈 代替案: 標準 Flex + MediaQuery
```dart
// 既存のレスポンシブ実装を活用
LayoutBuilder(
  builder: (context, constraints) {
    if (constraints.maxWidth < 768) {
      return MobileLayout();
    } else {
      return DesktopLayout();
    }
  },
)
```

### 4. 状態管理

#### 🥇 推奨: Provider + ChangeNotifier
```dart
class PreviewProvider extends ChangeNotifier {
  PreviewMode _mode = PreviewMode.preview;
  String _htmlContent = '';
  bool _isEditing = false;
  
  void switchMode(PreviewMode mode) {
    _mode = mode;
    notifyListeners();
  }
  
  void updateContent(String content) {
    _htmlContent = content;
    notifyListeners();
  }
}

enum PreviewMode {
  preview,    // プレビューモード
  edit,       // 編集モード
  printView,  // 印刷ビューモード
}
```

## 🎨 UI/UX設計詳細

### モード切り替えボタン
```dart
Row(
  children: [
    IconButton(
      icon: Icon(Icons.preview),
      label: Text('プレビュー'),
      onPressed: () => provider.switchMode(PreviewMode.preview),
      selected: provider.mode == PreviewMode.preview,
    ),
    IconButton(
      icon: Icon(Icons.edit),
      label: Text('編集'),
      onPressed: () => provider.switchMode(PreviewMode.edit),
      selected: provider.mode == PreviewMode.edit,
    ),
    IconButton(
      icon: Icon(Icons.print),
      label: Text('印刷ビュー'),
      onPressed: () => provider.switchMode(PreviewMode.printView),
    ),
    IconButton(
      icon: Icon(Icons.picture_as_pdf),
      label: Text('PDF'),
      onPressed: () => generateAndDownloadPdf(),
    ),
    IconButton(
      icon: Icon(Icons.refresh),
      label: Text('再生成'),
      onPressed: () => regenerateContent(),
    ),
  ],
)
```

### 編集モード機能
1. **インライン編集**: テキストの直接編集
2. **フォーマット**: 太字・斜体・下線
3. **レイアウト調整**: 段落・リスト・配置
4. **画像挿入**: 写真・イラスト追加
5. **スタイル変更**: フォント・色・サイズ

### 印刷ビューモード機能
1. **全画面表示**: 印刷時の実際のレイアウト
2. **ズーム機能**: 拡大・縮小で詳細確認
3. **余白表示**: 印刷時の余白確認
4. **改ページ表示**: 複数ページの場合のページ区切り

## 🚀 実装フェーズ

### Phase 1: 基本プレビュー機能
- [ ] モード切り替えUI実装
- [ ] プレビューモード（読み取り専用）
- [ ] PDF出力機能（既存API活用）

### Phase 2: 編集機能
- [ ] Quill.js統合
- [ ] インライン編集機能
- [ ] 基本フォーマット機能

### Phase 3: 印刷ビュー
- [ ] printing パッケージ統合
- [ ] 全画面印刷プレビュー
- [ ] ズーム・パン機能

### Phase 4: 高度な編集機能
- [ ] 画像挿入・編集
- [ ] レイアウトカスタマイズ
- [ ] テンプレート機能

## 🧪 テスト戦略

### 単体テスト
```dart
testWidgets('プレビューモード切り替えテスト', (WidgetTester tester) async {
  await tester.pumpWidget(MyApp());
  
  // プレビューモードから編集モードへ
  await tester.tap(find.byIcon(Icons.edit));
  await tester.pump();
  
  expect(find.byType(QuillEditor), findsOneWidget);
});
```

### 統合テスト
- チャットからプレビューまでの全フロー
- PDF生成・ダウンロード
- レスポンシブ動作

### E2Eテスト
- 実際の学級通信作成フロー
- 異なるデバイスでの動作確認

## 📊 パフォーマンス考慮事項

### 最適化ポイント
1. **遅延読み込み**: 大きなコンテンツの段階的読み込み
2. **キャッシュ**: 生成済みPDFのキャッシュ
3. **メモリ管理**: 大きなHTML/PDFファイルのメモリ効率
4. **レンダリング**: 60fps維持のためのウィジェット最適化

### メモリ使用量目標
- HTML編集時: 50MB以下
- PDF生成時: 100MB以下
- 同時プレビュー: 30MB以下

この仕様により、教師が直感的に学級通信を編集・確認・出力できる包括的なプレビューシステムが実現できます。