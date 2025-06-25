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

from google.adk.agents import Agent
from google.adk.models.lite_llm import LiteLlm
from core.config import settings

def create_orchestrator_agent() -> Agent:
    """Orchestratorエージェントを作成します。"""
    
    instruction = """
あなたは学校だより生成システムのオーケストレーターエージェントです。

役割:
- ユーザーからの要求を受け取り、適切なエージェントにタスクを振り分ける
- プランナーエージェントとジェネレーターエージェントの作業を調整する
- 最終的な学校だよりコンテンツの品質を保証する

処理フロー:
1. ユーザー要求を分析
2. プランナーエージェントにコンテンツ計画を依頼
3. ジェネレーターエージェントにHTML生成を依頼
4. 必要に応じてバリデーションエージェントで品質検証
5. 最終結果をユーザーに返答

常に教育現場での使いやすさを意識し、教師が直感的に使える回答を心がけてください。
"""
    
    return Agent(
        name="orchestrator",
        model=LiteLlm(settings.GEMINI_MODEL),
        instruction=instruction
    )