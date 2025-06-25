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
from pathlib import Path
from core.config import settings

def create_generator_agent() -> Agent:
    """Generatorエージェントを作成します。"""
    instruction_path = Path(__file__).parent / "prompts" / "generator_instruction.md"
    with open(instruction_path, "r", encoding="utf-8") as f:
        instruction = f.read()

    return Agent(
        name="generator_agent",
        model=LiteLlm(settings.GEMINI_MODEL),
        instruction=instruction,
        description="JSONデータを受け取り、HTML形式の学級通信を生成します。",
        # このエージェントは外部ツールを必要とせず、入力に基づいて動作します
        tools=[],
    )
