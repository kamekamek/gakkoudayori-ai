# ゆとり職員室

**HTMLベースグラレコ風学級通信作成システム**

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

音声入力 → AIチャット編集 → グラレコ風HTML → PDF配信

**→ 先生が子どもと向き合う「ゆとり」を創出！**

---

## ✨ 主要機能

### 🎤 音声入力
- **ワンタップ録音**: 簡単な音声入力でコンテンツ作成
- **リアルタイム字幕**: 発話内容を即座にテキスト化
- **ノイズ抑制**: 教室環境でも高精度な音声認識
- **ユーザー辞書**: 学校固有の用語・名前の認識率向上

### 🤖 AI編集
- **自動リライト**: Gemini 1.5 Proによる自然な文章調整
- **カスタム指示**: 「やさしい語り口」等のワンフレーズ反映
- **チャット編集**: 対話形式での差分表示・リアルタイム編集
- **見出し生成**: コンテンツを自動分析して適切な見出し提案

### 🎨 グラレコ風HTML
- **WYSIWYG エディタ**: リアルタイムプレビュー対応
- **季節テンプレート**: 春夏秋冬の色彩・アイコンセット
- **手描き風素材**: 豊富なSVGアイコン・吹き出し・装飾
- **自動レイアウト**: 「全まかせボタン」で最適デザイン生成

### 📤 自動配信
- **複数フォーマット**: HTML・PDF同時生成
- **Google Classroom**: 投稿・ファイル添付・生徒通知
- **Google Drive**: 月別フォルダ自動振り分け・共有設定
- **LINE通知**: 保護者への配信完了通知（オプション）

---

## 🏗️ 技術スタック

### **ハッカソン必須要件対応**
- ✅ **Google Cloud Run**: メインアプリケーション基盤
- ✅ **Vertex AI Gemini 1.5 Pro**: テキスト生成・リライト
- ✅ **Speech-to-Text**: 音声認識
- ✅ **Flutter Web**: 特別賞対象フロントエンド
- ✅ **Firebase**: 特別賞対象（Authentication・Firestore）

### **アーキテクチャ**
```
Flutter Web App
    ↓ HTTPS API
Cloud Run (FastAPI)
    ↓ 
┌─ Vertex AI ────┬─ Cloud Storage ──┬─ Firestore ─┐
│  - Gemini      │  - 月別管理      │  - ユーザー  │
│  - STT/TTS     │  - ファイル保存   │  - 履歴管理   │
└────────────────┴───────────────────┴──────────────┘
```

---

## 🚀 クイックスタート

### 📖 ドキュメント読み方

**🎬 新規参加者**
1. [📏 ハッカソンルール](docs/hackason_rule.md) - 制約・要件理解
2. [📝 要件定義](docs/REQUIREMENT.md) - プロジェクト全体把握  
3. [🏗️ システム設計](docs/system_design.md) - 技術アーキテクチャ
4. [📋 タスクリスト](docs/tasks.md) - 現在の進捗・次のアクション

**💻 開発開始**
1. [📋 今日のタスク](docs/tasks.md) - 実装すべき内容確認
2. [🧪 TDD実践ガイド](docs/tdd_guide.md) - テスト駆動開発方法
3. [🏗️ システム設計](docs/system_design.md) - 実装仕様確認

### 🛠️ 開発環境構築

```bash
# 1. プロジェクトクローン
git clone https://github.com/kamekamek/yutorikyoshitu.git
cd yutorikyoshitu

# 2. Flutter環境
cd frontend
flutter pub get
flutter run -d chrome

# 3. Python環境 
cd ../backend
pip install -r requirements.txt
uvicorn main:app --reload

# 4. Google Cloud設定
gcloud auth login
gcloud config set project YOUR_PROJECT_ID

# 5. 開発品質ツール設定
pip install pre-commit
pre-commit install
```

### 🔄 CI/CD パイプライン

**自動化されたワークフロー**
- ✅ **継続的インテグレーション**: プッシュ・PR時の自動テスト
- ✅ **静的解析**: Flutter analyze・flake8・black・mypy
- ✅ **テストカバレッジ**: 80%以上の品質保証
- ✅ **自動デプロイ**: Firebase Hosting への自動デプロイ
- ✅ **依存関係管理**: Dependabot による週次更新
- ✅ **セキュリティ**: 秘密情報検出・脆弱性スキャン

**品質ゲート**
```bash
# ローカル品質チェック
cd frontend && flutter analyze && flutter test
cd backend && flake8 . && black --check . && pytest
```

### 📊 現在の進捗

| フェーズ | 期間 | 状況 | 主要成果物 |
|---------|------|------|-----------|
| **要件定義** | - | ✅ 完了 | 14機能要件・非機能要件 |
| **システム設計** | - | ✅ 完了 | API・データ・セキュリティ設計 |
| **タスク分解** | - | ✅ 完了 | 79タスク・4フェーズ |
| **Phase 1** | Week 1-2 | 🚀 準備中 | 基盤構築・基本API |
| **Phase 2** | Week 3-4 | ⏳ 待機中 | HTMLエディタ・チャット編集 |
| **Phase 3** | Week 5 | ⏳ 待機中 | レイアウト自動生成・PDF |
| **Phase 4** | Week 6 | ⏳ 待機中 | 統合・最適化・提出準備 |

---

## 📋 今週のフォーカスタスク

**Phase 1: 基盤構築**
1. 🔴 Google Cloud プロジェクト作成・Vertex AI有効化
2. 🔴 Flutter Web プロジェクト初期化・Firebase接続
3. 🔴 FastAPI バックエンド・基本API実装
4. 🔴 Speech-to-Text・Gemini統合・動作確認
5. 🔴 Firebase Authentication・基本UI構築

**詳細は [📋 tasks.md](docs/tasks.md) を参照**

---

## 🎖️ ハッカソン適合性

### ✅ 必須条件クリア
- **Google Cloud アプリケーション**: Cloud Run ✅
- **Google Cloud AI**: Vertex AI・Speech-to-Text ✅

### 🏆 特別賞対象
- **Flutter賞**: Flutter Web使用 ✅
- **Firebase賞**: Authentication・Firestore使用 ✅
- **Deep Dive賞**: 複数Google Cloudサービス活用 ✅

---

## 📚 ドキュメント構成

| ドキュメント | 説明 | 対象 |
|------------|------|------|
| **[📋 Index](docs/index.md)** | エントリーポイント | 全員 |
| **[📖 Overview](docs/README.md)** | 全体ナビゲーション | 全員 |
| **[📝 要件定義](docs/REQUIREMENT.md)** | 14機能要件・画面設計 | 全員 |
| **[🏗️ システム設計](docs/system_design.md)** | API・データ・セキュリティ | 開発者 |
| **[📋 タスク](docs/tasks.md)** | 79実装タスク・進捗管理 | 開発者 |
| **[🧪 TDD](docs/tdd_guide.md)** | テスト駆動開発実践 | 開発者 |
| **[🚀 将来拡張](docs/future_extensions.md)** | ADKマルチエージェント | 設計者 |
| **[📏 ハッカソンルール](docs/hackason_rule.md)** | 制約・技術要件 | 全員 |

---

## 🤝 コントリビューション

### 📋 タスク管理
- 毎日 [tasks.md](docs/tasks.md) で進捗更新
- 4つの完了条件すべて満たしてからタスクチェック
- TDD必須（🔴 Red → 🟢 Green → 🔵 Refactor）

### 🔧 開発ワークフロー
1. 今日のタスク確認
2. TDD実践でコード実装
3. テスト通過・品質確認
4. 実際の使用シナリオで動作検証
5. 完了条件満たしてタスク完了

---

## 📞 サポート・質問

- **設計・仕様**: [system_design.md](docs/system_design.md) 参照
- **実装方法**: [tdd_guide.md](docs/tdd_guide.md) 参照  
- **進捗確認**: [tasks.md](docs/tasks.md) 参照
- **ハッカソン要件**: [hackason_rule.md](docs/hackason_rule.md) 参照

---

## 📜 ライセンス

MIT License - Google Cloud Japan AI Hackathon Vol.2 提出用

---

**🎉 ゴール: 先生が子どもと向き合う「ゆとり」を創出する学級通信システムの実現！**
