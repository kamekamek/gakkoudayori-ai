# バックエンド接続のトラブルシューティングガイド

フロントエンドからバックエンドAPIへの接続で `net::ERR_CONNECTION_TIMED_OUT` のようなエラーが発生した場合、多くはバックエンドサーバーが正常に応答していないことが原因です。このガイドでは、その際の一般的な調査手順と、過去に発生した具体的な問題とその解決策をまとめます。

## 基本的な調査手順

1.  **バックエンドサーバーの起動ログを確認する**:
    何よりもまず、`make backend-dev` などを実行しているターミナルのログを確認します。エラーメッセージが表示されていれば、それが直接的な原因です。

2.  **ヘルスチェックエンドポイントを叩く**:
    サーバーが起動しているように見えても、リクエストに応答できる状態かを確認するために、ヘルスチェック用のAPIを直接呼び出します。
    ```bash
    curl -s http://localhost:8081/api/v1/ai/health | jq .
    ```
    - `{"status": "ok", ...}` のような正常なJSONが返ってくれば、サーバーの基本機能は動作しています。
    - `curl: (7) Failed to connect to localhost port 8081: Connection refused` のようなメッセージが出れば、サーバープロセスが起動していません。ログを確認してください。
    - `{"detail":"Not Found"}` のようなメッセージが出れば、サーバーは起動していますが、リクエストしたURLのAPIが存在しません（後述のケース3を参照）。

---

## ケーススタディ: 過去の解決事例

### ケース1: `ImportError` によるサーバー起動失敗

-   **症状**: 起動ログに `ImportError: cannot import name 'SessionService' from 'google.adk.sessions'` のようなエラーが表示される。
-   **原因**: 使用しているライブラリ（この場合は `google-adk`）のバージョンアップによる仕様変更や、存在しないモジュールをインポートしようとしていることが原因です。
-   **解決策**:
    1.  エラーメッセージを元に、問題の `import` 文があるファイル（例: `backend/app/services/adk_session_service.py`）を特定します。
    2.  ライブラリの公式ドキュメントやリリースノート、関連するGitHubのIssueなどを確認し、現在のバージョンでの正しい使い方を調査します。
    3.  今回の例では、`SessionService` という基底クラスは存在せず、継承が不要であることが判明したため、該当の `import` 文とクラスの継承を削除して修正しました。

### ケース2: ライブラリ破損による `ImportError: dlopen(...)`

-   **症状**: 起動ログに `ImportError: dlopen(...) ... .so: ...` のような、共有ライブラリの読み込みに関するエラーが表示される。
-   **原因**: Pythonライブラリ（特にC言語の拡張モジュールを含むもの）のインストールが破損しているか、現在のOS環境と互換性がないバージョンがインストールされている可能性があります。
-   **解決策**: 破損したライブラリをクリーンに再インストールします。
    1.  まず、通常のアンインストールと再インストールを試みます。
        ```bash
        # venv環境下で実行
        pip uninstall <package-name>
        pip install <package-name>
        ```
    2.  アンインストールが `RECORD file not found` のようなエラーで失敗する場合、インストール情報自体が破損しています。その場合は、手動で関連ファイルを削除する必要があります。
        ```bash
        # site-packages内の関連ディレクトリを直接削除
        rm -rf backend/app/venv/lib/python3.11/site-packages/<package-name>
        rm -rf backend/app/venv/lib/python3.11/site-packages/<package-name>-*.dist-info
        ```
    3.  手動削除後、キャッシュを使用せずに強制的に再インストールします。
        ```bash
        pip install --force-reinstall --no-cache-dir <package-name>
        ```
        依存関係にあるライブラリが原因の場合は、そのライブラリを含む親ライブラリ（今回の場合は `litellm`）を再インストールすることで、依存関係が解決されます。

### ケース3: APIエンドポイントの `404 Not Found`

-   **症状**: サーバーは正常に起動しているが、特定のAPI（例: `/api/v1/ai/health`）にアクセスすると `404 Not Found` が返ってくる。
-   **原因**: リクエストされたURLに対応するAPIエンドポイントが、FastAPIのルーターに登録されていないためです。
-   **解決策**:
    1.  メインのルーターファイル（`backend/app/api/v1/router.py`）を確認し、目的のパス（prefix）を持つルーターが `include_router` で登録されているかを確認します。
    2.  登録されていない場合、エンドポイントを定義するファイル（例: `backend/app/api/v1/endpoints/ai.py`）を作成または修正し、FastAPIの `APIRouter` を使ってエンドポイントを実装します。
    3.  実装したルーターを、メインのルーターファイルで `include_router` を使って登録します。
        ```python
        # backend/app/api/v1/router.py の例
        from .endpoints import ai
        
        router.include_router(ai.router, prefix="/ai", tags=["AI Service"])
        ```
---
## 結論

バックエンドとの接続エラーは、まずバックエンドのログを注意深く読むことから始まります。エラーメッセージに基づいて、ライブラリの問題なのか、コード（ルーティングなど）の問題なのかを切り分け、段階的に対処していくことが解決への近道です。 