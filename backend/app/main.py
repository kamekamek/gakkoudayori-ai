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
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from asgiref.wsgi import WsgiToAsgi
import uvicorn

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
    description="学級通信AIエージェントと通常APIを統合したサーバー"
)

# v1のAPIルーターをアプリにマウント
app.include_router(api_v1_router, prefix="/api/v1")

# CORS設定 - 本番とローカル開発環境の両方を許可
# プレビュー環境のURLパターン (例: https://gakkoudayori-ai--pr-123.web.app) にマッチする正規表現
preview_origin_pattern = r"https://gakkoudayori-ai--pr-\d+\.web\.app"
# ステージング環境のURLパターン (例: https://gakkoudayori-ai--staging-abc123.web.app) にマッチする正規表現
staging_origin_pattern = r"https://gakkoudayori-ai--staging-[a-z0-9]+\.web\.app"

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "https://gakkoudayori-ai.web.app",
        "https://gakkoudayori-ai--staging.web.app",
        "http://localhost:3000",
        "http://localhost:5000",
        "http://localhost:8080"
    ],
    allow_origin_regex=f"({preview_origin_pattern}|{staging_origin_pattern})",
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

# ==============================================================================
# ヘルパー関数
# ==============================================================================

def _clean_html_for_pdf(html_content: str) -> str:
    """
    PDF生成前にHTMLからMarkdownコードブロックを除去 - 強化版
    
    Args:
        html_content (str): クリーンアップするHTMLコンテンツ
        
    Returns:
        str: Markdownコードブロックが除去されたHTMLコンテンツ
    """
    if not html_content:
        return html_content
    
    import re
    
    content = html_content.strip()
    
    # Markdownコードブロックの様々なパターンを削除 - 強化版
    patterns = [
        r'```html\s*',          # ```html
        r'```HTML\s*',          # ```HTML  
        r'```\s*html\s*',       # ``` html
        r'```\s*HTML\s*',       # ``` HTML
        r'```\s*',              # 一般的なコードブロック開始
        r'\s*```',              # コードブロック終了
        r'`html\s*',            # `html（単一バッククォート）
        r'`HTML\s*',            # `HTML（単一バッククォート）
        r'\s*`\s*$',            # 末尾の単一バッククォート
        r'^\s*`',               # 先頭の単一バッククォート
    ]
    
    for pattern in patterns:
        content = re.sub(pattern, '', content, flags=re.IGNORECASE | re.MULTILINE)
    
    # HTMLの前後にある説明文を削除（より積極的に）
    explanation_patterns = [
        r'^[^<]*(?=<)',                           # HTML開始前の説明文
        r'>[^<]*$',                               # HTML終了後の説明文  
        r'以下のHTML.*?です[。：]?\s*',              # 「以下のHTML〜です」パターン
        r'HTML.*?を出力.*?[。：]?\s*',             # 「HTMLを出力〜」パターン
        r'こちらが.*?HTML.*?[。：]?\s*',           # 「こちらがHTML〜」パターン
        r'生成された.*?HTML.*?[。：]?\s*',         # 「生成されたHTML〜」パターン
        r'【[^】]*】',                               # 【〜】形式のラベル
    ]
    
    for pattern in explanation_patterns:
        content = re.sub(pattern, '', content, flags=re.IGNORECASE)
    
    # 空白の正規化
    content = re.sub(r'\n\s*\n', '\n', content)
    content = content.strip()
    
    # デバッグログ：PDFエンドポイントでのクリーンアップチェック（強化）
    if '```' in content or '`' in content:
        logger.warning(f"PDF endpoint: Markdown/backtick remnants detected after enhanced cleanup: {content[:100]}...")
    
    return content

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