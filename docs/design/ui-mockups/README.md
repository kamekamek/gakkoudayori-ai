# UI/UXデザインモックアップ

このディレクトリには、学校だよりAIのUI/UXデザインモックアップとワイヤーフレームが含まれています。

## 📁 ファイル構成

```
ui-mockups/
├── README.md                    # このファイル
├── wireframes/                  # ワイヤーフレーム
│   ├── login-flow.png          # ログインフロー
│   ├── dashboard.png           # ダッシュボード
│   ├── editor-layout.png       # エディタレイアウト
│   └── mobile-responsive.png   # モバイル対応
├── mockups/                     # 高解像度モックアップ
│   ├── home-screen.png         # ホーム画面
│   ├── voice-input.png         # 音声入力画面
│   ├── ai-processing.png       # AI処理中画面
│   ├── editor-wysiwyg.png      # WYSIWYGエディタ
│   └── pdf-preview.png         # PDFプレビュー
├── user-flows/                  # ユーザーフロー図
│   ├── complete-workflow.png   # 完全ワークフロー
│   ├── voice-to-pdf.png        # 音声→PDF変換フロー
│   └── error-scenarios.png     # エラーシナリオ
└── design-system/              # デザインシステム
    ├── colors.png              # カラーパレット
    ├── typography.png          # タイポグラフィ
    ├── components.png          # コンポーネントライブラリ
    └── icons.png               # アイコンセット
```

## 🎨 デザインコンセプト

### 1. 教育現場への配慮
- **親しみやすさ**: 温かみのある色調とフォント
- **直感性**: 複雑な操作を排除し、1-2タップで完了
- **信頼性**: 安定感のあるレイアウトと十分な余白

### 2. モバイルファースト
- **タッチフレンドリー**: 44px以上のタップターゲット
- **片手操作**: 重要な操作は画面下部に配置
- **レスポンシブ**: PC・タブレット・スマホで最適化

### 3. アクセシビリティ
- **高コントラスト**: WCAG 2.1 AA準拠
- **大きな文字**: 最小14px、推奨16px
- **視覚的階層**: 明確な情報の優先順位

## 🎯 主要画面の設計思想

### ホーム画面
```
目的: 新規作成と過去の文書へのアクセス
レイアウト: FAB + カード一覧
重要な要素: 
- 「新しい学校だより」FABボタン（右下）
- 最近の文書（上部）
- 検索・フィルター（ヘッダー）
```

### 音声入力画面
```
目的: ストレスフリーな音声録音
レイアウト: 中央集約型
重要な要素:
- 大きな録音ボタン（画面中央）
- リアルタイム文字起こし（下部）
- 録音状態の視覚的フィードバック
```

### エディタ画面
```
目的: 直感的な文書編集
レイアウト: 2カラム（エディタ + プレビュー）
重要な要素:
- WYSIWYGエディタ（左）
- リアルタイムプレビュー（右）
- ツールバー（上部固定）
- AI支援パネル（折りたたみ式）
```

## 📱 レスポンシブデザイン

### ブレークポイント
```css
/* スマートフォン */
@media (max-width: 768px) {
  .editor-container {
    flex-direction: column;
  }
  .toolbar {
    position: sticky;
    top: 0;
  }
}

/* タブレット */
@media (min-width: 769px) and (max-width: 1024px) {
  .sidebar {
    width: 300px;
  }
}

/* デスクトップ */
@media (min-width: 1025px) {
  .main-content {
    max-width: 1200px;
    margin: 0 auto;
  }
}
```

### モバイル対応の工夫
1. **ナビゲーション**: ハンバーガーメニューでスペース確保
2. **エディタ**: シングルカラムでフォーカス向上
3. **ツールバー**: 必要最小限のアイコンに厳選
4. **入力**: 音声入力を優先、キーボード入力は補助的

## 🎨 デザインシステム

### カラーパレット
```scss
// プライマリカラー
$primary-blue: #2c5aa0;
$primary-light: #5e7bbf;
$primary-dark: #1d3a6f;

// セカンダリカラー
$secondary-orange: #ff6b35;
$secondary-green: #4ecdc4;
$secondary-yellow: #ffc107;

// 季節カラー
$spring-pink: #ffb3ba;
$summer-blue: #b3d9ff;
$autumn-orange: #ffcc99;
$winter-purple: #d1b3ff;

// システムカラー
$success: #28a745;
$warning: #ffc107;
$error: #dc3545;
$info: #17a2b8;

// グレースケール
$gray-50: #fafafa;
$gray-100: #f5f5f5;
$gray-200: #eeeeee;
$gray-300: #e0e0e0;
$gray-400: #bdbdbd;
$gray-500: #9e9e9e;
$gray-600: #757575;
$gray-700: #616161;
$gray-800: #424242;
$gray-900: #212121;
```

### タイポグラフィ
```scss
// 日本語フォント優先
$font-family: 'Noto Sans JP', 'Hiragino Kaku Gothic ProN', 
              'Hiragino Sans', 'Meiryo', sans-serif;

// フォントサイズ
$font-size-xs: 12px;
$font-size-sm: 14px;
$font-size-base: 16px;
$font-size-lg: 18px;
$font-size-xl: 20px;
$font-size-2xl: 24px;
$font-size-3xl: 30px;

// フォントウェイト
$font-weight-light: 300;
$font-weight-normal: 400;
$font-weight-medium: 500;
$font-weight-bold: 700;
```

## 🖼️ 既存のモックアップファイル

現在、以下のモックアップが利用可能です：

### user_flow_v1.png
- 完全なユーザーフローの概要
- 音声入力からPDF出力までの全ステップ
- エラーハンドリングのシナリオ

*このファイルは /docs/user_flow_v1.png にあります*

## 🔧 デザインツール

### 使用ツール
- **Figma**: 主要なデザインツール
- **Adobe XD**: プロトタイプ作成
- **Sketch**: コンポーネントライブラリ
- **Zeplin**: デザイン仕様書

### ファイル形式
- **PNG**: 高解像度画像（推奨: 2x, 3x）
- **SVG**: アイコン・ロゴ
- **PDF**: 印刷用資料
- **GIF**: アニメーション（操作説明）

## 📋 デザインレビュープロセス

### 1. 初期設計
- [ ] ユーザーストーリーベースの画面設計
- [ ] ワイヤーフレーム作成
- [ ] 情報アーキテクチャの確認

### 2. 詳細デザイン
- [ ] 高解像度モックアップ
- [ ] インタラクションデザイン
- [ ] レスポンシブ対応

### 3. ユーザビリティテスト
- [ ] プロトタイプでのユーザーテスト
- [ ] アクセシビリティチェック
- [ ] 教育現場での実地テスト

### 4. 実装フィードバック
- [ ] 開発者からの技術的フィードバック
- [ ] 実装可能性の検証
- [ ] パフォーマンス影響の評価

## 🚀 今後の予定

### Phase 1（基本デザイン）
- [ ] 全主要画面のモックアップ完成
- [ ] デザインシステムの確立
- [ ] アクセシビリティガイドライン策定

### Phase 2（応用デザイン）
- [ ] マイクロインタラクション設計
- [ ] アニメーション仕様
- [ ] ダークモード対応

### Phase 3（拡張デザイン）
- [ ] マルチテーマ対応
- [ ] カスタマイズ機能
- [ ] 多言語対応UI

---

*デザインについての質問や提案は、GitHubのIssueで管理しています*