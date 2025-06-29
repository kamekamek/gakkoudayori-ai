from typing import Annotated, Optional

from fastapi import APIRouter, File, Form, HTTPException, UploadFile
from fastapi.concurrency import run_in_threadpool
from google.cloud import speech

router = APIRouter(
    prefix="/stt",
    tags=["Speech-to-Text"],
)


@router.post(
    "/", summary="音声ファイルをテキストに変換", response_description="文字起こし結果"
)
async def transcribe_audio(
    audio_file: Annotated[UploadFile, File(description="文字起こしする音声ファイル。")],
    phrase_set_resource: Annotated[
        Optional[str],
        Form(description="（オプション）使用するフレーズセットの完全リソース名。"),
    ] = None,
):
    """
    音声ファイルを受け取り、Speech-to-Textを使用してテキストに変換します。
    オプションで、音声認識の精度を向上させるための`phrase_set_resource`を指定できます。
    """
    if not audio_file:
        raise HTTPException(
            status_code=400, detail="音声ファイルが提供されていません。"
        )

    try:
        # 同期クライアントを使用
        client = speech.SpeechClient()
        audio_content = await audio_file.read()

        if not audio_content:
            raise HTTPException(status_code=400, detail="音声ファイルが空です。")

        recognition_audio = speech.RecognitionAudio(content=audio_content)

        config_dict = {
            "language_code": "ja-JP",
            "enable_automatic_punctuation": True,
        }
        if phrase_set_resource:
            adaptation = speech.SpeechAdaptation(
                phrase_set_references=[phrase_set_resource]
            )
            config_dict["adaptation"] = adaptation

        config = speech.RecognitionConfig(**config_dict)

        # 同期的な（ブロッキングする）処理をスレッドプールで実行
        response = await run_in_threadpool(
            client.recognize, config=config, audio=recognition_audio
        )

        transcripts = [result.alternatives[0].transcript for result in response.results]
        full_transcript = " ".join(transcripts)

        if not full_transcript:
            return {
                "success": True,
                "data": {"transcript": "", "confidence": 0.0},
                "message": "音声は認識されましたが、テキストは検出されませんでした。",
            }

        # フロントエンドの期待する形式に合わせる
        confidence = response.results[0].alternatives[0].confidence if response.results else 0.0
        return {
            "success": True,
            "data": {"transcript": full_transcript, "confidence": confidence},
        }

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"音声の文字起こし中に予期せぬエラーが発生しました: {str(e)}",
        )
