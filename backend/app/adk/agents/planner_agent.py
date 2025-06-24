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

import os
from pathlib import Path
from google.adk.agents import Agent
from google.adk.models.lite_llm import LiteLlm
from ...core.config import settings
from ..tools import get_current_date

def _load_instruction() -> str:
    """プロンプトファイルを読み込みます。"""
    current_dir = Path(os.path.dirname(__file__))
    prompt_file = current_dir / "prompts" / "planner_instruction.md"
    with open(prompt_file, "r", encoding="utf-8") as f:
        return f.read()

PLANNER_INSTRUCTION = _load_instruction()

def create_planner_agent() -> Agent:
    """Plannerエージェントを作成します。"""
    return Agent(
        name="planner_agent",
        model=LiteLlm(settings.GEMINI_MODEL),
        instruction=PLANNER_INSTRUCTION,
        description="ユーザーと対話して学級通信の構成を計画し、JSON形式で出力します。",
        tools=[get_current_date],
    )