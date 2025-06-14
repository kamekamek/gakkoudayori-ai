"""
音声→JSON変換サービス

音声認識結果を構造化されたJSONデータに変換
グラフィックレコーディング（グラレコ）用のデータ構造を生成
"""

import os
import logging
import time
import json
import re
from typing import Dict, Any, List, Optional, Tuple
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
def load_prompt(style: str) -> Optional[str]:
    """
    指定されたスタイルのプロンプトファイルを読み込む
    
    Args:
        style (str): プロンプトのスタイル (例: "classic", "modern")
        
    Returns:
        Optional[str]: 読み込んだプロンプトの文字列、見つからない場合はNone
    """
    # スタイルに応じてプロンプトファイル名を決定
    if style.lower() == 'modern':
        prompt_filename = "MODERN_TENSAKU.md"
    else:
        # classic または その他のスタイルはCLASSIC_TENSAKU.mdを使用
        prompt_filename = "CLASSIC_TENSAKU.md"
    
    try:
        # スクリプトのディレクトリ基準でパスを解決
        prompt_path = os.path.join(PROMPT_DIR, prompt_filename)
        
        if not os.path.exists(prompt_path):
            logger.error(f"Prompt file not found: {prompt_path}")
            # モダンプロンプトが見つからない場合はクラシックにフォールバック
            if style.lower() == 'modern':
                logger.warning(f"Modern prompt not found, falling back to classic")
                return load_prompt('classic')
            return None
            
        with open(prompt_path, "r", encoding="utf-8") as f:
            return f.read()
    except Exception as e:
        logger.error(f"Error loading prompt file {prompt_filename}: {e}")
        return None


# ==============================================================================
# JSON構造定義
# ==============================================================================

def get_json_schema() -> Dict[str, Any]:
    """
    学級通信用JSON構造のスキーマを取得（CLASSIC_TENSAKU.md v2.2 + MODERN_TENSAKU.md v2.3準拠）
    
    Returns:
        Dict[str, Any]: JSONスキーマ定義
    """
    return {
        "type": "object",
        "properties": {
            "school_name": {
                "type": "string",
                "description": "学校名"
            },
            "grade": {
                "type": "string",
                "description": "発行対象学年"
            },
            "issue": {
                "type": "string",
                "description": "号数"
            },
            "issue_date": {
                "type": "string",
                "description": "発行日"
            },
            "author": {
                "type": "object",
                "properties": {
                    "name": {"type": "string"},
                    "title": {"type": "string"}
                },
                "required": ["name", "title"]
            },
            "main_title": {
                "type": "string",
                "description": "メインタイトル"
            },
            "sub_title": {
                "type": ["string", "null"],
                "description": "サブタイトル"
            },
            "season": {
                "type": "string",
                "description": "季節"
            },
            "theme": {
                "type": "string",
                "description": "テーマ"
            },
            "color_scheme": {
                "type": "object",
                "properties": {
                    "primary": {"type": "string"},
                    "secondary": {"type": "string"},
                    "accent": {"type": "string"},
                    "background": {"type": "string"}
                },
                "required": ["primary", "secondary", "accent", "background"]
            },
            "color_scheme_source": {
                "type": "string",
                "description": "カラースキームの根拠"
            },
            "sections": {
                "type": "array",
                "items": {
                    "type": "object",
                    "properties": {
                        "type": {
                            "type": "string",
                            "enum": ["greeting", "main", "event", "announcement", "ending"],
                            "description": "セクションの種類"
                        },
                        "title": {
                            "type": ["string", "null"],
                            "description": "セクションのタイトル"
                        },
                        "content": {
                            "type": "string",
                            "description": "セクションの内容"
                        },
                        "emotion": {
                            "type": "string",
                            "enum": ["positive", "neutral", "focused", "excited", "calm", "concerned"],
                            "description": "セクションの感情表現"
                        },
                        "section_visual_hint": {
                            "type": ["string", "null"],
                            "enum": ["role-list", "emphasis-block", "infographic", None],
                            "description": "モダンスタイル用の視覚的ヒント"
                        },
                        "estimated_length": {
                            "type": ["string", "null"],
                            "enum": ["short", "medium", "long", None],
                            "description": "セクションの推定分量"
                        }
                    },
                    "required": ["type", "content"]
                }
            },
            "photo_placeholders": {
                "type": "object",
                "properties": {
                    "count": {"type": "number"},
                    "suggested_positions": {
                        "type": "array",
                        "items": {
                            "type": "object",
                            "properties": {
                                "section_type": {"type": "string"},
                                "position": {"type": "string"},
                                "caption_suggestion": {"type": "string"}
                            }
                        }
                    }
                }
            },
            "enhancement_suggestions": {
                "type": "array",
                "items": {"type": "string"},
                "description": "改善提案"
            },
            "has_editor_note": {
                "type": "boolean",
                "description": "編集者注記の有無"
            },
            "editor_note": {
                "type": ["string", "null"],
                "description": "編集者注記"
            },
            "layout_suggestion": {
                "type": "object",
                "properties": {
                    "page_count": {"type": "number"},
                    "columns": {"type": "number"},
                    "column_ratio": {"type": "string"},
                    "blocks": {
                        "type": "array",
                        "items": {"type": "string"}
                    }
                }
            },
            "meta_reasoning": {
                "type": "object",
                "properties": {
                    "title_reason": {"type": "string"},
                    "issue_reason": {"type": "string"},
                    "grade_reason": {"type": "string"},
                    "author_reason": {"type": "string"},
                    "sectioning_strategy_reason": {"type": "string"},
                    "season_reason": {"type": "string"},
                    "color_reason": {"type": "string"}
                }
            }
        },
        "required": ["school_name", "grade", "issue", "issue_date", "author", "main_title", "season", "theme", "sections"]
    }


# ==============================================================================
# 音声→JSON変換機能
# ==============================================================================

def extract_json_from_response(response_text: str) -> Optional[str]:
    """
    AIの応答からJSONコードブロックを抽出する
    """
    # ```json ... ``` ブロックを探す
    match = re.search(r'```json\s*(\{.*?\})\s*```', response_text, re.DOTALL)
    if match:
        return match.group(1)
    
    # ``` ... ``` ブロックを探す
    match = re.search(r'```\s*(\{.*?\})\s*```', response_text, re.DOTALL)
    if match:
        return match.group(1)

    # JSONオブジェクトそのものを探す
    if response_text.strip().startswith('{'):
        return response_text

    logger.warning("No JSON block found in the response.")
    return None


def convert_speech_to_json(
    transcribed_text: str,
    project_id: str,
    credentials_path: str,
    style: str = "classic",
    custom_context: str = "",
    model_name: str = "gemini-2.0-flash-exp",
    temperature: float = 0.3,
    max_output_tokens: int = 2048
) -> Dict[str, Any]:
    """
    音声認識結果を構造化JSONに変換
    
    Args:
        transcribed_text (str): 音声認識結果のテキスト
        project_id (str): Google CloudプロジェクトID
        credentials_path (str): サービスアカウントキーファイルのパス
        style (str): 使用するプロンプトのスタイル
        custom_context (str): 追加のコンテキスト情報
        model_name (str): 使用するGeminiモデル
        temperature (float): 生成の多様性
        max_output_tokens (int): 最大出力トークン数
        
    Returns:
        Dict[str, Any]: 変換結果（成功時はJSONデータ、失敗時はエラー情報）
    """
    start_time = time.time()
    timestamp = datetime.now().isoformat()
    
    try:
        # JSONスキーマを取得
        json_schema = get_json_schema()
        
        # プロンプトをファイルから読み込み
        system_prompt_template = load_prompt(style)
        if not system_prompt_template:
            return {
                "success": False,
                "error": {
                    "code": "PROMPT_LOADING_FAILED",
                    "message": f"Style '{style}'のプロンプトファイルの読み込みに失敗しました。",
                    "processing_time_ms": int((time.time() - start_time) * 1000),
                    "timestamp": timestamp
                }
            }

        # プロンプトをそのまま使用（v2.2プロンプトは完全な形式）
        system_prompt = system_prompt_template
        
        # カスタムコンテキストがある場合は追加
        if custom_context and custom_context.strip():
            system_prompt += f"\n\n### 追加指示\n{custom_context}"

        user_prompt = f"""
以下の音声認識テキストをJSONに変換してください：

```
{transcribed_text}
```

出力（JSONのみ）:
"""

        full_prompt = f"{system_prompt}\n\n{user_prompt}"
        
        logger.info(f"Converting speech to JSON. Text length: {len(transcribed_text)} chars. Style: {style}")
        
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
                    "message": "音声→JSON変換でGemini APIエラーが発生しました",
                    "details": api_response.get("error", {}),
                    "processing_time_ms": int((time.time() - start_time) * 1000),
                    "timestamp": timestamp
                }
            }
        
        # 生成されたテキストからJSONを抽出
        generated_text = api_response.get("data", {}).get("text", "")
        ai_metadata = api_response.get("data", {}).get("ai_metadata", {})
        
        # JSONをパース
        response_text = generated_text
        
        # 応答からJSON部分のみを抽出
        json_string = extract_json_from_response(response_text)
        if not json_string:
            logger.error("Failed to extract JSON from AI response.")
            return {"success": False, "error": {"code": "JSON_EXTRACTION_FAILED", "message": "AIの応答からJSONを抽出できませんでした。"}}

        try:
            # 抽出した文字列をJSONとしてパース
            generated_json = json.loads(json_string)
        except json.JSONDecodeError as e:
            logger.error(f"Failed to decode extracted JSON: {e}")
            return {"success": False, "error": {"code": "JSON_DECODE_ERROR", "message": str(e)}}

        # バリデーション
        is_valid, error_message = validate_generated_json(generated_json)
        if not is_valid:
            logger.error(f"Invalid JSON generated: {error_message}")
            return {"success": False, "error": {"code": "JSON_VALIDATION_ERROR", "message": error_message}}
        
        # 成功レスポンス
        processing_time = time.time() - start_time
        
        return {
            "success": True,
            "data": {
                "json_data": generated_json,
                "source_text": transcribed_text,
                "ai_metadata": ai_metadata,
                "validation_info": {
                    "schema_valid": True,
                    "sections_count": len(generated_json.get("sections", [])),
                    "highlights_count": len(generated_json.get("highlights", [])),
                    "overall_mood": generated_json.get("overall_mood", "neutral")
                },
                "processing_time_ms": int(processing_time * 1000),
                "timestamp": timestamp
            }
        }
        
    except Exception as e:
        logger.error(f"Speech to JSON conversion failed: {e}", exc_info=True)
        return {"success": False, "error": {"code": "UNKNOWN_ERROR", "message": str(e)}}


# ==============================================================================
# JSON検証・抽出機能
# ==============================================================================

def validate_generated_json(json_data: Dict[str, Any]) -> Tuple[bool, Optional[str]]:
    """
    生成されたJSONデータを検証
    
    Args:
        json_data (Dict[str, Any]): 生成されたJSONデータ
        
    Returns:
        Tuple[bool, Optional[str]]: 検証結果とエラーメッセージ
    """
    try:
        # 基本的なスキーマ検証
        schema = get_json_schema()
        required_fields = schema.get("required", [])
        
        for field in required_fields:
            if field not in json_data:
                return False, f"必須フィールド '{field}' が不足しています"
        
        # sectionsの検証
        if "sections" in json_data:
            for i, section in enumerate(json_data["sections"]):
                if not isinstance(section, dict):
                    return False, f"sections[{i}] は辞書である必要があります"
                
                section_required = ["type", "title", "content", "emotion"]
                for req_field in section_required:
                    if req_field not in section:
                        return False, f"sections[{i}] に必須フィールド '{req_field}' が不足しています"
        
        return True, None
    except Exception as e:
        return False, f"JSON検証エラー: {str(e)}"


# ==============================================================================
# サンプルデータ生成
# ==============================================================================

def generate_sample_json() -> Dict[str, Any]:
    """
    テスト用のサンプルJSONデータを生成（CLASSIC_TENSAKU.md v2.2準拠）
    
    Returns:
        Dict[str, Any]: サンプルJSONデータ
    """
    return {
        "school_name": "○○小学校",
        "grade": "第3学年",
        "issue": "第1号",
        "issue_date": datetime.now().strftime("%Y年%m月%d日"),
        "author": {
            "name": "○○校長",
            "title": "校長"
        },
        "main_title": "今日の学級の様子",
        "sub_title": None,
        "season": "春",
        "theme": "新学期の始まり",
        "color_scheme": {
            "primary": "#2c3e50",
            "secondary": "#3498db",
            "accent": "#e74c3c",
            "background": "#ffffff"
        },
        "color_scheme_source": "春の新緑をイメージした清潔感のある配色",
        "sections": [
            {
                "type": "greeting",
                "title": "はじめに",
                "content": "新学期が始まり、子どもたちの元気な声が学校に響いています。"
            },
            {
                "type": "main",
                "title": "朝の会の様子",
                "content": "みんな元気に挨拶ができました。今日の係活動の確認も行いました。"
            },
            {
                "type": "main",
                "title": "算数の授業",
                "content": "九九の練習をしました。7の段が難しそうでしたが、みんな頑張って覚えようとしていました。"
            },
            {
                "type": "ending",
                "title": "おわりに",
                "content": "今後ともご協力をお願いいたします。"
            }
        ],
        "photo_placeholders": {
            "count": 2,
            "suggested_positions": [
                {
                    "section_type": "main",
                    "position": "end_of_section",
                    "caption_suggestion": "朝の会の様子"
                }
            ]
        },
        "enhancement_suggestions": [
            "明日の持ち物について追記することを推奨",
            "保護者への連絡事項があれば追加"
        ],
        "has_editor_note": False,
        "editor_note": None,
        "layout_suggestion": {
            "page_count": 1,
            "columns": 1,
            "column_ratio": "1:1",
            "blocks": ["header", "sections", "footer"]
        },
        "meta_reasoning": {
            "title_reason": "日常の学級活動を報告する内容のため",
            "issue_reason": "新学期最初の発行のため第1号と推論",
            "grade_reason": "3年生の活動内容が含まれているため",
            "author_reason": "一般的な学級通信は校長発行のため",
            "sectioning_strategy_reason": "挨拶、メイン活動2点、締めの構成で分割",
            "season_reason": "新学期の時期のため春と判断",
            "color_reason": "春の新緑と清潔感を表現"
        }
    }


# ==============================================================================
# テスト機能
# ==============================================================================

def test_speech_to_json_conversion():
    """
    音声→JSON変換のテスト
    """
    sample_text = """
今日は朝の会でみんな元気に挨拶ができました。
その後、算数の授業で九九の練習をしました。7の段が少し難しそうでしたが、
子どもたちは一生懸命頑張っていました。
給食の時間はカレーライスで、みんなとても喜んで食べていました。
明日は運動会の練習があります。
"""
    
    # テスト用の設定
    project_id = "gakkoudayori-ai"
    credentials_path = "../secrets/service-account-key.json"
    
    print("=== 音声→JSON変換テスト ===")
    print(f"入力テキスト: {sample_text}")
    
    result = convert_speech_to_json(
        transcribed_text=sample_text,
        project_id=project_id,
        credentials_path=credentials_path
    )
    
    if result["success"]:
        print("✅ 変換成功")
        print(f"処理時間: {result['data']['processing_time_ms']}ms")
        print(f"セクション数: {result['data']['validation_info']['sections_count']}")
        print(f"ハイライト数: {result['data']['validation_info']['highlights_count']}")
        print(f"全体的な雰囲気: {result['data']['validation_info']['overall_mood']}")
        print("\n生成されたJSON:")
        print(json.dumps(result['data']['json_data'], indent=2, ensure_ascii=False))
    else:
        print("❌ 変換失敗")
        print(f"エラー: {result['error']}")


if __name__ == "__main__":
    test_speech_to_json_conversion() 