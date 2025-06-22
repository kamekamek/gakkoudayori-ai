# Welcome to Cloud Functions for Firebase for Python!
# To get started, simply uncomment the below code or create your own.
# Deploy with `firebase deploy`

from firebase_functions import https_fn
from datetime import datetime
from google.cloud import speech  # speechモジュールをインポート
from firebase_admin import initialize_app
from flask import Flask, request, jsonify
from flask_cors import CORS
import logging
import os
import re
from datetime import datetime
from pydantic import BaseModel
from dotenv import load_dotenv

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

# .envファイルから環境変数を読み込む
load_dotenv()

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

# FastAPIアプリケーションのインスタンスを作成
app = FastAPI(
    title="学校だよりAI API",
    description="学校だよりAIのバックエンドAPIです。音声文字起こし、AIによる文章生成、PDF出力機能を提供します。",
    version="1.0.0",
)

# CORS (Cross-Origin Resource Sharing) の設定
origins = [
    "http://localhost",
    "http://localhost:8080",  # Flutter Web開発サーバー
    # NOTE: デプロイ先のフロントエンドURLを本番環境では追加してください
    #例: "https://your-production-domain.web.app"
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Firebase初期化
def init_firebase():
    """Firebase初期化"""
    try:
        # firebase_service.pyのinitialize_firebase()を使用（Secret Manager対応済み）
        from firebase_service import initialize_firebase
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

# API v1のルーターをインクルード
# 全てのv1エンドポイントは /api/v1 プレフィックスを持つ
app.include_router(api_v1_router, prefix="/api/v1")

# ヘルスチェック用のエンドポイント
@app.get("/health", tags=["System"])
async def health_check():
    """
    アプリケーションの稼働状況を確認するためのヘルスチェックエンドポイント。
    """
    return {"status": "ok"}

# サーバー起動時の処理（デバッグ用）
@app.on_event("startup")
async def startup_event():
    print("🚀 FastAPI application startup")
    project_id = os.getenv("GOOGLE_CLOUD_PROJECT")
    if not project_id:
        print("⚠️  Warning: GOOGLE_CLOUD_PROJECT environment variable is not set.")

@app.on_event("shutdown")
async def shutdown_event():
    print("👋 FastAPI application shutdown")

@app.errorhandler(404)
def not_found(error):
    """404エラーハンドラー"""
    return JSONResponse(
        status_code=404,
        content={'error': 'Not Found', 'message': 'The requested endpoint was not found', 'timestamp': datetime.utcnow().isoformat()}
    )

@app.errorhandler(500)
def internal_error(error):
    """500エラーハンドラー"""
    return JSONResponse(
        status_code=500,
        content={'error': 'Internal Server Error', 'message': 'An unexpected error occurred', 'timestamp': datetime.utcnow().isoformat()}
    )

# Cloud Functions用のエントリーポイント
@https_fn.on_request(max_instances=10)
def api(req: https_fn.Request) -> https_fn.Response:
    """
    すべてのリクエストをFastAPIアプリケーションにルーティングする
    """
    asgi_app = WsgiToAsgi(app)
    return https_fn.Response(asgi_app(req))

# ローカル開発用
if __name__ == '__main__':
    # 本番環境とローカル開発の両方に対応
    port = int(os.environ.get('PORT', 8081))
    uvicorn.run("main:app", host="0.0.0.0", port=port, reload=True, log_level="info")