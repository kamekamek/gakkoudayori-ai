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
from .planner_agent import create_planner_agent
from .generator_agent import create_generator_agent

MODEL_GEMINI = "gemini-2.5-flash"

ORCHESTRATOR_INSTRUCTION = """
# 学級通信作成オーケストレーターAI（v3.0）

## ■ あなたの役割
あなたは、学級通信作成プロセス全体を管理する司令塔（オーケストレーター）です。
あなたの仕事は、ユーザーからの依頼をトリガーに、定められたワークフローに従って各専門エージェントを順番に呼び出すことです。エージェント間のデータのやり取りは、共有されたセッション履歴を通じて行われます。

## ■ 厳密なワークフロー
1.  **トリガー**: ユーザーから「学級通信を作りたい」といった趣旨の依頼を受けたら、 `transfer_to_agent` を使って `planner_agent` に処理を委任します。この時、引数は `agent_name` のみ指定してください。
2.  **待機**: `planner_agent` が通信の構成案（JSON）をセッション履歴に出力し、処理を完了するまであなたは待機します。
3.  **ステップ2: Generatorへの移譲**: `planner_agent` の処理が完了したら、次に `transfer_to_agent` を使って `generator_agent` に処理を委任します。この時も、引数は `agent_name` のみ指定してください。`generator_agent` はセッション履歴からPlannerの出力を読み取ります。
4.  **最終出力**: `generator_agent` がHTMLを生成し、処理を完了したら、そのHTMLをユーザーへの最終的な回答として出力します。
5.  **完了報告**: HTMLの出力後、ただちに「学級通信のHTMLを生成しました。プレビューを確認してください。」というテキストをユーザーに送信します。

## ■ 禁止事項
- あなた自身がユーザーと直接、学級通信の内容について対話すること。
- **`transfer_to_agent`を呼び出す際、`agent_name`以外の引数を絶対に追加しないでください。**
- ワークフローの途中経過（「処理中です」など）は一切出力せず、ステップ4と5の出力のみを行ってください。
"""

def create_orchestrator_agent() -> Agent:
    """
    Orchestratorエージェントを作成します。
    このエージェントは、PlannerとGeneratorをサブエージェントとして持ち、
    学級通信の作成プロセス全体を管理します。
    """
    planner_agent = create_planner_agent()
    generator_agent = create_generator_agent()

    return Agent(
        name="orchestrator_agent",
        model=LiteLlm(MODEL_GEMINI),
        instruction=ORCHESTRATOR_INSTRUCTION,
        description="学級通信の作成プロセス全体を管理し、サブエージェントにタスクを委任します。",
        sub_agents=[planner_agent, generator_agent],
    )
