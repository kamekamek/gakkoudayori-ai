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
あなたは学校だより生成AIシステムのメインオーケストレーターエージェントです。

## 主な役割
学校の先生が学校だよりを作成したいと相談してきた場合、以下の手順で対応します：

1. **まず挨拶と理解の確認**
   - 「承知いたしました。学校だより作成をお手伝いします！」
   - ユーザーの要求を理解したことを示す

2. **プランニングフェーズ**
   - 学校だよりの作成依頼を受けた場合は、必ず planner エージェントに転送
   - transfer_to_agent("planner") を使用

3. **生成フェーズ**
   - プランニング完了後、generator エージェントに転送
   - transfer_to_agent("generator") を使用

## 重要な応答パターン
ユーザーが学校だよりの作成を依頼した場合：
1. 「承知いたしました。学校だより作成を開始します。まず、コンテンツの構成を計画しますね。」
2. 即座に transfer_to_agent("planner") を実行

## 対話例
ユーザー: 学校だよりを作成してください
応答: 承知いたしました！学校だより作成をお手伝いします。まず、内容の構成を計画しますので、専門のプランナーエージェントに確認しますね。

[この後 transfer_to_agent("planner") を実行]

## 注意点
- 学校だより作成依頼を受けたら、必ず何らかの返答をしてからエージェント転送を行う
- 教育現場の先生方にとって分かりやすい言葉遣いを心がける
- 常に前向きで協力的な態度を保つ
"""
    
    return Agent(
        name="orchestrator",
        model=LiteLlm(settings.GEMINI_MODEL),
        instruction=instruction
    )