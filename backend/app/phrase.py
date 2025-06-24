from fastapi import APIRouter, HTTPException, Body
from pydantic import BaseModel
from typing import List, Optional

from google.cloud import speech_v2
from google.api_core.exceptions import NotFound

router = APIRouter(
    prefix="/phrase",
    tags=["Speech Adaptation"],
)

class PhraseRequest(BaseModel):
    project_id: str
    phrase_set_id: str
    phrases: List[str]
    boost_value: float = 10.0

@router.post(
    "/",
    summary="ユーザー辞書（フレーズセット）を作成・更新",
    response_description="処理結果"
)
async def register_phrases(req: PhraseRequest):
    """
    音声認識の精度向上のため、ユーザー辞書（フレーズセット）を作成または更新します。
    """
    try:
        client = speech_v2.SpeechAsyncClient()
        phrase_set_name = f"projects/{req.project_id}/locations/global/phraseSets/{req.phrase_set_id}"

        try:
            # 既存のフレーズセットを取得試行
            await client.get_phrase_set(name=phrase_set_name)
            # 存在する場合：更新
            phrase_set = speech_v2.PhraseSet(
                name=phrase_set_name,
                phrases=[{"value": p, "boost": req.boost_value} for p in req.phrases],
            )
            operation = await client.update_phrase_set(phrase_set=phrase_set)
            message = "既存のフレーズセットを更新しました。"
        except NotFound:
            # 存在しない場合：新規作成
            phrase_set = speech_v2.PhraseSet(
                phrases=[{"value": p, "boost": req.boost_value} for p in req.phrases],
            )
            operation = await client.create_phrase_set(
                parent=f"projects/{req.project_id}/locations/global",
                phrase_set_id=req.phrase_set_id,
                phrase_set=phrase_set,
            )
            message = "新しいフレーズセットを作成しました。"

        # オペレーション完了を待機
        await operation.result(timeout=300)

        return {"status": "success", "message": message, "phrase_set_name": phrase_set_name}

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"フレーズセットの登録中に予期せぬエラーが発生しました: {str(e)}"
        )
