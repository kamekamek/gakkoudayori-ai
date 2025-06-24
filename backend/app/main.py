# Welcome to Cloud Functions for Firebase for Python!
# To get started, simply uncomment the below code or create your own.
# Deploy with `firebase deploy`

from firebase_functions import https_fn
from datetime import datetime
from google.cloud import speech  # speechモジュールをインポート
from firebase_admin import initialize_app
import logging
import os
import re
from datetime import datetime
from pydantic import BaseModel

# カスタムサービスをインポート
from services.firebase_service import (
    initialize_firebase,
    health_check,
    get_firebase_config,
    get_firestore_client
)
from services.speech_recognition_service import (
    transcribe_audio_file,
    validate_audio_format,
    get_supported_formats,
    get_default_speech_contexts,
)
from services.user_dictionary_service import (
    create_user_dictionary_service,
)
from services.audio_to_json_service import convert_speech_to_json
from services.json_to_graphical_record_service import convert_json_to_graphical_record
from services.pdf_generator import generate_pdf_from_html, get_pdf_info

# FastAPIをインポート
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from asgiref.wsgi import WsgiToAsgi
import uvicorn
from contextlib import asynccontextmanager

# ADK Runner関連のインポート
from google.adk.runners import Runner
# 新しい依存関係ファイルからインポート
from core.dependencies import get_orchestrator_agent, get_session_service

# アプリケーションコンテキストでADK Runnerを管理
app_context = {}

@asynccontextmanager
async def lifespan(app: FastAPI):
    # アプリケーション起動時に実行
    logger.info("Initializing ADK Runner...")
    app.state.adk_runner = Runner(
        app_name="gakkoudayori-ai",
        agent=get_orchestrator_agent(),
        session_service=get_session_service()
    )
    logger.info("ADK Runner initialized successfully.")
    yield
    # アプリケーション終了時に実行
    logger.info("Cleaning up resources...")
    app_context.clear()
    logger.info("Cleanup complete.")

# Firebase Admin SDKを初期化
# 環境変数で初期化済みかチェックすることで、複数回呼び出しを避ける
if not os.getenv("FIREBASE_APP_INITIALIZED"):
    initialize_app()
    os.environ["FIREBASE_APP_INITIALIZED"] = "true"

# appディレクトリからメインのAPIルーターをインポート
# (この後のステップで、FastAPIインスタンスはこのファイルで作成されるようにリファクタリングします)
from api.v1.router import router as api_v1_router

# ログ設定
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Flaskアプリケーション作成
app = FastAPI(
    title="Gakkoudayori AI Backend",
    version="1.0.0",
    description="学級通信AIエージェントと通常APIを統合したサーバー",
    lifespan=lifespan
)

# v1のAPIルーターをアプリにマウント
app.include_router(api_v1_router, prefix="/api/v1")

# CORS設定 - 本番とローカル開発環境の両方を許可
# プレビュー環境のURLパターン (例: https://gakkoudayori-ai--pr-123.web.app) にマッチする正規表現
preview_origin_pattern = r"https://gakkoudayori-ai--pr-\d+\.web\.app"
# ステージング環境のURLパターン (例: https://gakkoudayori-ai--staging-abc123.web.app) にマッチする正規表現
staging_origin_pattern = r"https://gakkoudayori-ai--staging-[a-z0-9]+\.web\.app"
# ローカル開発環境のURLパターン（http://localhost:<ポート番号>）
local_origin_pattern = r"http://localhost:\d+"

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "https://gakkoudayori-ai.web.app",
        "https://gakkoudayori-ai--staging.web.app",
        "https://gakkoudayori-ai--staging-gwvqcn37.web.app",
        "*",  # ステージング環境用の緩い設定
    ],
    allow_origin_regex=f"({preview_origin_pattern}|{staging_origin_pattern}|{local_origin_pattern})",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Firebase初期化
def init_firebase():
    """Firebase初期化"""
    try:
        # firebase_service.pyのinitialize_firebase()を使用（Secret Manager対応済み）
        from services.firebase_service import initialize_firebase
        return initialize_firebase()
    except Exception as e:
        logger.error(f"Firebase initialization failed: {e}")
        return False

def get_firestore_client():
    """Firestoreクライアント取得"""
    try:
        if firebase_initialized:
            from firebase_admin import firestore
            return firestore.client()
        else:
            logger.warning("Firebase not initialized, returning None firestore client")
            return None
    except Exception as e:
        logger.error(f"Failed to get Firestore client: {e}")
        logger.error(f"Exception type: {type(e).__name__}")
        import traceback
        logger.error(f"Full traceback: {traceback.format_exc()}")
        return None

# アプリケーション起動時にFirebase初期化
firebase_initialized = init_firebase()

@app.get("/", summary="基本ヘルスチェック")
def read_root():
    """サービスの稼働状況とタイムスタンプを返します。"""
    return {
        'status': 'ok',
        'service': 'gakkoudayori-ai-backend',
        'timestamp': datetime.utcnow().isoformat(),
    }

@app.get("/health", summary="詳細ヘルスチェック")
def read_health():
    """Firebaseの接続状況など、より詳細なヘルスチェックを行います。"""
    try:
        health_result = health_check()
        status_code = 200 if health_result.get('status') == 'healthy' else 503
        return JSONResponse(content=health_result, status_code=status_code)
    except Exception as e:
        logger.error(f"Health check error: {e}", exc_info=True)
        return JSONResponse(
            status_code=500,
            content={'status': 'error', 'message': 'Health check failed unexpectedly.'}
        )

@app.get("/config", summary="Firebase設定情報の取得")
def read_config():
    """フロントエンドが必要とするFirebaseの設定情報を返します。"""
    try:
        config_info = get_firebase_config()
        return config_info
    except Exception as e:
        logger.error(f"Config retrieval error: {e}", exc_info=True)
        return JSONResponse(
            status_code=500,
            content={'status': 'error', 'message': 'Failed to retrieve Firebase config.'}
        )
