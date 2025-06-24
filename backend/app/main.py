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

class AdkChatRequest(BaseModel):
    message: str
    user_id: str
    session_id: str = None

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

@app.post("/adk/chat/stream")
async def adk_chat_stream(req: AdkChatRequest):
    """フロントエンド互換のADKチャットストリーミングエンドポイント"""
    session_id = req.session_id or f"{req.user_id}:default"
    
    async def gen():
        try:
            # ADKのrun_asyncを呼び出してイベントストリームを取得
            async for event in runner.run_async(
                user_id=req.user_id,
                session_id=session_id,
                new_message=genai_types.to_content(req.message),
            ):
                # フロントエンドが期待する形式に変換
                event_data = {
                    "session_id": session_id,
                    "type": "message",
                    "data": event.model_dump_json()
                }
                yield {"data": json.dumps(event_data), "event": "message"}
        except Exception as e:
            # エラーハンドリング
            error_event = {
                "session_id": session_id,
                "type": "error", 
                "data": f"Error during streaming: {str(e)}"
            }
            yield {"data": json.dumps(error_event), "event": "error"}
            print(f"Error during streaming: {e}")

    return EventSourceResponse(gen(), ping=15)


class PdfIn(BaseModel):
    html_content: str

class NewsletterGenerationRequest(BaseModel):
    initial_request: str
    user_id: str
    session_id: str = None

class SessionResponse(BaseModel):
    session_id: str
    user_id: str
    created_at: str
    updated_at: str
    messages: list
    status: str
    agent_state: dict = None

@app.post("/adk/newsletter/generate")
async def generate_newsletter(req: NewsletterGenerationRequest):
    """学級通信生成エンドポイント"""
    session_id = req.session_id or f"{req.user_id}:newsletter_{int(__import__('time').time())}"
    
    # セッションでメッセージを処理
    try:
        # 初期リクエストをもとに生成プロセスを開始
        response_data = {
            "session_id": session_id,
            "status": "in_progress",
            "html_content": None,
            "json_structure": None,
            "messages": [
                {
                    "role": "user",
                    "content": req.initial_request,
                    "timestamp": __import__('datetime').datetime.now().isoformat()
                },
                {
                    "role": "assistant", 
                    "content": "学級通信の作成を開始します。詳細を教えてください。",
                    "timestamp": __import__('datetime').datetime.now().isoformat()
                }
            ]
        }
        return response_data
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error generating newsletter: {str(e)}")

@app.get("/adk/sessions/{session_id}")
async def get_session(session_id: str):
    """セッション情報取得エンドポイント"""
    try:
        # セッション情報を取得
        # 実際の実装では session_service から取得
        return SessionResponse(
            session_id=session_id,
            user_id="user_placeholder",
            created_at=__import__('datetime').datetime.now().isoformat(),
            updated_at=__import__('datetime').datetime.now().isoformat(),
            messages=[],
            status="active"
        )
    except Exception as e:
        raise HTTPException(status_code=404, detail="Session not found")

@app.delete("/adk/sessions/{session_id}")
async def delete_session(session_id: str):
    """セッション削除エンドポイント"""
    try:
        # セッションを削除
        # 実際の実装では session_service から削除
        return {"message": "Session deleted successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error deleting session: {str(e)}")

@app.post("/adk/generate/newsletter")
async def generate_newsletter_html(req: dict):
    """学級通信HTML生成エンドポイント"""
    user_id = req.get("user_id")
    session_id = req.get("session_id")
    
    if not user_id or not session_id:
        raise HTTPException(status_code=400, detail="user_id and session_id are required")
    
    try:
        # 仮のHTML生成（実際はADKエージェントから取得）
        sample_html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <title>学級通信</title>
            <style>
                body { font-family: 'Noto Sans JP', sans-serif; margin: 20px; }
                h1 { color: #2c5aa0; border-bottom: 2px solid #2c5aa0; }
                .date { text-align: right; color: #666; }
                .content { line-height: 1.6; }
            </style>
        </head>
        <body>
            <h1>1年1組 学級通信</h1>
            <div class="date">2024年3月15日</div>
            <div class="content">
                <h2>今日の出来事</h2>
                <p>AI によって生成された学級通信のサンプルです。</p>
                <p>実際の内容は、チャットでの会話内容をもとに生成されます。</p>
            </div>
        </body>
        </html>
        """
        
        return {"html_content": sample_html}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error generating HTML: {str(e)}")
