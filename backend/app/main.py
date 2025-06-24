import sys
import os
from fastapi import FastAPI, Request, UploadFile, File
from pydantic import BaseModel
from sse_starlette.sse import EventSourceResponse
import asyncio
import json
from typing import AsyncGenerator, Any

# --- Project Root Path Hack ---
# This allows to import 'backend' as a package
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../../')))
# -----------------------------

from backend.app import pdf as pdf_api
from backend.app import classroom as classroom_api
from backend.app import stt as stt_api
from backend.app import phrase as phrase_api
from backend.agents.orchestrator_agent.agent import create_orchestrator_agent

# REMAKE.md の設計に基づき、ADK Runner の概念を実装します。
# 本来はADKのセッション管理とイベントストリーミングをラップするクラスです。
# ここではプレースホルダーとして基本的なキューイング機能を提供します。
# TODO: agents/ を import できるように PYTHONPATH を調整する必要がある
# from agents.orchestrator_agent.agent import create_orchestrator_agent

class AdkRunner:
    """ADKエージェントの実行とイベントストリーミングを管理するランナー"""
    def __init__(self, agent):
        self.agent = agent
        # セッションごとのイベントキューを保持
        self._event_queues: dict[str, asyncio.Queue] = {}

    async def enqueue(self, session_id: str, message: str):
        """エージェントの実行をキューに追加し、非同期で処理を開始します。"""
        if session_id not in self._event_queues:
            self._event_queues[session_id] = asyncio.Queue()
        
        # ここで実際のADKエージェントの非同期実行をトリガーします。
        # agent_task = asyncio.create_task(self.agent.run(session_id, message, self._event_queues[session_id]))
        
        # --- 以下はモック実装です ---
        async def mock_agent_run():
            await self._event_queues[session_id].put({"event": "message", "data": json.dumps({"type": "status", "content": "Planner Agent started..."})})
            await asyncio.sleep(1.5)
            await self._event_queues[session_id].put({"event": "message", "data": json.dumps({"type": "artifact", "name": "outline.json", "content": '{"title": "test"}'})})
            await asyncio.sleep(1.5)
            await self._event_queues[session_id].put({"event": "message", "data": json.dumps({"type": "status", "content": "Generator Agent started..."})})
            await asyncio.sleep(2)
            await self._event_queues[session_id].put({"event": "message", "data": json.dumps({"type": "html", "html": "<h1>Test HTML</h1>"})})
            await self._event_queues[session_id].put({"event": "message", "data": json.dumps({"type": "complete"})})

        asyncio.create_task(mock_agent_run())


    async def emit_queue(self, session_id: str) -> AsyncGenerator[Any, None]:
        """指定されたセッションIDのイベントキューからイベントをストリーミングします。"""
        q = self._event_queues.get(session_id)
        if not q:
            return

        try:
            while True:
                event = await q.get()
                yield event
                if json.loads(event["data"]).get("type") == "complete":
                    break
        finally:
            del self._event_queues[session_id]


app = FastAPI(
    title="Gakkoudayori AI Backend v2",
    description="REMAKE.mdに基づいた再設計バージョン"
)

# Include routers from other files
app.include_router(pdf_api.router)
app.include_router(classroom_api.router)
app.include_router(stt_api.router)
app.include_router(phrase_api.router)

# 実際のエージェントを渡してRunnerを初期化
runner = AdkRunner(agent=create_orchestrator_agent())

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
    return EventSourceResponse(runner.emit_queue(sid))
