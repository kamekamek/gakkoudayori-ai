# ADK セッション管理修正計画

## 📋 概要
Google ADK v1.0.0の公式ドキュメント調査に基づく、セッション管理の包括的修正計画

## 🚨 発見された主要問題

### 1. ADK v1.0.0 Breaking Changes未対応
- **問題**: 全サービスが非同期（async）に変更されたが、現在のコードが同期的
- **影響**: `BaseSessionService`のメソッドシグネチャが変更され、互換性がない
- **根拠**: ADK v1.0.0リリースノートの「Async Services」項目

### 2. セッション管理アーキテクチャの非推奨パターン
- **問題**: 自作`FirestoreSessionService`が最新ADKベストプラクティスに準拠していない
- **推奨**: Google公式の`VertexAiSessionService`または`InMemorySessionService`使用
- **根拠**: 公式ドキュメント「SessionService Implementations」

### 3. Import依存関係エラー
- **問題**: 削除された`models.adk_models`への依存が残っている
- **原因**: 相対importパスとモジュール構造の不整合

## 🔧 修正戦略

### Phase 1: 緊急修正（即座に実行）
1. ✅ **Import エラー修正**
   - `models.adk_models` import削除
   - 型定義をインライン化

2. ✅ **FirestoreSessionService最小限動作確保**
   - 破綻的なインポートを除去
   - 基本機能の動作確認

### Phase 2: ADK準拠修正（中期実装）
1. **セッションサービス選択**
   ```python
   # Option A: Google推奨 - VertexAiSessionService
   from google.adk.sessions import VertexAiSessionService
   session_service = VertexAiSessionService(project_id, location)
   
   # Option B: 開発用 - InMemorySessionService  
   from google.adk.sessions import InMemorySessionService
   session_service = InMemorySessionService()
   ```

2. **非同期対応**
   - 全セッション操作をasync/awaitパターンに変更
   - FastAPIエンドポイントの非同期化

### Phase 3: 本格的リファクタリング（長期実装）
1. **Vertex AI Agent Engine統合**
   - Reasoning Engineリソース作成
   - ADK Runnerの本格導入

2. **セッション状態管理最適化**
   - Event-based状態更新
   - ADK標準のState管理パターン採用

## 🛠️ 具体的実装手順

### 手順1: 設定ベース切り替え機能
```python
# config.py拡張
class Settings(BaseSettings):
    # ... existing fields ...
    
    # セッション管理設定
    SESSION_SERVICE_TYPE: str = "firestore"  # firestore, vertex_ai, memory
    VERTEX_AI_PROJECT_ID: Optional[str] = None
    VERTEX_AI_LOCATION: str = "us-central1"
    VERTEX_AI_REASONING_ENGINE_ID: Optional[str] = None
```

### 手順2: セッションサービスファクトリーパターン
```python
# session_factory.py
async def create_session_service(settings: Settings) -> BaseSessionService:
    if settings.SESSION_SERVICE_TYPE == "vertex_ai":
        return VertexAiSessionService(
            project=settings.VERTEX_AI_PROJECT_ID,
            location=settings.VERTEX_AI_LOCATION
        )
    elif settings.SESSION_SERVICE_TYPE == "memory":
        return InMemorySessionService()
    else:
        # Firestore (backward compatibility)
        firestore_client = get_firestore_client()
        return FirestoreSessionService(firestore_client)
```

### 手順3: エンドポイント非同期化
```python
# adk_agent.py リファクタリング
@router.post("/generate")
async def generate_newsletter(
    request: NewsletterGenerationRequest,
    session_service: BaseSessionService = Depends(get_session_service)
):
    # Async session operations
    session = await session_service.get_session(
        session_id=request.session_id,
        app_name=app_name,
        user_id=request.user_id
    )
    
    if not session:
        session = await session_service.create_session(
            session_id=request.session_id,
            app_name=app_name, 
            user_id=request.user_id
        )
```

## 📊 移行優先度マトリックス

| 項目 | 緊急度 | 実装コスト | ADK準拠度 | 優先度 |
|------|--------|------------|-----------|--------|
| Import修正 | 高 | 低 | 中 | **最高** |
| 非同期対応 | 高 | 中 | 高 | **高** |
| VertexAi移行 | 中 | 高 | 最高 | 中 |
| Event管理最適化 | 低 | 高 | 高 | 低 |

## 🎯 成功基準

### 短期目標 (1-2日)
- [ ] Import エラー解消
- [ ] 基本セッション機能動作確認
- [ ] 既存テスト通過

### 中期目標 (1-2週間)  
- [ ] 非同期セッション操作実装
- [ ] VertexAiSessionService統合
- [ ] パフォーマンス改善確認

### 長期目標 (1ヶ月)
- [ ] ADK Runner完全統合
- [ ] Event-drivenアーキテクチャ
- [ ] 本番環境デプロイ対応

## 🔍 リスク分析

### 高リスク
- **Breaking Changes**: ADK v1.0.0の非互換性により既存機能が破綻
- **緊急対応**: 本番環境でのセッション管理停止

### 中リスク  
- **移行コスト**: Vertex AI課金増加の可能性
- **複雑性**: 非同期プログラミングのデバッグ難易度上昇

### 軽減策
- 段階的移行によるリスク分散
- 充実したテストカバレッジ
- ロールバック計画の準備

## 📚 参考資料

1. **Google ADK Official Documentation**
   - Sessions API: https://google.github.io/adk-docs/sessions/session/
   - Agent Engine Sessions: https://cloud.google.com/vertex-ai/generative-ai/docs/agent-engine/sessions/manage-sessions-adk

2. **Breaking Changes Documentation**
   - ADK v1.0.0 Release Notes
   - Async Services Migration Guide

3. **Best Practices**
   - Session Lifecycle Management
   - VertexAiSessionService Implementation Patterns 