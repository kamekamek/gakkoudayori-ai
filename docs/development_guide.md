# 📋 学校だよりAI 開発ガイド

**開発環境構築・開発手順・トラブルシューティング統合ガイド**

---

## 🚀 環境構築

### 1. 前提条件

```bash
# 必要なツール
- Flutter 3.32.2+
- Python 3.11+
- Node.js 18+
- Git
- Google Cloud SDK
```

### 2. プロジェクトセットアップ

```bash
# 1. リポジトリクローン
git clone https://github.com/kamekamek/yutorikyoshitu.git
cd yutorikyoshitu

# 2. Flutter環境確認
flutter doctor

# 3. 依存関係インストール
cd frontend && flutter pub get
cd ../backend/functions && pip install -r requirements.txt
```

### 3. 環境変数設定

```bash
# Firebase設定
cp frontend/lib/firebase_options.dart.template frontend/lib/firebase_options.dart
# エディタで実際の値に置換

# バックエンド環境変数
cd backend/functions
cp .env.example .env
# 実際のAPIキーを設定
```

---

## 💻 開発手順

### フロントエンド開発

```bash
# 開発サーバー起動
cd frontend
flutter run -d chrome

# ホットリロード有効
# r: ホットリロード
# R: ホットリスタート
# q: 終了
```

### バックエンド開発

```bash
# FastAPIサーバー起動
cd backend/functions
python main.py

# 自動リロード有効（開発時）
uvicorn main:app --reload --host 0.0.0.0 --port 8080
```

### テスト実行

```bash
# フロントエンドテスト
cd frontend && flutter test

# バックエンドテスト
cd backend/functions && python -m pytest tests/ -v

# 統合テスト
flutter test integration_test/
```

---

## 🔧 品質管理

### 静的解析

```bash
# Flutter解析
cd frontend && flutter analyze

# Python解析
cd backend/functions
flake8 .
black --check .
```

### フォーマット

```bash
# Dartフォーマット
cd frontend && dart format .

# Pythonフォーマット
cd backend/functions && black .
```

---

## 🐛 トラブルシューティング

### よくある問題

#### 1. Firebase接続エラー
```bash
# 症状: Firebase初期化失敗
# 解決: firebase_options.dartの設定確認
flutter clean && flutter pub get
```

#### 2. CORS エラー
```bash
# 症状: API呼び出し時のCORSエラー
# 解決: backend/main.pyのCORS設定確認
# 開発時は --web-browser-flag "--disable-web-security" 使用
```

#### 3. 音声録音エラー
```bash
# 症状: マイク許可・録音失敗
# 解決: HTTPS環境での実行確認
# Chrome: chrome://settings/content/microphone で許可確認
```

#### 4. PDF生成エラー
```bash
# 症状: WeasyPrint PDF生成失敗
# 解決: 日本語フォント確認
pip install weasyprint
# フォントパス確認: /usr/share/fonts/
```

### デバッグ手順

#### フロントエンド
```bash
# Chrome DevTools使用
# Console, Network, Application タブ活用
# Flutter Inspector使用（VS Code拡張）
```

#### バックエンド
```bash
# ログ確認
tail -f backend/functions/logs/app.log

# デバッガー使用
python -m pdb main.py
```

---

## 🚀 デプロイ

### ステージング環境

```bash
# 自動デプロイ（developブランチ）
git push origin develop

# 手動デプロイ
./scripts/deploy.sh staging
```

### 本番環境

```bash
# 自動デプロイ（mainブランチ）
git push origin main

# 手動デプロイ
./scripts/deploy.sh production
```

---

## 📊 パフォーマンス最適化

### フロントエンド

```bash
# ビルド最適化
flutter build web --release --dart-define=FLUTTER_WEB_USE_SKIA=true

# バンドルサイズ分析
flutter build web --analyze-size
```

### バックエンド

```bash
# プロファイリング
python -m cProfile -o profile.stats main.py

# メモリ使用量監視
pip install memory-profiler
python -m memory_profiler main.py
```

---

## 🔐 セキュリティ

### APIキー管理

```bash
# 環境変数使用
export GEMINI_API_KEY=your_key_here
export FIREBASE_API_KEY=your_key_here

# .env ファイル使用（本番環境）
# 絶対にGitにコミットしない
```

### HTTPS設定

```bash
# 開発環境でHTTPS使用
flutter run -d chrome --web-port 8080 --web-hostname localhost

# 本番環境: Firebase Hosting自動HTTPS
```

---

## 📞 サポート

### 開発チーム連絡先
- **技術的質問**: [GitHub Issues](https://github.com/kamekamek/yutorikyoshitu/issues)
- **緊急時**: プロジェクトSlack #dev-support

### 参考資料
- **[システム設計](system_architecture.md)** - 技術アーキテクチャ
- **[テストガイド](testing_guide.md)** - テスト実行・品質管理
- **[完了報告書](archive/PROJECT_COMPLETION_SUMMARY.md)** - プロジェクト履歴

---

**🎯 開発効率化: 環境構築30分、開発サイクル高速化を実現！** 