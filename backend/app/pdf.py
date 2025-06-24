from fastapi import APIRouter, HTTPException, Body, Depends
from pydantic import BaseModel
from typing import Annotated

# サービスとツールを絶対パスでインポート
from backend.services import storage, firestore_service
from backend.agents.tools.pdf_converter import convert_html_to_pdf

# APIRouterインスタンスを作成
router = APIRouter(
    prefix="/pdf",
    tags=["PDF"],
)

class PdfRequest(BaseModel):
    html_content: str
    session_id: str
    document_id: str # Firestoreの更新対象ドキュメントID

@router.post(
    "/", 
    summary="HTMLからPDFを生成して保存",
    response_description="生成されたPDFへの署名付きURL"
)
async def generate_and_save_pdf(req: PdfRequest):
    """
    HTMLコンテンツを受け取り、PDFに変換後、GCSにアップロードします。
    その後、対応するFirestoreドキュメントにPDFのURLを保存します。
    """
    # 1. HTMLをPDFに変換
    pdf_bytes = await convert_html_to_pdf(html_content=req.html_content)

    if not pdf_bytes or "PDF変換中にエラーが発生しました" in pdf_bytes.decode('utf-8', errors='ignore'):
        raise HTTPException(
            status_code=500, 
            detail=f"HTMLからPDFへの変換に失敗しました: {pdf_bytes.decode('utf-8', errors='ignore')}"
        )

    try:
        # 2. PDFをGoogle Cloud Storageに保存
        pdf_url = await storage.save_pdf_to_gcs(
            session_id=req.session_id,
            pdf_content=pdf_bytes
        )

        # 3. FirestoreドキュメントをPDFのURLで更新
        await firestore_service.update_newsletter_pdf_url(
            document_id=req.document_id,
            pdf_url=pdf_url
        )

        return {"status": "success", "pdf_url": pdf_url}

    except Exception as e:
        # エラーロギング
        print(f"PDFの処理またはアップロード中にエラーが発生しました: {e}")
        raise HTTPException(status_code=500, detail=f"予期せぬエラーが発生しました: {str(e)}")
