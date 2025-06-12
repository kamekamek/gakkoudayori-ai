"""
HTML制約プロンプトサービス

T3-AI-003-H: HTML制約プロンプト実装
- HTML制約プロンプト設計
- Gemini API連携実装
- HTML生成テスト
- 品質チェック（タグ、構造）
"""

import logging
from typing import Dict, Any, List, Optional, Tuple
from bs4 import BeautifulSoup # BeautifulSoup4をインポート

# Gemini APIサービスを利用
from gemini_api_service import generate_text, get_gemini_client

# ロギング設定
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# 許可するHTMLタグのリスト (例)
ALLOWED_TAGS = ['h1', 'h2', 'h3', 'p', 'ul', 'ol', 'li', 'strong', 'em', 'br']

# デフォルトで禁止するHTML属性のリスト
# AIプロンプト仕様書 Section 2.2 に基づく + 一般的なイベントハンドラ
DEFAULT_FORBIDDEN_ATTRIBUTES = [
    'class', 'id', 'style', 
    'onclick', 'onload', 'onerror', 'onmouseover', 'onmouseout', 
    'onfocus', 'onblur', 'onsubmit', 'onchange', 'onkeydown', 'onkeyup', 'onkeypress'
]

import time
from datetime import datetime

def generate_constrained_html(
    prompt: str,
    project_id: str,
    credentials_path: str,
    custom_instruction: str = "",
    season_theme: str = "",
    document_type: str = "class_newsletter",
    constraints: Dict[str, Any] = None,
    model_name: str = "gemini-1.5-pro",
    temperature: float = 0.2,
    max_output_tokens: int = 1024,
    top_k: int = 40,
    top_p: float = 0.8,
    location: str = "asia-northeast1"
) -> Dict[str, Any]:
    """
    指定された制約に基づいてHTMLコンテンツを生成します。

    Args:
        prompt (str): 生成の元となるテキストプロンプト (例: 音声認識結果)
        project_id (str): Google CloudプロジェクトID
        credentials_path (str): サービスアカウントキーファイルのパス
        custom_instruction (str, optional): ユーザーからの追加指示
        season_theme (str, optional): 季節のテーマ
        document_type (str, optional): ドキュメントタイプ (例: class_newsletter)
        constraints (Dict[str, Any], optional): HTML生成の制約 (例: 許可タグ、最大単語数)
        model_name (str, optional): 使用するGeminiモデル名
        temperature (float, optional): 生成の温度パラメータ
        max_output_tokens (int, optional): 最大出力トークン数
        top_k (int, optional): トップKサンプリング
        top_p (float, optional): トップPサンプリング
        location (str, optional): APIリージョン

    Returns:
        Dict[str, Any]: 生成されたHTMLコンテンツまたはエラー情報 (API仕様書準拠)
    """
    start_time = time.time()
    current_timestamp = datetime.now().isoformat()
    logger.info(f"Generating HTML with constraints for prompt: {prompt[:50]}...")

    # 制約のデフォルト値とマージ
    current_constraints = constraints if constraints is not None else {}
    final_allowed_tags = current_constraints.get("allowed_tags", ALLOWED_TAGS)
    # forbidden_tags はプロンプトで直接指定するより、後処理でフィルタリングする方が確実かもしれない
    # final_forbidden_tags = current_constraints.get("forbidden_tags", ["script", "style", "div"])

    # --- プロンプトエンジニアリング (BLUEフェーズ品質改善) ---
    # AIが制約をより遵守しやすくなるよう、プロンプトを構造化し、Few-shot learningを取り入れる。
    
    # 1. 禁止属性リストをプロンプト用に準備
    forbidden_attributes_list_str = ", ".join(current_constraints.get("forbidden_attributes", DEFAULT_FORBIDDEN_ATTRIBUTES))

    # 2. Few-shot learningのための良い例を定義
    good_example_prompt = "運動会のお知らせ\n10月5日に運動会があります。みんなで頑張りましょう！"
    good_example_output = "<h1>運動会のお知らせ</h1><p>10月5日に運動会があります。<strong>みんなで頑張りましょう！</strong></p>"

    # 3. 構造化されたプロンプトの構築
    system_prompt_parts = [
        "あなたは、厳格なルールに従ってHTMLを生成する専門家です。",
        "以下のルールを絶対に守り、与えられたテキストからHTMLコンテンツを生成してください。",
        "",
        "## ルール",
        "1. **許可されたタグのみ使用**: 指定されたHTMLタグ以外は絶対に使用しないでください。",
        "2. **禁止された属性は使用しない**: 指定された属性は絶対に使用しないでください。",
        "3. **構造**: `<html>`や`<body>`タグは含めず、コンテンツ本体のみを生成してください。",
        "4. **忠実性**: 元のテキストの内容を忠実に反映し、マークアップのみを行ってください。",
        "",
        "## 制約",
        f"### 許可するHTMLタグ\n- `{', '.join(final_allowed_tags)}`",
        f"### 禁止するHTML属性\n- `{forbidden_attributes_list_str}`",
        "",
        "## 良い例 (この形式に従ってください)",
        f"### 入力テキスト:\n```\n{good_example_prompt}\n```",
        f"### 出力HTML:\n```html\n{good_example_output}\n```",
        ""
    ]
    
    # ドキュメントタイプやテーマに応じた指示を追加
    context_instructions = []
    if document_type == "class_newsletter":
        context_instructions.append("これは学校の学級通信用のコンテンツです。保護者向けに、丁寧で分かりやすい言葉遣いを心がけてください。")
    if season_theme:
        context_instructions.append(f"季節のテーマ「{season_theme}」を意識した内容にしてください。")
    if custom_instruction:
        context_instructions.append(f"追加の指示: {custom_instruction}")

    if context_instructions:
        system_prompt_parts.extend(["## 追加コンテキスト", *context_instructions, ""])

    # 最終的なプロンプトの組み立て
    system_prompt = "\n".join(system_prompt_parts)
    final_prompt = f"{system_prompt}\n---\n## あなたのタスク\n### 入力テキスト:\n```\n{prompt}\n```\n### 出力HTML:"

    logger.debug(f"Final prompt for HTML generation: {final_prompt}")

    try:
        # Gemini APIサービスを利用してテキスト生成
        # 注意: gemini_api_service.generate_text は get_gemini_client を内部で呼び出すため、
        # ここで直接 get_gemini_client を呼び出す必要はない。
        api_response = generate_text(
            project_id=project_id,
            credentials_path=credentials_path,
            prompt=final_prompt,
            model_name=model_name,
            temperature=temperature,
            max_output_tokens=max_output_tokens,
            top_k=top_k,
            top_p=top_p,
            location=location
        )

        if not api_response.get("success"): # gemini_api_serviceからのエラーをそのまま返す
            # API仕様書に準拠したエラー形式になっているはず
            logger.error(f"Gemini API call failed: {api_response.get('error')}")
            # processing_time_ms をこのレベルでも計算・上書きするか検討
            api_response["error"]["details"] = api_response.get("error",{}).get("details",{})
            api_response["error"]["details"]["processing_time_ms_html_service"] = int((time.time() - start_time) * 1000)
            api_response["timestamp"] = current_timestamp
            return api_response

        generated_html_content = api_response.get("data", {}).get("text", "")
        ai_metadata = api_response.get("data", {}).get("ai_metadata", {})

        # BLUEフェーズ: _validate_and_filter_html を使用してHTMLを検証・フィルタリング
        filtered_html_content, validation_issues = _validate_and_filter_html(
            html_content=generated_html_content,
            allowed_tags=final_allowed_tags,
            forbidden_tags=current_constraints.get("forbidden_tags"),
            forbidden_attributes=current_constraints.get("forbidden_attributes")
        )

        if validation_issues:
            for issue in validation_issues:
                logger.warning(f"HTML Validation/Filtering Issue: {issue}")
            
            return {
                "success": False,
                "error": {
                    "code": "HTML_VALIDATION_FILTERING_ERROR",
                    "message": "生成されたHTMLに制約違反があり、フィルタリング処理が実行されました。またはパースエラーが発生しました。",
                    "details": {
                        "original_html_preview": generated_html_content[:200] + "..." if len(generated_html_content) > 200 else generated_html_content,
                        "filtered_html_preview": filtered_html_content[:200] + "..." if len(filtered_html_content) > 200 else filtered_html_content,
                        "validation_issues": validation_issues,
                        "allowed_tags": final_allowed_tags,
                        "forbidden_tags_applied": current_constraints.get("forbidden_tags"),
                        "forbidden_attributes_applied": current_constraints.get("forbidden_attributes", DEFAULT_FORBIDDEN_ATTRIBUTES),
                        "processing_time_ms": int((time.time() - start_time) * 1000),
                        "timestamp": current_timestamp
                    }
                }
            }

        final_html_to_return = filtered_html_content

        # API仕様書に準拠した成功レスポンス
        return {
            "success": True,
            "data": {
                "html_content": final_html_to_return,
                "source_prompt": prompt, # 元のプロンプトも返す
                "ai_metadata": ai_metadata, # Geminiサービスからのメタデータをそのまま含める
                "constraints_applied": {
                    "allowed_tags": final_allowed_tags,
                    # "forbidden_tags": final_forbidden_tags, # 必要であれば
                    "document_type": document_type,
                    "season_theme": season_theme
                },
                "processing_time_ms": int((time.time() - start_time) * 1000),
            },
            "timestamp": current_timestamp
        }

    except Exception as e:
        logger.exception("Error during HTML generation process in html_constraint_service")
        # gemini_api_service.handle_gemini_error を流用するか、独自の詳細エラーを定義
        # ここでは汎用的なエラーとして返す
        return {
            "success": False,
            "error": {
                "code": "INTERNAL_SERVICE_ERROR",
                "message": f"HTML生成処理中に予期せぬエラーが発生しました: {str(e)}",
                "details": {
                    "error_type": type(e).__name__,
                    "processing_time_ms": int((time.time() - start_time) * 1000),
                    "timestamp": current_timestamp
                }
            }
        }

def _validate_and_filter_html(
    html_content: str,
    allowed_tags: List[str],
    forbidden_tags: Optional[List[str]] = None,
    forbidden_attributes: Optional[List[str]] = None
) -> Tuple[str, List[str]]:
    """
    生成されたHTMLを検証し、制約に基づいてフィルタリングします。
    不正なタグや属性は削除され、その操作が記録されます。

    Args:
        html_content (str): 検証・フィルタリングするHTML文字列。
        allowed_tags (List[str]): 許可されるHTMLタグのリスト。
        forbidden_tags (Optional[List[str]], optional): 禁止されるHTMLタグのリスト。
        forbidden_attributes (Optional[List[str]], optional): 禁止されるHTML属性のリスト。
                                                             Defaults to DEFAULT_FORBIDDEN_ATTRIBUTES.

    Returns:
        Tuple[str, List[str]]: フィルタリング後のHTML文字列と、検出された問題/実行されたフィルタリング操作のリスト。
    """
    issues_found = []
    if not html_content.strip():
        return "", issues_found # 空のコンテンツは空のHTMLと空のissueリストを返す

    if forbidden_tags is None:
        forbidden_tags = []
    if forbidden_attributes is None:
        forbidden_attributes = DEFAULT_FORBIDDEN_ATTRIBUTES

    try:
        soup = BeautifulSoup(html_content, 'html.parser')
    except Exception as e:
        error_msg = f"HTML parsing failed: {e}. Content: {html_content[:100]}..."
        logger.warning(error_msg)
        issues_found.append(f"PARSE_ERROR: {error_msg}")
        return "", issues_found # パースエラー時は空のHTMLとエラーメッセージ

    for tag in soup.find_all(True): # Trueは全てのタグを取得
        tag_name = tag.name.lower()
        original_tag_repr = str(tag)[:100] # 変更前のタグの表現（ログ用）

        # 1. 禁止タグのチェック -> 削除
        if tag_name in forbidden_tags:
            issue = f"FORBIDDEN_TAG_REMOVED: Tag '<{tag_name}>' was found and removed. Original: {original_tag_repr}"
            logger.warning(issue)
            issues_found.append(issue)
            tag.decompose() # タグとその内容を削除
            continue # このタグは処理済み

        # 2. 許可タグリストに含まれているかチェック -> 削除
        if tag_name not in allowed_tags:
            issue = f"DISALLOWED_TAG_REMOVED: Tag '<{tag_name}>' (not in allowed_list) was found and removed. Original: {original_tag_repr}"
            logger.warning(issue)
            issues_found.append(issue)
            tag.decompose() # タグとその内容を削除
            continue # このタグは処理済み

        # 3. 属性のチェック -> 削除
        current_attributes_keys = list(tag.attrs.keys()) # イテレーション中に変更するためキーのリストを作成
        for attr_name_original in current_attributes_keys:
            attr_name_lower = attr_name_original.lower()
            if attr_name_lower in forbidden_attributes:
                issue = f"FORBIDDEN_ATTRIBUTE_REMOVED: Attribute '{attr_name_original}' in tag '<{tag_name}>' was found and removed."
                logger.warning(issue)
                issues_found.append(issue)
                del tag[attr_name_original] # 属性を削除

    if soup.body:
        filtered_html_content = soup.body.decode_contents()
    elif soup.html:
        filtered_html_content = soup.html.decode_contents()
    else:
        filtered_html_content = str(soup)
        
    return filtered_html_content.strip(), issues_found

