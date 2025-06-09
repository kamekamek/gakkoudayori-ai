# Welcome to Cloud Functions for Firebase for Python!
# To get started, simply uncomment the below code or create your own.
# Deploy with `firebase deploy`

from firebase_functions import https_fn
from firebase_admin import initialize_app
from flask import Flask, request, jsonify
from flask_cors import CORS
import logging
import os
import sys
from datetime import datetime

# カスタムサービスをインポート
from firebase_service import (
    initialize_firebase,
    initialize_firebase_with_credentials,
    health_check,
    get_firebase_config
)

# ログ設定
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Flaskアプリケーション作成
app = Flask(__name__)
CORS(app)  # CORS設定

# Firebase初期化
def init_firebase():
    """Firebase初期化"""
    try:
        # 環境変数または認証ファイルパスを確認
        credentials_path = os.getenv('GOOGLE_APPLICATION_CREDENTIALS')
        if credentials_path and os.path.exists(credentials_path):
            logger.info(f"Initializing Firebase with credentials: {credentials_path}")
            return initialize_firebase_with_credentials(credentials_path)
        else:
            logger.info("Initializing Firebase with default credentials")
            return initialize_firebase()
    except Exception as e:
        logger.error(f"Firebase initialization failed: {e}")
        return False

# アプリケーション起動時にFirebase初期化
firebase_initialized = init_firebase()

@app.route('/')
def hello_world():
    """ヘルスチェックエンドポイント"""
    return jsonify({
        'status': 'ok',
        'service': 'yutori-kyoshitu-backend',
        'timestamp': datetime.utcnow().isoformat(),
        'firebase_initialized': firebase_initialized
    })

@app.route('/health', methods=['GET'])
def health():
    """詳細ヘルスチェック"""
    try:
        health_result = health_check()
        status = 'healthy' if all([
            health_result.get('firebase_initialized'),
            health_result.get('firestore_accessible'),
            health_result.get('storage_accessible')
        ]) else 'unhealthy'
        
        health_result['status'] = status
        return jsonify(health_result), 200 if status == 'healthy' else 503
    except Exception as e:
        logger.error(f"Health check error: {e}")
        return jsonify({
            'status': 'error',
            'error': str(e),
            'timestamp': datetime.utcnow().isoformat()
        }), 500

@app.route('/config', methods=['GET'])
def config():
    """Firebase設定情報取得"""
    try:
        config_info = get_firebase_config()
        return jsonify(config_info)
    except Exception as e:
        logger.error(f"Config retrieval error: {e}")
        return jsonify({
            'error': str(e),
            'timestamp': datetime.utcnow().isoformat()
        }), 500

@app.errorhandler(404)
def not_found(error):
    """404エラーハンドラー"""
    return jsonify({
        'error': 'Not Found',
        'message': 'The requested endpoint was not found',
        'timestamp': datetime.utcnow().isoformat()
    }), 404

@app.errorhandler(500)
def internal_error(error):
    """500エラーハンドラー"""
    return jsonify({
        'error': 'Internal Server Error',
        'message': 'An unexpected error occurred',
        'timestamp': datetime.utcnow().isoformat()
    }), 500

# Cloud Functions用のエントリーポイント
@https_fn.on_request()
def api(req: https_fn.Request) -> https_fn.Response:
    """
    Firebase Cloud Functions用のHTTPSエンドポイント
    
    Args:
        req: HTTPSリクエスト
        
    Returns:
        HTTPSレスポンス
    """
    with app.request_context(req.environ):
        return app.full_dispatch_request()

# ローカル開発用
if __name__ == '__main__':
    # ローカル開発モード
    app.run(debug=True, host='0.0.0.0', port=8080)