最初の一段落まとめ
本仕様書は、小学校教員が Flutter アプリから週報メモを送信すると、Google ADK で実装した **InfoAgent → HtmlBuilderAgent** の2ステップパイプラインが Cloud Functions 上で実行され、Cloud Firestore／Storage に **Outline JSON → HTML ニュースレター** を蓄積し、アプリ側は `webview_flutter` で即時プレビューできるフルスタック構成を定義します。PDF 変換は独立関数 `/api/pdf` で WeasyPrint に委譲し、Firestore ルールで `teacherId == request.auth.uid` を強制。すべての入出力は Pydantic でスキーマ駆動、SequentialAgent の `output_key` で状態遷移を共有するため拡張が容易です。([google.github.io][1], [google.github.io][1], [zenn.dev][2], [firebase.google.com][3], [firebase.google.com][4], [chartjs.org][5], [pub.dev][6], [firebase.google.com][7], [firebase.google.com][8], [docs.pydantic.dev][9])

## 1. プロダクト概要

* **ユーザー**: 小学校教員
* **目的**: 週次学級通信を半自動で作成し、HTML で編集・プレビュー、必要に応じ PDF 配布
* **機能フロー**:

  1. 先生が自由メモを入力 *(Flutter → Firestore)*
  2. InfoAgent が不足を質問し `Outline` を生成 *(Cloud Functions)* ([google.github.io][1])
  3. HtmlBuilderAgent が Chart.js 付き HTML を生成し Storage へ保存 ([chartjs.org][5])
  4. アプリは HTML を WebView に表示、PDF が必要なら `/api/pdf` を呼び出し WeasyPrint で変換 ([weasyprint.org][10])

## 2. システム構成

```
Flutter (Mobile/Web)
 └─ FirebaseAuth
     └─ Firestore  ←→ Cloud Functions
                      • infoCallable  (InfoAgent)
                      • buildCallable (HtmlBuilderAgent)
                      • pdfCallable   (WeasyPrint)
     └─ Storage  (html / pdf assets)
```

* **SequentialAgent** が InfoAgent ➔ HtmlBuilderAgent を順序実行し `session.state` を継承します ([zenn.dev][2]).
* **Callable Functions** は Firebase SDK から安全に呼び出せ、認証トークンが自動添付されます ([firebase.google.com][3]).

## 3. エージェント定義（Google ADK）

### 3.1 Pydantic スキーマ

```python
class TeacherNote(BaseModel):
    raw_text: str

class Outline(BaseModel):
    week_title: str
    sections: list[str]

class HtmlDoc(BaseModel):
    html: str
```

Pydantic は `model_json_schema()` で JSON Schema を自動生成し ADK が型検証に利用します ([docs.pydantic.dev][9]).

### 3.2 InfoAgent

| パラメータ              | 値                  |
| ------------------ | ------------------ |
| `model`            | `gemini-2.0-pro`   |
| `input_schema`     | `TeacherNote`      |
| `output_schema`    | `Outline`          |
| `output_key`       | `"outline"`        |
| `include_contents` | `'none'`           |
| `planner`          | `BuiltInPlanner()` |

`instruction`: *「不足項目のみ日本語で質問し、完成したらアウトライン JSON だけ返す」*
`planner` により質問→回答→完了の内部ループを自動管理できます ([google.github.io][1]).

### 3.3 HtmlBuilderAgent

| パラメータ           | 値                       |
| --------------- | ----------------------- |
| `input_schema`  | `Outline`               |
| `output_schema` | `HtmlDoc`               |
| `output_key`    | `"html_doc"`            |
| `code_executor` | `BuiltInCodeExecutor()` |

`instruction`: *「Outline を Chart.js CDN、インライン CSS 付きのレスポンシブ HTML に変換し、`{'html': '<!DOCTYPE …>'}` JSON だけ返す」*
Chart.js を CDN 一行で読み込む最小構成を採用します ([chartjs.org][5]).

## 4. Cloud Functions API

| Name              | Trigger                  | Args         | Returns        |
| ----------------- | ------------------------ | ------------ | -------------- |
| **infoCallable**  | `functions.https.onCall` | `{raw_text}` | `Outline` JSON |
| **buildCallable** | `functions.https.onCall` | `{outline}`  | `{html_url}`   |
| **pdfCallable**   | `functions.https.onCall` | `{html_url}` | `{pdf_url}`    |

HTTPS Callable はクライアント SDK 経由で呼び出し、Auth が必須です ([firebase.google.com][11]).

## 5. Firebase データモデル

| Collection    | DocId | フィールド                                    |
| ------------- | ----- | ---------------------------------------- |
| `drafts`      | auto  | `teacherId`, `rawText`, `outline`        |
| `newsletters` | auto  | `teacherId`, `week`, `htmlUrl`, `status` |

Firestore は「小さな JSON ドキュメント + 大量コレクション」に最適化されています ([firebase.google.com][4]).

## 6. Flutter クライアント契約

* **プレビュー**: `webview_flutter` の `WebViewWidget` に `controller.loadHtmlString(html)` を渡して描画 ([pub.dev][6]).
* **リアルタイム更新**: `StreamBuilder` × `Firestore.snapshots()` でドキュメント変更を監視 ([firebase.google.com][7]).
* **状態管理**: 小規模のため `Riverpod` を推奨（コンパイル安全・自動 dispose） ([docs.flutter.dev][12]).
* **編集モード**: WebView 内に `contenteditable` を持つ HTML を注入し、JS ブリッジで Dart に変更を返す ([developer.mozilla.org][13])。高度編集が必要なら headless WYSIWYG の TipTap を iframe で利用できます ([tiptap.dev][14]).

## 7. PDF 変換エンドポイント

* `/api/pdf` Cloud Function が Storage の HTML を WeasyPrint に渡し、CSS レイアウトを保った PDF を生成 ([weasyprint.org][10]).
* 生成後 URL を Firestore に保存し、Flutter がダウンロードリンクを表示。

## 8. セキュリティ

* **Firestore ルール**

  ```rules
  match /newsletters/{docId} {
    allow read, write: if request.auth.uid == resource.data.teacherId;
  }
  ```

  ユーザー ID に基づくアクセス制御例 ([firebase.google.com][15])
* **Storage ルール** 同様に `resource.metadata.teacherId` をチェックして限定 ([firebase.google.com][8]).
* **Cloud Functions** は `context.auth.uid` を検証。

## 9. 受け入れ基準

1. InfoAgent が最大 3 質問で `Outline` を返す。
2. HtmlBuilderAgent が valid HTML5 + Chart.js `<canvas>` を返す。
3. Callable 応答がウォーム時 ≤ 2 秒。
4. Firestore & Storage ルールテストが全通過。
5. Flutter WebView で UTF-8 が欠損しない。

## 10. 運用・デプロイ

* Cloud Functions を `minInstances=0` でコールドスタート最適化、ワークロード増時は Cloud Run 移行も検討。
* Observability は ADK のトレースを Cloud Logging へ送出し、必要に応じ Arize/Phoenix で可視化 ([google.github.io][1]).
* CI/CD は GitHub Actions → `firebase deploy --only functions,firestore,storage`.

## 11. 今後の拡張例

| 機能             | 追加コンポーネント                     | 備考                                   |
| -------------- | ----------------------------- | ------------------------------------ |
| WYSIWYG ブロック編集 | EditorAgent + TipTap          | HtmlDoc + EditInstructions スキーマで差分反映 |
| 共同編集           | Yjs over WebSocket            | Firestore ドキュメントの CRDT sync          |
| 画像アップロード       | Storage Function + signed URL | Chart.js と同ページでレンダリング                |
| テーマ切替          | CSS Variables / Tailwind      | teacher preferences コレクションで保存        |

---

### 使い方（AI への最終プロンプト例）

> **System**: *You are a senior full-stack engineer. Implement the following spec in TypeScript Cloud Functions and Flutter. Follow every schema and API contract precisely.*
> **User**: *<<本仕様書全文>>*
> **Assistant**: *Return repository tree, then each file’s content.*

この指示書を渡せば、生成 AI は ADK エージェント、Cloud Functions、Flutter UI、Firestore ルールまで一貫したコードを出力でき、後続のリファクタやテスト追加も最小限の追記で済みます。

[1]: https://google.github.io/adk-docs/agents/llm-agents/ "LLM agents - Agent Development Kit"
[2]: https://zenn.dev/tetoteto/articles/google-adk-sequential "Google ADK SequentialAgent で出力を安定させる"
[3]: https://firebase.google.com/docs/functions/callable "Call functions from your app  |  Cloud Functions for Firebase"
[4]: https://firebase.google.com/docs/firestore/data-model?hl=ja&utm_source=chatgpt.com "Cloud Firestore データモデル | Firebase"
[5]: https://www.chartjs.org/docs/latest/getting-started/ "Getting Started | Chart.js"
[6]: https://pub.dev/packages/webview_flutter "webview_flutter | Flutter package"
[7]: https://firebase.google.com/docs/firestore/query-data/listen?hl=ja "Cloud Firestore でリアルタイム アップデートを入手する  |  Firebase"
[8]: https://firebase.google.com/docs/storage/security/rules-conditions?utm_source=chatgpt.com "Use conditions in Firebase Cloud Storage Security Rules"
[9]: https://docs.pydantic.dev/latest/concepts/json_schema/?utm_source=chatgpt.com "JSON Schema - Pydantic"
[10]: https://weasyprint.org/?utm_source=chatgpt.com "WeasyPrint"
[11]: https://firebase.google.com/docs/functions/callable?hl=ja "アプリから関数を呼び出す  |  Cloud Functions for Firebase"
[12]: https://docs.flutter.dev/data-and-backend/state-mgmt/options?utm_source=chatgpt.com "List of state management approaches | Flutter"
[13]: https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Global_attributes/contenteditable?utm_source=chatgpt.com "HTML contenteditable global attribute - MDN"
[14]: https://tiptap.dev/product/editor "Tiptap Rich Text Editor - the Headless WYSIWYG Editor"
[15]: https://firebase.google.com/docs/firestore/security/rules-query?hl=ja&utm_source=chatgpt.com "データを安全にクエリする | Firestore | Firebase"

