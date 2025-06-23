# ADR-0002: Google ADK採用とTool/Agent分割方針

## ステータス

受諾済み（2025-06-20）

## コンテキスト

学校だよりAIの音声→AI→HTML→PDF のワークフローを実装するにあたり、各機能の責務分担とアーキテクチャ設計が必要でした。単一のモノリシックなシステムではなく、再利用可能で保守性の高いコンポーネント設計が求められています。

### 技術的課題

1. **複雑なワークフロー**: 音声認識→固有名詞補正→リライト→HTML生成→PDF変換→配信通知の多段階処理
2. **外部API依存**: Google Speech-to-Text、Vertex AI Gemini、Google Classroom等の外部サービス連携
3. **エラーハンドリング**: 各段階での失敗時のリトライ・フォールバック処理
4. **状態管理**: ユーザーコンテキストと進行状況の管理
5. **テスタビリティ**: 単体テストと統合テストの実装容易性

### 選択肢の検討

#### 選択肢A: モノリシック実装
- 単一のサービスクラスですべての処理を実行
- シンプルだが責務が不明確
- テストとメンテナンスが困難

#### 選択肢B: マイクロサービス分割
- 各機能を独立したサービスに分離
- インフラ複雑性とネットワーク遅延が課題
- オーバーエンジニアリングのリスク

#### 選択肢C: Google ADK (Agent Development Kit)
- Google推奨のAgent/Tool分割パターン
- 単機能Tool + 統合制御Agent の組み合わせ
- 適度な粒度で責務分離

## 決定

**Google ADK を採用し、以下の方針でTool/Agent分割を行う**

### Tool責務（単機能モジュール）
外部APIのラッパーまたは単純な処理を担当：

| Tool | 責務 | 実装形態 |
|------|------|----------|
| SpeechToTextTool | Google Speech-to-Text API呼び出し | @tool デコレータ付き関数 |
| UserDictTool | ローカル辞書による固有名詞置換 | @tool デコレータ付き関数 |
| TemplateTool | HTMLテンプレートへのデータ充填 | @tool デコレータ付き関数 |
| HtmlToPdfTool | wkhtmltopdf実行ラッパー | @tool デコレータ付き関数 |
| ClassroomTool | Google Classroom API投稿 | @tool デコレータ付き関数 |
| LineNotifyTool | LINE Notify API送信 | @tool デコレータ付き関数 |

### Agent責務（ワークフロー制御）
複数Toolの組み合わせと状態管理を担当：

| Agent | 責務 | 実装形態 |
|-------|------|----------|
| OrchestratorAgent | 全体ワークフロー制御、リトライ処理、エラーハンドリング | Agentクラス継承 |
| RewriteAgent | 教師との対話、リライト方針決定、複数案生成 | Agentクラス継承 |

### 分割の判断基準

**Tool化する機能**:
- 単一の外部API呼び出し
- 副作用が少ない処理
- 状態を持たない純粋関数に近い処理
- リトライロジックが不要な処理

**Agent化する機能**:
- 複数Toolの組み合わせが必要
- 状態管理が必要
- 分岐判断やリトライ制御が必要
- ユーザーとの対話が必要

## 理由

### ADK採用の利点

1. **Google Cloud公式推奨**: Vertex AI との統合がスムーズ
2. **適切な粒度**: マイクロサービスほど複雑でなく、モノリシックより構造化
3. **テスタビリティ**: Tool単体テストとAgent統合テストが可能
4. **再利用性**: 他のプロジェクトでもTool流用可能
5. **保守性**: 責務分離により変更影響範囲が限定的

### Tool/Agent分割の利点

1. **責務の明確化**: 各コンポーネントの役割が明確
2. **並列開発**: ToolとAgentを独立して開発可能
3. **エラー分離**: Tool失敗とAgent失敗を区別可能
4. **スケーラビリティ**: 必要なToolのみスケール可能



## 結果

### 期待される効果

1. **開発効率向上**: 並列開発とコンポーネント再利用
2. **品質向上**: 単体テストと統合テストの実装容易性
3. **保守性向上**: 変更影響範囲の限定とデバッグ容易性
4. **拡張性**: 新Toolの追加が容易

### リスク と対策

| リスク | 対策 |
|--------|------|
| ADK学習コスト | チーム向け勉強会実施 |
| Tool間の依存関係複雑化 | 依存関係図の維持 |
| パフォーマンス劣化 | Tool呼び出しオーバーヘッドの測定 |

## 実装計画

### Phase 1: 基盤構築
- [ ] ADK Python SDKセットアップ
- [ ] Tool/Agent雛形作成
- [ ] 統合テスト環境構築

### Phase 2: Core Tools実装
- [ ] SpeechToTextTool
- [ ] UserDictTool
- [ ] TemplateTool

### Phase 3: Agents実装
- [ ] OrchestratorAgent
- [ ] RewriteAgent

### Phase 4: 追加Tools実装
- [ ] HtmlToPdfTool
- [ ] ClassroomTool
- [ ] LineNotifyTool

## 関連資料

- [ADK Python SDK Documentation](https://cloud.google.com/vertex-ai/docs/agent-development-kit)
- [Google Cloud Agent Builder](https://cloud.google.com/agent-builder)
- [学校だよりAI要件定義](../archive/01_REQUIREMENT_overview.md)
- [ADKワークフローガイド](../guides/adk-workflow.md)

## 更新履歴

- 2025-06-20: 初版作成、ADK採用決定