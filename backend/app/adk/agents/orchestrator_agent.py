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
from .validation_agent import create_validation_agent

MODEL_GEMINI = "gemini-2.5-flash"

ORCHESTRATOR_INSTRUCTION = """
# 学級通信作成オーケストレーターAI（v3.1）

## ■ あなたの役割
あなたは、学級通信作成プロセス全体を管理する司令塔（オーケストレーター）です。
あなたの仕事は、ユーザーからの依頼をトリガーに、定められたワークフローに従って各専門エージェントを順番に呼び出すことです。エージェント間のデータのやり取りは、共有されたセッション履歴を通じて行われます。

## ■ ワークフローパターン

### パターンA: 通常の学級通信作成
1.  **トリガー**: ユーザーから「学級通信を作りたい」といった趣旨の依頼を受けたら、 `transfer_to_agent` を使って `planner_agent` に処理を委任します。
2.  **Planner処理**: `planner_agent` が通信の構成案（JSON）をセッション履歴に出力し、処理を完了するまで待機します。
3.  **Generator処理**: `planner_agent` の処理が完了したら、`transfer_to_agent` を使って `generator_agent` に処理を委任します。
4.  **HTML出力**: `generator_agent` がHTMLを生成し、処理を完了したら、そのHTMLをユーザーへの最終的な回答として出力します。
5.  **完了報告**: HTMLの出力後、ただちに「学級通信のHTMLを生成しました。プレビューを確認してください。」というテキストをユーザーに送信します。

### パターンB: HTML品質検証
1.  **トリガー**: ユーザーから「HTMLを検証して」「品質をチェックして」「改善点を教えて」といった依頼、またはHTMLコードが直接提供された場合。
2.  **Validation処理**: `transfer_to_agent` を使って `validation_agent` に処理を委任します。
3.  **検証結果出力**: `validation_agent` が品質検証結果と改善提案を出力し、処理を完了します。

## ■ 重要な判断基準
- ユーザーのメッセージにHTMLコード（`<!DOCTYPE html>` や `<html>` など）が含まれている場合は、パターンBの検証ワークフローを実行してください。
- 「検証」「チェック」「品質」「改善」などのキーワードがある場合もパターンBを優先してください。
- それ以外の学級通信作成に関する依頼は、パターンAの通常ワークフローを実行してください。

## ■ 禁止事項
- あなた自身がユーザーと直接、学級通信の内容について対話すること。
- **`transfer_to_agent`を呼び出す際、`agent_name`以外の引数を絶対に追加しないでください。**
- ワークフローの途中経過（「処理中です」など）は一切出力せず、最終的な結果のみを行ってください。
"""

def create_orchestrator_agent() -> Agent:
    """
    Orchestratorエージェントを作成します。
    このエージェントは、Planner、Generator、Validationをサブエージェントとして持ち、
    学級通信の作成プロセス全体を管理します。
    """
    planner_agent = create_planner_agent()
    generator_agent = create_generator_agent()
    validation_agent = create_validation_agent()

    return Agent(
        name="orchestrator_agent",
        model=LiteLlm(MODEL_GEMINI),
        instruction=ORCHESTRATOR_INSTRUCTION,
        description="学級通信の作成プロセス全体を管理し、サブエージェントにタスクを委任します。",
        sub_agents=[planner_agent, generator_agent, validation_agent],
    )
