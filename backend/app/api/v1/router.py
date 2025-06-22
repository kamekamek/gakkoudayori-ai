from fastapi import APIRouter
from .endpoints import transcribe, dictionary, newsletter, adk_agent, ai

# APIルーターのインスタンスを作成
router = APIRouter()

# 各エンドポイントのルーターをインクルード
router.include_router(ai.router, prefix="/ai", tags=["AI Service"])
router.include_router(transcribe.router, tags=["AI Transcription"]) # prefixを削除
router.include_router(dictionary.router, prefix="/dictionary", tags=["User Dictionary"])
router.include_router(newsletter.router, tags=["Newsletter Generation"]) # prefixを削除
router.include_router(adk_agent.router, prefix="/adk", tags=["ADK Agent"]) 