# 学校だよりAI

**AIによる学級通信自動生成システム**

*Google Cloud Japan AI Hackathon Vol.2 提出プロジェクト*

<div align="center">

![Logo](https://img.shields.io/badge/Google%20Cloud-AI%20Hackathon%20Vol.2-4285F4?style=for-the-badge&logo=googlecloud&logoColor=white)
![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-039BE5?style=for-the-badge&logo=Firebase&logoColor=white)
![Vertex AI](https://img.shields.io/badge/Vertex%20AI-4285F4?style=for-the-badge&logo=googlecloud&logoColor=white)

</div>

---

## 🎯 プロジェクトゴール

**「学級通信作成時間を従来の2-3時間から20分以内に短縮」**

音声入力 → AI文章生成 → WYSIWYG編集 → PDF出力

**→ 先生が子どもと向き合う時間を創出！**

---

## ✨ 主要機能

### 🎤 音声入力
- **ワンタップ録音**: 簡単な音声入力でコンテンツ作成
- **リアルタイム文字起こし**: Google Speech-to-Text API統合
- **ノイズ抑制**: 教室環境でも高精度な音声認識
- **ユーザー辞書**: 学校固有の用語・名前の認識率向上

### 🤖 AI文章生成
- **自動リライト**: Gemini 1.5 Proによる自然な文章調整
- **学級通信特化**: 教育現場に適した文体・構成自動生成
- **カスタム指示**: 「やさしい語り口」等のワンフレーズ反映
- **リアルタイム編集**: 対話形式での差分表示・即座反映

### 🎨 WYSIWYG編集
- **Quill.jsエディタ**: プロ仕様のリッチテキスト編集
- **季節テンプレート**: 春夏秋冬の色彩・アイコンセット
- **インライン編集**: クリックで直接編集可能
- **Delta/HTML変換**: 高品質なレイアウト保持

### 📄 PDF出力・配信
- **高品質PDF**: WeasyPrintによるA4最適化レイアウト
- **日本語フォント**: NotoSansCJK完全対応
- **自動レイアウト**: 季節テーマ色彩・装飾自動反映
- **ワンクリック配信**: PDF生成・ダウンロード・共有

---

## 🏗️ 技術スタック

### **ハッカソン必須要件対応**
- ✅ **Google Cloud Platform**: Vertex AI + Speech-to-Text
- ✅ **Vertex AI Gemini 1.5 Pro**: テキスト生成・リライト
- ✅ **Flutter Web**: 特別賞対象フロントエンド
- ✅ **Firebase**: 特別賞対象（Authentication・Firestore・Storage）

### **アーキテクチャ**
```
Flutter Web App (フロントエンド)
    ↓ HTTPS API
FastAPI Backend (バックエンド)
    ↓ 
┌─ Vertex AI ────┬─ Firebase ──────┬─ WeasyPrint ─┐
│  - Gemini Pro  │  - Auth         │  - PDF生成    │
│  - STT API     │  - Firestore    │  - 日本語対応  │
│                │  - Storage      │              │
└────────────────┴─────────────────┴──────────────┘
```

---

## 🚀 クイックスタート

### 📖 ドキュメント

**🎬 新規参加者**
1. [📚 ドキュメント一覧](docs/README.md) - 全体ナビゲーション
2. [📏 ハッカソンルール](docs/HACKASON_RULES.md) - 制約・要件理解
3. [🏆 プロジェクト完了報告](docs/archive/PROJECT_COMPLETION_SUMMARY.md) - 最終成果物

**💻 開発者**
1. [📋 開発ガイド](docs/development_guide.md) - 環境構築・開発手順
2. [🏗️ システム設計](docs/system_architecture.md) - 技術アーキテクチャ
3. [🧪 テストガイド](docs/testing_guide.md) - テスト実行・品質管理

### 🛠️ 開発環境構築

```bash
# 1. プロジェクトクローン
git clone https://github.com/kamekamek/gakkoudayori-ai.git
cd gakkoudayori-ai

# 2. 環境設定確認
./scripts/check_env.sh

# 3. APIキー設定
export GEMINI_API_KEY=your_api_key_here
export SPEECH_TO_TEXT_API_KEY=your_api_key_here

# 4. 開発環境起動
make dev
```

### 🎉 プロジェクト完了状況

**🏆 全62タスク完了 (100%) - プロジェクト完成** ✅

| 機能カテゴリ | 状況 | 主要成果物 |
|------------|------|-----------|
| **音声入力システム** | ✅ 完了 | Web Audio API統合・STT連携 |
| **AI文章生成** | ✅ 完了 | Gemini Pro完全統合・学級通信特化 |
| **WYSIWYGエディタ** | ✅ 完了 | Quill.js・Delta/HTML変換・季節テーマ |
| **PDF出力配信** | ✅ 完了 | WeasyPrint・日本語フォント・A4最適化 |
| **Firebase統合** | ✅ 完了 | 認証・Firestore・Storage完全連携 |
| **レスポンシブUI** | ✅ 完了 | PC/タブレット/モバイル完全対応 |

---

## 🎖️ ハッカソン適合性

### ✅ 必須条件クリア
- **Google Cloud アプリケーション**: Vertex AI・Speech-to-Text ✅
- **AI機能活用**: Gemini 1.5 Pro完全統合 ✅

### 🏆 特別賞対象
- **Flutter賞**: Flutter Web使用 ✅
- **Firebase賞**: Authentication・Firestore・Storage使用 ✅
- **Deep Dive賞**: 複数Google Cloudサービス活用 ✅

---

## 🔐 セキュリティ・設定管理

### Firebase設定

Firebase設定ファイル `frontend/lib/firebase_options.dart` の管理：

```bash
# テンプレートから実際の設定ファイルを作成
cp frontend/lib/firebase_options.dart.template frontend/lib/firebase_options.dart

# 実際のFirebase設定値を設定（エディタで編集）
# - API Key: AIzaSyAROJC6oomnN4tl1Sv27fcE5yaB_vIzXxc
# - Project ID: yutori-kyoshitu
# - App ID: 1:309920383305:web:fa0ae9890d4e7bf2355a98
```

### 環境変数

```bash
# Frontend (.env)
FIREBASE_API_KEY=your_api_key_here
FIREBASE_PROJECT_ID=your_project_id_here

# Backend (backend/functions/.env)
GOOGLE_CLOUD_PROJECT=your_project_id_here
GEMINI_API_KEY=your_gemini_api_key_here
```

---

## 🤝 コントリビューション

### 🔧 開発ワークフロー
1. **ブランチ作成**: `git checkout -b feature/your-feature`
2. **開発・テスト**: TDD実践でコード実装
3. **品質確認**: `make lint && make test`
4. **プルリクエスト**: mainブランチへのPR作成

### 📋 品質基準
- **テストカバレッジ**: 80%以上維持
- **静的解析**: Flutter analyze・flake8・black通過
- **パフォーマンス**: 音声→PDF生成20秒以内

---

## 📞 サポート・質問

- **開発手順**: [開発ガイド](docs/development_guide.md)参照
- **技術仕様**: [システム設計](docs/system_architecture.md)参照  
- **プロジェクト履歴**: [完了報告書](docs/archive/PROJECT_COMPLETION_SUMMARY.md)参照
- **ハッカソン要件**: [ハッカソンルール](docs/HACKASON_RULES.md)参照

---

## 📜 ライセンス

MIT License - Google Cloud Japan AI Hackathon Vol.2 提出用

---

**🎯 ゴール達成: 学級通信作成時間を2-3時間から20分以内に短縮！**
