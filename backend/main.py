from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import uvicorn

# FastAPIアプリケーション初期化
app = FastAPI(
    title="ゆとり職員室 API",
    description="HTMLベースグラレコ風学級通信作成システム",
    version="1.0.0"
)

# CORS設定 (フロントエンドからのアクセス許可)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "http://localhost:8080"],  # Flutter Web開発サーバー
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ヘルスチェックエンドポイント (タスク完了条件)
@app.get("/health")
async def health_check():
    """
    APIサーバーの動作確認用エンドポイント
    """
    return {
        "status": "healthy",
        "message": "ゆとり職員室 API is running",
        "version": "1.0.0"
    }

# ルートエンドポイント
@app.get("/")
async def root():
    """
    API情報表示
    """
    return {
        "name": "ゆとり職員室 API",
        "description": "HTMLベースグラレコ風学級通信作成システム",
        "docs": "/docs",
        "health": "/health"
    }

# 開発サーバー起動用
if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True  # 開発時の自動リロード
    ) 