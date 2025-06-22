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
from .gemini_api_service import generate_text

# ロギング設定
logger = logging.getLogger(__name__)

# ADK関連（公式フレームワーク）
try:
    from .adk_official_service import generate_newsletter_with_official_adk
    OFFICIAL_ADK_AVAILABLE = True
    logger.info("Official ADK service imported successfully")
except ImportError as e:
    OFFICIAL_ADK_AVAILABLE = False
    logger.warning(f"Official ADK service not available: {e}")

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


def repair_json_data(json_data: Dict[str, Any], schema: Dict[str, Any]) -> Tuple[Dict[str, Any], List[str]]:
    """
    不足している必須フィールドをデフォルト値で補完してJSONを修復する
    """
    repaired_data = json_data.copy()
    repairs_made = []

    required_fields = schema.get("required", [])
    for field in required_fields:
        if field not in repaired_data or not repaired_data[field]:
            default_value = ""
            if field == "school_name":
                default_value = "（学校名不明）"
            elif field == "issue_date":
                default_value = datetime.now().strftime('%Y-%m-%d')
            elif field == "grade":
                default_value = "（学年不明）"
            elif field == "issue":
                default_value = "（号数不明）"
            elif field == "author":
                default_value = {"name": "（作成者不明）", "title": "担任"}
            elif field == "main_title":
                default_value = "（タイトルなし）"
            elif field == "season":
                default_value = "（季節不明）"
            elif field == "theme":
                default_value = "（テーマ不明）"
            elif field == "sections":
                default_value = []
            
            repaired_data[field] = default_value
            repairs_made.append(f"フィールド '{field}' をデフォルト値で補完しました。")

    return repaired_data, repairs_made


def _convert_adk_to_legacy_format(adk_data: Dict[str, Any]) -> Dict[str, Any]:
    """
    ADKマルチエージェント結果を従来のJSON形式に変換
    
    Args:
        adk_data: ADKから返されたデータ
        
    Returns:
        従来形式のJSONデータ
    """
    try:
        # ADKの結果から必要な情報を抽出
        optimized_content = adk_data.get("optimized_content", {}).get("optimized_content", {})
        content_analysis = adk_data.get("content_analysis", {})
        layout_design = adk_data.get("layout_design", {})
        
        # 基本情報の推定
        inferred_metadata = content_analysis.get("inferred_metadata", {})
        
        # セクション情報を従来形式に変換
        newsletter_sections = optimized_content.get("newsletter_sections", [])
        sections = []
        
        for section in newsletter_sections:
            sections.append({
                "type": section.get("section_type", "main"),
                "title": section.get("title"),
                "content": section.get("content", ""),
                "emotion": "positive"  # デフォルト
            })
        
        # カラースキームの変換
        color_scheme = layout_design.get("color_scheme", {})
        if not color_scheme:
            color_scheme = {
                "primary": "#2c3e50",
                "secondary": "#3498db", 
                "accent": "#e74c3c",
                "background": "#ffffff"
            }
        
        # 従来形式のJSONデータ構造
        legacy_json = {
            "school_name": inferred_metadata.get("school_context", "○○小学校"),
            "grade": inferred_metadata.get("grade_level", "3年1組"),
            "issue": "第1号",  # ADKからは推定困難なのでデフォルト
            "issue_date": datetime.now().strftime("%Y年%m月%d日"),
            "author": {
                "name": "担任教師",
                "title": "担任"
            },
            "main_title": sections[0].get("title", "学級通信") if sections else "学級通信",
            "sub_title": None,
            "season": inferred_metadata.get("season", "春"),
            "theme": content_analysis.get("key_messages", [{}])[0].get("content", "学級の様子") if content_analysis.get("key_messages") else "学級の様子",
            "color_scheme": color_scheme,
            "color_scheme_source": layout_design.get("color_scheme_rationale", "季節に応じた配色"),
            "sections": sections,
            "photo_placeholders": {
                "count": layout_design.get("photo_layout", {}).get("suggested_photo_count", 2),
                "suggested_positions": [
                    {
                        "section_type": "main",
                        "position": "end_of_section", 
                        "caption_suggestion": "活動の様子"
                    }
                ]
            },
            "enhancement_suggestions": adk_data.get("fact_check", {}).get("improvement_suggestions", []),
            "has_editor_note": False,
            "editor_note": None,
            "layout_suggestion": {
                "page_count": 1,
                "columns": layout_design.get("layout_structure", {}).get("column_count", 1),
                "column_ratio": "1:1",
                "blocks": layout_design.get("layout_structure", {}).get("section_arrangement", ["header", "main", "footer"])
            },
            "meta_reasoning": {
                "title_reason": "ADKマルチエージェントにより最適化されたタイトル",
                "issue_reason": "新規作成のため第1号と設定",
                "grade_reason": f"音声内容から{inferred_metadata.get('grade_level', '3年生')}と推定",
                "author_reason": "教師による作成",
                "sectioning_strategy_reason": "ADKエージェントによる構造化",
                "season_reason": f"時期と内容から{inferred_metadata.get('season', '春')}と判定",
                "color_reason": layout_design.get("color_scheme_rationale", "季節とテーマに基づく配色選択")
            }
        }
        
        return legacy_json
        
    except Exception as e:
        logger.error(f"ADK to legacy format conversion failed: {e}")
        # フォールバック: 最小限のデータ構造を返す
        return {
            "school_name": "○○小学校",
            "grade": "3年1組", 
            "issue": "第1号",
            "issue_date": datetime.now().strftime("%Y年%m月%d日"),
            "author": {"name": "担任教師", "title": "担任"},
            "main_title": "学級通信",
            "season": "春",
            "theme": "学級の様子",
            "sections": [
                {
                    "type": "main",
                    "title": "ADK変換エラー",
                    "content": "マルチエージェント結果の変換中にエラーが発生しました。",
                    "emotion": "neutral"
                }
            ]
        }


def _convert_official_adk_to_legacy_format(adk_result: Dict[str, Any]) -> Dict[str, Any]:
    """
    公式ADKマルチエージェント結果を従来のJSON形式に変換
    
    Args:
        adk_result: 公式ADKから返された結果
        
    Returns:
        従来形式のJSONデータ
    """
    try:
        # 新しい公式ADK結果構造から情報を抽出
        data = adk_result.get("data", {})
        adk_metadata = adk_result.get("adk_metadata", {})
        
        # コンテンツの抽出
        content_text = data.get("content", "")
        
        # デザイン仕様の抽出
        design_spec = {}
        design_spec_str = data.get("design_spec", "{}")
        try:
            design_spec = json.loads(design_spec_str) if isinstance(design_spec_str, str) else design_spec_str
        except json.JSONDecodeError:
            design_spec = {}
        
        # HTMLの抽出
        final_html = data.get("html", "")
        
        # セクションの抽出（既に構造化されている場合）
        sections = data.get("sections", [])
        if not sections and content_text:
            # セクションが提供されていない場合は、コンテンツから簡単なセクションを生成
            sections = [
                {
                    "type": "title",
                    "content": "学級通信",
                    "style": "heading"
                },
                {
                    "type": "paragraph", 
                    "content": content_text,
                    "style": "body_text"
                }
            ]
        
        # 品質スコアの抽出
        quality_score = adk_metadata.get("quality_score", 85)
        
        # 現在日時の取得
        current_date = datetime.now()
        
        # 季節の判定
        season_map = {
            (3, 4, 5): "春",
            (6, 7, 8): "夏", 
            (9, 10, 11): "秋",
            (12, 1, 2): "冬"
        }
        
        current_season = "春"
        for months, season in season_map.items():
            if current_date.month in months:
                current_season = season
                break
        
        # カラースキームの抽出
        color_scheme = design_spec.get("color_scheme", {})
        if not color_scheme:
            color_scheme = {
                "primary": "#4CAF50",
                "secondary": "#81C784", 
                "accent": "#FFC107",
                "background": "#ffffff"
            }
        
        # コンテンツからセクションを生成（簡単な分割）
        sections = []
        if content_text:
            # テキストを段落で分割してセクションを作成
            paragraphs = [p.strip() for p in content_text.split('\n\n') if p.strip()]
            
            for i, paragraph in enumerate(paragraphs[:5]):  # 最大5セクション
                section_type = "header" if i == 0 else "main"
                sections.append({
                    "type": section_type,
                    "title": f"セクション{i+1}" if i > 0 else "メインタイトル",
                    "content": paragraph,
                    "emotion": "positive"
                })
        
        # セクションが空の場合はデフォルトを追加
        if not sections:
            sections = [
                {
                    "type": "header",
                    "title": "学級通信",
                    "content": "今日の学級の様子をお伝えします。",
                    "emotion": "positive"
                }
            ]
        
        # 従来形式のJSONデータ構造
        legacy_json = {
            "school_name": "○○小学校",
            "grade": adk_result.get("input_data", {}).get("grade_level", "3年1組"),
            "issue": "第1号",
            "issue_date": current_date.strftime("%Y年%m月%d日"),
            "author": {
                "name": "担任教師",
                "title": "担任"
            },
            "main_title": "学級通信",
            "season": current_season,
            "theme": "学級の様子",
            "sections": sections,
            "visual_elements": {
                "layout": design_spec.get("layout_type", "modern"),
                "color_scheme": color_scheme,
                "fonts": design_spec.get("fonts", {
                    "heading": "Noto Sans JP",
                    "body": "Hiragino Sans"
                }),
                "season_elements": design_spec.get("visual_elements", {}).get("illustration_style", current_season)
            },
            "metadata": {
                "generation_timestamp": current_date.isoformat(),
                "processing_method": "official_adk_multi_agent",
                "content_length": len(content_text),
                "quality_score": quality_score,
                "html_available": bool(final_html),
                "agents_used": adk_result.get("agents_executed", [])
            },
            "generated_html": final_html,
            "color_theme": {
                "primary_color": color_scheme.get("primary", "#4CAF50"),
                "secondary_color": color_scheme.get("secondary", "#81C784"),
                "accent_color": color_scheme.get("accent", "#FFC107"),
                "season": current_season,
                "color_reason": f"{current_season}の季節感を表現した配色選択"
            }
        }
        
        return legacy_json
        
    except Exception as e:
        logger.error(f"Official ADK to legacy format conversion failed: {e}")
        # フォールバック: 最小限のデータ構造を返す
        return {
            "school_name": "○○小学校",
            "grade": "3年1組", 
            "issue": "第1号",
            "issue_date": datetime.now().strftime("%Y年%m月%d日"),
            "author": {"name": "担任教師", "title": "担任"},
            "main_title": "学級通信",
            "season": "春",
            "theme": "学級の様子",
            "sections": [
                {
                    "type": "header",
                    "title": "学級通信",
                    "content": "今日の学級の様子をお伝えします。",
                    "emotion": "positive"
                }
            ],
            "visual_elements": {
                "layout": "modern",
                "color_scheme": {
                    "primary": "#4CAF50",
                    "secondary": "#81C784",
                    "accent": "#FFC107"
                }
            },
            "metadata": {
                "generation_timestamp": datetime.now().isoformat(),
                "processing_method": "official_adk_fallback",
                "error": str(e)
            }
        }


# ==============================================================================
# JSON検証・抽出機能
# ==============================================================================

def validate_generated_json(json_data: Dict[str, Any]) -> Tuple[bool, List[str]]:
    """
    生成されたJSONがスキーマに準拠しているか検証する
    
    Args:
        json_data (Dict[str, Any]): AIによって生成されたJSONデータ
        
    Returns:
        Tuple[bool, List[str]]: 検証結果 (bool) とエラーメッセージのリスト
    """
    schema = get_json_schema()
    errors = []

    # 必須フィールドのチェック
    for required_field in schema.get("required", []):
        if required_field not in json_data or not json_data[required_field]:
            errors.append(f"必須フィールド '{required_field}' が不足しているか、空です。")

    # セクションの必須フィールドチェック
    if "sections" in json_data and isinstance(json_data["sections"], list):
        for i, section in enumerate(json_data["sections"]):
            if not isinstance(section, dict):
                errors.append(f"sections[{i}] がオブジェクトではありません。")
                continue
            
            section_required = schema["properties"]["sections"]["items"].get("required", [])
            for field in section_required:
                if field not in section or not section[field]:
                    errors.append(f"sections[{i}] の必須フィールド '{field}' が不足しているか、空です。")
    
    if errors:
        return False, errors
        
    return True, []


# ==============================================================================
# 音声→JSON変換機能
# ==============================================================================

def extract_json_from_response(response_text: str) -> Optional[str]:
    """
    AIの応答からJSONコードブロックを抽出する
    """
    logger.info(f"Attempting to extract JSON from response (length: {len(response_text)})")
    
    # まず、応答をログに出力（デバッグ用）
    logger.debug(f"Response text preview: {response_text[:500]}...")
    
    # ```json ... ``` ブロックを探す（より柔軟に）
    patterns = [
        r'```json\s*(\{.*?\})\s*```',
        r'```JSON\s*(\{.*?\})\s*```',
        r'```\s*(\{.*?\})\s*```',
        r'(\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\})',  # ネストしたJSONも対応
    ]
    
    for pattern in patterns:
        match = re.search(pattern, response_text, re.DOTALL | re.IGNORECASE)
        if match:
            json_text = match.group(1).strip()
            logger.info(f"JSON extracted using pattern: {pattern[:20]}...")
            # 抽出した文字列の最初と最後が波括弧であることを確認
            if json_text.startswith('{') and json_text.endswith('}'):
                return json_text

    # 行ベースでJSONの開始と終了を探す
    lines = response_text.split('\n')
    start_idx = None
    end_idx = None
    brace_count = 0
    
    for i, line in enumerate(lines):
        stripped = line.strip()
        if stripped.startswith('{') and start_idx is None:
            start_idx = i
            brace_count = 1
        elif start_idx is not None:
            brace_count += stripped.count('{') - stripped.count('}')
            if brace_count == 0:
                end_idx = i
                break
    
    if start_idx is not None and end_idx is not None:
        json_lines = lines[start_idx:end_idx + 1]
        json_text = '\n'.join(json_lines).strip()
        logger.info("JSON extracted using line-by-line parsing")
        return json_text
    
    # 最後の手段：レスポンス全体がJSONかどうかチェック
    response_stripped = response_text.strip()
    if response_stripped.startswith('{') and response_stripped.endswith('}'):
        logger.info("Using entire response as JSON")
        return response_stripped

    logger.warning("No JSON block found in the response.")
    return None


def _build_prompt(transcribed_text: str, style: str, custom_context: str = "") -> str:
    """プロンプトを構築する"""
    system_prompt = load_prompt(style)
    if not system_prompt:
        raise ValueError(f"Could not load prompt for style '{style}'")

    if custom_context:
        system_prompt += f"\n\n### 追加指示\n{custom_context}"

    user_prompt = f"""
以下の音声認識テキストを、システムプロンプトで定義されたルールに厳密に従って、学級通信用のJSONデータに変換してください。
**特に、`school_name`, `grade`, `issue`, `issue_date`, `author`, `main_title` などの基本情報は必ず含めてください。**

入力テキスト:
```
{transcribed_text}
```

出力はJSON形式のコードブロック(` ```json ... ``` `)で、他の説明文は含めないでください。
"""
    return f"{system_prompt}\n\n{user_prompt}"


def convert_speech_to_json(
    transcribed_text: str,
    project_id: str,
    credentials_path: str,
    style: str = "classic",
    custom_context: str = "",
    model_name: str = "gemini-2.5-flash-preview-05-20",
    temperature: float = 0.3,
    max_output_tokens: int = 8192,
    use_adk: bool = False,
    teacher_profile: Dict[str, Any] = None
) -> Dict[str, Any]:
    """
    音声認識テキストをJSONに変換する。検証と自己修復メカニズムを含む。

    Args:
        transcribed_text (str): 音声認識サービスから得られたテキスト
        project_id (str): GCPプロジェクトID
        credentials_path (str): GCPサービスアカウントキーのパス
        style (str): 使用するプロンプトのスタイル ('classic', 'modern')
        custom_context (str): ユーザーからの追加の指示
        model_name (str): 使用するGeminiモデル名
        temperature (float): 生成の多様性を制御する温度
        max_output_tokens (int): 最大出力トークン数
        use_adk (bool): ADKマルチエージェントシステムを使用するかどうか
        teacher_profile (Dict[str, Any]): 教師プロファイル情報（ADK使用時）

    Returns:
        Dict[str, Any]: 変換結果。成功時はJSONデータ、失敗時はエラードキュメント
    """
    logger.info(f"Converting speech to JSON. Text length: {len(transcribed_text)} chars. Style: {style}. Use ADK: {use_adk}")
    
    # ADKマルチエージェントシステムを使用する場合
    if use_adk:
        try:
            # 公式ADKサービスを使用
            import asyncio
            
            if not OFFICIAL_ADK_AVAILABLE:
                logger.warning("Official ADK service not available, falling back to traditional method")
            else:
                # 非同期関数を同期的に実行
                loop = asyncio.new_event_loop()
                asyncio.set_event_loop(loop)
                
                try:
                    adk_result = loop.run_until_complete(
                        generate_newsletter_with_official_adk(
                            audio_transcript=transcribed_text,
                            teacher_profile=teacher_profile,
                            grade_level=teacher_profile.get('grade', '3年1組') if teacher_profile else '3年1組'
                        )
                    )
                    
                    if adk_result["success"]:
                        # 公式ADK結果を従来のJSON形式に変換
                        converted_json = _convert_official_adk_to_legacy_format(adk_result)
                        
                        logger.info(f"Official ADK multi-agent conversion successful")
                        
                        return {
                            "success": True,
                            "data": converted_json,
                            "adk_metadata": {
                                "generation_method": adk_result.get("generation_method", "official_adk_multi_agent"),
                                "agents_executed": adk_result.get("agents_executed", []),
                                "content_generation": adk_result.get("content_generation", {}),
                                "design_generation": adk_result.get("design_generation", {}),
                                "html_generation": adk_result.get("html_generation", {}),
                                "quality_check": adk_result.get("quality_check", {})
                            }
                        }
                    else:
                        logger.warning(f"ADK conversion failed, falling back to traditional method: {adk_result.get('error', 'Unknown error')}")
                        # ADK失敗時は従来の方法にフォールバック
                        
                except Exception as adk_error:
                    logger.warning(f"ADK system error, falling back to traditional method: {adk_error}")
                    # ADKエラー時は従来の方法にフォールバック
                finally:
                    loop.close()
                
        except Exception as e:
            logger.warning(f"ADK system error, falling back to traditional method: {e}")
            # ADKエラー時は従来の方法にフォールバック
    
    # 従来の単一Gemini方式
    full_prompt = _build_prompt(transcribed_text, style, custom_context)
    
    try:
        api_response = generate_text(
            project_id=project_id,
            credentials_path=credentials_path,
            model_name=model_name,
            prompt=full_prompt,
            temperature=temperature,
            max_output_tokens=max_output_tokens
        )

        if not api_response or not api_response.get("success"):
            error_details = api_response.get("error", {}) if api_response else {"message": "Empty response from API service"}
            logger.error(f"Gemini API call failed: {error_details}")
            return {"success": False, "error": {"code": "GEMINI_API_ERROR", "message": "AIサービス呼び出しに失敗しました", "details": error_details}}

        response_text = api_response.get("data", {}).get("text")

        if not response_text:
            return {"success": False, "error": {"code": "EMPTY_RESPONSE", "message": "AIからの応答テキストが空です。"}}

        json_string = extract_json_from_response(response_text)
        
        if not json_string:
            return {"success": False, "error": {"code": "JSON_EXTRACTION_FAILED", "message": "AIの応答からJSONを抽出できませんでした。", "response_preview": response_text[:500]}}

        try:
            json_data = json.loads(json_string)
            
            is_valid, errors = validate_generated_json(json_data)
            if is_valid:
                logger.info("JSON validation successful.")
                return {"success": True, "data": json_data}

            logger.warning(f"生成されたJSONの検証に失敗しました: {', '.join(errors)}. 修復を試みます。")
            
            repaired_json, repairs_made = repair_json_data(json_data, get_json_schema())
            
            # 修復後、再度バリデーション
            is_valid_after_repair, final_errors = validate_generated_json(repaired_json)
            
            if is_valid_after_repair:
                logger.info(f"JSONの修復に成功しました。実施した修復: {', '.join(repairs_made)}")
                return {"success": True, "data": repaired_json, "warnings": repairs_made}
            else:
                # 修復してもなお無効な場合はエラー
                error_message = f"JSONの修復後も検証に失敗しました: {', '.join(final_errors)}"
                logger.error(error_message)
                return {"success": False, "error": {"code": "REPAIR_VALIDATION_FAILED", "message": error_message, "repaired_json": repaired_json}}

        except json.JSONDecodeError as e:
            error_message = f"抽出された文字列のJSONパースに失敗しました: {e}"
            logger.error(error_message, exc_info=True)
            return {"success": False, "error": {"code": "JSON_DECODE_ERROR", "message": error_message, "invalid_json_string": json_string}}
    
    except Exception as e:
        error_message = f"JSON生成中に予期せぬエラーが発生しました: {e}"
        logger.critical(error_message, exc_info=True)
        return {"success": False, "error": {"code": "UNEXPECTED_ERROR", "message": str(e)}}


# ==============================================================================
# JSON検証
# ==============================================================================

def validate_generated_json_v1(json_data: Dict[str, Any]) -> Tuple[bool, Optional[str]]:
    """
    [旧バージョン - v1] 生成されたJSONがスキーマに準拠しているか検証する
    
    Args:
        json_data (Dict[str, Any]): AIによって生成されたJSONデータ
        
    Returns:
        Tuple[bool, Optional[str]]: 検証結果 (bool) とエラーメッセージ (str)
    """
    schema = get_json_schema()

    # 必須フィールドのチェック
    for required_field in schema.get("required", []):
        if required_field not in json_data:
            error_message = f"必須フィールド '{required_field}' が不足しています"
            logger.error(f"Validation failed: {error_message}")
            return False, error_message

    # すべてのチェックを通過
    logger.info("JSON validation successful.")
    return True, None


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