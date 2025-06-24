import asyncio
from typing import Optional

import pdfkit


async def convert_html_to_pdf(html_content: str) -> Optional[bytes]:
    """
    HTML文字列をPDFに非同期で変換します。
    成功した場合はPDFのbytesを、失敗した場合はNoneを返します。
    """
    options = {
        'page-size': 'A4',
        'margin-top': '0.75in',
        'margin-right': '0.75in',
        'margin-bottom': '0.75in',
        'margin-left': '0.75in',
        'encoding': "UTF-8",
        'no-outline': None,
        'enable-local-file-access': None
    }
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
