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

# Gemini API関連
from gemini_api_service import generate_text

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
        template_name (str): テンプレート名 (例: "classic")
        
    Returns:
        Optional[str]: 読み込んだプロンプトの文字列、見つからない場合はNone
    """
    # テンプレート名からファイル名を決定（例: 'colorful' -> 'COLORFUL_LAYOUT.md'）
    # classic, modernなど、flowドキュメントの指定に合わせる
    if template_name in ['classic', 'modern']:
         prompt_filename = f"{template_name.upper()}_LAYOUT.md"
    else: # colorful, pastelなどはclassicにフォールバック
         prompt_filename = f"CLASSIC_LAYOUT.md"

    try:
        prompt_path = os.path.join(PROMPT_DIR, prompt_filename)
        
        if not os.path.exists(prompt_path):
            logger.error(f"Prompt file not found: {prompt_path}")
            # フォールバックとしてclassicを試みる
            if template_name != 'classic':
                logger.warning(f"Falling back to classic layout prompt.")
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
            "description": "シンプルで落ち着いた印象",
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
    model_name: str = "gemini-2.0-flash-exp",
    temperature: float = 0.2,
    max_output_tokens: int = 3072
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

        # プロンプトに変数を埋め込む
        system_prompt = system_prompt_template.format(
            template_name=template_info.get('name', 'N/A'),
            template_style=template_info.get('style', 'N/A'),
            template_description=template_info.get('description', 'N/A'),
            colors=json.dumps(template_info.get('colors', {}), indent=2, ensure_ascii=False),
            emotion_icons=json.dumps(emotion_icons, indent=2, ensure_ascii=False),
            section_icons=json.dumps(section_icons, indent=2, ensure_ascii=False),
            title=json_data.get("title", "無題の学級通信") # titleをJSONデータから取得
        )

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
    生成されたHTMLを検証・クリーンアップ
    
    Args:
        html_content (str): 生成されたHTML
        
    Returns:
        Dict[str, Any]: 検証結果
    """
    try:
        # HTMLの基本構造をチェック
        html_text = html_content.strip()
        
        # HTMLブロックを抽出（```html ... ``` または <!DOCTYPE html> ... </html>）
        if "```html" in html_text:
            start = html_text.find("```html") + 7
            end = html_text.find("```", start)
            if end != -1:
                html_text = html_text[start:end].strip()
        elif "```" in html_text:
            start = html_text.find("```") + 3
            end = html_text.find("```", start)
            if end != -1:
                html_text = html_text[start:end].strip()
        
        # DOCTYPE宣言の確認
        if not html_text.startswith("<!DOCTYPE html>"):
            if "<html" in html_text:
                # DOCTYPE宣言を追加
                html_start = html_text.find("<html")
                html_text = "<!DOCTYPE html>\n" + html_text[html_start:]
            else:
                return {
                    "valid": False,
                    "error": "HTML開始タグが見つかりません",
                    "html": None
                }
        
        # 基本的なHTML構造の確認
        required_tags = ["<html", "</html>", "<head", "</head>", "<body", "</body>"]
        for tag in required_tags:
            if tag not in html_text:
                return {
                    "valid": False,
                    "error": f"必須HTMLタグ '{tag}' が見つかりません",
                    "html": None
                }
        
        # メタタグの確認・追加
        if '<meta charset="UTF-8">' not in html_text and '<meta charset="utf-8">' not in html_text:
            # charset metaタグを追加
            head_start = html_text.find("<head>") + 6
            html_text = html_text[:head_start] + '\n    <meta charset="UTF-8">' + html_text[head_start:]
        
        if 'name="viewport"' not in html_text:
            # viewport metaタグを追加
            charset_pos = html_text.find('<meta charset="UTF-8">') + len('<meta charset="UTF-8">')
            html_text = html_text[:charset_pos] + '\n    <meta name="viewport" content="width=device-width, initial-scale=1.0">' + html_text[charset_pos:]
        
        # 基本的なセキュリティチェック
        dangerous_patterns = ["<script", "javascript:", "onclick=", "onerror="]
        for pattern in dangerous_patterns:
            if pattern in html_text.lower():
                logger.warning(f"Potentially dangerous pattern found: {pattern}")
                # 実際のプロダクションでは、より厳密なサニタイゼーションが必要
        
        return {
            "valid": True,
            "error": None,
            "html": html_text
        }
        
    except Exception as e:
        return {
            "valid": False,
            "error": f"HTML検証エラー: {str(e)}",
            "html": None
        }


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


if __name__ == "__main__":
    test_json_to_graphical_record_conversion() 