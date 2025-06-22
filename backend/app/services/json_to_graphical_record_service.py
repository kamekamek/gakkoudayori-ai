"""
JSON→HTMLグラレコ生成サービス

構造化JSONデータからHTMLグラフィックレコーディング（グラレコ）を生成
視覚的で分かりやすいレイアウトとデザインを提供
"""

import os
import logging
import time
import json
from typing import Dict, Any, List, Optional
from datetime import datetime
import re

# Gemini API関連
from .gemini_api_service import generate_text

# ロギング設定
logger = logging.getLogger(__name__)

# プロンプトディレクトリを定数として定義
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
PROMPT_DIR = os.path.join(BASE_DIR, "prompts")


# ==============================================================================
# プロンプト読み込みヘルパー
# ==============================================================================
def load_prompt(template_name: str) -> Optional[str]:
    """
    指定されたテンプレート名のプロンプトファイルを読み込む
    
    Args:
        template_name (str): テンプレート名 (例: "classic", "modern_newsletter")
        
    Returns:
        Optional[str]: 読み込んだプロンプトの文字列、見つからない場合はNone
    """
    # テンプレート名からプロンプトファイル名を決定
    if template_name in ['modern', 'modern_newsletter']:
        prompt_filename = "MODERN_LAYOUT.md"
    else:
        # classic系やその他はCLASSIC_LAYOUT.mdを使用
        prompt_filename = "CLASSIC_LAYOUT.md"

    try:
        prompt_path = os.path.join(PROMPT_DIR, prompt_filename)
        
        if not os.path.exists(prompt_path):
            logger.error(f"Prompt file not found: {prompt_path}")
            # モダンプロンプトが見つからない場合はクラシックにフォールバック
            if template_name in ['modern', 'modern_newsletter']:
                logger.warning(f"Modern layout prompt not found, falling back to classic")
                return load_prompt('classic')
            return None
            
        with open(prompt_path, "r", encoding="utf-8") as f:
            return f.read()
    except Exception as e:
        logger.error(f"Error loading prompt file {prompt_filename}: {e}")
        return None


# ==============================================================================
# グラレコテンプレート定義
# ==============================================================================

def get_graphical_record_templates() -> Dict[str, Dict[str, Any]]:
    """
    グラレコテンプレート一覧を取得
    
    Returns:
        Dict[str, Dict[str, Any]]: テンプレート定義
    """
    return {
        "classic": {
            "name": "クラシック",
            "description": "伝統的な学級通信スタイル",
            "colors": {
                "primary": "#2c3e50",
                "secondary": "#3498db",
                "accent": "#e74c3c",
                "background": "#ffffff",
                "positive": "#27AE60",
                "neutral": "#95A5A6",
                "focused": "#3498DB",
                "excited": "#E74C3C",
                "calm": "#16A085",
                "concerned": "#E67E22"
            },
            "style": "classic"
        },
        "classic_newsletter": {
            "name": "クラシック学級通信",
            "description": "学級通信専用の伝統的なスタイル",
            "colors": {
                "primary": "#2c3e50",
                "secondary": "#3498db",
                "accent": "#e74c3c",
                "background": "#ffffff",
                "positive": "#27AE60",
                "neutral": "#95A5A6",
                "focused": "#3498DB",
                "excited": "#E74C3C",
                "calm": "#16A085",
                "concerned": "#E67E22"
            },
            "style": "classic"
        },
        "modern": {
            "name": "モダン",
            "description": "現代的でインフォグラフィック的な学級通信スタイル",
            "colors": {
                "primary": "#2E86AB",
                "secondary": "#A23B72",
                "accent": "#F18F01",
                "background": "#FFFFFF",
                "positive": "#06D6A0",
                "neutral": "#8D99AE",
                "focused": "#2E86AB",
                "excited": "#F18F01",
                "calm": "#06D6A0",
                "concerned": "#EF476F"
            },
            "style": "modern"
        },
        "modern_newsletter": {
            "name": "モダン学級通信",
            "description": "学級通信専用の現代的でインフォグラフィック的なスタイル",
            "colors": {
                "primary": "#2E86AB",
                "secondary": "#A23B72",
                "accent": "#F18F01",
                "background": "#FFFFFF",
                "positive": "#06D6A0",
                "neutral": "#8D99AE",
                "focused": "#2E86AB",
                "excited": "#F18F01",
                "calm": "#06D6A0",
                "concerned": "#EF476F"
            },
            "style": "modern"
        },
        "colorful": {
            "name": "カラフル",
            "description": "明るい色彩で楽しい雰囲気",
            "colors": {
                "primary": "#FF6B6B",
                "secondary": "#4ECDC4", 
                "accent": "#45B7D1",
                "positive": "#96CEB4",
                "neutral": "#FFEAA7",
                "focused": "#DDA0DD",
                "excited": "#FFB347",
                "calm": "#87CEEB",
                "concerned": "#F0A0A0"
            },
            "style": "modern"
        },
        "monochrome": {
            "name": "モノクロ",
            "description": "シンプルで落ち着いた印刷",
            "colors": {
                "primary": "#2C3E50",
                "secondary": "#34495E",
                "accent": "#7F8C8D",
                "positive": "#27AE60",
                "neutral": "#95A5A6",
                "focused": "#3498DB",
                "excited": "#E74C3C",
                "calm": "#16A085",
                "concerned": "#E67E22"
            },
            "style": "classic"
        },
        "pastel": {
            "name": "パステル",
            "description": "優しい色合いで温かい印象",
            "colors": {
                "primary": "#FFB6C1",
                "secondary": "#E6E6FA",
                "accent": "#B0E0E6",
                "positive": "#98FB98",
                "neutral": "#F0E68C",
                "focused": "#DDA0DD",
                "excited": "#FFA07A",
                "calm": "#AFEEEE",
                "concerned": "#F5DEB3"
            },
            "style": "soft"
        }
    }


def get_emotion_icons() -> Dict[str, str]:
    """
    感情に対応するアイコン（絵文字）を取得
    
    Returns:
        Dict[str, str]: 感情→アイコンのマッピング
    """
    return {
        "positive": "😊",
        "neutral": "😐",
        "focused": "🤔",
        "excited": "🎉",
        "calm": "😌",
        "concerned": "😟"
    }


def get_section_type_icons() -> Dict[str, str]:
    """
    セクションタイプに対応するアイコンを取得
    
    Returns:
        Dict[str, str]: セクションタイプ→アイコンのマッピング
    """
    return {
        "activity": "🏃",
        "learning": "📚",
        "event": "🎪",
        "discussion": "💬",
        "announcement": "📢"
    }


# ==============================================================================
# JSON→HTMLグラレコ変換機能
# ==============================================================================

def convert_json_to_graphical_record(
    json_data: Dict[str, Any],
    project_id: str,
    credentials_path: str,
    template: str = "classic",
    custom_style: str = "",
    model_name: str = "gemini-2.5-flash-preview-05-20",
    temperature: float = 0.2,
    max_output_tokens: int = 8192
) -> Dict[str, Any]:
    """
    JSON構造化データからHTMLグラレコを生成
    
    Args:
        json_data (Dict[str, Any]): 構造化JSONデータ
        project_id (str): Google CloudプロジェクトID
        credentials_path (str): サービスアカウントキーファイルのパス
        template (str): 使用するテンプレート（colorful, monochrome, pastel）
        custom_style (str): カスタムスタイル指定
        model_name (str): 使用するGeminiモデル
        temperature (float): 生成の多様性
        max_output_tokens (int): 最大出力トークン数
        
    Returns:
        Dict[str, Any]: 生成結果（成功時はHTMLデータ、失敗時はエラー情報）
    """
    start_time = time.time()
    timestamp = datetime.now().isoformat()
    
    try:
        # テンプレート情報を取得
        templates = get_graphical_record_templates()
        if template not in templates:
            logger.warning(f"Template '{template}' not found in definitions. Falling back to 'classic'.")
            template = "classic" 
        
        template_info = templates[template]
        emotion_icons = get_emotion_icons()
        section_icons = get_section_type_icons()
        
        # プロンプトをファイルから読み込み
        system_prompt_template = load_prompt(template)
        if not system_prompt_template:
            return {
                "success": False,
                "error": {
                    "code": "PROMPT_LOADING_FAILED",
                    "message": f"Template '{template}'のレイアウトプロンプトファイルの読み込みに失敗しました。",
                    "processing_time_ms": int((time.time() - start_time) * 1000),
                    "timestamp": timestamp
                }
            }
        
        # 必須HTML構造に関する注意：プロンプトファイルに完全なHTML構造が含まれていることを前提とする
        # そのため、ここでのハードコードされたHTMLスニペットは不要

        # プロンプトに変数を埋め込む（format()の代わりにreplace()を使用してCSS変数との衝突を回避）
        system_prompt = system_prompt_template
        system_prompt = system_prompt.replace('{{template_name}}', template_info.get('name', 'N/A'))
        system_prompt = system_prompt.replace('{{template_style}}', template_info.get('style', 'N/A'))
        system_prompt = system_prompt.replace('{{template_description}}', template_info.get('description', 'N/A'))
        system_prompt = system_prompt.replace('{{colors}}', json.dumps(template_info.get('colors', {}), indent=2, ensure_ascii=False))
        system_prompt = system_prompt.replace('{{emotion_icons}}', json.dumps(emotion_icons, indent=2, ensure_ascii=False))
        system_prompt = system_prompt.replace('{{section_icons}}', json.dumps(section_icons, indent=2, ensure_ascii=False))
        system_prompt = system_prompt.replace('{{title}}', json_data.get("title", "無題の学級通信"))

        user_prompt = f"""
以下のJSONデータをHTMLに変換してください。

入力JSON:
```json
{json.dumps(json_data, indent=2, ensure_ascii=False)}
```

追加のスタイル指示:
{custom_style if custom_style else "特になし"}

HTML出力（完全なHTMLドキュメント）:
"""

        full_prompt = f"{system_prompt}\n\n{user_prompt}"

        logger.info(f"Converting JSON to graphical record. Template: {template}")
        
        # Gemini APIで変換実行
        api_response = generate_text(
            prompt=full_prompt,
            project_id=project_id,
            credentials_path=credentials_path,
            model_name=model_name,
            temperature=temperature,
            max_output_tokens=max_output_tokens
        )
        
        if not api_response.get("success"):
            logger.error(f"Gemini API call failed: {api_response.get('error')}")
            return {
                "success": False,
                "error": {
                    "code": "GEMINI_API_ERROR",
                    "message": "JSON→HTMLグラレコ生成でGemini APIエラーが発生しました",
                    "details": api_response.get("error", {}),
                    "processing_time_ms": int((time.time() - start_time) * 1000),
                    "timestamp": timestamp
                }
            }
        
        # 生成されたHTMLを取得
        generated_html = api_response.get("data", {}).get("text", "")
        ai_metadata = api_response.get("data", {}).get("ai_metadata", {})
        
        # HTML検証・クリーンアップ
        html_result = validate_and_clean_html(generated_html)
        
        if not html_result["valid"]:
            logger.error(f"Invalid HTML generated: {html_result['error']}")
            return {
                "success": False,
                "error": {
                    "code": "INVALID_HTML",
                    "message": "生成されたHTMLが無効です",
                    "details": {
                        "validation_error": html_result["error"],
                        "generated_html": generated_html[:500] + "..." if len(generated_html) > 500 else generated_html,
                        "processing_time_ms": int((time.time() - start_time) * 1000),
                        "timestamp": timestamp
                    }
                }
            }
        
        # 成功レスポンス
        processing_time = time.time() - start_time
        
        return {
            "success": True,
            "data": {
                "html_content": html_result["html"],
                "source_json": json_data,
                "template_info": template_info,
                "ai_metadata": ai_metadata,
                "generation_info": {
                    "template_used": template,
                    "sections_count": len(json_data.get("sections", [])),
                    "highlights_count": len(json_data.get("highlights", [])),
                    "overall_mood": json_data.get("overall_mood", "neutral"),
                    "html_size_bytes": len(html_result["html"])
                },
                "processing_time_ms": int(processing_time * 1000),
                "timestamp": timestamp
            }
        }
        
    except Exception as e:
        logger.error(f"JSON to graphical record conversion failed: {e}")
        return {
            "success": False,
            "error": {
                "code": "CONVERSION_ERROR",
                "message": f"JSON→HTMLグラレコ変換中にエラーが発生しました: {str(e)}",
                "details": {
                    "error_type": type(e).__name__,
                    "processing_time_ms": int((time.time() - start_time) * 1000),
                    "timestamp": timestamp
                }
            }
        }


# ==============================================================================
# HTML検証・クリーンアップ機能
# ==============================================================================

def validate_and_clean_html(html_content: str) -> Dict[str, Any]:
    """
    生成されたHTMLを検証し、クリーンアップする

    Args:
        html_content (str): 生成されたHTML文字列

    Returns:
        Dict[str, Any]: "valid": bool, "html": str, "error": Optional[str]
    """
    if not isinstance(html_content, str) or not html_content.strip():
        return {"valid": False, "html": "", "error": "HTMLコンテンツが空または無効です"}

    # 【重要】Markdownコードブロックのクリーンアップを追加
    cleaned_html = _clean_markdown_codeblocks_service(html_content.strip())

    # 必須タグの存在チェック
    required_tags = {
        "<!DOCTYPE html>": "文書型宣言",
        "<html": "htmlタグ",
        "<head": "headタグ",
        "<body": "bodyタグ",
        "</body": "body終了タグ",
        "</html": "html終了タグ",
    }
    
    missing_tags = []
    # 大文字小文字を区別しないチェック
    html_lower = cleaned_html.lower()
    for tag, name in required_tags.items():
        if tag.lower() not in html_lower:
            missing_tags.append(name)

    if missing_tags:
        error_message = f"必須HTMLタグが不足しています: {', '.join(missing_tags)}"
        logger.warning(f"{error_message}。修復を試みます。")
        repaired_html = _perform_final_html_repair(cleaned_html)
        
        # 修復後、再度バリデーション
        if not _validate_html_structure(repaired_html):
            final_error_message = f"HTMLの自動修復に失敗しました。不足タグ: {', '.join(missing_tags)}"
            logger.error(final_error_message)
            return {"valid": False, "html": cleaned_html, "error": final_error_message}
        
        logger.info("HTMLの自動修復に成功しました。")
        cleaned_html = repaired_html

    # ここでさらに最終的な構造保証を行う
    if not cleaned_html.lower().startswith('<!doctype html>'):
         cleaned_html = '<!DOCTYPE html>\n' + cleaned_html

    if '<html' not in cleaned_html.lower():
        cleaned_html = f'<html lang="ja"><head><meta charset="UTF-8"></head><body>{cleaned_html}</body></html>'
    elif '<body' not in cleaned_html.lower():
        # htmlタグはあるがbodyがない場合
        # <html>...</html> の中に <body>...</body> を挿入する
        html_parts = re.split(r'(<html[^>]*>)', cleaned_html, flags=re.IGNORECASE)
        if len(html_parts) >= 3:
             # 暫定的にheadを閉じてからbodyを開始する
            cleaned_html = html_parts[1] + '<head></head><body>' + html_parts[2]
            if not cleaned_html.lower().endswith('</body></html>'):
                 cleaned_html += '</body></html>'

    # HTMLの断片化（途中で切れている）チェック
    if not cleaned_html.lower().endswith("</html>"):
        logger.warning("HTMLが'</html>'で終了していません。修復を試みます。")
        cleaned_html = _perform_final_html_repair(cleaned_html)

    # 最終チェック
    if not _validate_html_structure(cleaned_html):
        return {"valid": False, "html": html_content, "error": "最終検証でHTML構造が無効と判断されました"}

    return {"valid": True, "html": cleaned_html, "error": None}


# ==============================================================================
# HTML構造検証ヘルパー
# ==============================================================================

def _validate_html_structure(html_text: str) -> bool:
    """
    HTMLの基本構造が有効かチェックする
    - DOCTYPE, html, head, bodyタグの存在を確認
    """
    if not html_text or not isinstance(html_text, str):
        return False
        
    txt_lower = html_text.lower()
    
    # 必須タグがすべて存在するか
    tags_to_check = ['<!doctype html>', '<html', '<head', '<body', '</body>', '</html>']
    for tag in tags_to_check:
        if tag not in txt_lower:
            logger.warning(f"HTML構造検証エラー: タグ '{tag}' が見つかりません。")
            return False
            
    return True


def _perform_final_html_repair(html_text: str) -> str:
    """
    不完全なHTMLを修復する最終防衛ライン
    - 足りない主要タグを補完する
    - 既に完全なHTMLドキュメントの場合は重複タグを避ける
    """
    repaired_html = html_text.strip()
    
    # 既に完全なHTMLドキュメントかチェック
    html_lower = repaired_html.lower()
    
    # 既に完全なHTML構造が存在する場合は、余計な処理を避ける
    is_complete_html = (
        '<!doctype html>' in html_lower and
        '<html' in html_lower and
        '</html>' in html_lower and
        '<head' in html_lower and
        '<body' in html_lower and
        '</body>' in html_lower
    )
    
    if is_complete_html:
        logger.info("既に完全なHTML文書のため、リペア処理をスキップします")
        return repaired_html

    # 以下、不完全なHTMLの場合のみ実行

    # DOCTYPE宣言
    if not repaired_html.lower().startswith('<!doctype html>'):
        repaired_html = '<!DOCTYPE html>\n' + repaired_html

    # <html> タグ
    if '<html' not in repaired_html.lower():
        repaired_html = f'<html lang="ja">\n{repaired_html}'
    if '</html>' not in repaired_html.lower():
        repaired_html += '\n</html>'
    
    # <head> タグ
    if '<head' not in repaired_html.lower():
        # <html> の直後に挿入
        repaired_html = re.sub(r'(<html[^>]*>)', r'\1\n<head>\n<meta charset="UTF-8">\n</head>\n', repaired_html, count=1, flags=re.IGNORECASE)
    elif '</head>' not in repaired_html.lower():
        # <head>はあるが閉じタグがない場合
         if '<body' in repaired_html.lower():
             # bodyの前に挿入
             repaired_html = re.sub(r'(<body[^>]*>)', r'</head>\n\1', repaired_html, count=1, flags=re.IGNORECASE)
         else:
             # headのコンテンツの後に挿入
             repaired_html = re.sub(r'(<head[^>]*>.*?)', r'\1</head>', repaired_html, count=1, flags=re.IGNORECASE | re.DOTALL)


    # <body> タグ
    if '<body' not in repaired_html.lower():
         # </head> の直後か、<html> の直後に挿入
        if '</head>' in repaired_html.lower():
             repaired_html = re.sub(r'(</head>)', r'\1\n<body>\n', repaired_html, count=1, flags=re.IGNORECASE)
        else:
             repaired_html = re.sub(r'(<html[^>]*>)', r'\1\n<head></head>\n<body>\n', repaired_html, count=1, flags=re.IGNORECASE)
             
    if '</body>' not in repaired_html.lower():
        # </html> の直前に挿入
        repaired_html = re.sub(r'(</html>)', r'\n</body>\n\1', repaired_html, count=1, flags=re.IGNORECASE)
        
    return repaired_html


# ==============================================================================
# テスト機能
# ==============================================================================

def test_json_to_graphical_record_conversion():
    """
    JSON→HTMLグラレコ変換のテスト
    """
    sample_json = {
        "title": "今日の学級の様子",
        "date": "2025-06-13",
        "sections": [
            {
                "type": "activity",
                "title": "朝の会",
                "content": "みんな元気に挨拶ができました。今日の係活動の確認も行いました。",
                "emotion": "positive",
                "participants": ["全員"],
                "time": "8:30-8:45"
            },
            {
                "type": "learning",
                "title": "算数の授業",
                "content": "九九の練習をしました。7の段が難しそうでしたが、みんな頑張って覚えようとしていました。",
                "emotion": "focused",
                "participants": ["3年生"],
                "time": "9:00-9:45"
            }
        ],
        "highlights": [
            "元気な挨拶ができた",
            "九九の練習に集中して取り組んだ"
        ],
        "next_actions": [
            "明日は運動会の練習",
            "7の段の復習"
        ],
        "overall_mood": "positive"
    }
    
    # テスト用の設定
    project_id = "gakkoudayori-ai"
    credentials_path = "../secrets/service-account-key.json"
    
    print("=== JSON→HTMLグラレコ変換テスト ===")
    print(f"入力JSON: {json.dumps(sample_json, indent=2, ensure_ascii=False)}")
    
    for template in ["colorful", "monochrome", "pastel"]:
        print(f"\n--- テンプレート: {template} ---")
        
        result = convert_json_to_graphical_record(
            json_data=sample_json,
            project_id=project_id,
            credentials_path=credentials_path,
            template=template
        )
        
        if result["success"]:
            print("✅ 変換成功")
            print(f"処理時間: {result['data']['processing_time_ms']}ms")
            print(f"HTMLサイズ: {result['data']['generation_info']['html_size_bytes']} bytes")
            print(f"セクション数: {result['data']['generation_info']['sections_count']}")
            print(f"全体的な雰囲気: {result['data']['generation_info']['overall_mood']}")
            
            # HTMLファイルとして保存（テスト用）
            filename = f"test_graphical_record_{template}.html"
            with open(filename, 'w', encoding='utf-8') as f:
                f.write(result['data']['html_content'])
            print(f"HTMLファイル保存: {filename}")
        else:
            print("❌ 変換失敗")
            print(f"エラー: {result['error']}")

def _clean_markdown_codeblocks_service(html_content: str) -> str:
    """
    JSON to HTML変換サービス用のMarkdownコードブロッククリーンアップ - 強化版
    
    Args:
        html_content (str): クリーンアップするHTMLコンテンツ
        
    Returns:
        str: Markdownコードブロックが除去されたHTMLコンテンツ
    """
    if not html_content:
        return html_content
    
    import re
    
    content = html_content.strip()
    
    # Markdownコードブロックの様々なパターンを削除 - 強化版
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
    
    # HTMLの前後にある説明文を削除（より積極的に）
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
    
    # デバッグログ：サービスレベルでのクリーンアップチェック（強化）
    if '```' in content or '`' in content:
        logger.warning(f"Service: Markdown code block remnants detected: {content[:100]}...")
    
    return content


if __name__ == "__main__":
    test_json_to_graphical_record_conversion() 