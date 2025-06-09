# 学校だよりAI 実装計画 - Google ADK対応版

**カテゴリ**: STRATEGY | **レイヤー**: IMPLEMENTATION | **更新**: 2025-06-09  
**担当**: 亀ちゃん | **依存**: 24_SPEC_adk_multi_agent.md | **タグ**: #implementation #adk #multi-agent

## 1. 実装フェーズ概要

### Phase 1: 基盤構築（2-3日）
- 新プロジェクト初期化
- Google ADK環境セットアップ  
- 基本エージェント実装

### Phase 2: マルチエージェント開発（3-4日）
- Content Analyzer Agent
- Style Writer Agent
- エージェント協調システム

### Phase 3: 高度エージェント（2-3日）
- Layout Designer Agent
- Fact Checker Agent
- Engagement Optimizer Agent

### Phase 4: UI統合（2-3日）
- Flutter Web + Quill.js統合
- エージェント結果の表示
- リアルタイムプレビュー

### Phase 5: 統合・最適化（2-3日）
- E2Eテスト
- パフォーマンス最適化
- 品質保証

## 2. 技術仕様（仮決め項目）

### Google ADK環境
- **Python ADK**: v1.0.0（Production Ready）
- **Vertex AI**: Gemini Pro API統合
- **エージェント管理**: ADK Agent Orchestrator
- **通信**: WebSocket（リアルタイム協調）

### Quill.js設定
- **バージョン**: 2.0.0（最新の安定版）
- **テーマ**: Snow
- **モジュール**: toolbar, history, clipboard, formula
- **ADK統合**: WebView経由でエージェント結果受信
- **CDN**: `https://cdn.quilljs.com/2.0.0/quill.snow.css` および `https://cdn.quilljs.com/2.0.0/quill.min.js`

### HTMLテンプレート（グラレコ風）
基本構造:
```html
<div class="letter-container season-spring">
  <header class="letter-header">
    <h1 class="letter-title">学級通信 6月号</h1>
    <div class="letter-meta">2025年6月15日発行</div>
  </header>
  
  <section class="topic">
    <h2 class="topic-heading">
      <span class="topic-icon">📝</span>
      <span class="topic-text">今月のお知らせ</span>
    </h2>
    <div class="topic-content">
      <p>6月も元気に活動しています！</p>
      <div class="speech-bubble">
        <p>みなさん、こんにちは！<br>梅雨の季節になりましたね。</p>
      </div>
    </div>
  </section>
  
  <!-- 以下同様の構造を繰り返し -->
</div>
```

### 季節カラーパレット
```json
{
  "spring": {
    "primary": "#ff9eaa",
    "secondary": "#a5d8ff",
    "accent": "#ffdb4d",
    "background": "#f8f9fa",
    "text": "#343a40"
  },
  "summer": {
    "primary": "#51cf66",
    "secondary": "#339af0",
    "accent": "#ff922b",
    "background": "#f1f8ff",
    "text": "#1a1c20"
  },
  "autumn": {
    "primary": "#e67700",
    "secondary": "#d9480f",
    "accent": "#fff3bf",
    "background": "#fff9db",
    "text": "#2b2a29"
  },
  "winter": {
    "primary": "#4dabf7",
    "secondary": "#e7f5ff",
    "accent": "#91a7ff",
    "background": "#f8f9fa",
    "text": "#1a1c20"
  }
}
```

## 2. プロジェクト再構築計画

### フェーズ1: プロジェクト初期化と基盤構築（1-2日）

1. **プロジェクト構造**:
   - 既存のディレクトリ構造を活かす
   - `frontend/web/quill/` ディレクトリを新設
   - `docs/` 配下にデザイン仕様書を配置

2. **フロントエンド依存関係整理**:
   - 既存の`pubspec.yaml`を継続利用
   - WebView関連パッケージの最新化

3. **バックエンド依存関係整理**:
   - 既存の`requirements.txt`を継続利用
   - HTML処理・PDF生成関連の依存関係確認

### フェーズ2: Quill.js統合（2-3日）

1. **WebView + Quill.js実装**:
   - `frontend/web/quill/index.html` - Quill.jsローディングページ
   - `frontend/lib/widgets/quill_editor_widget.dart` - WebViewラッパー
   - `frontend/lib/providers/quill_editor_provider.dart` - 状態管理

2. **Dart ⇔ JavaScript Bridge**:
   - Delta JSON シリアライズ/デシリアライズ
   - 双方向コマンド通信

3. **デルタ変換関数**:
   - Delta → クリーンHTML変換
   - HTML → Delta逆変換

### フェーズ3: AI補助UI実装（2-3日）

1. **折りたたみUI**:
   - `frontend/lib/widgets/ai_assistant_panel.dart` - 折りたたみパネル
   - `frontend/lib/widgets/ai_suggestion_item.dart` - 提案アイテム
   - アニメーション・トランジション実装

2. **Geminiプロンプト**:
   - `backend/services/ai_prompt_service.py` - プロンプト生成
   - タグ制約実装
   - 回答フォーマット最適化

3. **挿入機能**:
   - Quill.js Delta操作
   - コンテンツ挿入位置管理

### フェーズ4: ストレージ連携（1-2日）

1. **Firestore/Storage構造**:
   - Firestoreスキーマ定義
   - Storageパス設計
   - アクセス制御設定

2. **保存/読込機能**:
   - HTML & Delta同時保存
   - 一貫性保証トランザクション
   - 履歴バージョン管理

### フェーズ5: 出力機能（1-2日）

1. **PDF生成**:
   - WeasyPrint最適化
   - CSSプリント用スタイル
   - フォント埋め込み

2. **配信連携**:
   - Drive API連携
   - Classroom API（オプション）
   - 共有設定自動化

### フェーズ6: グラレコ要素（2-3日）

1. **テンプレート実装**:
   - 基本テンプレート3種
   - 季節カラーパレット適用
   - アイコン・素材セット

2. **UI強化**:
   - プレビュー機能
   - ツールバーカスタマイズ
   - ドラッグ&ドロップ実装

### フェーズ7: テスト・最適化（1-2日）

1. **単体テスト**:
   - WebView⇔Quill.js連携
   - Delta⇔HTML変換
   - AI補助機能

2. **E2Eテスト**:
   - ユーザーフロー検証
   - PDF出力品質
   - パフォーマンス計測

## 3. 再構築アプローチ

既存の基盤部分を活かしながら、UI/エディタ部分を段階的に再実装します：

1. **既存コードの再利用対象**:
   - 認証機能
   - API連携基盤
   - ルーティング
   - 基本的なUI骨格

2. **新規実装対象**:
   - Quill.js統合
   - Delta⇔HTML変換
   - 折りたたみAI補助UI
   - グラレコテンプレート

3. **移行戦略**:
   - 既存HTMLエディタと並行して新エディタを実装
   - 機能検証後に切り替え
   - データ互換性の確保 