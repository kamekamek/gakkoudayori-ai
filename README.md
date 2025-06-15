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
1. [📏 ハッカソンルール](docs/HACKASON_RULE.md) - 制約・要件理解
2. [📝 要件定義](docs/REQUIREMENT.md) - プロジェクト全体把握  
3. [🏗️ システム設計](docs/Archive/system_design.md) - 技術アーキテクチャ
4. [📋 タスクリスト](docs/tasks.md) - 現在の進捗・次のアクション

**💻 開発開始**
1. [📋 今日のタスク](docs/tasks.md) - 実装すべき内容確認
2. [🧪 TDD実践ガイド](docs/Archive/tdd_guide.md) - テスト駆動開発方法
3. [🏗️ システム設計](docs/Archive/system_design.md) - 実装仕様確認

### 🛠️ 開発環境構築

```bash
# 1. プロジェクトクローン
git clone https://github.com/kamekamek/yutorikyoshitu.git
cd yutorikyoshitu

# 2. 環境設定確認
./scripts/check_env.sh

# 3. APIキー設定
export GEMINI_API_KEY=your_api_key_here
export SPEECH_TO_TEXT_API_KEY=your_api_key_here

# 4. 開発環境起動
make dev
# または
./scripts/deploy.sh dev all
```

### 📚 詳細なセットアップガイド

初心者向けの詳細なデプロイ手順は以下のドキュメントを参照してください：

- **[🚀 デプロイガイド](docs/deployment_guide.md)** - 初心者向け完全ガイド
- **[🔐 環境変数設定](docs/environment_setup.md)** - APIキー・シークレット設定詳細
- **[🛠️ 便利スクリプト](scripts/)** - 自動化されたデプロイ・確認ツール

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

### 🎉 プロジェクト完了状況

| フェーズ | 期間 | 状況 | 主要成果物 |
|---------|------|------|-----------|
| **要件定義** | - | ✅ 完了 | 14機能要件・非機能要件 |
| **システム設計** | - | ✅ 完了 | API・データ・セキュリティ設計 |
| **基盤実装** | - | ✅ 完了 | Firebase・GCP・Flutter Web基盤 |
| **コア機能** | - | ✅ 完了 | 音声入力・AI生成・Quill.jsエディタ |
| **高度機能** | - | ✅ 完了 | PDF出力・季節テーマ・レスポンシブUI |
| **品質保証** | - | ✅ 完了 | E2Eテスト・パフォーマンス最適化 |

**🏆 全61タスク完了 (100%) - プロジェクト完成** ✅

---

## 🎉 完成機能一覧

**✅ 完全実装済み機能**
1. ✅ **音声入力システム** - リアルタイム録音・STT・ファイルアップロード
2. ✅ **AI文章生成** - Gemini Pro・チャット編集・カスタム指示
3. ✅ **WYSIWYGエディタ** - Quill.js・Delta変換・季節テーマ
4. ✅ **PDF出力配信** - 高品質PDF・日本語フォント・自動レイアウト
5. ✅ **Firebase統合** - 認証・ストレージ・リアルタイムDB
6. ✅ **レスポンシブUI** - 3カラム・PC/タブレット/モバイル対応

**📊 詳細な実装状況は [📋 tasks.md](docs/tasks.md) と [🎉 完了報告書](docs/archive/PROJECT_COMPLETION_SUMMARY.md) を参照**

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
| **[📋 Index](docs/archive/INDEX.md)** | エントリーポイント | 全員 |
| **[📖 Overview](docs/Archive/README.md)** | 全体ナビゲーション | 全員 |
| **[📝 要件定義](docs/REQUIREMENT.md)** | 14機能要件・画面設計 | 全員 |
| **[🏗️ システム設計](docs/Archive/system_design.md)** | API・データ・セキュリティ | 開発者 |
| **[📋 タスク](docs/tasks.md)** | 79実装タスク・進捗管理 | 開発者 |
| **[🧪 TDD](docs/Archive/tdd_guide.md)** | テスト駆動開発実践 | 開発者 |
| **[🚀 将来拡張](docs/Archive/future_extensions.md)** | ADKマルチエージェント | 設計者 |
| **[📏 ハッカソンルール](docs/HACKASON_RULE.md)** | 制約・技術要件 | 全員 |

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

- **設計・仕様**: [system_design.md](docs/Archive/system_design.md) 参照
- **実装方法**: [tdd_guide.md](docs/Archive/tdd_guide.md) 参照  
- **進捗確認**: [tasks.md](docs/tasks.md) 参照
- **ハッカソン要件**: [hackason_rule.md](docs/HACKASON_RULE.md) 参照

---

## 📜 ライセンス

MIT License - Google Cloud Japan AI Hackathon Vol.2 提出用

---

## 🔐 機密情報の管理

### Firebase設定

Firebase設定ファイル `frontend/lib/firebase_options.dart` には機密情報が含まれているため、以下の手順で管理してください：

1. **初回セットアップ時**：
   ```bash
   # テンプレートファイルから実際の設定ファイルを作成
   cp frontend/lib/firebase_options.dart.template frontend/lib/firebase_options.dart
   
   # 実際のFirebase設定値を設定
   # エディタで firebase_options.dart を開き、YOUR_*_HERE を実際の値に置換
   ```

2. **設定値の更新**：
   - API Key: `AIzaSyAROJC6oomnN4tl1Sv27fcE5yaB_vIzXxc`
   - App ID: `1:309920383305:web:fa0ae9890d4e7bf2355a98`
   - Project ID: `yutori-kyoshitu`
   - Auth Domain: `yutori-kyoshitu.firebaseapp.com`
   - Storage Bucket: `yutori-kyoshitu.firebasestorage.app`

3. **セキュリティ注意事項**：
   - `firebase_options.dart` は `.gitignore` に登録済みでGit追跡されません
   - テンプレートファイル `firebase_options.dart.template` のみがバージョン管理対象です
   - 本番環境では環境変数やシークレット管理サービスの使用を推奨

### 環境変数

各環境で `.env` ファイルを作成し、以下の変数を設定してください：

```bash
# Frontend (.env)
FIREBASE_API_KEY=your_api_key_here
FIREBASE_APP_ID=your_app_id_here
FIREBASE_PROJECT_ID=your_project_id_here

# Backend (backend/functions/.env)
GOOGLE_CLOUD_PROJECT=your_project_id_here
FIREBASE_PROJECT_ID=your_project_id_here
```

---

**🎉 ゴール: 先生が子どもと向き合う「ゆとり」を創出する学級通信システムの実現！**
