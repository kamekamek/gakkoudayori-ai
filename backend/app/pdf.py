import asyncio
import base64
from typing import Optional

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

# サービスとツールを相対パスでインポート

# PDF変換のためのライブラリ
try:
    import pdfkit

    PDFKIT_AVAILABLE = True
except ImportError:
    PDFKIT_AVAILABLE = False

try:
    from playwright.async_api import async_playwright

    PLAYWRIGHT_AVAILABLE = True
except ImportError:
    PLAYWRIGHT_AVAILABLE = False

try:
    import weasyprint
    WEASYPRINT_AVAILABLE = True
except (ImportError, OSError) as e:
    WEASYPRINT_AVAILABLE = False
    print(f"WeasyPrint利用不可: {e}")

# APIRouterインスタンスを作成
router = APIRouter(
    prefix="/pdf",
    tags=["PDF"],
)


class PdfRequest(BaseModel):
    html_content: str
    title: str = "学級通信"
    page_size: str = "A4"
    margin: str = "15mm"
    include_header: bool = False
    include_footer: bool = False
    custom_css: str = ""



async def convert_html_to_pdf_pdfkit(
    html_content: str,
    title: str = "学級通信",
    page_size: str = "A4",
    margin: str = "15mm",
    include_header: bool = False,
    include_footer: bool = False,
    custom_css: str = "",
) -> Optional[bytes]:
    """
    pdfkitを使用してHTML文字列をPDFに非同期で変換します。
    """
    if not PDFKIT_AVAILABLE:
        return None

    # wkhtmltopdfの存在確認
    import shutil

    if not shutil.which("wkhtmltopdf"):
        return None

    # 日本語フォント対応のためのカスタムCSS
    font_css = """
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Noto+Sans+JP:wght@400;500;700&display=swap');
        
        body, * {
            font-family: 'Noto Sans JP', 'Hiragino Kaku Gothic ProN', 'Hiragino Sans', 'Yu Gothic', 'Meiryo', sans-serif !important;
            -webkit-font-smoothing: antialiased;
            -moz-osx-font-smoothing: grayscale;
        }
        
        h1, h2, h3, h4, h5, h6 {
            font-family: 'Noto Sans JP', 'Hiragino Kaku Gothic ProN', 'Hiragino Sans', 'Yu Gothic', 'Meiryo', sans-serif !important;
            font-weight: 500;
        }
    </style>
    """
    
    # カスタムCSSがある場合はHTMLに追加
    if custom_css:
        html_content = f"{font_css}<style>{custom_css}</style>\n{html_content}"
    else:
        html_content = f"{font_css}\n{html_content}"

    options = {
        "page-size": page_size,
        "margin-top": margin,
        "margin-right": margin,
        "margin-bottom": margin,
        "margin-left": margin,
        "encoding": "UTF-8",
        "no-outline": None,
        "enable-local-file-access": None,
        "title": title,
        "disable-smart-shrinking": "",
        "print-media-type": "",
        "javascript-delay": 1000,  # JavaScript実行待機時間
        "load-error-handling": "ignore",  # エラー無視
        "load-media-error-handling": "ignore",  # メディアエラー無視
    }

    # ヘッダー・フッターオプション
    if include_header:
        options["header-right"] = title
        options["header-font-size"] = "8"

    if include_footer:
        options["footer-center"] = "ページ [page] / [topage]"
        options["footer-font-size"] = "8"

    try:
        loop = asyncio.get_running_loop()
        pdf_bytes = await loop.run_in_executor(
            None, lambda: pdfkit.from_string(html_content, False, options=options)
        )
        return pdf_bytes
    except Exception as e:
        print(f"pdfkit PDF変換中にエラーが発生しました: {e}")
        return None


async def convert_html_to_pdf_playwright(
    html_content: str,
    title: str = "学級通信",
    page_size: str = "A4",
    margin: str = "15mm",
    include_header: bool = False,
    include_footer: bool = False,
    custom_css: str = "",
) -> Optional[bytes]:
    """
    Playwrightを使用してHTML文字列をPDFに変換します。
    """
    if not PLAYWRIGHT_AVAILABLE:
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
            @import url('https://fonts.googleapis.com/css2?family=Noto+Sans+JP:wght@400;500;700&display=swap');
            
            body {{
                font-family: 'Noto Sans JP', 'Hiragino Kaku Gothic ProN', 'Hiragino Sans', 'Yu Gothic', 'Meiryo', sans-serif;
                line-height: 1.6;
                margin: 0;
                padding: 20px;
                color: #333;
                -webkit-font-smoothing: antialiased;
                -moz-osx-font-smoothing: grayscale;
            }}
            
            h1, h2, h3, h4, h5, h6 {{
                font-family: 'Noto Sans JP', 'Hiragino Kaku Gothic ProN', 'Hiragino Sans', 'Yu Gothic', 'Meiryo', sans-serif;
                font-weight: 500;
            }}
            
            /* PDF印刷用のスタイル調整 */
            * {{
                -webkit-print-color-adjust: exact !important;
                color-adjust: exact !important;
                print-color-adjust: exact !important;
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
        async with async_playwright() as p:
            browser = await p.chromium.launch()
            page = await browser.new_page()
            await page.set_content(full_html)

            # フォント読み込み待機
            await page.wait_for_timeout(2000)
            
            pdf_bytes = await page.pdf(
                format=page_size,
                margin={
                    "top": margin,
                    "right": margin,
                    "bottom": margin,
                    "left": margin,
                },
                print_background=True,
                prefer_css_page_size=True,
            )
            await browser.close()
            return pdf_bytes
    except Exception as e:
        print(f"Playwright PDF変換中にエラーが発生しました: {e}")
        return None


async def convert_html_to_pdf_weasyprint(
    html_content: str,
    title: str = "学級通信",
    page_size: str = "A4",
    margin: str = "15mm",
    include_header: bool = False,
    include_footer: bool = False,
    custom_css: str = "",
) -> Optional[bytes]:
    """
    WeasyPrintを使用してHTML文字列をPDFに変換します（CSS完全対応）。
    """
    if not WEASYPRINT_AVAILABLE:
        return None

    try:
        # 完全なHTMLドキュメントを作成
        full_html = f"""
        <!DOCTYPE html>
        <html lang="ja">
        <head>
            <meta charset="UTF-8">
            <title>{title}</title>
            <style>
                @import url('https://fonts.googleapis.com/css2?family=Noto+Sans+JP:wght@400;500;700&display=swap');
                
                @page {{
                    size: {page_size};
                    margin: {margin};
                }}
                
                body {{
                    font-family: 'Noto Sans JP', 'Hiragino Kaku Gothic ProN', 'Hiragino Sans', 'Yu Gothic', 'Meiryo', sans-serif;
                    line-height: 1.6;
                    margin: 0;
                    padding: 0;
                    color: #333;
                }}
                
                h1, h2, h3, h4, h5, h6 {{
                    font-family: 'Noto Sans JP', 'Hiragino Kaku Gothic ProN', 'Hiragino Sans', 'Yu Gothic', 'Meiryo', sans-serif;
                    font-weight: 500;
                }}
                
                {custom_css}
            </style>
        </head>
        <body>
            {html_content}
        </body>
        </html>
        """

        # WeasyPrintでPDF生成
        html_doc = weasyprint.HTML(string=full_html)
        pdf_bytes = html_doc.write_pdf()
        
        return pdf_bytes
        
    except Exception as e:
        print(f"WeasyPrint PDF変換中にエラーが発生しました: {e}")
        return None


async def convert_html_to_pdf_simple(
    html_content: str,
    title: str = "学級通信",
    page_size: str = "A4",
    margin: str = "15mm",
    include_header: bool = False,
    include_footer: bool = False,
    custom_css: str = "",
) -> Optional[bytes]:
    """
    ReportLabを使用してHTMLから基本的なPDFを生成します。
    CSSは制限されますが、HTMLの構造を読み取って美しいPDFを作成します。
    """
    try:
        from io import BytesIO
        import re
        from html import unescape

        from reportlab.lib.pagesizes import A4
        from reportlab.pdfgen import canvas
        from reportlab.lib.colors import Color
        from reportlab.pdfbase import pdfmetrics
        from reportlab.pdfbase.ttfonts import TTFont

        buffer = BytesIO()
        p = canvas.Canvas(buffer, pagesize=A4)
        
        # 日本語フォント対応の試行
        try:
            # Hiragino Sans があれば使用
            p.setFont("HeiseiKakuGo-W5", 16)
        except:
            try:
                p.setFont("HeiseiMin-W3", 16)
            except:
                p.setFont("Helvetica", 16)

        # HTMLから構造化されたコンテンツを抽出
        content = _extract_structured_content(html_content)
        
        # A4サイズでの描画開始
        y_position = 750
        margin_left = 50
        page_width = A4[0] - 100  # 左右マージンを考慮

        # タイトル描画
        try:
            p.setFont("HeiseiKakuGo-W5", 20)
        except:
            p.setFont("Helvetica-Bold", 20)
        
        # タイトルの中央寄せ
        title_width = p.stringWidth(title, "Helvetica-Bold", 20)
        title_x = (A4[0] - title_width) / 2
        p.drawString(title_x, y_position, title)
        y_position -= 40

        # 区切り線
        p.setStrokeColor(Color(0.8, 0.8, 0.8))
        p.line(margin_left, y_position, A4[0] - margin_left, y_position)
        y_position -= 30

        # メイン通常フォント
        try:
            p.setFont("HeiseiKakuGo-W5", 12)
        except:
            p.setFont("Helvetica", 12)

        # 構造化されたコンテンツを描画
        for item in content['items']:
            if y_position < 100:  # 新しいページが必要
                p.showPage()
                y_position = 750
                try:
                    p.setFont("HeiseiKakuGo-W5", 12)
                except:
                    p.setFont("Helvetica", 12)

            if item['type'] == 'header':
                # ヘッダー
                p.setFillColor(Color(0.2, 0.4, 0.8))
                try:
                    p.setFont("HeiseiKakuGo-W5", 16)
                except:
                    p.setFont("Helvetica-Bold", 16)
                p.drawString(margin_left, y_position, item['text'])
                y_position -= 25
                p.setFillColor(Color(0, 0, 0))  # 通常の黒色に戻す
                
            elif item['type'] == 'subheader':
                # サブヘッダー
                p.setFillColor(Color(0.4, 0.4, 0.4))
                try:
                    p.setFont("HeiseiKakuGo-W5", 14)
                except:
                    p.setFont("Helvetica-Bold", 14)
                p.drawString(margin_left, y_position, item['text'])
                y_position -= 20
                p.setFillColor(Color(0, 0, 0))
                
            elif item['type'] == 'paragraph':
                # 段落
                try:
                    p.setFont("HeiseiKakuGo-W5", 12)
                except:
                    p.setFont("Helvetica", 12)
                    
                # 長いテキストの折り返し処理
                words = item['text'].split()
                lines = []
                current_line = ""
                for word in words:
                    test_line = current_line + (" " if current_line else "") + word
                    if p.stringWidth(test_line, "Helvetica", 12) < page_width - 100:
                        current_line = test_line
                    else:
                        if current_line:
                            lines.append(current_line)
                        current_line = word
                if current_line:
                    lines.append(current_line)
                
                for line in lines:
                    if y_position < 100:
                        p.showPage()
                        y_position = 750
                    p.drawString(margin_left, y_position, line)
                    y_position -= 15
                y_position -= 5  # 段落間のスペース

        # フッター
        try:
            p.setFont("HeiseiKakuGo-W5", 10)
        except:
            p.setFont("Helvetica", 10)
        p.setFillColor(Color(0.5, 0.5, 0.5))
        footer_text = f"{title} - {content.get('school_name', '')} {content.get('class_name', '')}"
        p.drawString(margin_left, 30, footer_text)

        p.save()
        buffer.seek(0)
        return buffer.getvalue()
        
    except ImportError:
        return None
    except Exception as e:
        print(f"Enhanced PDF変換中にエラーが発生しました: {e}")
        return None


def _extract_structured_content(html_content: str) -> dict:
    """HTMLから構造化されたコンテンツを抽出"""
    import re
    from html import unescape
    
    content = {
        'items': [],
        'school_name': '',
        'class_name': ''
    }
    
    # HTMLタグを除去して構造を解析
    # h1タグを抽出
    h1_matches = re.findall(r'<h1[^>]*>(.*?)</h1>', html_content, re.DOTALL | re.IGNORECASE)
    for h1 in h1_matches:
        clean_text = re.sub(r'<[^>]+>', '', h1).strip()
        clean_text = unescape(clean_text)
        if clean_text:
            content['items'].append({'type': 'header', 'text': clean_text})
            # 学校名・クラス名を抽出
            if '小学校' in clean_text or '中学校' in clean_text:
                content['school_name'] = clean_text.split()[0] if ' ' in clean_text else clean_text
            if '年' in clean_text and '組' in clean_text:
                content['class_name'] = clean_text.split()[-1] if ' ' in clean_text else clean_text

    # h2タグを抽出
    h2_matches = re.findall(r'<h2[^>]*>(.*?)</h2>', html_content, re.DOTALL | re.IGNORECASE)
    for h2 in h2_matches:
        clean_text = re.sub(r'<[^>]+>', '', h2).strip()
        clean_text = unescape(clean_text)
        if clean_text:
            content['items'].append({'type': 'subheader', 'text': clean_text})

    # pタグを抽出
    p_matches = re.findall(r'<p[^>]*>(.*?)</p>', html_content, re.DOTALL | re.IGNORECASE)
    for p in p_matches:
        clean_text = re.sub(r'<[^>]+>', '', p).strip()
        clean_text = unescape(clean_text)
        if clean_text:
            content['items'].append({'type': 'paragraph', 'text': clean_text})
    
    # タグなしのテキストも抽出（フォールバック）
    if not content['items']:
        clean_html = re.sub(r'<[^>]+>', ' ', html_content)
        clean_html = unescape(clean_html).strip()
        if clean_html:
            # 改行で分割して段落として追加
            paragraphs = [p.strip() for p in clean_html.split('\n') if p.strip()]
            for para in paragraphs:
                content['items'].append({'type': 'paragraph', 'text': para})
    
    return content


async def convert_html_to_pdf(
    html_content: str,
    title: str = "学級通信",
    page_size: str = "A4",
    margin: str = "15mm",
    include_header: bool = False,
    include_footer: bool = False,
    custom_css: str = "",
) -> Optional[bytes]:
    """
    HTML文字列をPDFに変換します。利用可能なライブラリを順次試行します。
    """
    # WeasyPrintを最初に試行（CSS完全対応）
    if WEASYPRINT_AVAILABLE:
        print("WeasyPrintを使用してPDF変換を試行します...")
        result = await convert_html_to_pdf_weasyprint(
            html_content,
            title,
            page_size,
            margin,
            include_header,
            include_footer,
            custom_css,
        )
        if result:
            return result

    # Playwrightを次に試行
    if PLAYWRIGHT_AVAILABLE:
        print("Playwrightを使用してPDF変換を試行します...")
        result = await convert_html_to_pdf_playwright(
            html_content,
            title,
            page_size,
            margin,
            include_header,
            include_footer,
            custom_css,
        )
        if result:
            return result

    # pdfkitを試行
    if PDFKIT_AVAILABLE:
        print("pdfkitを使用してPDF変換を試行します...")
        result = await convert_html_to_pdf_pdfkit(
            html_content,
            title,
            page_size,
            margin,
            include_header,
            include_footer,
            custom_css,
        )
        if result:
            return result

    # 最後の手段としてシンプルPDF生成
    print("シンプルPDF生成を試行します...")
    result = await convert_html_to_pdf_simple(
        html_content,
        title,
        page_size,
        margin,
        include_header,
        include_footer,
        custom_css,
    )
    if result:
        return result

    print("PDF変換ライブラリが利用できません。")
    print("推奨: uv add weasyprint (CSS完全対応)")
    print("または: uv add playwright && playwright install chromium")
    print("または: uv add reportlab (基本的なPDF生成のみ)")
    return None


@router.post(
    "/generate",
    summary="HTMLからPDFを生成して保存",
    response_description="生成されたPDFへの署名付きURL",
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
            custom_css=req.custom_css,
        )

        if pdf_bytes is None:
            raise HTTPException(
                status_code=500,
                detail="HTMLからPDFへの変換に失敗しました。pdfkitの設定を確認してください。",
            )

        # Base64エンコードしてフロントエンドに返す
        pdf_base64 = base64.b64encode(pdf_bytes).decode("utf-8")

        return {
            "success": True,
            "data": {
                "pdf_base64": pdf_base64,
                "file_size_mb": round(len(pdf_bytes) / (1024 * 1024), 2),
                "page_count": 1,  # 実際のページ数は簡単には取得できないため固定値
                "title": req.title,
            },
        }

    except Exception as e:
        print(f"PDF生成エラー: {e}")
        raise HTTPException(status_code=500, detail=f"PDF生成に失敗しました: {str(e)}")
