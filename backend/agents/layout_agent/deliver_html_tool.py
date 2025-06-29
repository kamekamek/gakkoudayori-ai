"""
LayoutAgent用 HTML配信ツール
生成されたHTMLをフロントエンドに直接配信するためのADKツール
"""
import logging
import os
from typing import Optional

import httpx
from google.adk.tools import FunctionTool

logger = logging.getLogger(__name__)


class DeliverHtmlTool:
    """LayoutAgentからフロントエンドにHTMLを直接配信するツール"""

    def __init__(self):
        # FastAPIサーバーのベースURL設定
        self.base_url = os.getenv("FASTAPI_BASE_URL", "http://localhost:8081")
        self.artifact_endpoint = f"{self.base_url}/api/v1/artifacts/html"

        # 現在のセッションIDを保存するための変数
        self._current_session_id: Optional[str] = None

    def set_session_id(self, session_id: str):
        """現在のセッションIDを設定"""
        self._current_session_id = session_id
        logger.info(f"DeliverHtmlTool: セッションID設定 - {session_id}")

    async def deliver_html_to_frontend(
        self,
        html_content: str,
        artifact_type: str,
        metadata_json: str
    ) -> str:
        """
        HTMLコンテンツをフロントエンドに配信
        
        Args:
            html_content: 配信するHTMLコンテンツ
            artifact_type: アーティファクトの種類（例: newsletter）
            metadata_json: 追加のメタデータのJSON文字列（例: "{}"）
            
        Returns:
            配信結果のメッセージ
        """
        if not self._current_session_id:
            error_msg = "❌ セッションIDが設定されていません。配信に失敗しました。"
            logger.error("DeliverHtmlTool: セッションIDが未設定")
            return error_msg

        if not html_content.strip():
            error_msg = "❌ HTMLコンテンツが空です。配信をスキップします。"
            logger.warning("DeliverHtmlTool: 空のHTMLコンテンツ")
            return error_msg

        try:
            # JSON文字列をDictに変換
            import json
            try:
                metadata = json.loads(metadata_json) if metadata_json.strip() else {}
            except json.JSONDecodeError:
                logger.warning(f"Invalid metadata JSON: {metadata_json}, using empty dict")
                metadata = {}

            # FastAPI エンドポイントにHTMLを送信
            async with httpx.AsyncClient(timeout=30.0) as client:
                payload = {
                    "session_id": self._current_session_id,
                    "html_content": html_content,
                    "artifact_type": artifact_type,
                    "metadata": metadata
                }

                logger.info(f"DeliverHtmlTool: HTML配信開始 - セッション:{self._current_session_id}, サイズ:{len(html_content)}文字")

                response = await client.post(
                    self.artifact_endpoint,
                    json=payload,
                    headers={"Content-Type": "application/json"}
                )

                if response.status_code == 200:
                    result = response.json()
                    success_msg = f"✅ 学級通信をプレビューに送信しました！({result.get('content_length', 0)}文字)"
                    logger.info(f"DeliverHtmlTool: HTML配信成功 - セッション:{self._current_session_id}, サイズ:{result.get('content_length', 0)}文字")
                    return success_msg
                else:
                    error_msg = f"❌ プレビュー送信でエラーが発生しました。(HTTP {response.status_code})"
                    logger.error(f"DeliverHtmlTool: HTTP エラー - {response.status_code}: {response.text}")
                    return error_msg

        except httpx.TimeoutException:
            error_msg = "❌ プレビュー送信がタイムアウトしました。ネットワークを確認してください。"
            logger.error("DeliverHtmlTool: タイムアウトエラー")
            return error_msg

        except httpx.ConnectError:
            error_msg = "❌ バックエンドサーバーに接続できません。サーバーが起動していることを確認してください。"
            logger.error("DeliverHtmlTool: 接続エラー")
            return error_msg

        except Exception as e:
            error_msg = f"❌ 予期しないエラーが発生しました: {str(e)}"
            logger.error(f"DeliverHtmlTool: 予期しないエラー - {e}")
            return error_msg

    def create_adk_function_tool(self) -> FunctionTool:
        """ADK FunctionTool として使用可能な形式で返す"""
        return FunctionTool(func=self.deliver_html_to_frontend)


# グローバルインスタンス（LayoutAgentで使用）
html_delivery_tool = DeliverHtmlTool()
