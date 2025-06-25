# Copyright 2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

from adk.agents.generation_workflow_agent import create_generation_workflow_agent
from adk.agents.validation_agent import create_validation_agent
from models.adk_models import (
    NewsletterGenerationRequest,
    NewsletterGenerationResponse,
    HTMLValidationRequest,
    HTMLValidationResponse,
)
from google.adk.sessions import Session

class NewsletterService:
    def __init__(self):
        """ニュースレターサービスの初期化"""
        self.generation_agent = create_generation_workflow_agent()
        self.validation_agent = create_validation_agent()

    def generate_newsletter(
        self, request: NewsletterGenerationRequest
    ) -> NewsletterGenerationResponse:
        """学級通信を生成する"""
        session = Session()
        # ADKエージェントは辞書形式で入力を受け取ることが多い
        agent_input = {"input": request.initial_request}
        
        # generation_workflow_agent を実行
        final_response = self.generation_agent.invoke(agent_input, session=session)

        # 仮のレスポンスマッピング
        # 実際のレスポンス構造に合わせて調整が必要
        return NewsletterGenerationResponse(
            session_id=session.session_id,
            status="completed",
            html_content=final_response.get("output", ""),
            messages=[], # 必要に応じてセッションから取得
        )

    def validate_html(self, request: HTMLValidationRequest) -> HTMLValidationResponse:
        """HTMLを検証する"""
        session = Session()
        agent_input = {"input": request.html_content}

        # validation_agent を実行
        validation_result = self.validation_agent.invoke(agent_input, session=session)
        
        # 仮のレスポンスマッピング
        # こちらも実際のレスポンス構造に合わせて詳細なマッピングが必要
        # 現時点ではモック的な応答を返す
        return HTMLValidationResponse(
            session_id=session.session_id,
            overall_score=85, # Mock
            grade="B", # Mock
            summary=validation_result.get("output", "No summary available."), # Mock
            structure={"score": 80, "issues": [], "recommendations": []}, # Mock
            accessibility={"score": 90, "issues": [], "recommendations": []}, # Mock
            performance={"score": 75, "issues": [], "recommendations": []}, # Mock
            seo={"score": 95, "issues": [], "recommendations": []}, # Mock
            printing={"score": 85, "issues": [], "recommendations": []}, # Mock
            priority_actions=[], # Mock
            compliance_status={}, # Mock
        )


newsletter_service = NewsletterService()

def get_newsletter_service() -> "NewsletterService":
    """ニュースレターサービス（シングルトン）を取得します。"""
    return newsletter_service 