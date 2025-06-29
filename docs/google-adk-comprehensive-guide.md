# Google ADK (Agent Development Kit) 完全ガイド

## 📚 目次
1. [ADKとは](#adkとは)
2. [核心的な概念](#核心的な概念)
3. [アーキテクチャパターン](#アーキテクチャパターン)
4. [セットアップとインストール](#セットアップとインストール)
5. [基本的なAgent作成](#基本的なagent作成)
6. [Tool開発](#tool開発)
7. [マルチエージェントシステム](#マルチエージェントシステム)
8. [フローとワークフロー](#フローとワークフロー)
9. [API実装方法](#api実装方法)
10. [ベストプラクティス](#ベストプラクティス)
11. [実用的な例](#実用的な例)
12. [トラブルシューティング](#トラブルシューティング)

---

## 🤖 ADKとは

Google Agent Development Kit (ADK)は、**AI エージェントの開発とデプロイのための柔軟でモジュラーなフレームワーク**です。

### 主要な特徴
- **モデル非依存**: Gemini、GPT、Claudeなど複数のLLMをサポート
- **デプロイ非依存**: ローカル、Cloud Run、Vertex AIなど多様な環境で動作
- **モジュラー設計**: 再利用可能なコンポーネントで構成
- **開発者フレンドリー**: 従来のソフトウェア開発に近い感覚

### なぜADKを選ぶのか？
```
従来のAI開発        →    ADKによる開発
・モノリシック        →    ・モジュラー
・単一モデル依存      →    ・マルチモデル対応
・ハードコーディング  →    ・設定ベース
・スケーラビリティ低  →    ・高スケーラビリティ
```

---

## 🏗️ 核心的な概念

### 1. Agent（エージェント）
**役割**: 特定のタスクを実行する自律的なAIコンポーネント

```python
# 基本的なAgent
from adk import Agent, LlmAgent

@Agent
class MyAgent:
    def __init__(self):
        self.llm = LlmAgent(model="gemini-2.5-pro")
    
    async def process(self, input_data):
        return await self.llm.generate(input_data)
```

### 2. Tool（ツール）
**役割**: Agentが利用できる機能を提供

```python
from adk import tool

@tool
async def get_weather(location: str) -> str:
    """指定された場所の天気を取得"""
    # 天気API呼び出しロジック
    return f"{location}の天気は晴れです"
```

### 3. Flow（フロー）
**役割**: Agentとツールの実行順序を定義

```python
from adk import Flow, Sequential

flow = Sequential([
    "weather_agent",
    "summary_agent",
    "notification_agent"
])
```

### 4. Session（セッション）
**役割**: 状態管理とメモリ保持

```python
from adk import Session

session = Session(
    memory_type="in_memory",  # or "database"
    max_messages=100
)
```

---

## 🔧 アーキテクチャパターン

### 1. 単一エージェントパターン
```
User Input → Agent → Tool → Response
```

**用途**: シンプルなタスク処理

```python
from adk import LlmAgent, tool

@tool
async def calculate(expression: str) -> float:
    return eval(expression)  # 実際は安全な評価を使用

agent = LlmAgent(
    model="gemini-2.5-pro",
    tools=[calculate],
    instructions="数学的な計算を行います"
)
```

### 2. マルチエージェントパターン
```
User Input → Orchestrator → Agent A → Agent B → Response
            ↓
        Agent Delegation
```

**用途**: 複雑なタスクの分散処理

```python
from adk import MultiAgent, Agent

class OrchestratorAgent(Agent):
    def __init__(self):
        self.planner = PlannerAgent()
        self.executor = ExecutorAgent()
    
    async def process(self, request):
        plan = await self.planner.create_plan(request)
        result = await self.executor.execute(plan)
        return result
```

### 3. パイプラインパターン
```
Input → Agent1 → Agent2 → Agent3 → Output
```

**用途**: 段階的な処理が必要な場合

```python
from adk import Sequential

pipeline = Sequential([
    "preprocessing_agent",
    "analysis_agent", 
    "formatting_agent"
])
```

### 4. 並列処理パターン
```
Input → ┌─ Agent A ─┐
        ├─ Agent B ─┤ → Aggregator → Output
        └─ Agent C ─┘
```

**用途**: 独立したタスクの同時実行

```python
from adk import Parallel

parallel_flow = Parallel([
    "content_agent",
    "image_agent",
    "metadata_agent"
])
```

---

## ⚙️ セットアップとインストール

### 1. 基本インストール
```bash
# Python環境の準備
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# ADKのインストール
pip install google-adk

# 必要に応じて追加パッケージ
pip install google-adk[vertex]  # Vertex AI用
pip install google-adk[cloud]   # Cloud Run用
```

### 2. 認証設定
```bash
# Google Cloud認証
gcloud auth application-default login

# 環境変数設定
export GOOGLE_CLOUD_PROJECT="your-project-id"
export GOOGLE_APPLICATION_CREDENTIALS="path/to/service-account.json"
```

### 3. プロジェクト構造
```
my-adk-project/
├── agents/
│   ├── __init__.py
│   ├── orchestrator.py
│   ├── planner.py
│   └── generator.py
├── tools/
│   ├── __init__.py
│   ├── weather_tool.py
│   └── database_tool.py
├── flows/
│   ├── __init__.py
│   └── main_flow.py
├── config/
│   └── settings.py
├── requirements.txt
└── main.py
```

---

## 🤖 基本的なAgent作成

### 1. シンプルなLLMエージェント
```python
from adk import LlmAgent
from adk.models import Gemini

# 基本的なエージェント
agent = LlmAgent(
    model=Gemini(model="gemini-2.5-pro"),
    instructions="""
    あなたは学級通信作成の専門家です。
    教師からの情報を元に、魅力的な学級通信を作成してください。
    """,
    temperature=0.7
)

# 実行
response = await agent.generate("今日の運動会について通信を作成してください")
```

### 2. カスタムエージェント
```python
from adk import Agent
from typing import Dict, Any

class NewsletterAgent(Agent):
    """学級通信専用エージェント"""
    
    def __init__(self):
        super().__init__()
        self.llm = LlmAgent(
            model="gemini-2.5-pro",
            instructions=self._get_instructions()
        )
    
    def _get_instructions(self) -> str:
        return """
        あなたは学級通信作成の専門家です。
        以下の要素を含む魅力的な通信を作成してください：
        1. 分かりやすいタイトル
        2. 日付と学級情報
        3. 本文（イベント詳細）
        4. 感謝の言葉
        5. 読みやすいHTML形式
        """
    
    async def create_newsletter(self, content: Dict[str, Any]) -> str:
        """学級通信を作成"""
        prompt = f"""
        以下の情報を元に学級通信を作成してください：
        
        イベント: {content.get('event', '')}
        日付: {content.get('date', '')}
        内容: {content.get('description', '')}
        """
        
        return await self.llm.generate(prompt)
    
    async def process(self, input_data: Dict[str, Any]) -> str:
        """メイン処理"""
        return await self.create_newsletter(input_data)
```

### 3. エージェントの実行
```python
# エージェントのインスタンス化
newsletter_agent = NewsletterAgent()

# 実行
input_data = {
    "event": "運動会",
    "date": "2024年6月15日",
    "description": "晴天の中、子どもたちが元気に競技に参加しました"
}

result = await newsletter_agent.process(input_data)
print(result)
```

---

## 🛠️ Tool開発

### 1. 基本的なTool
```python
from adk import tool
from datetime import datetime

@tool
async def get_current_date() -> str:
    """現在の日付を日本語形式で取得"""
    return datetime.now().strftime("%Y年%m月%d日")

@tool
async def format_html(content: str, title: str) -> str:
    """HTML形式でコンテンツを整形"""
    return f"""
    <!DOCTYPE html>
    <html>
    <head>
        <title>{title}</title>
        <style>
            body {{ font-family: 'Noto Sans JP', sans-serif; }}
            .header {{ background-color: #f0f8ff; padding: 20px; }}
            .content {{ margin: 20px; line-height: 1.6; }}
        </style>
    </head>
    <body>
        <div class="header">
            <h1>{title}</h1>
        </div>
        <div class="content">
            {content}
        </div>
    </body>
    </html>
    """
```

### 2. APIツール
```python
import aiohttp
from adk import tool

@tool
async def call_external_api(endpoint: str, data: dict) -> dict:
    """外部APIを呼び出し"""
    async with aiohttp.ClientSession() as session:
        async with session.post(endpoint, json=data) as response:
            return await response.json()

@tool
async def save_to_database(data: dict) -> bool:
    """データベースに保存"""
    # データベース保存ロジック
    try:
        # 実際のDB操作
        return True
    except Exception as e:
        print(f"保存エラー: {e}")
        return False
```

### 3. ファイル操作ツール
```python
import os
import json
from adk import tool

@tool
async def save_file(content: str, filename: str, format: str = "html") -> str:
    """ファイルを保存"""
    file_path = f"output/{filename}.{format}"
    os.makedirs("output", exist_ok=True)
    
    with open(file_path, "w", encoding="utf-8") as f:
        f.write(content)
    
    return file_path

@tool
async def load_template(template_name: str) -> str:
    """テンプレートを読み込み"""
    template_path = f"templates/{template_name}.html"
    
    with open(template_path, "r", encoding="utf-8") as f:
        return f.read()
```

### 4. ツールの組み合わせ
```python
from adk import LlmAgent

# ツールを含むエージェント
agent = LlmAgent(
    model="gemini-2.5-pro",
    tools=[
        get_current_date,
        format_html,
        save_file,
        load_template
    ],
    instructions="""
    利用可能なツールを使って効率的にタスクを実行してください。
    必要に応じて複数のツールを組み合わせて使用してください。
    """
)
```

---

## 👥 マルチエージェントシステム

### 1. オーケストレーターパターン
```python
from adk import Agent, LlmAgent
from typing import Dict, Any

class OrchestratorAgent(Agent):
    """複数のエージェントを調整"""
    
    def __init__(self):
        super().__init__()
        self.planner = PlannerAgent()
        self.generator = GeneratorAgent()
        self.validator = ValidatorAgent()
    
    async def process(self, request: Dict[str, Any]) -> Dict[str, Any]:
        """メイン処理フロー"""
        # 1. 計画立案
        plan = await self.planner.create_plan(request)
        
        # 2. コンテンツ生成
        content = await self.generator.generate_content(plan)
        
        # 3. 検証・修正
        validated_content = await self.validator.validate(content)
        
        return {
            "plan": plan,
            "content": validated_content,
            "status": "completed"
        }

class PlannerAgent(Agent):
    """計画立案専門エージェント"""
    
    def __init__(self):
        super().__init__()
        self.llm = LlmAgent(
            model="gemini-2.5-pro",
            instructions="""
            学級通信作成のための詳細な計画を立案してください。
            以下の要素を含めてください：
            1. 構成要素
            2. コンテンツの流れ
            3. 必要な情報
            4. デザインの方向性
            """
        )
    
    async def create_plan(self, request: Dict[str, Any]) -> Dict[str, Any]:
        """計画を作成"""
        prompt = f"""
        以下のリクエストに基づいて学級通信の計画を立ててください：
        {json.dumps(request, ensure_ascii=False, indent=2)}
        """
        
        response = await self.llm.generate(prompt)
        return {"plan": response, "timestamp": datetime.now().isoformat()}

class GeneratorAgent(Agent):
    """コンテンツ生成専門エージェント"""
    
    def __init__(self):
        super().__init__()
        self.llm = LlmAgent(
            model="gemini-2.5-pro",
            tools=[format_html, get_current_date],
            instructions="""
            計画に基づいて魅力的な学級通信を生成してください。
            HTMLファイルとして出力し、見やすい形式にしてください。
            """
        )
    
    async def generate_content(self, plan: Dict[str, Any]) -> str:
        """コンテンツを生成"""
        prompt = f"""
        以下の計画に基づいて学級通信を作成してください：
        {json.dumps(plan, ensure_ascii=False, indent=2)}
        """
        
        return await self.llm.generate(prompt)
```

### 2. 専門化エージェントパターン
```python
class SpecializedAgentSystem:
    """専門化されたエージェントシステム"""
    
    def __init__(self):
        self.content_agent = ContentAgent()      # コンテンツ作成
        self.design_agent = DesignAgent()        # デザイン
        self.review_agent = ReviewAgent()        # レビュー
        self.export_agent = ExportAgent()        # エクスポート
    
    async def create_newsletter(self, request: Dict[str, Any]) -> Dict[str, Any]:
        """学級通信の完全な作成フロー"""
        
        # 1. コンテンツ作成
        content = await self.content_agent.create_content(request)
        
        # 2. デザイン適用
        designed_content = await self.design_agent.apply_design(content)
        
        # 3. レビュー
        reviewed_content = await self.review_agent.review(designed_content)
        
        # 4. エクスポート
        final_output = await self.export_agent.export(reviewed_content)
        
        return final_output
```

### 3. 対話型エージェント
```python
class InteractiveAgent(Agent):
    """対話型エージェント"""
    
    def __init__(self):
        super().__init__()
        self.llm = LlmAgent(
            model="gemini-2.5-pro",
            instructions="""
            教師との対話を通じて学級通信の要件を詳しく聞き出してください。
            不明な点があれば質問してください。
            """
        )
        self.conversation_history = []
    
    async def interactive_session(self, initial_input: str) -> str:
        """対話セッション"""
        self.conversation_history.append({"role": "user", "content": initial_input})
        
        # 対話継続の判定
        while True:
            # 現在の対話履歴を含めて応答生成
            context = self._build_context()
            response = await self.llm.generate(context)
            
            self.conversation_history.append({"role": "assistant", "content": response})
            
            # 対話終了の判定
            if self._is_conversation_complete():
                break
            
            # ユーザーからの追加入力を待つ
            user_input = await self._get_user_input()
            self.conversation_history.append({"role": "user", "content": user_input})
        
        return self._generate_final_requirements()
```

---

## 🔄 フローとワークフロー

### 1. 順次実行フロー
```python
from adk import Sequential

# 順次実行のフロー定義
sequential_flow = Sequential([
    {
        "agent": "input_processor",
        "config": {"timeout": 30}
    },
    {
        "agent": "content_generator", 
        "config": {"model": "gemini-2.5-pro"}
    },
    {
        "agent": "html_formatter",
        "config": {"template": "newsletter_template"}
    },
    {
        "agent": "validator",
        "config": {"strict_mode": True}
    }
])

# 実行
result = await sequential_flow.execute(input_data)
```

### 2. 並列実行フロー
```python
from adk import Parallel

# 並列実行のフロー定義
parallel_flow = Parallel([
    {
        "agent": "content_agent",
        "input_key": "content_data"
    },
    {
        "agent": "image_agent",
        "input_key": "image_data"  
    },
    {
        "agent": "metadata_agent",
        "input_key": "meta_data"
    }
])

# 実行後の結果統合
async def process_parallel_results(results):
    """並列処理結果の統合"""
    return {
        "content": results["content_agent"],
        "images": results["image_agent"],
        "metadata": results["metadata_agent"]
    }
```

### 3. 条件分岐フロー
```python
from adk import ConditionalFlow

class NewsletterFlow(ConditionalFlow):
    """条件分岐を含むフロー"""
    
    async def execute(self, input_data: Dict[str, Any]) -> Dict[str, Any]:
        """実行フロー"""
        
        # 1. 入力の種類を判定
        input_type = await self._determine_input_type(input_data)
        
        if input_type == "voice":
            # 音声入力の処理
            text_data = await self._process_voice_input(input_data)
        elif input_type == "text":
            # テキスト入力の処理
            text_data = await self._process_text_input(input_data)
        else:
            raise ValueError(f"Unsupported input type: {input_type}")
        
        # 2. コンテンツ生成
        content = await self._generate_content(text_data)
        
        # 3. 出力形式の判定
        output_format = input_data.get("output_format", "html")
        
        if output_format == "html":
            result = await self._generate_html(content)
        elif output_format == "pdf":
            result = await self._generate_pdf(content)
        else:
            result = content
        
        return result
```

### 4. ループフロー
```python
from adk import LoopFlow

class IterativeImprovementFlow(LoopFlow):
    """反復改善フロー"""
    
    def __init__(self):
        super().__init__()
        self.max_iterations = 3
        self.quality_threshold = 0.8
    
    async def execute(self, input_data: Dict[str, Any]) -> Dict[str, Any]:
        """反復実行"""
        current_content = input_data
        iteration = 0
        
        while iteration < self.max_iterations:
            # コンテンツ生成
            generated_content = await self._generate_content(current_content)
            
            # 品質評価
            quality_score = await self._evaluate_quality(generated_content)
            
            if quality_score >= self.quality_threshold:
                return generated_content
            
            # 改善提案の生成
            improvement_suggestions = await self._generate_improvements(
                generated_content, quality_score
            )
            
            # 改善適用
            current_content = await self._apply_improvements(
                generated_content, improvement_suggestions
            )
            
            iteration += 1
        
        return current_content
```

---

## 🌐 API実装方法

### 1. FastAPIとの統合
```python
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import Dict, Any
import asyncio

app = FastAPI(title="学級通信AI API")

# ADKエージェントの初期化
orchestrator = OrchestratorAgent()

class NewsletterRequest(BaseModel):
    content: str
    event_type: str
    date: str
    class_info: Dict[str, Any]
    output_format: str = "html"

class NewsletterResponse(BaseModel):
    status: str
    content: str
    metadata: Dict[str, Any]

@app.post("/api/v1/newsletter/create", response_model=NewsletterResponse)
async def create_newsletter(request: NewsletterRequest):
    """学級通信作成API"""
    try:
        # ADKエージェントの実行
        result = await orchestrator.process({
            "content": request.content,
            "event_type": request.event_type,
            "date": request.date,
            "class_info": request.class_info,
            "output_format": request.output_format
        })
        
        return NewsletterResponse(
            status="success",
            content=result["content"],
            metadata=result.get("metadata", {})
        )
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/v1/agents/status")
async def get_agent_status():
    """エージェントの状態取得"""
    return {
        "orchestrator": "active",
        "agents": [
            {"name": "planner", "status": "ready"},
            {"name": "generator", "status": "ready"},
            {"name": "validator", "status": "ready"}
        ]
    }
```

### 2. WebSocketサポート
```python
from fastapi import WebSocket, WebSocketDisconnect
import json

class ConnectionManager:
    """WebSocket接続管理"""
    
    def __init__(self):
        self.active_connections: List[WebSocket] = []
    
    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)
    
    def disconnect(self, websocket: WebSocket):
        self.active_connections.remove(websocket)
    
    async def send_progress(self, message: str):
        """全接続にプログレス送信"""
        for connection in self.active_connections:
            await connection.send_text(json.dumps({
                "type": "progress",
                "message": message
            }))

manager = ConnectionManager()

@app.websocket("/ws/newsletter")
async def websocket_endpoint(websocket: WebSocket):
    await manager.connect(websocket)
    
    try:
        while True:
            # クライアントからのメッセージ受信
            data = await websocket.receive_text()
            request_data = json.loads(data)
            
            # プログレス送信
            await manager.send_progress("処理を開始しています...")
            
            # ADKエージェントの実行（プログレス付き）
            result = await orchestrator.process_with_progress(
                request_data,
                progress_callback=manager.send_progress
            )
            
            # 結果送信
            await websocket.send_text(json.dumps({
                "type": "result",
                "data": result
            }))
    
    except WebSocketDisconnect:
        manager.disconnect(websocket)
```

### 3. 認証・認可
```python
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
import jwt

security = HTTPBearer()

async def verify_token(credentials: HTTPAuthorizationCredentials = Depends(security)):
    """JWTトークン検証"""
    try:
        payload = jwt.decode(
            credentials.credentials,
            "your-secret-key",
            algorithms=["HS256"]
        )
        return payload
    except jwt.ExpiredSignatureError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token expired"
        )
    except jwt.JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token"
        )

@app.post("/api/v1/newsletter/create")
async def create_newsletter(
    request: NewsletterRequest,
    current_user: dict = Depends(verify_token)
):
    """認証付きエンドポイント"""
    # ユーザー権限チェック
    if not current_user.get("can_create_newsletter"):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Insufficient permissions"
        )
    
    # 処理実行
    return await orchestrator.process(request.dict())
```

### 4. ミドルウェアとエラーハンドリング
```python
from fastapi import Request, Response
from fastapi.middleware.base import BaseHTTPMiddleware
import time
import logging

class ProcessingTimeMiddleware(BaseHTTPMiddleware):
    """処理時間ログ用ミドルウェア"""
    
    async def dispatch(self, request: Request, call_next):
        start_time = time.time()
        
        response = await call_next(request)
        
        process_time = time.time() - start_time
        response.headers["X-Process-Time"] = str(process_time)
        
        logging.info(f"処理時間: {process_time:.2f}秒 - {request.url}")
        
        return response

app.add_middleware(ProcessingTimeMiddleware)

@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    """グローバル例外ハンドラー"""
    logging.error(f"予期しないエラー: {exc}", exc_info=True)
    
    return {"error": "内部サーバーエラーが発生しました", "detail": str(exc)}
```

---

## 🏆 ベストプラクティス

### 1. エージェント設計の原則

#### 単一責任の原則
```python
# ❌ 悪い例：多すぎる責任
class BadAgent(Agent):
    async def process(self, data):
        # 音声処理
        text = await self.speech_to_text(data)
        # コンテンツ生成
        content = await self.generate_content(text)
        # HTML生成
        html = await self.create_html(content)
        # PDF生成
        pdf = await self.create_pdf(html)
        # メール送信
        await self.send_email(pdf)
        return pdf

# ✅ 良い例：単一責任
class SpeechToTextAgent(Agent):
    async def process(self, audio_data):
        return await self.speech_to_text(audio_data)

class ContentGeneratorAgent(Agent):
    async def process(self, text_data):
        return await self.generate_content(text_data)
```

#### 設定の外部化
```python
# config/settings.py
from pydantic import BaseSettings

class Settings(BaseSettings):
    # LLM設定
    llm_model: str = "gemini-2.5-pro"
    llm_temperature: float = 0.7
    llm_max_tokens: int = 2048
    
    # Agent設定
    max_retries: int = 3
    timeout_seconds: int = 30
    
    # API設定
    api_base_url: str = "http://localhost:8000"
    api_key: str
    
    class Config:
        env_file = ".env"

settings = Settings()

# エージェントでの使用
agent = LlmAgent(
    model=settings.llm_model,
    temperature=settings.llm_temperature,
    max_tokens=settings.llm_max_tokens
)
```

### 2. エラーハンドリング

#### 再試行メカニズム
```python
import asyncio
from typing import Callable, Any

async def retry_on_failure(
    func: Callable,
    max_retries: int = 3,
    delay: float = 1.0,
    backoff_factor: float = 2.0
) -> Any:
    """失敗時の再試行メカニズム"""
    
    for attempt in range(max_retries):
        try:
            return await func()
        except Exception as e:
            if attempt == max_retries - 1:
                raise e
            
            wait_time = delay * (backoff_factor ** attempt)
            await asyncio.sleep(wait_time)
            
            logging.warning(f"試行 {attempt + 1} 失敗: {e}. {wait_time}秒後に再試行")

# 使用例
async def generate_content_with_retry(prompt: str) -> str:
    return await retry_on_failure(
        lambda: agent.generate(prompt),
        max_retries=3,
        delay=1.0
    )
```

#### 例外の階層化
```python
class ADKException(Exception):
    """ADK基底例外"""
    pass

class AgentExecutionError(ADKException):
    """エージェント実行エラー"""
    pass

class ToolError(ADKException):
    """ツールエラー"""
    pass

class ValidationError(ADKException):
    """検証エラー"""
    pass

# 使用例
try:
    result = await agent.process(data)
except AgentExecutionError as e:
    logging.error(f"エージェント実行エラー: {e}")
    # 適切な代替処理
except ToolError as e:
    logging.error(f"ツールエラー: {e}")
    # ツール関連の回復処理
```

### 3. パフォーマンス最適化

#### 並列処理の活用
```python
import asyncio

async def process_multiple_requests(requests: List[Dict]) -> List[Dict]:
    """複数リクエストの並列処理"""
    
    # 並列実行
    tasks = [
        process_single_request(request)
        for request in requests
    ]
    
    results = await asyncio.gather(*tasks, return_exceptions=True)
    
    # 結果の処理
    successful_results = []
    errors = []
    
    for i, result in enumerate(results):
        if isinstance(result, Exception):
            errors.append({"request_id": i, "error": str(result)})
        else:
            successful_results.append(result)
    
    return {
        "successful": successful_results,
        "errors": errors
    }
```

#### キャッシング
```python
from functools import lru_cache
import hashlib
import json

class CachedAgent(Agent):
    """キャッシュ機能付きエージェント"""
    
    def __init__(self):
        super().__init__()
        self.cache = {}
    
    def _generate_cache_key(self, input_data: Dict) -> str:
        """キャッシュキー生成"""
        content = json.dumps(input_data, sort_keys=True)
        return hashlib.md5(content.encode()).hexdigest()
    
    async def process(self, input_data: Dict) -> Dict:
        """キャッシュ付き処理"""
        cache_key = self._generate_cache_key(input_data)
        
        # キャッシュチェック
        if cache_key in self.cache:
            logging.info(f"キャッシュヒット: {cache_key}")
            return self.cache[cache_key]
        
        # 処理実行
        result = await self._actual_process(input_data)
        
        # キャッシュ保存
        self.cache[cache_key] = result
        
        return result
```

### 4. テスト戦略

#### 単体テスト
```python
import pytest
from unittest.mock import AsyncMock, patch

class TestNewsletterAgent:
    """学級通信エージェントのテスト"""
    
    @pytest.fixture
    def agent(self):
        return NewsletterAgent()
    
    @pytest.fixture
    def sample_input(self):
        return {
            "event": "運動会",
            "date": "2024年6月15日",
            "description": "晴天の中、運動会が開催されました"
        }
    
    @pytest.mark.asyncio
    async def test_create_newsletter_success(self, agent, sample_input):
        """正常なニュースレター作成"""
        result = await agent.create_newsletter(sample_input)
        
        assert isinstance(result, str)
        assert "運動会" in result
        assert "2024年6月15日" in result
    
    @pytest.mark.asyncio
    async def test_create_newsletter_with_missing_data(self, agent):
        """データ不足時の処理"""
        incomplete_input = {"event": "運動会"}
        
        with pytest.raises(ValidationError):
            await agent.create_newsletter(incomplete_input)
    
    @pytest.mark.asyncio
    async def test_llm_failure_handling(self, agent, sample_input):
        """LLM失敗時の処理"""
        with patch.object(agent.llm, 'generate', side_effect=Exception("LLM Error")):
            with pytest.raises(AgentExecutionError):
                await agent.create_newsletter(sample_input)
```

#### 統合テスト
```python
@pytest.mark.asyncio
async def test_full_workflow():
    """全体フローのテスト"""
    
    # テストデータ
    input_data = {
        "voice_data": "base64_encoded_audio",
        "class_info": {"grade": "3", "class": "A"}
    }
    
    # オーケストレーター作成
    orchestrator = OrchestratorAgent()
    
    # 実行
    result = await orchestrator.process(input_data)
    
    # 検証
    assert result["status"] == "completed"
    assert "content" in result
    assert "metadata" in result
```

---

## 🎯 実用的な例

### 完全な学級通信システム

```python
# main.py - 完全なシステム例
from fastapi import FastAPI, UploadFile, File
from adk import LlmAgent, tool
import asyncio
import json

app = FastAPI(title="学級通信AI システム")

# ツール定義
@tool
async def speech_to_text(audio_data: bytes) -> str:
    """音声をテキストに変換"""
    # Google Speech-to-Text API呼び出し
    # 実装は省略
    return "運動会が開催されました。子どもたちは元気に参加しました。"

@tool
async def generate_html_template(content: str, metadata: dict) -> str:
    """HTMLテンプレート生成"""
    return f"""
    <!DOCTYPE html>
    <html lang="ja">
    <head>
        <meta charset="UTF-8">
        <title>{metadata.get('title', '学級通信')}</title>
        <style>
            body {{
                font-family: 'Noto Sans JP', sans-serif;
                line-height: 1.6;
                margin: 0;
                padding: 20px;
                background-color: #f9f9f9;
            }}
            .newsletter {{
                max-width: 800px;
                margin: 0 auto;
                background: white;
                padding: 30px;
                border-radius: 10px;
                box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            }}
            .header {{
                text-align: center;
                border-bottom: 3px solid #4CAF50;
                padding-bottom: 20px;
                margin-bottom: 30px;
            }}
            .content {{
                font-size: 16px;
                line-height: 1.8;
            }}
            .highlight {{
                background-color: #fff3cd;
                padding: 15px;
                border-left: 4px solid #ffc107;
                margin: 20px 0;
            }}
        </style>
    </head>
    <body>
        <div class="newsletter">
            <div class="header">
                <h1>{metadata.get('title', '学級通信')}</h1>
                <p>{metadata.get('date', '')} | {metadata.get('class', '')}</p>
            </div>
            <div class="content">
                {content}
            </div>
        </div>
    </body>
    </html>
    """

@tool
async def validate_content(content: str) -> dict:
    """コンテンツの検証"""
    validation_result = {
        "is_valid": True,
        "warnings": [],
        "suggestions": []
    }
    
    # 基本的な検証
    if len(content) < 100:
        validation_result["warnings"].append("コンテンツが短すぎます")
    
    if "運動会" not in content and "イベント" not in content:
        validation_result["suggestions"].append("具体的なイベント名を追加してください")
    
    return validation_result

# エージェント定義
class ComprehensiveNewsletterAgent:
    """包括的な学級通信エージェント"""
    
    def __init__(self):
        self.speech_agent = LlmAgent(
            model="gemini-2.5-pro",
            tools=[speech_to_text],
            instructions="音声データを正確にテキストに変換してください。"
        )
        
        self.content_agent = LlmAgent(
            model="gemini-2.5-pro",
            instructions="""
            学級通信のコンテンツを作成してください。
            以下の要素を含めてください：
            1. 魅力的な導入文
            2. イベントの詳細
            3. 子どもたちの様子
            4. 保護者への感謝
            5. 今後の予定
            
            親しみやすく、読みやすい文章にしてください。
            """
        )
        
        self.design_agent = LlmAgent(
            model="gemini-2.5-pro",
            tools=[generate_html_template],
            instructions="魅力的なHTMLレイアウトを作成してください。"
        )
        
        self.validator_agent = LlmAgent(
            model="gemini-2.5-pro",
            tools=[validate_content],
            instructions="コンテンツの品質を検証し、改善提案を行ってください。"
        )
    
    async def process_voice_input(self, audio_data: bytes) -> str:
        """音声入力の処理"""
        result = await self.speech_agent.generate(
            f"この音声データをテキストに変換してください: {len(audio_data)} bytes"
        )
        return result
    
    async def generate_content(self, text_input: str, metadata: dict) -> str:
        """コンテンツ生成"""
        prompt = f"""
        以下の情報を元に学級通信を作成してください：
        
        基本情報:
        - 学級: {metadata.get('class', '')}
        - 日付: {metadata.get('date', '')}
        - 先生: {metadata.get('teacher', '')}
        
        内容:
        {text_input}
        
        魅力的で読みやすい学級通信を作成してください。
        """
        
        content = await self.content_agent.generate(prompt)
        return content
    
    async def create_html_design(self, content: str, metadata: dict) -> str:
        """HTMLデザイン作成"""
        prompt = f"""
        以下のコンテンツを美しいHTMLレイアウトで表示してください：
        
        メタデータ: {json.dumps(metadata, ensure_ascii=False)}
        
        コンテンツ:
        {content}
        """
        
        html_result = await self.design_agent.generate(prompt)
        return html_result
    
    async def validate_and_improve(self, content: str) -> dict:
        """検証と改善"""
        prompt = f"""
        以下のコンテンツを検証してください：
        {content}
        
        品質評価と改善提案を行ってください。
        """
        
        validation_result = await self.validator_agent.generate(prompt)
        return {"validation": validation_result, "content": content}

# APIエンドポイント
newsletter_agent = ComprehensiveNewsletterAgent()

@app.post("/api/v1/newsletter/create-from-voice")
async def create_newsletter_from_voice(
    audio_file: UploadFile = File(...),
    class_info: str = "3年A組",
    teacher_name: str = "田中先生",
    date: str = "2024年6月15日"
):
    """音声からの学級通信作成"""
    
    try:
        # 音声データの読み込み
        audio_data = await audio_file.read()
        
        # メタデータ
        metadata = {
            "class": class_info,
            "teacher": teacher_name,
            "date": date,
            "title": f"{class_info} 学級通信"
        }
        
        # 処理フロー
        # 1. 音声→テキスト変換
        text_content = await newsletter_agent.process_voice_input(audio_data)
        
        # 2. コンテンツ生成
        newsletter_content = await newsletter_agent.generate_content(text_content, metadata)
        
        # 3. HTMLデザイン
        html_output = await newsletter_agent.create_html_design(newsletter_content, metadata)
        
        # 4. 検証
        validation_result = await newsletter_agent.validate_and_improve(newsletter_content)
        
        return {
            "status": "success",
            "html_content": html_output,
            "text_content": newsletter_content,
            "validation": validation_result,
            "metadata": metadata
        }
    
    except Exception as e:
        return {
            "status": "error",
            "message": str(e)
        }

@app.get("/api/v1/health")
async def health_check():
    """ヘルスチェック"""
    return {
        "status": "healthy",
        "agents": [
            "speech_agent",
            "content_agent", 
            "design_agent",
            "validator_agent"
        ]
    }

# 実行
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
```

---

## 🐛 トラブルシューティング

### 1. よくある問題と解決方法

#### エージェントが応答しない
```python
# 問題: エージェントがハングアップ
# 解決: タイムアウト設定

import asyncio
from adk import LlmAgent

async def safe_agent_call(agent: LlmAgent, prompt: str, timeout: float = 30.0):
    """タイムアウト付きエージェント呼び出し"""
    try:
        result = await asyncio.wait_for(
            agent.generate(prompt),
            timeout=timeout
        )
        return result
    except asyncio.TimeoutError:
        raise Exception(f"エージェント応答がタイムアウトしました ({timeout}秒)")
```

#### メモリ使用量が多い  
```python
# 問題: メモリ使用量が増加
# 解決: 適切なクリーンアップ

class MemoryEfficientAgent(Agent):
    def __init__(self):
        super().__init__()
        self.conversation_history = []
        self.max_history = 10  # 履歴の上限
    
    async def process(self, input_data):
        # 処理実行
        result = await self._actual_process(input_data)
        
        # 履歴管理
        self.conversation_history.append({
            "input": input_data,
            "output": result,
            "timestamp": time.time()
        })
        
        # 古い履歴を削除
        if len(self.conversation_history) > self.max_history:
            self.conversation_history = self.conversation_history[-self.max_history:]
        
        return result
```

#### API呼び出し制限
```python
# 問題: API呼び出し制限に引っかかる
# 解決: レート制限

import asyncio
import time
from collections import deque

class RateLimitedAgent(Agent):
    def __init__(self, calls_per_minute: int = 60):
        super().__init__()
        self.calls_per_minute = calls_per_minute
        self.call_times = deque()
    
    async def _enforce_rate_limit(self):
        """レート制限の実行"""
        now = time.time()
        
        # 1分以内の呼び出しをカウント
        while self.call_times and now - self.call_times[0] > 60:
            self.call_times.popleft()
        
        if len(self.call_times) >= self.calls_per_minute:
            # 待機時間計算
            wait_time = 60 - (now - self.call_times[0])
            await asyncio.sleep(wait_time)
        
        self.call_times.append(now)
    
    async def generate(self, prompt: str):
        await self._enforce_rate_limit()
        return await super().generate(prompt)
```

### 2. デバッグとロギング

```python
import logging
import json
from datetime import datetime

# ロギング設定
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('adk_debug.log'),
        logging.StreamHandler()
    ]
)

class DebuggableAgent(Agent):
    """デバッグ機能付きエージェント"""
    
    def __init__(self, name: str):
        super().__init__()
        self.name = name
        self.logger = logging.getLogger(f"Agent.{name}")
    
    async def process(self, input_data):
        """処理実行（デバッグ付き）"""
        request_id = f"{self.name}_{int(time.time())}"
        
        self.logger.info(f"[{request_id}] 処理開始")
        self.logger.debug(f"[{request_id}] 入力データ: {json.dumps(input_data, ensure_ascii=False)}")
        
        try:
            start_time = time.time()
            result = await self._actual_process(input_data)
            end_time = time.time()
            
            self.logger.info(f"[{request_id}] 処理完了 ({end_time - start_time:.2f}秒)")
            self.logger.debug(f"[{request_id}] 出力データ: {json.dumps(result, ensure_ascii=False)}")
            
            return result
        
        except Exception as e:
            self.logger.error(f"[{request_id}] 処理エラー: {e}", exc_info=True)
            raise
```

### 3. パフォーマンス監視

```python
import psutil
import asyncio
from dataclasses import dataclass
from typing import Dict, List

@dataclass
class PerformanceMetrics:
    """パフォーマンス指標"""
    cpu_percent: float
    memory_percent: float
    processing_time: float
    success_rate: float
    error_count: int

class PerformanceMonitor:
    """パフォーマンス監視"""
    
    def __init__(self):
        self.metrics_history: List[PerformanceMetrics] = []
        self.error_count = 0
        self.success_count = 0
    
    async def monitor_agent_performance(self, agent: Agent, input_data: Dict):
        """エージェントのパフォーマンス監視"""
        start_time = time.time()
        start_memory = psutil.Process().memory_percent()
        start_cpu = psutil.cpu_percent()
        
        try:
            result = await agent.process(input_data)
            self.success_count += 1
            return result
        
        except Exception as e:
            self.error_count += 1
            raise e
        
        finally:
            end_time = time.time()
            end_memory = psutil.Process().memory_percent()
            end_cpu = psutil.cpu_percent()
            
            # メトリクス記録
            metrics = PerformanceMetrics(
                cpu_percent=(start_cpu + end_cpu) / 2,
                memory_percent=(start_memory + end_memory) / 2,
                processing_time=end_time - start_time,
                success_rate=self.success_count / (self.success_count + self.error_count),
                error_count=self.error_count
            )
            
            self.metrics_history.append(metrics)
            
            # アラート
            if metrics.processing_time > 30:  # 30秒以上
                logging.warning(f"処理時間が長すぎます: {metrics.processing_time:.2f}秒")
            
            if metrics.memory_percent > 80:  # 80%以上
                logging.warning(f"メモリ使用量が高すぎます: {metrics.memory_percent:.2f}%")
    
    def get_performance_summary(self) -> Dict:
        """パフォーマンス要約"""
        if not self.metrics_history:
            return {"status": "no_data"}
        
        recent_metrics = self.metrics_history[-10:]  # 直近10件
        
        return {
            "avg_processing_time": sum(m.processing_time for m in recent_metrics) / len(recent_metrics),
            "avg_cpu_usage": sum(m.cpu_percent for m in recent_metrics) / len(recent_metrics),
            "avg_memory_usage": sum(m.memory_percent for m in recent_metrics) / len(recent_metrics),
            "current_success_rate": recent_metrics[-1].success_rate,
            "total_errors": self.error_count
        }
```

---

## 🎉 まとめ

Google ADKは、**現代のAIアプリケーション開発において極めて重要な役割を果たすフレームワーク**です。本ガイドで紹介した概念、パターン、実装方法を活用することで、スケーラブルで保守性の高いマルチエージェントシステムを構築できます。

### 重要なポイント
1. **モジュラー設計**: 各エージェントは単一の責任を持つ
2. **適切なツール選択**: 単純な処理はTool、複雑な処理はAgent
3. **エラーハンドリング**: 適切な例外処理と再試行メカニズム
4. **パフォーマンス監視**: 継続的な性能改善
5. **テスト戦略**: 単体テストから統合テストまで

### 次のステップ
- 実際のプロジェクトでADKを活用してみる
- 独自のエージェントとツールを開発する
- パフォーマンスの最適化を継続的に行う
- コミュニティとのナレッジ共有

このガイドが、あなたのADK開発の旅の出発点となることを願っています。Google ADKの無限の可能性を探求し、革新的なAIアプリケーションを構築してください！

---

*このドキュメントは、Google ADK公式ドキュメントおよびコミュニティの知見を基に作成されました。最新の情報については、公式ドキュメントをご確認ください。*