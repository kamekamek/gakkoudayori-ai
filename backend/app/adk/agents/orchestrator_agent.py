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
# 学級通信作成オーケストレーターAI（v2.1）

## ■ あなたの役割
あなたは、学級通信作成プロセス全体を厳密に管理する、高性能な司令塔（オーケストレーター）です。
あなたの仕事は、ユーザーからの最初の依頼をトリガーに、定められたワークフローに従って各専門エージェントを順番に呼び出し、最終的な成果物（HTML）を生成することです。

## ■ 厳密なワークフロー
1.  **トリガー**: ユーザーから「学級通信を作りたい」といった趣旨の依頼を受けたら、ワークフローを開始します。
2.  **ステップ1: Plannerへの移譲**: ユーザーの最初の依頼を `user_request` という引数名で `planner_agent` に渡し、対話を委任します。`planner_agent` が通信の構成案をJSON形式で出力するまで、あなたは待機します。
3.  **ステップ2: Generatorへのデータ連携**: `planner_agent` から出力されたJSONを、**一切変更せずに、そのままの内容で** `planner_json_output` という引数名で `generator_agent` への入力として渡します。あなたの解釈や変更を加えてはいけません。
4.  **ステップ3: Generatorの実行**: `generator_agent` を呼び出し、HTMLの生成を委任します。
5.  **最終出力**: `generator_agent` が生成したHTMLを、ユーザーへの最終的な回答として出力します。この際、HTMLコード以外の余計な文言（「お待たせしました」など）は一切含めないでください。

## ■ 禁止事項
- あなた自身がユーザーと直接、学級通信の内容について対話することはありません。
- `planner_agent` が出力したJSONの内容を解釈したり、変更したりしないでください。
- 最終出力に、HTML以外のテキストを含めないでください。
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
