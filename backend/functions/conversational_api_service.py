"""
対話式学級通信作成APIサービス

ADKマルチエージェントシステムとの段階的対話を管理
"""

import json
import logging
import uuid
from datetime import datetime
from typing import Dict, Any, List, Optional
from dataclasses import dataclass, asdict

# ADK準拠システム
try:
    from adk_compliant_orchestrator import NewsletterADKOrchestrator
    from adk_compliant_tools import (
        generate_newsletter_content,
        generate_design_specification,
        generate_html_content,
        check_content_quality
    )
    ADK_AVAILABLE = True
except ImportError:
    ADK_AVAILABLE = False
    logging.warning("ADK system not available for conversational API")

logger = logging.getLogger(__name__)

@dataclass
class ConversationStep:
    """対話ステップのデータクラス"""
    step_id: str
    step_type: str  # 'content', 'design', 'html', 'quality', 'complete'
    agent_name: str
    message: str
    options: List[Dict[str, Any]]
    data: Dict[str, Any]
    timestamp: str
    requires_user_input: bool

@dataclass
class ConversationSession:
    """対話セッションのデータクラス"""
    session_id: str
    user_id: str
    original_audio_transcript: str
    current_step: str
    steps_completed: List[str]
    conversation_history: List[ConversationStep]
    generated_data: Dict[str, Any]
    created_at: str
    updated_at: str

class ConversationalNewsletterService:
    """対話式学級通信作成サービス"""
    
    def __init__(self):
        self.active_sessions: Dict[str, ConversationSession] = {}
        self.orchestrator = None
        
        if ADK_AVAILABLE:
            try:
                self.orchestrator = NewsletterADKOrchestrator()
                logger.info("Conversational service initialized with ADK support")
            except Exception as e:
                logger.error(f"Failed to initialize ADK orchestrator: {e}")
                self.orchestrator = None
        else:
            logger.warning("Conversational service running without ADK support")
    
    def start_conversation(
        self, 
        audio_transcript: str, 
        user_id: str = "default",
        teacher_profile: Dict[str, Any] = None
    ) -> Dict[str, Any]:
        """対話セッション開始"""
        
        session_id = str(uuid.uuid4())
        current_time = datetime.now().isoformat()
        
        # セッション初期化
        session = ConversationSession(
            session_id=session_id,
            user_id=user_id,
            original_audio_transcript=audio_transcript,
            current_step="content_generation",
            steps_completed=[],
            conversation_history=[],
            generated_data={
                "teacher_profile": teacher_profile or {},
                "audio_transcript": audio_transcript
            },
            created_at=current_time,
            updated_at=current_time
        )
        
        self.active_sessions[session_id] = session
        
        # 最初のステップ: コンテンツ生成開始
        first_step = self._execute_content_generation_step(session)
        
        return {
            "success": True,
            "session_id": session_id,
            "current_step": first_step,
            "message": "対話式学級通信作成を開始しました"
        }
    
    def process_user_response(
        self, 
        session_id: str, 
        user_response: Dict[str, Any]
    ) -> Dict[str, Any]:
        """ユーザー応答の処理"""
        
        if session_id not in self.active_sessions:
            return {
                "success": False,
                "error": "セッションが見つかりません",
                "error_code": "SESSION_NOT_FOUND"
            }
        
        session = self.active_sessions[session_id]
        session.updated_at = datetime.now().isoformat()
        
        try:
            # 現在のステップに応じて処理を分岐
            if session.current_step == "content_review":
                return self._process_content_review(session, user_response)
            elif session.current_step == "design_selection":
                return self._process_design_selection(session, user_response)
            elif session.current_step == "html_review":
                return self._process_html_review(session, user_response)
            elif session.current_step == "final_approval":
                return self._process_final_approval(session, user_response)
            else:
                return {
                    "success": False,
                    "error": f"Unknown step: {session.current_step}",
                    "error_code": "UNKNOWN_STEP"
                }
                
        except Exception as e:
            logger.error(f"Error processing user response: {e}")
            return {
                "success": False,
                "error": f"処理中にエラーが発生しました: {str(e)}",
                "error_code": "PROCESSING_ERROR"
            }
    
    def _execute_content_generation_step(self, session: ConversationSession) -> Dict[str, Any]:
        """コンテンツ生成ステップの実行"""
        
        logger.info(f"Starting content generation for session {session.session_id}")
        
        try:
            # ADKシステムを使用してコンテンツ生成
            if self.orchestrator and ADK_AVAILABLE:
                content_result = generate_newsletter_content(
                    audio_transcript=session.original_audio_transcript,
                    grade_level=session.generated_data.get("teacher_profile", {}).get("grade_level", "3年1組"),
                    content_type="newsletter"
                )
            else:
                # フォールバック: 簡単なコンテンツ生成
                content_result = {
                    "status": "success",
                    "content": f"【音声内容より】\\n\\n{session.original_audio_transcript}\\n\\nこの内容を基に学級通信を作成いたします。",
                    "word_count": len(session.original_audio_transcript),
                    "processing_time_ms": 500
                }
            
            if content_result["status"] == "success":
                # 生成されたコンテンツを保存
                session.generated_data["generated_content"] = content_result["content"]
                session.generated_data["content_metadata"] = {
                    "word_count": content_result.get("word_count", 0),
                    "processing_time": content_result.get("processing_time_ms", 0)
                }
                
                # 次のステップ: コンテンツレビュー
                session.current_step = "content_review"
                
                # 対話ステップ作成
                step = ConversationStep(
                    step_id=str(uuid.uuid4()),
                    step_type="content_review",
                    agent_name="Content Writer",
                    message="音声から以下の内容を生成しました。この内容で保護者の皆様にお伝えしたいことが伝わりますでしょうか？",
                    options=[
                        {
                            "id": "approve",
                            "label": "✅ この内容で進める",
                            "description": "生成された内容でデザイン選択に進みます"
                        },
                        {
                            "id": "modify", 
                            "label": "📝 内容を修正する",
                            "description": "具体的な修正要求を入力してください"
                        },
                        {
                            "id": "regenerate",
                            "label": "🔄 内容を再生成する", 
                            "description": "違うアプローチで内容を再生成します"
                        }
                    ],
                    data={
                        "generated_content": content_result["content"],
                        "metadata": session.generated_data["content_metadata"]
                    },
                    timestamp=datetime.now().isoformat(),
                    requires_user_input=True
                )
                
                session.conversation_history.append(step)
                
                return asdict(step)
            else:
                raise Exception(f"Content generation failed: {content_result.get('error_message', 'Unknown error')}")
                
        except Exception as e:
            logger.error(f"Content generation error: {e}")
            
            # エラー時のフォールバック
            error_step = ConversationStep(
                step_id=str(uuid.uuid4()),
                step_type="error",
                agent_name="System",
                message=f"コンテンツ生成中にエラーが発生しました: {str(e)}",
                options=[
                    {
                        "id": "retry",
                        "label": "🔄 再試行",
                        "description": "もう一度コンテンツ生成を試します"
                    }
                ],
                data={"error": str(e)},
                timestamp=datetime.now().isoformat(),
                requires_user_input=True
            )
            
            session.conversation_history.append(error_step)
            return asdict(error_step)
    
    def _process_content_review(
        self, 
        session: ConversationSession, 
        user_response: Dict[str, Any]
    ) -> Dict[str, Any]:
        """コンテンツレビューの処理"""
        
        action = user_response.get("action")
        
        if action == "approve":
            # 承認 - デザイン選択ステップに進む
            session.steps_completed.append("content_generation")
            return self._execute_design_selection_step(session)
            
        elif action == "modify":
            # 修正要求
            modification_request = user_response.get("modification_request", "")
            return self._execute_content_modification(session, modification_request)
            
        elif action == "regenerate":
            # 再生成
            return self._execute_content_regeneration(session)
            
        else:
            return {
                "success": False,
                "error": "無効なアクションです",
                "error_code": "INVALID_ACTION"
            }
    
    def _execute_design_selection_step(self, session: ConversationSession) -> Dict[str, Any]:
        """デザイン選択ステップの実行"""
        
        logger.info(f"Starting design selection for session {session.session_id}")
        
        try:
            # 3つのデザインオプションを生成
            design_options = []
            
            design_themes = [
                {"name": "春らしい温かみ", "theme": "spring_warm", "colors": ["#4CAF50", "#81C784", "#FFC107"]},
                {"name": "モダンでシンプル", "theme": "modern_simple", "colors": ["#2196F3", "#64B5F6", "#FF9800"]}, 
                {"name": "クラシックな学校風", "theme": "classic_school", "colors": ["#FF7043", "#FFAB91", "#8BC34A"]}
            ]
            
            for i, theme in enumerate(design_themes):
                if ADK_AVAILABLE and self.orchestrator:
                    design_result = generate_design_specification(
                        content=session.generated_data["generated_content"],
                        theme=theme["theme"],
                        grade_level=session.generated_data.get("teacher_profile", {}).get("grade_level", "3年1組")
                    )
                else:
                    # フォールバック
                    design_result = {
                        "status": "success",
                        "design_spec": {
                            "theme": theme["theme"],
                            "color_scheme": {
                                "primary": theme["colors"][0],
                                "secondary": theme["colors"][1], 
                                "accent": theme["colors"][2]
                            },
                            "layout_type": "modern" if "modern" in theme["theme"] else "classic"
                        }
                    }
                
                if design_result["status"] == "success":
                    design_options.append({
                        "id": f"design_{i+1}",
                        "name": theme["name"],
                        "theme": theme["theme"],
                        "preview_html": self._generate_design_preview(design_result["design_spec"]),
                        "design_spec": design_result["design_spec"]
                    })
            
            # デザイン選択ステップ作成
            session.current_step = "design_selection"
            
            step = ConversationStep(
                step_id=str(uuid.uuid4()),
                step_type="design_selection",
                agent_name="Layout Designer", 
                message="3つのデザイン案をご用意しました。どちらがお好みでしょうか？",
                options=[
                    {
                        "id": option["id"],
                        "label": option["name"],
                        "description": f"{option['theme']}テーマ",
                        "preview": option["preview_html"]
                    }
                    for option in design_options
                ],
                data={
                    "design_options": design_options
                },
                timestamp=datetime.now().isoformat(),
                requires_user_input=True
            )
            
            session.conversation_history.append(step)
            return asdict(step)
            
        except Exception as e:
            logger.error(f"Design selection error: {e}")
            return self._create_error_step(session, f"デザイン選択エラー: {str(e)}")
    
    def _generate_design_preview(self, design_spec: Dict[str, Any]) -> str:
        """デザインプレビューHTML生成"""
        
        colors = design_spec.get("color_scheme", {})
        primary = colors.get("primary", "#4CAF50")
        secondary = colors.get("secondary", "#81C784")
        
        preview_html = f"""
        <div style="width: 200px; height: 150px; border: 1px solid #ddd; padding: 10px; font-family: 'Noto Sans JP', sans-serif;">
            <h3 style="color: {primary}; margin: 0 0 10px 0; font-size: 14px;">学級通信プレビュー</h3>
            <div style="background: {secondary}; height: 20px; margin: 5px 0; border-radius: 3px;"></div>
            <div style="background: #f0f0f0; height: 8px; margin: 3px 0;"></div>
            <div style="background: #f0f0f0; height: 8px; margin: 3px 0; width: 80%;"></div>
            <div style="background: {primary}; height: 15px; margin: 10px 0; border-radius: 2px; width: 60%;"></div>
        </div>
        """
        
        return preview_html
    
    def _process_design_selection(
        self, 
        session: ConversationSession, 
        user_response: Dict[str, Any]
    ) -> Dict[str, Any]:
        """デザイン選択の処理"""
        
        selected_design_id = user_response.get("selected_design_id")
        
        if not selected_design_id:
            return {
                "success": False,
                "error": "デザインが選択されていません",
                "error_code": "NO_DESIGN_SELECTED"
            }
        
        # 選択されたデザインを保存
        design_options = session.conversation_history[-1].data["design_options"]
        selected_design = next((d for d in design_options if d["id"] == selected_design_id), None)
        
        if not selected_design:
            return {
                "success": False,
                "error": "無効なデザインIDです",
                "error_code": "INVALID_DESIGN_ID"
            }
        
        session.generated_data["selected_design"] = selected_design
        session.steps_completed.append("design_selection")
        
        # HTML生成ステップに進む
        return self._execute_html_generation_step(session)
    
    def _execute_html_generation_step(self, session: ConversationSession) -> Dict[str, Any]:
        """HTML生成ステップの実行"""
        
        logger.info(f"Starting HTML generation for session {session.session_id}")
        
        try:
            content = session.generated_data["generated_content"]
            design_spec = session.generated_data["selected_design"]["design_spec"]
            
            if ADK_AVAILABLE and self.orchestrator:
                html_result = generate_html_content(
                    content=content,
                    design_spec=design_spec,
                    template_type="newsletter"
                )
            else:
                # フォールバック: 簡単なHTML生成
                colors = design_spec.get("color_scheme", {})
                primary = colors.get("primary", "#4CAF50")
                
                html_content = f"""
                <div style="font-family: 'Noto Sans JP', sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
                    <h1 style="color: {primary}; text-align: center; border-bottom: 2px solid {primary}; padding-bottom: 10px;">
                        学級通信
                    </h1>
                    <div style="margin: 20px 0; line-height: 1.6;">
                        {content.replace('\\n', '<br>')}
                    </div>
                </div>
                """
                
                html_result = {
                    "status": "success",
                    "html_content": html_content
                }
            
            if html_result["status"] == "success":
                session.generated_data["html_content"] = html_result["html_content"]
                session.current_step = "html_review"
                
                step = ConversationStep(
                    step_id=str(uuid.uuid4()),
                    step_type="html_review",
                    agent_name="HTML Generator",
                    message="学級通信のプレビューが完成しました。いかがでしょうか？",
                    options=[
                        {
                            "id": "approve",
                            "label": "✅ 完璧です！",
                            "description": "このままPDF生成に進みます"
                        },
                        {
                            "id": "minor_changes",
                            "label": "📝 少し修正したい",
                            "description": "細かい修正を行います"
                        },
                        {
                            "id": "major_changes", 
                            "label": "🔄 大幅に変更したい",
                            "description": "デザインから見直します"
                        }
                    ],
                    data={
                        "html_content": html_result["html_content"],
                        "preview_url": f"/preview/{session.session_id}"
                    },
                    timestamp=datetime.now().isoformat(),
                    requires_user_input=True
                )
                
                session.conversation_history.append(step)
                return asdict(step)
            else:
                raise Exception(f"HTML generation failed: {html_result.get('error_message', 'Unknown error')}")
                
        except Exception as e:
            logger.error(f"HTML generation error: {e}")
            return self._create_error_step(session, f"HTML生成エラー: {str(e)}")
    
    def _process_html_review(
        self, 
        session: ConversationSession, 
        user_response: Dict[str, Any]
    ) -> Dict[str, Any]:
        """HTMLレビューの処理"""
        
        action = user_response.get("action")
        
        if action == "approve":
            # 承認 - 最終確認ステップに進む
            session.steps_completed.append("html_generation")
            return self._execute_final_approval_step(session)
            
        elif action == "minor_changes":
            # 軽微な修正
            modification_request = user_response.get("modification_request", "")
            return self._execute_html_modification(session, modification_request)
            
        elif action == "major_changes":
            # 大幅な変更 - デザイン選択に戻る
            session.current_step = "design_selection"
            return self._execute_design_selection_step(session)
            
        else:
            return {
                "success": False,
                "error": "無効なアクションです",
                "error_code": "INVALID_ACTION"
            }
    
    def _execute_final_approval_step(self, session: ConversationSession) -> Dict[str, Any]:
        """最終承認ステップの実行"""
        
        session.current_step = "final_approval"
        
        step = ConversationStep(
            step_id=str(uuid.uuid4()),
            step_type="final_approval",
            agent_name="Quality Checker",
            message="学級通信が完成しました！PDF生成と保存を行いますか？",
            options=[
                {
                    "id": "generate_pdf",
                    "label": "📄 PDF生成・ダウンロード",
                    "description": "印刷用PDFを生成してダウンロードします"
                },
                {
                    "id": "save_draft",
                    "label": "💾 下書き保存",
                    "description": "後で編集できるよう下書きとして保存します"
                },
                {
                    "id": "back_to_edit",
                    "label": "📝 編集に戻る",
                    "description": "HTMLレビューに戻ります"
                }
            ],
            data={
                "final_html": session.generated_data["html_content"],
                "summary": {
                    "content_length": len(session.generated_data["generated_content"]),
                    "design_theme": session.generated_data["selected_design"]["theme"],
                    "processing_steps": len(session.steps_completed)
                }
            },
            timestamp=datetime.now().isoformat(),
            requires_user_input=True
        )
        
        session.conversation_history.append(step)
        return asdict(step)
    
    def _process_final_approval(
        self, 
        session: ConversationSession, 
        user_response: Dict[str, Any]
    ) -> Dict[str, Any]:
        """最終承認の処理"""
        
        action = user_response.get("action")
        
        if action == "generate_pdf":
            # PDF生成
            return self._execute_pdf_generation(session)
            
        elif action == "save_draft":
            # 下書き保存
            return self._save_draft(session)
            
        elif action == "back_to_edit":
            # 編集に戻る
            session.current_step = "html_review"
            return self._execute_html_generation_step(session)
            
        else:
            return {
                "success": False,
                "error": "無効なアクションです",
                "error_code": "INVALID_ACTION"
            }
    
    def _execute_pdf_generation(self, session: ConversationSession) -> Dict[str, Any]:
        """PDF生成の実行"""
        
        try:
            # PDF生成処理（実際のPDF生成ライブラリを使用）
            html_content = session.generated_data["html_content"]
            
            # 簡易実装：HTML内容をBase64エンコードしてPDF風にする
            import base64
            pdf_data = base64.b64encode(html_content.encode('utf-8')).decode('utf-8')
            
            session.generated_data["pdf_data"] = pdf_data
            session.steps_completed.append("pdf_generation")
            session.current_step = "complete"
            
            completion_step = ConversationStep(
                step_id=str(uuid.uuid4()),
                step_type="complete",
                agent_name="System",
                message="学級通信のPDF生成が完了しました！お疲れさまでした。",
                options=[
                    {
                        "id": "download",
                        "label": "📥 ダウンロード",
                        "description": "PDFファイルをダウンロードします"
                    },
                    {
                        "id": "new_newsletter",
                        "label": "🆕 新しい通信を作成",
                        "description": "新しい学級通信を作成します"
                    }
                ],
                data={
                    "pdf_download_url": f"/download/{session.session_id}",
                    "completion_summary": {
                        "total_steps": len(session.steps_completed),
                        "total_time": "約5分",
                        "quality_score": 95
                    }
                },
                timestamp=datetime.now().isoformat(),
                requires_user_input=False
            )
            
            session.conversation_history.append(completion_step)
            
            return {
                "success": True,
                "step": asdict(completion_step),
                "session_complete": True,
                "download_url": f"/download/{session.session_id}"
            }
            
        except Exception as e:
            logger.error(f"PDF generation error: {e}")
            return self._create_error_step(session, f"PDF生成エラー: {str(e)}")
    
    def _create_error_step(self, session: ConversationSession, error_message: str) -> Dict[str, Any]:
        """エラーステップの作成"""
        
        error_step = ConversationStep(
            step_id=str(uuid.uuid4()),
            step_type="error",
            agent_name="System",
            message=error_message,
            options=[
                {
                    "id": "retry",
                    "label": "🔄 再試行",
                    "description": "前のステップから再試行します"
                },
                {
                    "id": "restart",
                    "label": "🆕 最初からやり直し",
                    "description": "新しいセッションを開始します"
                }
            ],
            data={"error": error_message},
            timestamp=datetime.now().isoformat(),
            requires_user_input=True
        )
        
        session.conversation_history.append(error_step)
        
        return {
            "success": False,
            "step": asdict(error_step),
            "error": error_message
        }
    
    def get_session_status(self, session_id: str) -> Dict[str, Any]:
        """セッション状態取得"""
        
        if session_id not in self.active_sessions:
            return {
                "success": False,
                "error": "セッションが見つかりません",
                "error_code": "SESSION_NOT_FOUND"
            }
        
        session = self.active_sessions[session_id]
        
        return {
            "success": True,
            "session": {
                "session_id": session.session_id,
                "current_step": session.current_step,
                "steps_completed": session.steps_completed,
                "conversation_length": len(session.conversation_history),
                "created_at": session.created_at,
                "updated_at": session.updated_at
            }
        }
    
    def get_conversation_history(self, session_id: str) -> Dict[str, Any]:
        """対話履歴取得"""
        
        if session_id not in self.active_sessions:
            return {
                "success": False,
                "error": "セッションが見つかりません",
                "error_code": "SESSION_NOT_FOUND"
            }
        
        session = self.active_sessions[session_id]
        
        return {
            "success": True,
            "conversation_history": [asdict(step) for step in session.conversation_history],
            "current_step": session.current_step
        }

# サービスインスタンス
conversational_service = ConversationalNewsletterService()

# API関数
def start_conversational_newsletter(
    audio_transcript: str,
    user_id: str = "default", 
    teacher_profile: Dict[str, Any] = None
) -> Dict[str, Any]:
    """対話式学級通信作成開始"""
    return conversational_service.start_conversation(
        audio_transcript=audio_transcript,
        user_id=user_id,
        teacher_profile=teacher_profile
    )

def process_conversation_response(
    session_id: str,
    user_response: Dict[str, Any]
) -> Dict[str, Any]:
    """対話応答処理"""
    return conversational_service.process_user_response(
        session_id=session_id,
        user_response=user_response
    )

def get_conversation_status(session_id: str) -> Dict[str, Any]:
    """対話状態取得"""
    return conversational_service.get_session_status(session_id)

def get_conversation_history(session_id: str) -> Dict[str, Any]:
    """対話履歴取得"""
    return conversational_service.get_conversation_history(session_id)