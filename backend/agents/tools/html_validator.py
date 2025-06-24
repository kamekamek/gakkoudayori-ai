import html5lib

async def validate_html(html: str) -> dict:
    """
    html5libを使用してHTML文字列の構造を厳密に検証します。
    
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
