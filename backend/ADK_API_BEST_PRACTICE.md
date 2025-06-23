# Google ADKエージェントと通常APIの共存ベストプラクティス

## 1. はじめに

Agent Development Kit (ADK) は、AIエージェントを開発・デプロイするための強力なフレームワークです。`adk api_server` コマンドを使えば、作成したエージェントを簡単にAPIとして公開できます。

しかし、実際のアプリケーションでは、ADKエージェント以外の機能（例：ユーザー認証、データ管理など）を提供する通常のAPIエンドポイントも必要になるケースがほとんどです。

このドキュメントでは、ADKエージェントと既存のAPI（本稿ではPythonのWebフレームワークであるFastAPIを例とします）を共存させるための2つの主要なアプローチと、それぞれのベストプラクティスについて解説します。

## 2. 2つの主要なアプローチ

ADKエージェントと通常のFastAPIアプリケーションを共存させるには、主に以下の2つのアーキテクチャが考えられます。

1.  **APIサーバーの分離（マイクロサービス型）**:
    *   ADKエージェント用のサーバーと、通常のAPI用のサーバーを別々のプロセスで起動します。
    *   APIゲートウェイ（Nginxなど）を前段に置き、リクエストのパスに応じて適切なサーバーにリクエストを振り分けます。

2.  **単一FastAPIサーバーへの統合（モノリシック型）**:
    *   既存のFastAPIアプリケーションに、ADKエージェントのAPIエンドポイントをプログラムで組み込み（マウントし）ます。
    *   単一のサーバープロセスが、エージェントと通常APIの両方のリクエストを処理します。

## 3. アプローチ1: APIサーバーの分離（マイクロサービス型）

このアプローチでは、関心事を明確に分離します。エージェントはエージェント、APIはAPIとして独立して開発・運用できます。

### 構成図

```mermaid
graph TD
    subgraph "クライアント (例: Flutter Web App)"
        Client
    end

    subgraph "API Gateway (例: Nginx)"
        Gateway
    end

    subgraph "バックエンドサーバー"
        Server1[ADK Agent Server<br/>(adk api_server on :8080)]
        Server2[Regular API Server<br/>(uvicorn on :8081)]
    end

    Client --> Gateway
    Gateway -- "/api/v1/agent/*" --> Server1
    Gateway -- "/api/v1/other/*" --> Server2
```

### セットアップ方法

1.  **ADKエージェントサーバーを起動する:**
    ```bash
    adk api_server --agent-path /path/to/your/agent --port 8080
    ```

2.  **通常のFastAPIサーバーを起動する:**
    ```bash
    uvicorn your_app.main:app --port 8081
    ```

3.  **APIゲートウェイを設定する:**
    Nginxなどのリバースプロキシを設定し、パスに基づいてリクエストを各サーバーに振り分けます。

### メリット

*   **関心の分離**: エージェントとビジネスロジックが完全に分離されるため、コードベースがクリーンに保たれます。
*   **独立したスケーリング**: エージェントの負荷が高い場合、エージェントサーバーだけをスケールアウトすることが可能です。
*   **技術スタックの柔軟性**: 通常のAPIはFastAPI以外（例: Django, Node.js）でも構築できます。
*   **ADKの恩恵を最大化**: `adk api_server` の機能をそのまま利用できます。

### デメリット

*   **インフラの複雑化**: 複数のサーバーとAPIゲートウェイを管理・維持する必要があります。
*   **開発のオーバーヘッド**: ローカル開発環境のセットアップが少し煩雑になります。
*   **ネットワークレイテンシ**: サービス間通信が発生する場合、若干のオーバーヘッドが生じます。

---

## 4. アプローチ2: 単一FastAPIサーバーへの統合（詳細ガイド）

このアプローチは、既存のFastAPIアプリケーションにADKを「アドオン」として組み込む、最も推奨される方法です。管理がシンプルで、開発体験もスムーズです。

ここでは、ADKが提供する公式ユーティリティ `adk.server.get_fast_api_app` を利用して、既存のアプリケーションにエージェントのAPIと開発用UIをマウントする方法を詳しく解説します。

### 想定するディレクトリ構成

まず、プロジェクトの構成を以下のように整理します。

```
gakkoudayori-ai/
├── agent/
│   ├── __init__.py
│   └── agent.py         # ADKエージェントの定義
├── api/
│   ├── __init__.py
│   └── v1/
│       ├── __init__.py
│       └── other_routes.py  # 通常のAPIルーター (例: 辞書、ヘルスチェック)
└── main.py              # FastAPIアプリケーションのエントリポイント
```

### Step 1: ADKエージェントを定義する

`agent/agent.py` ファイルに、APIとして公開したいエージェントを定義します。

`gakkoudayori-ai/agent/agent.py`:
```python
from adk.agent import LlmAgent
from adk.llm.gemini import Gemini
from adk.memory import ConversationMemory
from adk.prompt import PromptTemplate

# 学級通信の作成を支援するプロンプト
GAKKOUDAYORI_PROMPT = PromptTemplate(
    "あなたはプロの編集者です。以下のテキストを元に、小学校の保護者向けの、魅力的で読みやすい学級通信の記事を作成してください。\n\n"
    "元のテキスト:\n"
    "{text}"
)

# このエージェントがAPIとして公開される
agent = LlmAgent(
    llm=Gemini(),
    prompt_template=GAKKOUDAYORI_PROMPT,
    memory=ConversationMemory(window_size=10)
)
```

### Step 2: 通常のAPIエンドポイントを作成する

`api/v1/other_routes.py` に、エージェント以外のAPIエンドポイントを定義します。

`gakkoudayori-ai/api/v1/other_routes.py`:
```python
from fastapi import APIRouter

# 通常のAPIエンドポイント用のルーターを作成
router = APIRouter()

@router.get("/health", summary="ヘルスチェック")
async def health_check():
    """サーバーの状態を返すシンプルなエンドポイント"""
    return {"status": "ok"}

@router.get("/dictionary/{user_id}", summary="ユーザー辞書取得")
async def get_user_dictionary(user_id: str):
    """指定されたユーザーの辞書データを返す（ダミー）"""
    return {"user_id": user_id, "terms": ["学級通信", "保護者会", "運動会"]}
```

### Step 3: メインのFastAPIアプリで統合する

`main.py` で、FastAPIアプリケーションを初期化し、通常APIのルーターとADKエージェントのアプリをマウントします。

`gakkoudayori-ai/main.py`:
```python
from fastapi import FastAPI
from adk.server import get_fast_api_app
from agent.agent import agent as gakkoudayori_agent # Step 1 で作成したエージェント
from api.v1.other_routes import router as other_router   # Step 2 で作成したルーター

# 1. メインのFastAPIアプリケーションを作成
app = FastAPI(
    title="Gakkoudayori AI Backend",
    version="1.0.0",
    description="学級通信AIエージェントと通常APIを統合したサーバー"
)

# 2. 通常APIのルーターをアプリにマウント
app.include_router(other_router, prefix="/api/v1/other", tags=["Other APIs"])


# 3. ADKエージェントをFastAPIアプリとして取得し、サブアプリケーションとしてマウント
# get_fast_api_app は、エージェントのAPI(/invoke)とWeb UI(/ui)を含む
# 完全なFastAPIアプリケーションを返します。
agent_app = get_fast_api_app(agent=gakkoudayori_agent)
app.mount("/api/v1/agent", agent_app, name="agent")


# 4. (任意) ルートにウェルカムメッセージを追加
@app.get("/", include_in_schema=False)
def read_root():
    return {
        "message": "Welcome to Gakkoudayori AI Backend!",
        "docs": "/docs",
        "agent_ui": "/api/v1/agent/ui"
    }
```

### Step 4: サーバーを起動して確認する

以下のコマンドで、統合されたAPIサーバーを起動します。

```bash
uvicorn main:app --reload --port 8081
```

起動後、以下のURLにアクセスして動作を確認できます。

*   **OpenAPIドキュメント**: `http://localhost:8081/docs`
    *   通常APIとエージェントAPIの両方がリストされていることを確認できます。
*   **通常API（ヘルスチェック）**: `http://localhost:8081/api/v1/other/health`
    *   `{"status": "ok"}` が返されることを確認します。
*   **ADKエージェントWeb UI**: `http://localhost:8081/api/v1/agent/ui`
    *   ADK標準のチャットUIが表示され、エージェントと対話できることを確認します。
*   **ADKエージェントAPI**: `http://localhost:8081/api/v1/agent/invoke`
    *   `POST` リクエストを送ることで、エージェントを直接呼び出せます。


### メリット

*   **管理のシンプルさ**: 単一のアプリケーションとプロセスを管理するだけで済みます。
*   **開発の容易さ**: ローカルでの起動やデバッグが簡単で、`--reload` オプションも有効です。
*   **ADKの全機能活用**: `get_fast_api_app` を使うことで、APIエンドポイントだけでなく、デバッグに非常に便利な**Web UI**も利用できます。
*   **統一されたAPIドキュメント**: FastAPIの自動ドキュメント機能（Swagger UI / ReDoc）に、通常APIとエージェントAPIの両方が表示されます。
*   **コンポーネントの共有**: データベース接続や設定オブジェクトなどを、通常APIとエージェントで簡単に共有できます。

### デメリット

*   **密結合**: エージェントと他のAPIが同じコードベースに存在するため、結合度がやや高くなります。
*   **スケーリングの制約**: アプリケーション全体としてスケールする必要があり、特定の部分だけをスケールするのが困難です。
*   **ADKの内部実装への依存**: `get_fast_api_app` のようなヘルパー関数に依存します。（ただし、これは公式にサポートされている機能です）

## 5. 結論と推奨プラクティス

どちらのアプローチが最適かは、プロジェクトの要件や規模によって異なります。

| 観点 | サーバー分離（マイクロサービス） | 単一サーバー（モノリス） |
| :--- | :--- | :--- |
| **シンプルさ** | ✕ | ◎ |
| **スケーラビリティ** | ◎ | ◯ |
| **保守性** | ◯ | ◯ |
| **開発速度** | ◯ | ◎ |

**推奨:**

多くのプロジェクト、特に開発の初期〜中期段階においては、**アプローチ2（単一FastAPIサーバーへの統合）** がベストプラクティスと言えるでしょう。管理のシンプルさと開発の容易さが、インフラの複雑化というデメリットを上回ることが多いからです。

ADKが `get_fast_api_app` のような統合用のユーティリティを提供していることからも、このアプローチが公式にサポートされていることがわかります。

**例外:**

*   エージェントが非常に高い計算リソースを必要とし、他のAPIと明らかに負荷特性が異なる場合。
*   将来的に、エージェント部分を完全に別のサービスとして切り出す計画が明確にある場合。

このようなケースでは、初期段階から**アプローチ1（APIサーバーの分離）** を検討する価値があります。 