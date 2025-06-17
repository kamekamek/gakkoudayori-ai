"""
学級通信自動生成サービス

音声認識結果からGemini APIを使って学級通信を自動生成
"""

import os
import logging
import time
import json
from typing import Dict, Any, List, Optional
from datetime import datetime, timedelta
import re

# Google Generative AI関連
import google.generativeai as genai

# 設定
logger = logging.getLogger(__name__)

# Gemini設定
PROJECT_ID = "gakkoudayori-ai"
LOCATION = "us-central1"
MODEL_NAME = "gemini-2.5-flash-preview-05-20"

# プロンプトディレクトリを定数として定義
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
PROMPT_DIR = os.path.join(BASE_DIR, "prompts")

def load_newsletter_prompt(template_type: str) -> Optional[str]:
    """
    指定されたテンプレートタイプに対応するプロンプトファイルを読み込む
    
    Args:
        template_type (str): テンプレートタイプ (例: "daily_report", "weekly_summary", "modern_report")
        
    Returns:
        Optional[str]: 読み込んだプロンプトの文字列、見つからない場合はNone
    """
    # テンプレートタイプからプロンプトファイル名を決定
    if 'modern' in template_type.lower():
        prompt_filename = "MODERN_TENSAKU.md"
    else:
        # classic系やその他はCLASSIC_TENSAKU.mdを使用
        prompt_filename = "CLASSIC_TENSAKU.md"

    try:
        prompt_path = os.path.join(PROMPT_DIR, prompt_filename)
        
        if not os.path.exists(prompt_path):
            logger.error(f"Newsletter prompt file not found: {prompt_path}")
            # モダンプロンプトが見つからない場合はクラシックにフォールバック
            if 'modern' in template_type.lower():
                logger.warning(f"Modern newsletter prompt not found, falling back to classic")
                return load_newsletter_prompt('daily_report')  # classic系にフォールバック
            return None
            
        with open(prompt_path, "r", encoding="utf-8") as f:
            return f.read()
    except Exception as e:
        logger.error(f"Error loading newsletter prompt file {prompt_filename}: {e}")
        return None

def initialize_gemini_api(api_key: str = None) -> bool:
    """
    Gemini APIを初期化
    
    Args:
        api_key (str): Gemini API キー
        
    Returns:
        bool: 初期化成功可否
    """
    try:
        # API keyを環境変数から取得、またはパラメータから使用
        if api_key is None:
            api_key = os.getenv('GEMINI_API_KEY')
        
        if not api_key:
            logger.error("Gemini API key not found in environment variables")
            return False
        
        # Gemini API設定
        genai.configure(api_key=api_key)
        
        logger.info("Gemini API initialized successfully")
        return True
        
    except Exception as e:
        logger.error(f"Failed to initialize Gemini API: {e}")
        return False

def generate_newsletter_from_speech(
    speech_text: str,
    template_type: str = "daily_report",
    include_greeting: bool = True,
    target_audience: str = "parents",
    season: str = "auto",
    credentials_path: str = "../secrets/service-account-key.json"
) -> Dict[str, Any]:
    """
    音声認識結果から学級通信を生成
    
    Args:
        speech_text (str): 音声認識結果のテキスト
        template_type (str): テンプレートタイプ
        include_greeting (bool): 挨拶文を含めるか
        target_audience (str): 対象読者
        season (str): 季節（auto = 自動判定）
        credentials_path (str): 認証情報パス
        
    Returns:
        Dict[str, Any]: 生成結果
    """
    start_time = time.time()
    
    try:
        # Gemini API初期化
        if not initialize_gemini_api():
            return {
                'success': False,
                'error': 'Failed to initialize Gemini API',
                'processing_time_ms': int((time.time() - start_time) * 1000)
            }
        
        # 季節自動判定
        if season == "auto":
            season = _detect_season_from_text(speech_text)
        
        # プロンプト生成
        prompt = _create_newsletter_prompt(
            speech_text, template_type, include_greeting, target_audience, season
        )
        
        # Gemini APIで生成
        model = genai.GenerativeModel('gemini-2.5-flash-preview-05-20')
        
        # 生成設定
        generation_config = genai.types.GenerationConfig(
            max_output_tokens=8192,
            temperature=0.7,
            top_p=0.8,
        )
        
        # 安全設定
        safety_settings = [
            {
                "category": "HARM_CATEGORY_HARASSMENT",
                "threshold": "BLOCK_MEDIUM_AND_ABOVE",
            },
            {
                "category": "HARM_CATEGORY_HATE_SPEECH",
                "threshold": "BLOCK_MEDIUM_AND_ABOVE",
            },
            {
                "category": "HARM_CATEGORY_SEXUALLY_EXPLICIT",
                "threshold": "BLOCK_MEDIUM_AND_ABOVE",
            },
            {
                "category": "HARM_CATEGORY_DANGEROUS_CONTENT",
                "threshold": "BLOCK_MEDIUM_AND_ABOVE",
            },
        ]
        
        logger.info(f"Generating newsletter with Gemini API. Input length: {len(speech_text)}")
        
        response = model.generate_content(
            prompt,
            generation_config=generation_config,
            safety_settings=safety_settings
        )
        
        # レスポンス処理
        if response.text:
            newsletter_html = _clean_and_format_html(response.text)
            processing_time = time.time() - start_time
            
            result = {
                'success': True,
                'data': {
                    'newsletter_html': newsletter_html,
                    'original_speech': speech_text,
                    'template_type': template_type,
                    'season': season,
                    'processing_time_ms': int(processing_time * 1000),
                    'generated_at': datetime.now().isoformat(),
                    'word_count': len(newsletter_html.split()),
                    'character_count': len(newsletter_html)
                }
            }
            
            logger.info(f"Newsletter generation successful. Output length: {len(newsletter_html)}")
            return result
            
        else:
            return {
                'success': False,
                'error': 'No content generated by Gemini API',
                'processing_time_ms': int((time.time() - start_time) * 1000)
            }
        
    except Exception as e:
        error_msg = f"Newsletter generation failed: {str(e)}"
        logger.error(error_msg)
        return {
            'success': False,
            'error': error_msg,
            'processing_time_ms': int((time.time() - start_time) * 1000)
        }

def _detect_season_from_text(text: str) -> str:
    """
    テキストから季節を自動判定
    
    Args:
        text (str): 入力テキスト
        
    Returns:
        str: 季節 (spring, summer, autumn, winter, default)
    """
    # 現在の月による基本判定
    current_month = datetime.now().month
    
    if 3 <= current_month <= 5:
        base_season = "spring"
    elif 6 <= current_month <= 8:
        base_season = "summer"
    elif 9 <= current_month <= 11:
        base_season = "autumn"
    else:
        base_season = "winter"
    
    # テキスト内のキーワードによる調整
    text_lower = text.lower()
    
    spring_keywords = ["桜", "入学", "新学期", "春", "お花見", "暖かく", "芽吹く"]
    summer_keywords = ["運動会", "プール", "夏休み", "暑い", "七夕", "夏祭り"]
    autumn_keywords = ["紅葉", "学習発表会", "秋", "文化祭", "涼しく", "収穫"]
    winter_keywords = ["雪", "寒い", "冬", "クリスマス", "正月", "温かく"]
    
    keyword_scores = {
        "spring": sum(1 for kw in spring_keywords if kw in text),
        "summer": sum(1 for kw in summer_keywords if kw in text),
        "autumn": sum(1 for kw in autumn_keywords if kw in text),
        "winter": sum(1 for kw in winter_keywords if kw in text)
    }
    
    # 最高得点の季節があれば使用、なければ月ベースの季節
    max_score = max(keyword_scores.values())
    if max_score > 0:
        for season, score in keyword_scores.items():
            if score == max_score:
                return season
    
    return base_season

def _create_newsletter_prompt(
    speech_text: str,
    template_type: str,
    include_greeting: bool,
    target_audience: str,
    season: str
) -> str:
    """
    学級通信生成用プロンプトを作成
    
    Args:
        speech_text (str): 音声認識結果
        template_type (str): テンプレートタイプ
        include_greeting (bool): 挨拶文を含めるか
        target_audience (str): 対象読者
        season (str): 季節
        
    Returns:
        str: 生成されたプロンプト
    """
    
    # 外部プロンプトファイルを読み込み
    system_prompt_template = load_newsletter_prompt(template_type)
    if not system_prompt_template:
        # フォールバック: ハードコードされたプロンプト
        logger.warning(f"Using fallback hardcoded prompt for template_type: {template_type}")
        return _create_fallback_prompt(speech_text, template_type, include_greeting, target_audience, season)
    
    # 季節に応じた挨拶文テンプレート
    seasonal_greetings = {
        "spring": "桜の花が美しく咲く季節となりました。新学期も始まり、子どもたちは元気いっぱいです。",
        "summer": "暑い日が続いておりますが、子どもたちは元気に活動しています。",
        "autumn": "秋の深まりを感じる季節となりました。子どもたちも学習に集中して取り組んでいます。",
        "winter": "寒い日が続きますが、子どもたちは元気に過ごしています。",
        "default": "いつも子どもたちの教育にご理解ご協力をいただき、ありがとうございます。"
    }
    
    greeting = seasonal_greetings.get(season, seasonal_greetings["default"])
    
    # テンプレートタイプ別の指示
    template_instructions = {
        "daily_report": "今日の学校での出来事を中心とした日報形式",
        "weekly_summary": "一週間の活動をまとめた週報形式",
        "event_report": "特別な行事やイベントの報告形式",
        "modern_report": "モダンな学級通信形式",
        "general": "一般的な学級通信形式"
    }
    
    template_instruction = template_instructions.get(template_type, template_instructions["general"])
    
    # プロンプトに変数を埋め込む（format()の代わりにreplace()を使用）
    user_prompt = f"""
以下の音声認識結果をもとに学級通信を生成してください。

【音声認識結果】
{speech_text}

【生成パラメータ】
- テンプレート形式: {template_instruction}
- 対象読者: {target_audience}
- 季節: {season}
- 挨拶文含める: {include_greeting}
- 季節の挨拶: {greeting if include_greeting else "なし"}
"""
    
    # システムプロンプトとユーザープロンプトを結合
    full_prompt = f"{system_prompt_template}\n\n{user_prompt}"
    
    return full_prompt

def _create_fallback_prompt(
    speech_text: str,
    template_type: str,
    include_greeting: bool,
    target_audience: str,
    season: str
) -> str:
    """
    フォールバック用のハードコードされたプロンプトを生成
    """
    # 季節に応じた挨拶文テンプレート
    seasonal_greetings = {
        "spring": "桜の花が美しく咲く季節となりました。新学期も始まり、子どもたちは元気いっぱいです。",
        "summer": "暑い日が続いておりますが、子どもたちは元気に活動しています。",
        "autumn": "秋の深まりを感じる季節となりました。子どもたちも学習に集中して取り組んでいます。",
        "winter": "寒い日が続きますが、子どもたちは元気に過ごしています。",
        "default": "いつも子どもたちの教育にご理解ご協力をいただき、ありがとうございます。"
    }
    
    greeting = seasonal_greetings.get(season, seasonal_greetings["default"])
    
    # テンプレートタイプ別の指示
    template_instructions = {
        "daily_report": "今日の学校での出来事を中心とした日報形式",
        "weekly_summary": "一週間の活動をまとめた週報形式",
        "event_report": "特別な行事やイベントの報告形式",
        "general": "一般的な学級通信形式"
    }
    
    template_instruction = template_instructions.get(template_type, template_instructions["general"])
    
    # HTML制約
    html_constraints = """
以下のHTML制約を厳守してください：
- 見出しは <h1>, <h2>, <h3> タグのみ使用
- 段落は <p> タグで囲む
- リストは <ul>, <ol>, <li> タグを使用
- 強調は <strong>, <em> タグを使用
- 改行は <br> タグを使用
- 色指定、フォントサイズ指定は禁止
- スクリプトタグは禁止
- インラインスタイルは禁止
"""
    
    # メインプロンプト構築
    prompt = f"""
あなたは経験豊富な小学校教師です。以下の音声認識結果をもとに、保護者向けの学級通信を作成してください。

【音声認識結果】
{speech_text}

【作成指示】
- 形式: {template_instruction}
- 対象読者: {target_audience}
- 季節: {season}
- 挨拶文含める: {include_greeting}

【HTML制約】
{html_constraints}

【作成要件】
1. 温かみのある親しみやすい文体で書く
2. 子どもたちの活動や成長を具体的に伝える
3. 保護者への感謝の気持ちを込める
4. 適切な長さ（200-500文字程度）に調整
5. HTMLタグを使って読みやすくレイアウト

【重要な出力形式】
- HTMLコンテンツのみを出力してください
- Markdownコードブロック（```html や ``` など）は絶対に使用しないでください
- 説明文や前置きは一切不要です
- HTMLタグから直接開始し、HTMLタグで終了してください
- 「以下のHTML」「こちらが学級通信です」などの説明は不要です

【学級通信】
"""

    if include_greeting:
        prompt += f"\n{greeting}\n"
    
    return prompt

def _clean_and_format_html(html_content: str) -> str:
    """
    生成されたHTMLを清浄化・フォーマット
    
    Args:
        html_content (str): 生成されたHTMLコンテンツ
        
    Returns:
        str: 清浄化されたHTMLコンテンツ
    """
    # 不要な前後の説明文を削除
    content = html_content.strip()
    
    # 【重要】Markdownコードブロックの完全除去 - 強化版
    # 様々なパターンのMarkdownコードブロックを確実に削除
    patterns_to_remove = [
        r'```html\s*',              # ```html
        r'```HTML\s*',              # ```HTML
        r'```\s*html\s*',           # ``` html
        r'```\s*HTML\s*',           # ``` HTML
        r'```\s*',                  # 一般的なコードブロック開始
        r'\s*```',                  # コードブロック終了
        r'`html\s*',                # `html
        r'`HTML\s*',                # `HTML
        r'\s*`\s*$',                # 末尾の`
    ]
    
    for pattern in patterns_to_remove:
        content = re.sub(pattern, '', content, flags=re.IGNORECASE | re.MULTILINE)
    
    # HTMLの前後にある説明文も除去（より積極的に）
    content = re.sub(r'^[^<]*(?=<)', '', content)  # HTML開始前の説明文
    content = re.sub(r'>[^<]*$', '>', content)     # HTML終了後の説明文
    
    # 「【学級通信】」などの不要なテキストを削除
    content = re.sub(r'【[^】]*】', '', content)
    
    # よくある説明文パターンを削除
    explanation_patterns = [
        r'以下のHTML.*?です[。：]?\s*',
        r'HTML.*?を出力.*?[。：]?\s*',
        r'こちらが.*?HTML.*?[。：]?\s*',
        r'生成された.*?HTML.*?[。：]?\s*'
    ]
    
    for pattern in explanation_patterns:
        content = re.sub(pattern, '', content, flags=re.IGNORECASE)
    
    # 危険なタグを削除
    dangerous_tags = ['script', 'style', 'iframe', 'object', 'embed']
    for tag in dangerous_tags:
        content = re.sub(f'<{tag}[^>]*>.*?</{tag}>', '', content, flags=re.DOTALL | re.IGNORECASE)
        content = re.sub(f'<{tag}[^>]*/?>', '', content, flags=re.IGNORECASE)
    
    # インラインスタイルを削除
    content = re.sub(r'style="[^"]*"', '', content, flags=re.IGNORECASE)
    
    # 不適切な属性を削除
    content = re.sub(r'onclick="[^"]*"', '', content, flags=re.IGNORECASE)
    content = re.sub(r'onload="[^"]*"', '', content, flags=re.IGNORECASE)
    
    # 重複する空白・改行を削除
    content = re.sub(r'\n\s*\n', '\n', content)
    content = re.sub(r' +', ' ', content)
    
    # 最終的なクリーンアップ
    content = content.strip()
    
    # デバッグログ：クリーンアップ後のコンテンツをチェック
    if '```' in content:
        logger.warning(f"Markdown code block remnants still detected after enhanced cleanup: {content[:200]}...")
    
    return content

def get_newsletter_templates() -> List[Dict[str, Any]]:
    """
    利用可能な学級通信テンプレート一覧を取得
    
    Returns:
        List[Dict[str, Any]]: テンプレート情報
    """
    return [
        {
            'type': 'daily_report',
            'name': '日報形式',
            'description': '今日の学校での出来事を中心とした日報',
            'suitable_for': ['日常活動', '授業の様子', '休み時間の出来事']
        },
        {
            'type': 'weekly_summary',
            'name': '週報形式',
            'description': '一週間の活動をまとめた週報',
            'suitable_for': ['週末のまとめ', '複数日の活動', '週の振り返り']
        },
        {
            'type': 'event_report',
            'name': 'イベント報告',
            'description': '特別な行事やイベントの報告',
            'suitable_for': ['運動会', '学習発表会', '遠足', '特別授業']
        },
        {
            'type': 'general',
            'name': '一般形式',
            'description': '汎用的な学級通信形式',
            'suitable_for': ['お知らせ', '一般的な連絡', 'その他']
        }
    ]

def test_newsletter_generation(credentials_path: str = "../secrets/service-account-key.json") -> bool:
    """
    学級通信生成機能のテスト
    
    Args:
        credentials_path (str): 認証情報パス
        
    Returns:
        bool: テスト成功可否
    """
    print("=== 学級通信生成テスト ===")
    
    # テスト用音声テキスト
    test_speech = "今日は運動会の練習をしました。子どもたちは一生懸命頑張っていて、リレーの練習では転んでしまった子もいましたが、みんなで励まし合いながら取り組んでいました。本番が楽しみです。保護者の皆様もぜひ応援してください。"
    
    try:
        result = generate_newsletter_from_speech(
            speech_text=test_speech,
            template_type="daily_report",
            include_greeting=True,
            target_audience="parents",
            credentials_path=credentials_path
        )
        
        if result['success']:
            print("✅ 学級通信生成成功")
            print(f"処理時間: {result['data']['processing_time_ms']}ms")
            print(f"生成内容: {result['data']['newsletter_html'][:200]}...")
            print(f"文字数: {result['data']['character_count']}")
            return True
        else:
            print("❌ 学級通信生成失敗")
            print(f"エラー: {result['error']}")
            return False
            
    except Exception as e:
        print(f"❌ テストエラー: {e}")
        return False

if __name__ == '__main__':
    success = test_newsletter_generation()
    if success:
        print('\n🎉 学級通信自動生成機能 - テスト完了!')
    else:
        print('\n⚠️ 設定に問題があります。エラーを確認してください。') 