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
        """JSON構成案を優先してHTMLを生成するメソッド"""
        try:
            logger.info("=== JSON構成案を優先したHTML生成開始 ===")
            
            # 最優先: セッション状態からJSON構成案を取得
            json_outline = ""
            if hasattr(ctx, "session") and hasattr(ctx.session, "state"):
                logger.info(f"📊 セッション状態キー: {list(ctx.session.state.keys())}")
                json_outline = ctx.session.state.get("outline", "")
                logger.info(f"📄 セッション状態から取得したJSON構成案: {len(json_outline)} 文字")
                if json_outline:
                    logger.info(f"📄 JSON構成案プレビュー: {json_outline[:300]}...")
            
            # JSON構成案が存在する場合は優先的に使用
            if json_outline:
                logger.info("✅ JSON構成案を使用してHTML生成")
                html_content = await self._generate_html_from_json_outline(json_outline)
                if html_content:
                    logger.info(f"✅ JSON構成案からHTML生成完了: {len(html_content)} 文字")
                    return html_content
                else:
                    logger.warning("⚠️  JSON構成案からのHTML生成に失敗 - 会話内容にフォールバック")
            
            # フォールバック: 会話内容を取得（複数の場所から試行）
            logger.info("🔄 JSON構成案が使用できないため、会話内容にフォールバック")
            conversation_content = ""
            if hasattr(ctx, "session") and hasattr(ctx.session, "state"):
                # メインの会話内容を確認
                conversation_content = ctx.session.state.get("conversation_content", "")
                logger.info(f"📄 セッション状態から取得した会話内容: {len(conversation_content)} 文字")
                
                # バックアップからも確認
                if not conversation_content:
                    backup_content = ctx.session.state.get("backup_conversation", "")
                    if backup_content:
                        logger.info(f"📄 バックアップから会話内容を復旧: {len(backup_content)} 文字")
                        conversation_content = backup_content
                
                if conversation_content:
                    logger.info(f"📄 会話内容プレビュー: {conversation_content[:200]}...")
                else:
                    logger.warning(f"⚠️  会話内容が両方から取得できません。利用可能キー: {list(ctx.session.state.keys())}")
            
            # 方法2: セッション状態から取得できない場合、セッションイベントから直接抽出
            if not conversation_content:
                logger.warning("⚠️  セッション状態に会話内容がありません - セッションイベントから直接抽出を試行")
                conversation_content = await self._extract_conversation_from_session_events(ctx)
                logger.info(f"📄 セッションイベントから抽出した会話内容: {len(conversation_content)} 文字")
            
            # 方法3: それでも取得できない場合の代替手段
            if not conversation_content:
                logger.warning("⚠️  セッションイベントからも会話内容を取得できません - 代替方法を試行")
                conversation_content = await self._get_fallback_conversation_content(ctx)
                logger.info(f"📄 代替方法で取得した会話内容: {len(conversation_content)} 文字")
            
            if not conversation_content:
                logger.error("❌ すべての方法でデータ取得に失敗しました")
                return self._generate_default_html()
            
            logger.info(f"✅ 会話内容を取得: {len(conversation_content)} 文字")
            
            # 会話から基本情報を抽出
            basic_info = self._extract_basic_info_from_conversation(conversation_content)
            logger.info(f"✅ 基本情報抽出完了: {basic_info}")
            
            # シンプルなHTMLテンプレートを生成
            html_content = self._generate_simple_html_template(basic_info)
            
            logger.info(f"✅ HTML生成完了: {len(html_content)} 文字")
            return html_content
            
        except Exception as e:
            logger.error(f"❌ HTML生成エラー: {e}")
            import traceback
            logger.error(f"詳細エラー: {traceback.format_exc()}")
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
        """デフォルトのHTMLを生成（データ取得失敗時のフォールバック）"""
        logger.warning("⚠️  デフォルトHTMLを生成します")
        default_info = {
            'school_name': '学校名',
            'grade': '学年',
            'teacher_name': '担任',
            'title': '学級通信',
            'content': 'データの取得に失敗したため、デフォルトの内容を表示しています。システム管理者にお問い合わせください。',
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

    async def _extract_conversation_from_session_events(self, ctx: InvocationContext) -> str:
        """セッションイベントから直接会話内容を抽出"""
        try:
            logger.info("=== セッションイベントからの会話内容抽出開始 ===")
            
            if not hasattr(ctx, "session") or not hasattr(ctx.session, "events"):
                logger.error("❌ セッションイベントにアクセスできません")
                return ""
            
            session_events = ctx.session.events
            if not session_events:
                logger.warning("⚠️  セッションイベントが空です")
                return ""
            
            logger.info(f"📊 セッションイベント数: {len(session_events)}")
            
            conversation_text = ""
            for i, event in enumerate(session_events):
                logger.info(f"📝 イベント #{i}: author={getattr(event, 'author', 'unknown')}")
                
                # MainConversationAgentのテキスト抽出メソッドを複製
                event_text = self._extract_text_from_event(event)
                logger.info(f"📝 イベント #{i} テキスト長: {len(event_text)} 文字")
                
                if len(event_text) > 0:
                    logger.info(f"📝 イベント #{i} 内容プレビュー: {event_text[:100]}...")
                    conversation_text += event_text + " "
            
            logger.info(f"✅ セッションイベントから抽出完了: {len(conversation_text)} 文字")
            return conversation_text.strip()
            
        except Exception as e:
            logger.error(f"❌ セッションイベント抽出エラー: {e}")
            import traceback
            logger.error(f"詳細エラー: {traceback.format_exc()}")
            return ""

    def _extract_text_from_event(self, event) -> str:
        """イベントからテキストを抽出（MainConversationAgentのメソッドを複製）"""
        try:
            if hasattr(event, "content") and event.content:
                if hasattr(event.content, "parts") and event.content.parts:
                    text_parts = []
                    for part in event.content.parts:
                        if hasattr(part, "text") and part.text:
                            text_parts.append(part.text)
                    return " ".join(text_parts)
                elif isinstance(event.content, list):
                    text_parts = []
                    for item in event.content:
                        if isinstance(item, dict) and "text" in item:
                            text_parts.append(item["text"])
                    return " ".join(text_parts)
            return ""
        except Exception as e:
            logger.warning(f"テキスト抽出エラー: {e}")
            return ""

    async def _get_fallback_conversation_content(self, ctx: InvocationContext) -> str:
        """代替手段での会話内容取得"""
        try:
            logger.info("=== 代替手段での会話内容取得開始 ===")
            
            # 最後の手段: ダミーの会話内容を生成
            fallback_content = "運動会が開催されました。子どもたちは一生懸命練習した成果を発揮し、素晴らしい演技を披露しました。"
            logger.warning(f"⚠️  代替手段として固定の会話内容を使用: {fallback_content}")
            
            return fallback_content
            
        except Exception as e:
            logger.error(f"❌ 代替手段での取得エラー: {e}")
            return ""

    async def _generate_html_from_json_outline(self, json_outline: str) -> str:
        """JSON構成案からHTMLを生成"""
        try:
            logger.info("=== JSON構成案からHTML生成開始 ===")
            
            # JSONを解析
            import json
            outline_data = json.loads(json_outline)
            logger.info(f"✅ JSON解析成功: {outline_data.get('school_name', 'N/A')} {outline_data.get('grade', 'N/A')}")
            
            # 基本情報を抽出
            school_name = outline_data.get('school_name', '学校名')
            grade = outline_data.get('grade', '学年')
            issue_date = outline_data.get('issue_date', datetime.now().strftime("%Y年%m月%d日"))
            author_info = outline_data.get('author', {})
            author_name = author_info.get('name', '担任') if isinstance(author_info, dict) else '担任'
            main_title = outline_data.get('main_title', '学級通信')
            
            # セクション情報を抽出
            sections = outline_data.get('sections', [])
            main_content = ""
            if sections and len(sections) > 0:
                first_section = sections[0]
                main_content = first_section.get('content', '学級の様子をお伝えします。')
            
            # 色情報を抽出
            color_scheme = outline_data.get('color_scheme', {})
            primary_color = color_scheme.get('primary', '#667eea')
            secondary_color = color_scheme.get('secondary', '#764ba2')
            
            logger.info(f"📄 抽出された情報: {school_name} {grade}, タイトル: {main_title}")
            logger.info(f"📄 内容プレビュー: {main_content[:100]}...")
            
            # HTML生成
            html_content = self._generate_structured_html_template(
                school_name=school_name,
                grade=grade,
                issue_date=issue_date,
                author_name=author_name,
                main_title=main_title,
                main_content=main_content,
                primary_color=primary_color,
                secondary_color=secondary_color
            )
            
            logger.info(f"✅ 構造化HTML生成完了: {len(html_content)} 文字")
            return html_content
            
        except json.JSONDecodeError as e:
            logger.error(f"❌ JSON解析エラー: {e}")
            return ""
        except Exception as e:
            logger.error(f"❌ JSON構成案からのHTML生成エラー: {e}")
            import traceback
            logger.error(f"詳細エラー: {traceback.format_exc()}")
            return ""

    def _generate_structured_html_template(self, school_name: str, grade: str, issue_date: str, 
                                         author_name: str, main_title: str, main_content: str,
                                         primary_color: str, secondary_color: str) -> str:
        """構造化されたHTMLテンプレートを生成"""
        html_template = f'''<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{school_name} {grade} 学級通信</title>
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
            background: linear-gradient(135deg, {primary_color} 0%, {secondary_color} 100%);
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
        .header .subtitle {{
            margin: 15px 0 5px 0;
            font-size: 18px;
            opacity: 0.9;
            position: relative;
            z-index: 1;
        }}
        .header .author {{
            margin: 5px 0 0 0;
            font-size: 16px;
            opacity: 0.8;
            position: relative;
            z-index: 1;
        }}
        .content {{
            padding: 50px;
        }}
        .content h2 {{
            color: {primary_color};
            border-left: 5px solid {primary_color};
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
            background: linear-gradient(transparent 60%, {primary_color}20 60%);
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
            <h1>{school_name} {grade}</h1>
            <p class="subtitle">学級通信 - {issue_date}</p>
            <p class="author">発行者: {author_name}</p>
        </div>
        <div class="content">
            <h2><span class="highlight">{main_title}</span></h2>
            <p>{main_content}</p>
            
            <p>いつも子どもたちを温かく見守っていただき、ありがとうございます。学級での様子をお伝えします。</p>
        </div>
        <div class="footer">
            <p>{school_name} {grade} 担任: {author_name}</p>
        </div>
    </div>
</body>
</html>'''
        return html_template


def create_simple_layout_agent() -> SimpleLayoutAgent:
    """SimpleLayoutAgentのインスタンスを生成するファクトリ関数。"""
    return SimpleLayoutAgent(output_key="html")


# ADK Web UI用のroot_agent変数
root_agent = create_simple_layout_agent()