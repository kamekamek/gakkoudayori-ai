from google.cloud import firestore
from datetime import datetime

# Firestoreクライアントを初期化
# このファイルがインポートされると、GCPの認証情報が環境変数から自動的に読み込まれます。
db = firestore.AsyncClient()

async def save_newsletter(user_id: str, title: str, html_content: str) -> str:
    """
    生成された学級通信をFirestoreに保存します。

    Args:
        user_id: ユーザーID。
        title: 学級通信のタイトル。
        html_content: 生成されたHTMLコンテンツ。

    Returns:
        作成されたドキュメントのID。
    """
    collection_ref = db.collection("newsletters")
    doc_ref = await collection_ref.add({
        "user_id": user_id,
        "title": title,
        "html_content": html_content,
        "created_at": datetime.utcnow(),
        "pdf_url": None,  # PDFは後から生成・更新される
    })
    return doc_ref.id

async def get_newsletter(document_id: str) -> dict | None:
    """
    指定されたIDの学級通信をFirestoreから取得します。

    Args:
        document_id: 取得するドキュメントのID。

    Returns:
        ドキュメントのデータを辞書として返します。存在しない場合はNoneを返します。
    """
    doc_ref = db.collection("newsletters").document(document_id)
    doc = await doc_ref.get()
    if doc.exists:
        return doc.to_dict()
    return None

async def update_newsletter_pdf_url(document_id: str, pdf_url: str):
    """
    学級通信ドキュメントに、生成されたPDFへのURLを保存します。

    Args:
        document_id: 更新するドキュメントのID。
        pdf_url: 保存するPDFのURL。
    """
    doc_ref = db.collection("newsletters").document(document_id)
    await doc_ref.update({
        "pdf_url": pdf_url
    })
