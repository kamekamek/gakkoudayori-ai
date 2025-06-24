import pdfkit
from google.adk.tools import BaseTool
from pydantic import BaseModel, Field

class PdfConverterTool(BaseTool):
    """
    pdfkitを使用してHTML文字列をPDFファイルに変換するツール。
    """
    class PdfConverterToolSchema(BaseModel):
        html_content: str = Field(..., description="PDFに変換するHTMLコンテンツ。")
        options: dict | None = Field(default=None, description="pdfkitに渡すオプションの辞書。")

    def __init__(self):
        super().__init__(
            name="pdf_converter",
            description="HTML文字列をPDFファイルに変換します。",
            schema=self.PdfConverterToolSchema,
        )

    def _run(self, html_content: str, options: dict | None = None) -> bytes:
        """
        pdfkitを使用してHTMLをPDFに変換します。

        Args:
            html_content: 変換するHTML文字列。
            options: pdfkitに渡すオプション。

        Returns:
            生成されたPDFのバイトデータ。
        """
        # デフォルトの印刷オプション
        default_options = {
            'page-size': 'A4',
            'margin-top': '15mm',
            'margin-right': '15mm',
            'margin-bottom': '15mm',
            'margin-left': '15mm',
            'encoding': "UTF-8",
            'print-media-type': None, # @media print のCSSを適用
            'enable-local-file-access': None # ローカルファイルアクセスを許可（画像等）
        }

        if options:
            default_options.update(options)

        try:
            # `from_string`の第2引数はファイルパス(出力先)。Falseで変数に格納
            pdf_bytes = pdfkit.from_string(html_content, False, options=default_options)
            return pdf_bytes
        except OSError as e:
            # wkhtmltopdfがインストールされていない場合などにOSErrorが発生する
            error_message = f"PDF変換中にエラーが発生しました: {e}。wkhtmltopdfがインストールされ、PATHが通っているか確認してください。"
            print(error_message)
            # エラー情報をバイトデータとして返すこともできる
            return error_message.encode('utf-8')
