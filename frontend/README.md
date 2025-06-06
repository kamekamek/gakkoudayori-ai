# ゆとり職員室 フロントエンド

Flutter Webベースのグラレコ風学級通信作成アプリケーション

## 🎯 概要

音声入力から AIチャット編集を経てグラレコ風HTMLの学級通信を20分で作成。先生の「ゆとり」を創出するシステムのフロントエンドです。

## 🚀 開発環境構築

### 前提条件
- Flutter SDK 3.4.1+ 
- Dart SDK 3.4.1+
- Chrome ブラウザ（Web開発用）

### セットアップ手順

```bash
# 1. 依存関係のインストール
flutter pub get

# 2. Web サーバー起動（開発用）
flutter run -d chrome

# 3. 本番ビルド（必要時）
flutter build web
```

### ポート・URL
- **開発サーバー**: http://localhost:****（Flutterが自動割り当て）
- **本番URL**: Cloud Run デプロイ先

## 🏗️ アーキテクチャ

### ディレクトリ構造
```
lib/
├── main.dart                 # アプリケーションエントリーポイント
├── app.dart                  # ルートアプリウィジェット設定
├── models/                   # データモデル
│   ├── document.dart         # ドキュメントモデル
│   └── template.dart         # テンプレートモデル
├── providers/                # 状態管理（Provider）
│   └── app_state.dart        # グローバル状態管理
├── screens/                  # 画面ウィジェット
│   ├── dashboard_screen.dart # ダッシュボード画面
│   ├── editor_screen.dart    # エディタ画面
│   └── settings_screen.dart  # 設定画面
├── widgets/                  # 再利用可能コンポーネント
│   ├── preview_panel.dart    # プレビューパネル
│   ├── text_editor_panel.dart # テキストエディタ
│   ├── voice_input_panel.dart # 音声入力パネル
│   ├── quick_action_button.dart # クイックアクション
│   ├── recent_documents_list.dart # 最近のドキュメント
│   └── season_card.dart      # 季節カード
└── theme/                    # テーマ設定
    └── app_theme.dart        # アプリテーマ定義
```

### 技術スタック
- **UI Framework**: Flutter Web 3.4.1+
- **状態管理**: Provider 6.1.1
- **ルーティング**: go_router 13.2.0  
- **HTTP通信**: http 1.1.0
- **アニメーション**: flutter_animate 4.5.2
- **認証**: Firebase Auth 4.15.3
- **DB**: Cloud Firestore 4.13.6
- **アイコン**: lucide_icons 0.257.0

## 🎨 デザインシステム

### カラーパレット
- **春**: 桜ピンク・若草グリーン系
- **夏**: スカイブルー・ひまわりイエロー系  
- **秋**: 紅葉オレンジ・栗ブラウン系
- **冬**: 雪ホワイト・常緑グリーン系

### コンポーネント
- **Voice Input Panel**: ワンタップ録音・リアルタイム字幕
- **Text Editor Panel**: WYSIWYG・差分表示対応
- **Preview Panel**: リアルタイムHTMLプレビュー
- **Season Card**: 季節テンプレート選択
- **Quick Action**: よく使う機能へのワンタップアクセス

## 🔧 開発ルール

### コーディング規約
[CODING_GUIDELINES.md](../docs/CODING_GUIDELINES.md) の Flutter/Dart セクションを参照

### 重要ルール
- **MVVM + Provider**: ViewModelは Providerクラスで実装
- **State管理**: `Consumer`ウィジェットで状態購読  
- **非同期処理**: 必ず`mounted`チェック実装
- **エラーハンドリング**: Try-catchでログ+ユーザー通知
- **ライフサイクル**: StreamSubscription等の適切なdispose

### テスト戦略
```bash
# ウィジェットテスト実行
flutter test

# テスト（統合・E2E含む）
flutter drive --target=test_driver/integration_test.dart
```

## 🔍 主要機能実装状況

### ✅ 実装済み
- [x] ダッシュボード画面（過去通信一覧・新規作成）
- [x] 基本エディタ画面（3ペイン構成）
- [x] 設定画面（ユーザー辞書・Drive連携・LINE通知）
- [x] 音声入力UI（ワンタップ録音・リアルタイム字幕）
- [x] レスポンシブ対応（スマートフォン・タブレット）

### 🚧 開発中
- [ ] Firebase Authentication統合
- [ ] WYSIWYG HTMLエディタ統合  
- [ ] リアルタイムチャット編集UI
- [ ] テンプレート選択・適用機能
- [ ] 素材パレット（SVGアイコン・D&D）

### ⏳ 今後実装
- [ ] PDF生成プレビュー
- [ ] Google Classroom投稿UI
- [ ] アクセシビリティ強化
- [ ] パフォーマンス最適化

## 🐛 デバッグ・トラブルシューティング

### よくある問題

#### 1. Webアプリが起動しない
```bash
# Flutterキャッシュクリア
flutter clean
flutter pub get

# Chromeキャッシュクリア
# 開発者ツール > Application > Storage > Clear site data
```

#### 2. Firebase接続エラー
```dart
// web/index.html のFirebase設定確認
// Firebase Console プロジェクト設定の確認
```

#### 3. CORS エラー
```dart
// backend の CORS設定確認
// FastAPIのadd_middleware設定確認
```

#### 4. 状態管理エラー  
```dart
// Providerのライフサイクル確認
// Consumer ウィジェットの適切な配置確認
```

### デバッグツール
```bash
# Flutter Inspector（Widget Tree確認）
flutter inspector

# パフォーマンス分析
flutter run --profile -d chrome
```

## 📊 パフォーマンス目標

- **エディタ応答**: <100ms（リアルタイム編集）
- **画面遷移**: <200ms
- **音声録音開始**: <50ms  
- **プレビュー更新**: <100ms
- **アプリ起動**: <3秒

## 🤝 コントリビューション

### プルリクエスト前チェック
- [ ] `flutter analyze` エラー0件
- [ ] `flutter test` 全テスト通過  
- [ ] UI/UXレビュー（デザインシステム準拠）
- [ ] パフォーマンスチェック（Chrome DevTools）
- [ ] アクセシビリティチェック（Lighthouse）

### コミットメッセージ
```
[FEAT] 音声入力UIのリアルタイム字幕機能を実装
[FIX] エディタ画面のプレビュー表示バグ修正  
[REFACTOR] Provider状態管理の最適化
[TEST] 音声入力ウィジェットのテスト追加
```

---

**🎯 目標: 20分で学級通信作成 → 先生の「ゆとり」創出！**
