# 📋 学校だよりAI 詳細実装タスク管理

**最終更新**: 2025-01-17  
**プロジェクト**: Google Cloud AI Hackathon Vol.2  

---

## 🎯 タスク管理システム概要

### 📊 作業者分類
- **🔧 MANUAL** - 人間が手動で行う設定・環境構築
- **🤖 AI** - AIに完全委託可能なコーディング・テスト
- **🤝 HYBRID** - 人間の指示でAIが実装する複雑な機能

### ⏱️ タスク粒度
- **細分化済み**: 各タスク30-60分で完了可能
- **並行実行**: 依存関係のないタスクは同時進行
- **TDD準拠**: 全コーディングタスクでテストファースト

### 📈 全体進捗サマリー
- **Total Tasks**: 58個
- **Completed**: 9個 (15.5%)
- **Manual Tasks**: 23個 (設定・環境構築)
- **AI Tasks**: 28個 (コーディング・テスト)
- **Hybrid Tasks**: 7個 (複雑実装)

---

## 📋 Phase 1: プロジェクト基盤構築

### 🌟 Phase 1 並行実行グループ

**Group A (順次実行)**: Google Cloud基盤
**Group B (並行可能)**: Firebase基盤  
**Group C (並行可能)**: Flutter Web基盤

---

### Group A: Google Cloud基盤 (順次実行)

#### T1-GCP-001-M: Google Cloudプロジェクト作成 ✅
- **作業者**: 🔧 MANUAL
- **所要時間**: 20分 (実績: 18分)
- **依存**: なし
- **進行状況**: ✅ 完了 (2025-06-09 23:48)
- **📄 参考**: `docs/HACKASON_RULE.md` Section 1
- **完了条件**: 
  - [x] Google Cloudプロジェクト作成完了
  - [x] プロジェクトID記録（環境変数用）
  - [x] 課金アカウント有効化確認
- **成果物**: プロジェクトID `yutori-kyoshitu-ai`

#### T1-GCP-002-M: 必要API有効化 ✅
- **作業者**: 🔧 MANUAL  
- **所要時間**: 30分 (実績: 25分)
- **依存**: T1-GCP-001-M ✅
- **進行状況**: ✅ 完了 (2025-06-09 23:52)
- **📄 参考**: `docs/HACKASON_RULE.md` Section 2
- **完了条件**:
  - [x] Vertex AI API有効化
  - [x] Speech-to-Text API有効化
  - [x] Cloud Storage API有効化
  - [x] Cloud Run API有効化
  - [x] Cloud Firestore API有効化
- **成果物**: 8つのAPI有効化完了

#### T1-GCP-003-M: サービスアカウント設定 ✅
- **作業者**: 🔧 MANUAL
- **所要時間**: 25分 (実績: 22分)
- **依存**: T1-GCP-002-M ✅
- **進行状況**: ✅ 完了 (2025-06-09 23:50)
- **📄 参考**: `docs/11_DESIGN_database_schema.md` Section 5
- **完了条件**:
  - [x] サービスアカウント作成
  - [x] 必要な権限付与（Vertex AI, Storage, Firestore）
  - [x] JSONキーファイルダウンロード
  - [x] キーファイル安全保存（gitignore確認）
- **成果物**: `backend/secrets/service-account-key.json`

#### T1-GCP-004-A: 認証テストコード実装
- **作業者**: 🤖 AI
- **所要時間**: 45分
- **依存**: T1-GCP-003-M
- **📄 参考**: `docs/30_API_endpoints.md` Section 1.2
- **TDD要件**: Red→Green→Refactor
- **完了条件**:
  - [ ] Google Cloud認証テスト実装
  - [ ] 各API接続テスト作成
  - [ ] 認証エラーハンドリングテスト
  - [ ] 全テスト通過確認

---

### Group B: Firebase基盤 (並行実行可能)

#### T1-FB-001-M: Firebase プロジェクト設定 ✅
- **作業者**: 🔧 MANUAL
- **所要時間**: 30分 (実績: 28分)
- **依存**: T1-GCP-001-M ✅
- **進行状況**: ✅ 完了 (2025-06-10 00:23)
- **📄 参考**: `docs/11_DESIGN_database_schema.md` Section 1-2
- **完了条件**:
  - [x] Firebaseプロジェクト作成
  - [x] Google Cloudプロジェクトと連携
  - [x] Firebase Console でプロジェクト確認
- **成果物**: firebase.json, firestore.rules, storage.rules

#### T1-FB-002-M: Authentication設定 ✅
- **作業者**: 🔧 MANUAL
- **所要時間**: 20分 (実績: 18分)
- **依存**: T1-FB-001-M ✅
- **進行状況**: ✅ 完了 (2025-06-10 00:43)
- **📄 参考**: `docs/30_API_endpoints.md` Section 1.1
- **完了条件**:
  - [x] Google プロバイダ有効化
  - [x] 承認済みドメイン設定
  - [x] OAuth設定完了
- **成果物**: Google認証プロバイダ設定完了

#### T1-FB-003-M: Firestore設定 ✅
- **作業者**: 🔧 MANUAL  
- **所要時間**: 25分 (実績: 23分)
- **依存**: T1-FB-001-M ✅
- **進行状況**: ✅ 完了 (2025-06-10 00:17)
- **📄 参考**: `docs/11_DESIGN_database_schema.md` Section 2
- **完了条件**:
  - [x] Firestore Database作成
  - [x] セキュリティルール初期設定
  - [x] インデックス設定準備
- **成果物**: Firestore Database + ルール設定完了

#### T1-FB-004-M: Cloud Storage設定 ✅
- **作業者**: 🔧 MANUAL
- **所要時間**: 20分 (実績: 25分)
- **依存**: T1-FB-001-M ✅
- **進行状況**: ✅ 完了 (2025-06-10 00:42)
- **📄 参考**: `docs/11_DESIGN_database_schema.md` Section 3
- **完了条件**:
  - [x] Storage Bucket作成
  - [x] セキュリティルール設定
  - [x] CORS設定完了
- **成果物**: Storage Bucket `yutori-kyoshitu.firebasestorage.app` + CORS設定

#### T1-FB-005-A: Firebase SDK統合コード ✅
- **作業者**: 🤖 AI
- **所要時間**: 50分 (実績: 48分)
- **依存**: T1-FB-002-M, T1-FB-003-M, T1-FB-004-M
- **進行状況**: ✅ 完了 (2025-01-17 13:45)
- **📄 参考**: `docs/30_API_endpoints.md` Section 1
- **TDD Phase**: ✅ 完了 (🔴→🟢→🔵)
- **完了条件**:
  - [x] Firebase初期化コード実装 ✅
  - [x] 認証ヘルパー関数実装 ✅
  - [x] Firestore接続テスト実装 ✅
  - [x] Storage接続テスト実装 ✅
  - [x] 全統合テスト通過 ✅ (20/20 テスト通過)
- **成果物**: 
  - `backend/functions/firebase_service.py` (Firebase SDK統合サービス)
  - `backend/functions/main.py` (Flask統合エントリーポイント)
  - `backend/functions/test_firebase_service.py` (包括的テストスイート)
  - **テストカバレッジ**: 100% (20テスト全通過)

---

### Group C: Flutter Web基盤 (並行実行可能)

#### T1-FL-001-M: Flutter Web環境構築 ✅
- **作業者**: 🔧 MANUAL
- **所要時間**: 35分 (実績: 30分)
- **依存**: なし
- **進行状況**: ✅ 完了 (2025-06-10 00:28)
- **📄 参考**: `frontend/README.md` Section 2
- **完了条件**:
  - [x] Flutter SDK最新版確認 (3.32.2)
  - [x] Chrome ブラウザ設定
  - [x] Flutter Web テストプロジェクト動作確認
  - [x] 開発ツール準備完了
- **成果物**: Flutter Web環境構築完了、build/web/ 生成確認

#### T1-FL-002-A: Flutter Webプロジェクト初期化
- **作業者**: 🤖 AI  
- **所要時間**: 45分
- **依存**: T1-FL-001-M
- **📄 参考**: `docs/23_SPEC_ui_component_design.md` Section 2
- **TDD要件**: Red→Green→Refactor
- **完了条件**:
  - [ ] プロジェクト構造作成
  - [ ] 必要依存関係追加（pubspec.yaml）
  - [ ] 基本ルーティング設定
  - [ ] プロジェクト起動テスト通過

#### T1-FL-003-A: Firebase Web SDK統合
- **作業者**: 🤖 AI
- **所要時間**: 40分  
- **依存**: T1-FL-002-A, T1-FB-001-M
- **📄 参考**: `docs/30_API_endpoints.md` Section 1.3
- **TDD要件**: Red→Green→Refactor
- **完了条件**:
  - [ ] firebase_core パッケージ統合
  - [ ] Firebase設定ファイル配置
  - [ ] Web初期化コード実装
  - [ ] Firebase接続テスト通過

#### T1-FL-004-H: 認証システム実装
- **作業者**: 🤝 HYBRID
- **所要時間**: 60分
- **依存**: T1-FL-003-A, T1-FB-002-M
- **📄 参考**: `docs/23_SPEC_ui_component_design.md` Section 3.1
- **TDD要件**: Red→Green→Refactor
- **完了条件**:
  - [ ] GoogleサインインUI実装
  - [ ] 認証状態管理Provider実装
  - [ ] ログイン・ログアウト機能
  - [ ] 認証フローテスト通過
  - [ ] ユーザー情報表示確認

#### T1-FL-005-A: 基本レイアウト実装
- **作業者**: 🤖 AI
- **所要時間**: 50分
- **依存**: T1-FL-004-H
- **📄 参考**: `docs/23_SPEC_ui_component_design.md` Section 4
- **TDD要件**: Red→Green→Refactor
- **完了条件**:
  - [ ] AppShell (3カラム) ウィジェット実装
  - [ ] レスポンシブデザイン対応
  - [ ] 基本画面（ホーム・設定）作成
  - [ ] ナビゲーションテスト通過

#### T1-FL-006-M: 環境変数設定
- **作業者**: 🔧 MANUAL  
- **所要時間**: 20分
- **依存**: T1-GCP-003-M, T1-FB-005-A
- **📄 参考**: 各種設定ファイル
- **完了条件**:
  - [ ] .env ファイル作成
  - [ ] Google Cloud認証情報設定
  - [ ] Firebase設定情報記録
  - [ ] 環境変数読み込み確認

---

## 📋 Phase 2: Quill.js統合・エディタ機能

### 🌟 Phase 2 並行実行グループ

**Group D**: Quill.js基盤実装
**Group E**: エディタ機能拡張（Group D完了後）

---

### Group D: Quill.js基盤実装

#### T2-QU-001-A: Quill.js HTMLファイル作成
- **作業者**: 🤖 AI
- **所要時間**: 45分
- **依存**: T1-FL-002-A
- **📄 参考**: `docs/22_SPEC_quill_features.md`, `docs/23_SPEC_quill_implementation.md`
- **TDD要件**: Red→Green→Refactor
- **完了条件**:
  - [ ] `web/quill/index.html` 作成
  - [ ] Quill.js ライブラリ読み込み
  - [ ] 基本設定・ツールバー定義
  - [ ] HTML表示テスト通過

#### T2-QU-002-A: WebView Flutter統合
- **作業者**: 🤖 AI
- **所要時間**: 55分
- **依存**: T2-QU-001-A, T1-FL-005-A
- **📄 参考**: `docs/23_SPEC_quill_implementation.md` Section 2
- **TDD要件**: Red→Green→Refactor
- **完了条件**:
  - [ ] webview_flutter_web パッケージ統合
  - [ ] WebViewウィジェット実装
  - [ ] Quill表示確認
  - [ ] WebView統合テスト通過

#### T2-QU-003-A: JavaScript Bridge実装
- **作業者**: 🤖 AI
- **所要時間**: 60分
- **依存**: T2-QU-002-A
- **📄 参考**: `docs/23_SPEC_quill_implementation.md` Section 3
- **TDD要件**: Red→Green→Refactor  
- **完了条件**:
  - [ ] JS ↔ Dart 通信実装
  - [ ] コマンド送受信機能
  - [ ] エラーハンドリング実装
  - [ ] Bridge通信テスト通過

#### T2-QU-004-H: Delta変換システム実装
- **作業者**: 🤝 HYBRID
- **所要時間**: 75分
- **依存**: T2-QU-003-A
- **📄 参考**: `docs/23_SPEC_quill_implementation.md` Section 4
- **TDD要件**: Red→Green→Refactor
- **完了条件**:
  - [ ] Quill Delta ↔ HTML 変換実装
  - [ ] データ整合性保証
  - [ ] 変換精度テスト実装
  - [ ] 双方向変換テスト通過

#### T2-QU-005-A: 状態管理Provider実装
- **作業者**: 🤖 AI
- **所要時間**: 50分  
- **依存**: T2-QU-004-H
- **📄 参考**: `docs/23_SPEC_ui_component_design.md` Section 5
- **TDD要件**: Red→Green→Refactor
- **完了条件**:
  - [ ] QuillEditorProvider実装
  - [ ] 編集状態管理
  - [ ] 保存・読み込み機能
  - [ ] 状態管理テスト通過

---

### Group E: エディタ機能拡張

#### T2-ED-001-A: 季節カラーパレット実装
- **作業者**: 🤖 AI
- **所要時間**: 45分
- **依存**: T2-QU-005-A
- **📄 参考**: `docs/10_DESIGN_color_palettes.md`
- **TDD要件**: Red→Green→Refactor
- **完了条件**:
  - [ ] 4季節CSSテーマ作成
  - [ ] テーマ切り替えUI実装
  - [ ] カラーパレット即座反映
  - [ ] テーマ切り替えテスト通過

#### T2-ED-002-A: ツールバーカスタマイズ
- **作業者**: 🤖 AI  
- **所要時間**: 40分
- **依存**: T2-QU-005-A
- **📄 参考**: `docs/22_SPEC_quill_features.md` Section 2
- **TDD要件**: Red→Green→Refactor
- **完了条件**:
  - [ ] 日本語ツールバー実装
  - [ ] 学級通信向け機能追加
  - [ ] ショートカットキー対応
  - [ ] ツールバー操作テスト通過

#### T2-ED-003-A: プレビュー機能実装
- **作業者**: 🤖 AI
- **所要時間**: 35分
- **依存**: T2-QU-004-H
- **📄 参考**: `docs/23_SPEC_ui_component_design.md` Section 6
- **TDD要件**: Red→Green→Refactor
- **完了条件**:
  - [ ] リアルタイムHTMLプレビュー
  - [ ] プレビューペイン実装
  - [ ] スタイル反映確認
  - [ ] プレビューテスト通過

---

## 📋 Phase 3: AI機能統合

### 🌟 Phase 3 並行実行グループ

**Group F**: 基本AI機能実装
**Group G**: マルチエージェント実装（Group F完了後）
**Group H**: AI補助UI実装（Group Fと並行）

---

### Group F: 基本AI機能実装

#### T3-AI-001-M: Vertex AI設定
- **作業者**: 🔧 MANUAL
- **所要時間**: 30分
- **依存**: T1-GCP-002-M
- **📄 参考**: `docs/21_SPEC_ai_prompts.md` Section 1
- **完了条件**:
  - [ ] Vertex AI コンソール設定
  - [ ] Gemini 1.5 Pro モデル有効化
  - [ ] API制限・課金設定確認
  - [ ] テスト呼び出し成功確認

#### T3-AI-002-A: Gemini API基盤実装
- **作業者**: 🤖 AI
- **所要時間**: 50分
- **依存**: T3-AI-001-M, T1-GCP-004-A
- **📄 参考**: `docs/30_API_endpoints.md` Section 3.1
- **TDD要件**: Red→Green→Refactor
- **完了条件**:
  - [ ] Gemini API クライアント実装
  - [ ] 基本リクエスト・レスポンス処理
  - [ ] エラーハンドリング実装
  - [ ] API接続テスト通過

#### T3-AI-003-H: HTML制約プロンプト実装
- **作業者**: 🤝 HYBRID
- **所要時間**: 60分
- **依存**: T3-AI-002-A
- **📄 参考**: `docs/21_SPEC_ai_prompts.md` Section 2-3
- **TDD要件**: Red→Green→Refactor
- **完了条件**:
  - [ ] HTML制約プロンプト実装
  - [ ] タグ制限ロジック実装
  - [ ] プロンプト品質テスト実装
  - [ ] 制約遵守テスト通過

#### T3-AI-004-M: Speech-to-Text設定
- **作業者**: 🔧 MANUAL
- **所要時間**: 25分  
- **依存**: T1-GCP-002-M
- **📄 参考**: `docs/30_API_endpoints.md` Section 3.2
- **完了条件**:
  - [ ] Speech-to-Text API設定
  - [ ] 日本語モデル設定
  - [ ] 音声フォーマット設定確認
  - [ ] テスト音声変換成功

#### T3-AI-005-A: 音声認識API実装
- **作業者**: 🤖 AI
- **所要時間**: 55分
- **依存**: T3-AI-004-M
- **📄 参考**: `docs/30_API_endpoints.md` Section 3.2
- **TDD要件**: Red→Green→Refactor
- **完了条件**:
  - [ ] Speech-to-Text クライアント実装
  - [ ] 音声ファイルアップロード処理
  - [ ] 文字起こし結果処理
  - [ ] 音声認識テスト通過

---

### Group G: マルチエージェント実装

#### T3-MA-001-H: Content Analyzer Agent
- **作業者**: 🤝 HYBRID
- **所要時間**: 90分
- **依存**: T3-AI-003-H
- **📄 参考**: `docs/24_SPEC_adk_multi_agent.md` Section 2.1
- **TDD要件**: Red→Green→Refactor
- **完了条件**:
  - [ ] テキスト構造化ロジック実装
  - [ ] 教育イベント抽出機能
  - [ ] 学習成果識別機能
  - [ ] エージェント単体テスト通過

#### T3-MA-002-H: Style Writer Agent
- **作業者**: 🤝 HYBRID
- **所要時間**: 90分
- **依存**: T3-AI-003-H
- **📄 参考**: `docs/24_SPEC_adk_multi_agent.md` Section 2.2
- **TDD要件**: Red→Green→Refactor
- **完了条件**:
  - [ ] 文体学習システム実装
  - [ ] 一貫性保持ロジック実装
  - [ ] 読みやすさ最適化実装
  - [ ] 文体適応テスト通過

#### T3-MA-003-H: Layout Designer Agent
- **作業者**: 🤝 HYBRID
- **所要時間**: 90分
- **依存**: T2-ED-001-A
- **📄 参考**: `docs/24_SPEC_adk_multi_agent.md` Section 2.3
- **TDD要件**: Red→Green→Refactor
- **完了条件**:
  - [ ] デザイン選択ロジック実装
  - [ ] 情報階層視覚化実装
  - [ ] レイアウト最適化実装
  - [ ] レイアウト品質テスト通過

#### T3-MA-004-H: Agent Orchestrator
- **作業者**: 🤝 HYBRID
- **所要時間**: 75分
- **依存**: T3-MA-001-H, T3-MA-002-H, T3-MA-003-H
- **📄 参考**: `docs/24_SPEC_adk_multi_agent.md` Section 3
- **TDD要件**: Red→Green→Refactor
- **完了条件**:
  - [ ] エージェント協調システム実装
  - [ ] 並行処理・同期制御実装
  - [ ] エラー処理・リトライ実装
  - [ ] 協調フローテスト通過

---

### Group H: AI補助UI実装

#### T3-UI-001-A: 折りたたみパネル基盤
- **作業者**: 🤖 AI
- **所要時間**: 45分
- **依存**: T1-FL-005-A
- **📄 参考**: `docs/24_SPEC_ai_assistant_panel.md` Section 2
- **TDD要件**: Red→Green→Refactor
- **完了条件**:
  - [ ] 折りたたみウィジェット実装
  - [ ] アニメーション実装
  - [ ] 状態管理実装
  - [ ] UI操作テスト通過

#### T3-UI-002-A: AI機能ボタン実装
- **作業者**: 🤖 AI
- **所要時間**: 40分
- **依存**: T3-UI-001-A
- **📄 参考**: `docs/24_SPEC_ai_assistant_panel.md` Section 3
- **TDD要件**: Red→Green→Refactor
- **完了条件**:
  - [ ] ワンクリック機能ボタン実装
  - [ ] アイコン・ラベル配置
  - [ ] ボタン動作実装
  - [ ] ボタン操作テスト通過

#### T3-UI-003-A: カスタム指示入力
- **作業者**: 🤖 AI
- **所要時間**: 35分
- **依存**: T3-UI-001-A
- **📄 参考**: `docs/24_SPEC_ai_assistant_panel.md` Section 4
- **TDD要件**: Red→Green→Refactor
- **完了条件**:
  - [ ] テキスト入力フィールド実装
  - [ ] プレースホルダー・検証機能
  - [ ] 入力値管理実装
  - [ ] 入力機能テスト通過

#### T3-UI-004-H: AI統合連携実装
- **作業者**: 🤝 HYBRID
- **所要時間**: 65分
- **依存**: T3-UI-002-A, T3-UI-003-A, T3-AI-002-A
- **📄 参考**: `docs/24_SPEC_ai_assistant_panel.md` Section 5
- **TDD要件**: Red→Green→Refactor
- **完了条件**:
  - [ ] UI → AI API連携実装
  - [ ] レスポンス処理・エラーハンドリング
  - [ ] エディタ挿入機能実装
  - [ ] AI統合テスト通過

---

## 📊 依存関係可視化

### 全体クリティカルパス分析

### ⚡ 並行実行可能グループ
- **Week 1**: Group A + Group B + Group C (並行)
- **Week 2**: Group D → Group E (順次) + Group F + Group H (並行)
- **Week 3**: Group G (マルチエージェント実装)

---

## 📈 進捗管理

### Phase 1 進捗 (18タスク)
- **Group A**: 3/4 完了 (GCP基盤) 🎯
- **Group B**: 5/5 完了 (Firebase基盤) ✅ 
- **Group C**: 1/6 完了 (Flutter基盤) ✅
- **環境設定**: 1/3 完了

### Phase 2 進捗 (8タスク)
- **Group D**: 0/5 完了 (Quill基盤)
- **Group E**: 0/3 完了 (エディタ機能)

### Phase 3 進捗 (13タスク)
- **Group F**: 0/5 完了 (基本AI)
- **Group G**: 0/4 完了 (マルチエージェント)
- **Group H**: 0/4 完了 (AI UI)

**全体進捗**: 9/58 タスク完了 (15.5%) ⬆️

---

## 🚀 今週の推奨アクション

### 🎯 Priority 1 (今日): 環境構築 ✅
1. ✅ T1-GCP-001-M → T1-GCP-002-M → T1-GCP-003-M (順次実行)
2. ✅ T1-FB-001-M (完了)、🚀 T1-FB-002-M (進行中)
3. ✅ T1-FL-001-M (完了)

### 🎯 Priority 2 (明日): 基盤コーディング
1. T1-GCP-004-A (AI実装)
2. T1-FB-005-A (AI実装) 
3. T1-FL-002-A → T1-FL-003-A (AI実装)

### 🎯 Priority 3 (今週末): 統合確認
1. T1-FL-004-H (協調実装)
2. T1-FL-005-A (AI実装)
3. Phase 1完全動作確認

---

## 📞 困ったときの参照先

### 🔧 Manual タスクのヘルプ
- **Google Cloud**: [Console ヘルプ](https://cloud.google.com/docs)
- **Firebase**: [Console ガイド](https://firebase.google.com/docs)
- **環境構築**: `frontend/README.md`

### 🤖 AI タスクのプロンプト例
- **コーディング**: "以下の仕様に基づいてテストファーストで実装してください"
- **テスト**: "以下の機能の単体テスト・統合テストを作成してください"
- **デバッグ**: "以下のエラーを解決してください"

### 📄 仕様参照
- **要件**: `docs/01_REQUIREMENT_overview.md`
- **UI設計**: `docs/23_SPEC_ui_component_design.md`
- **API**: `docs/30_API_endpoints.md`
- **データ設計**: `docs/11_DESIGN_database_schema.md`

---

**🎯 ゴール**: 効率的な並行開発でハッカソン完走！** 