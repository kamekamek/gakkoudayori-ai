# 学校だよりAI ― 技術要件完全版シート (2025-06-08)

*Notion へそのまま貼り付けられる Markdown 形式*

---

## 0. 目的とゴール

| 項目 | 内容 |
|------|------|
| 課題 | 学級通信・学年通信・学校通信の作成に 2-3 時間かかる／Word 格闘でレイアウト崩れ |
| ゴール | 20 分以内でドラフト完成＋編集体験は Google Docs / Sites 風の WYSIWYG教師の残業削減 & 保護者との接点強化 |
| AI 価値 | 音声入力 → Gemini が HTML ドラフト生成 → AI 補助 UI で文章提案・リライト |

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
   - 本シートを全員で読み合わせ→合意
   - AI補助 UI は「折りたたみボタン型」から着手と決定

2. **ライブラリ試作**
   - Quill.js を Flutter WebView に仮組み
   - Gemini から HTML 出力テスト（タグ制約 OK か検証）

3. **UI モック確定**
   - 上記レイアウトを Figma に清書 → チームレビュー → Fix

4. **Firebase 設計実装**
   - Firestore コレクション & Storage パス作成
   - HTML/delta 保存・読み込みの雛形コード完成

5. **タスク分解 & 担当割当**
   - ブロック表を粒度細分化 → Asana/Notion にタスク化
   - 進捗ガント & デイリースタンドアップ運用開始

6. **MVP コーディング**
   - 音声→STT→Gemini 連携パイプ完成
   - 編集画面 (左 Quill / 右 Preview) 動作
   - Firebase 保存／ロード往復
   - PDF+Drive 出力

7. **ユーザーテスト & フィードバック反映**
   - 6/14 までに教師テスター 7 名以上で検証
   - UI/UX 改善 → 最終デモ準備

---

## 8. 注意ポイント（要周知）

- **Quill delta → HTML 整形** 時に div/style 付与されやすい → 必ず整形関数で削除
- **AI 挿入文は Quill 経由** → Preview へ一元反映し「二重管理」事故を防止
- **Firestore/Storage 同期** はトランザクション or Cloud Function で担保
- **AI バージョン管理** (aiVersion) は将来の再生成トレーサビリティに必須

---