# 🚀 学級通信AI - 実行可能タスクロードマップ

**作成日**: 2025-06-13  
**基準**: 現実の実装状況に基づく実行可能計画  
**目標**: 動作するプロダクト完成

---

## 🎯 最終ゴール

**完成品イメージ**:
```
音声録音 → 文字起こし → Quill.js編集 → PDF出力
   ↓           ↓           ↓           ↓
🎤 Web Audio → 📝 Google STT → ✏️ WYSIWYG → 📄 ダウンロード
```

**ユーザー体験**:
1. 先生が音声で学級通信内容を話す
2. AIが文字起こし・文章整形
3. Quill.jsでWYSIWYG編集
4. 季節テーマ適用・PDF出力

---

## 📋 実行タスク（優先度順）

### 🔥 Phase R3-A: 緊急バグ修正（今日 - 1時間）

#### ✅ T-R3-001: 重複AI生成バグ修正
- **緊急度**: 🚨 最高
- **作業時間**: 30分
- **ファイル**: `frontend/lib/main.dart`
- **問題**: 音声録音完了後にAI生成が2回実行される
- **解決策**: `_generateNewsletter()`の重複呼び出し防止フラグ追加
- **成功基準**: 音声→文字起こし→手動送信→1回だけAI生成

**実装内容**:
```dart
bool _isGenerating = false; // 生成中フラグ追加

Future<void> _generateNewsletter() async {
  if (_isGenerating) return; // 重複実行防止
  _isGenerating = true;
  try {
    // AI生成処理
  } finally {
    _isGenerating = false;
  }
}
```

#### ✅ T-R3-002: ユーザーフロー修正
- **作業時間**: 30分
- **問題**: 音声録音→即座AI生成（ユーザー確認なし）
- **解決策**: 音声→文字起こし表示→確認→手動送信→AI生成
- **UI変更**: 
  - 「学級通信を作成する」送信ボタン追加
  - 文字起こし結果の編集可能テキストエリア
  - 音声録音後の自動生成を無効化

---

### 🔥 Phase R3-B: Quill.js基盤実装（今日〜明日 - 4時間）

#### T-R3-003: Quill.js HTMLファイル作成
- **作業時間**: 1時間
- **成果物**: `frontend/web/quill/index.html`
- **内容**: 
  - Quill.js 2.0.0 CDN読み込み
  - 学校向けシンプルツールバー（H1,H2,H3,Bold,Italic,List）
  - 季節テーマCSS基盤
  - HTML制約プロンプト対応（allowedTags制限）

**ツールバー設計**:
```javascript
const toolbarOptions = [
  [{ 'header': [1, 2, 3, false] }],      // 見出し
  ['bold', 'italic'],                     // 基本書式
  [{ 'list': 'ordered'}, { 'list': 'bullet' }], // リスト
  ['clean']                               // クリア
];
```

#### T-R3-004: Flutter WebView統合
- **作業時間**: 1.5時間
- **成果物**: `frontend/lib/widgets/quill_editor_widget.dart`
- **内容**:
  - webview_flutter_web パッケージ統合
  - Quill.js HTMLファイル読み込み
  - WebView設定最適化

#### T-R3-005: JavaScript Bridge実装
- **作業時間**: 1.5時間
- **成果物**: 
  - `frontend/web/quill/bridge.js`
  - `frontend/lib/services/quill_bridge_service.dart`
- **機能**:
  - Flutter ↔ JavaScript 双方向通信
  - HTML/Delta取得・設定
  - リアルタイム内容同期

---

### 🔥 Phase R3-C: PDF出力実装（明日 - 2時間）

#### T-R3-006: PDF生成API実装
- **作業時間**: 1時間
- **成果物**: `backend/functions/pdf_generator.py`
- **内容**:
  - WeasyPrint統合
  - HTML→PDF変換
  - 日本語フォント対応（NotoSansCJK）
  - A4サイズ最適化

#### T-R3-007: PDF出力UI実装
- **作業時間**: 1時間
- **成果物**: `frontend/lib/widgets/pdf_export_widget.dart`
- **機能**:
  - PDFダウンロードボタン
  - 生成進捗表示
  - エラーハンドリング

---

### 🟡 Phase R4: UI/UX改善（来週 - 6時間）

#### T-R4-001: 先生向けシンプルUI
- **作業時間**: 3時間
- **UI改善**:
  - 大きな音声録音ボタン（👆 タップしやすい）
  - 明確な送信ボタン（「学級通信を作成する」）
  - 文字起こし確認エリア（編集可能）
  - 右側リアルタイムプレビュー
  - 装飾の簡素化（ボタン・色・フォント）

#### T-R4-002: テイスト選択統合
- **作業時間**: 2時間
- **内容**:
  - 昨日実装済み`taste_selection_service.py`のフロントエンド統合
  - モダン/クラシック/ミニマル/カラフル選択UI
  - Quill.js季節テーマとの連携

#### T-R4-003: エラーハンドリング強化
- **作業時間**: 1時間
- **対応範囲**:
  - マイクアクセス拒否時の案内
  - STT API失敗時の代替手段提示
  - AI生成失敗時のリトライ機能
  - オフライン時の動作制御

---

### 🟢 Phase R5: 高度機能（余裕があれば - 4時間）

#### T-R5-001: ユーザー辞書統合
- **作業時間**: 1時間
- **内容**: 昨日実装済み`user_dictionary_service.py`の完全統合

#### T-R5-002: 画像挿入機能
- **作業時間**: 2時間
- **内容**: Quill.js画像モジュール、Firebase Storage連携

#### T-R5-003: 保存・履歴機能
- **作業時間**: 1時間
- **内容**: Firestore連携、過去通信の保存・読み込み

---

## 📅 実行スケジュール

### 【今日 2025-06-13】 ⚡ 緊急修正デー
- **09:00-10:00**: 重複バグ修正 + ユーザーフロー修正
- **10:00-12:00**: Quill.js HTMLファイル作成 + WebView統合開始
- **14:00-16:00**: WebView統合完成 + JavaScript Bridge実装開始
- **目標**: 基本的なQuill.js表示まで

### 【明日 2025-06-14】 🔥 機能実装デー  
- **09:00-10:30**: JavaScript Bridge完成
- **10:30-12:00**: PDF出力API実装
- **14:00-15:00**: PDF出力UI実装
- **15:00-17:00**: 全体統合テスト + バグ修正
- **目標**: 音声→Quill編集→PDF出力の完全フロー

### 【来週 2025-06-15〜17】 🎨 UX改善週間
- **6/15**: 先生向けシンプルUI実装
- **6/16**: テイスト選択統合
- **6/17**: エラーハンドリング + 最終調整

---

## ✅ 成功基準・受け入れテスト

### Phase R3 完了基準
1. **バグ修正**: 音声録音→文字起こし→手動送信→1回生成 ✅
2. **Quill.js**: 文字起こし結果をQuill.jsで編集可能 ✅
3. **PDF出力**: 編集済みHTMLをPDFダウンロード可能 ✅

### Phase R4 完了基準
1. **シンプルUI**: デジタル疎い先生が迷わず使用可能
2. **テイスト選択**: 4種類のテイスト選択・即座反映
3. **エラー対応**: 主要エラーで適切なガイダンス表示

### 最終受け入れテスト
```
E2Eテストシナリオ:
1. 音声録音ボタンタップ
2. 「今日は運動会でした」と話す
3. 文字起こし結果確認・編集
4. 「学級通信を作成する」ボタン押下
5. Quill.jsでAI生成文章を編集
6. テイスト選択・季節テーマ適用
7. PDFダウンロード
8. 印刷可能なPDFファイル確認

成功基準: 上記フロー20分以内で完了
```

---

## 🔧 技術構成（最終版）

```
Frontend: Flutter Web
├── UI: Material Design (シンプル化)
├── Editor: Quill.js 2.0.0 (WebView統合)
├── 音声: Web Audio API
└── 状態管理: Provider

Backend: FastAPI
├── STT: Google Speech-to-Text
├── AI: Gemini 1.5 Pro
├── PDF: WeasyPrint
└── Storage: Firebase

Infrastructure:
├── GCP: Vertex AI + Speech-to-Text
├── Firebase: Auth + Firestore + Storage
└── Hosting: Firebase Hosting (Web)
```

---

## 📞 次のアクション

1. **今すぐ実行**: 重複バグ修正（30分）
2. **今日中**: Quill.js基盤実装開始
3. **明日完成**: PDF出力機能統合
4. **来週**: UI/UX改善・最終調整

**今日のコミット目標**: 「🔥 Phase R3-A: 重複バグ修正 + Quill.js基盤実装開始」 