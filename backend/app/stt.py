from fastapi import APIRouter, HTTPException, File, UploadFile, Form
from typing import Annotated, Optional

from backend.agents.tools.stt_transcriber import transcribe_audio as transcribe_audio_tool

router = APIRouter(
    prefix="/stt",
    tags=["Speech-to-Text"],
)

@router.post(
    "/",
    summary="音声ファイルをテキストに変換",
    response_description="文字起こし結果"
)
async def transcribe_audio(
    audio_file: Annotated[UploadFile, File(description="文字起こしする音声ファイル。")],
    phrase_set_resource: Annotated[Optional[str], Form(description="（オプション）使用するフレーズセットの完全リソース名。")] = None
):
    """
    音声ファイルを受け取り、Speech-to-Textツールを使用してテキストに変換します。

    オプションで、音声認識の精度を向上させるための`phrase_set_resource`を指定できます。
    """
    if not audio_file:
        raise HTTPException(status_code=400, detail="音声ファイルが提供されていません。")

    audio_content = await audio_file.read()
    if not audio_content:
        raise HTTPException(status_code=400, detail="音声ファイルが空です。")

    # 音声ファイルの情報からエンコーディングやサンプルレートを決定するのが理想的ですが、
    # ここではツール側のデフォルト値に依存します。
    result = await transcribe_audio_tool(
        audio_content=audio_content,
        phrase_set_resource=phrase_set_resource
    )

    if result.get("status") == "error":
        raise HTTPException(
            status_code=500,
            detail=f"音声の文字起こしに失敗しました: {result.get('message')}"
        )

    return result
