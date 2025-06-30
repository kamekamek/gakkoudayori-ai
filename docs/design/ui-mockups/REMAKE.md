シンプル実装を最優先しつつ **「学級通信ジェネレーター」** に必要なバックエンドすべてを **Python １本・１コンテナ** にまとめる最終ディレクトリ構成と設計を、公式 ADK／Google API ドキュメントを踏まえて完全に書き起こしました。要点は **FastAPI + Google ADK** がチャット／SSE／AI／PDF／Classroom／STT／Firestore CRUD を一手に受け持ち、Flutter は REST＋SSE だけを呼ぶ――という極小アーキテクチャです。

---

## ディレクトリツリー（完成形）

```text
backend/
├── app/                  # FastAPI エントリ & ルート
│   ├── main.py           # /chat /stream
│   ├── pdf.py            # /pdf          → PdfConverterTool
│   ├── classroom.py      # /classroom    → ClassroomSenderTool
│   ├── stt.py            # /stt          → SttTranscriberTool
│   └── phrase.py         # /phrase       → UserDictRegisterTool
├── agents/               # Google-ADK 規約ルート
│   ├── orchestrator_agent/
│   │   └── agent.py
│   ├── planner_agent/
│   │   ├── agent.py
│   │   └── prompts/planner_instruction.md
│   ├── generator_agent/
│   │   ├── agent.py
│   │   └── prompts/generator_instruction.md
│   └── tools/            # “AI外” からも直接 import
│       ├── html_validator.py
│       ├── pdf_converter.py
│       ├── classroom_sender.py
│       ├── stt_transcriber.py
│       └── user_dict_register.py
├── services/
│   ├── firestore_service.py
│   └── storage.py
├── Dockerfile
└── pyproject.toml
```

---

## 1 FastAPI 層

### 1.1 共通初期化

```python
from fastapi import FastAPI, UploadFile
from adk.runners import Runner
from agents.orchestrator_agent.agent import create_orchestrator_agent

app = FastAPI()
runner = Runner(agent=create_orchestrator_agent())          # ADK Runner:contentReference[oaicite:0]{index=0}
```

### 1.2 チャット & SSE

```python
@app.post("/chat")
async def chat(req: ChatIn):
    await runner.enqueue(req.session, req.message)
    return {"session": req.session}

@app.get("/stream/{sid}")
async def stream(sid: str):
    async def gen():
        async for ev in runner.emit_queue(sid):             # ADK Streaming API:contentReference[oaicite:1]{index=1}
            yield {"data": ev.json(), "event": "message"}
    return EventSourceResponse(gen(), ping=15)              # FastAPI SSE パターン:contentReference[oaicite:2]{index=2}
```

### 1.3 ユーティリティ REST

| ルート                       | 説明                | 内部 Tool 呼び出し                                   |
| ------------------------- | ----------------- | ---------------------------------------------- |
| `/pdf` (`POST`)           | HTML→PDF 変換       | `PdfConverterTool`（pdfkit + wkhtmltopdf）       |
| `/classroom` (`POST`)     | Classroom アナウンス送信 | `ClassroomSenderTool`（Classroom API）           |
| `/stt` (`POST multipart`) | 音声→テキスト           | `SttTranscriberTool`（Cloud Speech / PhraseSet） |
| `/phrase` (`POST`)        | ユーザー辞書登録          | `UserDictRegisterTool`（Speech Adaptation）      |

---

## 2 ADK エージェント

### 2.1 OrchestratorAgent (`agents/orchestrator_agent/agent.py`)

```python
class NewsletterOrchestrator(RunnerAgent):
    async def _run_async_impl(self, ctx):
        txt = ctx.user_message
        if txt.startswith("/create"):
            await ctx.transfer_to_agent("planner_agent")
        elif ctx.artifact_exists("outline.json") and not ctx.artifact_exists("newsletter.html"):
            await ctx.transfer_to_agent("generator_agent")
        elif txt.startswith("/send"):
            course = txt.split()[1]
            await self.call_tool("classroom_post", course, ctx.artifact("newsletter.html").data)
            await ctx.emit({"type":"classroom_ack"})
```

* Runner → Planner → Generator の 3 段は **ADK公式「Agent Team」例** と同型
* `ctx.emit()` がそのまま FastAPI SSE に転送される

### 2.2 Planner & Generator

* **Planner**：質問で JSON 構成出力 → `ctx.save_artifact("outline.json", …)`
* **Generator**：Gemini 2.5 API で Tailwind HTML 作成 → `HtmlValidatorTool` で strict parse

### 2.3 Tool 一覧

| ファイル                    | コア実装                                            | 根拠ドキュメント                       |
| ----------------------- | ----------------------------------------------- | ------------------------------ |
| `html_validator.py`     | `html5lib.HTMLParser(strict=True)`              | HTML5lib docs                  |
| `pdf_converter.py`      | `pdfkit.from_string(html, False)`               | pdfkit PyPI                    |
| `classroom_sender.py`   | `service.courses().announcements().create()`    | Classroom quickstart＋ REST ref |
| `stt_transcriber.py`    | `speech.RecognitionConfig(phrase_sets=[…])`     | Speech adaptation guide        |
| `user_dict_register.py` | `speech.AdaptationClient().create_phrase_set()` | 同上                             |

Tool 定義方法は **ADK “Function Tools” 公式** に準拠。

---

## 3 サービス層例（Firestore）

```python
from google.cloud import firestore, storage
db  = firestore.Client()
gcs = storage.Client().bucket("newsletter-bucket")

def save_newsletter(uid: str, html: str):
    db.collection("newsletters").add({"uid": uid, "html": html})

def save_pdf(sid: str, pdf: bytes) -> str:
    blob = gcs.blob(f"pdf/{sid}.pdf")
    blob.upload_from_string(pdf, content_type="application/pdf")
    return blob.generate_signed_url(expiration=datetime.timedelta(days=1))
```

* Firestore Python SDK は公式クイックスタート通り。

---

## 4 依存・環境変数

| 依存パッケージ                                                                                             | 用途          |
| --------------------------------------------------------------------------------------------------- | ----------- |
| `fastapi`, `uvicorn[standard]`, `sse-starlette`                                                     | HTTP & SSE  |
| `google-cloud-firestore`, `google-cloud-storage`, `google-api-python-client`, `google-cloud-speech` | GCP API     |
| `pdfkit`, `html5lib`, `adk`                                                                         | PDF/HTML/AI |

`.env`

```
GOOGLE_API_KEY=
GOOGLE_APPLICATION_CREDENTIALS=/var/secrets/sa.json
CLASSROOM_SUBJECT="学級通信"
```

---

## 5 Cloud Run デプロイ

```bash
gcloud run deploy newsletter-ai \
  --source backend \
  --region=asia-northeast1 \
  --max-instances=3 \
  --concurrency=80           # Cloud Run concurrency ref:contentReference[oaicite:24]{index=24}:contentReference[oaicite:25]{index=25}
```

---

## 6 Flutter 側最小フロー

1. `/chat` へ `/create ○月号` 投稿
2. SSE `/stream/{sid}` で HTML を受信 → `flutter_html` で表示
3. 画像は `firebase_storage` にアップ → URL を HTML 編集欄に貼付
4. **PDF ボタン** → `POST /pdf` → `pdf_ready` イベント ⇒ `openUrl()`
5. **送信ボタン** → `/chat` `/send {courseId}` → `classroom_ack` トースト

---

### 参考文献リスト（主なもの）

| ID                                   | 内容 |
| ------------------------------------ | -- |
|  Agent Team / Tool 設定—ADK Docs       |    |
|  FastAPI SSE 実装例                     |    |
|  ADK Streaming + FastAPI チュートリアル     |    |
|  Firestore Python クイックスタート           |    |
|  Classroom API Python Quickstart     |    |
|  Cloud Speech Model Adaptation 概要    |    |
|  pdfkit PyPI 説明                      |    |
|  Cloud Run Concurrency ドキュメント        |    |
|  ADK Function Tools ガイド              |    |
|  ADK Python API Reference            |    |
|  ADK Streaming Quickstart (FastAPI)  |    |
|  html5lib Strict parse ドキュメント        |    |
|  Classroom Announcements create REST |    |
|  Speech Adaptation PhraseSet コード     |    |
|  pdfkit 0.2.3 詳細                     |    |
以下が設計で参照した公式ドキュメント URLの一覧です（順不同・重複排除済み）。

* [https://google.github.io/adk-docs/api-reference/](https://google.github.io/adk-docs/api-reference/)
* [https://google.github.io/adk-docs/agents/multi-agents/](https://google.github.io/adk-docs/agents/multi-agents/)
* [https://google.github.io/adk-docs/get-started/streaming/quickstart-streaming/](https://google.github.io/adk-docs/get-started/streaming/quickstart-streaming/)
* [https://google.github.io/adk-docs/get-started/quickstart/](https://google.github.io/adk-docs/get-started/quickstart/)
* [https://github.com/google/adk-samples](https://github.com/google/adk-samples)
* [https://medium.com/%40Rachita\_B/implementing-sse-server-side-events-using-fastapi-3b2d6768249e](https://medium.com/%40Rachita_B/implementing-sse-server-side-events-using-fastapi-3b2d6768249e)
* [https://stackoverflow.com/questions/77141481/how-to-set-the-event-for-when-sending-sse-via-fastapi-starlette-to-have-differen](https://stackoverflow.com/questions/77141481/how-to-set-the-event-for-when-sending-sse-via-fastapi-starlette-to-have-differen)
* [https://cloud.google.com/firestore/native/docs/create-database-server-client-library](https://cloud.google.com/firestore/native/docs/create-database-server-client-library)
* [https://developers.google.com/workspace/classroom/quickstart/python](https://developers.google.com/workspace/classroom/quickstart/python)
* [https://developers.google.com/workspace/classroom/reference/rest](https://developers.google.com/workspace/classroom/reference/rest)
* [https://cloud.google.com/speech-to-text/v2/docs/adaptation-model](https://cloud.google.com/speech-to-text/v2/docs/adaptation-model)
* [https://cloud.google.com/python/docs/reference/speech/latest/google.cloud.speech\_v1p1beta1.types.SpeechAdaptation](https://cloud.google.com/python/docs/reference/speech/latest/google.cloud.speech_v1p1beta1.types.SpeechAdaptation)
* [https://pypi.org/project/pdfkit/](https://pypi.org/project/pdfkit/)
* [https://pypi.org/project/pdfkit/0.2.3/](https://pypi.org/project/pdfkit/0.2.3/)
* [https://cloud.google.com/run/docs/configuring/concurrency](https://cloud.google.com/run/docs/configuring/concurrency)

---

これが **最小かつ実装しやすい** ディレクトリ構成と、そのまま写せる設計・コード骨格です。