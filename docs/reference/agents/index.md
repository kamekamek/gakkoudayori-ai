# Agents API リファレンス

## 概要

学校だよりAIで使用するAgentsのAPI仕様書一覧です。各Agentは複数のToolを組み合わせて、ワークフロー制御や状態管理を行います。

## Agent一覧

### 統括・制御

| Agent名 | 説明 | 状態 |
|---------|------|------|
| [OrchestratorAgent](orchestrator_agent.md) | 全体ワークフロー制御、リトライ処理 | ✅ 設計済み |

### AI・対話

| Agent名 | 説明 | 状態 |
|---------|------|------|
| [RewriteAgent](rewrite_agent.md) | 教師との対話、リライト方針決定 | ✅ 設計済み |

### レイアウト・出力

| Agent名 | 説明 | 状態 |
|---------|------|------|
| [LayoutAgent](layout_agent.md) | テーマベースHTML生成 | 🚧 検討中 |
| [PdfExportAgent](pdf_export_agent.md) | PDF変換・最適化制御 | 🚧 検討中 |

## Agent設計原則

### オーケストレーション重視
Agentはビジネスロジックよりも、Toolの組み合わせとフロー制御に専念します。

```python
# ✅ 良い例：フロー制御に専念
class OrchestratorAgent(Agent):
    async def process_audio(self, audio_bytes: bytes):
        # Tool を順次呼び出し、エラー時はリトライ
        text = await self.use_tool_with_retry("speech_to_text_tool", audio_bytes)
        corrected = await self.use_tool("user_dict_tool", text)
        return corrected

# ❌ 悪い例：Agent内にビジネスロジック
class OrchestratorAgent(Agent):
    async def process_audio(self, audio_bytes: bytes):
        # 音声処理ロジックを直接実装（Toolに委譲すべき）
        client = speech.SpeechClient()
        response = client.recognize(config, audio_bytes)
        return response.results[0].alternatives[0].transcript
```

### 状態管理とコンテキスト
Agentは実行中の状態を管理し、適切なコンテキストを次の処理に渡します。

```python
class OrchestratorAgent(Agent):
    def __init__(self):
        super().__init__()
        self.workflow_state = {
            "current_step": None,
            "completed_steps": [],
            "context": {}
        }
    
    async def run_step(self, step_name: str, **kwargs):
        self.workflow_state["current_step"] = step_name
        try:
            result = await self.execute_step(step_name, **kwargs)
            self.workflow_state["completed_steps"].append(step_name)
            return result
        except Exception as e:
            await self.handle_step_error(step_name, e)
```

### エラーハンドリングと復旧
Tool呼び出しの失敗に対するリトライ、フォールバック、ユーザー通知を実装します。

```python
async def use_tool_with_retry(self, tool_name: str, max_retries: int = 3, **kwargs):
    for attempt in range(max_retries):
        try:
            return await self.use_tool(tool_name, **kwargs)
        except Exception as e:
            if attempt == max_retries - 1:
                # 最終試行も失敗した場合
                await self.notify_user_error(f"{tool_name} failed after {max_retries} attempts")
                raise
            
            # 指数バックオフでリトライ
            await asyncio.sleep(2 ** attempt)
```

## Agent実装テンプレート

```python
from adk import Agent
from typing import Dict, Any, Optional
import asyncio

class ExampleAgent(Agent):
    def __init__(self, name: str = "example_agent"):
        super().__init__(
            name=name,
            description="Agentの簡潔な説明"
        )
        self.state = {}
    
    async def run(self, **kwargs) -> Dict[str, Any]:
        """
        メインエントリーポイント
        
        Args:
            **kwargs: 実行時パラメータ
        
        Returns:
            実行結果の辞書
        
        Raises:
            AgentExecutionError: 実行時エラー
        """
        try:
            # 1. 入力検証
            self.validate_inputs(**kwargs)
            
            # 2. 初期化
            await self.initialize_state(**kwargs)
            
            # 3. メイン処理
            result = await self.execute_main_workflow(**kwargs)
            
            # 4. 後処理
            await self.cleanup()
            
            return result
            
        except Exception as e:
            await self.handle_error(e)
            raise
    
    async def execute_main_workflow(self, **kwargs) -> Dict[str, Any]:
        """サブクラスで実装するメインロジック"""
        raise NotImplementedError
    
    async def initialize_state(self, **kwargs):
        """状態初期化（必要に応じてオーバーライド）"""
        self.state = {"started_at": datetime.now()}
    
    async def cleanup(self):
        """リソースクリーンアップ（必要に応じてオーバーライド）"""
        pass
    
    def validate_inputs(self, **kwargs):
        """入力値検証（必要に応じてオーバーライド）"""
        pass
    
    async def handle_error(self, error: Exception):
        """エラーハンドリング（必要に応じてオーバーライド）"""
        self.logger.error(f"Agent {self.name} failed: {error}")
```

## Agent間通信

### 委譲パターン
複雑な処理は専門Agentに委譲します。

```python
class OrchestratorAgent(Agent):
    async def process_rewrite_request(self, text: str, user_context: dict):
        # RewriteAgent に委譲
        rewrite_result = await self.delegate_to_agent(
            "rewrite_agent",
            original_text=text,
            user_preferences=user_context
        )
        return rewrite_result

class RewriteAgent(Agent):
    async def run(self, original_text: str, user_preferences: dict):
        # リライト専門処理
        return await self.generate_rewrite_options(original_text, user_preferences)
```

### 状態共有
必要に応じてAgent間で状態を共有します。

```python
# 共有状態管理
class WorkflowState:
    def __init__(self):
        self.shared_context = {}
        self.step_results = {}
    
    def update_context(self, key: str, value: Any):
        self.shared_context[key] = value
    
    def get_context(self, key: str) -> Any:
        return self.shared_context.get(key)

# Agent実装
class OrchestratorAgent(Agent):
    def __init__(self, shared_state: WorkflowState):
        super().__init__()
        self.shared_state = shared_state
    
    async def process_step(self, step_name: str):
        result = await self.execute_step(step_name)
        self.shared_state.step_results[step_name] = result
        return result
```

## テスト戦略

### Agent単体テスト
Tool呼び出しをモック化してAgentロジックをテストします。

```python
class TestOrchestratorAgent:
    @pytest.fixture
    def agent(self):
        return OrchestratorAgent()
    
    @pytest.mark.asyncio
    async def test_successful_workflow(self, agent):
        # Tool呼び出しをモック
        with patch.object(agent, 'use_tool') as mock_tool:
            mock_tool.side_effect = [
                "speech_result",  # speech_to_text_tool
                "corrected_text", # user_dict_tool  
                "final_html"      # template_tool
            ]
            
            result = await agent.run(audio_bytes=b"dummy")
            
            # Tool呼び出し順序の検証
            assert mock_tool.call_count == 3
            assert result["status"] == "completed"
    
    @pytest.mark.asyncio
    async def test_retry_logic(self, agent):
        with patch.object(agent, 'use_tool') as mock_tool:
            # 2回失敗後、3回目で成功
            mock_tool.side_effect = [
                Exception("API Error"),
                Exception("API Error"), 
                "success_result"
            ]
            
            result = await agent.use_tool_with_retry("test_tool", max_retries=3)
            assert result == "success_result"
            assert mock_tool.call_count == 3
```

### Agent統合テスト
実際のToolと組み合わせてE2Eテストを行います。

```python
class TestAgentIntegration:
    @pytest.mark.asyncio
    async def test_full_workflow(self):
        # 実際のToolを使用した統合テスト
        agent = OrchestratorAgent()
        
        with open("test_audio.wav", "rb") as f:
            audio_bytes = f.read()
        
        result = await agent.run(audio_bytes=audio_bytes)
        
        # 期待結果の検証
        assert "html" in result
        assert "pdf" in result
        assert result["status"] == "completed"
```

## パフォーマンス考慮事項

### 並列処理
独立したTool呼び出しは並列実行します。

```python
async def parallel_tool_execution(self):
    # 並列実行可能な処理
    tasks = [
        self.use_tool("classroom_tool", content=pdf),
        self.use_tool("line_notify_tool", message="完了通知")
    ]
    
    results = await asyncio.gather(*tasks, return_exceptions=True)
    
    # 結果とエラーの分離
    for i, result in enumerate(results):
        if isinstance(result, Exception):
            self.logger.error(f"Task {i} failed: {result}")
```

### メモリ管理
長時間実行されるAgentはメモリリークを防止します。

```python
class LongRunningAgent(Agent):
    def __init__(self):
        super().__init__()
        self.max_state_size = 1000
    
    async def add_to_state(self, key: str, value: Any):
        if len(self.state) > self.max_state_size:
            # 古い状態を削除
            oldest_key = next(iter(self.state))
            del self.state[oldest_key]
        
        self.state[key] = value
```

## 関連ドキュメント

- [Tools API リファレンス](/reference/tools/) - Agent で使用するTool
- [ADKワークフローガイド](/guides/adk-workflow.md) - 全体設計
- [ローカル開発ガイド](/guides/local-dev.md) - 開発環境
- [エラーハンドリングガイド](/guides/error-handling.md) - エラー処理戦略