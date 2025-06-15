
# 🚀 学級通信エディタ - クイックスタートガイド

**Phase R（MVP）完了済み** - 基本機能が稼働中のプロジェクトです

## 🎯 このガイドについて

このプロジェクトは既に**音声録音→AI生成→HTML出力**の基本フローが完成しています。
このガイドでは、既存の機能を確認・テストする方法を説明します。

## ⚡ 5分でテスト実行

### 1. 環境確認
```bash
# プロジェクトルートで実行
./scripts/check_env.sh
```

### 2. 依存関係インストール（最小構成）
```bash
# フロントエンド（依存関係は2個のみ）
cd frontend
flutter pub get

# バックエンド
cd ../backend/functions
pip install -r requirements.txt
```

### 3. 開発環境起動
```bash
# バックエンド起動（別ターミナル）
cd backend/functions
python main.py

# フロントエンド起動
cd frontend
flutter run -d chrome
```

## 🧪 機能テスト手順

### ✅ 実装済み機能の確認

#### 1. 音声録音機能
- 🎤 録音ボタンをクリック
- リアルタイム音声レベル表示を確認
- 録音停止後、音声データ生成を確認

#### 2. 音声認識機能
- 📝 録音した音声が自動的にテキスト変換される
- 日本語認識精度: 平均89%（78.5-95.0%）
- 処理時間: 通常1-3秒

#### 3. AI文章生成機能
- 🤖 テキストから学級通信が自動生成される
- Vertex AI + Gemini Pro 1.5使用
- 生成時間: 1.2-5.2秒
- 出力: 52-392文字の適切な学級通信

#### 4. HTML表示・ダウンロード
- 📄 生成された学級通信をHTML形式で表示
- ダウンロードボタンでファイル保存
- dart:js_interop使用の高速処理

## 🔧 開発者向け情報

### 現在の技術スタック
```
フロントエンド: Flutter Web (最小依存関係)
├── http: ^1.1.0      # API呼び出し
└── web: ^1.1.0       # Web Audio API

バックエンド: Python Flask
├── Vertex AI         # Gemini Pro 1.5
├── Speech-to-Text    # 音声認識
└── Google Cloud APIs
```

### APIエンドポイント
```
開発環境: https://yutori-api-dev.a.run.app
本番環境: https://yutori-api.a.run.app
```

### 最小pubspec.yaml
```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0      # API呼び出し（STT・Gemini）
  web: ^1.1.0       # Web Audio API
  
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
```

## 🐛 既知の課題

### 緊急対応必要
- ❌ **UIレイアウトエラー**: RenderFlex overflow by 93 pixels
- ❌ **JavaScript Bridge型エラー**: JsObject → bool型変換エラー
- ⚠️ **フォント警告**: Noto fonts missing characters警告

### 改善候補
- 🔧 音声レベル表示の安定化
- 🔧 AI生成内容の一貫性向上
- 🔧 エラーメッセージの日本語化
- 🔧 レスポンシブデザイン対応

## 🎯 次のステップ

### Phase R+1: 品質向上
- UI/UXバグ修正
- エラーハンドリング強化
- パフォーマンス最適化

### Phase R+2: 機能拡張
- Firebase Firestore統合（データ保存）
- モバイル最適化UI
- 季節カラーパレット
- Quill.js高度エディタ統合

## 📚 関連ドキュメント

| ドキュメント | 用途 |
|------------|------|
| [🚀 デプロイガイド](deployment_guide.md) | 本格的なデプロイ手順 |
| [🔐 環境変数設定](environment_setup.md) | APIキー・シークレット設定 |
| [📋 現在の実装仕様](91_CURRENT_SPEC.md) | 詳細な実装状況 |
| [📦 依存関係管理](92_DEPENDENCIES.md) | パッケージ管理方針 |
| [🔌 API仕様](30_API_endpoints.md) | エンドポイント詳細 |

## 💡 開発のコツ

### 軽量開発の維持
- 新しいパッケージ追加前に必要性を検討
- 標準ライブラリで代替できないか確認
- 最小構成を維持してパフォーマンス重視

### デバッグ方法
```bash
# Flutter Web デバッグ
flutter run -d chrome --debug

# バックエンドログ確認
cd backend/functions && python main.py

# ブラウザ開発者ツールでJavaScript Bridge確認
```

### テスト実行
```bash
# フロントエンドテスト
cd frontend && flutter test

# バックエンドテスト（今後実装予定）
cd backend/functions && pytest
```

---

**🎉 Phase R完了おめでとうございます！**  
基本機能が稼働中の実用的なMVPが完成しています。 