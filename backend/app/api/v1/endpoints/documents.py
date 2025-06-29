from typing import Any, Dict, List

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel

from app.auth import User, get_current_user
from services import firestore_service

router = APIRouter()

# --- Pydanticモデル ---
class DocumentCreate(BaseModel):
    title: str
    htmlContent: str
    conversationHistory: List[Dict[str, Any]]

class DocumentUpdate(BaseModel):
    title: str
    htmlContent: str

class DocumentResponse(BaseModel):
    id: str
    userId: str
    title: str
    htmlContent: str
    status: str
    createdAt: str
    updatedAt: str

# --- エンドポイント定義 ---

@router.post("/documents", response_model=DocumentResponse, status_code=status.HTTP_201_CREATED)
async def create_document(
    doc_in: DocumentCreate,
    # current_user: User = Depends(get_current_user) # 一時的に認証を無効化
):
    """
    新しいドキュメントを作成
    （注：現在、デバッグのため認証は一時的に無効化されています）
    """
    # 認証を無効化しているため、一時的に固定のユーザーIDを使用
    user_id = "temp-fixed-user-id-for-debug"
    # user_id = current_user.uid
    try:
        doc_id = await firestore_service.save_document(
            user_id=user_id,
            title=doc_in.title,
            html_content=doc_in.htmlContent,
            conversation_history=doc_in.conversationHistory
        )
        doc = await firestore_service.get_document(doc_id)
        if not doc:
            raise HTTPException(status_code=404, detail="Document not found after creation")

        return DocumentResponse(
            id=doc_id,
            userId=doc.get("userId"),
            title=doc.get("title"),
            htmlContent=doc.get("htmlContent"),
            status=doc.get("status"),
            createdAt=str(doc.get("createdAt")),
            updatedAt=str(doc.get("updatedAt")),
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error creating document: {e}")

@router.get("/documents", response_model=List[DocumentResponse])
async def list_documents(
    # current_user: User = Depends(get_current_user) # 一時的に認証を無効化
):
    """
    ユーザーのドキュメント一覧を取得
    （注：現在、デバッグのため認証は一時的に無効化されています）
    """
    user_id = "temp-fixed-user-id-for-debug"
    # user_id = current_user.uid
    try:
        docs = await firestore_service.get_documents_by_user(user_id)
        return [
            DocumentResponse(
                id=doc.get("id"),
                userId=doc.get("userId"),
                title=doc.get("title"),
                htmlContent=doc.get("htmlContent"),
                status=doc.get("status"),
                createdAt=str(doc.get("createdAt")),
                updatedAt=str(doc.get("updatedAt")),
            ) for doc in docs
        ]
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error listing documents: {e}")

@router.get("/documents/{doc_id}", response_model=DocumentResponse)
async def get_document(
    doc_id: str,
    # current_user: User = Depends(get_current_user) # 一時的に認証を無効化
):
    """
    指定されたIDのドキュメントを取得
    （注：現在、デバッグのため認証は一時的に無効化されています）
    """
    user_id = "temp-fixed-user-id-for-debug"
    # user_id = current_user.uid
    try:
        doc = await firestore_service.get_document(doc_id)
        if not doc or doc.get("userId") != user_id:
            raise HTTPException(status_code=404, detail="Document not found or access denied")

        return DocumentResponse(
            id=doc_id,
            userId=doc.get("userId"),
            title=doc.get("title"),
            htmlContent=doc.get("htmlContent"),
            status=doc.get("status"),
            createdAt=str(doc.get("createdAt")),
            updatedAt=str(doc.get("updatedAt")),
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error getting document: {e}")

@router.put("/documents/{doc_id}", status_code=status.HTTP_204_NO_CONTENT)
async def update_document(
    doc_id: str,
    doc_in: DocumentUpdate,
    # current_user: User = Depends(get_current_user) # 一時的に認証を無効化
):
    """
    指定されたIDのドキュメントを更新
    （注：現在、デバッグのため認証は一時的に無効化されています）
    """
    user_id = "temp-fixed-user-id-for-debug"
    # user_id = current_user.uid
    try:
        doc = await firestore_service.get_document(doc_id)
        if not doc or doc.get("userId") != user_id:
            raise HTTPException(status_code=404, detail="Document not found or access denied")

        await firestore_service.update_document(doc_id, doc_in.model_dump())
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error updating document: {e}")

@router.delete("/documents/{doc_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_document(
    doc_id: str,
    # current_user: User = Depends(get_current_user) # 一時的に認証を無効化
):
    """
    指定されたIDのドキュメントを削除
    （注：現在、デバッグのため認証は一時的に無効化されています）
    """
    user_id = "temp-fixed-user-id-for-debug"
    # user_id = current_user.uid
    try:
        doc = await firestore_service.get_document(doc_id)
        if not doc or doc.get("userId") != user_id:
            raise HTTPException(status_code=404, detail="Document not found or access denied")

        await firestore_service.delete_document(doc_id)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error deleting document: {e}")
