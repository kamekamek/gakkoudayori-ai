#!/usr/bin/env python3
"""
バックエンドサーバー起動スクリプト
ポート8081で起動（Flutter Webが8080を使用中のため）
"""

import sys
import os

# 現在のディレクトリをPythonパスに追加
current_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, current_dir)

from main import app

if __name__ == '__main__':
    print('=== 学校だよりAI バックエンドサーバー ===')
    print('Available endpoints:')
    print('- POST /api/v1/ai/transcribe - 音声文字起こし')
    print('- GET /api/v1/ai/formats - サポート音声フォーマット')
    print('- POST /api/v1/ai/generate-newsletter - 学級通信自動生成')
    print('- GET /api/v1/ai/newsletter-templates - テンプレート一覧')
    print()
    print('Starting server on port 8081...')
    
    app.run(
        host='0.0.0.0',
        port=8081,
        debug=True
    ) 