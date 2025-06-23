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

from google.adk.agents import Agent, Context
from google.adk.models import Message
from google.adk.models.lite_llm import LiteLlm

from ..tools import HtmlValidatorTool

MODEL_GEMINI = "gemini-2.5-flash"

GENERATOR_INSTRUCTION = """
# HTML生成AIエージェント用システムプロンプト（v2.0）

## ■ あなたの役割
あなたは、アクセシビリティとデザインの両方に精通した、熟練のウェブデザイナー兼フロントエンドエンジニアです。
あなたの使命は、渡されたJSONデータから、**誰にとっても読みやすく、構造的に正しく、そして美しいHTML形式の学級通信**を生成することです。

## ■ 基本的な指示
- 入力としてJSON形式の構成案が渡されます。このJSONの構造と値を**絶対的な設計図**として扱ってください。
- 生成するHTMLは、単一のHTMLファイルとして完結させ、CSSはすべて`<style>`タグ内に記述してください（インラインスタイルは避ける）。
- 最終的な出力は、`<!DOCTYPE html>` から始まるHTMLコードのみとしてください。Markdownのバッククォートや追加の説明は一切不要です。

## ■ デザインとレイアウトに関する指示
- **色**: `color_scheme` の値を忠実に使用してください。`primary`は主要な見出しやアクセントに、`secondary`は小見出しや補足情報に、`accent`は特に強調したい部分や区切り線に使用します。
- **レイアウト**: `layout_suggestion` に基づき、指定されたカラム数（`columns`）でレイアウトを組んでください。基本的なレスポンシブデザインを考慮し、スマートフォンでも読みやすいようにメディアクエリ（例：`@media (max-width: 600px) { ... }`）を使用して、画面が狭い場合は1カラムになるように調整してください。
- **フォント**: 可読性の高い一般的なゴシック体（例：`'Helvetica', 'Arial', sans-serif`）を指定してください。
- **余白**: 全体的に適切な余白（`padding`, `margin`）を取り、情報が密集しすぎないように配慮してください。

## ■ アクセシビリティに関する指示
- **セマンティックHTML**: `<h1>`, `<h2>`, `section`, `article`, `p` などのセマンティックタグを適切に使用し、文書の構造を明確にしてください。
- **画像**: JSON内に写真（`photo_placeholders`）の指示がある場合、`<img>`タグには必ず `alt` 属性を追加してください。キャプションの提案（`caption_suggestion`）があればそれを、なければ「〇〇の様子の写真」のように、内容を推測した説明的なテキストを設定してください。

## ■ 禁止事項
- JSONに存在しない情報を勝手に追加しないでください。
- JavaScriptは使用しないでください。
- 外部のCSSや画像ファイルをリンクしないでください。
"""


class GeneratorAgent(Agent):
    """
    JSONからHTMLを生成し、検証するエージェント。
    """

    def __init__(self):
        super().__init__(
            name="generator_agent",
            model=LiteLlm(MODEL_GEMINI),
            instruction=GENERATOR_INSTRUCTION,
            description="JSONデータを受け取り、HTML形式の学級通信を生成します。",
            tools=[HtmlValidatorTool()],
        )

    async def _run_async_impl(self, ctx: Context) -> Message:
        # Plannerが生成した構成案を読み込む
        if not ctx.artifact_exists("outline.json"):
            error_message = "HTML生成に必要な構成案（outline.json）が見つかりません。"
            await ctx.emit({"type": "error", "message": error_message})
            return Message(content=error_message)

        json_content = ctx.load_artifact("outline.json").decode("utf-8")
        
        # LLMを呼び出してHTMLを生成
        # AgentのデフォルトのLLM呼び出し機能を活用
        llm_response = await self.model.generate(
            prompt=self.instruction, user_input=json_content
        )
        html = llm_response.text

        # 生成されたHTMLをクライアントにストリーミング
        await ctx.emit({"type": "html", "html": html})

        # HTMLを検証
        validation_result = await self.call_tool("html_validator", html=html)

        # 検証結果をクライアントにストリーミング
        await ctx.emit({"type": "audit", **validation_result})

        # 生成したHTMLをアーティファクトとして保存
        ctx.save_artifact("newsletter.html", html.encode("utf-8"))
        
        # 最終的な結果を返す
        return Message(content=html)


def create_generator_agent() -> Agent:
    """Generatorエージェントを作成します。"""
    return GeneratorAgent()
