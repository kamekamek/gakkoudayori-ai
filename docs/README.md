# 学校だよりAI 実装ガイド

## プロジェクト概要

「学校だよりAI」は、音声入力から始まりGemini AIによるコンテンツ生成・編集を経て、グラレコ風学級通信をHTMLで作成するシステムです。このプロジェクトの目標は、先生が2-3時間かけていた学級通信作成を**20分以内**で完了できるようにすることです。

## 実装方針

プロジェクトは以下のフェーズで段階的に再構築します。

### フェーズ1: 初期化と基盤構築

- Flutterプロジェクト構造整理
- Quill.jsとWebViewの統合準備
- バックエンドAPI設計

### フェーズ2: Quill.js統合

- WebViewでのQuill.js実装
- デルタ形式とHTMLの双方向変換
- 季節テーマ適用機能

### フェーズ3: AI補助UI

- 折りたたみパネルUI実装
- Gemini API呼び出し
- 結果のエディタ挿入

### フェーズ4: ストレージと出力

- Firestore/Storage保存
- PDF生成
- Google連携

## 技術スタック

- **フロントエンド**: Flutter Web
- **エディタ**: Quill.js (Snow theme)
- **バックエンド**: FastAPI on Cloud Run
- **AI**: Vertex AI (Gemini 1.5 Pro)
- **音声認識**: Google Speech-to-Text
- **ストレージ**: Firestore, Cloud Storage
- **認証**: Firebase Authentication

## 実装リソース

### 1. 要件・設計仕様書

- [実装計画](implementation_plan.md) - 全体実装計画
- [技術要件](01_REQUIREMENT.md) - 詳細な技術要件書

### 2. コンポーネント仕様書

- [Quill.js統合仕様](specs/quill_integration.md) - エディタ実装仕様
- [AI補助UI仕様](specs/ai_assistant_panel.md) - 折りたたみパネル仕様
- [AIプロンプト仕様](specs/ai_prompts.md) - Geminiプロンプト設計

### 3. デザイン資料

- [季節カラーパレット](design/color_palettes.md) - 季節ごとの色彩設計

## 開発ガイドライン

### コーディング規約

- **Dart/Flutter**: [公式スタイルガイド](https://dart.dev/guides/language/effective-dart/style)に準拠
- **Python/FastAPI**: [PEP 8](https://www.python.org/dev/peps/pep-0008/)に準拠
- **HTML/CSS**: [Google HTML/CSS Style Guide](https://google.github.io/styleguide/htmlcssguide.html)に準拠

### ブランチ戦略

- `main`: 本番環境用の安定ブランチ
- `develop`: 開発用統合ブランチ
- `feature/*`: 機能開発用ブランチ
- `hotfix/*`: 緊急修正用ブランチ

### 実装順序

1. まずプロジェクト構造を整理
2. Quill.js + WebViewの基本統合
3. 機能を小さな単位で段階的に実装
4. テストをしながら進める

## 開始方法

### 開発環境セットアップ

```bash
# プロジェクトのクローン
git clone https://github.com/your-org/school-letter-ai.git
cd school-letter-ai

# フロントエンド依存関係のインストール
cd frontend
flutter pub get

# バックエンド依存関係のインストール
cd ../backend
python -m venv venv
source venv/bin/activate  # Windowsの場合: venv\Scripts\activate
pip install -r requirements.txt
```

### 開発サーバー起動

```bash
# フロントエンド開発サーバー
cd frontend
flutter run -d chrome

# バックエンド開発サーバー
cd backend
uvicorn main:app --reload
```

## コントリビューション

1. 適切な`feature`ブランチを作成
2. コーディング規約に従ってコードを実装
3. テストを追加・実行
4. Pull Requestを送信

## ライセンス

本プロジェクトは[MITライセンス](LICENSE)のもとで公開されています。 