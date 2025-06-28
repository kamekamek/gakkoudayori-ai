# Copyright 2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""
ローカル開発用のメインアプリケーション
"""

import logging
import os
from contextlib import asynccontextmanager
from datetime import datetime

import uvicorn
from core.dependencies import get_orchestrator_agent, get_session_service
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

# Firebase Admin SDKを初期化
from firebase_admin import initialize_app

# ADK Runner関連のインポート
from google.adk.runners import Runner

# ログ設定
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    # アプリケーション起動時に実行
    logger.info("Initializing ADK Runner...")
    app.state.adk_runner = Runner(
        app_name="gakkoudayori-ai",
        agent=get_orchestrator_agent(),
        session_service=get_session_service(),
    )
    logger.info("ADK Runner initialized successfully.")
    yield
    # アプリケーション終了時に実行
    logger.info("Cleaning up resources...")


# Firebase Admin SDKを初期化
if not os.getenv("FIREBASE_APP_INITIALIZED"):
    try:
        initialize_app()
        os.environ["FIREBASE_APP_INITIALIZED"] = "true"
        logger.info("Firebase initialized successfully")
    except Exception as e:
        logger.warning(f"Firebase initialization failed: {e}")

# FastAPIアプリケーション作成
app = FastAPI(
    title="Gakkoudayori AI Backend",
    version="1.0.0",
    description="学級通信AIエージェントと通常APIを統合したサーバー",
    lifespan=lifespan,
)

# v1のAPIルーターをアプリにマウント
from api.v1.router import router as api_v1_router

app.include_router(api_v1_router, prefix="/api/v1")

# CORS設定
# ローカル開発環境のURLパターン（http://localhost:<ポート番号>）
local_origin_pattern = r"http://localhost:\d+"

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "https://gakkoudayori-ai.web.app",
        "https://gakkoudayori-ai--staging.web.app",
        "https://gakkoudayori-ai--staging-gwvqcn37.web.app",
        "*",  # ローカル開発環境用の緩い設定
    ],
    allow_origin_regex=local_origin_pattern,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/", summary="基本ヘルスチェック")
def read_root():
    """サービスの稼働状況とタイムスタンプを返します。"""
    return {
        "status": "ok",
        "service": "gakkoudayori-ai-backend",
        "timestamp": datetime.utcnow().isoformat(),
    }


@app.get("/health", summary="詳細ヘルスチェック")
def read_health():
    """Firebaseの接続状況など、より詳細なヘルスチェックを行います。"""
    try:
        from services.firebase_service import health_check

        health_result = health_check()
        status_code = 200 if health_result.get("status") == "healthy" else 503
        return JSONResponse(content=health_result, status_code=status_code)
    except Exception as e:
        logger.error(f"Health check error: {e}", exc_info=True)
        return JSONResponse(
            status_code=500,
            content={"status": "error", "message": "Health check failed unexpectedly."},
        )


# ローカル開発用
if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8081))
    uvicorn.run(
        "main_local:app", host="0.0.0.0", port=port, reload=True, log_level="info"
    )
