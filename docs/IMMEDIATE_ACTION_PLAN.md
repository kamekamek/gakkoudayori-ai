# 即座実行アクションプラン

**作成日**: 2025-06-13  
**緊急度**: 🚨 最高  
**目標**: Web版Quill.jsエディタの完全統合

---

## 🎯 現在の状況

### ✅ 完了済み実装
1. **重複AI生成バグ修正** - 2025-06-13 完了
   - `_isGenerating`フラグ追加
   - 重複防止ログ確認済み
   - ユーザーフロー改善済み

2. **Quill.jsエディタ基盤** - 2025-06-13 完了
   - `frontend/web/quill/index.html` (384行)
   - 季節テーマ4種類実装
   - JavaScript Bridge基盤

3. **QuillEditorWidget実装** - 2025-06-13 完了
   - `frontend/lib/widgets/quill_editor_widget.dart`
   - HtmlElementView + iframe方式
   - Flutter ↔ JavaScript 双方向通信

4. **技術選択分析** - 2025-06-13 完了
   - [WEBVIEW_TECHNOLOGY_ANALYSIS.md](WEBVIEW_TECHNOLOGY_ANALYSIS.md)
   - 5回の調査サイクル実行
   - 段階的ハイブリッド実装戦略決定

### 🚀 現在の実行状況
- ✅ バックエンドサーバー稼働中（ポート8080）
- ✅ Flutter Web稼働中（Chrome）
- ✅ 音声録音→文字起こし→AI生成フロー動作確認済み

---

## 🎯 次のタスク：main.dart統合

### 📋 T-R3-005: main.dart統合（今すぐ実行）

#### 🎯 目標
HtmlPreviewWidget を QuillEditorWidget に置き換え、AI生成結果を編集可能にする

#### 📂 対象ファイル
- `frontend/lib/main.dart` (591行)
- 該当箇所: 516-526行（HtmlPreviewWidget使用部分）

#### 🔧 実装内容

##### Step 1: import追加
```dart
// main.dartの先頭に追加
import 'widgets/quill_editor_widget.dart';
```

##### Step 2: HtmlPreviewWidget置き換え
```dart
// 現在の実装（516-526行）
LayoutBuilder(
  builder: (context, constraints) {
    final screenHeight = MediaQuery.of(context).size.height;
    final previewHeight = (screenHeight * 0.3).clamp(200.0, 400.0);

    return HtmlPreviewWidget(
      htmlContent: _generatedHtml,
      height: previewHeight,
    );
  },
),

// ↓ 置き換え後
LayoutBuilder(
  builder: (context, constraints) {
    final screenHeight = MediaQuery.of(context).size.height;
    final editorHeight = (screenHeight * 0.4).clamp(300.0, 500.0);

    return QuillEditorWidget(
      initialContent: _generatedHtml,
      contentFormat: 'html',
      height: editorHeight,
      onContentChanged: (html) {
        setState(() {
          _generatedHtml = html;
        });
        print('📝 [QuillEditor] 内容更新: ${html.length}文字');
      },
      onEditorReady: () {
        print('✅ [QuillEditor] エディタ準備完了');
      },
    );
  },
),
```

##### Step 3: 状態管理変数追加
```dart
// _MyAppStateクラスに追加
final GlobalKey<QuillEditorWidgetState> _quillEditorKey = GlobalKey();
bool _isEditing = false;
```

##### Step 4: 編集モード切り替えボタン追加
```dart
// アクションボタン行に追加
Row(
  children: [
    // 既存の再生成ボタン
    Expanded(
      child: ElevatedButton.icon(/* 既存実装 */),
    ),
    SizedBox(width: 8),
    
    // 編集モード切り替えボタン（新規追加）
    Expanded(
      child: ElevatedButton.icon(
        onPressed: () {
          setState(() {
            _isEditing = !_isEditing;
          });
          print('✏️ [QuillEditor] 編集モード: $_isEditing');
        },
        icon: Icon(_isEditing ? Icons.preview : Icons.edit),
        label: Text(_isEditing ? '📄 プレビュー' : '✏️ 編集'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
        ),
      ),
    ),
    SizedBox(width: 8),
    
    // 既存のダウンロードボタン
    Expanded(
      flex: 2,
      child: ElevatedButton.icon(/* 既存実装 */),
    ),
  ],
),
```

---

## ⚡ 即座実行コマンド

### 1. バックエンド確認
```bash
# バックエンドが稼働していない場合
cd backend/functions && python main.py
```

### 2. フロントエンド起動
```bash
# 新しいターミナルで実行
cd frontend && flutter run -d chrome --hot
```

### 3. main.dart統合実装
```bash
# QuillEditorWidget import追加 → HtmlPreviewWidget置き換え → テスト
```

### 4. 動作確認フロー
1. ✅ 音声録音ボタンタップ
2. ✅ 音声録音（例: 「今日は運動会でした」）
3. ✅ 文字起こし確認
4. ✅ 「学級通信を作成する」ボタン押下
5. ✅ AI生成結果確認
6. 🆕 Quill.jsエディタで編集テスト
7. 🆕 リアルタイム編集同期確認
8. 🆕 季節テーマ切り替えテスト

---

## 🔍 期待される結果

### 成功基準
- [ ] QuillEditorWidget正常表示
- [ ] AI生成HTMLの初期表示
- [ ] テキスト編集機能動作
- [ ] リアルタイム内容同期
- [ ] 季節テーマ切り替え機能
- [ ] エラーなしで完全フロー実行

### 確認ポイント
1. **iframe読み込み**: 「✅ [QuillEditor] iframe読み込み完了」ログ
2. **Bridge接続**: 「🔗 [QuillEditor] JavaScript Bridge設定完了」ログ
3. **内容設定**: 「📝 [QuillEditor] 内容設定完了」ログ
4. **編集同期**: 「📝 [QuillEditor] 内容更新」ログ

---

## 🚨 エラー対応

### よくある問題と対策

#### 1. iframe読み込み失敗
```
エラー: ❌ [QuillEditor] iframe contentWindow取得失敗
対策: quill/index.htmlのパス確認、数秒待ってリトライ
```

#### 2. JavaScript Bridge未接続
```
エラー: 🔗 [QuillBridge] Flutter通信エラー
対策: window.parent存在確認、ブラウザコンソールでエラー確認
```

#### 3. HtmlElementView表示されない
```
エラー: プラットフォームビュー未登録
対策: ui_web.platformViewRegistry確認、viewType重複チェック
```

---

## 📅 今日のスケジュール

### 🕐 今すぐ〜30分後
- [x] ドキュメント作成完了
- [ ] main.dart統合実装
- [ ] 基本動作確認

### 🕐 30分後〜1時間後
- [ ] エラー修正・調整
- [ ] 詳細機能テスト
- [ ] UI/UX確認

### 🕐 1時間後〜
- [ ] 完成版コミット
- [ ] 次のタスク（PDF出力）準備
- [ ] Phase R3-B完了報告

---

## 🎉 完了後の次ステップ

### Phase R3-C: PDF出力実装（明日）
1. **T-R3-007**: WeasyPrint PDF生成API
2. **T-R3-008**: PDF出力UI統合
3. **T-R3-009**: E2Eテスト完了

### Phase R4: UI/UX改善（来週）
1. **先生向けシンプルUI**
2. **テイスト選択統合**
3. **エラーハンドリング強化**

---

**🚀 今すぐmain.dart統合を開始しましょう！** 