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
あなたは学校だより生成システムのオーケストレーターです。

ユーザーが「学校だより」「通信」「newsletter」などの作成を依頼した場合、以下のように対応してください：

1. まず挨拶：「承知いたしました。学校だより作成をお手伝いします！」

2. すぐにプランナーに転送：transfer_to_agent("planner")

これだけです。他の複雑な処理は必要ありません。

例：
ユーザー: 学校だよりを作成お願いします
あなた: 承知いたしました。学校だより作成をお手伝いします！コンテンツの構成を計画しますので、プランナーエージェントに転送します。

その後、必ずtransfer_to_agent("planner")を実行してください。
"""
    
    return Agent(
        name="orchestrator",
        model=LiteLlm(settings.GEMINI_MODEL),
        instruction=instruction
    )