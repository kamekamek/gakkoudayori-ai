import json
import os
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from sse_starlette.sse import EventSourceResponse

import google.genai.types as genai_types
from google.adk.runners import Runner
from google.adk.sessions.in_memory_session_service import InMemorySessionService

# 実行対象のエージェントを直接インポート
from agents.orchestrator_agent.agent import root_agent
from app import classroom as classroom_api
from app import pdf as pdf_api
from app import stt as stt_api
from app import user_dictionary as user_dictionary_api

# --- 環境設定 ---
ENVIRONMENT = os.getenv("ENVIRONMENT", "production")

# --- FastAPIアプリの初期化 ---
app = FastAPI(
    title="Gakkoudayori AI Backend v2",
    description=f"ADK v1.0.0-compatible version (Environment: {ENVIRONMENT})"
)

# --- CORS設定 ---
if ENVIRONMENT == "development":
    origins = [
        "http://localhost",
        "http://localhost:8000", # poetry run server
        "http://localhost:8080", # uvicorn app.main:app
        "http://localhost:8081", # Flutter Web
    ]
    app.add_middleware(
        CORSMiddleware,
        allow_origin_regex="http://localhost:.*",
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    print("✅ CORS: Development mode enabled")
else:
    origins = [
        "https://gakkoudayori-ai.web.app",
        "https://gakkoudayori-ai.firebaseapp.com",
    ]
    app.add_middleware(
        CORSMiddleware,
        allow_origins=origins,
        allow_credentials=True,
        allow_methods=["GET", "POST", "PUT", "DELETE"],
        allow_headers=["Content-Type", "Authorization"],
    )
    print("✅ CORS: Production mode enabled")

# --- ADK v1.0.0手動セットアップ ---
session_service = InMemorySessionService()
runner = Runner(
    app_name="gakkoudayori-agent",
    agent=root_agent,
    session_service=session_service
)
print("✅ ADK Runner initialized manually for v1.0.0")

# --- APIルーターの組み込み ---
app.include_router(pdf_api.router)
app.include_router(classroom_api.router)
app.include_router(stt_api.router)
app.include_router(user_dictionary_api.router)

# --- モデル定義 ---
class AdkChatRequest(BaseModel):
    message: str
    user_id: str
    session_id: str

# --- ADKチャットエンドポイント ---
@app.post("/api/v1/adk/chat/stream")
async def adk_chat_stream(req: AdkChatRequest):
    """ADK v1.0.0互換のチャットストリーミングエンドポイント"""
    
    user_id = req.user_id
    # フロントエンドは "user_id:session_id" 形式で送ってくるため分割
    try:
        session_id = req.session_id.split(":", 1)[1]
    except (IndexError, AttributeError):
        # 分割できない場合はデフォルト値を使用
        session_id = "default"

    async def event_generator():
        try:
            print(f"🔧 Processing ADK chat stream for user: {user_id}, session: {session_id}")
            
            # セッションが存在しない場合は作成
            existing_session = await session_service.get_session(
                app_name="gakkoudayori-agent",
                user_id=user_id,
                session_id=session_id
            )
            
            if not existing_session:
                print(f"📝 Creating new session for user: {user_id}, session: {session_id}")
                await session_service.create_session(
                    app_name="gakkoudayori-agent",
                    user_id=user_id,
                    session_id=session_id
                )
            
            # ADKのrun_asyncを呼び出してイベントストリームを取得
            async for event in runner.run_async(
                user_id=user_id,
                session_id=session_id,
                new_message=genai_types.Content(role='user', parts=[genai_types.Part(text=req.message)]),
            ):
                # フロントエンドがデシリアライズできるよう、eventオブジェクトをJSON文字列に変換
                yield {"data": event.model_dump_json()}

        except Exception as e:
            print(f"❌ Error during streaming: {e}")
            # エラー情報をフロントエンドに送信
            error_data = {
                "type": "error",
                "message": f"An error occurred: {str(e)}"
            }
            yield {"data": json.dumps(error_data), "event": "error"}

    return EventSourceResponse(event_generator())

# --- ヘルスチェックエンドポイント ---
@app.get("/health")
def health_check():
    """ヘルスチェック用エンドポイント"""
    return {"status": "ok", "environment": ENVIRONMENT}
