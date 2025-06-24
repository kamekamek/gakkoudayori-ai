import sys
import os
from fastapi import FastAPI, Request, UploadFile, File
from pydantic import BaseModel
from sse_starlette.sse import EventSourceResponse
import asyncio
import json
from typing import AsyncGenerator, Any

# REMAKE.md の設計に基づき、ADK Runner を FastAPI と連携させます。
from google.adk.runners import Runner
from google.adk.sessions.in_memory_session_service import InMemorySessionService

from backend.app import pdf as pdf_api
from backend.app import classroom as classroom_api
from backend.app import stt as stt_api
from backend.app import phrase as phrase_api
from backend.agents.orchestrator_agent.agent import create_orchestrator_agent


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
    session: str
    message: str

@app.post("/chat")
async def chat(req: ChatIn):
    """チャットリクエストを受け付け、エージェントの処理を開始します。"""
    await runner.enqueue(req.session, req.message)
    return {"session": req.session}


@app.get("/stream/{sid}")
async def stream(req: Request, sid: str):
    """サーバーセントイベント(SSE)でエージェントの生成物やイベントをストリーミングします。"""
    async def gen():
        async for ev in runner.emit_queue(sid):
            # ADKからのイベントをSSE形式に変換
            yield {"data": ev.json(), "event": "message"}
            
    return EventSourceResponse(gen(), ping=15)
