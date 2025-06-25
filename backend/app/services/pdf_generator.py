"""
HTML学級通信PDF変換サービス

生成されたHTMLコンテンツをPDFに変換し、
配信準備を行います。
"""

import os
import logging
import time
import tempfile
import base64
from typing import Dict, Any, Optional
from datetime import datetime
import asyncio
from pathlib import Path
import re

# PDF生成関連
try:
    from weasyprint import HTML, CSS
    WEASYPRINT_AVAILABLE = True
except ImportError:
    WEASYPRINT_AVAILABLE = False
    print("WeasyPrint not installed. Installing...")
    os.system("pip install weasyprint")
    try:
        from weasyprint import HTML, CSS
        WEASYPRINT_AVAILABLE = True
    except ImportError:
        WEASYPRINT_AVAILABLE = False

# 画像処理関連
try:
    from PIL import Image
    import io
    PIL_AVAILABLE = True
except ImportError:
    PIL_AVAILABLE = False
    print("Pillow not installed. Installing...")
    os.system("pip install Pillow")
    try:
        from PIL import Image
        import io
        PIL_AVAILABLE = True
    except ImportError:
        PIL_AVAILABLE = False

# 設定
logger = logging.getLogger(__name__)

# PDF設定
DEFAULT_PAGE_SIZE = 'A4'
DEFAULT_MARGIN = '15mm'
DEFAULT_DPI = 300

def _get_available_japanese_fonts() -> list:
    """利用可能な日本語フォントを検出 - プレビューと統一"""
    import platform
    
    # プレビューと統一したフォント設定
    fonts = [
        "Noto Sans JP",
        "Hiragino Sans", 
        "Yu Gothic"
    ]
    
    # OS別の追加フォント候補（フォールバック用）
    if platform.system() == "Darwin":  # macOS
        fonts.extend([
            "Hiragino Kaku Gothic ProN",
            "Osaka"
        ])
    elif platform.system() == "Windows":
        fonts.extend([
            "Meiryo",
            "MS PGothic",
            "MS Gothic"
        ])
    else:  # Linux
        fonts.extend([
            "Noto Sans CJK JP",
            "DejaVu Sans",
            "Liberation Sans"
        ])
    
    # 基本的なフォールバック
    fonts.extend(["sans-serif", "serif"])
    return fonts

def generate_pdf_from_html_bytes(html_content: str) -> bytes:
    if not WEASYPRINT_AVAILABLE:
        raise RuntimeError("WeasyPrint is not available.")
    full_html = _build_complete_html_document(
        html_content=html_content,
        title="学級通信",
        page_size=DEFAULT_PAGE_SIZE,
        margin=DEFAULT_MARGIN,
        include_header=False,
        include_footer=False,
        custom_css="",
        font_family=", ".join([f'"{font}"' for font in _get_available_japanese_fonts()])
    )
    return HTML(string=full_html).write_pdf()


def generate_pdf_from_html(
    html_content: str,
    title: str = "学級通信",
    page_size: str = DEFAULT_PAGE_SIZE,
    margin: str = DEFAULT_MARGIN,
    include_header: bool = False,
    include_footer: bool = False,
    custom_css: str = "",
    output_path: Optional[str] = None
) -> Dict[str, Any]:
    """
    HTMLコンテンツからPDFを生成
    
    Args:
        html_content (str): PDF化するHTMLコンテンツ
        title (str): ドキュメントタイトル
        page_size (str): ページサイズ (A4, A3, Letter等)
        margin (str): マージン (例: "20mm", "1in")
        include_header (bool): ヘッダーを含めるか
        include_footer (bool): フッターを含めるか
        custom_css (str): 追加のCSS
        output_path (str): 出力パス (指定しない場合は一時ファイル)
        
    Returns:
        Dict[str, Any]: PDF生成結果
    """
    start_time = time.time()
    
    try:
        if not WEASYPRINT_AVAILABLE:
            return {
                'success': False,
                'error': 'WeasyPrint is not available. PDF generation requires WeasyPrint.',
                'error_code': 'WEASYPRINT_NOT_AVAILABLE',
                'processing_time_ms': int((time.time() - start_time) * 1000)
            }
        
        # フォント処理のログレベルを一時的に変更
        import logging
        font_logger = logging.getLogger('fontTools')
        original_level = font_logger.level
        font_logger.setLevel(logging.WARNING)  # INFO以下のログを抑制
        
        try:
            # 利用可能な日本語フォントを取得
            available_fonts = _get_available_japanese_fonts()
            font_family = ", ".join([f'"{font}"' for font in available_fonts])
            
            # デバッグ用：HTMLコンテンツの先頭を確認
            html_preview = html_content[:200] + "..." if len(html_content) > 200 else html_content
            logger.info(f"入力HTMLプレビュー: {html_preview}")
            
            # HTML文書を構築
            full_html = _build_complete_html_document(
                html_content=html_content,
                title=title,
                page_size=page_size,
                margin=margin,
                include_header=include_header,
                include_footer=include_footer,
                custom_css=custom_css,
                font_family=font_family
            )
            
            # デバッグ用：生成されたHTML文書の先頭を確認
            full_html_preview = full_html[:300] + "..." if len(full_html) > 300 else full_html
            logger.info(f"生成HTML文書プレビュー: {full_html_preview}")
            
            # 出力パス決定（Cloud Run環境対応）
            if output_path is None:
                # Cloud Run環境では/tmpディレクトリを使用
                temp_dir = '/tmp' if os.path.exists('/tmp') else tempfile.gettempdir()
                temp_file = tempfile.NamedTemporaryFile(delete=False, suffix='.pdf', dir=temp_dir)
                output_path = temp_file.name
                temp_file.close()
                logger.info(f"Using temporary file: {output_path}")
            
            # PDF生成実行（日本語フォント対応）
            logger.info(f"Generating PDF: {output_path}")
            logger.info(f"Using font family: {font_family}")
            
            # HTMLドキュメント作成（WeasyPrint 60.x対応）
            # WeasyPrint HTMLドキュメント作成
            html_doc = HTML(string=full_html)
            
            # PDF生成
            html_doc.write_pdf(output_path)
            
            logger.info("PDF generation completed with Japanese font support")
            
        finally:
            # フォント処理のログレベルを元に戻す
            font_logger.setLevel(original_level)
        
        # ファイル情報取得
        file_size = os.path.getsize(output_path)
        
        # PDF内容をBase64エンコード（API応答用）
        with open(output_path, 'rb') as pdf_file:
            pdf_base64 = base64.b64encode(pdf_file.read()).decode('utf-8')
        
        processing_time = time.time() - start_time
        
        result = {
            'success': True,
            'data': {
                'pdf_path': output_path,
                'pdf_base64': pdf_base64,
                'file_size_bytes': file_size,
                'file_size_mb': round(file_size / (1024 * 1024), 2),
                'title': title,
                'page_size': page_size,
                'margin': margin,
                'processing_time_ms': int(processing_time * 1000),
                'generated_at': datetime.now().isoformat(),
                'page_count': _get_pdf_page_count(output_path)
            }
        }
        
        logger.info(f"PDF generation successful. File size: {file_size} bytes, Time: {processing_time:.3f}s")
        return result
        
    except Exception as e:
        error_msg = f"PDF generation failed: {str(e)}"
        error_type = type(e).__name__
        logger.error(f"PDF generation error ({error_type}): {error_msg}")
        logger.error(f"WeasyPrint available: {WEASYPRINT_AVAILABLE}")
        logger.error(f"PIL available: {PIL_AVAILABLE}")
        
        # より詳細なエラー情報を提供
        error_details = {
            'error_type': error_type,
            'weasyprint_available': WEASYPRINT_AVAILABLE,
            'pil_available': PIL_AVAILABLE,
            'temp_dir_writable': os.access('/tmp', os.W_OK) if os.path.exists('/tmp') else False
        }
        
        return {
            'success': False,
            'error': error_msg,
            'error_code': 'PDF_GENERATION_ERROR',
            'error_details': error_details,
            'processing_time_ms': int((time.time() - start_time) * 1000)
        }

def _build_complete_html_document(
    html_content: str,
    title: str,
    page_size: str,
    margin: str,
    include_header: bool,
    include_footer: bool,
    custom_css: str,
    font_family: str = None
) -> str:
    """
    完全なHTML文書を構築
    
    Args:
        html_content (str): メインHTMLコンテンツ
        title (str): ドキュメントタイトル
        page_size (str): ページサイズ
        margin (str): マージン
        include_header (bool): ヘッダー含有フラグ
        include_footer (bool): フッター含有フラグ
        custom_css (str): カスタムCSS
        
    Returns:
        str: 完全なHTML文書
    """
    
    # HTMLコンテンツの前処理と検査
    clean_html_content = html_content.strip()
    
    # 【重要】Markdownコードブロックのクリーンアップを追加
    clean_html_content = _clean_markdown_codeblocks_pdf(clean_html_content)
    
    # 既に完全なHTMLドキュメントかチェック
    html_lower = clean_html_content.lower()
    is_complete_html = (
        '<!doctype html>' in html_lower and
        '<html' in html_lower and
        '</html>' in html_lower and
        '<head' in html_lower and
        '<body' in html_lower and
        '</body>' in html_lower
    )
    
    # 既に完全なHTMLドキュメントの場合は、そのまま返す（PDF用CSS調整のみ）
    if is_complete_html:
        logger.info("完全なHTMLドキュメントを検出：PDF用CSS調整のみ実行")
        
        # PDF用CSSの追加
        pdf_css = f"""
        /* 日本語フォント対応 - プレビューと統一 */
        @import url('https://fonts.googleapis.com/css2?family=Noto+Sans+JP:wght@300;400;500;700&display=swap');
        
        @page {{
            size: {page_size};
            margin: {margin};
            @bottom-center {{
                content: counter(page);
                font-family: 'Noto Sans JP', sans-serif;
                font-size: 10pt;
                color: #666;
            }}
        }}
        
        @page:first {{
            @bottom-center {{
                content: none;
            }}
        }}
        
        body {{
            font-family: 'Noto Sans JP', 'Hiragino Sans', 'Yu Gothic', sans-serif !important;
            -webkit-print-color-adjust: exact !important;
            print-color-adjust: exact !important;
        }}
        
        .a4-sheet {{
            width: 100% !important;
            min-height: auto !important;
            margin: 0 !important;
            padding: 10mm !important;
            box-shadow: none !important;
            background: white !important;
        }}
        
        .print-container {{
            width: 100% !important;
            min-height: auto !important;
            margin: 0 !important;
            padding: 0 !important;
            box-shadow: none !important;
        }}
        
        {custom_css}
        """
        
        # 既存のスタイルタグ内にPDF用CSSを追加
        if "<style>" in clean_html_content and "</style>" in clean_html_content:
            clean_html_content = clean_html_content.replace("</style>", f"\n{pdf_css}\n</style>", 1)
        else:
            # head内にスタイルタグを追加
            head_end = clean_html_content.find("</head>")
            if head_end != -1:
                clean_html_content = (
                    clean_html_content[:head_end] +
                    f"<style>{pdf_css}</style>\n" +
                    clean_html_content[head_end:]
                )
        
        return clean_html_content
    
    # 以下、不完全なHTMLの場合の従来処理
    
    # 元のHTMLコンテンツからスタイルを抽出
    original_styles = ""
    if "<style>" in clean_html_content and "</style>" in clean_html_content:
        start_idx = clean_html_content.find("<style>") + 7
        end_idx = clean_html_content.find("</style>")
        original_styles = clean_html_content[start_idx:end_idx]
    
    # PDF用CSS（最小限の調整のみ）
    pdf_css = f"""
    /* 日本語フォント対応 - プレビューと統一 */
    @import url('https://fonts.googleapis.com/css2?family=Noto+Sans+JP:wght@300;400;500;700&display=swap');
    
    @page {{
        size: {page_size};
        margin: {margin};
        /* ページ番号は2ページ目以降のみ */
        @bottom-center {{
            content: counter(page);
            font-family: 'Noto Sans JP', sans-serif;
            font-size: 10pt;
            color: #666;
        }}
    }}
    
    @page:first {{
        @bottom-center {{
            content: none;
        }}
    }}
    
    /* 元のスタイルを保持 */
    {original_styles}
    
    /* PDF出力時の調整 - プレビューと統一 */
    body {{
        font-family: 'Noto Sans JP', 'Hiragino Sans', 'Yu Gothic', sans-serif !important;
        -webkit-print-color-adjust: exact !important;
        print-color-adjust: exact !important;
        margin: 0 !important;
        padding: 0 !important;
    }}
    
    /* A4シートのマージン調整 - プレビューと統一 */
    .a4-sheet {{
        width: 100% !important;
        min-height: auto !important;
        margin: 0 !important;
        padding: 10mm !important;
        box-shadow: none !important;
        background: white !important;
    }}
    
    /* プリントコンテナの調整 - プレビューと統一 */
    .print-container {{
        width: 100% !important;
        min-height: auto !important;
        margin: 0 !important;
        padding: 0 !important;
        box-shadow: none !important;
    }}
    
    /* フォントサイズの調整 - プレビューと完全統一 */
    h1 {{
        font-size: 18px !important;
        margin: 8px 0 !important;
        line-height: 1.2 !important;
    }}
    
    h2 {{
        font-size: 16px !important;
        margin: 6px 0 !important;
        line-height: 1.2 !important;
    }}
    
    h3 {{
        font-size: 14px !important;
        margin: 4px 0 !important;
        line-height: 1.2 !important;
    }}
    
    p {{
        font-size: 12px !important;
        line-height: 1.3 !important;
        margin: 3px 0 !important;
    }}
    
    /* セクション間のマージン - プレビューと統一 */
    .section {{
        margin-bottom: 8px !important;
        padding: 8px !important;
    }}
    
    .content-section {{
        margin-bottom: 6px !important;
        padding: 6px !important;
    }}
    
    /* 改ページ制御の強化 */
    .page-break {{
        page-break-before: always;
    }}
    
    .no-break {{
        page-break-inside: avoid;
    }}
    
    /* 不要な改ページを防ぐ */
    h1, h2, h3 {{
        page-break-after: avoid !important;
        page-break-inside: avoid !important;
    }}
    
    /* 画像の最大幅制限 */
    img {{
        max-width: 100% !important;
        height: auto !important;
    }}
    
    /* テーブルの改ページ制御 */
    table {{
        page-break-inside: avoid;
    }}
    
    /* ヘッダー・フッターのマージン - プレビューと統一 */
    .newsletter-header {{
        margin-bottom: 10px !important;
        padding: 8px !important;
    }}
    
    .footer-note {{
        margin-top: 10px !important;
        padding: 6px !important;
    }}
    
    {custom_css}
    """
    
    # HTMLコンテンツからstyleタグを除去（重複を防ぐため）
    if "<style>" in clean_html_content and "</style>" in clean_html_content:
        start_idx = clean_html_content.find("<style>")
        end_idx = clean_html_content.find("</style>") + 8
        clean_html_content = clean_html_content[:start_idx] + clean_html_content[end_idx:]
    
    # HTMLタグやDOCTYPE宣言を除去（bodyコンテンツのみに）
    clean_html_content = _extract_body_content(clean_html_content)
    
    # 既存のヘッダーがある場合は追加ヘッダーを無効化
    has_existing_header = any(tag in html_content.lower() for tag in ['<h1', '<header', 'class="newsletter-header"', 'class="a4-sheet"'])
    
    # ヘッダー部分（既存ヘッダーがない場合のみ）
    header_content = ""
    if include_header and not has_existing_header:
        header_content = f"""
        <div class="pdf-header" style="text-align: center; margin-bottom: 20px; padding: 10px; border-bottom: 1px solid #ddd;">
            <h1 style="margin: 0; font-size: 18px; color: #333;">{title}</h1>
            <div style="font-size: 12px; color: #666; margin-top: 5px;">{datetime.now().strftime('%Y年%m月%d日')}</div>
        </div>
        """
    
    # フッター部分（控えめに）
    footer_content = ""
    if include_footer:
        footer_content = f"""
        <div class="pdf-footer" style="margin-top: 30px; padding: 10px; border-top: 1px solid #eee; font-size: 10px; text-align: center; color: #999;">
            <p style="margin: 0;">この学級通信はAIによって自動生成されました。</p>
        </div>
        """
    
    # 完全なHTML文書
    complete_html = f"""
    <!DOCTYPE html>
    <html lang="ja">
    <head>
        <meta charset="UTF-8">
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>{title}</title>
        <style>
            {pdf_css}
        </style>
    </head>
    <body>
        {header_content}
        
        <div class="content-main">
            {clean_html_content}
        </div>
        
        {footer_content}
    </body>
    </html>
    """
    
    return complete_html

def _extract_body_content(html_content: str) -> str:
    """
    HTMLからbodyコンテンツのみを抽出
    - 完全なHTMLドキュメントからbody内容のみを取得
    - HTMLタグやDOCTYPE宣言を除去
    """
    content = html_content.strip()
    
    # body要素の抽出を試行
    body_match = re.search(r'<body[^>]*>(.*?)</body>', content, re.DOTALL | re.IGNORECASE)
    if body_match:
        return body_match.group(1).strip()
    
    # body要素がない場合、HTML要素の抽出を試行
    html_match = re.search(r'<html[^>]*>(.*?)</html>', content, re.DOTALL | re.IGNORECASE)
    if html_match:
        html_content_inner = html_match.group(1).strip()
        # head要素を除去
        html_content_inner = re.sub(r'<head[^>]*>.*?</head>', '', html_content_inner, flags=re.DOTALL | re.IGNORECASE)
        return html_content_inner.strip()
    
    # DOCTYPEとhtmlタグを除去
    content = re.sub(r'<!DOCTYPE[^>]*>', '', content, flags=re.IGNORECASE)
    content = re.sub(r'</?html[^>]*>', '', content, flags=re.IGNORECASE)
    content = re.sub(r'<head[^>]*>.*?</head>', '', content, flags=re.DOTALL | re.IGNORECASE)
    content = re.sub(r'</?body[^>]*>', '', content, flags=re.IGNORECASE)
    
    return content.strip()

def _get_pdf_page_count(pdf_path: str) -> int:
    """
    PDFのページ数を取得
    
    Args:
        pdf_path (str): PDFファイルパス
        
    Returns:
        int: ページ数
    """
    try:
        # PyPDF2を使用してページ数を取得
        try:
            import PyPDF2
            with open(pdf_path, 'rb') as file:
                pdf_reader = PyPDF2.PdfReader(file)
                return len(pdf_reader.pages)
        except ImportError:
            # PyPDF2が利用できない場合は、ファイルサイズから推定
            file_size = os.path.getsize(pdf_path)
            # 概算: 1ページあたり約50KB（画像やフォントにより大きく変動）
            estimated_pages = max(1, file_size // 50000)
            return estimated_pages
            
    except Exception as e:
        logger.warning(f"Failed to get PDF page count: {e}")
        return 1  # デフォルトは1ページ

def create_pdf_preview_image(
    pdf_path: str,
    page_number: int = 1,
    output_path: Optional[str] = None,
    width: int = 800,
    dpi: int = 150
) -> Dict[str, Any]:
    """
    PDFの指定ページからプレビュー画像を生成
    
    Args:
        pdf_path (str): PDFファイルパス
        page_number (int): ページ番号 (1から開始)
        output_path (str): 画像出力パス
        width (int): 画像幅（ピクセル）
        dpi (int): 解像度
        
    Returns:
        Dict[str, Any]: プレビュー画像生成結果
    """
    start_time = time.time()
    
    try:
        if not PIL_AVAILABLE:
            return {
                'success': False,
                'error': 'PIL (Pillow) is not available for image generation',
                'error_code': 'PIL_NOT_AVAILABLE'
            }
        
        # pdf2imageライブラリを使用（追加インストール必要）
        try:
            from pdf2image import convert_from_path
            
            # PDFを画像に変換
            images = convert_from_path(
                pdf_path,
                first_page=page_number,
                last_page=page_number,
                dpi=dpi
            )
            
            if not images:
                raise Exception(f"No image generated for page {page_number}")
            
            image = images[0]
            
            # 幅に基づいてリサイズ
            aspect_ratio = image.height / image.width
            new_height = int(width * aspect_ratio)
            image = image.resize((width, new_height), Image.Resampling.LANCZOS)
            
            # 出力パス決定
            if output_path is None:
                temp_file = tempfile.NamedTemporaryFile(delete=False, suffix='.png')
                output_path = temp_file.name
                temp_file.close()
            
            # 画像保存
            image.save(output_path, 'PNG', optimize=True)
            
            # 画像をBase64エンコード
            with open(output_path, 'rb') as img_file:
                image_base64 = base64.b64encode(img_file.read()).decode('utf-8')
            
            file_size = os.path.getsize(output_path)
            
            return {
                'success': True,
                'data': {
                    'image_path': output_path,
                    'image_base64': image_base64,
                    'width': width,
                    'height': new_height,
                    'file_size_bytes': file_size,
                    'page_number': page_number,
                    'processing_time_ms': int((time.time() - start_time) * 1000)
                }
            }
            
        except ImportError:
            return {
                'success': False,
                'error': 'pdf2image library is not available. Install with: pip install pdf2image',
                'error_code': 'PDF2IMAGE_NOT_AVAILABLE'
            }
            
    except Exception as e:
        error_msg = f"PDF preview generation failed: {str(e)}"
        logger.error(error_msg)
        return {
            'success': False,
            'error': error_msg,
            'error_code': 'PREVIEW_GENERATION_ERROR',
            'processing_time_ms': int((time.time() - start_time) * 1000)
        }

def get_pdf_info(pdf_path: str) -> Dict[str, Any]:
    """
    PDFファイルの情報を取得
    
    Args:
        pdf_path (str): PDFファイルパス
        
    Returns:
        Dict[str, Any]: PDF情報
    """
    try:
        if not os.path.exists(pdf_path):
            return {
                'success': False,
                'error': 'PDF file not found',
                'error_code': 'FILE_NOT_FOUND'
            }
        
        file_size = os.path.getsize(pdf_path)
        page_count = _get_pdf_page_count(pdf_path)
        created_time = datetime.fromtimestamp(os.path.getctime(pdf_path))
        modified_time = datetime.fromtimestamp(os.path.getmtime(pdf_path))
        
        return {
            'success': True,
            'data': {
                'file_path': pdf_path,
                'file_size_bytes': file_size,
                'file_size_mb': round(file_size / (1024 * 1024), 3),
                'page_count': page_count,
                'created_at': created_time.isoformat(),
                'modified_at': modified_time.isoformat(),
                'file_name': os.path.basename(pdf_path)
            }
        }
        
    except Exception as e:
        return {
            'success': False,
            'error': f'Failed to get PDF info: {str(e)}',
            'error_code': 'PDF_INFO_ERROR'
        }

def cleanup_temp_files(file_paths: list) -> int:
    """
    一時ファイルをクリーンアップ
    
    Args:
        file_paths (list): 削除するファイルパスのリスト
        
    Returns:
        int: 削除されたファイル数
    """
    deleted_count = 0
    
    for file_path in file_paths:
        try:
            if os.path.exists(file_path):
                os.unlink(file_path)
                deleted_count += 1
                logger.info(f"Deleted temp file: {file_path}")
        except Exception as e:
            logger.warning(f"Failed to delete temp file {file_path}: {e}")
    
    return deleted_count

def test_pdf_generation() -> bool:
    """
    PDF生成機能のテスト
    
    Returns:
        bool: テスト成功可否
    """
    print("=== PDF生成機能テスト ===")
    
    # テスト用HTMLコンテンツ
    test_html = """
    <h1>今日の学級通信</h1>
    
    <h2>今日の出来事</h2>
    <p>今日は運動会の練習をしました。子どもたちは一生懸命頑張っていました。</p>
    
    <h3>各教科の様子</h3>
    <ul>
        <li><strong>国語</strong>: 詩の音読発表</li>
        <li><strong>算数</strong>: 九九の練習</li>
        <li><strong>体育</strong>: 運動会の練習</li>
    </ul>
    
    <h2>お知らせ</h2>
    <p>来週の運動会に向けて、<em>体操服</em>の準備をお願いします。</p>
    """
    
    try:
        # PDF生成テスト
        result = generate_pdf_from_html(
            html_content=test_html,
            title="テスト学級通信",
            include_header=False,
            include_footer=False
        )
        
        if result['success']:
            print("✅ PDF生成成功")
            print(f"ファイルサイズ: {result['data']['file_size_mb']} MB")
            print(f"ページ数: {result['data']['page_count']}")
            print(f"処理時間: {result['data']['processing_time_ms']}ms")
            
            # PDF情報取得テスト
            info_result = get_pdf_info(result['data']['pdf_path'])
            if info_result['success']:
                print("✅ PDF情報取得成功")
            
            # 一時ファイル削除
            cleanup_temp_files([result['data']['pdf_path']])
            
            return True
        else:
            print("❌ PDF生成失敗")
            print(f"エラー: {result['error']}")
            return False
            
    except Exception as e:
        print(f"❌ テストエラー: {e}")
        return False

def _clean_html_for_pdf(html_content: str) -> str:
    """
    PDF生成前にHTMLからMarkdownコードブロックを完全に除去 - 強化版
    
    Args:
        html_content (str): クリーンアップするHTMLコンテンツ
        
    Returns:
        str: Markdownコードブロックが除去されたHTMLコンテンツ
    """
    if not html_content:
        return html_content
    
    content = html_content.strip()
    
    # Markdownコードブロックの様々なパターンを削除 - PDF用強化版
    patterns = [
        r'```html\s*',          # ```html
        r'```HTML\s*',          # ```HTML  
        r'```\s*html\s*',       # ``` html
        r'```\s*HTML\s*',       # ``` HTML
        r'```\s*',              # 一般的なコードブロック開始
        r'\s*```',              # コードブロック終了
        r'`html\s*',            # `html（単一バッククォート）
        r'`HTML\s*',            # `HTML（単一バッククォート）
        r'\s*`\s*$',            # 末尾の単一バッククォート
        r'^\s*`',               # 先頭の単一バッククォート
    ]
    
    for pattern in patterns:
        content = re.sub(pattern, '', content, flags=re.IGNORECASE | re.MULTILINE)
    
    # HTMLの前後にある説明文を削除（PDF用強化）
    explanation_patterns = [
        r'^[^<]*(?=<)',                           # HTML開始前の説明文
        r'>[^<]*$',                               # HTML終了後の説明文  
        r'以下のHTML.*?です[。：]?\s*',              # 「以下のHTML〜です」パターン
        r'HTML.*?を出力.*?[。：]?\s*',             # 「HTMLを出力〜」パターン
        r'こちらが.*?HTML.*?[。：]?\s*',           # 「こちらがHTML〜」パターン
        r'生成された.*?HTML.*?[。：]?\s*',         # 「生成されたHTML〜」パターン
        r'【[^】]*】',                               # 【〜】形式のラベル
    ]
    
    for pattern in explanation_patterns:
        content = re.sub(pattern, '', content, flags=re.IGNORECASE)
    
    # 空白の正規化
    content = re.sub(r'\n\s*\n', '\n', content)
    content = content.strip()
    
    # デバッグログ：PDF生成前のクリーンアップチェック（強化）
    if '```' in content or '`' in content:
        logger.warning(f"PDF generation: Markdown/backtick remnants detected after enhanced cleanup: {content[:100]}...")
    
    logger.debug(f"PDF HTML content after enhanced markdown cleanup: {content[:200]}...")
    
    return content

if __name__ == '__main__':
    success = test_pdf_generation()
    if success:
        print('\n🎉 PDF生成機能 - テスト完了!')
    else:
        print('\n⚠️ 設定に問題があります。エラーを確認してください。') 