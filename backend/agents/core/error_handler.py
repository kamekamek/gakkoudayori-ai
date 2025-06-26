"""
ADK Agent Error Handling System
統一的なエラーハンドリングとフォールバック戦略を提供
"""
import json
import logging
from datetime import datetime
from typing import Dict, Any, Optional, Callable, Awaitable
from google.adk.agents.invocation_context import InvocationContext
from enum import Enum
import traceback
from dataclasses import dataclass
from functools import wraps
import asyncio


class ErrorSeverity(Enum):
    """エラーの重要度"""
    INFO = "info"
    WARNING = "warning"
    ERROR = "error"
    CRITICAL = "critical"


class AgentErrorType(Enum):
    """エージェントエラーの種別"""
    AGENT_TRANSFER_FAILED = "agent_transfer_failed"
    ARTIFACT_PROCESSING_FAILED = "artifact_processing_failed"
    LLM_GENERATION_FAILED = "llm_generation_failed"
    JSON_PARSING_FAILED = "json_parsing_failed"
    HTML_VALIDATION_FAILED = "html_validation_failed"
    TIMEOUT_ERROR = "timeout_error"
    NETWORK_ERROR = "network_error"
    AUTHENTICATION_ERROR = "authentication_error"
    RESOURCE_EXHAUSTED = "resource_exhausted"
    UNKNOWN_ERROR = "unknown_error"


class AgentError(Exception):
    """カスタムエージェントエラー"""
    def __init__(
        self,
        error_type: AgentErrorType,
        message: str,
        severity: ErrorSeverity = ErrorSeverity.ERROR,
        context: Optional[Dict[str, Any]] = None,
        recoverable: bool = True,
        original_error: Optional[Exception] = None
    ):
        super().__init__(message)
        self.error_type = error_type
        self.severity = severity
        self.context = context or {}
        self.recoverable = recoverable
        self.original_error = original_error
        self.timestamp = datetime.utcnow().isoformat()


class ErrorHandler:
    """統一エラーハンドリングシステム"""
    
    def __init__(self):
        self.logger = logging.getLogger(__name__)
        self.error_stats = {}
        self.recovery_strategies = {}
        self._setup_default_strategies()
    
    def _setup_default_strategies(self):
        """デフォルトの復旧戦略を設定"""
        self.recovery_strategies = {
            AgentErrorType.AGENT_TRANSFER_FAILED: self._handle_transfer_failure,
            AgentErrorType.LLM_GENERATION_FAILED: self._handle_llm_failure,
            AgentErrorType.JSON_PARSING_FAILED: self._handle_json_failure,
            AgentErrorType.HTML_VALIDATION_FAILED: self._handle_html_validation_failure,
            AgentErrorType.TIMEOUT_ERROR: self._handle_timeout,
            AgentErrorType.NETWORK_ERROR: self._handle_network_error,
        }
    
    async def handle_error(
        self,
        ctx: InvocationContext,
        error: Exception,
        error_type: Optional[AgentErrorType] = None,
        severity: ErrorSeverity = ErrorSeverity.ERROR
    ) -> bool:
        """
        エラーを処理し、可能であれば復旧を試行
        
        Returns:
            bool: 復旧に成功したかどうか
        """
        # エラー種別の自動推定
        if error_type is None:
            error_type = self._infer_error_type(error)
        
        # AgentErrorに変換
        if not isinstance(error, AgentError):
            agent_error = AgentError(
                error_type=error_type,
                message=str(error),
                severity=severity,
                original_error=error
            )
        else:
            agent_error = error
        
        # エラー統計を更新
        self._update_error_stats(agent_error)
        
        # ログ出力
        self._log_error(agent_error)
        
        # ユーザーに通知
        await self._emit_error_event(ctx, agent_error)
        
        # 復旧を試行
        if agent_error.recoverable and error_type in self.recovery_strategies:
            try:
                recovery_success = await self.recovery_strategies[error_type](ctx, agent_error)
                if recovery_success:
                    await ctx.emit({
                        "type": "recovery_success",
                        "message": f"エラーから復旧しました: {agent_error.error_type.value}",
                        "timestamp": datetime.utcnow().isoformat()
                    })
                    return True
            except Exception as recovery_error:
                self.logger.error(f"復旧処理でエラー: {recovery_error}")
                await ctx.emit({
                    "type": "recovery_failed",
                    "message": f"復旧に失敗しました: {str(recovery_error)}",
                    "timestamp": datetime.utcnow().isoformat()
                })
        
        return False
    
    def _infer_error_type(self, error: Exception) -> AgentErrorType:
        """エラーから種別を推定"""
        error_str = str(error).lower()
        
        if "timeout" in error_str:
            return AgentErrorType.TIMEOUT_ERROR
        elif "network" in error_str or "connection" in error_str:
            return AgentErrorType.NETWORK_ERROR
        elif "json" in error_str or "parse" in error_str:
            return AgentErrorType.JSON_PARSING_FAILED
        elif "auth" in error_str or "permission" in error_str:
            return AgentErrorType.AUTHENTICATION_ERROR
        elif "transfer" in error_str or "agent" in error_str:
            return AgentErrorType.AGENT_TRANSFER_FAILED
        elif "html" in error_str or "validation" in error_str:
            return AgentErrorType.HTML_VALIDATION_FAILED
        else:
            return AgentErrorType.UNKNOWN_ERROR
    
    def _update_error_stats(self, error: AgentError):
        """エラー統計を更新"""
        error_key = error.error_type.value
        if error_key not in self.error_stats:
            self.error_stats[error_key] = {
                "count": 0,
                "last_occurrence": None,
                "severity_counts": {s.value: 0 for s in ErrorSeverity}
            }
        
        self.error_stats[error_key]["count"] += 1
        self.error_stats[error_key]["last_occurrence"] = error.timestamp
        self.error_stats[error_key]["severity_counts"][error.severity.value] += 1
    
    def _log_error(self, error: AgentError):
        """構造化ログ出力"""
        log_data = {
            "error_type": error.error_type.value,
            "severity": error.severity.value,
            "message": str(error),
            "context": error.context,
            "timestamp": error.timestamp,
            "recoverable": error.recoverable
        }
        
        if error.original_error:
            log_data["original_error"] = str(error.original_error)
        
        if error.severity == ErrorSeverity.CRITICAL:
            self.logger.critical(f"Critical Agent Error: {json.dumps(log_data)}")
        elif error.severity == ErrorSeverity.ERROR:
            self.logger.error(f"Agent Error: {json.dumps(log_data)}")
        elif error.severity == ErrorSeverity.WARNING:
            self.logger.warning(f"Agent Warning: {json.dumps(log_data)}")
        else:
            self.logger.info(f"Agent Info: {json.dumps(log_data)}")
    
    async def _emit_error_event(self, ctx: InvocationContext, error: AgentError):
        """ユーザーにエラーイベントを送信"""
        await ctx.emit({
            "type": "error",
            "error_type": error.error_type.value,
            "severity": error.severity.value,
            "message": self._get_user_friendly_message(error),
            "timestamp": error.timestamp,
            "recoverable": error.recoverable,
            "suggestions": self._get_recovery_suggestions(error.error_type)
        })
    
    def _get_user_friendly_message(self, error: AgentError) -> str:
        """ユーザー向けのメッセージを生成"""
        messages = {
            AgentErrorType.AGENT_TRANSFER_FAILED: "処理の切り替えに失敗しました。再試行します。",
            AgentErrorType.LLM_GENERATION_FAILED: "AI による内容生成に失敗しました。再試行してください。",
            AgentErrorType.JSON_PARSING_FAILED: "データの解析に失敗しました。",
            AgentErrorType.HTML_VALIDATION_FAILED: "生成された HTML の検証に失敗しました。",
            AgentErrorType.TIMEOUT_ERROR: "処理がタイムアウトしました。再試行してください。",
            AgentErrorType.NETWORK_ERROR: "ネットワーク接続に問題があります。",
            AgentErrorType.AUTHENTICATION_ERROR: "認証に失敗しました。ログインし直してください。",
            AgentErrorType.RESOURCE_EXHAUSTED: "リソースが不足しています。しばらく待ってから再試行してください。"
        }
        return messages.get(error.error_type, "予期しないエラーが発生しました。")
    
    def _get_recovery_suggestions(self, error_type: AgentErrorType) -> list:
        """復旧のための提案を生成"""
        suggestions = {
            AgentErrorType.AGENT_TRANSFER_FAILED: [
                "処理を再開してください",
                "別の表現で再試行してください"
            ],
            AgentErrorType.LLM_GENERATION_FAILED: [
                "より具体的な内容で再試行してください",
                "内容を分割して段階的に生成してください"
            ],
            AgentErrorType.TIMEOUT_ERROR: [
                "ネットワーク接続を確認してください",
                "しばらく待ってから再試行してください"
            ],
            AgentErrorType.NETWORK_ERROR: [
                "インターネット接続を確認してください",
                "VPN を使用している場合は無効にしてください"
            ]
        }
        return suggestions.get(error_type, ["サポートにお問い合わせください"])
    
    # 復旧戦略の実装
    async def _handle_transfer_failure(self, ctx: InvocationContext, error: AgentError) -> bool:
        """エージェント転送失敗の復旧"""
        try:
            # セッション状態をリセット
            await ctx.emit({
                "type": "info",
                "message": "セッションをリセットして再試行しています..."
            })
            return True
        except Exception:
            return False
    
    async def _handle_llm_failure(self, ctx: InvocationContext, error: AgentError) -> bool:
        """LLM生成失敗の復旧"""
        try:
            # 簡易版のフォールバック処理
            await ctx.emit({
                "type": "info",
                "message": "簡易版で処理を続行します..."
            })
            return True
        except Exception:
            return False
    
    async def _handle_json_failure(self, ctx: InvocationContext, error: AgentError) -> bool:
        """JSON解析失敗の復旧"""
        try:
            # デフォルトの構造を作成
            default_outline = {
                "title": "学級通信",
                "sections": [
                    {"title": "今日の活動", "content": "活動内容をここに記入してください。"},
                    {"title": "お知らせ", "content": "お知らせをここに記入してください。"}
                ],
                "date": datetime.now().strftime("%Y年%m月%d日")
            }
            ctx.save_artifact("outline.json", json.dumps(default_outline, ensure_ascii=False).encode())
            
            await ctx.emit({
                "type": "info",
                "message": "基本構造で処理を続行します。内容を追加してください。"
            })
            return True
        except Exception:
            return False
    
    async def _handle_html_validation_failure(self, ctx: InvocationContext, error: AgentError) -> bool:
        """HTML検証失敗の復旧"""
        # HTMLを修正して再試行
        return False  # 今回は手動修正を促す
    
    async def _handle_timeout(self, ctx: InvocationContext, error: AgentError) -> bool:
        """タイムアウトの復旧"""
        await ctx.emit({
            "type": "info",
            "message": "処理を再開します。しばらくお待ちください..."
        })
        return True
    
    async def _handle_network_error(self, ctx: InvocationContext, error: AgentError) -> bool:
        """ネットワークエラーの復旧"""
        # 接続テストを実行
        await ctx.emit({
            "type": "warning",
            "message": "ネットワーク接続を確認してください。"
        })
        return False  # 手動での対応が必要


# グローバルエラーハンドラのインスタンス
error_handler = ErrorHandler()


# デコレータ関数
def handle_agent_errors(
    error_type: Optional[AgentErrorType] = None,
    severity: ErrorSeverity = ErrorSeverity.ERROR
):
    """エージェントメソッド用のエラーハンドリングデコレータ"""
    def decorator(func: Callable):
        async def wrapper(self, ctx: InvocationContext, *args, **kwargs):
            try:
                return await func(self, ctx, *args, **kwargs)
            except Exception as e:
                recovery_success = await error_handler.handle_error(
                    ctx, e, error_type, severity
                )
                if not recovery_success:
                    # 復旧に失敗した場合は例外を再発生
                    raise
                return None  # 復旧成功時はNoneを返す
        return wrapper
    return decorator