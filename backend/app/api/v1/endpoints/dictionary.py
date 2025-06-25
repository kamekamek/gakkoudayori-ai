import logging
from typing import List, Dict, Any

from fastapi import APIRouter, HTTPException, status, Path, Body
from pydantic import BaseModel, Field

from services.user_dictionary_service import create_user_dictionary_service
from services.firebase_service import get_firestore_client

logger = logging.getLogger(__name__)
router = APIRouter()

# --- Pydantic Models ---

class DictionaryTerm(BaseModel):
    term: str
    variations: List[str]

class DictionaryResponse(BaseModel):
    success: bool
    data: Dict[str, Any]

class AddTermBody(BaseModel):
    term: str = Field(..., description="登録する用語")
    variations: List[str] = Field(default=[], description="用語のバリエーション（読み方など）")

class UpdateTermBody(BaseModel):
    variations: List[str] = Field(..., description="更新後の用語のバリエーション")
    
class CorrectBody(BaseModel):
    transcript: str

class LearnBody(BaseModel):
    original: str
    corrected: str
    context: str = ""

class SuggestBody(BaseModel):
    text: str


# --- API Endpoints ---

@router.get(
    "/{user_id}",
    response_model=DictionaryResponse,
    summary="ユーザー辞書の取得",
)
async def get_user_dictionary(user_id: str = Path(..., description="ユーザーID")):
    """ユーザーの辞書全体を取得します。"""
    try:
        firestore_client = get_firestore_client()
        dict_service = create_user_dictionary_service(firestore_client)
        dictionary = dict_service.get_user_dictionary(user_id)
        return {"success": True, "data": {"dictionary": dictionary, "user_id": user_id}}
    except Exception as e:
        logger.error(f"Get user dictionary error for {user_id}: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@router.post(
    "/{user_id}/terms",
    response_model=DictionaryResponse,
    summary="カスタム用語の追加",
)
async def add_custom_term(
    user_id: str = Path(..., description="ユーザーID"),
    body: AddTermBody = Body(...)
):
    """ユーザー辞書に新しい用語を追加します。"""
    try:
        firestore_client = get_firestore_client()
        dict_service = create_user_dictionary_service(firestore_client)
        success = dict_service.add_custom_term(user_id, body.term, body.variations)
        if success:
            return {"success": True, "data": {"term": body.term, "variations": body.variations}}
        else:
            raise HTTPException(status_code=500, detail="Failed to add custom term")
    except Exception as e:
        logger.error(f"Add custom term error for {user_id}: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@router.put(
    "/{user_id}/terms/{term_name}",
    response_model=DictionaryResponse,
    summary="カスタム用語の更新",
)
async def update_custom_term(
    user_id: str = Path(..., description="ユーザーID"),
    term_name: str = Path(..., description="更新する用語"),
    body: UpdateTermBody = Body(...)
):
    """ユーザー辞書の既存の用語を更新します。"""
    try:
        firestore_client = get_firestore_client()
        dict_service = create_user_dictionary_service(firestore_client)
        success = dict_service.update_custom_term(user_id, term_name, body.variations)
        if success:
            return {"success": True, "data": {"term": term_name, "variations": body.variations}}
        else:
            raise HTTPException(status_code=404, detail=f'Term "{term_name}" not found or failed to update.')
    except Exception as e:
        logger.error(f"Update term error for {user_id}/{term_name}: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@router.delete(
    "/{user_id}/terms/{term_name}",
    response_model=DictionaryResponse,
    summary="カスタム用語の削除",
)
async def delete_custom_term(
    user_id: str = Path(..., description="ユーザーID"),
    term_name: str = Path(..., description="削除する用語")
):
    """ユーザー辞書から用語を削除します。"""
    try:
        firestore_client = get_firestore_client()
        dict_service = create_user_dictionary_service(firestore_client)
        success = dict_service.delete_custom_term(user_id, term_name)
        if success:
            return {"success": True, "data": {"term": term_name, "message": f'Term "{term_name}" deleted.'}}
        else:
            raise HTTPException(status_code=404, detail=f'Term "{term_name}" not found or failed to delete.')
    except Exception as e:
        logger.error(f"Delete term error for {user_id}/{term_name}: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))

@router.post(
    "/{user_id}/correct",
    response_model=DictionaryResponse,
    summary="文字起こし結果の修正",
)
async def correct_transcription_with_dict(
    user_id: str = Path(..., description="ユーザーID"),
    body: CorrectBody = Body(...)
):
    """ユーザー辞書を使って、与えられたテキストの修正を行います。"""
    try:
        firestore_client = get_firestore_client()
        dict_service = create_user_dictionary_service(firestore_client)
        corrected_text, corrections = dict_service.correct_transcription(body.transcript, user_id)
        return {
            "success": True,
            "data": {
                "original_text": body.transcript,
                "corrected_text": corrected_text,
                "corrections": corrections,
            },
        }
    except Exception as e:
        logger.error(f"Correct transcription error for {user_id}: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))
        
@router.post(
    "/{user_id}/learn",
    response_model=DictionaryResponse,
    summary="手動修正の学習",
)
async def learn_manual_correction(
    user_id: str = Path(..., description="ユーザーID"),
    body: LearnBody = Body(...)
):
    """手動での修正内容を記録し、将来の学習データとします。"""
    try:
        firestore_client = get_firestore_client()
        dict_service = create_user_dictionary_service(firestore_client)
        success = dict_service.manual_correction(user_id, body.original, body.corrected, body.context)
        if success:
            return {"success": True, "data": {"learned": True, **body.dict()}}
        else:
            raise HTTPException(status_code=500, detail="Failed to record correction")
    except Exception as e:
        logger.error(f"Learn correction error for {user_id}: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))

@router.post(
    "/{user_id}/suggest",
    response_model=DictionaryResponse,
    summary="修正候補の提案",
)
async def suggest_dictionary_corrections(
    user_id: str = Path(..., description="ユーザーID"),
    body: SuggestBody = Body(...)
):
    """与えられたテキストに対する修正候補をユーザー辞書から提案します。"""
    try:
        firestore_client = get_firestore_client()
        dict_service = create_user_dictionary_service(firestore_client)
        suggestions = dict_service.suggest_corrections(body.text, user_id)
        return {"success": True, "data": {"text": body.text, "suggestions": suggestions}}
    except Exception as e:
        logger.error(f"Suggest corrections error for {user_id}: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e)) 