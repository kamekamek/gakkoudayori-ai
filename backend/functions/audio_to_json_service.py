"""
音声→JSON変換サービス

音声認識結果を構造化されたJSONデータに変換
グラフィックレコーディング（グラレコ）用のデータ構造を生成
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

def convert_speech_to_json(
    transcribed_text: str,
    project_id: str,
    credentials_path: str,
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
        
        # プロンプト構築
        system_prompt = f"""
あなたは学校の先生の音声記録を構造化されたJSONデータに変換する専門AIです。

## タスク
音声認識で得られたテキストを、グラフィックレコーディング（グラレコ）用の構造化JSONデータに変換してください。

## 出力形式
以下のJSONスキーマに厳密に従って出力してください：

```json
{json.dumps(json_schema, indent=2, ensure_ascii=False)}
```

## 変換ルール
1. **セクション分類**: 内容を適切なtype（activity, learning, event, discussion, announcement）に分類
2. **感情分析**: 各セクションの雰囲気をemotion（positive, neutral, focused, excited, calm, concerned）で表現
3. **参加者抽出**: 「子どもたち」「3年生」「全員」などの参加者情報を抽出
4. **ハイライト抽出**: 重要なポイントや成果を3-5個抽出
5. **次のアクション**: 今後の予定や課題があれば抽出
6. **日付推定**: 明示的な日付がない場合は今日の日付を使用

## 注意事項
- 出力は有効なJSONのみ（説明文は不要）
- 日本語の内容はそのまま保持
- 推測が必要な場合は合理的な推測を行う
- 不明な情報は空配列[]や"neutral"などのデフォルト値を使用

## 追加コンテキスト
{custom_context if custom_context else "特になし"}
"""

        user_prompt = f"""
以下の音声認識テキストをJSONに変換してください：

```
{transcribed_text}
```

出力（JSONのみ）:
"""

        full_prompt = f"{system_prompt}\n\n{user_prompt}"
        
        logger.info(f"Converting speech to JSON. Text length: {len(transcribed_text)} chars")
        
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
        
        # JSON抽出・検証
        json_result = extract_and_validate_json(generated_text)
        
        if not json_result["valid"]:
            logger.error(f"Invalid JSON generated: {json_result['error']}")
            return {
                "success": False,
                "error": {
                    "code": "INVALID_JSON",
                    "message": "生成されたJSONが無効です",
                    "details": {
                        "validation_error": json_result["error"],
                        "generated_text": generated_text[:500] + "..." if len(generated_text) > 500 else generated_text,
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
                "json_data": json_result["data"],
                "source_text": transcribed_text,
                "ai_metadata": ai_metadata,
                "validation_info": {
                    "schema_valid": True,
                    "sections_count": len(json_result["data"].get("sections", [])),
                    "highlights_count": len(json_result["data"].get("highlights", [])),
                    "overall_mood": json_result["data"].get("overall_mood", "neutral")
                },
                "processing_time_ms": int(processing_time * 1000),
                "timestamp": timestamp
            }
        }
        
    except Exception as e:
        logger.error(f"Speech to JSON conversion failed: {e}")
        return {
            "success": False,
            "error": {
                "code": "CONVERSION_ERROR",
                "message": f"音声→JSON変換中にエラーが発生しました: {str(e)}",
                "details": {
                    "error_type": type(e).__name__,
                    "processing_time_ms": int((time.time() - start_time) * 1000),
                    "timestamp": timestamp
                }
            }
        }


# ==============================================================================
# JSON検証・抽出機能
# ==============================================================================

def extract_and_validate_json(text: str) -> Dict[str, Any]:
    """
    テキストからJSONを抽出し、スキーマに対して検証
    
    Args:
        text (str): JSON含有テキスト
        
    Returns:
        Dict[str, Any]: 検証結果
    """
    try:
        # JSONブロックを抽出（```json ... ``` または { ... }）
        json_text = text.strip()
        
        # コードブロック形式の場合
        if "```json" in json_text:
            start = json_text.find("```json") + 7
            end = json_text.find("```", start)
            if end != -1:
                json_text = json_text[start:end].strip()
        elif "```" in json_text:
            start = json_text.find("```") + 3
            end = json_text.find("```", start)
            if end != -1:
                json_text = json_text[start:end].strip()
        
        # JSON部分のみを抽出（最初の{から最後の}まで）
        start_brace = json_text.find("{")
        if start_brace == -1:
            return {
                "valid": False,
                "error": "JSON開始ブレース '{' が見つかりません",
                "data": None
            }
        
        # 対応する閉じブレースを見つける
        brace_count = 0
        end_brace = -1
        for i in range(start_brace, len(json_text)):
            if json_text[i] == "{":
                brace_count += 1
            elif json_text[i] == "}":
                brace_count -= 1
                if brace_count == 0:
                    end_brace = i
                    break
        
        if end_brace == -1:
            return {
                "valid": False,
                "error": "JSON終了ブレース '}' が見つかりません",
                "data": None
            }
        
        json_text = json_text[start_brace:end_brace + 1]
        
        # JSONパース
        parsed_json = json.loads(json_text)
        
        # 基本的なスキーマ検証
        schema = get_json_schema()
        required_fields = schema.get("required", [])
        
        for field in required_fields:
            if field not in parsed_json:
                return {
                    "valid": False,
                    "error": f"必須フィールド '{field}' が不足しています",
                    "data": None
                }
        
        # sectionsの検証
        if "sections" in parsed_json:
            for i, section in enumerate(parsed_json["sections"]):
                if not isinstance(section, dict):
                    return {
                        "valid": False,
                        "error": f"sections[{i}] は辞書である必要があります",
                        "data": None
                    }
                
                section_required = ["type", "title", "content", "emotion"]
                for req_field in section_required:
                    if req_field not in section:
                        return {
                            "valid": False,
                            "error": f"sections[{i}] に必須フィールド '{req_field}' が不足しています",
                            "data": None
                        }
        
        return {
            "valid": True,
            "error": None,
            "data": parsed_json
        }
        
    except json.JSONDecodeError as e:
        return {
            "valid": False,
            "error": f"JSON解析エラー: {str(e)}",
            "data": None
        }
    except Exception as e:
        return {
            "valid": False,
            "error": f"JSON検証エラー: {str(e)}",
            "data": None
        }


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