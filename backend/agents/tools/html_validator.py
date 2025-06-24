import html5lib
from google.adk.tools import BaseTool
from pydantic import BaseModel, Field

class HtmlValidatorTool(BaseTool):
    """
    html5libを使用してHTML文字列の構造を厳密に検証するツール。
    """

    class HtmlValidatorToolSchema(BaseModel):
        html: str = Field(..., description="検証対象のHTMLコンテンツ文字列。")

    def __init__(self):
        super().__init__(
            name="html_validator",
            description="HTML文字列の構造が正しいかを厳密に検証します。",
            schema=self.HtmlValidatorToolSchema,
        )

    def _run(self, html: str) -> dict:
        """
        html5libパーサーを実行してHTMLを検証します。
        
        Args:
            html: 検証するHTML文字列。
        
        Returns:
            検証結果を含む辞書。エラーがなければ空のリストを返します。
        """
        parser = html5lib.HTMLParser(strict=True)
        errors = []
        try:
            parser.parse(html)
            if parser.errors:
                for pos, errorcode, datavars in parser.errors:
                    errors.append(f"Line {pos[0]}, Col {pos[1]}: {errorcode} {datavars}")
            
            if not errors:
                return {"status": "valid", "message": "HTML is well-formed."}
            else:
                return {"status": "invalid", "errors": errors}

        except Exception as e:
            # 予期せぬパースエラー
            return {"status": "error", "message": f"An unexpected error occurred during parsing: {str(e)}"}
