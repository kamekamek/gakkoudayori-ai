# ADK実装チェックリスト

## 🚀 スタートアップ・初期化

### ✅ ADK Runner 初期化
- [ ] `main.py` で `lifespan` イベントハンドラーを実装
- [ ] ADK サービスの初期化を起動時に実行
- [ ] アプリケーション終了時のクリーンアップを実装

```python
@asynccontextmanager
async def lifespan(app: FastAPI):
    adk_service = AdkAgentService()
    await adk_service.initialize()
    app.state.adk_service = adk_service
    yield
    if hasattr(app.state, 'adk_service'):
        app.state.adk_service.dispose()
```

### ✅ 依存性注入の設定
- [ ] FastAPIの依存性注入でサービスを正しく提供
- [ ] セッションサービスの適切な初期化
- [ ] サービス間の依存関係を明確に定義

## 🔧 セッション管理

### ✅ FirestoreSessionService の実装
- [ ] ADK標準のメソッドシグネチャに準拠
- [ ] `get_session(session_id, app_name=None, user_id=None)` の実装
- [ ] `create_session(app_name=None, user_id=None)` の実装
- [ ] オプション引数の適切な処理

### ✅ データモデルの整合性
- [ ] ADK標準の `Session` モデルを使用
- [ ] Firestoreデータの前処理（余分なフィールド除去）
- [ ] タイムゾーン情報の統一（`datetime.now(timezone.utc)` 使用）
- [ ] Pydantic バリデーションエラーの対策

```python
# タイムゾーン統一の例
from datetime import datetime, timezone

# ❌ 間違い
created_at = datetime.utcnow()

# ✅ 正しい
created_at = datetime.now(timezone.utc)
```

## 🤖 エージェント実装

### ✅ エージェント定義
- [ ] 各エージェントの役割を明確に定義
- [ ] プロンプトでの指示が具体的で曖昧さがない
- [ ] エージェント間の連携フローを設計

### ✅ transfer_to_agent の正しい使用
- [ ] `agent_name` 以外の引数は使用しない
- [ ] データ連携はセッション履歴を通じて行う
- [ ] プロンプトでAIに正しい使用法を明示

```python
# ❌ 間違った使用法
transfer_to_agent(
    agent_name="generator_agent",
    user_request="...",  # これはエラーになる
    parameters={}        # これもエラーになる
)

# ✅ 正しい使用法
transfer_to_agent(agent_name="generator_agent")
```

### ✅ プロンプトエンジニアリング
- [ ] AIに対する指示が明確で具体的
- [ ] 禁止事項を明確に記載
- [ ] 期待する出力形式を詳細に説明
- [ ] エラーパターンを予防する指示を含める

## 🌐 API・通信

### ✅ Server-Sent Events (SSE) 実装
- [ ] 正しいSSE形式（`data: {...}\n\n`）
- [ ] イベントタイプの統一（バックエンド↔フロントエンド）
- [ ] JSON形式の適切なエスケープ
- [ ] エラーハンドリングの実装

```python
# 正しいSSE形式
async def generate_sse_response():
    yield f"data: {json.dumps({'type': 'message', 'data': content})}\n\n"
    # ⚠️ \n\n は必須
```

### ✅ エラーハンドリング
- [ ] 各レイヤーでの適切なエラーキャッチ
- [ ] ユーザーフレンドリーなエラーメッセージ
- [ ] ログ出力の充実
- [ ] エラー時のグレースフルデグラデーション

## 📱 フロントエンド

### ✅ プロバイダー設計
- [ ] 状態管理の責務を明確に分離
- [ ] プロバイダー間のデータ連携を実装
- [ ] `addPostFrameCallback` を使用した安全な状態更新
- [ ] 無限ループの防止

```dart
// プロバイダー間連携の例
WidgetsBinding.instance.addPostFrameCallback((_) {
  final newHtml = adkChatProvider.generatedHtml;
  if (newHtml != null && 
      newHtml.isNotEmpty && 
      newHtml != previewProvider.htmlContent) {
    previewProvider.updateHtmlContent(newHtml);
  }
});
```

### ✅ UI実装
- [ ] レスポンシブデザインの実装
- [ ] ローディング状態の表示
- [ ] エラー状態の適切な表示
- [ ] アクセシビリティの考慮

### ✅ SSE受信処理
- [ ] イベントタイプの正確な判定
- [ ] JSON パースエラーの処理
- [ ] ストリーミングデータの適切な蓄積
- [ ] 接続エラー時の再接続処理

## 🔍 デバッグ・テスト

### ✅ ログ出力
- [ ] 各レイヤーでの適切なログ出力
- [ ] デバッグ情報の充実
- [ ] エラー発生時の詳細情報記録
- [ ] パフォーマンス測定のためのログ

### ✅ テスト戦略
- [ ] 単体テストの実装
- [ ] 統合テストの実装
- [ ] エンドツーエンドテストの実装
- [ ] エラー条件のテスト

### ✅ 段階的デバッグ
1. [ ] API レベルのテスト（Postman等）
2. [ ] エージェント単体のテスト
3. [ ] プロバイダー状態の監視
4. [ ] UI表示の確認

## 🚀 パフォーマンス

### ✅ 最適化ポイント
- [ ] ストリーミングレスポンスの活用
- [ ] 不要な再レンダリングの防止
- [ ] メモリリークの防止
- [ ] セッション管理の効率化

### ✅ モニタリング
- [ ] レスポンス時間の監視
- [ ] エラー率の監視
- [ ] リソース使用量の監視
- [ ] ユーザー行動の分析

## 🔒 セキュリティ

### ✅ セキュリティ対策
- [ ] 入力値のサニタイゼーション
- [ ] 認証・認可の実装
- [ ] セッション管理のセキュリティ
- [ ] APIキーの適切な管理

## 📚 ドキュメント

### ✅ ドキュメント整備
- [ ] API仕様書の作成
- [ ] エージェント設計書の作成
- [ ] トラブルシューティングガイド
- [ ] 運用マニュアルの作成

## 🎯 実装前の確認事項

### 必須確認ポイント
1. **ADK バージョンの確認** - 使用するADKバージョンと互換性
2. **依存関係の整理** - 必要なライブラリとバージョン
3. **環境設定** - 開発・本番環境の設定
4. **権限設定** - 必要なGCPサービスの権限

### よくある落とし穴
- `transfer_to_agent` の引数指定ミス
- SSE形式の `\n\n` 区切り忘れ
- タイムゾーン情報の不統一
- プロバイダー間連携の欠如
- エラーハンドリングの不備

## 🔄 継続的改善

### ✅ 改善サイクル
- [ ] ユーザーフィードバックの収集
- [ ] パフォーマンス分析
- [ ] エラー分析と対策
- [ ] 機能追加・改善の計画

---

このチェックリストを活用して、ADKエージェントシステムの確実な実装を進めてください。各項目を段階的に確認することで、今回のようなデバッグセッションを回避し、スムーズな開発を実現できます。 