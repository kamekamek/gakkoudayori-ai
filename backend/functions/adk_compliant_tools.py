"""
ADK準拠ツール関数定義

Google ADK公式仕様に完全準拠したツール関数群
- 辞書返却必須
- デフォルト値禁止
- 完全なdocstring
- 統一されたエラーハンドリング
"""

import logging
import json
import time
from typing import Dict, Any, List, Optional
from datetime import datetime

# 既存サービス
from gemini_api_service import generate_text

logger = logging.getLogger(__name__)


# ==============================================================================
# ADK準拠ツール関数（Google公式仕様準拠）
# ==============================================================================

def generate_newsletter_content(
    audio_transcript: str,
    grade_level: str,
    content_type: str
) -> dict:
    """学級通信の文章を生成するツール
    
    音声認識結果から教師らしい温かい語り口調の学級通信文章を生成します。
    保護者向けの親しみやすい内容を800-1200文字程度で作成します。
    学年に応じた適切な表現と具体的なエピソードを重視します。
    
    Args:
        audio_transcript: 音声認識結果のテキスト。空文字列不可。
        grade_level: 対象学年（例：3年1組、4年2組）
        content_type: コンテンツタイプ（newsletter固定値）
        
    Returns:
        生成結果を含む辞書：
        - status (str): 'success' | 'error'
        - content (str): 生成された文章（成功時のみ）
        - word_count (int): 生成された文字数（成功時のみ）
        - grade_level (str): 処理対象学年（成功時のみ）
        - processing_time_ms (int): 処理時間（成功時のみ）
        - error_message (str): エラーの詳細説明（失敗時のみ）
        - error_code (str): エラー分類コード（失敗時のみ）
    """
    start_time = time.time()
    
    try:
        # 入力検証
        if not audio_transcript.strip():
            return {
                "status": "error",
                "error_message": "音声認識結果が空文字列です",
                "error_code": "EMPTY_TRANSCRIPT",
                "processing_time_ms": int((time.time() - start_time) * 1000)
            }
        
        if not grade_level.strip():
            return {
                "status": "error",
                "error_message": "学年情報が指定されていません",
                "error_code": "EMPTY_GRADE_LEVEL",
                "processing_time_ms": int((time.time() - start_time) * 1000)
            }
        
        # プロンプト構築
        prompt = f"""
        あなたは{grade_level}の担任教師です。
        以下の音声内容を基に学級通信を作成してください：
        
        音声内容: {audio_transcript}
        
        制約：
        - 保護者向けの温かい語り口調
        - 具体的なエピソード重視
        - 800-1200文字程度
        - 子供たちの成長を中心とした内容
        - 個人名は仮名を使用
        """
        
        # Gemini API呼び出し
        response = generate_text(
            prompt=prompt,
            project_id="your-project-id",
            credentials_path="path/to/credentials.json",
            model_name="gemini-2.5-pro-preview-06-05",
            temperature=0.3,
            max_output_tokens=2048
        )
        
        if response and response.get("success"):
            content = response.get("data", {}).get("text", "")
            
            if not content.strip():
                return {
                    "status": "error",
                    "error_message": "生成されたコンテンツが空です",
                    "error_code": "EMPTY_GENERATED_CONTENT",
                    "processing_time_ms": int((time.time() - start_time) * 1000)
                }
            
            processing_time = int((time.time() - start_time) * 1000)
            
            return {
                "status": "success",
                "content": content,
                "word_count": len(content),
                "grade_level": grade_level,
                "content_type": content_type,
                "processing_time_ms": processing_time
            }
        else:
            error_details = response.get("error", {}) if response else {"message": "API応答なし"}
            return {
                "status": "error",
                "error_message": f"Gemini API呼び出しに失敗しました: {error_details}",
                "error_code": "API_CALL_FAILED",
                "processing_time_ms": int((time.time() - start_time) * 1000)
            }
            
    except Exception as e:
        logger.error(f"Newsletter content generation failed: {e}", exc_info=True)
        return {
            "status": "error",
            "error_message": f"文章生成中に予期せぬエラーが発生しました: {str(e)}",
            "error_code": "PROCESSING_ERROR",
            "processing_time_ms": int((time.time() - start_time) * 1000)
        }


def generate_design_specification(
    content: str,
    theme: str,
    grade_level: str
) -> dict:
    """デザイン仕様をJSON形式で生成するツール
    
    学級通信の内容に基づいて、季節感のあるデザイン仕様を生成します。
    カラースキーム、レイアウト構成、視覚的要素を含む完全な設計仕様を
    JSON形式で提供し、後続のHTML生成に活用されます。
    
    Args:
        content: 学級通信の文章内容。空文字列不可。
        theme: デザインテーマ（seasonal, modern, classic等）
        grade_level: 対象学年（デザイン調整に使用）
        
    Returns:
        デザイン仕様を含む辞書：
        - status (str): 'success' | 'error'
        - design_spec (dict): 完全なデザイン仕様（成功時のみ）
        - season (str): 判定された季節（成功時のみ）
        - theme (str): 適用されたテーマ（成功時のみ）
        - processing_time_ms (int): 処理時間（成功時のみ）
        - error_message (str): エラーの詳細説明（失敗時のみ）
        - error_code (str): エラー分類コード（失敗時のみ）
    """
    start_time = time.time()
    
    try:
        # 入力検証
        if not content.strip():
            return {
                "status": "error",
                "error_message": "デザイン対象のコンテンツが空です",
                "error_code": "EMPTY_CONTENT",
                "processing_time_ms": int((time.time() - start_time) * 1000)
            }
        
        # 季節判定
        current_month = datetime.now().month
        season_map = {
            (3, 4, 5): "spring",
            (6, 7, 8): "summer", 
            (9, 10, 11): "autumn",
            (12, 1, 2): "winter"
        }
        
        current_season = "spring"
        for months, season in season_map.items():
            if current_month in months:
                current_season = season
                break
        
        # カラースキーム定義
        color_schemes = {
            "spring": {"primary": "#4CAF50", "secondary": "#81C784", "accent": "#FFC107", "background": "#FFFFFF"},
            "summer": {"primary": "#2196F3", "secondary": "#64B5F6", "accent": "#FF9800", "background": "#FFFFFF"},
            "autumn": {"primary": "#FF7043", "secondary": "#FFAB91", "accent": "#8BC34A", "background": "#FFFFFF"},
            "winter": {"primary": "#9C27B0", "secondary": "#BA68C8", "accent": "#00BCD4", "background": "#FFFFFF"}
        }
        
        # デザイン仕様構築
        design_spec = {
            "layout_type": "modern",
            "color_scheme": color_schemes.get(current_season, color_schemes["spring"]),
            "fonts": {
                "heading": "Noto Sans JP",
                "body": "Hiragino Sans"
            },
            "layout_sections": [
                {
                    "type": "header",
                    "position": "top",
                    "content_type": "title"
                },
                {
                    "type": "main_content", 
                    "position": "center",
                    "content_type": "body_text",
                    "columns": 1
                }
            ],
            "visual_elements": {
                "photo_placeholders": 2,
                "illustration_style": current_season,
                "border_style": "rounded"
            },
            "responsive_breakpoints": {
                "mobile": "768px",
                "tablet": "1024px",
                "desktop": "1200px"
            }
        }
        
        # テーマ別調整
        if theme == "classic":
            design_spec["fonts"]["heading"] = "serif"
            design_spec["visual_elements"]["border_style"] = "traditional"
        elif theme == "modern":
            design_spec["layout_sections"][1]["columns"] = 2
            design_spec["visual_elements"]["border_style"] = "minimal"
        
        processing_time = int((time.time() - start_time) * 1000)
        
        return {
            "status": "success",
            "design_spec": design_spec,
            "season": current_season,
            "theme": theme,
            "grade_level": grade_level,
            "processing_time_ms": processing_time
        }
        
    except Exception as e:
        logger.error(f"Design specification generation failed: {e}", exc_info=True)
        return {
            "status": "error",
            "error_message": f"デザイン仕様生成中に予期せぬエラーが発生しました: {str(e)}",
            "error_code": "PROCESSING_ERROR",
            "processing_time_ms": int((time.time() - start_time) * 1000)
        }


def generate_html_newsletter(
    content: str,
    design_spec: dict,
    template_type: str
) -> dict:
    """HTMLニュースレターを生成するツール
    
    文章内容とデザイン仕様に基づいて、厳格な制約に準拠したHTMLを生成します。
    指定されたHTMLタグのみを使用し、アクセシブルで印刷適応性の高い
    マークアップを作成します。
    
    Args:
        content: 学級通信の文章内容。空文字列不可。
        design_spec: デザイン仕様辞書。必須キーを含む必要あり。
        template_type: テンプレートタイプ（newsletter, announcement等）
        
    Returns:
        HTML生成結果を含む辞書：
        - status (str): 'success' | 'error'
        - html (str): 生成されたHTML文字列（成功時のみ）
        - char_count (int): HTML文字数（成功時のみ）
        - template_type (str): 使用されたテンプレート（成功時のみ）
        - validation_passed (bool): HTML制約チェック結果（成功時のみ）
        - processing_time_ms (int): 処理時間（成功時のみ）
        - error_message (str): エラーの詳細説明（失敗時のみ）
        - error_code (str): エラー分類コード（失敗時のみ）
    """
    start_time = time.time()
    
    try:
        # 入力検証
        if not content.strip():
            return {
                "status": "error",
                "error_message": "HTML生成対象のコンテンツが空です",
                "error_code": "EMPTY_CONTENT",
                "processing_time_ms": int((time.time() - start_time) * 1000)
            }
        
        if not isinstance(design_spec, dict):
            return {
                "status": "error",
                "error_message": "デザイン仕様が正しい辞書形式ではありません",
                "error_code": "INVALID_DESIGN_SPEC",
                "processing_time_ms": int((time.time() - start_time) * 1000)
            }
        
        if not design_spec:
            return {
                "status": "error",
                "error_message": "デザイン仕様が空の辞書です",
                "error_code": "EMPTY_DESIGN_SPEC",
                "processing_time_ms": int((time.time() - start_time) * 1000)
            }
        
        # 必須キーの確認
        required_keys = ["color_scheme", "fonts"]
        missing_keys = [key for key in required_keys if key not in design_spec]
        if missing_keys:
            return {
                "status": "error",
                "error_message": f"デザイン仕様に必須キーが不足: {missing_keys}",
                "error_code": "MISSING_DESIGN_KEYS",
                "processing_time_ms": int((time.time() - start_time) * 1000)
            }
        
        # プロンプト構築
        prompt = f"""
        以下の内容とデザイン仕様に基づいて、学級通信用のHTMLを生成してください：
        
        内容: {content}
        デザイン仕様: {json.dumps(design_spec, ensure_ascii=False, indent=2)}
        
        制約：
        - 使用タグ: <h1>〜<h3>, <p>, <ul>/<ol>/<li>, <strong>, <em>, <br>のみ
        - style/class/div タグ禁止（inline styleのみ許可）
        - <html>タグ不要、本文のみ出力
        - 画像プレースホルダーは [写真: 説明] 形式
        - 日本語対応フォント指定
        
        出力形式例:
        <h1 style="color: {design_spec.get('color_scheme', {}).get('primary', '#4CAF50')}; font-family: '{design_spec.get('fonts', {}).get('heading', 'Noto Sans JP')}';">学級通信タイトル</h1>
        <p style="font-family: '{design_spec.get('fonts', {}).get('body', 'Hiragino Sans')}';">内容...</p>
        """
        
        # Gemini API呼び出し
        response = generate_text(
            prompt=prompt,
            project_id="your-project-id", 
            credentials_path="path/to/credentials.json",
            model_name="gemini-2.5-pro-preview-06-05",
            temperature=0.2,
            max_output_tokens=4096
        )
        
        if response and response.get("success"):
            html = response.get("data", {}).get("text", "")
            
            if not html.strip():
                return {
                    "status": "error",
                    "error_message": "生成されたHTMLが空です",
                    "error_code": "EMPTY_GENERATED_HTML",
                    "processing_time_ms": int((time.time() - start_time) * 1000)
                }
            
            # HTML制約チェック
            validation_passed = validate_html_constraints(html)
            
            processing_time = int((time.time() - start_time) * 1000)
            
            return {
                "status": "success",
                "html": html,
                "char_count": len(html),
                "template_type": template_type,
                "validation_passed": validation_passed,
                "processing_time_ms": processing_time
            }
        else:
            error_details = response.get("error", {}) if response else {"message": "API応答なし"}
            return {
                "status": "error",
                "error_message": f"HTML生成API呼び出しに失敗しました: {error_details}",
                "error_code": "API_CALL_FAILED",
                "processing_time_ms": int((time.time() - start_time) * 1000)
            }
            
    except Exception as e:
        logger.error(f"HTML generation failed: {e}", exc_info=True)
        return {
            "status": "error",
            "error_message": f"HTML生成中に予期せぬエラーが発生しました: {str(e)}",
            "error_code": "PROCESSING_ERROR",
            "processing_time_ms": int((time.time() - start_time) * 1000)
        }


def modify_html_content(
    current_html: str,
    modification_request: str
) -> dict:
    """HTML修正を実行するツール
    
    既存のHTMLコンテンツに対して修正要求を適用します。
    元の構造とスタイル制約を保持しながら、必要な変更のみを実施し、
    変更履歴も記録します。
    
    Args:
        current_html: 修正対象の現在のHTML内容。空文字列不可。
        modification_request: 修正要求の詳細説明
        
    Returns:
        修正結果を含む辞書：
        - status (str): 'success' | 'error'
        - modified_html (str): 修正後のHTML（成功時のみ）
        - changes_made (str): 実施した変更の説明（成功時のみ）
        - original_length (int): 元HTML文字数（成功時のみ）
        - modified_length (int): 修正後HTML文字数（成功時のみ）
        - modification_type (str): 修正タイプ分類（成功時のみ）
        - processing_time_ms (int): 処理時間（成功時のみ）
        - error_message (str): エラーの詳細説明（失敗時のみ）
        - error_code (str): エラー分類コード（失敗時のみ）
    """
    start_time = time.time()
    
    try:
        # 入力検証
        if not current_html.strip():
            return {
                "status": "error",
                "error_message": "修正対象のHTMLが空です",
                "error_code": "EMPTY_HTML",
                "processing_time_ms": int((time.time() - start_time) * 1000)
            }
        
        if not modification_request.strip():
            return {
                "status": "error",
                "error_message": "修正要求が指定されていません",
                "error_code": "EMPTY_MODIFICATION_REQUEST",
                "processing_time_ms": int((time.time() - start_time) * 1000)
            }
        
        # 修正タイプの判定
        modification_type = classify_modification_type(modification_request)
        
        # プロンプト構築
        prompt = f"""
        以下のHTMLを修正してください：
        
        現在のHTML:
        {current_html}
        
        修正要求: {modification_request}
        
        制約：
        - 既存の構造を保持
        - 使用タグ制限を遵守（h1-h3, p, ul/ol/li, strong, em, br のみ）
        - インラインスタイルのみ使用
        - 修正部分のみを変更し、不要な変更は行わない
        """
        
        # Gemini API呼び出し
        response = generate_text(
            prompt=prompt,
            project_id="your-project-id",
            credentials_path="path/to/credentials.json",
            model_name="gemini-2.5-pro-preview-06-05",
            temperature=0.1,
            max_output_tokens=4096
        )
        
        if response and response.get("success"):
            modified_html = response.get("data", {}).get("text", current_html)
            
            # 変更点の分析
            changes_made = analyze_html_changes(current_html, modified_html)
            
            processing_time = int((time.time() - start_time) * 1000)
            
            return {
                "status": "success",
                "modified_html": modified_html,
                "changes_made": changes_made,
                "original_length": len(current_html),
                "modified_length": len(modified_html),
                "modification_type": modification_type,
                "processing_time_ms": processing_time
            }
        else:
            error_details = response.get("error", {}) if response else {"message": "API応答なし"}
            return {
                "status": "error",
                "error_message": f"HTML修正API呼び出しに失敗しました: {error_details}",
                "error_code": "API_CALL_FAILED",
                "processing_time_ms": int((time.time() - start_time) * 1000)
            }
            
    except Exception as e:
        logger.error(f"HTML modification failed: {e}", exc_info=True)
        return {
            "status": "error",
            "error_message": f"HTML修正中に予期せぬエラーが発生しました: {str(e)}",
            "error_code": "PROCESSING_ERROR",
            "processing_time_ms": int((time.time() - start_time) * 1000)
        }


def validate_newsletter_quality(
    html_content: str,
    original_content: str
) -> dict:
    """学級通信の品質を検証するツール
    
    生成された学級通信の内容適切性、技術的正確性、教育的価値を
    多角的に評価します。数値化されたスコアと具体的な改善提案を
    含む包括的な品質レポートを作成します。
    
    Args:
        html_content: 検証対象のHTML内容。空文字列不可。
        original_content: 元の文章内容。比較分析に使用。
        
    Returns:
        品質検証結果を含む辞書：
        - status (str): 'success' | 'error'
        - quality_score (int): 総合品質スコア 0-100（成功時のみ）
        - assessment (str): 全体評価カテゴリ（成功時のみ）
        - category_scores (dict): カテゴリ別スコア（成功時のみ）
        - suggestions (list): 改善提案リスト（成功時のみ）
        - content_analysis (dict): 内容分析結果（成功時のみ）
        - processing_time_ms (int): 処理時間（成功時のみ）
        - error_message (str): エラーの詳細説明（失敗時のみ）
        - error_code (str): エラー分類コード（失敗時のみ）
    """
    start_time = time.time()
    
    try:
        # 入力検証
        if not html_content.strip() or not original_content.strip():
            return {
                "status": "error",
                "error_message": "検証対象のコンテンツが不足しています",
                "error_code": "INSUFFICIENT_CONTENT",
                "processing_time_ms": int((time.time() - start_time) * 1000)
            }
        
        # 基本的な品質評価
        quality_scores = {}
        suggestions = []
        
        # 1. 教育的価値 (25%)
        educational_score = evaluate_educational_value(original_content)
        quality_scores["educational_value"] = educational_score
        
        if educational_score < 70:
            suggestions.append("教育的エピソードをより具体的に記述してください")
        
        # 2. 読みやすさ (25%)
        readability_score = evaluate_readability(original_content)
        quality_scores["readability"] = readability_score
        
        if readability_score < 70:
            suggestions.append("文章をより読みやすく構成してください")
        
        # 3. 技術的正確性 (25%)
        technical_score = evaluate_html_technical_quality(html_content)
        quality_scores["technical_accuracy"] = technical_score
        
        if technical_score < 70:
            suggestions.append("HTML構造を改善してください")
        
        # 4. 保護者への配慮 (25%)
        parent_consideration_score = evaluate_parent_consideration(original_content)
        quality_scores["parent_consideration"] = parent_consideration_score
        
        if parent_consideration_score < 70:
            suggestions.append("保護者の関心により配慮した内容にしてください")
        
        # 総合スコア計算
        total_score = sum(quality_scores.values()) // len(quality_scores)
        
        # 評価カテゴリ決定
        if total_score >= 90:
            assessment = "excellent"
        elif total_score >= 80:
            assessment = "good"
        elif total_score >= 70:
            assessment = "acceptable"
        else:
            assessment = "needs_improvement"
        
        # 内容分析
        content_analysis = {
            "word_count": len(original_content),
            "html_length": len(html_content),
            "structure_elements": count_html_elements(html_content),
            "readability_metrics": calculate_readability_metrics(original_content)
        }
        
        processing_time = int((time.time() - start_time) * 1000)
        
        return {
            "status": "success",
            "quality_score": total_score,
            "assessment": assessment,
            "category_scores": quality_scores,
            "suggestions": suggestions,
            "content_analysis": content_analysis,
            "processing_time_ms": processing_time
        }
        
    except Exception as e:
        logger.error(f"Quality validation failed: {e}", exc_info=True)
        return {
            "status": "error",
            "error_message": f"品質検証中に予期せぬエラーが発生しました: {str(e)}",
            "error_code": "PROCESSING_ERROR",
            "processing_time_ms": int((time.time() - start_time) * 1000)
        }


# ==============================================================================
# ヘルパー関数
# ==============================================================================

def validate_html_constraints(html: str) -> bool:
    """HTML制約の検証"""
    try:
        # 禁止タグのチェック
        forbidden_tags = ["<div", "<class=", "<id=", "<style>", "<script>"]
        for tag in forbidden_tags:
            if tag.lower() in html.lower():
                return False
        
        # 許可タグのみかチェック
        allowed_tags = ["<h1", "<h2", "<h3", "<p", "<ul", "<ol", "<li", "<strong", "<em", "<br"]
        # 簡易チェック（実際にはより厳密なパーサーが必要）
        
        return True
        
    except Exception:
        return False


def classify_modification_type(request: str) -> str:
    """修正要求の分類"""
    request_lower = request.lower()
    
    if any(word in request_lower for word in ["色", "カラー", "color"]):
        return "style_modification"
    elif any(word in request_lower for word in ["追加", "挿入", "add"]):
        return "content_addition"
    elif any(word in request_lower for word in ["削除", "除去", "remove"]):
        return "content_removal"
    elif any(word in request_lower for word in ["修正", "変更", "modify"]):
        return "content_modification"
    else:
        return "general_modification"


def analyze_html_changes(original: str, modified: str) -> str:
    """HTML変更点の分析"""
    if len(modified) > len(original):
        return f"コンテンツが追加されました（{len(modified) - len(original)}文字増加）"
    elif len(modified) < len(original):
        return f"コンテンツが削除されました（{len(original) - len(modified)}文字減少）"
    else:
        return "コンテンツが修正されました（文字数変化なし）"


def evaluate_educational_value(content: str) -> int:
    """教育的価値の評価"""
    score = 50  # ベーススコア
    
    # キーワード評価
    educational_keywords = ["成長", "学習", "頑張", "協力", "挑戦", "発見"]
    for keyword in educational_keywords:
        if keyword in content:
            score += 8
    
    # 具体性評価
    if len(content) > 500:
        score += 10
    
    return min(score, 100)


def evaluate_readability(content: str) -> int:
    """読みやすさの評価"""
    score = 50
    
    # 文の長さ評価
    sentences = content.split("。")
    avg_sentence_length = sum(len(s) for s in sentences) / len(sentences) if sentences else 0
    
    if 20 <= avg_sentence_length <= 50:
        score += 20
    
    # 段落構成評価
    if content.count("\n") > 2:
        score += 15
    
    return min(score, 100)


def evaluate_html_technical_quality(html: str) -> int:
    """HTML技術的品質の評価"""
    score = 50
    
    # 構造評価
    if "<h1" in html:
        score += 15
    if "<p" in html:
        score += 10
    
    # 制約準拠評価
    if validate_html_constraints(html):
        score += 25
    
    return min(score, 100)


def evaluate_parent_consideration(content: str) -> int:
    """保護者への配慮評価"""
    score = 50
    
    # 語調評価
    positive_words = ["嬉しい", "素晴らしい", "頑張", "成長", "楽しい"]
    for word in positive_words:
        if word in content:
            score += 10
    
    return min(score, 100)


def count_html_elements(html: str) -> dict:
    """HTML要素の数をカウント"""
    import re
    
    elements = {}
    tags = ["h1", "h2", "h3", "p", "ul", "ol", "li", "strong", "em", "br"]
    
    for tag in tags:
        pattern = f"<{tag}[^>]*>"
        matches = re.findall(pattern, html, re.IGNORECASE)
        elements[tag] = len(matches)
    
    return elements


def calculate_readability_metrics(content: str) -> dict:
    """読みやすさメトリクスの計算"""
    sentences = [s.strip() for s in content.split("。") if s.strip()]
    words = len(content)
    
    return {
        "sentence_count": len(sentences),
        "word_count": words,
        "avg_sentence_length": words / len(sentences) if sentences else 0,
        "complexity_score": min(100, (words / len(sentences)) * 2) if sentences else 0
    }


# ==============================================================================
# テスト機能
# ==============================================================================

def test_adk_compliant_tools():
    """ADK準拠ツール関数のテスト"""
    
    print("=== ADK準拠ツール関数テスト開始 ===")
    
    # テスト1: コンテンツ生成
    print("\n1. コンテンツ生成テスト")
    content_result = generate_newsletter_content(
        "今日は運動会の練習をしました。子どもたちは頑張っていました。",
        "3年1組",
        "newsletter"
    )
    print(f"結果: {content_result['status']}")
    if content_result['status'] == 'success':
        print(f"文字数: {content_result['word_count']}")
    
    # テスト2: デザイン仕様生成
    print("\n2. デザイン仕様生成テスト")
    design_result = generate_design_specification(
        "テスト用コンテンツ",
        "seasonal",
        "3年1組"
    )
    print(f"結果: {design_result['status']}")
    if design_result['status'] == 'success':
        print(f"季節: {design_result['season']}")
    
    # テスト3: HTML生成
    print("\n3. HTML生成テスト")
    if design_result['status'] == 'success':
        html_result = generate_html_newsletter(
            "テスト用コンテンツ",
            design_result['design_spec'],
            "newsletter"
        )
        print(f"結果: {html_result['status']}")
        if html_result['status'] == 'success':
            print(f"HTML文字数: {html_result['char_count']}")
    
    # テスト4: 品質検証
    print("\n4. 品質検証テスト")
    if 'html_result' in locals() and html_result['status'] == 'success':
        quality_result = validate_newsletter_quality(
            html_result['html'],
            "テスト用コンテンツ"
        )
        print(f"結果: {quality_result['status']}")
        if quality_result['status'] == 'success':
            print(f"品質スコア: {quality_result['quality_score']}/100")
    
    print("\n=== ADK準拠ツール関数テスト完了 ===")


if __name__ == "__main__":
    test_adk_compliant_tools()