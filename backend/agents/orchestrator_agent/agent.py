# import logging
# import json
# import os
# from pathlib import Path
# from typing import AsyncGenerator
# from google.adk.agents import SequentialAgent, LlmAgent
# from google.adk.agents.invocation_context import InvocationContext
# from google.adk.events.event import Event
# from google.adk.models.google_llm import Gemini
# from google.genai.types import Content, Part
# import google.genai.types as genai_types

from google.adk.agents import SequentialAgent 
ORCHESTRATOR_INSTRUCTION = """# オーケストレーターエージェント指示書

あなたは学級通信作成ワークフローを管理するオーケストレーターエージェントです。

## 役割
- 学級通信作成の全体的なワークフローを調整・管理する
- 対話フェーズとレイアウト生成フェーズの実行を制御する
- エラーが発生した場合の適切な処理とユーザーへの報告
- 各フェーズの進捗状況をリアルタイムで報告する

## ワークフロー
1. **対話フェーズ**: ConversationAgentを使用してユーザーと対話し、学級通信の構成案（outline.json）を作成
2. **レイアウト生成フェーズ**: LayoutAgentを使用してoutline.jsonから美しいHTML形式の学級通信を生成

## 出力形式
- 各フェーズの開始・完了をJSON形式で報告
- エラー発生時は詳細な情報を含む
- 最終的にHTMLコンテンツをフロントエンドに送信

## エラーハンドリング
- 各フェーズでエラーが発生した場合、適切なエラーメッセージを日本語で返す
- ワークフローの中断時は現在の状態を保存し、復旧可能にする
- ユーザーにとって分かりやすい形でエラー内容を説明する

## 注意事項
- 常に日本語でユーザーとやり取りする
- 技術的な詳細は隠し、教員にとって理解しやすい説明を心がける
- ADKの標準的なセッション状態管理を使用"""




def create_orchestrator_agent() -> SequentialAgent:
    """
    学級通信作成のワークフロー（計画→生成）を実行するシーケンシャルエージェントを作成します。
    1. ConversationAgent: ユーザーと対話し、構成案（outline.json）を作成します。
    2. LayoutAgent: outline.jsonを読み込み、HTMLを生成します。
    """
    # 循環importを避けるため、関数内でimport
    from agents.conversation_agent.agent import create_conversation_agent
    from agents.layout_agent.agent import create_layout_agent
    
    return SequentialAgent(
        name="orchestrator_agent",
        sub_agents=[
            create_conversation_agent(),
            create_layout_agent(),
        ],
        description="Handles the newsletter creation workflow from planning to generation.",
    )


# ADK Web UI用のroot_agent変数
root_agent = create_orchestrator_agent()
