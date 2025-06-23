from adk.tools import BaseTool
import html5lib
import io

class HtmlValidatorTool(BaseTool):
    """
    Validates the syntax of an HTML string.
    """
    name = "html_validator"
    description = "Validates an HTML string using html5lib. Returns whether the HTML is valid and a list of errors if any."

    async def __call__(self, html: str) -> dict:
        """
        Parses the HTML string and checks for errors.

        Args:
            html: The HTML content to validate.

        Returns:
            A dictionary with 'valid' (boolean) and 'errors' (list of strings).
        """
        if not isinstance(html, str):
            return {"valid": False, "errors": ["Invalid input: HTML must be a string."]}

        parser = html5lib.HTMLParser(strict=True)
        try:
            parser.parse(io.StringIO(html))
            # strict=Trueでも例外を発生させないエラーがparser.errorsに格納されることがある
            errors = [
                html5lib.constants.E.get(error_code, "Unknown error") % error_params
                for error_code, error_params in parser.errors
            ]
            if errors:
                return {"valid": False, "errors": errors}
            return {"valid": True, "errors": []}
        except Exception as e:
            #致命的なパースエラーを捕捉
            return {"valid": False, "errors": [str(e)]} 