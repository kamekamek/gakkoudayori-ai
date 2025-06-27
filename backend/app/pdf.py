from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from agents.tools.pdf_converter import convert_html_to_pdf

# サービスとツールを相対パスでインポート
from services import firestore_service, storage

# APIRouterインスタンスを作成
router = APIRouter(
    prefix="/pdf",
    tags=["PDF"],
)

class PdfRequest(BaseModel):
    html_content: str
    title: str = '学級通信'
    page_size: str = 'A4'
    margin: str = '15mm'
    include_header: bool = False
    include_footer: bool = False
    custom_css: str = ''

@router.post(
    "/generate",
    summary="HTMLからPDFを生成して保存",
    response_description="生成されたPDFへの署名付きURL"
)
async def generate_and_save_pdf(req: PdfRequest):
    """
    HTMLコンテンツを受け取り、PDFに変換します。
    フロントエンド互換のシンプルなPDF生成エンドポイント。
    """
    try:
        # HTMLをPDFに変換
        pdf_bytes = await convert_html_to_pdf(
            html_content=req.html_content,
            title=req.title,
            page_size=req.page_size,
            margin=req.margin,
            include_header=req.include_header,
            include_footer=req.include_footer,
            custom_css=req.custom_css
        )

        if pdf_bytes is None:
            raise HTTPException(
                status_code=500,
                detail="HTMLからPDFへの変換に失敗しました。"
            )

        # Base64エンコードしてフロントエンドに返す
        import base64
        pdf_base64 = base64.b64encode(pdf_bytes).decode('utf-8')
        
        return {
            "success": True,
            "data": {
                "pdf_base64": pdf_base64,
                "file_size_mb": round(len(pdf_bytes) / (1024 * 1024), 2),
                "page_count": 1,  # 実際のページ数は簡単には取得できないため固定値
                "title": req.title
            }
        }

    except Exception as e:
        print(f"PDF生成エラー: {e}")
        raise HTTPException(
            status_code=500, 
            detail=f"PDF生成に失敗しました: {str(e)}"
        )
