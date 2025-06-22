from fastapi import APIRouter
from .endpoints import transcribe

# APIルーターのインスタンスを作成
router = APIRouter()

# transcribeエンドポイントのルーターをインクルード
# ここで設定したprefixが、transcribe.py内の各エンドポイントのパスの前に追加される
router.include_router(transcribe.router, prefix="/ai", tags=["AI Transcription"]) 