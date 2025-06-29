# ADKエージェントシステム 動作原理とトラブルシューティングガイド

## 概要

このドキュメントは、GoogleのAgent Development Kit (ADK)を使用したマルチエージェントAIシステムの動作原理と、実際のデバッグ経験から得られたトラブルシューティング手法をまとめたものです。

## システム構成

### 1. バックエンド構成
```
backend/
├── app/
│   ├── adk/
│   │   ├── agents/           # ADKエージェント定義
│   │   │   ├── orchestrator_agent.py  # オーケストレーターエージェント
│   │   │   └── generator_agent.py     # ジェネレーターエージェント
│   │   └── tools/            # ADK用ツール
│   ├── api/v1/endpoints/     # FastAPI エンドポイント
│   ├── services/             # ビジネスロジックサービス
│   └── main.py              # アプリケーションエントリーポイント
```

### 2. フロントエンド構成
```
frontend/lib/
├── features/
│   ├── ai_assistant/         # AIチャット機能
│   │   ├── providers/        # 状態管理
│   │   └── widgets/          # UIコンポーネント
│   ├── editor/               # プレビュー・編集機能
│   │   ├── providers/        # プレビュー状態管理
│   │   └── widgets/          # プレビューUI
│   └── home/                 # メイン画面
└── services/                 # APIサービス
```

## 動作フロー

### 1. 基本的な処理フロー
1. **ユーザー入力** → フロントエンドのチャットUI
2. **API呼び出し** → バックエンドの `/api/v1/adk-agent/chat-stream` エンドポイント
3. **エージェント実行** → ADK Runnerによるマルチエージェント処理
4. **ストリーミング応答** → Server-Sent Events (SSE) でリアルタイム配信
5. **UI更新** → フロントエンドでプレビュー表示

### 2. エージェント間連携
- **オーケストレーター** → ユーザーリクエストを解析し、適切なエージェントに振り分け
- **ジェネレーター** → 具体的なHTML生成処理を実行
- **セッション共有** → エージェント間でコンテキストを共有

## 重要な技術的ポイント

### 1. ADK Runner の初期化

**問題**: アプリケーション起動時に `AttributeError: ADK Runner not initialized` エラー

**解決策**: FastAPIの `lifespan` イベントハンドラーでADK Runnerを初期化

```python
# main.py
@asynccontextmanager
async def lifespan(app: FastAPI):
    # 起動時処理
    adk_service = AdkAgentService()
    await adk_service.initialize()
    app.state.adk_service = adk_service
    
    yield
    
    # 終了時処理
    if hasattr(app.state, 'adk_service'):
        app.state.adk_service.dispose()

app = FastAPI(lifespan=lifespan)
```

### 2. セッション管理の正しい実装

**問題**: `FirestoreSessionService` のメソッドシグネチャがADKの期待と異なる

**解決策**: ADK標準に準拠したメソッド定義

```python
class FirestoreSessionService:
    async def get_session(self, session_id: str, app_name=None, user_id=None):
        # app_name, user_id はオプション引数として定義
        pass
    
    async def create_session(self, app_name=None, user_id=None):
        # ADK標準のシグネチャに準拠
        pass
```

### 3. データモデルの整合性

**問題**: Pydantic `ValidationError` - 余分なフィールドや型不整合

**解決策**: 
- ADK標準の `Session` モデルを使用
- Firestoreから読み込んだデータの前処理
- タイムゾーン情報の統一

```python
# 正しいデータ変換例
def _convert_to_adk_session(self, firestore_data: dict) -> Session:
    # 余分なフィールドを除去
    clean_data = {
        'id': firestore_data.get('id'),
        'messages': firestore_data.get('messages', []),
        # ADKが期待するフィールドのみ
    }
    return Session(**clean_data)
```

### 4. エージェント間の正しい連携方法

**最重要**: `transfer_to_agent` ツールの正しい使用法

**間違った使用例**:
```python
# ❌ これはエラーになる
transfer_to_agent(
    agent_name="generator_agent",
    user_request="学級通信を作成して",
    parameters={"style": "modern"}
)
```

**正しい使用例**:
```python
# ✅ 正しい使用法
transfer_to_agent(agent_name="generator_agent")
# データ連携はセッション履歴を通じて暗黙的に行われる
```

### 5. Server-Sent Events (SSE) の実装

**問題**: フロントエンドでJSONパースエラー、メッセージが表示されない

**解決策**: 正確なSSE形式とイベントタイプの統一

```python
# バックエンド - 正しいSSE形式
async def generate_sse_response():
    yield f"data: {json.dumps({'type': 'message', 'data': content})}\n\n"
    # ⚠️ \n\n は必須（メッセージ区切り）
```

```dart
// フロントエンド - 対応するイベントタイプ
if (event.type == 'message') {  // バックエンドと一致させる
    // メッセージ処理
}
```

### 6. プロバイダー間連携

**問題**: AIが生成したHTMLがプレビューに表示されない

**解決策**: プロバイダー間のデータ連携を `addPostFrameCallback` で実装

```dart
Widget build(BuildContext context) {
  final adkChatProvider = context.watch<AdkChatProvider>();
  
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final newHtml = adkChatProvider.generatedHtml;
    if (newHtml != null && newHtml.isNotEmpty) {
      context.read<PreviewProvider>().updateHtmlContent(newHtml);
    }
  });
  
  return Scaffold(/* UI構築 */);
}
```

## よくあるエラーと対処法

### 1. `NameError: name 'FirestoreSessionService' is not defined`
**原因**: 依存性注入の設定ミス
**対処**: FastAPIの依存性注入を正しく設定

### 2. `TypeError: got an unexpected keyword argument`
**原因**: メソッドシグネチャの不一致
**対処**: ADK標準に準拠したメソッド定義

### 3. `ValidationError` (Pydantic)
**原因**: データモデルの不整合
**対処**: 
- 余分なフィールドの除去
- タイムゾーン情報の統一
- 型変換の適切な実装

### 4. `AttributeError: 'NoneType' object has no attribute`
**原因**: Null値のハンドリング不足
**対処**: 適切なNull チェックの実装

### 5. フロントエンドでメッセージが表示されない
**原因**: 
- SSE形式の間違い
- イベントタイプの不一致
- プロバイダー連携の欠如
**対処**: 
- SSE形式の修正（`\n\n` 区切り）
- イベントタイプの統一
- プロバイダー間連携の実装

## デバッグのベストプラクティス

### 1. ログ出力の活用
```python
# バックエンド
import logging
logger = logging.getLogger(__name__)
logger.info(f"Processing request: {request_data}")
```

```dart
// フロントエンド
import 'package:flutter/foundation.dart';
debugPrint('[AdkChatProvider] Message received: $message');
```

### 2. 段階的なデバッグ
1. **API レベル** → Postmanなどでエンドポイントテスト
2. **エージェント レベル** → 個別エージェントの動作確認
3. **UI レベル** → プロバイダーの状態変化を監視

### 3. エラーハンドリング
```python
try:
    result = await some_operation()
except SpecificException as e:
    logger.error(f"Specific error: {e}")
    # 適切なエラーレスポンス
except Exception as e:
    logger.error(f"Unexpected error: {e}")
    # 汎用エラーハンドリング
```

## パフォーマンス最適化

### 1. ストリーミングレスポンス
- リアルタイム応答のためにSSEを活用
- チャンク単位での処理でユーザー体験向上

### 2. セッション管理
- 適切なセッションライフサイクル管理
- メモリリークの防止

### 3. エラー境界の設定
- フロントエンドでのエラー境界実装
- グレースフルデグラデーション

## 今後の改善点

1. **テスト自動化** → 単体テスト・統合テストの充実
2. **モニタリング** → APMツールの導入
3. **ドキュメント** → APIドキュメントの自動生成
4. **CI/CD** → デプロイメントパイプラインの改善

## まとめ

ADKエージェントシステムを安定稼働させるためには、以下の点が特に重要です：

1. **ADK Runnerの正しい初期化**
2. **セッション管理の標準準拠**
3. **エージェント間連携の理解**
4. **SSE通信の正確な実装**
5. **プロバイダー間のデータ連携**

これらのポイントを押さえることで、マルチエージェントAIシステムの安定した動作を実現できます。 