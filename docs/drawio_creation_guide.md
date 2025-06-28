# 学校だよりAI システムアーキテクト図 作成手順書

## 🎯 目標
添付画像のような、プロフェッショナルで視覚的に美しいシステムアーキテクチャ図を作成する

## 📋 事前準備

### 1. draw.io (diagrams.net) を開く
- ブラウザで https://app.diagrams.net/ にアクセス
- 「Create New Diagram」をクリック
- 「Blank Diagram」を選択
- キャンバスサイズ: A4 Landscape (1400x900px) 推奨

### 2. アイコンライブラリの有効化
左パネルで「More Shapes」→以下をチェック:
- ✅ **Google Cloud Platform** (Firebase, Cloud Run等)
- ✅ **General** (基本図形)
- ✅ **Icons** (汎用アイコン)
- ✅ **Networking** (矢印等)

## 🏗️ 作成手順

### Phase 1: レイアウト設計 (15分)

#### 1.1 タイトル作成
```
1. 「Text」から大きなテキストボックスを挿入
2. テキスト: "🌸 学校だよりAI システムアーキテクチャ"
3. フォント: 24px, Bold
4. 色: #FF6B9D (ピンク)
5. 配置: 中央上部
```

#### 1.2 全体レイアウト構成
```
キャンバスを3つのゾーンに分割:
┌─────────────┬─────────────────────┬─────────────┐
│   ユーザー   │    Google Cloud     │ ストレージ   │
│    ゾーン    │     Platform        │ &外部サービス│
│   (左端)     │      (中央)         │   (右端)    │
└─────────────┴─────────────────────┴─────────────┘
```

### Phase 2: ユーザーゾーン作成 (10分)

#### 2.1 教師・ユーザー
```
1. 矩形図形を挿入 (左上 x:50, y:100)
2. サイズ: 200x60
3. 塗り: #E3F2FD (薄い青)
4. 境界: #1976D2, 太さ3px
5. テキスト: "👩‍🏫 教師・ユーザー" (14px, Bold)
```

#### 2.2 Flutter Web アプリ
```
1. 矩形図形を挿入 (x:50, y:200)
2. サイズ: 120x100
3. 塗り: #E3F2FD
4. 境界: #42A5F5, 太さ2px
5. アイコン追加:
   - GCPライブラリから「Flutter」アイコンを検索
   - なければ「📱」絵文字使用
6. テキスト: 
   ```
   Flutter Web
   PWA対応
   教師用UI
   ```
```

#### 2.3 音声入力
```
1. 矩形図形を挿入 (x:50, y:330)
2. サイズ: 120x100
3. 塗り: #F3E5F5 (薄い紫)
4. 境界: #9C27B0, 太さ2px
5. アイコン: 🎤
6. テキスト:
   ```
   音声入力
   MediaRecorder API
   WebRTC録音
   ```
```

### Phase 3: Google Cloud Platform ゾーン (20分)

#### 3.1 GCPコンテナ作成
```
1. 角丸矩形を挿入 (x:300, y:80)
2. サイズ: 700x500
3. 塗り: #E8F0FE (薄いGCP青)
4. 境界: #4285F4, 太さ3px, 破線スタイル
5. ラベル: "Google Cloud Platform" (16px, Bold, #4285F4)
```

#### 3.2 Cloud Run
```
1. 矩形図形を挿入 (x:580, y:120)
2. サイズ: 140x100
3. 塗り: #E8F0FE
4. 境界: #4285F4, 太さ2px
5. アイコン: GCPライブラリから「Cloud Run」
6. テキスト:
   ```
   Cloud Run
   FastAPI + ADK Server
   コンテナ実行環境
   ```
```

#### 3.3 ADKマルチエージェント エリア
```
1. 角丸矩形を挿入 (x:320, y:260)
2. サイズ: 660x200
3. 塗り: #E8F5E8 (薄い緑)
4. 境界: #4CAF50, 太さ3px
5. ラベル: "🤖 Google ADK マルチエージェント" (14px, Bold)
```

#### 3.4 エージェント群 (3つ横並び)
```
Orchestrator Agent:
- 位置: (x:340, y:300), サイズ: 100x80
- 塗り: #C8E6C9, 境界: #4CAF50
- アイコン: 🎯
- テキスト: "Orchestrator\nAgent\nワークフロー制御"

Planner Agent:
- 位置: (x:460, y:300), サイズ: 100x80  
- 塗り: #C8E6C9, 境界: #4CAF50
- アイコン: 💭
- テキスト: "Planner\nAgent\n対話・計画立案"

Generator Agent:
- 位置: (x:580, y:300), サイズ: 100x80
- 塗り: #C8E6C9, 境界: #4CAF50  
- アイコン: 📝
- テキスト: "Generator\nAgent\nHTML通信生成"
```

#### 3.5 Tools群 (右側小さく5つ)
```
配置: (x:720, y:300) から縦に並べる
各サイズ: 80x25, 塗り: #E8F5E8, 境界: #4CAF50

1. "Speech-to-Text"
2. "User Dict" 
3. "HTML Template"
4. "PDF Export"
5. "HTML Validator"
```

#### 3.6 Vertex AI Gemini
```
1. 矩形図形を挿入 (x:580, y:480)
2. サイズ: 140x80
3. 塗り: #FFF8E1 (薄い黄色)
4. 境界: #FFC107, 太さ2px
5. アイコン: ✨ (Geminiロゴが見つからない場合)
6. テキスト:
   ```
   Vertex AI Gemini
   2.5 Flash
   文章リライト・整形
   ```
```

### Phase 4: ストレージ&外部サービス ゾーン (15分)

#### 4.1 Firebase Authentication
```
1. 矩形図形を挿入 (x:1100, y:120)
2. サイズ: 120x100
3. 塗り: #FFF3E0 (薄いオレンジ)
4. 境界: #FF9800, 太さ2px
5. アイコン: GCPライブラリから「Firebase」または🔐
6. テキスト:
   ```
   Firebase
   Authentication
   ユーザー管理
   ```
```

#### 4.2 Cloud Firestore
```
1. 矩形図形を挿入 (x:1100, y:250)
2. サイズ: 120x100
3. 塗り: #FFF3E0
4. 境界: #FF9800, 太さ2px
5. アイコン: 📄
6. テキスト:
   ```
   Cloud Firestore
   NoSQL Database
   通信データ保存
   ```
```

#### 4.3 Cloud Storage
```
1. 矩形図形を挿入 (x:1100, y:380)
2. サイズ: 120x100
3. 塗り: #FFF3E0
4. 境界: #FF9800, 太さ2px
5. アイコン: 💾
6. テキスト:
   ```
   Cloud Storage
   Object Storage
   PDF・画像ファイル
   ```
```

#### 4.4 Google Classroom
```
1. 矩形図形を挿入 (x:1100, y:520)
2. サイズ: 120x100
3. 塗り: #E1F5FE (薄い水色)
4. 境界: #0277BD, 太さ2px
5. アイコン: 📚
6. テキスト:
   ```
   Google Classroom
   通信配布
   保護者・生徒配信
   ```
```

### Phase 5: データフロー矢印 (10分)

#### 5.1 主要な矢印
```
1. Flutter → Cloud Run
   - 色: #4CAF50, 太さ: 3px
   - ラベル: "API呼び出し"

2. 音声入力 → Orchestrator
   - 色: #4CAF50, 太さ: 3px
   - ラベル: "音声データ"

3. Agent間の矢印 (Orchestrator → Planner → Generator)
   - 色: #4CAF50, 太さ: 2px

4. Generator → Gemini
   - 色: #FFC107, 太さ: 2px
   - ラベル: "リライト要求"

5. Cloud Run → Firebase群
   - 色: #FF9800, 太さ: 2px
   - ラベル: "認証・保存"

6. Storage → Classroom
   - 色: #0277BD, 太さ: 2px
   - ラベル: "配布"
```

### Phase 6: 情報ボックス追加 (10分)

#### 6.1 技術スタック
```
位置: (x:50, y:650), サイズ: 300x150
塗り: #F8F9FA, 境界: #DEE2E6
タイトル: "📋 技術スタック"
内容:
🔵 Frontend: Flutter Web (PWA)
⚡ Backend: FastAPI + Google ADK  
🤖 AI: Multi-Agent System
✨ LLM: Vertex AI Gemini 2.5 Flash
🔥 Infrastructure: Firebase Services
📚 Integration: Google Classroom API
```

#### 6.2 主要特徴
```
位置: (x:400, y:650), サイズ: 300x150
塗り: #FFF3E0, 境界: #FF9800
タイトル: "🎯 主要特徴"
内容:
⚡ 高速処理: 2分以内で通信完成
🤖 マルチエージェント: 専門化されたAI協調
🎨 自動デザイン: グラレコ風レイアウト
📱 PWA対応: オフライン編集可能
🔄 リアルタイム: WebSocket通信
📊 品質保証: HTMLバリデーション
```

#### 6.3 処理フロー
```
位置: (x:750, y:650), サイズ: 300x150
塗り: #E8F5E8, 境界: #4CAF50
タイトル: "🔄 処理フロー"
内容:
1️⃣ 音声録音・転写
2️⃣ Orchestrator → Planner 対話
3️⃣ Generator → HTML生成
4️⃣ Gemini → 文章リライト
5️⃣ Firebase → データ保存
6️⃣ Classroom → 配布・共有
```

#### 6.4 技術革新ポイント
```
位置: (x:1100, y:650), サイズ: 300x150
塗り: #E3F2FD, 境界: #1976D2
タイトル: "💡 技術革新ポイント"
内容:
🎓 教育分野初のマルチエージェントAI
🔧 Tool/Agent分離設計思想
🎯 グラフィックレコーディング自動化
⚡ Google ADK活用による高速処理
🌐 フルクラウドネイティブ構成
🔒 エンタープライズレベルセキュリティ
```

## 🎨 デザイン調整

### カラーパレット
```
- Flutter: #42A5F5 (青)
- Google Cloud: #4285F4 (GCP青)
- ADK/AI: #4CAF50 (緑)
- Firebase: #FF9800 (オレンジ)
- Gemini: #FFC107 (黄色)
- Classroom: #0277BD (濃い青)
- 紫系: #9C27B0 (音声入力)
```

### フォント設定
```
- タイトル: 24px, Bold
- セクション見出し: 16px, Bold
- コンポーネント名: 14px, Bold
- 説明文: 12px, Regular
- 小さなラベル: 10px, Regular
```

## ✅ 完成チェックリスト

- [ ] タイトルが中央上部に配置されている
- [ ] 3つのゾーンが明確に分かれている
- [ ] 各コンポーネントに適切なアイコンが付いている
- [ ] データフローが矢印で示されている
- [ ] 色分けが統一されている
- [ ] 情報ボックスが配置されている
- [ ] 全体的にバランスが取れている
- [ ] 文字が読みやすいサイズになっている

## 💾 保存・エクスポート

1. **保存**: File → Save as → `gakkoudayori_architecture.drawio`
2. **PNG出力**: File → Export as → PNG (解像度: 300dpi推奨)
3. **PDF出力**: File → Export as → PDF (プレゼン用)
4. **SVG出力**: File → Export as → SVG (Web用)

## 🔧 よくある問題と解決策

**問題**: アイコンが見つからない
**解決**: 絵文字 (🎯📱🤖) を代替として使用

**問題**: レイアウトが崩れる
**解決**: Align機能を使用して整列

**問題**: 矢印がうまく繋がらない
**解決**: コネクターツールを使用

**問題**: 色が統一されない
**解決**: カラーパレットをメモしておく

---

この手順書に従えば、プロフェッショナルな学校だよりAIのシステムアーキテクト図が完成します！