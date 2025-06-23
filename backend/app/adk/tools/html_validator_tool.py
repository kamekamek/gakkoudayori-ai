from google.adk.tools import BaseTool
import html5lib
import io
from pydantic import Field
from pydantic import BaseModel

class HtmlValidatorTool(BaseTool):
    """HTMLの構文が正しいか、必須要素が含まれているかを検証するツール。"""

    class HtmlValidatorToolSchema(BaseModel):
        html_body: str = Field(..., description="検証するHTMLのbody部分の文字列。")

    def __init__(self):
        super().__init__(
            name="html_validator",
            description="HTMLの構文が正しいか、必須要素（例：h1, pなど）が含まれているかを検証します。",
        )

    def _run(self, html_body: str) -> str:
        """
        指定されたHTML文字列の妥当性を検証します。

        Args:
            html_body: The HTML content to validate.

        Returns:
            A string indicating the result of the validation.
        """
        if not isinstance(html_body, str):
            return "Invalid input: HTML must be a string."

        parser = html5lib.HTMLParser(strict=True)
        try:
            parser.parse(io.StringIO(html_body))
            # strict=Trueでも例外を発生させないエラーがparser.errorsに格納されることがある
            errors = [
                html5lib.constants.E.get(error_code, "Unknown error") % error_params
                for error_code, error_params in parser.errors
            ]
            if errors:
                return f"Invalid HTML. Errors: {', '.join(errors)}"
            return "Valid HTML."
        except Exception as e:
            #致命的なパースエラーを捕捉
            return f"Fatal parse error: {str(e)}" 