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
DEFAULT_MARGIN = '20mm'
DEFAULT_DPI = 300

def generate_pdf_from_html(
    html_content: str,
    title: str = "学級通信",
    page_size: str = DEFAULT_PAGE_SIZE,
    margin: str = DEFAULT_MARGIN,
    include_header: bool = True,
    include_footer: bool = True,
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
        
        # HTML文書を構築
        full_html = _build_complete_html_document(
            html_content=html_content,
            title=title,
            page_size=page_size,
            margin=margin,
            include_header=include_header,
            include_footer=include_footer,
            custom_css=custom_css
        )
        
        # 出力パス決定
        if output_path is None:
            temp_file = tempfile.NamedTemporaryFile(delete=False, suffix='.pdf')
            output_path = temp_file.name
            temp_file.close()
        
        # PDF生成実行
        logger.info(f"Generating PDF: {output_path}")
        
        html_doc = HTML(string=full_html)
        html_doc.write_pdf(output_path)
        
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
        logger.error(error_msg)
        return {
            'success': False,
            'error': error_msg,
            'error_code': 'PDF_GENERATION_ERROR',
            'processing_time_ms': int((time.time() - start_time) * 1000)
        }

def _build_complete_html_document(
    html_content: str,
    title: str,
    page_size: str,
    margin: str,
    include_header: bool,
    include_footer: bool,
    custom_css: str
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
    
    # PDF用CSS
    pdf_css = f"""
    @page {{
        size: {page_size};
        margin: {margin};
        @top-center {{
            content: "{title}" counter(page);
        }}
        @bottom-center {{
            content: "生成日: {datetime.now().strftime('%Y年%m月%d日')} - ページ " counter(page);
        }}
    }}
    
    body {{
        font-family: "Hiragino Sans", "Meiryo", "Yu Gothic", "MS PGothic", sans-serif;
        line-height: 1.6;
        color: #333;
        font-size: 14px;
        margin: 0;
        padding: 0;
    }}
    
    h1 {{
        font-size: 24px;
        color: #2c3e50;
        border-bottom: 3px solid #3498db;
        padding-bottom: 10px;
        margin-bottom: 20px;
        page-break-after: avoid;
    }}
    
    h2 {{
        font-size: 20px;
        color: #34495e;
        border-left: 5px solid #e74c3c;
        padding-left: 10px;
        margin-top: 25px;
        margin-bottom: 15px;
        page-break-after: avoid;
    }}
    
    h3 {{
        font-size: 18px;
        color: #555;
        margin-top: 20px;
        margin-bottom: 10px;
        page-break-after: avoid;
    }}
    
    p {{
        margin-bottom: 12px;
        text-align: justify;
    }}
    
    ul, ol {{
        margin-bottom: 15px;
        padding-left: 25px;
    }}
    
    li {{
        margin-bottom: 5px;
    }}
    
    strong {{
        color: #2c3e50;
        font-weight: bold;
    }}
    
    em {{
        color: #e74c3c;
        font-style: italic;
    }}
    
    .newsletter-header {{
        text-align: center;
        margin-bottom: 30px;
        padding: 20px;
        background: linear-gradient(135deg, #74b9ff 0%, #0984e3 100%);
        color: white;
        border-radius: 10px;
    }}
    
    .newsletter-date {{
        text-align: right;
        margin-bottom: 20px;
        font-size: 12px;
        color: #7f8c8d;
    }}
    
    .content-section {{
        margin-bottom: 25px;
        padding: 15px;
        border-left: 4px solid #3498db;
        background-color: #f8f9fa;
    }}
    
    .footer-note {{
        margin-top: 30px;
        padding: 15px;
        background-color: #ecf0f1;
        border-radius: 5px;
        font-size: 12px;
        text-align: center;
        color: #7f8c8d;
        page-break-inside: avoid;
    }}
    
    /* 印刷時の改ページ制御 */
    .page-break {{
        page-break-before: always;
    }}
    
    .no-break {{
        page-break-inside: avoid;
    }}
    
    /* 季節テーマ */
    .spring-theme {{
        --primary-color: #ff9eaa;
        --secondary-color: #a8e6cf;
    }}
    
    .summer-theme {{
        --primary-color: #51cf66;
        --secondary-color: #74c0fc;
    }}
    
    .autumn-theme {{
        --primary-color: #e67700;
        --secondary-color: #ffa94d;
    }}
    
    .winter-theme {{
        --primary-color: #4dabf7;
        --secondary-color: #91a7ff;
    }}
    
    {custom_css}
    """
    
    # ヘッダー部分
    header_content = ""
    if include_header:
        header_content = f"""
        <div class="newsletter-header">
            <h1>{title}</h1>
            <div class="newsletter-date">{datetime.now().strftime('%Y年%m月%d日')}</div>
        </div>
        """
    
    # フッター部分
    footer_content = ""
    if include_footer:
        footer_content = f"""
        <div class="footer-note">
            <p>この学級通信はAIによって自動生成されました。</p>
            <p>ご質問やご不明な点がございましたら、担任までお気軽にお声かけください。</p>
        </div>
        """
    
    # 完全なHTML文書
    complete_html = f"""
    <!DOCTYPE html>
    <html lang="ja">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>{title}</title>
        <style>
            {pdf_css}
        </style>
    </head>
    <body>
        {header_content}
        
        <div class="content-main">
            {html_content}
        </div>
        
        {footer_content}
    </body>
    </html>
    """
    
    return complete_html

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
            include_header=True,
            include_footer=True
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

if __name__ == '__main__':
    success = test_pdf_generation()
    if success:
        print('\n🎉 PDF生成機能 - テスト完了!')
    else:
        print('\n⚠️ 設定に問題があります。エラーを確認してください。') 