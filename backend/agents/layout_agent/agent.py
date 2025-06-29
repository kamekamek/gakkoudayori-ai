import json
import logging
import os
import re
from datetime import datetime
from typing import AsyncGenerator, Optional

from google.adk.agents import LlmAgent
from google.adk.agents.invocation_context import InvocationContext
from google.adk.events.event import Event
from google.adk.models.google_llm import Gemini
from google.genai.types import Content, Part

from .prompt import INSTRUCTION
from .deliver_html_tool import html_delivery_tool

# ロガーの設定
logger = logging.getLogger(__name__)


class SimpleLayoutAgent(LlmAgent):
    """
    シンプルなLayoutAgent。
    会話内容から直接HTMLを生成し、フロントエンドに配信します。
    """

    def __init__(self, output_key: str = "html"):
        model = Gemini(model_name="gemini-2.5-pro")
        logger.info("SimpleLayoutAgent初期化: モデル=gemini-2.5-pro")
        
        super().__init__(
            name="layout_agent",
            model=model,
            instruction=INSTRUCTION,
            description="会話内容から美しいHTMLレイアウトを生成し、フロントエンドに配信します。",
            tools=[html_delivery_tool.create_adk_function_tool()],
            output_key=output_key,
        )

    async def generate_html_from_conversation(self, ctx: InvocationContext) -> str:
        """会話内容から直接HTMLを生成するシンプルなメソッド"""
        try:
            logger.info("=== 会話内容から直接HTML生成開始 ===")
            
            # セッション状態から会話内容を取得
            conversation_content = ""
            if hasattr(ctx, "session") and hasattr(ctx.session, "state"):
                conversation_content = ctx.session.state.get("conversation_content", "")
            
            if not conversation_content:
                logger.warning("会話内容が見つかりません")
                return self._generate_default_html()
            
            logger.info(f"会話内容を取得: {len(conversation_content)} 文字")
            
            # 会話から基本情報を抽出
            basic_info = self._extract_basic_info_from_conversation(conversation_content)
            logger.info(f"基本情報抽出完了: {basic_info}")
            
            # シンプルなHTMLテンプレートを生成
            html_content = self._generate_simple_html_template(basic_info)
            
            logger.info(f"HTML生成完了: {len(html_content)} 文字")
            return html_content
            
        except Exception as e:
            logger.error(f"HTML生成エラー: {e}")
            return self._generate_default_html()

    def _extract_basic_info_from_conversation(self, conversation_text: str) -> dict:
        """会話テキストから基本情報を抽出"""
        basic_info = {
            'school_name': '○○小学校',
            'grade': '1年1組', 
            'teacher_name': '担任',
            'title': '学級通信',
            'content': self._clean_conversation_content(conversation_text),
            'date': datetime.now().strftime("%Y年%m月%d日")
        }
        
        # シンプルなパターンマッチング
        school_match = re.search(r'([あ-ん一-龯A-Za-z0-9]+(?:小学校|中学校|高校))', conversation_text)
        if school_match:
            basic_info['school_name'] = school_match.group(1)
            
        grade_match = re.search(r'([1-6]年[1-9]組)', conversation_text)
        if grade_match:
            basic_info['grade'] = grade_match.group(1)
            
        teacher_match = re.search(r'([あ-ん一-龯]+)先生', conversation_text)
        if teacher_match:
            basic_info['teacher_name'] = teacher_match.group(1)
            
        # タイトルを会話から推測
        if '運動会' in conversation_text:
            basic_info['title'] = '運動会の様子'
        elif '遠足' in conversation_text:
            basic_info['title'] = '遠足について'
        elif '発表会' in conversation_text:
            basic_info['title'] = '発表会のお知らせ'
        else:
            basic_info['title'] = '学級の様子'
            
        return basic_info

    def _clean_conversation_content(self, conversation_text: str) -> str:
        """会話内容をクリーンアップして学級通信に適した内容に変換"""
        # 不要な文字列を除去
        content = conversation_text.replace('音声認識中...', '')
        content = content.replace('エージェント', '')
        content = content.replace('システム', '')
        
        # 長すぎる場合は適切な長さにカット
        if len(content) > 800:
            content = content[:800] + '...'
            
        # 改行を適切に処理
        sentences = content.split('。')
        cleaned_sentences = []
        for sentence in sentences:
            sentence = sentence.strip()
            if sentence and len(sentence) > 10:  # 短すぎる文は除外
                cleaned_sentences.append(sentence + '。')
                
        return ' '.join(cleaned_sentences[:5])  # 最大5文まで

    def _generate_simple_html_template(self, basic_info: dict) -> str:
        """基本情報からシンプルなHTMLテンプレートを生成"""
        html_template = f'''<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{basic_info['school_name']} {basic_info['grade']} 学級通信</title>
    <style>
        body {{
            font-family: 'Hiragino Sans', 'Yu Gothic', sans-serif;
            margin: 0;
            padding: 20px;
            background-color: #f8f9fa;
            color: #333;
            line-height: 1.8;
        }}
        .container {{
            max-width: 800px;
            margin: 0 auto;
            background: white;
            border-radius: 15px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.1);
            overflow: hidden;
        }}
        .header {{
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 40px;
            text-align: center;
            position: relative;
        }}
        .header::before {{
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: url('data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><circle cx="10" cy="10" r="1" fill="rgba(255,255,255,0.1)"/><circle cx="30" cy="25" r="1.5" fill="rgba(255,255,255,0.1)"/><circle cx="60" cy="15" r="1" fill="rgba(255,255,255,0.1)"/><circle cx="80" cy="30" r="1.5" fill="rgba(255,255,255,0.1)"/></svg>');
        }}
        .header h1 {{
            margin: 0;
            font-size: 32px;
            font-weight: bold;
            position: relative;
            z-index: 1;
        }}
        .header p {{
            margin: 15px 0 0 0;
            font-size: 18px;
            opacity: 0.9;
            position: relative;
            z-index: 1;
        }}
        .content {{
            padding: 50px;
        }}
        .content h2 {{
            color: #667eea;
            border-left: 5px solid #667eea;
            padding-left: 20px;
            margin-bottom: 30px;
            font-size: 24px;
        }}
        .content p {{
            margin-bottom: 20px;
            text-align: justify;
            font-size: 16px;
        }}
        .highlight {{
            background: linear-gradient(transparent 60%, #667eea20 60%);
            padding: 2px 0;
        }}
        .footer {{
            background-color: #f8f9fa;
            padding: 30px;
            text-align: center;
            color: #666;
            border-top: 1px solid #e9ecef;
        }}
        @media print {{
            body {{ margin: 0; background: white; }}
            .container {{ box-shadow: none; }}
        }}
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>{basic_info['school_name']} {basic_info['grade']}</h1>
            <p>学級通信 - {basic_info['date']}</p>
            <p>発行者: {basic_info['teacher_name']}</p>
        </div>
        <div class="content">
            <h2><span class="highlight">{basic_info['title']}</span></h2>
            <p>{basic_info['content']}</p>
            
            <p>いつも子どもたちを温かく見守っていただき、ありがとうございます。学級での様子をお伝えします。</p>
        </div>
        <div class="footer">
            <p>{basic_info['school_name']} {basic_info['grade']} 担任: {basic_info['teacher_name']}</p>
        </div>
    </div>
</body>
</html>'''
        return html_template

    def _generate_default_html(self) -> str:
        """デフォルトのHTMLを生成"""
        default_info = {
            'school_name': '学校名',
            'grade': '学年',
            'teacher_name': '担任',
            'title': '学級通信',
            'content': 'いつも温かくご支援いただき、ありがとうございます。',
            'date': datetime.now().strftime("%Y年%m月%d日")
        }
        return self._generate_simple_html_template(default_info)

    async def _run_async_impl(
        self, ctx: InvocationContext
    ) -> AsyncGenerator[Event, None]:
        """シンプルな実行ロジック"""
        try:
            # ユーザーフレンドリーなメッセージ
            yield Event(
                author=self.name,
                content=Content(parts=[Part(text="学級通信のレイアウトを作成しています...")])
            )
            
            # 会話内容から直接HTML生成
            html_content = await self.generate_html_from_conversation(ctx)
            
            if html_content:
                # セッション状態にHTMLを保存
                if hasattr(ctx, "session") and hasattr(ctx.session, "state"):
                    ctx.session.state["html"] = html_content
                    ctx.session.state["html_generated"] = True
                    ctx.session.state["html_generation_timestamp"] = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
                    
                    logger.info("✅ HTML生成完了 - セッション状態に保存")
                
                # 成功メッセージ
                yield Event(
                    author=self.name,
                    content=Content(parts=[Part(text="✅ 学級通信のHTMLを生成しました！")])
                )
                
                # HTML配信ツールを自動実行
                session_id = self._extract_session_id(ctx)
                if session_id:
                    html_delivery_tool.set_session_id(session_id)
                    try:
                        metadata_json = json.dumps({"auto_generated": True, "agent": "simple_layout_agent"})
                        delivery_result = await html_delivery_tool.deliver_html_to_frontend(
                            html_content=html_content,
                            artifact_type="newsletter",
                            metadata_json=metadata_json
                        )
                        
                        yield Event(
                            author=self.name,
                            content=Content(parts=[Part(text=delivery_result)])
                        )
                        
                    except Exception as tool_error:
                        logger.error(f"HTML配信ツールエラー: {tool_error}")
            else:
                yield Event(
                    author=self.name,
                    content=Content(parts=[Part(text="❌ HTML生成に失敗しました。")])
                )

        except Exception as e:
            logger.error(f"レイアウト生成エラー: {str(e)}")
            yield Event(
                author=self.name, 
                content=Content(parts=[Part(text="レイアウト作成中に問題が発生しました。")])
            )

    def _extract_session_id(self, ctx: InvocationContext) -> Optional[str]:
        """InvocationContextからセッションIDを抽出"""
        try:
            # ADKセッションからセッションIDを取得
            if hasattr(ctx, "session") and hasattr(ctx.session, "session_id"):
                session_id = ctx.session.session_id
                logger.info(f"セッションID抽出成功: {session_id}")
                return session_id
            
            # 代替手段: セッション情報から推測
            if hasattr(ctx, "session") and hasattr(ctx.session, "user_id"):
                user_id = ctx.session.user_id
                session_id = f"{user_id}:default"
                logger.warning(f"セッションIDをuser_idから推測: {session_id}")
                return session_id
                
            logger.error("セッションIDの抽出に失敗")
            return None
            
        except Exception as e:
            logger.error(f"セッションID抽出エラー: {e}")
            return None


def create_simple_layout_agent() -> SimpleLayoutAgent:
    """SimpleLayoutAgentのインスタンスを生成するファクトリ関数。"""
    return SimpleLayoutAgent(output_key="html")


# ADK Web UI用のroot_agent変数
root_agent = create_simple_layout_agent()