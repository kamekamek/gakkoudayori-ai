import asyncio
import base64
from typing import Optional
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

# サービスとツールを相対パスでインポート
from services import firestore_service, storage

# PDF変換のためのライブラリ
try:
    from weasyprint import HTML
    WEASYPRINT_AVAILABLE = True
except ImportError:
    WEASYPRINT_AVAILABLE = False

try:
    import pdfkit
    PDFKIT_AVAILABLE = True
except ImportError:
    PDFKIT_AVAILABLE = False

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

async def convert_html_to_pdf_weasyprint(
    html_content: str,
    title: str = '学級通信',
    page_size: str = 'A4',
    margin: str = '15mm',
    include_header: bool = False,
    include_footer: bool = False,
    custom_css: str = ''
) -> Optional[bytes]:
    """
    WeasyPrintを使用してHTML文字列をPDFに非同期で変換します。
    """
    if not WEASYPRINT_AVAILABLE:
        print("WeasyPrintが利用できません。uv add weasyprintを実行してください。")
        return None
    
    # カスタムCSSがある場合はHTMLに追加
    full_html = f"""
    <!DOCTYPE html>
    <html lang="ja">
    <head>
        <meta charset="UTF-8">
        <title>{title}</title>
        <style>
            @page {{
                size: {page_size};
                margin: {margin};
            }}
            body {{
                font-family: 'Hiragino Sans', 'Yu Gothic', sans-serif;
                line-height: 1.6;
            }}
            {custom_css}
        </style>
    </head>
    <body>
        {html_content}
    </body>
    </html>
    """
    
    try:
        # WeasyPrintは非同期に対応していないため、run_in_executorでブロッキングを防ぐ
        loop = asyncio.get_running_loop()
        pdf_bytes = await loop.run_in_executor(
            None,
            lambda: HTML(string=full_html).write_pdf()
        )
        return pdf_bytes
    except Exception as e:
        print(f"WeasyPrint PDF変換中にエラーが発生しました: {e}")
        return None


async def convert_html_to_pdf_pdfkit(
    html_content: str,
    title: str = '学級通信',
    page_size: str = 'A4',
    margin: str = '15mm',
    include_header: bool = False,
    include_footer: bool = False,
    custom_css: str = ''
) -> Optional[bytes]:
    """
    pdfkitを使用してHTML文字列をPDFに非同期で変換します。
    """
    if not PDFKIT_AVAILABLE:
        return None
    
    # wkhtmltopdfの存在確認
    import shutil
    if not shutil.which('wkhtmltopdf'):
        return None
    
    # カスタムCSSがある場合はHTMLに追加
    if custom_css:
        html_content = f"<style>{custom_css}</style>\n{html_content}"
    
    options = {
        'page-size': page_size,
        'margin-top': margin,
        'margin-right': margin,
        'margin-bottom': margin,
        'margin-left': margin,
        'encoding': "UTF-8",
        'no-outline': None,
        'enable-local-file-access': None,
        'title': title,
        'disable-smart-shrinking': '',
        'print-media-type': '',
    }
    
    # ヘッダー・フッターオプション
    if include_header:
        options['header-right'] = title
        options['header-font-size'] = '8'
    
    if include_footer:
        options['footer-center'] = 'ページ [page] / [topage]'
        options['footer-font-size'] = '8'
    
    try:
        loop = asyncio.get_running_loop()
        pdf_bytes = await loop.run_in_executor(
            None,
            lambda: pdfkit.from_string(html_content, False, options=options)
        )
        return pdf_bytes
    except Exception as e:
        print(f"pdfkit PDF変換中にエラーが発生しました: {e}")
        return None


async def convert_html_to_pdf(
    html_content: str,
    title: str = '学級通信',
    page_size: str = 'A4',
    margin: str = '15mm',
    include_header: bool = False,
    include_footer: bool = False,
    custom_css: str = ''
) -> Optional[bytes]:
    """
    HTML文字列をPDFに変換します。利用可能なライブラリを順次試行します。
    """
    # WeasyPrintを最初に試行（より安定している）
    if WEASYPRINT_AVAILABLE:
        print("WeasyPrintを使用してPDF変換を試行します...")
        result = await convert_html_to_pdf_weasyprint(
            html_content, title, page_size, margin, include_header, include_footer, custom_css
        )
        if result:
            return result
    
    # pdfkitをフォールバックとして試行
    if PDFKIT_AVAILABLE:
        print("pdfkitを使用してPDF変換を試行します...")
        result = await convert_html_to_pdf_pdfkit(
            html_content, title, page_size, margin, include_header, include_footer, custom_css
        )
        if result:
            return result
    
    print("PDF変換ライブラリが利用できません。")
    print("推奨: uv add weasyprint")
    print("または: uv add pdfkit && brew install wkhtmltopdf")
    return None


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
                detail="HTMLからPDFへの変換に失敗しました。pdfkitの設定を確認してください。"
            )

        # Base64エンコードしてフロントエンドに返す
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
