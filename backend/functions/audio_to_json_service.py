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
        style (str): プロンプトのスタイル (例: "classic")
        
    Returns:
        Optional[str]: 読み込んだプロンプトの文字列、見つからない場合はNone
    """
    prompt_filename = f"{style.upper().replace('CLASIC', 'CLASSIC')}_TENSAKU.md"
    try:
        # スクリプトのディレクトリ基準でパスを解決
        prompt_path = os.path.join(PROMPT_DIR, prompt_filename)
        
        if not os.path.exists(prompt_path):
            logger.error(f"Prompt file not found: {prompt_path}")
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
    グラレコ用JSON構造のスキーマを取得
    
    Returns:
        Dict[str, Any]: JSONスキーマ定義
    """
    return {
        "type": "object",
        "properties": {
            "title": {
                "type": "string",
                "description": "グラレコのタイトル"
            },
            "date": {
                "type": "string",
                "format": "date",
                "description": "日付 (YYYY-MM-DD形式)"
            },
            "sections": {
                "type": "array",
                "items": {
                    "type": "object",
                    "properties": {
                        "type": {
                            "type": "string",
                            "enum": ["activity", "learning", "event", "discussion", "announcement"],
                            "description": "セクションの種類"
                        },
                        "title": {
                            "type": "string",
                            "description": "セクションのタイトル"
                        },
                        "content": {
                            "type": "string",
                            "description": "セクションの内容"
                        },
                        "emotion": {
                            "type": "string",
                            "enum": ["positive", "neutral", "focused", "excited", "calm", "concerned"],
                            "description": "感情・雰囲気"
                        },
                        "participants": {
                            "type": "array",
                            "items": {"type": "string"},
                            "description": "参加者・対象者"
                        },
                        "time": {
                            "type": "string",
                            "description": "時間帯（任意）"
                        }
                    },
                    "required": ["type", "title", "content", "emotion"]
                }
            },
            "highlights": {
                "type": "array",
                "items": {"type": "string"},
                "description": "重要なポイント・ハイライト"
            },
            "next_actions": {
                "type": "array",
                "items": {"type": "string"},
                "description": "次のアクション・予定"
            },
            "overall_mood": {
                "type": "string",
                "enum": ["positive", "neutral", "mixed", "energetic", "calm"],
                "description": "全体的な雰囲気"
            }
        },
        "required": ["title", "date", "sections", "highlights"]
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
    model_name: str = "gemini-1.5-pro",
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

        # プロンプトに変数を埋め込む
        system_prompt = system_prompt_template.format(
            json_schema=json.dumps(json_schema, indent=2, ensure_ascii=False),
            custom_context=custom_context if custom_context else "特になし"
        )

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
    テスト用のサンプルJSONデータを生成
    
    Returns:
        Dict[str, Any]: サンプルJSONデータ
    """
    return {
        "title": "今日の学級の様子",
        "date": datetime.now().strftime("%Y-%m-%d"),
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
            },
            {
                "type": "event",
                "title": "給食の時間",
                "content": "今日のメニューはカレーライスでした。みんなおいしそうに食べていました。",
                "emotion": "excited",
                "participants": ["全員"],
                "time": "12:15-13:00"
            }
        ],
        "highlights": [
            "元気な挨拶ができた",
            "九九の練習に集中して取り組んだ",
            "給食を楽しく食べた"
        ],
        "next_actions": [
            "明日は運動会の練習",
            "7の段の復習"
        ],
        "overall_mood": "positive"
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