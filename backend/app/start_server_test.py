#!/usr/bin/env python3
"""
テスト用バックエンドサーバー起動スクリプト
ポート8082で起動（テスト環境用）
"""

import sys
import os

# 現在のディレクトリをPythonパスに追加
current_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, current_dir)

import uvicorn
from main_local import app

if __name__ == '__main__':
    print('=== 学校だよりAI テスト用バックエンドサーバー ===')
    print('Available endpoints:')
    print('- POST /api/v1/ai/transcribe - 音声文字起こし')
    print('- GET /api/v1/ai/formats - サポート音声フォーマット')
    print('- POST /api/v1/ai/generate-newsletter - 学級通信自動生成')
    print('- GET /api/v1/ai/newsletter-templates - テンプレート一覧')
    print('- POST /api/v1/adk/generate - ADK 学級通信生成')
    print('- POST /api/v1/adk/chat/stream - ADK ストリーミングチャット')
    print('- GET /docs - Swagger UI')
    print('- GET /redoc - ReDoc')
    print()
    print('🧪 Starting TEST FastAPI server on port 8082...')
    
    uvicorn.run(
        app,
        host='0.0.0.0',
        port=8082,
        reload=True  # テスト環境では自動リロード有効
    )