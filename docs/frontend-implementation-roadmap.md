# 📱 フロントエンド実装ロードマップ

## 📊 現在の実装状況

### ✅ 完了済み (Phase 1-2)
- **依存関係設定**: 画像処理・Classroom・高度エディタ・レスポンシブ関連
- **プロジェクト構造**: features/core Clean Architectureに移行完了
- **状態管理統一**: Provider パターンでの全体統合
- **画像アップロードサービス**: Web/Mobile対応、4つの入力方法
- **画像管理UI**: アップロード・プレビュー・選択機能

### 🔄 実装中
- **画像アップロード機能デバッグ**: Firebase Storage統合、エラーハンドリング改善

## 🎯 Phase 3-5: 追加実装計画

### **Phase 3: エディタ機能強化** 🎨
**優先度**: 高 | **工数**: 3-5日

#### T3-ED-001: Quill.js エディタ統合改善
- **現状**: 基本実装済み（`web/quill/index.html`）
- **改善点**:
  - リッチテキスト機能拡張（表・リスト・色変更）
  - ショートカットキー対応
  - 自動保存機能
- **ファイル**: `lib/features/editor/`

#### T3-ED-002: リアルタイムプレビュー機能
- **機能**: HTML→視覚プレビューのリアルタイム表示
- **技術**: flutter_widget_from_html使用
- **UI**: 分割画面（エディタ + プレビュー）
- **ファイル**: `lib/features/editor/presentation/widgets/preview_panel.dart`

#### T3-ED-003: テンプレート選択機能
- **機能**: 季節・行事別デザインテンプレート
- **データ**: 
  - 春（入学式・遠足）
  - 夏（運動会・プール）
  - 秋（文化祭・修学旅行）
  - 冬（クリスマス・卒業式）
- **ファイル**: `lib/features/templates/`

### **Phase 4: UX改善・統合機能** ✨
**優先度**: 中 | **工数**: 4-6日

#### T4-UX-001: ドラッグ&ドロップ画像アップロード
- **現状**: desktop_drop依存関係追加済み
- **機能**: 
  - 画像ファイルをブラウザにドラッグ&ドロップ
  - 複数ファイル一括アップロード
  - ドラッグオーバー時の視覚フィードバック
- **実装場所**: `ImageUploadButtonGrid`に統合
- **ファイル**: `lib/features/images/presentation/widgets/drag_drop_area.dart`

#### T4-UX-002: 画像エディタ機能（簡易版）
- **機能**:
  - 基本トリミング（正方形・16:9・4:3）
  - 明度・コントラスト調整
  - 90度回転
- **技術**: Canvas API使用
- **ファイル**: `lib/features/images/presentation/widgets/image_editor.dart`

#### T4-UX-003: レスポンシブデザイン改善
- **対象**:
  - スマートフォン縦持ち最適化
  - タブレット横持ち対応
  - 大画面デスクトップ対応
- **技術**: responsive_framework活用
- **ファイル**: 既存UIコンポーネント全体

### **Phase 5: 高度機能** 🚀
**優先度**: 低 | **工数**: 5-8日

#### T5-ADV-001: 音声入力UI改善
- **機能**:
  - リアルタイム波形表示
  - 音声レベルメーター
  - 録音時間表示
  - ノイズレベル表示
- **技術**: Web Audio API + Canvas
- **ファイル**: `lib/features/chat/presentation/widgets/audio_visualizer.dart`

#### T5-ADV-002: AIチャット機能拡張
- **機能**:
  - デザイン修正提案（色・レイアウト・フォント）
  - 文章改善提案
  - 画像配置提案
- **バックエンド連携**: Google ADK Multi-Agent使用
- **ファイル**: `lib/features/chat/presentation/widgets/ai_suggestions.dart`

#### T5-ADV-003: 保存・履歴機能
- **機能**:
  - 作業途中保存（下書き）
  - 過去作品一覧・プレビュー
  - テンプレート化機能
- **データ**: Firestore使用
- **ファイル**: `lib/features/history/`

## 🔧 技術実装詳細

### **優先実装: ドラッグ&ドロップ機能**

```dart
// lib/features/images/presentation/widgets/drag_drop_area.dart
class DragDropArea extends StatefulWidget {
  final Function(List<File>) onFilesDropped;
  final Widget child;
  
  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragDone: (detail) {
        final imageFiles = detail.files.where(
          (file) => file.mimeType?.startsWith('image/') ?? false
        ).toList();
        onFilesDropped(imageFiles);
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: _isDragOver ? Colors.blue : Colors.transparent,
            width: 2,
          ),
        ),
        child: child,
      ),
    );
  }
}
```

### **統合方針**

```dart
// 既存のImageUploadButtonGridに統合
class ImageUploadButtonGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DragDropArea(
      onFilesDropped: _handleDroppedFiles,
      child: Container(
        // 既存のボタングリッド
        child: _buildButtonGrid(),
      ),
    );
  }
}
```

## 📋 実装チェックリスト

### Phase 3: エディタ機能強化
- [ ] T3-ED-001: Quill.js機能拡張
- [ ] T3-ED-002: リアルタイムプレビュー
- [ ] T3-ED-003: テンプレート選択

### Phase 4: UX改善
- [ ] T4-UX-001: ドラッグ&ドロップ
- [ ] T4-UX-002: 画像エディタ
- [ ] T4-UX-003: レスポンシブ改善

### Phase 5: 高度機能
- [ ] T5-ADV-001: 音声UI改善
- [ ] T5-ADV-002: AIチャット拡張
- [ ] T5-ADV-003: 保存・履歴機能

## 🎯 推奨実装順序

### **即座に実装可能（高ROI）**
1. **ドラッグ&ドロップ機能** - 既存UIに簡単統合、UX大幅改善
2. **リアルタイムプレビュー** - 既存プレビュー機能の強化
3. **レスポンシブ改善** - 既存レイアウトの調整

### **中期実装（要設計・準備）**
4. **テンプレート機能** - デザインアセット準備が必要
5. **画像エディタ機能** - Canvas操作実装が必要
6. **音声UI改善** - Web Audio API学習が必要

### **長期実装（複雑・バックエンド連携）**
7. **AIチャット拡張** - バックエンドAI連携が必要
8. **保存・履歴機能** - データベース設計が必要

## 🔄 バックエンド連携ポイント

### **画像処理API連携**
- 画像アップロード成功時のメタデータ保存
- 画像圧縮・リサイズ処理結果の反映
- Firebase Storage URL管理

### **AI機能連携**
- 音声認識結果の表示・編集
- Gemini AI修正提案の表示
- ADK Multi-Agent結果の統合

### **データ永続化**
- 作業履歴のFirestore保存
- ユーザー設定の同期
- テンプレート管理

## 📈 品質・パフォーマンス目標

### **パフォーマンス**
- 画像アップロード: <3秒（2MB以下）
- リアルタイムプレビュー: <100ms応答
- ドラッグ&ドロップ: 即座に反応

### **ユーザビリティ**
- 直感的な操作（説明不要）
- エラー時の分かりやすいメッセージ
- アクセシビリティ対応（キーボード操作）

### **クロスプラットフォーム**
- Chrome/Safari/Firefox対応
- デスクトップ/タブレット/スマートフォン対応
- Progressive Web App (PWA) 対応

---

**📝 更新履歴**
- 2025-06-22: 初版作成（Phase 1-2完了後）
- TBD: Phase 3実装開始時の詳細追加予定

**🎯 次のアクション**
バックエンドAPI実装完了後、Phase 3から段階的に実装開始予定。