# 学校だよりAI ドキュメント

[![Google Cloud](https://img.shields.io/badge/Google%20Cloud-Powered-blue)](https://cloud.google.com)
[![Flutter](https://img.shields.io/badge/Flutter-Web-02569B)](https://flutter.dev)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

## 🎯 プロジェクト概要

**学校だよりAI**は、教師が音声入力とAIを活用して効率的に学級通信を作成できるWebアプリケーションです。従来2-3時間かかっていた作成時間を**20分以内**に短縮し、教師の働き方改革を支援します。

### 主な特徴

- 🎤 **音声入力**: スマートフォンから簡単に音声で内容を入力
- 🤖 **AI支援**: Google Gemini AIが文章を自動整形・リライト
- ✏️ **WYSIWYG編集**: Quill.jsベースの直感的なエディタ
- 📄 **PDF出力**: A4フォーマットで印刷用PDFを自動生成
- 🚀 **配信機能**: Google ClassroomやLINEへの自動配信（開発中）

## 📚 ドキュメント構成

### 🚀 はじめに

- [プロジェクト概要](getting-started/overview.md) - プロジェクトの目的と全体像
- [クイックスタート](getting-started/quickstart.md) - 開発環境のセットアップと初回起動

### 📖 開発ガイド

- [AI機能ワークフロー](guides/ai-workflow.md) - 音声認識からAI処理までの流れ
- [エディタ機能](guides/editing.md) - Quill.jsエディタの使い方と拡張

### 📋 リファレンス

- [APIエンドポイント](reference/api/endpoints.md) - バックエンドAPI仕様
- [データモデル](reference/schema/data-model.md) - Firestoreスキーマ定義

### 🏗️ アーキテクチャ

- [アーキテクチャ決定記録](adr/) - 重要な技術的決定の記録
- [UI/UXデザイン](design/ui-mockups/) - 画面設計とモックアップ

### 📢 リリース情報

- [リリースノート](release-notes/v0.1.0.md) - バージョンごとの変更履歴

## 🛠️ 技術スタック

| レイヤー | 技術 | 説明 |
|---------|------|------|
| フロントエンド | Flutter Web | クロスプラットフォーム対応のWebアプリ |
| エディタ | Quill.js | リッチテキストエディタ |
| バックエンド | Python FastAPI | Cloud Run上で動作するAPI |
| AI/ML | Google Vertex AI | Gemini Pro、Speech-to-Text |
| データベース | Cloud Firestore | NoSQLドキュメントDB |
| ストレージ | Cloud Storage | ファイル保存用 |
| 認証 | Firebase Auth | Google認証・匿名認証 |

## 🎯 プロジェクトゴール

1. **作成時間の短縮**: 2-3時間 → 20分以内
2. **使いやすさ**: 技術に詳しくない教師でも直感的に使える
3. **品質向上**: AIによる文章整形で読みやすい通信を作成
4. **配信の簡素化**: 印刷・デジタル配信を一元化

## 🤝 コントリビューション

本プロジェクトは**Google Cloud Japan AI Hackathon Vol.2**向けに開発されました。

### 開発チーム

- プロジェクトリード: 亀ちゃん
- 開発環境: Google Cloud Platform
- ライセンス: MIT License

## 📞 お問い合わせ

質問や提案がある場合は、GitHubのIssueを作成してください。

---

*最終更新: 2025年6月20日*