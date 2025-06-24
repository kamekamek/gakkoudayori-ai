import json

import google.genai.types as genai_types
from fastapi import FastAPI, HTTPException

# REMAKE.md の設計に基づき、ADK Runner を FastAPI と連携させます。
from google.adk.runners import Runner
from google.adk.sessions.in_memory_session_service import InMemorySessionService
from pydantic import BaseModel
from sse_starlette.sse import EventSourceResponse

from agents.orchestrator_agent.agent import create_orchestrator_agent
from app import classroom as classroom_api
from app import pdf as pdf_api
from app import phrase as phrase_api
from app import stt as stt_api

# 以下のツールは直接APIとして実装されたため、main.pyからは不要
# from agents.tools.pdf_converter import convert_html_to_pdf
# from agents.tools.classroom_sender import post_to_classroom
# from agents.tools.stt_transcriber import transcribe_audio
# from agents.tools.user_dict_register import register_user_dictionary


app = FastAPI(
    title="Gakkoudayori AI Backend v2",
    description="REMAKE.mdに基づいた再設計バージョン"
)

# Include routers from other files
app.include_router(pdf_api.router)
app.include_router(classroom_api.router)
app.include_router(stt_api.router)
app.include_router(phrase_api.router)

# 実際のエージェントとセッションサービスを渡してRunnerを初期化
runner = Runner(
    app_name="gakkoudayori-agent",
    agent=create_orchestrator_agent(),
    session_service=InMemorySessionService()
)

class ChatIn(BaseModel):
    session: str  # "user_id:session_id"
    message: str

@app.post("/chat")
async def chat(req: ChatIn):
    try:
        user_id, session_id = req.session.split(":", 1)
    except ValueError:
        raise HTTPException(
            status_code=400,
            detail="Invalid session format. Expected 'user_id:session_id'",
        )

    async def gen():
        try:
            # ADKのrun_asyncを呼び出してイベントストリームを取得
            async for event in runner.run_async(
                user_id=user_id,
                session_id=session_id,
                new_message=genai_types.to_content(req.message),
            ):
                yield {"data": event.model_dump_json(), "event": "message"}
        except Exception as e:
            # エラーハンドリング
            error_message = {"error": str(e), "type": "error"}
            yield {"data": json.dumps(error_message), "event": "error"}
            print(f"Error during streaming: {e}") # Log error to server console

    return EventSourceResponse(gen(), ping=15)


class PdfIn(BaseModel):
    html_content: str
