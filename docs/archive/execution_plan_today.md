# 🚀 今日の実行プラン - Phase 1 Critical Path

**目標**: Phase 1の70-80%完了（基盤構築）  
**時間**: 4-5時間  
**戦略**: Manual設定 → AI並列実装

---

## ⚡ 第1波：Manual設定（並行開始）

### 🔧 Session 1: GCP基盤（順次実行必須）
```bash
tmux attach -t yutori
# Session 1に切り替え
```

#### T1-GCP-001-M: Google Cloudプロジェクト作成 (20分)
- [ ] Google Cloud Console アクセス
- [ ] 新規プロジェクト作成
- [ ] プロジェクトID記録：`yutori-kyoshitu-ai`
- [ ] 課金アカウント有効化確認

#### T1-GCP-002-M: 必要API有効化 (30分)
- [ ] Vertex AI API有効化
- [ ] Speech-to-Text API有効化  
- [ ] Cloud Storage API有効化
- [ ] Cloud Run API有効化
- [ ] Cloud Firestore API有効化

#### T1-GCP-003-M: サービスアカウント設定 (25分)
- [ ] サービスアカウント作成
- [ ] 必要な権限付与（Vertex AI User, Storage Admin, Firestore User）
- [ ] JSONキーファイルダウンロード
- [ ] `backend/secrets/` に保存（gitignore確認）

### 🎨 Session 2: Flutter環境（並行実行）
```bash
# Session 2に切り替え（Ctrl+a, 2）
```

#### T1-FL-001-M: Flutter Web環境構築 (35分)
- [ ] Flutter SDK最新版確認：`flutter doctor`
- [ ] Chrome ブラウザ設定確認
- [ ] Flutter Web テストプロジェクト動作確認
- [ ] VS Code Flutter拡張確認

---

## 🤖 第2波：AI実装（並行実行開始）

### Session 1: 認証テスト実装
#### T1-GCP-004-A: 認証テストコード実装 (45分)
```bash
# Claude Codeでの実装指示例
"T1-GCP-003-M完了後、以下の仕様でTDDで認証テストを実装：
- Google Cloud認証テスト
- 各API接続テスト  
- 認証エラーハンドリングテスト
参考: docs/30_API_endpoints.md Section 1.2"
```

### Session 2: Flutter基盤実装  
#### T1-FL-002-A: Flutter Webプロジェクト初期化 (45分)
```bash
# Claude Codeでの実装指示例
"T1-FL-001-M完了後、以下の仕様でTDDでFlutterプロジェクトを初期化：
- プロジェクト構造作成
- pubspec.yaml依存関係追加
- 基本ルーティング設定
参考: docs/23_SPEC_ui_component_design.md Section 2"
```

### Session 3: Firebase基盤（段階的実行）
#### T1-FB-001-M: Firebase プロジェクト設定 (30分)
- [ ] Firebase Console アクセス
- [ ] Google Cloudプロジェクトと連携
- [ ] Firebase プロジェクト作成確認

---

## 🔄 第3波：統合フェーズ

### Session 2: Firebase統合実装
#### T1-FL-003-A: Firebase Web SDK統合 (40分)
```bash
# T1-FL-002-A + T1-FB-001-M完了後
"Firebase Web SDKを統合してください：
- firebase_core パッケージ統合
- Firebase設定ファイル配置  
- Web初期化コード実装
参考: docs/30_API_endpoints.md Section 1.3"
```

### Session 4: 統合テスト
#### 基盤動作確認
- [ ] GCP認証テスト実行
- [ ] Flutter Web起動確認
- [ ] Firebase接続確認

---

## 📊 完了条件チェックリスト

### 🎯 今日終了時の成功指標
- [ ] Google Cloud基盤100%完了（API有効化、認証設定）
- [ ] Flutter Web環境100%完了（プロジェクト起動成功）
- [ ] Firebase基盤70%完了（プロジェクト作成、基本SDK統合）
- [ ] 各基盤の接続テスト通過

### 📈 進捗確認方法
```bash
# 全セッション状況確認
tmux list-sessions && tmux list-windows -a

# 統合テスト実行
tmux send-keys -t yutori:4 "flutter test && npm run test" Enter
```

---

## 🚨 緊急時対応

### 🔧 Manual設定でブロック発生時
1. **Slack/Discord でヘルプ要請**
2. **代替手順の検索・実行**  
3. **並行実行可能タスクに一時切り替え**

### 🤖 AI実装でエラー発生時
1. **エラーログをSession 4のデバッグペインに表示**
2. **Claude Codeに詳細エラー情報を共有**
3. **TDDサイクルでのデバッグ実行**

---

## 🎯 明日への引き継ぎ

### 完了予想タスク
- Phase 1: Group A（GCP）100%完了
- Phase 1: Group C（Flutter）80%完了  
- Phase 1: Group B（Firebase）60%完了

### 明日優先タスク
1. **T1-FL-004-H**: 認証システム実装（60分、HYBRID）
2. **T1-FB-002-M〜005-A**: Firebase基盤完全構築
3. **Phase 2開始準備**: Quill.js設計確認

---

**🎯 ゴール**: 今日でPhase 1基盤を80%完成させ、明日からQuill統合に集中！ 