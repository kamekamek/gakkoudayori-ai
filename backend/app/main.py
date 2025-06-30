import json
import os
from contextlib import asynccontextmanager

import google.genai.types as genai_types
from fastapi import Depends, FastAPI, HTTPException, WebSocket, WebSocketDisconnect, Header
from fastapi.middleware.cors import CORSMiddleware
from google.adk.runners import Runner
from google.adk.sessions.in_memory_session_service import InMemorySessionService
from pydantic import BaseModel
from sse_starlette.sse import EventSourceResponse

# 実行対象のエージェントを直接インポート
from agents.main_conversation_agent.agent import root_agent
from app import classroom as classroom_api
from app import pdf as pdf_api
from app import stt as stt_api
from app import upload as upload_api
from app import user_dictionary as user_dictionary_api
from app.api.v1.endpoints import documents as documents_api
from app.auth import User, get_current_user, initialize_firebase_app

# HTML Artifact 管理
from app.core.artifact_manager import artifact_manager

# --- 環境設定 ---
ENVIRONMENT = os.getenv("ENVIRONMENT", "production")

# --- FastAPIのライフサイクル管理 ---
@asynccontextmanager
async def lifespan(app: FastAPI):
    # アプリケーション起動時に実行
    print("🚀 Application startup...")
    initialize_firebase_app()
    yield
    # アプリケーション終了時に実行
    print("👋 Application shutdown...")

# --- FastAPIアプリの初期化 ---
app = FastAPI(
    title="Gakkoudayori AI Backend v2",
    description=f"ADK v1.0.0-compatible version (Environment: {ENVIRONMENT})",
    lifespan=lifespan,
)

# --- CORS設定 (最優先で処理) ---
# 認証ミドルウェアより先にCORSを処理するため、アプリ初期化直後に設定
origins = [
    "https://gakkoudayori-ai.web.app",
    # 開発用オリジン
    "http://localhost",
    "http://localhost:8000",
    "http://localhost:8080",
    "http://localhost:8081",
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_origin_regex=r"https://(.*\.)?gakkoudayori-ai\.web\.app", # Firebaseプレビュー等に対応
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
print(f"✅ CORS settings applied for origins: {origins} and regex.")

# --- ADK v1.0.0手動セットアップ ---
session_service = InMemorySessionService()
runner = Runner(
    app_name="gakkoudayori-agent", agent=root_agent, session_service=session_service
)
print("✅ ADK Runner initialized manually for v1.0.0")

from app.api.v1.endpoints import user_settings as user_settings_api

# --- APIルーターの組み込み ---
app.include_router(pdf_api.router, prefix="/api/v1")
app.include_router(classroom_api.router, prefix="/api/v1")
app.include_router(stt_api.router, prefix="/api/v1")
app.include_router(upload_api.router, prefix="/api/v1")
app.include_router(user_dictionary_api.router, prefix="/api/v1")
app.include_router(documents_api.router, prefix="/api/v1")
app.include_router(user_settings_api.router, prefix="/api/v1")


# --- モデル定義 ---
class AdkChatRequest(BaseModel):
    message: str
    # user_idはトークンから取得するため不要に
    # user_id: str
    session_id: str


class HtmlArtifactRequest(BaseModel):
    session_id: str
    html_content: str
    artifact_type: str = "newsletter"
    metadata: dict = None


# --- ADKチャットエンドポイント ---
@app.post("/api/v1/adk/chat/stream")
async def adk_chat_stream(
    req: AdkChatRequest,
    x_user_id: str = Header(None, alias="X-User-ID")
    # current_user: User = Depends(get_current_user) # 将来の認証完全実装用
):
    """
    ADK v1.0.0互換のチャットストリーミングエンドポイント
    X-User-IDヘッダーからユーザーIDを取得します。
    """

    # X-User-IDヘッダーからユーザーIDを取得
    if not x_user_id:
        raise HTTPException(status_code=400, detail="X-User-ID header is required")
    
    user_id = x_user_id
    print(f"🔍 ADK Chat - User ID: {user_id} (from X-User-ID header)")
    
    # フロントエンドは "user_id:session_id" 形式で送ってくるため分割
    try:
        session_id = req.session_id.split(":", 1)[1]
    except (IndexError, AttributeError):
        # 分割できない場合はデフォルト値を使用
        session_id = "default"

    async def event_generator():
        try:
            print(
                f"🔧 Processing ADK chat stream for user: {user_id}, session: {session_id}"
            )

            # セッションが存在しない場合は作成
            existing_session = await session_service.get_session(
                app_name="gakkoudayori-agent", user_id=user_id, session_id=session_id
            )

            if not existing_session:
                print(
                    f"📝 Creating new session for user: {user_id}, session: {session_id}"
                )
                new_session = await session_service.create_session(
                    app_name="gakkoudayori-agent",
                    user_id=user_id,
                    session_id=session_id,
                )
                # セッション状態にユーザーIDを保存
                if new_session and hasattr(new_session, 'state'):
                    new_session.state["user_id"] = user_id
                    print(f"✅ User ID saved to session state: {user_id}")
            else:
                # 既存セッションにもユーザーIDを保存
                if hasattr(existing_session, 'state'):
                    existing_session.state["user_id"] = user_id
                    print(f"✅ User ID updated in existing session: {user_id}")

            # ADKのrun_asyncを呼び出してイベントストリームを取得
            async for event in runner.run_async(
                user_id=user_id,
                session_id=session_id,
                new_message=genai_types.Content(
                    role="user", parts=[genai_types.Part(text=req.message)]
                ),
            ):
                # フロントエンドがデシリアライズできるよう、eventオブジェクトをJSON文字列に変換
                yield {"data": event.model_dump_json()}

        except Exception as e:
            print(f"❌ Error during streaming: {e}")
            # エラー情報をフロントエンドに送信
            error_data = {"type": "error", "message": f"An error occurred: {str(e)}"}
            yield {"data": json.dumps(error_data), "event": "error"}

    return EventSourceResponse(event_generator())


# --- ヘルスチェックエンドポイント ---
@app.get("/health")
def health_check():
    """ヘルスチェック用エンドポイント"""
    return {"status": "ok", "environment": ENVIRONMENT}

@app.get("/warmup")
def warmup():
    """Cloud Run warmup用エンドポイント - ADK初期化"""
    try:
        # ADKランナーの状態確認
        runner_status = "ready" if runner else "not_ready"
        return {
            "status": "warm",
            "environment": ENVIRONMENT,
            "adk_runner": runner_status,
            "message": "Backend is warmed up and ready"
        }
    except Exception as e:
        return {"status": "error", "error": str(e)}


# --- HTML Artifact エンドポイント ---
@app.post("/api/v1/artifacts/html")
async def receive_html_artifact(request: HtmlArtifactRequest):
    """LayoutAgentからのHTML Artifactを受信し、WebSocket経由でフロントエンドに配信"""
    try:
        artifact = await artifact_manager.store_html_artifact(
            session_id=request.session_id,
            html_content=request.html_content,
            artifact_type=request.artifact_type,
            metadata=request.metadata or {}
        )

        return {
            "status": "success",
            "artifact_id": request.session_id,
            "created_at": artifact.created_at,
            "content_length": len(request.html_content)
        }
    except Exception as e:
        print(f"❌ HTML Artifact受信エラー: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to store HTML artifact: {str(e)}")


@app.get("/api/v1/artifacts/html/{session_id}")
async def get_html_artifact(session_id: str):
    """指定セッションの最新HTML Artifactを取得（ポーリング用）"""
    try:
        artifact = artifact_manager.get_artifact(session_id)
        if artifact:
            return {
                "status": "found",
                "artifact": artifact.to_dict()
            }
        else:
            return {
                "status": "not_found",
                "message": f"No artifact found for session: {session_id}"
            }
    except Exception as e:
        print(f"❌ HTML Artifact取得エラー: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to retrieve HTML artifact: {str(e)}")


@app.websocket("/ws/artifacts/{session_id}")
async def artifact_websocket(websocket: WebSocket, session_id: str):
    """HTML Artifact配信用WebSocketエンドポイント"""
    try:
        await artifact_manager.websocket_manager.connect(session_id, websocket)
        print(f"🔌 WebSocket connected for session: {session_id}")

        # 既存のArtifactがあれば即座に送信
        existing_artifact = artifact_manager.get_artifact(session_id)
        if existing_artifact:
            await artifact_manager.websocket_manager.send_artifact(session_id, existing_artifact)
            print(f"📤 Existing artifact sent to session: {session_id}")

        # 接続を維持（クライアントからの切断またはエラーまで）
        try:
            while True:
                # Ping-Pong でコネクション維持
                await websocket.receive_text()
        except WebSocketDisconnect:
            print(f"🔌 WebSocket disconnected for session: {session_id}")

    except Exception as e:
        print(f"❌ WebSocket error for session {session_id}: {e}")
    finally:
        await artifact_manager.websocket_manager.disconnect(session_id)
