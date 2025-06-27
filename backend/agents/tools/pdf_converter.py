import asyncio
from typing import Optional

import pdfkit


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
    HTML文字列をPDFに非同期で変換します。
    成功した場合はPDFのbytesを、失敗した場合はNoneを返します。
    """
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
        'title': title
    }
    
    # ヘッダー・フッターオプション
    if include_header:
        options['header-right'] = title
        options['header-font-size'] = '8'
    
    if include_footer:
        options['footer-center'] = 'ページ [page] / [topage]'
        options['footer-font-size'] = '8'
    try:
        # pdfkitは非同期に対応していないため、run_in_executorでブロッキングを防ぐ
        loop = asyncio.get_running_loop()
        pdf_bytes = await loop.run_in_executor(
            None,
            lambda: pdfkit.from_string(html_content, False, options=options)
        )
        return pdf_bytes
    except Exception as e:
        # エラーをログに出力
        print(f"PDF変換中にエラーが発生しました: {e}")
        return None
