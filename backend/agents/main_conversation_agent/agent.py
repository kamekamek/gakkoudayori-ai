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
        # LayoutAgentをサブエージェントとして設定
        from agents.layout_agent.agent import create_layout_agent
        
        layout_agent = create_layout_agent()

        super().__init__(
            name="main_conversation_agent",
            model=Gemini(model_name="gemini-2.5-pro"),
            instruction=MAIN_CONVERSATION_INSTRUCTION,
            description="ユーザーと自然な対話を行い、学級通信作成をサポートします。必要に応じてHTML生成を委譲します。",
            tools=[
                FunctionTool(get_current_date)
            ],
            sub_agents=[layout_agent],
            output_key="outline",
        )

    async def _run_async_impl(
        self, ctx: InvocationContext
    ) -> AsyncGenerator[Event, None]:
        """
        純粋な対話エージェントとして実行します。
        HTML生成は明示的なユーザー要求があった場合のみ委譲します。
        """
        try:
            logger.info("=== MainConversationAgent実行開始 ===")
            event_count = 0
            
            # 親クラスの通常のLLM対話を実行
            async for event in super()._run_async_impl(ctx):
                event_count += 1
                logger.info(f"LLMイベント #{event_count}: author={getattr(event, 'author', 'unknown')}")
                yield event

            logger.info(f"=== LLM実行完了: {event_count}個のイベント ===")
            
            # 最後に対話状態をセッションに保存
            await self._save_conversation_state(ctx)
            
            # JSON構成案が生成された場合はセッション状態に保存
            await self._check_and_save_json_from_conversation(ctx)
            
            # ユーザー承認後のHTML生成準備（条件付き実行）
            await self._prepare_html_generation_if_approved(ctx)

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
        """対話からJSON構成案を検出して保存（完全サイレント処理）"""
        try:
            logger.info("=== JSON構成案検出開始 ===")
            
            # セッション詳細情報をログ出力
            if hasattr(ctx, "session"):
                logger.info(f"セッション存在: True")
                logger.info(f"セッション属性: {dir(ctx.session)}")
                
                if hasattr(ctx.session, "session_id"):
                    logger.info(f"セッションID: {ctx.session.session_id}")
                if hasattr(ctx.session, "user_id"):
                    logger.info(f"ユーザーID: {ctx.session.user_id}")
                if hasattr(ctx.session, "state"):
                    logger.info(f"セッション状態キー: {list(ctx.session.state.keys()) if ctx.session.state else 'None'}")
            else:
                logger.warning("セッションオブジェクトが存在しません")
            
            # セッションイベントから最後のエージェント応答を取得
            if not hasattr(ctx, "session") or not hasattr(ctx.session, "events"):
                logger.warning("セッションまたはイベントが利用できません")
                return

            session_events = ctx.session.events
            if not session_events:
                logger.warning("セッションイベントが空です")
                return
            
            logger.info(f"セッションイベント数: {len(session_events)}")
            
            # イベントの詳細情報をログ出力
            for i, event in enumerate(session_events[-3:]):  # 最新の3つだけ
                logger.info(f"イベント #{i}: author={getattr(event, 'author', 'unknown')}, type={type(event)}")

            # メインエージェントが作成した最後のイベントを探す
            conversation_event = None
            for event in reversed(session_events):
                if hasattr(event, "author") and event.author == self.name:
                    conversation_event = event
                    break

            if conversation_event is None:
                return

            # イベントの内容からテキストを抽出
            llm_response_text = self._extract_text_from_event(conversation_event)
            logger.info(f"LLM応答テキスト長: {len(llm_response_text)}")
            logger.info(f"LLM応答テキスト(最初の200文字): {llm_response_text[:200]}...")

            if not llm_response_text.strip():
                logger.warning("LLM応答テキストが空です")
                return

            # JSONブロックをユーザー表示から除去し、内部処理のみ実行
            json_str = None
            cleaned_response = llm_response_text
            
            logger.info(f"JSON検索開始: 複数パターンでの検索")
            
            # パターン1: Markdownコードブロック
            if "```json" in llm_response_text and "```" in llm_response_text:
                logger.info("パターン1: ```json コードブロック検出")
                json_str = self._extract_json_from_response(llm_response_text)
                if json_str:
                    logger.info(f"抽出されたJSON長: {len(json_str)} 文字")
                    logger.info(f"抽出されたJSON(最初の300文字): {json_str[:300]}...")
                    cleaned_response = self._remove_json_blocks_from_response(llm_response_text)
            
            # パターン2: 直接JSONオブジェクト検出
            elif "{" in llm_response_text and "school_name" in llm_response_text:
                logger.info("パターン2: 直接JSONオブジェクト検出")
                json_str = self._extract_direct_json_from_response(llm_response_text)
                if json_str:
                    logger.info(f"直接抽出JSON長: {len(json_str)} 文字")
            
            # パターン3: function_call引数からJSON抽出
            elif not json_str:
                logger.info("パターン3: セッションイベントからfunction_call JSON検索")
                json_str = await self._extract_json_from_function_calls(ctx)
                if json_str:
                    logger.info(f"function_call JSON長: {len(json_str)} 文字")
            
            # JSON保存処理
            if json_str:
                logger.info(f"JSON抽出成功: {len(json_str)} 文字")
                logger.info(f"抽出されたJSON(最初の300文字): {json_str[:300]}...")
                
                # 内部保存処理（サイレント）
                await self._save_json_data(ctx, json_str)
                logger.info("JSON構成案をサイレントで保存しました（ユーザーには非表示）")
                
                # イベント内容を更新（JSONブロックを除去したクリーンなテキストに置き換え）
                await self._update_event_content_silently(ctx, conversation_event, cleaned_response)
            else:
                logger.warning("全パターンでJSON抽出に失敗しました")
            
            # ユーザー承認確認を判定
            if self._is_user_approval(cleaned_response):
                await self._mark_user_approval(ctx)

        except Exception as e:
            logger.error(f"JSON検出・保存エラー: {e}")

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
        """JSONデータをセッション状態とファイルシステムに保存"""
        try:
            logger.info(f"=== JSON保存開始 ===")
            logger.info(f"保存対象JSON長: {len(json_str)} 文字")
            
            # セッション詳細情報を強化ログで出力
            logger.info(f"InvocationContext詳細:")
            logger.info(f"  - hasattr(ctx, 'session'): {hasattr(ctx, 'session')}")
            if hasattr(ctx, "session"):
                logger.info(f"  - session type: {type(ctx.session)}")
                logger.info(f"  - hasattr(session, 'state'): {hasattr(ctx.session, 'state')}")
                logger.info(f"  - hasattr(session, 'session_id'): {hasattr(ctx.session, 'session_id')}")
                if hasattr(ctx.session, "session_id"):
                    logger.info(f"  - session_id: {ctx.session.session_id}")
                if hasattr(ctx.session, "state"):
                    logger.info(f"  - state type: {type(ctx.session.state)}")
                    logger.info(f"  - state keys before save: {list(ctx.session.state.keys()) if ctx.session.state else 'None'}")
            
            # セッション状態に保存（ADK標準）
            if hasattr(ctx, "session") and hasattr(ctx.session, "state"):
                logger.info("セッション状態への保存実行中...")
                ctx.session.state["outline"] = json_str
                logger.info("JSON構成案をセッション状態に保存完了")
                
                # 保存確認（強化版）
                saved_data = ctx.session.state.get("outline", "NOT_FOUND")
                logger.info(f"保存確認: {len(saved_data) if saved_data != 'NOT_FOUND' else 'NOT_FOUND'} 文字")
                
                # セッション状態の全キーを確認
                all_keys_after = list(ctx.session.state.keys()) if ctx.session.state else []
                logger.info(f"保存後のセッション状態全キー: {all_keys_after}")
                
                # JSON内容の詳細確認（最初の100文字）
                if saved_data != "NOT_FOUND":
                    preview = saved_data[:100] + "..." if len(saved_data) > 100 else saved_data
                    logger.info(f"保存されたJSON内容(先頭100文字): {preview}")
                    
                    # JSONの有効性確認
                    try:
                        import json as json_module
                        parsed = json_module.loads(saved_data)
                        school_name = parsed.get('school_name', 'NOT_FOUND')
                        grade = parsed.get('grade', 'NOT_FOUND') 
                        logger.info(f"JSON解析成功: school_name={school_name}, grade={grade}")
                    except Exception as parse_error:
                        logger.error(f"保存されたJSONの解析エラー: {parse_error}")
                        
            else:
                logger.error("セッション状態へのアクセスに失敗しました")
                logger.error(f"ctx attributes: {dir(ctx) if ctx else 'ctx is None'}")

            # 🚨 本番環境対応: ファイルシステム保存を無効化
            # Cloud Runでは/tmpが一時的なため、セッション状態のみに依存
            logger.info("JSON構成案をセッション状態に保存（本番環境ではファイル保存無効）")

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

    async def _prepare_html_generation_if_approved(self, ctx: InvocationContext):
        """ユーザー承認後のHTML生成準備（条件チェック強化版）"""
        try:
            if not hasattr(ctx, "session") or not hasattr(ctx.session, "state"):
                logger.warning("セッション状態が利用できません")
                return

            # 1. セッション状態にJSONが存在するかチェック
            has_json = "outline" in ctx.session.state and ctx.session.state["outline"]
            
            # 2. ユーザー承認状態をチェック
            collection_stage = ctx.session.state.get("collection_stage", "initial")
            user_approved = ctx.session.state.get("user_approved", False)
            
            # 3. 最新の対話内容からユーザー承認を検出
            user_approval_detected = await self._detect_user_approval_from_conversation(ctx)
            
            logger.info(f"HTML生成条件チェック:")
            logger.info(f"  - has_json: {has_json}")
            logger.info(f"  - collection_stage: {collection_stage}")
            logger.info(f"  - user_approved: {user_approved}")
            logger.info(f"  - user_approval_detected: {user_approval_detected}")

            # 4. すべての条件を満たした場合のみLayoutAgent実行
            if has_json and (user_approved or user_approval_detected):
                logger.info("✅ HTML生成条件をすべて満たしました - LayoutAgent呼び出し実行")
                ctx.session.state["user_approved"] = True  # 承認状態を保存
                # まだ実装しない - プロンプト修正でLayoutAgentがtransfer_to_agentで呼ばれるはず
            else:
                logger.info("❌ HTML生成条件が不足 - LayoutAgent呼び出しをスキップ")
                
        except Exception as e:
            logger.error(f"HTML生成準備エラー: {e}")

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
                        # 承認キーワードをチェック
                        approval_keywords = [
                            "はい", "大丈夫", "お願いします", "作成して", "生成して",
                            "OK", "いいです", "問題ありません", "よろしく"
                        ]
                        if any(keyword in text for keyword in approval_keywords):
                            logger.info(f"ユーザー承認を検出: {text[:50]}...")
                            return True
                            
            return False
            
        except Exception as e:
            logger.error(f"ユーザー承認検出エラー: {e}")
            return False

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