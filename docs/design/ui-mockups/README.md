# UI/UXデザインモックアップ

このディレクトリには、学校だよりAIのUI/UXデザインモックアップとワイヤーフレームが含まれています。

## 📁 ファイル構成

```
ui-mockups/
├── README.md                          # このファイル（総合ガイド）
├── ui-design-mockup.md               # メインUI設計（チャットボット形式）
├── preview-editor-specification.md    # プレビュー・編集機能仕様
├── preview-mode-examples.md          # 各プレビューモードの画面例
├── classroom-integration-spec.md      # Classroom連携・画像アップロード仕様
├── user-flow-v1.png                  # ユーザーフロー図
├── wireframes/                        # ワイヤーフレーム
│   ├── chat-interface.png            # チャットインターフェース
│   ├── preview-modes.png             # プレビューモード切り替え
│   ├── image-upload.png              # 画像アップロード
│   ├── classroom-post.png            # Classroom投稿
│   └── mobile-responsive.png         # モバイル対応
├── mockups/                           # 高解像度モックアップ
│   ├── chat-bot-interface.png        # チャットボット画面
│   ├── multi-preview-modes.png       # マルチプレビューモード
│   ├── image-upload-flow.png         # 画像アップロード画面
│   ├── classroom-integration.png     # Classroom連携画面
│   └── pdf-print-preview.png         # PDF・印刷プレビュー
├── user-flows/                        # ユーザーフロー図
│   ├── chat-to-newsletter.png        # チャット→学級通信フロー
│   ├── image-integration.png         # 画像統合フロー
│   ├── classroom-posting.png         # Classroom投稿フロー
│   └── error-scenarios.png           # エラーシナリオ
└── design-system/                     # デザインシステム
    ├── colors-education.png          # 教育現場向けカラーパレット
    ├── typography-japanese.png       # 日本語タイポグラフィ
    ├── chat-components.png           # チャットコンポーネント
    ├── preview-components.png        # プレビューコンポーネント
    └── icons-education.png           # 教育関連アイコンセット
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

### チャットボット画面（メイン）
```
目的: 自然な会話で学級通信の情報収集
レイアウト: 左右分割（チャット + プレビュー）
重要な要素:
- AI⇄教師の対話インターフェース（左）
- リアルタイムプレビュー（右）
- 音声入力・テキスト入力両対応
- スマホではタブ切り替え
```

### プレビュー・編集画面
```
目的: 多様なプレビューモードと編集機能
レイアウト: モード切り替え型
重要な要素:
- [編集] [印刷ビュー] [PDF] [📚Classroom] [🔄] ボタン
- 読み取り専用プレビュー
- インライン編集モード
- 全画面印刷ビュー
```

### 画像アップロード画面
```
目的: 簡単な画像追加・管理
レイアウト: 4つの入力方法 + 一覧表示
重要な要素:
- ファイル選択・カメラ撮影・URL・AI生成
- サムネイル一覧・編集・削除機能
- ドラッグ&ドロップ対応（デスクトップ）
```

### Classroom投稿画面
```
目的: 学級通信の直接配信
レイアウト: 設定フォーム + プレビュー
重要な要素:
- Google認証・クラス選択
- タイトル・説明文・予約投稿設定
- 添付ファイル確認・投稿プレビュー
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

## 🔗 関連ドキュメント

### 📄 詳細仕様書
1. **[ui-design-mockup.md](ui-design-mockup.md)** - チャットボット形式のメインUI設計
2. **[preview-editor-specification.md](preview-editor-specification.md)** - プレビュー・編集機能の技術仕様
3. **[preview-mode-examples.md](preview-mode-examples.md)** - 各プレビューモードの画面例
4. **[classroom-integration-spec.md](classroom-integration-spec.md)** - Classroom連携・画像アップロード仕様

### 🎨 新機能の概要
- **チャットボット形式**: AI⇄教師の自然な対話で情報収集
- **マルチプレビューモード**: 編集・印刷ビュー・PDF・Classroom投稿
- **画像統合**: アップロード・編集・レイアウト調整
- **Classroom連携**: 直接投稿・予約投稿・一元管理

## 🚀 実装優先度

### Phase 1（基本UI）✅ 設計完了
- [x] チャットボット形式の基本設計
- [x] レスポンシブレイアウト（デスクトップ・モバイル）
- [x] プレビューモード切り替え設計

### Phase 2（画像・編集機能）📝 設計完了・実装待ち
- [x] 画像アップロード機能設計
- [x] インライン編集機能設計
- [x] 印刷ビュー・PDF出力設計
- [ ] 実装・テスト

### Phase 3（Classroom連携）📝 設計完了・実装待ち
- [x] Google Classroom API連携設計
- [x] 投稿機能・予約投稿設計
- [x] 認証・権限管理設計
- [ ] 実装・テスト

### Phase 4（UX向上）🔄 継続改善
- [ ] マイクロインタラクション設計
- [ ] アニメーション仕様
- [ ] アクセシビリティ強化
- [ ] パフォーマンス最適化

---

*デザインについての質問や提案は、GitHubのIssueで管理しています*