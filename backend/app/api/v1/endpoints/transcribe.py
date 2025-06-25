import logging
from typing import Dict, Any

from fastapi import APIRouter, HTTPException, status, File, UploadFile, Form
from pydantic import BaseModel
from google.cloud import speech

from services.speech_recognition_service import (
    transcribe_audio_file,
    validate_audio_format,
    get_supported_formats,
    get_default_speech_contexts,
)
from services.user_dictionary_service import create_user_dictionary_service
from services.firebase_service import get_firestore_client

logger = logging.getLogger(__name__)
router = APIRouter()

# --- Pydantic Models for Request/Response ---

class TranscribeResponseData(BaseModel):
    transcript: str
    original_transcript: str
    corrections: list
    confidence: float
    processing_time_ms: int
    sections: list
    audio_info: Dict[str, Any]
    validation_info: Dict[str, Any]
    user_dictionary_applied: bool

class TranscribeResponse(BaseModel):
    success: bool
    data: TranscribeResponseData

class AudioFormat(BaseModel):
    format: str
    mime_type: str
    extensions: list[str]

class SupportedLanguage(BaseModel):
    code: str
    name: str

class FormatsResponseData(BaseModel):
    supported_formats: list[AudioFormat]
    default_contexts: list[Dict[str, Any]]
    max_file_size_mb: int
    max_duration_seconds: int
    supported_languages: list[SupportedLanguage]

class FormatsResponse(BaseModel):
    success: bool
    data: FormatsResponseData


# --- API Endpoints ---

@router.post(
    "/transcribe",
    response_model=TranscribeResponse,
    summary="音声ファイルの文字起こし",
    description="アップロードされた音声ファイルを文字起こしし、ユーザー辞書を適用して結果を返します。",
)
async def transcribe_audio(
    audio_file: UploadFile = File(..., description="文字起こしする音声ファイル"),
    language: str = Form("ja-JP", description="言語コード (例: ja-JP)"),
    sample_rate: int = Form(48000, description="サンプリングレート (Hz)"),
    user_id: str = Form("default", description="ユーザーID"),
):
    """
    音声文字起こしエンドポイント
    """
    if not audio_file:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={"success": False, "error": "No audio file provided", "error_code": "MISSING_FILE"},
        )

    try:
        audio_content = await audio_file.read()

        # 音声フォーマット検証
        validation_result = validate_audio_format(audio_content)
        if not validation_result["valid"]:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail={"success": False, **validation_result},
            )

        # ユーザー辞書サービス初期化
        firestore_client = get_firestore_client()
        dict_service = create_user_dictionary_service(firestore_client)
        speech_contexts = dict_service.get_speech_contexts(user_id)

        # 音声文字起こし実行
        result = transcribe_audio_file(
            audio_content=audio_content,
            language_code=language,
            sample_rate_hertz=sample_rate,
            speech_contexts=speech_contexts,
            user_id=user_id,
            encoding=speech.RecognitionConfig.AudioEncoding.LINEAR16
            if validation_result.get("format") == "WAV"
            else speech.RecognitionConfig.AudioEncoding.WEBM_OPUS,
        )

        if not result["success"]:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail={"success": False, **result},
            )

        # ユーザー辞書でポストプロセシング
        original_transcript = result["data"]["transcript"]
        corrected_transcript, corrections = dict_service.correct_transcription(
            original_transcript, user_id
        )
        result["data"]["transcript"] = corrected_transcript
        result["data"]["corrections"] = corrections
        result["data"]["original_transcript"] = original_transcript
        result["data"]["user_dictionary_applied"] = len(corrections) > 0
        result["data"]["validation_info"] = validation_result


        return {"success": True, "data": result["data"]}

    except HTTPException as e:
        # Re-raise HTTPException to be handled by FastAPI
        raise e
    except Exception as e:
        logger.error(f"Audio transcription error: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail={"success": False, "error": f"Transcription failed: {str(e)}", "error_type": "server_error"},
        )


@router.get(
    "/formats",
    response_model=FormatsResponse,
    summary="サポートされている音声フォーマットの取得",
    description="文字起こし機能でサポートされている音声フォーマット、言語、その他の設定情報を返します。",
)
async def get_audio_formats():
    """
    サポートされている音声フォーマット一覧取得
    """
    try:
        formats = get_supported_formats()
        contexts = get_default_speech_contexts()

        return {
            "success": True,
            "data": {
                "supported_formats": formats,
                "default_contexts": contexts,
                "max_file_size_mb": 10,
                "max_duration_seconds": 60,
                "supported_languages": [
                    {"code": "ja-JP", "name": "日本語"},
                    {"code": "en-US", "name": "English (US)"},
                    {"code": "en-GB", "name": "English (UK)"},
                ],
            },
        }
    except Exception as e:
        logger.error(f"Format info error: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail={"success": False, "error": str(e)},
        ) 