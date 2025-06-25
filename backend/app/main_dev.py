"""
Development version of main.py without Google Cloud dependencies
for API endpoint testing and frontend integration.
"""
import json
import datetime
from typing import AsyncGenerator
from unittest.mock import Mock

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from sse_starlette.sse import EventSourceResponse

app = FastAPI(
    title="Gakkoudayori AI Backend v2 - Dev",
    description="Development version for frontend integration testing"
)

# CORS設定（開発環境用）
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",
        "http://127.0.0.1:3000",
        "http://localhost:8080",
        "http://127.0.0.1:8080"
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class ChatIn(BaseModel):
    session: str  # "user_id:session_id"
    message: str

class AdkChatRequest(BaseModel):
    message: str
    user_id: str
    session_id: str = None

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

# Mock event for testing
class MockEvent:
    def model_dump_json(self):
        return json.dumps({
            "type": "message",
            "content": "こんにちは！学級通信について教えてください。",
            "agent": "orchestrator_agent",
            "timestamp": datetime.datetime.now().isoformat()
        })

async def mock_adk_stream() -> AsyncGenerator[MockEvent, None]:
    """Mock ADK event stream for testing"""
    events = [
        "こんにちは！どのような学級通信を作成しますか？",
        "運動会について詳細を教えてください。どのような内容を含めたいですか？",
        "学級通信を生成しています...",
        "HTML形式の学級通信が完成しました！"
    ]
    
    for i, content in enumerate(events):
        event = Mock()
        event.model_dump_json = lambda c=content, idx=i: json.dumps({
            "type": "message" if i < len(events) - 1 else "complete",
            "content": c,
            "agent": "planner_agent" if i < 2 else "generator_agent",
            "timestamp": datetime.datetime.now().isoformat()
        })
        yield event

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
            async for event in mock_adk_stream():
                yield {"data": event.model_dump_json(), "event": "message"}
        except Exception as e:
            error_message = {"error": str(e), "type": "error"}
            yield {"data": json.dumps(error_message), "event": "error"}

    return EventSourceResponse(gen(), ping=15)

@app.post("/adk/chat/stream")
async def adk_chat_stream(req: AdkChatRequest):
    """フロントエンド互換のADKチャットストリーミングエンドポイント"""
    session_id = req.session_id or f"{req.user_id}:default"
    
    async def gen():
        try:
            async for event in mock_adk_stream():
                # フロントエンドが期待する形式に変換
                event_data = {
                    "session_id": session_id,
                    "type": "message",
                    "data": event.model_dump_json()
                }
                yield {"data": json.dumps(event_data), "event": "message"}
        except Exception as e:
            error_event = {
                "session_id": session_id,
                "type": "error", 
                "data": f"Error during streaming: {str(e)}"
            }
            yield {"data": json.dumps(error_event), "event": "error"}

    return EventSourceResponse(gen(), ping=15)

@app.post("/adk/newsletter/generate")
async def generate_newsletter(req: NewsletterGenerationRequest):
    """学級通信生成エンドポイント"""
    session_id = req.session_id or f"{req.user_id}:newsletter_{int(__import__('time').time())}"
    
    response_data = {
        "session_id": session_id,
        "status": "in_progress",
        "html_content": None,
        "json_structure": None,
        "messages": [
            {
                "role": "user",
                "content": req.initial_request,
                "timestamp": datetime.datetime.now().isoformat()
            },
            {
                "role": "assistant", 
                "content": "学級通信の作成を開始します。詳細を教えてください。",
                "timestamp": datetime.datetime.now().isoformat()
            }
        ]
    }
    return response_data

@app.get("/adk/sessions/{session_id}")
async def get_session(session_id: str):
    """セッション情報取得エンドポイント"""
    return SessionResponse(
        session_id=session_id,
        user_id="user_placeholder",
        created_at=datetime.datetime.now().isoformat(),
        updated_at=datetime.datetime.now().isoformat(),
        messages=[],
        status="active"
    )

@app.delete("/adk/sessions/{session_id}")
async def delete_session(session_id: str):
    """セッション削除エンドポイント"""
    return {"message": "Session deleted successfully"}

@app.post("/adk/generate/newsletter")
async def generate_newsletter_html(req: dict):
    """学級通信HTML生成エンドポイント"""
    user_id = req.get("user_id")
    session_id = req.get("session_id")
    
    if not user_id or not session_id:
        raise HTTPException(status_code=400, detail="user_id and session_id are required")
    
    sample_html = """
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="UTF-8">
        <title>学級通信</title>
        <style>
            body { font-family: 'Noto Sans JP', sans-serif; margin: 20px; line-height: 1.6; }
            h1 { color: #2c5aa0; border-bottom: 2px solid #2c5aa0; padding-bottom: 10px; }
            .date { text-align: right; color: #666; margin-bottom: 20px; }
            .content { background: #f8f9fa; padding: 20px; border-radius: 8px; }
            .section { margin-bottom: 20px; }
            .highlight { background: #fff3cd; padding: 10px; border-left: 4px solid #ffc107; }
        </style>
    </head>
    <body>
        <h1>1年1組 学級通信</h1>
        <div class="date">2024年3月15日</div>
        <div class="content">
            <div class="section">
                <h2>🏃‍♂️ 今日の運動会</h2>
                <p>今日は待ちに待った運動会でした！子どもたちの一生懸命な姿がとても印象的でした。</p>
                <div class="highlight">
                    <strong>特に印象的だった場面:</strong>
                    <ul>
                        <li>徒競走で転んでも最後まで走り抜いた田中くん</li>
                        <li>チーム一丸となってリレーを頑張った赤組</li>
                        <li>大きな声で応援していた保護者の皆様</li>
                    </ul>
                </div>
            </div>
            <div class="section">
                <h2>📚 来週の予定</h2>
                <p>来週は通常授業に戻ります。運動会の疲れもあると思いますので、お子様の体調管理をよろしくお願いします。</p>
            </div>
        </div>
        <div style="text-align: center; margin-top: 30px; color: #666;">
            <p>担任：○○先生 | 📞 03-XXXX-XXXX</p>
        </div>
    </body>
    </html>
    """
    
    return {"html_content": sample_html.strip()}

@app.get("/health")
async def health_check():
    """ヘルスチェックエンドポイント"""
    return {
        "status": "healthy",
        "version": "dev-v2.0.0",
        "timestamp": datetime.datetime.now().isoformat(),
        "features": [
            "adk_chat_streaming",
            "newsletter_generation", 
            "session_management",
            "cors_enabled"
        ]
    }

@app.get("/")
async def root():
    """ルートエンドポイント"""
    return {
        "message": "学校だよりAI Backend - Development Server",
        "version": "dev-v2.0.0",
        "docs": "/docs",
        "health": "/health"
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8081)