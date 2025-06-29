import json
import logging
from datetime import datetime
from typing import AsyncGenerator, Optional

# from pathlib import Path  # 本番環境対応: ファイルシステム使用無効化
from google.adk.agents import LlmAgent
from google.adk.agents.invocation_context import InvocationContext
from google.adk.events.event import Event
from google.adk.models.google_llm import Gemini
from google.adk.tools import FunctionTool
from google.genai.types import Content, Part

from .prompt import MAIN_CONVERSATION_INSTRUCTION

# ロガーの設定
logger = logging.getLogger(__name__)


def get_current_date() -> str:
    """現在の日付を'YYYY-MM-DD'形式で返します。ユーザーには自然な形で表示されます。"""
    current_date = datetime.now().strftime("%Y-%m-%d")
    logger.info(f"正確な現在日付を取得しました: {current_date}")
    return current_date


def save_json_to_session(json_data: str) -> str:
    """JSONデータをセッション状態とファイルシステムに保存します。"""
    try:
        # TODO: InvocationContextをツール関数で直接取得する方法を検討
        # 現在はMainConversationAgentのメソッドで実装
        return f"JSON構成案を準備しました: {len(json_data)} 文字"
    except Exception as e:
        logger.error(f"JSON保存エラー: {e}")
        return f"保存中にエラーが発生しました: {str(e)}"


class MainConversationAgent(LlmAgent):
    """
    メインの対話エージェント。
    ユーザーと自然な対話を行い、適切なタイミングでLayoutAgentにHTML生成を委譲します。
    """

    def __init__(self):
        # シンプルなLayoutAgentを使用
        from agents.layout_agent.agent import create_simple_layout_agent
        layout_agent = create_simple_layout_agent()
        
        super().__init__(
            name="main_conversation_agent",
            model=Gemini(model_name="gemini-2.5-pro"),
            instruction=MAIN_CONVERSATION_INSTRUCTION,
            description="ユーザーと自然な対話を行い、学級通信作成をサポートします。",
            tools=[
                FunctionTool(get_current_date)
            ],
            sub_agents=[layout_agent],
        )

    async def _run_async_impl(
        self, ctx: InvocationContext
    ) -> AsyncGenerator[Event, None]:
        """
        純粋な対話エージェントとして実行します。
        HTML生成は明示的なユーザー要求があった場合のみ委譲します。
        """
        try:
            logger.info("=== MainConversationAgent実行開始 (ADK推奨パターン) ===")
            logger.info(f"Output key: {self.output_key}")
            logger.info(f"Sub agents: {len(self.sub_agents)}")
            event_count = 0
            
            # 事前に会話情報を抽出（LLM実行前）
            logger.info("🔄 LLM実行前に既存の会話情報を抽出")
            await self._extract_simple_conversation_info(ctx)
            
            # ADK推奨: LLM実行のみでoutput_keyによる自動保存に任せる
            async for event in super()._run_async_impl(ctx):
                event_count += 1
                logger.info(f"LLMイベント #{event_count}: author={getattr(event, 'author', 'unknown')}")
                
                # transfer_to_agentの実行を確認
                if hasattr(event, 'actions') and event.actions and event.actions.transfer_to_agent:
                    logger.info(f"✅ transfer_to_agent実行: {event.actions.transfer_to_agent}")
                
                yield event

            logger.info(f"=== MainConversationAgent完了: {event_count}個のイベント ===")
            
            # LLM実行後に改めて会話情報を抽出（最新の会話を含む）
            logger.info("🔄 LLM実行後に最新の会話情報を抽出")
            await self._extract_simple_conversation_info(ctx)
            
            # 明示的な生成リクエストの場合のみHTML生成準備
            await self._prepare_html_generation_if_explicit_request(ctx)
            
            # シンプルなHTML生成呼び出し
            if hasattr(ctx, "session") and hasattr(ctx.session, "state"):
                if ctx.session.state.get("html_generation_requested", False):
                    logger.info("=== HTML生成要求を検出 - 直接LayoutAgent呼び出し ===")
                    
                    # フラグをクリア
                    ctx.session.state["html_generation_requested"] = False
                    
                    # LayoutAgentを直接実行してHTMLを生成
                    async for layout_event in self._call_layout_agent_directly(ctx):
                        yield layout_event
            
            # ADKセッション状態確認
            await self._log_session_state_for_debug(ctx)

        except Exception as e:
            error_msg = f"対話中にエラーが発生しました: {str(e)}"
            logger.error(error_msg)
            yield Event(
                author=self.name, 
                content=Content(parts=[Part(text=error_msg)])
            )

    async def _save_conversation_state(self, ctx: InvocationContext):
        """対話の状態をセッションに保存"""
        try:
            # セッション状態に対話完了フラグを保存
            if hasattr(ctx, "session") and hasattr(ctx.session, "state"):
                ctx.session.state["conversation_active"] = True
                ctx.session.state["last_interaction"] = get_current_date()
                
                # ユーザー承認状態の初期化
                if "user_approved" not in ctx.session.state:
                    ctx.session.state["user_approved"] = False
                    
                # 情報収集進捗の管理
                if "collection_stage" not in ctx.session.state:
                    ctx.session.state["collection_stage"] = "initial"
                    
                logger.info("対話状態をセッション状態に保存しました")

        except Exception as e:
            logger.error(f"対話状態保存エラー: {e}")

    async def _extract_simple_conversation_info(self, ctx: InvocationContext):
        """会話から学級通信に必要な基本情報をシンプルに抽出"""
        try:
            logger.info("=== シンプルな会話情報抽出開始 ===")
            
            # セッション情報の詳細確認
            if not hasattr(ctx, "session"):
                logger.error("❌ ctx.sessionが存在しません")
                return
            logger.info(f"✅ ctx.session確認完了: {type(ctx.session)}")
            
            if not hasattr(ctx.session, "events"):
                logger.error("❌ ctx.session.eventsが存在しません")
                return
            logger.info(f"✅ ctx.session.events確認完了: {type(ctx.session.events)}")

            session_events = ctx.session.events
            if not session_events:
                logger.warning("⚠️  セッションイベントが空です")
                return
            
            logger.info(f"📊 セッションイベント数: {len(session_events)}")
            
            # 各イベントの詳細をログ出力
            conversation_text = ""
            for i, event in enumerate(session_events):
                logger.info(f"📝 イベント #{i}: author={getattr(event, 'author', 'unknown')}")
                event_text = self._extract_text_from_event(event)
                logger.info(f"📝 イベント #{i} テキスト長: {len(event_text)} 文字")
                if len(event_text) > 0:
                    logger.info(f"📝 イベント #{i} 内容プレビュー: {event_text[:100]}...")
                conversation_text += event_text + " "
            
            logger.info(f"✅ 会話テキスト抽出完了: {len(conversation_text)} 文字")
            logger.info(f"📄 会話内容プレビュー: {conversation_text[:200]}...")
            
            # セッション状態の詳細確認
            if not hasattr(ctx, "session") or not hasattr(ctx.session, "state"):
                logger.error("❌ ctx.session.stateが存在しません")
                return
            
            logger.info(f"✅ ctx.session.state確認完了: {type(ctx.session.state)}")
            logger.info(f"📊 保存前のセッション状態キー: {list(ctx.session.state.keys())}")
            
            # JSON構成案の抽出（最優先）
            logger.info("🔍 JSON構成案の抽出を開始")
            json_outline = self._extract_json_from_conversation(conversation_text)
            
            if json_outline:
                logger.info(f"✅ JSON構成案を抽出しました: {len(json_outline)} 文字")
                logger.info(f"📄 JSON構成案プレビュー: {json_outline[:300]}...")
                ctx.session.state["outline"] = json_outline
                ctx.session.state["outline_extracted"] = True
            else:
                logger.warning("⚠️  JSON構成案の抽出に失敗 - 代替手段を試行")
                # 手動でJSON構築を試行
                json_outline = await self._build_json_from_conversation_analysis(conversation_text)
                if json_outline:
                    logger.info(f"✅ 手動JSON構築成功: {len(json_outline)} 文字")
                    ctx.session.state["outline"] = json_outline
                    ctx.session.state["outline_extracted"] = True
                else:
                    logger.error("❌ JSON構成案の生成に完全に失敗")
                    # それでも会話内容は保存しておく
                    logger.info("🔄 JSONは失敗したが会話内容は保存継続")
            
            # セッション状態にシンプルに保存（強制的に保存）
            try:
                ctx.session.state["conversation_content"] = conversation_text
                ctx.session.state["info_extracted"] = True
                ctx.session.state["extraction_timestamp"] = get_current_date()
                ctx.session.state["session_active"] = True  # セッション有効フラグ
                
                # 二重保存：重要な情報は複数のキーで保存
                ctx.session.state["backup_conversation"] = conversation_text
                ctx.session.state["last_update"] = get_current_date()
                
                logger.info("✅ 会話情報をセッション状態に保存しました")
                logger.info(f"📊 保存後のセッション状態キー: {list(ctx.session.state.keys())}")
                logger.info(f"📊 保存された会話内容長: {len(ctx.session.state.get('conversation_content', ''))} 文字")
                logger.info(f"📊 保存されたJSON構成案長: {len(ctx.session.state.get('outline', ''))} 文字")
                
                # 保存確認テスト
                saved_content = ctx.session.state.get("conversation_content", "")
                if saved_content == conversation_text:
                    logger.info("✅ セッション状態保存確認: 成功")
                else:
                    logger.error(f"❌ セッション状態保存確認: 失敗 (保存: {len(saved_content)}, 元: {len(conversation_text)})")
                    
            except Exception as save_error:
                logger.error(f"❌ セッション状態保存エラー: {save_error}")
                import traceback
                logger.error(f"保存エラー詳細: {traceback.format_exc()}")

        except Exception as e:
            logger.error(f"❌ 会話情報抽出エラー: {e}")
            import traceback
            logger.error(f"詳細エラー: {traceback.format_exc()}")

    def _extract_user_info_from_conversation(self, session_events) -> dict:
        """対話履歴からユーザー情報を抽出"""
        user_info = {
            'school_name': None,
            'grade': None,
            'teacher_name': None,
            'title': None,
            'content': None,
            'photo_count': 0,
            'issue_date': None
        }
        
        try:
            # 最新の日付を取得
            user_info['issue_date'] = get_current_date()
            
            # 全てのイベントからテキストを抽出して分析
            all_text = ""
            for event in session_events:
                event_text = self._extract_text_from_event(event)
                all_text += event_text + " "
            
            logger.info(f"対話履歴全体: {all_text[:500]}...")
            
            # パターンマッチングで情報を抽出
            import re
            
            # 学校名を抽出（「〇〇小学校」「〇〇中学校」など）
            school_patterns = [
                r'([あ-ん一-龯A-Za-z0-9\-〇○]+(?:小学校|中学校|高等学校|高校))',
                r'学校名[：:]\s*([あ-ん一-龯A-Za-z0-9\-〇○]+)',
                r'([あ-ん一-龯]+小)',
            ]
            for pattern in school_patterns:
                match = re.search(pattern, all_text)
                if match:
                    user_info['school_name'] = match.group(1)
                    break
            
            # 学年・組を抽出
            grade_patterns = [
                r'([1-6]年[1-9]組)',
                r'([1-6])年([1-9])組', 
                r'学年[：:]\s*([1-6]年[1-9]組)',
                r'([1-6]年)',
            ]
            for pattern in grade_patterns:
                match = re.search(pattern, all_text)
                if match:
                    if len(match.groups()) == 1:
                        user_info['grade'] = match.group(1)
                    else:
                        user_info['grade'] = f"{match.group(1)}年{match.group(2)}組"
                    break
            
            # 先生名を抽出
            teacher_patterns = [
                r'([あ-ん一-龯]+)先生',
                r'担任[：:]\s*([あ-ん一-龯]+)',
                r'発行者[：:]\s*([あ-ん一-龯]+)',
                r'私は([あ-ん一-龯]+)です',
            ]
            for pattern in teacher_patterns:
                match = re.search(pattern, all_text)
                if match:
                    user_info['teacher_name'] = match.group(1)
                    break
            
            # タイトルを抽出
            title_patterns = [
                r'タイトル[：:]\s*([あ-ん一-龯A-Za-z0-9\s]+)',
                r'題名[：:]\s*([あ-ん一-龯A-Za-z0-9\s]+)',
                r'([あ-ん一-龯]+(?:大成功|練習|発表会|運動会|遠足))',
            ]
            for pattern in title_patterns:
                match = re.search(pattern, all_text)
                if match:
                    user_info['title'] = match.group(1).strip()
                    break
            
            # 内容を抽出（長めのテキストブロック）
            content_patterns = [
                r'内容[：:]\s*([あ-ん一-龯A-Za-z0-9\s。、！？]{20,})',
                r'([あ-ん一-龯]{10,}(?:ました|です|でした)。[あ-ん一-龯\s。、]{20,})',
            ]
            for pattern in content_patterns:
                match = re.search(pattern, all_text)
                if match:
                    user_info['content'] = match.group(1).strip()
                    break
            
            # 写真枚数を抽出
            photo_patterns = [
                r'写真[：:]?\s*([0-9]+)枚',
                r'([0-9]+)枚の写真',
                r'写真.*?([0-9]+)',
            ]
            for pattern in photo_patterns:
                match = re.search(pattern, all_text)
                if match:
                    user_info['photo_count'] = int(match.group(1))
                    break
            
            logger.info(f"抽出結果: {user_info}")
            return user_info
            
        except Exception as e:
            logger.error(f"ユーザー情報抽出エラー: {e}")
            return user_info

    def _has_sufficient_info(self, user_info: dict) -> bool:
        """十分な情報が収集されているかチェック"""
        required_fields = ['school_name', 'grade', 'teacher_name']
        missing_fields = [field for field in required_fields if not user_info.get(field)]
        
        if missing_fields:
            logger.info(f"不足情報: {missing_fields}")
            return False
        
        logger.info("必要情報が揃いました")
        return True

    async def _build_json_from_user_info(self, user_info: dict) -> str:
        """ユーザー情報からJSONを手動構築"""
        try:
            json_obj = {
                "schema_version": "2.4",
                "school_name": user_info.get('school_name', '学校名'),
                "grade": user_info.get('grade', '学年'),
                "issue": "学級通信",
                "issue_date": user_info.get('issue_date', get_current_date()),
                "author": {
                    "name": user_info.get('teacher_name', '担任'),
                    "title": "担任"
                },
                "main_title": user_info.get('title', f"{user_info.get('grade', '学年')}だより"),
                "sub_title": None,
                "season": "通年",
                "theme": "学級の様子",
                "color_scheme": {
                    "primary": "#FFFF99",
                    "secondary": "#FFCC99", 
                    "accent": "#FF9966",
                    "background": "#ffffff"
                },
                "color_scheme_source": "温かみのある色合い",
                "sections": [
                    {
                        "type": "main_content",
                        "title": user_info.get('title', 'お知らせ'),
                        "content": user_info.get('content', '学級の様子をお伝えします。'),
                        "estimated_length": "medium",
                        "section_visual_hint": "text_content"
                    }
                ],
                "photo_placeholders": {
                    "count": user_info.get('photo_count', 0),
                    "suggested_positions": []
                },
                "enhancement_suggestions": [],
                "has_editor_note": False,
                "editor_note": None,
                "layout_suggestion": {
                    "page_count": 1,
                    "columns": 2,
                    "column_ratio": "1:1",
                    "blocks": ["header", "main_content", "footer"]
                },
                "force_single_page": True,
                "max_pages": 1
            }
            
            import json
            json_str = json.dumps(json_obj, ensure_ascii=False, indent=2)
            logger.info(f"JSON構築完了: {len(json_str)}文字")
            return json_str
            
        except Exception as e:
            logger.error(f"JSON構築エラー: {e}")
            return None

    def _extract_text_from_event(self, event) -> str:
        """イベントからテキストを抽出（function_call対応強化版）"""
        llm_response_text = ""
        logger.info(f"=== テキスト抽出開始 ===")
        logger.info(f"イベントタイプ: {type(event)}")
        logger.info(f"イベント属性: {dir(event)}")

        if hasattr(event, "content") and event.content:
            logger.info(f"コンテンツタイプ: {type(event.content)}")
            logger.info(f"コンテンツ属性: {dir(event.content)}")
            
            if hasattr(event.content, "parts"):
                logger.info(f"Parts数: {len(event.content.parts) if event.content.parts else 0}")
                # Google Generative AI形式
                for i, part in enumerate(event.content.parts):
                    logger.info(f"Part #{i}: type={type(part)}, attributes={dir(part)}")
                    
                    # テキストpart処理
                    if hasattr(part, "text") and part.text:
                        logger.info(f"Part #{i} テキスト長: {len(part.text)}")
                        llm_response_text += part.text
                    
                    # function_call part処理（JSONが含まれている可能性）
                    elif hasattr(part, "function_call") and part.function_call:
                        logger.info(f"Part #{i}: function_call検出")
                        logger.info(f"function_call詳細: {part.function_call}")
                        # function_callの結果にテキストが含まれている場合は抽出
                        if hasattr(part.function_call, "args") and part.function_call.args:
                            args_str = str(part.function_call.args)
                            logger.info(f"function_call args: {args_str[:200]}...")
                            # JSONらしき文字列があれば追加
                            if "school_name" in args_str or "grade" in args_str:
                                llm_response_text += args_str
                    
                    # function_response part処理
                    elif hasattr(part, "function_response") and part.function_response:
                        logger.info(f"Part #{i}: function_response検出")
                        response_content = str(part.function_response.response) if part.function_response.response else ""
                        logger.info(f"function_response content: {response_content[:200]}...")
                        if response_content:
                            llm_response_text += response_content
                    
                    else:
                        logger.warning(f"Part #{i}: テキストなし - 属性: {[attr for attr in dir(part) if not attr.startswith('_')]}")
                        
                        # その他のpart属性を詳細確認
                        for attr in ['inline_data', 'file_data', 'executable_code', 'code_execution_result']:
                            if hasattr(part, attr):
                                attr_value = getattr(part, attr)
                                if attr_value:
                                    logger.info(f"Part #{i} {attr}: {str(attr_value)[:100]}...")
                                    
            elif isinstance(event.content, list):
                logger.info(f"リスト形式: {len(event.content)}項目")
                # リスト形式
                for item in event.content:
                    if isinstance(item, dict) and "text" in item:
                        llm_response_text += item["text"]
            else:
                logger.warning(f"予期しないコンテンツ形式: {type(event.content)}")
        else:
            logger.warning("イベントにコンテンツが存在しません")

        logger.info(f"抽出結果: {len(llm_response_text)} 文字")
        return llm_response_text

    def _extract_json_from_response(self, response_text: str) -> Optional[str]:
        """LLM応答からJSONを抽出"""
        try:
            # Markdownコードブロック(```json)を検出して抽出
            if "```json" in response_text:
                json_start = response_text.find("```json") + 7
                json_end = response_text.find("```", json_start)
                if json_end != -1:
                    json_str = response_text[json_start:json_end].strip()
                    # JSONとして有効か検証
                    json.loads(json_str)
                    return json_str
        except (ValueError, json.JSONDecodeError) as e:
            logger.warning(f"JSON抽出・検証エラー: {e}")
        
        return None

    def _extract_direct_json_from_response(self, response_text: str) -> Optional[str]:
        """応答テキストから直接JSONオブジェクトを抽出"""
        try:
            # { で始まり } で終わるJSONオブジェクトを検索
            start_idx = response_text.find("{")
            if start_idx == -1:
                return None
                
            brace_count = 0
            end_idx = start_idx
            
            for i, char in enumerate(response_text[start_idx:], start_idx):
                if char == "{":
                    brace_count += 1
                elif char == "}":
                    brace_count -= 1
                    if brace_count == 0:
                        end_idx = i + 1
                        break
            
            if brace_count == 0:
                json_candidate = response_text[start_idx:end_idx]
                # JSONとして有効か検証
                json.loads(json_candidate)
                return json_candidate
                
        except (ValueError, json.JSONDecodeError) as e:
            logger.warning(f"直接JSON抽出・検証エラー: {e}")
        
        return None

    def _extract_json_from_conversation(self, conversation_text: str) -> Optional[str]:
        """会話テキストからJSON構成案を抽出"""
        try:
            logger.info("🔍 会話テキストからJSON抽出を開始")
            logger.info(f"📄 対象テキスト長: {len(conversation_text)} 文字")
            
            # 抽出対象がない場合は早期リターン
            if not conversation_text or len(conversation_text) < 10:
                logger.warning("⚠️  会話テキストが短すぎるためJSON抽出をスキップ")
                return None
            
            # 方法1: Markdownコードブロックから抽出
            logger.info("🔍 方法1: Markdownコードブロック検索")
            if "```json" in conversation_text:
                json_from_markdown = self._extract_json_from_response(conversation_text)
                if json_from_markdown:
                    logger.info("✅ MarkdownコードブロックからJSON抽出成功")
                    return json_from_markdown
                else:
                    logger.warning("⚠️  Markdownコードブロックは見つかったが抽出失敗")
            else:
                logger.info("📋 Markdownコードブロック(```json)が見つかりません")
            
            # 方法2: 直接JSONオブジェクトを検索（安全性を強化）
            logger.info("🔍 方法2: 直接JSONオブジェクト検索")
            if "{" in conversation_text and "}" in conversation_text:
                json_from_direct = self._extract_direct_json_from_response_safe(conversation_text)
                if json_from_direct:
                    logger.info("✅ 直接JSONオブジェクト検索成功")
                    return json_from_direct
                else:
                    logger.warning("⚠️  JSON構造は見つかったが抽出失敗")
            else:
                logger.info("📋 JSON構造({})が見つかりません")
            
            logger.warning("⚠️  すべての方法でJSON抽出失敗")
            return None
            
        except Exception as e:
            logger.error(f"❌ JSON抽出エラー: {e}")
            import traceback
            logger.error(f"詳細エラー: {traceback.format_exc()}")
            return None

    def _extract_direct_json_from_response_safe(self, response_text: str) -> Optional[str]:
        """安全性を強化した直接JSON抽出"""
        try:
            # 複数のJSONオブジェクトが存在する可能性を考慮
            start_positions = []
            for i, char in enumerate(response_text):
                if char == "{":
                    start_positions.append(i)
            
            if not start_positions:
                logger.info("📋 JSON開始記号({)が見つかりません")
                return None
            
            logger.info(f"📋 {len(start_positions)}個のJSON候補を発見")
            
            # 各候補を検証
            for i, start_idx in enumerate(start_positions):
                try:
                    brace_count = 0
                    end_idx = start_idx
                    
                    for j, char in enumerate(response_text[start_idx:], start_idx):
                        if char == "{":
                            brace_count += 1
                        elif char == "}":
                            brace_count -= 1
                            if brace_count == 0:
                                end_idx = j + 1
                                break
                    
                    if brace_count == 0:
                        json_candidate = response_text[start_idx:end_idx]
                        
                        # 長さチェック（あまりに短いJSONは無視）
                        if len(json_candidate) < 50:
                            logger.info(f"📋 候補 #{i}: 短すぎるためスキップ ({len(json_candidate)} 文字)")
                            continue
                        
                        # JSON妥当性チェック
                        parsed = json.loads(json_candidate)
                        
                        # 学級通信らしいJSONかチェック
                        if self._is_newsletter_json(parsed):
                            logger.info(f"✅ 候補 #{i}: 学級通信JSON として妥当")
                            return json_candidate
                        else:
                            logger.info(f"📋 候補 #{i}: 学級通信JSONではない")
                            
                except json.JSONDecodeError as e:
                    logger.info(f"📋 候補 #{i}: JSON解析エラー - {str(e)[:100]}")
                except Exception as e:
                    logger.info(f"📋 候補 #{i}: その他エラー - {str(e)[:100]}")
            
            logger.warning("⚠️  妥当なJSON候補が見つかりませんでした")
            return None
                    
        except Exception as e:
            logger.error(f"❌ 安全JSON抽出エラー: {e}")
            return None

    def _is_newsletter_json(self, parsed_json: dict) -> bool:
        """学級通信JSONとして妥当かチェック"""
        try:
            # 必須フィールドをチェック
            required_fields = ['school_name', 'grade', 'author']
            for field in required_fields:
                if field not in parsed_json:
                    return False
            
            # 学校らしい情報が含まれているかチェック
            school_keywords = ['小学校', '中学校', '高校', '学園', '学校']
            school_name = str(parsed_json.get('school_name', ''))
            if not any(keyword in school_name for keyword in school_keywords):
                # 学校名が空でない場合のみチェック
                if school_name and school_name != '学校名':
                    return False
            
            return True
            
        except Exception:
            return False

    async def _build_json_from_conversation_analysis(self, conversation_text: str) -> Optional[str]:
        """会話テキストの分析からJSON構成案を手動構築"""
        try:
            logger.info("🔧 会話テキスト分析によるJSON手動構築開始")
            
            # シンプルなパターンマッチングで情報抽出
            import re
            
            basic_info = {
                'school_name': '学校名',
                'grade': '学年',
                'teacher_name': '担任',
                'title': '学級通信',
                'content': '学級の様子をお伝えします。',
                'date': get_current_date()
            }
            
            # 学校名抽出
            school_match = re.search(r'([あ-ん一-龯A-Za-z0-9]+(?:小学校|中学校|高校))', conversation_text)
            if school_match:
                basic_info['school_name'] = school_match.group(1)
                
            # 学年・組抽出
            grade_match = re.search(r'([1-6]年[1-9]組)', conversation_text)
            if grade_match:
                basic_info['grade'] = grade_match.group(1)
                
            # 先生名抽出
            teacher_match = re.search(r'([あ-ん一-龯]+)先生', conversation_text)
            if teacher_match:
                basic_info['teacher_name'] = teacher_match.group(1)
            
            # 運動会関連の内容を抽出
            if '運動会' in conversation_text:
                basic_info['title'] = '運動会大成功！'
                # 運動会関連の文章を抽出
                content_match = re.search(r'(運動会.*?。.*?。.*?。)', conversation_text)
                if content_match:
                    basic_info['content'] = content_match.group(1)
            
            # JSON構造を構築
            json_structure = {
                "schema_version": "2.4",
                "school_name": basic_info['school_name'],
                "grade": basic_info['grade'],
                "issue": f"{datetime.now().month}月号",
                "issue_date": basic_info['date'],
                "author": {
                    "name": basic_info['teacher_name'],
                    "title": "担任"
                },
                "main_title": basic_info['title'],
                "sub_title": None,
                "season": "通年",
                "theme": "学級の様子",
                "color_scheme": {
                    "primary": "#667eea",
                    "secondary": "#764ba2",
                    "accent": "#f093fb",
                    "background": "#ffffff"
                },
                "color_scheme_source": "明るく親しみやすい色合い",
                "sections": [
                    {
                        "type": "main_content",
                        "title": basic_info['title'],
                        "content": basic_info['content'],
                        "estimated_length": "medium",
                        "section_visual_hint": "text_content"
                    }
                ],
                "photo_placeholders": {
                    "count": 2,
                    "suggested_positions": []
                },
                "enhancement_suggestions": [],
                "has_editor_note": False,
                "editor_note": None,
                "layout_suggestion": {
                    "page_count": 1,
                    "columns": 2,
                    "column_ratio": "1:1",
                    "blocks": ["header", "main_content", "footer"]
                },
                "force_single_page": True,
                "max_pages": 1
            }
            
            json_str = json.dumps(json_structure, ensure_ascii=False, indent=2)
            logger.info(f"✅ 手動JSON構築完了: {len(json_str)} 文字")
            logger.info(f"📄 構築されたJSON: {json_str[:200]}...")
            return json_str
            
        except Exception as e:
            logger.error(f"❌ 手動JSON構築エラー: {e}")
            import traceback
            logger.error(f"詳細エラー: {traceback.format_exc()}")
            return None

    async def _extract_json_from_function_calls(self, ctx: InvocationContext) -> Optional[str]:
        """セッションイベントからfunction_call引数のJSONを抽出"""
        try:
            if not hasattr(ctx, "session") or not hasattr(ctx.session, "events"):
                return None
                
            session_events = ctx.session.events
            
            # 最新のイベントから逆順でfunction_callを検索
            for event in reversed(session_events):
                if hasattr(event, "author") and event.author == self.name:
                    if hasattr(event, "content") and event.content and hasattr(event.content, "parts"):
                        for part in event.content.parts:
                            if hasattr(part, "function_call") and part.function_call:
                                if hasattr(part.function_call, "args") and part.function_call.args:
                                    args = part.function_call.args
                                    
                                    # argsがdict形式の場合
                                    if isinstance(args, dict):
                                        # JSON保存用の引数があるかチェック
                                        if "json_data" in args:
                                            return args["json_data"]
                                        # 引数全体がJSONデータの場合
                                        elif "school_name" in str(args):
                                            return json.dumps(args, ensure_ascii=False)
                                    
                                    # argsが文字列の場合
                                    elif isinstance(args, str):
                                        try:
                                            parsed_args = json.loads(args)
                                            if "school_name" in parsed_args:
                                                return args
                                        except:
                                            pass
                                            
            logger.info("function_callからのJSON抽出に失敗")
            return None
            
        except Exception as e:
            logger.error(f"function_call JSON抽出エラー: {e}")
            return None

    def _remove_json_blocks_from_response(self, response_text: str) -> str:
        """LLM応答からJSONブロックを完全に除去してクリーンなテキストを返す"""
        try:
            # 複数のJSONブロックに対応
            cleaned_text = response_text
            while "```json" in cleaned_text and "```" in cleaned_text:
                json_start = cleaned_text.find("```json")
                json_end = cleaned_text.find("```", json_start + 7) + 3
                if json_end > json_start:
                    # JSONブロックを除去
                    cleaned_text = cleaned_text[:json_start] + cleaned_text[json_end:]
                else:
                    break
            
            # 余分な空白行を整理
            lines = cleaned_text.split('\n')
            cleaned_lines = []
            consecutive_empty = 0
            
            for line in lines:
                if line.strip() == '':
                    consecutive_empty += 1
                    if consecutive_empty <= 1:  # 最大1行の空白行のみ許可
                        cleaned_lines.append(line)
                else:
                    consecutive_empty = 0
                    cleaned_lines.append(line)
            
            return '\n'.join(cleaned_lines).strip()
            
        except Exception as e:
            logger.warning(f"JSONブロック除去中にエラー: {e}")
            return response_text

    async def _update_event_content_silently(self, ctx: InvocationContext, event, new_content: str):
        """イベント内容をサイレントに更新（ユーザー表示をクリーン化）"""
        try:
            from google.genai.types import Content, Part
            
            # 新しいコンテンツでイベントを更新
            if hasattr(event, "content") and event.content:
                # Google Generative AI形式での更新
                new_content_obj = Content(parts=[Part(text=new_content)])
                event.content = new_content_obj
                logger.info("イベント内容をクリーンなテキストに更新しました")
                
        except Exception as e:
            logger.warning(f"イベント内容更新中にエラー: {e}")

    async def _call_layout_agent_directly(self, ctx: InvocationContext):
        """LayoutAgentを直接呼び出してHTMLを生成"""
        try:
            logger.info("=== LayoutAgent直接呼び出し開始 ===")
            
            # sub_agentsからLayoutAgentを取得
            layout_agent = None
            for agent in self.sub_agents:
                if agent.name == "layout_agent":
                    layout_agent = agent
                    break
            
            if layout_agent is None:
                logger.error("LayoutAgentがsub_agentsに見つかりません")
                yield Event(
                    author=self.name,
                    content=Content(parts=[Part(text="レイアウト生成エージェントが見つかりません。")])
                )
                return
            
            logger.info(f"LayoutAgent取得成功: {layout_agent.name}")
            
            # LayoutAgentを直接実行してイベントを転送
            async for layout_event in layout_agent._run_async_impl(ctx):
                yield layout_event
                
            logger.info("LayoutAgent実行完了")
                
        except Exception as e:
            logger.error(f"LayoutAgent呼び出しエラー: {e}")
            yield Event(
                author=self.name,
                content=Content(parts=[Part(text="レイアウト生成中にエラーが発生しました。")])
            )

    def _is_user_approval(self, response_text: str) -> bool:
        """ユーザーの承認を示すキーワードを検出"""
        approval_keywords = [
            "この内容でよろしいですか？",
            "この内容で大丈夫ですか？",
            "修正点があればお聞かせください",
            "いかがでしょうか？"
        ]
        return any(keyword in response_text for keyword in approval_keywords)

    async def _mark_user_approval(self, ctx: InvocationContext):
        """ユーザー承認段階をマーク"""
        try:
            if hasattr(ctx, "session") and hasattr(ctx.session, "state"):
                ctx.session.state["collection_stage"] = "awaiting_approval"
                logger.info("ユーザー承認待ち状態に設定しました")
        except Exception as e:
            logger.error(f"承認状態設定エラー: {e}")

    def _should_generate_html(self, ctx: InvocationContext) -> bool:
        """HTML生成すべきかどうかを判定"""
        try:
            if not hasattr(ctx, "session") or not hasattr(ctx.session, "state"):
                return False
            
            # セッション状態にoutlineが存在するかチェック
            has_outline = "outline" in ctx.session.state and ctx.session.state["outline"]
            
            # ユーザー承認状態をチェック（オプション）
            collection_stage = ctx.session.state.get("collection_stage", "initial")
            
            logger.info(f"HTML生成判定: has_outline={has_outline}, collection_stage={collection_stage}")
            
            return has_outline
            
        except Exception as e:
            logger.error(f"HTML生成判定エラー: {e}")
            return False

    async def _prepare_html_generation_if_explicit_request(self, ctx: InvocationContext):
        """明示的な生成リクエストの場合のみHTML生成準備（UIボタン対応版）"""
        try:
            if not hasattr(ctx, "session") or not hasattr(ctx.session, "state"):
                logger.warning("セッション状態が利用できません")
                return

            # 最新のユーザーメッセージを確認
            latest_user_message = self._get_latest_user_message(ctx)
            if not latest_user_message:
                return

            # 明示的な生成リクエストキーワードをチェック
            explicit_generation_keywords = [
                "学級通信を生成", "学級通信を作成", "生成してください", "作成してください",
                "HTMLを生成", "レイアウトを作成", "完成させて"
            ]
            
            is_explicit_request = any(
                keyword in latest_user_message 
                for keyword in explicit_generation_keywords
            )
            
            logger.info(f"明示的生成リクエスト判定:")
            logger.info(f"  - latest_message: {latest_user_message[:100]}...")
            logger.info(f"  - is_explicit_request: {is_explicit_request}")

            if not is_explicit_request:
                logger.info("明示的な生成リクエストではありません - HTML生成をスキップ")
                return

            # セッション状態の詳細確認
            logger.info(f"📊 セッション状態キー: {list(ctx.session.state.keys())}")
            
            # 会話内容が存在するかチェック（outline不要方式に変更）
            has_conversation = "conversation_content" in ctx.session.state and ctx.session.state["conversation_content"]
            has_json = "outline" in ctx.session.state and ctx.session.state["outline"]
            
            # 既にHTML生成済みかチェック
            html_already_generated = ctx.session.state.get("html_generated", False)
            
            logger.info(f"HTML生成条件チェック:")
            logger.info(f"  - has_conversation: {has_conversation} ({len(ctx.session.state.get('conversation_content', ''))} 文字)")
            logger.info(f"  - has_json: {has_json}")
            logger.info(f"  - html_already_generated: {html_already_generated}")

            # 会話内容が存在し、未生成の場合のみHTML生成を実行（JSON不要）
            if has_conversation and not html_already_generated:
                logger.info("✅ 明示的な生成リクエストを受理 - 会話内容からHTML生成を開始")
                ctx.session.state["user_approved"] = True  # 明示的承認
                ctx.session.state["html_generation_requested"] = True  # HTML生成フラグ
                logger.info("HTML生成準備が完了しました")
            elif html_already_generated:
                logger.info("HTML生成済みのため、再生成をスキップします")
            elif not has_conversation:
                logger.warning(f"会話内容が見つかりません - 対話を続行してください")
                # 代替手段として強制的にHTML生成を試行
                logger.info("🔄 代替手段として強制HTML生成フラグを設定")
                ctx.session.state["user_approved"] = True
                ctx.session.state["html_generation_requested"] = True
            else:
                logger.info("HTML生成条件が不足しています")
                
        except Exception as e:
            logger.error(f"明示的生成リクエスト処理エラー: {e}")

    def _get_latest_user_message(self, ctx: InvocationContext) -> str:
        """最新のユーザーメッセージを取得"""
        try:
            if not hasattr(ctx, "session") or not hasattr(ctx.session, "events"):
                return ""
                
            # 最新のユーザーイベントを逆順で検索
            for event in reversed(ctx.session.events):
                if hasattr(event, "content") and event.content:
                    # ユーザーからのメッセージかチェック
                    if hasattr(event.content, "role") and event.content.role == "user":
                        text = self._extract_text_from_event(event)
                        if text:
                            return text
                    # role属性がない場合は、ユーザーイベントと仮定してテキストを抽出
                    elif not hasattr(event.content, "role"):
                        text = self._extract_text_from_event(event)
                        if text and len(text) > 5:  # 短すぎるテキストは除外
                            return text
            
            return ""
            
        except Exception as e:
            logger.error(f"最新ユーザーメッセージ取得エラー: {e}")
            return ""

    async def _invoke_layout_agent_with_yield(self, ctx: InvocationContext):
        """LayoutAgentを直接呼び出してイベントをyield（MALFORMED_FUNCTION_CALL対応版）"""
        try:
            logger.info("=== LayoutAgent手動呼び出し開始 ===")
            
            # sub_agentsからLayoutAgentを取得
            layout_agent = None
            for agent in self.sub_agents:
                if agent.name == "layout_agent":
                    layout_agent = agent
                    break
            
            if layout_agent is None:
                logger.error("LayoutAgentがsub_agentsに見つかりません")
                return
            
            logger.info(f"LayoutAgent取得成功: {layout_agent.name}")
            
            # 同一セッション状態でLayoutAgentを実行
            logger.info(f"LayoutAgent実行前のセッション状態: {list(ctx.session.state.keys())}")
            
            # 手動でyieldするため、現在の_run_async_implの実行を一旦保存
            logger.info("LayoutAgentを非同期実行します...")
            # ここでは委譲の準備のみ行い、実際のyieldは親の_run_async_implで行う
            
            # セッション状態にHTML生成フラグを設定
            ctx.session.state["html_generation_requested"] = True
            logger.info("HTML生成リクエストフラグを設定しました")
            
        except Exception as e:
            logger.error(f"LayoutAgent手動呼び出しエラー: {e}")
            import traceback
            logger.error(f"詳細エラー: {traceback.format_exc()}")

    async def _detect_user_approval_from_conversation(self, ctx: InvocationContext) -> bool:
        """最新の対話からユーザー承認を検出"""
        try:
            if not hasattr(ctx, "session") or not hasattr(ctx.session, "events"):
                return False
                
            # 最新のユーザーイベントを確認
            for event in reversed(ctx.session.events):
                if hasattr(event, "content") and event.content:
                    text = self._extract_text_from_event(event)
                    if text:
                        # より厳密な承認キーワードをチェック（誤検出防止）
                        explicit_approval_patterns = [
                            "この内容で", "これで大丈夫", "これでお願い", "作成してください",
                            "生成してください", "この内容でよろしい", "問題ありません",
                            "はい、大丈夫", "はい、お願い", "OK", "この内容で作成"
                        ]
                        
                        # 追加情報と思われるパターンを除外
                        additional_info_patterns = [
                            "写真", "枚", "雰囲気", "色", "デザイン", "レイアウト"
                        ]
                        
                        # 追加情報パターンが含まれている場合は承認と判定しない
                        if any(pattern in text for pattern in additional_info_patterns):
                            logger.info(f"追加情報と判定（承認ではない）: {text[:50]}...")
                            return False
                        
                        # 明確な承認パターンのみ承認と判定
                        if any(pattern in text for pattern in explicit_approval_patterns):
                            logger.info(f"ユーザー承認を検出: {text[:50]}...")
                            return True
                            
            return False
            
        except Exception as e:
            logger.error(f"ユーザー承認検出エラー: {e}")
            return False

    async def _log_session_state_for_debug(self, ctx: InvocationContext):
        """強化されたセッション状態デバッグ機能"""
        try:
            logger.info("\n" + "="*80)
            logger.info("🔍 ADKセッション状態詳細デバッグ開始")
            logger.info("="*80)
            
            if not hasattr(ctx, "session"):
                logger.error("❌ ctx.sessionオブジェクトが存在しません")
                return
                
            if not hasattr(ctx.session, "state"):
                logger.error("❌ ctx.session.stateオブジェクトが存在しません")
                return
            
            # セッション基本情報
            if hasattr(ctx.session, "session_id"):
                logger.info(f"📋 セッションID: {ctx.session.session_id}")
            if hasattr(ctx.session, "user_id"):
                logger.info(f"👤 ユーザーID: {ctx.session.user_id}")
            
            # セッション状態詳細
            session_state = ctx.session.state
            if session_state:
                all_keys = list(session_state.keys())
                logger.info(f"🔑 セッション状態キー数: {len(all_keys)}")
                logger.info(f"🔑 セッション状態キー一覧: {all_keys}")
                
                logger.info("\n📊 各キーの詳細情報:")
                logger.info("-" * 60)
                
                # 各キーの詳細確認
                for key in all_keys:
                    value = session_state.get(key)
                    value_type = type(value).__name__
                    
                    if isinstance(value, str):
                        value_length = len(value)
                        value_preview = value[:100] + "..." if len(value) > 100 else value
                        logger.info(f"  {key:20} | {value_type:10} | {value_length:6} chars | {value_preview}")
                    elif isinstance(value, (dict, list)):
                        value_length = len(value)
                        logger.info(f"  {key:20} | {value_type:10} | {value_length:6} items | {str(value)[:100]}...")
                    else:
                        logger.info(f"  {key:20} | {value_type:10} | {str(value)[:50]}...")
                
                logger.info("-" * 60)
                
                # 重要なキーの特別確認
                critical_keys = ["outline", "newsletter_json", "user_data_json", "html"]
                logger.info("\n🎯 重要キーの検証:")
                
                for key in critical_keys:
                    if key in session_state:
                        value = session_state[key]
                        if value:
                            logger.info(f"  ✅ {key}: 存在（{len(str(value))} 文字）")
                            
                            # JSONキーの場合は構造確認
                            if key in ["outline", "newsletter_json", "user_data_json"]:
                                try:
                                    import json as json_module
                                    parsed = json_module.loads(str(value))
                                    school_name = parsed.get('school_name', 'N/A')
                                    grade = parsed.get('grade', 'N/A')
                                    author = parsed.get('author', {})
                                    author_name = author.get('name', 'N/A') if isinstance(author, dict) else 'N/A'
                                    logger.info(f"      📋 内容: {school_name} {grade} 発行者:{author_name}")
                                except Exception as parse_error:
                                    logger.warning(f"      ⚠️  JSON解析エラー: {parse_error}")
                        else:
                            logger.warning(f"  ⚠️  {key}: 存在するが空")
                    else:
                        logger.warning(f"  ❌ {key}: 存在しない")
                        
            else:
                logger.error("❌ セッション状態が空またはNoneです")
                
            logger.info("="*80)
            logger.info("🔍 ADKセッション状態詳細デバッグ完了")
            logger.info("="*80 + "\n")
            
        except Exception as e:
            logger.error(f"❌ セッション状態デバッグ中にエラー: {e}")
            import traceback
            logger.error(f"詳細エラー: {traceback.format_exc()}")

    async def _invoke_layout_agent_directly(self, ctx: InvocationContext):
        """LayoutAgentを直接呼び出し（transfer_to_agentを使わずに）"""
        try:
            logger.info("=== LayoutAgent直接呼び出し開始 ===")
            
            # sub_agentsからLayoutAgentを取得
            layout_agent = None
            for agent in self.sub_agents:
                if agent.name == "layout_agent":
                    layout_agent = agent
                    break
            
            if layout_agent is None:
                logger.error("LayoutAgentがsub_agentsに見つかりません")
                return
            
            logger.info(f"LayoutAgent取得成功: {layout_agent.name}")
            
            # 同一セッション状態でLayoutAgentを実行
            logger.info(f"LayoutAgent実行前のセッション状態: {list(ctx.session.state.keys())}")
            
            # LayoutAgentを直接実行
            async for event in layout_agent._run_async_impl(ctx):
                # LayoutAgentのイベントをそのまま通す
                yield event
                
            logger.info("LayoutAgent直接実行完了")
            
        except Exception as e:
            logger.error(f"LayoutAgent直接呼び出しエラー: {e}")
            import traceback
            logger.error(f"詳細エラー: {traceback.format_exc()}")


def create_main_conversation_agent() -> MainConversationAgent:
    """MainConversationAgentのインスタンスを生成するファクトリ関数。"""
    return MainConversationAgent()


# ADK Web UI用のroot_agent変数
root_agent = create_main_conversation_agent()