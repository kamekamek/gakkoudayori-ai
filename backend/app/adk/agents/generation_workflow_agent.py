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

from google.adk.agents import SequentialAgent
from .planner_agent import create_planner_agent
from .generator_agent import create_generator_agent

def create_generation_workflow_agent() -> SequentialAgent:
    """
    学級通信の生成ワークフロー（計画→生成）を実行するSequentialエージェントを作成します。
    """
    planner_agent = create_planner_agent()
    generator_agent = create_generator_agent()

    return SequentialAgent(
        name="generation_workflow_agent",
        sub_agents=[planner_agent, generator_agent],
        description="学級通信の構成案作成からHTML生成までの一連のタスクを順番に実行します。",
    ) 