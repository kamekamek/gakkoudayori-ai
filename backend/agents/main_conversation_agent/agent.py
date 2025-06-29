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
        # MALFORMED_FUNCTION_CALL対応: 手動sub_agents呼び出しに戻す
        from agents.layout_agent.agent import create_layout_agent
        layout_agent = create_layout_agent()
        
        super().__init__(
            name="main_conversation_agent",
            model=Gemini(model_name="gemini-2.5-pro"),
            instruction=MAIN_CONVERSATION_INSTRUCTION,
            description="ユーザーと自然な対話を行い、学級通信作成をサポートします。手動でHTML生成を委譲します。",
            tools=[
                FunctionTool(get_current_date)
            ],
            sub_agents=[layout_agent],  # 手動呼び出し用
            output_key="outline",  # JSON自動保存を有効化
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
            
            # ADK推奨: LLM実行のみでoutput_keyによる自動保存に任せる
            async for event in super()._run_async_impl(ctx):
                event_count += 1
                logger.info(f"LLMイベント #{event_count}: author={getattr(event, 'author', 'unknown')}")
                
                # transfer_to_agentの実行を確認
                if hasattr(event, 'actions') and event.actions and event.actions.transfer_to_agent:
                    logger.info(f"✅ transfer_to_agent実行: {event.actions.transfer_to_agent}")
                
                yield event

            logger.info(f"=== MainConversationAgent完了: {event_count}個のイベント ===")
            
            # MALFORMED_FUNCTION_CALL対応: 手動JSON検出を復活
            await self._check_and_save_json_from_conversation(ctx)
            
            # 明示的な生成リクエストの場合のみHTML生成準備
            await self._prepare_html_generation_if_explicit_request(ctx)
            
            # HTML生成が要求された場合、LayoutAgentを実行
            if hasattr(ctx, "session") and hasattr(ctx.session, "state"):
                if ctx.session.state.get("html_generation_requested", False):
                    logger.info("=== HTML生成要求を検出 - LayoutAgent実行開始 ===")
                    
                    # フラグをクリア
                    ctx.session.state["html_generation_requested"] = False
                    
                    # LayoutAgentを直接実行してイベントをyield
                    layout_agent = None
                    for agent in self.sub_agents:
                        if agent.name == "layout_agent":
                            layout_agent = agent
                            break
                    
                    if layout_agent:
                        logger.info("LayoutAgentを直接実行します")
                        async for layout_event in layout_agent._run_async_impl(ctx):
                            logger.info(f"LayoutAgentイベント: {getattr(layout_event, 'author', 'unknown')}")
                            yield layout_event
                        logger.info("LayoutAgent実行完了")
                    else:
                        logger.error("LayoutAgentが見つかりません")
            
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

    async def _check_and_save_json_from_conversation(self, ctx: InvocationContext):
        """対話からユーザー情報を検出してJSON構成案を生成（MALFORMED_FUNCTION_CALL対応版）"""
        try:
            logger.info("=== ユーザー情報検出・JSON構築開始 ===")
            
            # セッションイベントから最後のエージェント応答を取得
            if not hasattr(ctx, "session") or not hasattr(ctx.session, "events"):
                logger.warning("セッションまたはイベントが利用できません")
                return

            session_events = ctx.session.events
            if not session_events:
                logger.warning("セッションイベントが空です")
                return
            
            # すべてのユーザー・エージェントイベントから情報を収集
            user_info = self._extract_user_info_from_conversation(session_events)
            logger.info(f"収集されたユーザー情報: {user_info}")
            
            # 情報が十分収集されている場合はJSON構築
            if self._has_sufficient_info(user_info):
                logger.info("十分な情報が収集されました - JSON構築を実行")
                
                # 手動でJSONを構築（MALFORMED_FUNCTION_CALL回避）
                json_data = await self._build_json_from_user_info(user_info)
                
                if json_data:
                    # 内部保存処理（サイレント）
                    await self._save_json_data(ctx, json_data)
                    logger.info("ユーザー情報ベースのJSON構成案を保存しました")
                    
                    # ユーザー承認状態を確認
                    if await self._detect_user_approval_from_conversation(ctx):
                        await self._mark_user_approval(ctx)
                        logger.info("ユーザー承認を検出しました")
            else:
                logger.info("情報収集が不完全です - JSON構築をスキップ")

        except Exception as e:
            logger.error(f"ユーザー情報検出・JSON構築エラー: {e}")

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

    async def _save_json_data(self, ctx: InvocationContext, json_str: str):
        """JSONデータをセッション状態に保存（永続化強化版）"""
        try:
            logger.info(f"=== JSON保存開始 ===")
            logger.info(f"保存対象JSON長: {len(json_str)} 文字")
            
            # セッション状態に保存（ADK標準）
            if hasattr(ctx, "session") and hasattr(ctx.session, "state"):
                logger.info("セッション状態への保存実行中...")
                
                # 複数のキーに同一データを保存（冗長化）
                ctx.session.state["outline"] = json_str
                ctx.session.state["newsletter_json"] = json_str  # バックアップキー
                ctx.session.state["user_data_json"] = json_str   # 追加バックアップ
                ctx.session.state["json_generated"] = True
                ctx.session.state["json_generation_timestamp"] = get_current_date()
                ctx.session.state["persistent_data_saved"] = True  # 永続化フラグ
                
                logger.info("JSON構成案をセッション状態に保存完了（冗長化）")
                
                # 保存確認（全キーをチェック）
                for key in ["outline", "newsletter_json", "user_data_json"]:
                    saved_data = ctx.session.state.get(key, "NOT_FOUND")
                    status = len(saved_data) if saved_data != 'NOT_FOUND' else 'NOT_FOUND'
                    logger.info(f"保存確認 [{key}]: {status} 文字")
                
                # 主要キー（outline）の詳細確認
                main_saved_data = ctx.session.state.get("outline", "NOT_FOUND")
                if main_saved_data != "NOT_FOUND":
                    preview = main_saved_data[:100] + "..." if len(main_saved_data) > 100 else main_saved_data
                    logger.info(f"保存されたJSON内容(先頭100文字): {preview}")
                    
                    # JSONの有効性確認
                    try:
                        import json as json_module
                        parsed = json_module.loads(main_saved_data)
                        school_name = parsed.get('school_name', 'NOT_FOUND')
                        grade = parsed.get('grade', 'NOT_FOUND') 
                        logger.info(f"✅ JSON解析成功: school_name={school_name}, grade={grade}")
                    except Exception as parse_error:
                        logger.error(f"❌ 保存されたJSONの解析エラー: {parse_error}")
                        logger.error(f"問題のあるデータ: '{main_saved_data}'")
                        
            else:
                logger.error("セッション状態へのアクセスに失敗しました")

        except Exception as e:
            logger.error(f"JSON保存エラー: {e}")
            import traceback
            logger.error(f"JSON保存エラー詳細: {traceback.format_exc()}")

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

            # セッション状態にJSONが存在するかチェック
            has_json = "outline" in ctx.session.state and ctx.session.state["outline"]
            
            # 既にHTML生成済みかチェック
            html_already_generated = ctx.session.state.get("html_generated", False)
            
            logger.info(f"HTML生成条件チェック:")
            logger.info(f"  - has_json: {has_json}")
            logger.info(f"  - html_already_generated: {html_already_generated}")

            # JSONが存在し、未生成の場合のみHTML生成を実行
            if has_json and not html_already_generated:
                logger.info("✅ 明示的な生成リクエストを受理 - HTML生成を開始")
                ctx.session.state["user_approved"] = True  # 明示的承認
                ctx.session.state["html_generation_requested"] = True  # HTML生成フラグ
                logger.info("HTML生成準備が完了しました")
            elif html_already_generated:
                logger.info("HTML生成済みのため、再生成をスキップします")
            elif not has_json:
                logger.warning("JSON構成案が見つかりません - 情報収集を続行してください")
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
        """ADK推奨パターンでのセッション状態確認（デバッグ用）"""
        try:
            if hasattr(ctx, "session") and hasattr(ctx.session, "state"):
                logger.info("=== セッション状態確認 (ADK推奨パターン) ===")
                all_keys = list(ctx.session.state.keys()) if ctx.session.state else []
                logger.info(f"セッション状態キー: {all_keys}")
                
                # output_keyによる自動保存を確認
                if "outline" in ctx.session.state:
                    outline_data = ctx.session.state["outline"]
                    logger.info(f"✅ ADK output_key保存成功: {len(str(outline_data))} 文字")
                    logger.info(f"outline内容(先頭200文字): {str(outline_data)[:200]}...")
                else:
                    logger.warning("❌ ADK output_key保存なし: 'outline'キーが見つかりません")
            else:
                logger.error("セッション状態にアクセスできません")
        except Exception as e:
            logger.error(f"セッション状態確認エラー: {e}")

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