# 学校だよりAI ― 技術要件完全版シート (2025-06-08)

**カテゴリ**: REQUIREMENT | **レイヤー**: SUMMARY | **更新**: 2025-06-09  
**担当**: 亀ちゃん | **依存**: なし | **タグ**: #requirement #ai #education

## 🎯 TL;DR（30秒で読める要約）

- **目的**: 学級通信作成時間を2-3時間から20分に短縮するAIシステム
- **対象**: 全プロジェクトメンバー  
- **成果物**: 音声入力→AI生成→WYSIWYG編集の完全フロー
- **次のアクション**: 各技術仕様書で詳細確認・実装開始

## 🔗 関連ドキュメント

| 種別 | ファイル名 | 関係性 |
|------|-----------|--------|
| 派生 | 20_SPEC_quill_summary.md | エディタ仕様 |
| 派生 | 21_SPEC_ai_prompts.md | AIプロンプト仕様 |
| 派生 | 24_SPEC_adk_multi_agent.md | マルチエージェント仕様 |
| 派生 | 50_STRATEGY_implementation.md | 実装戦略 |

*Notion へそのまま貼り付けられる Markdown 形式*

---

## 0. 目的とゴール

| 項目        | 内容                                                                            |
| --------- | ----------------------------------------------------------------------------- |
| **課題**    | 学級通信・学年通信・学校通信の作成に 2-3 時間かかる／Word 格闘でレイアウト崩れ                                  |
| **ゴール**   | **20 分以内**でドラフト完成＋編集体験は Google Docs / Sites 風の WYSIWYG<br>教師の残業削減 & 保護者との接点強化 |
| **AI 価値** | 音声入力 → **Vertex AI (将来ADK拡張)** → HTML ドラフト生成 → AI 補助 UI で文章提案・リライト                             |

---

## 1. エンドツーエンド フロー

```plaintext
Phase 1 (MVP):
スマホ録音
    ↓  Google STT
文字起こし
    ↓  Vertex AI Gemini Pro
HTMLドラフト
    ↓
PC編集画面
┌─────────────────────────┐
│ 左：Quill.js WYSIWYG + AI補助UI       │
│ 右：リアルタイム HTML プレビュー       │
└─────────────────────────┘
    ↓
PDF 出力 / Drive 保存 / Classroom 転送

Phase 2 (将来拡張):
スマホ録音
    ↓  Google STT
文字起こし
    ↓  Content Analyzer Agent (ADK)
構造化データ
    ↓  マルチエージェント協調処理
    ┌─ Style Writer Agent
    ├─ Layout Designer Agent  
    ├─ Fact Checker Agent
    └─ Engagement Optimizer Agent
最適化HTMLドラフト
    ↓
PC編集画面 → PDF出力
```

## 📊 メタデータ

- **複雑度**: High
- **推定読了時間**: 15分
- **更新頻度**: 低

---

## 2. 技術アーキテクチャ（概要）

```
┌──────────────┐  録音ファイル  ┌─────────────────┐
│ Flutter (Mobile) │──────────→│ Google STT API     │
└──────────────┘   テキスト    └─────────────────┘
        │                               │
        │ REST/HTTP                     ▼
        │                      ┌─────────────────┐
        └──────────────→│ Cloud Run (Pre-proc) │
                               └─────────────────┘
                                        │
                                        ▼
                              ┌─────────────────┐
                              │ Vertex AI       │
                              │ (Gemini Pro)    │
                              └─────────────────┘
                                        │ HTML
┌──────────────────────────────┐         ▼
│ Flutter Web (+WebView)       │  ┌─────────────────┐
│ • Quill.js WYSIWYG           │  │ Firebase Storage│←─ delta.json / content.html
│ • AI補助UI (折りたたみ)      │  └─────────────────┘
│ • HTML Preview               │          ▲
└──────────────────────────────┘          │ メタ
                                        ┌─────────────────┐
                                        │ Firestore       │
                                        └─────────────────┘
```

---

## 3. 技術ブロック要件

| # | ブロック             | 技術スタック                                          | 主担当        | 注意点                                      |
| - | ---------------- | ----------------------------------------------- | ---------- | ---------------------------------------- |
| 1 | 音声録音→STT         | Flutter 録音 + Google STT                         | 亀ちゃん       | 録音停止後即アップロード                             |
| 2 | ユーザー辞書＋Section分け | Python or Dart 前処理                              | 山谷→統合:亀ちゃん | 誤変換補正＋見出し抽出                              |
| 3 | AI文章整形           | **Google ADK マルチエージェント** + Gemini Pro                          | 亀ちゃん       | エージェント協調による高品質化                        |
| 4 | 編集画面             | **Quill.js** (Snow) + WebView                   | 亀ちゃん       | delta→HTML 整形時に余計な div/style 削除          |
| 5 | AI補助UI           | 折りたたみ（モーダル可）+ Gemini 呼出                         | 亀ちゃん       | 挿入は必ず Quill に経由させ Preview と同期            |
| 6 | データ保存            | **Firestore (メタ)** + **Storage (HTML & delta)** | 亀ちゃん       | 更新は Firestore ↔ Storage 同期 1 本化          |
| 7 | 出力               | html-to-pdf ライブラリ + Drive API + Classroom API   | 亀ちゃん       | MVP = PDF+Drive；Classroom は Nice-to-Have |

---

## 4. 編集 UI 詳細（Figma 風レイアウト）

```

```

---

## 5. Firebase データモデル

### Firestore: `/letters/{documentId}`

| フィールド                 | 型              | 説明                |
| --------------------- | -------------- | ----------------- |
| documentId            | string         | UUID              |
| title                 | string         | 例: 学級通信 6月号       |
| author                | string         | 教師名               |
| grade                 | string         | 例: 3年1組           |
| createdAt / updatedAt | timestamp      |                   |
| status                | string         | draft / published |
| aiVersion             | string         | gemini-pro-v1.5   |
| sections              | array\<string> | 見出しリスト            |

### Storage

```
/documents/{documentId}/content.html   ← Quill HTML
/documents/{documentId}/delta.json    ← Quill delta (バックアップ用)
```

---

## 6. Gemini プロンプト（編集用 HTML 制約）

```
あなたは小学校の学級通信を作る AI です。
# 制約
・使用タグ: <h1>〜<h3>, <p>, <ul>/<ol>/<li>, <strong>, <em>, <br>
・style/class/div タグ禁止
・<html>タグ不要、本文のみ出力
# 出力形式例
<h1>学級通信 6月号</h1>
<p>皆さんこんにちは…</p>
...
```

---

## 7. 実装開始までのプロセス（省略なし）

1. **方針確定**

   * 本シートを全員で読み合わせ→合意
   * AI補助 UI は「折りたたみボタン型」から着手と決定
2. **ライブラリ試作**

   * Quill.js を Flutter WebView に仮組み
   * Gemini から HTML 出力テスト（タグ制約 OK か検証）
3. **UI モック確定**

   * 上記レイアウトを Figma に清書 → チームレビュー → Fix
4. **Firebase 設計実装**

   * Firestore コレクション & Storage パス作成
   * HTML/delta 保存・読み込みの雛形コード完成
5. **タスク分解 & 担当割当**

   * ブロック表を粒度細分化 → Asana/Notion にタスク化
   * 進捗ガント & デイリースタンドアップ運用開始
6. **MVP コーディング**

   * 音声→STT→Gemini 連携パイプ完成
   * 編集画面 (左 Quill / 右 Preview) 動作
   * Firebase 保存／ロード往復
   * PDF+Drive 出力
7. **ユーザーテスト & フィードバック反映**

   * 6/14 までに教師テスター 7 名以上で検証
   * UI/UX 改善 → 最終デモ準備

---

## 8. 注意ポイント（要周知）

* **Quill delta → HTML 整形** 時に div/style 付与されやすい → 必ず整形関数で削除
* **AI 挿入文は Quill 経由** → Preview へ一元反映し「二重管理」事故を防止
* **Firestore/Storage 同期** はトランザクション or Cloud Function で担保
* **AI バージョン管理** (aiVersion) は将来の再生成トレーサビリティに必須

---
