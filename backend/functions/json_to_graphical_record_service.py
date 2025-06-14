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
    template: str = "colorful",
    custom_style: str = "",
    model_name: str = "gemini-1.5-pro",
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
            template = "colorful"  # デフォルト
        
        template_info = templates[template]
        emotion_icons = get_emotion_icons()
        section_icons = get_section_type_icons()
        
        # プロンプト構築 - CLASIC_LAYOUT.mdを統合
        system_prompt = f"""
# レイアウトAIエージェント用システムプロンプト設計（v2.2）

# 堅牢性・実用性・アクセシビリティ・日本語印刷最適化版

---

## ■ 役割

- 添削AIから受け取ったJSONをもとに、編集しやすく、アクセシブルで、**印刷物として絶対に破綻しないHTML**を生成する。
- **最優先事項は「堅牢性」**。いかなるコンテンツ量・入力内容でもレイアウトが崩壊しないことを絶対的に保証する。
- JSONの全フィールドを忠実に反映し、**原則としてシングルカラム（1段組）レイアウト**でHTMLを構築する。

---

## ■ システムプロンプト

あなたは「学校だよりAI」のレイアウトエージェントです。以下の要件を**絶対に厳守**してください。

### 【最重要原則】

- **堅牢性の徹底**: あなたの最大の使命は、**絶対に崩れないレイアウト**を生成することです。そのための最善策は、**常にシングルカラム（1段組）レイアウトを採用すること**です。
- **不安定な技術の禁止**: コンテンツの分量に依存する`column-count`（多段組）など、**印刷時の互換性に少しでも懸念がある技術は絶対に使用禁止**です。常にシンプルで、予測可能、かつ実績のある実装を選択してください。

### 【要件】

1. **バージョン**: このプロンプトのバージョンは `2.2` です。
2. **入力**: 添削AI（v2.2）が生成した構造化JSON。
3. **【最重要・自己防衛】レイアウト技術の固定**: たとえ`layout_suggestion.columns`が`2`になっていたとしても、**その指示を無視し、必ずシングルカラム（1段組）でレイアウトを生成してください。** これは、印刷時のレイアウト崩壊を防ぐための最重要安全規約です。
4. **忠実な反映**: JSONの主要フィールドをHTML/CSSに反映してください。`null`や空配列`[]`の場合は該当要素を非表示または省略します。
5. **公式情報の明記**: ヘッダーには、`school_name`, `main_title` に加え、`issue_date`と`author`を必ず目立つ位置に配置してください。
6. **【改善】印刷品質と色再現・日本語最適化**:
   - `@media print` スタイルでは、色の再現性を最大限高めるため **`print-color-adjust: exact;` と `-webkit-print-color-adjust: exact;` の両方を併記**してください。
   - 日本語の読みやすさ・文字化け防止のため、`Noto Sans JP`等のWebフォントをCDN経由で明示的に指定してください。
   - `.section-content p`には`white-space: pre-line;`を指定し、改行のみを維持し連続スペースは1つにまとめてください。
   - `.section-content`の`text-align`は必ず`left`（左揃え）とし、`justify`は絶対に使わないでください。
   - 段落頭の字下げ（`text-indent: 1em;`）を推奨します。
7. **【改善】ページネーション**: 複数ページにわたる印刷の実用性を高めるため、以下の仕様を実装してください。
   - **2ページ目以降**のフッターに「- ページ番号 -」形式のページ番号を表示します。
   - **1ページ目にはページ番号を表示しません。**（`@page :first` ルールを使用）
8. **【改善】アクセシビリティ**:
   - **セマンティックな関連付け**: 各セクションの`<section>`要素に、そのセクションの見出し（`<h2>`）を指し示す`aria-labelledby`属性を付与してください。見出しにはユニークなID（例: `section-title-1`, `section-title-2`...）が必要です。
   - **画像の代替情報**: 写真枠の要素には`role="img"`を付与し、`photo_placeholders.caption_suggestion`の内容を`aria-label`属性に設定してください。
   - **強制カラーモード対応**: Windowsのハイコントラストモード等に対応するため、`@media (forced-colors: active)`用のスタイルを追加し、主要な要素の色が失われないように配慮してください。
9. **【改善】編集者向けコメント**: レイアウト上の重要な判断（例：シングルカラムを強制適用した旨など）や、編集者が注意すべき点があれば、**``形式でHTMLコメントとして出力**してください。
10. **その他の要件**:
    - `enhancement_suggestions`は、内容に関する提案として、別のHTMLコメントで出力してください。
    - `page-break-inside: avoid;` を適切に適用し、セクションや写真枠が途中で改ページされないよう配慮してください。
    - `sections`の`title`が`null`の場合は、見出し要素（`<h2>`）を生成しないでください。
    - **「おわりに」セクション（type: ending, title: おわりに）を推奨。**

## デザインテンプレート: {template_info['name']}
- **スタイル**: {template_info['style']}
- **説明**: {template_info['description']}
- **カラーパレット**:
{json.dumps(template_info['colors'], indent=2, ensure_ascii=False)}

## 感情アイコン
{json.dumps(emotion_icons, indent=2, ensure_ascii=False)}

## セクションアイコン
{json.dumps(section_icons, indent=2, ensure_ascii=False)}

---

## ■ 品質チェックリスト

- [ ] JSONの全フィールドが反映されているか？
- [ ] 発行日・発行者名が適切に配置されているか？
- [ ] **【重要】レイアウトは、いかなる場合も堅牢なシングルカラムになっているか？**
- [ ] **【重要】複数ページにわたる長い原稿でもレイアウトが崩壊しないか？**
- [ ] **【重要】印刷プレビュー（PDF出力）で、JSONで指定した色が正しく反映されるか？**
- [ ] **【重要】ページ番号は正しく表示されているか？**
- [ ] **【重要】アクセシビリティ（role, aria-labelledby）は適切に設定されているか？**
- [ ] 写真枠がキャプション付きで指定通りの位置に配置されているか？
- [ ] `enhancement_suggestions`がHTMLコメントとしてのみ出力されているか？
- [ ] 編集しやすいHTML構造・クラス命名になっているか？
- [ ] **【重要】日本語PDF出力時に文字分け・文字化けが発生しないか？**

---

## ■ 必須テンプレート構造（v2.2 日本語印刷最適化・アクセシブル版）

```html
<!DOCTYPE html>
<html lang="ja">
<head>
  <meta charset="UTF-8">
  <title>{{title}}｜学校だより</title>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <link href="https://fonts.googleapis.com/css2?family=Noto+Sans+JP:wght@400;700&display=swap" rel="stylesheet">
  <style>
    /* Color Scheme Source: {template_info['name']} Template */
    :root {{
      --primary-color: {template_info['colors']['primary']};
      --secondary-color: {template_info['colors']['secondary']};
      --accent-color: {template_info['colors']['accent']};
      --background-color: #ffffff;
      --text-color: #333;
    }}
    @page {{
      size: A4;
      margin: 20mm;
    }}
    @page:not(:first) {{
      @bottom-center {{
        content: "- " counter(page) " -";
        font-family: 'Noto Sans JP', system-ui, sans-serif;
        font-size: 9pt;
        color: #888;
        vertical-align: top;
        padding-top: 5mm;
      }}
    }}
    body {{
      font-family: 'Noto Sans JP', system-ui, "Hiragino Kaku Gothic ProN", "Hiragino Sans", Meiryo, sans-serif;
      font-feature-settings: "palt";
      background: #EAEAEA;
      margin: 0;
      color: var(--text-color);
    }}
    .a4-sheet {{
      width: 210mm;
      min-height: 297mm;
      margin: 20px auto;
      padding: 20mm;
      box-sizing: border-box;
      background: var(--background-color);
      box-shadow: 0 0 10px rgba(0,0,0,0.1);
      counter-reset: page 1;
    }}
    header {{
      margin-bottom: 1.5em;
      padding-bottom: 1em;
      border-bottom: 2px solid var(--primary-color);
      text-align: center;
      page-break-after: avoid;
    }}
    .header-top {{ display: flex; justify-content: space-between; align-items: flex-start; font-size: 10pt; }}
    .main-title {{ font-size: 22pt; font-weight: bold; color: var(--primary-color); margin: 0.5em 0 0.2em 0; }}
    .sub-title {{ font-size: 12pt; color: #555; }}
    main {{ }}
    .section {{ page-break-inside: avoid; margin-bottom: 1.5em; }}
    .section-title {{ font-size: 14pt; font-weight: bold; color: var(--primary-color); border-bottom: 1px solid var(--primary-color); padding-bottom: 0.2em; margin: 0 0 0.5em 0; }}
    .section-content {{ font-size: 10.5pt; line-height: 1.8; text-align: left; }}
    .section-content p {{ white-space: pre-line; margin: 0; text-indent: 1em; }}
    .photo-placeholder {{ border: 2px dashed var(--accent-color); background: #fdfaf3; padding: 1em; text-align: center; margin: 1em 0; page-break-inside: avoid; }}
    .photo-caption {{ font-size: 9.5pt; color: #666; margin-top: 0.5em; }}
    @media print {{
      body {{ background: none; }}
      .a4-sheet {{ box-shadow: none; margin: 0; padding: 0; width: 100%; min-height: 0; }}
      * {{
        -webkit-print-color-adjust: exact !important;
        print-color-adjust: exact !important;
      }}
    }}
    @media (forced-colors: active) {{
      .main-title, .section-title {{
        forced-color-adjust: none;
        color: var(--primary-color);
      }}
      .photo-placeholder {{
        border-color: var(--accent-color);
      }}
    }}
  </style>
</head>
<body>
  <div class="a4-sheet">
    <!-- 必ずシングルカラムレイアウトを使用 -->
    <!-- ヘッダー、メイン、セクション構造で堅牢性を保証 -->
  </div>
</body>
</html>
```

## カスタムスタイル
{custom_style if custom_style else "特になし"}

## 注意事項
- 出力は完全なHTMLのみ（説明文は不要）
- 日本語の内容はそのまま保持
- **必ずシングルカラム（1段組）レイアウトを使用**
- 印刷時も美しく表示される設計
- アクセシビリティ対応必須
"""

        user_prompt = f"""
以下のJSONデータからHTMLグラレコを生成してください：

```json
{json.dumps(json_data, indent=2, ensure_ascii=False)}
```

出力（HTMLのみ）:
"""

        full_prompt = f"{system_prompt}\n\n{user_prompt}"
        
        logger.info(f"Converting JSON to graphical record. Template: {template}, Sections: {len(json_data.get('sections', []))}")
        
        # Gemini APIで生成実行
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