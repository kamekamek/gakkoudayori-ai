from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import uvicorn

# FastAPIアプリケーション初期化
app = FastAPI(
    title=os.getenv("API_TITLE", "ゆとり職員室 API"),
    description=os.getenv("API_DESCRIPTION", "HTMLベースグラレコ風学級通信作成システム"),
    version=os.getenv("API_VERSION", "1.0.0")
 )

# CORS設定 (フロントエンドからのアクセス許可)
app.add_middleware(
    CORSMiddleware,
    allow_origins=os.getenv("CORS_ORIGINS", "http://localhost:3000,http://localhost:8080").split(","),
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
        host=os.getenv("HOST", "0.0.0.0"),
        port=int(os.getenv("PORT", "8000")),
        reload=os.getenv("ENVIRONMENT", "development") == "development"
     )