from datetime import datetime, timezone
from functools import lru_cache
from typing import Any, Dict, List, Optional

from google.cloud import firestore

from app.auth import User


@lru_cache()
def get_db_client() -> firestore.AsyncClient:
    """Firestoreクライアントのシングルトンインスタンスを返す"""
    return firestore.AsyncClient()

async def get_or_create_user(user: User) -> Dict[str, Any]:
    """
    Firestoreにユーザーが存在するか確認し、存在しない場合は作成する。
    ユーザー情報を返す。
    """
    db = get_db_client()
    user_ref = db.collection("users").document(user.uid)
    doc = await user_ref.get()

    if doc.exists:
        return doc.to_dict()
    else:
        user_data = {
            "uid": user.uid,
            "email": user.email,
            "displayName": user.name,
            "photoURL": user.picture,
            "createdAt": datetime.now(timezone.utc),
            "googleRefreshToken": None,  # 初期値はNone
        }
        await user_ref.set(user_data)
        return user_data

async def save_document(
    user_id: str, title: str, html_content: str, conversation_history: List[Dict]
) -> str:
    """
    生成された学級通信をFirestoreのdocumentsコレクションに保存します。
    """
    db = get_db_client()
    collection_ref = db.collection("documents")
    now = datetime.now(timezone.utc)
    doc_ref = await collection_ref.add(
        {
            "userId": user_id,
            "title": title,
            "htmlContent": html_content,
            "conversationHistory": conversation_history,
            "status": "draft",
            "createdAt": now,
            "updatedAt": now,
        }
    )
    return doc_ref.id

async def get_document(document_id: str) -> Optional[Dict[str, Any]]:
    """
    指定されたIDのドキュメントをFirestoreから取得します。
    """
    db = get_db_client()
    doc_ref = db.collection("documents").document(document_id)
    doc = await doc_ref.get()
    if doc.exists:
        return doc.to_dict()
    return None

async def get_documents_by_user(user_id: str) -> List[Dict[str, Any]]:
    """
    指定されたユーザーが作成したドキュメントの一覧を取得します。
    """
    db = get_db_client()
    docs_query = (
        db.collection("documents")
        .where("userId", "==", user_id)
        .order_by("updatedAt", direction=firestore.Query.DESCENDING)
    )
    docs_stream = docs_query.stream()

    documents = []
    async for doc in docs_stream:
        doc_data = doc.to_dict()
        doc_data["id"] = doc.id
        documents.append(doc_data)
    return documents

async def update_document(document_id: str, update_data: Dict[str, Any]) -> None:
    """
    指定されたIDのドキュメントを更新します。
    """
    db = get_db_client()
    doc_ref = db.collection("documents").document(document_id)
    update_data["updatedAt"] = datetime.now(timezone.utc)
    await doc_ref.update(update_data)

async def delete_document(document_id: str) -> None:
    """
    指定されたIDのドキュメントを削除します。
    """
    db = get_db_client()
    await db.collection("documents").document(document_id).delete()
