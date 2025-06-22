from fastapi import APIRouter, HTTPException
import logging

# ロガーの設定
logger = logging.getLogger(__name__)

# APIRouterインスタンスの作成
router = APIRouter()

@router.get("/health")
async def health_check():
    """
    サービスが正常に動作しているかを確認するためのヘルスチェックエンドポイント。
    """
    logger.info("Health check endpoint was called.")
    return {"status": "ok", "message": "AI service is healthy."} 