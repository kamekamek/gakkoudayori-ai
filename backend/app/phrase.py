from fastapi import APIRouter, HTTPException, Body
from pydantic import BaseModel
from typing import List

from backend.agents.tools.user_dict_register import register_user_dictionary

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
    result = await register_user_dictionary(
        project_id=req.project_id,
        phrase_set_id=req.phrase_set_id,
        phrases=req.phrases,
        boost_value=req.boost_value
    )

    if result.get("status") == "error":
        raise HTTPException(
            status_code=500,
            detail=f"フレーズセットの登録に失敗しました: {result.get('message')}"
        )

    return result
