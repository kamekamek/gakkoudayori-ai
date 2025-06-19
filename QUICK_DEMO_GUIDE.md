# 🚀 学校だよりAI - 動作確認ガイド

**最終更新**: 2025年6月19日  
**想定時間**: 5-15分  

## 📋 準備

現在以下が起動中です：
- ✅ Flutterプロジェクト準備完了（dependencies installed）
- ✅ バックエンドサーバー起動中（http://127.0.0.1:8081）

## 🎯 推奨動作確認方法

### 🥇 **方法1: 個別機能テスト（最も簡単）**

バックエンドディレクトリで以下を実行：

```bash
cd backend/functions

# 1. PDF生成機能テスト（2分）
python test_pdf_layout_stability.py

# 2. 拡張機能全体テスト（1分）
python test_adk_enhanced_features.py

# 3. 完全フロー統合テスト（5分・少し時間かかります）
python test_adk_complete_flow.py
```

**期待される結果**:
```
🎯 成功率: 4/4 (100.0%)
✅ 完璧！全ての安定化機能が動作
```

### 🥈 **方法2: Flutter Webアプリテスト**

1. **Webアプリ起動**:
```bash
cd frontend
flutter run -d chrome --web-port=5000
```

2. **ブラウザで確認**:
   - `http://localhost:5000` が自動で開きます
   - 音声録音ボタンをクリック
   - 「今日は運動会の練習をしました」等を話す
   - AI生成結果を確認

### 🥉 **方法3: API直接テスト**

**バックエンドサーバーが起動している状態**で：

```bash
# 健康チェック
curl http://127.0.0.1:8081/health

# 学級通信生成（従来方式）
curl -X POST http://127.0.0.1:8081/api/v1/ai/generate-newsletter \
-H "Content-Type: application/json" \
-d '{
  "transcribed_text": "今日は運動会の練習をしました。子どもたちはとても頑張っていました。",
  "use_adk": false,
  "template_type": "daily_report"
}'
```

## 📊 確認ポイント

### ✅ **成功の確認方法**

#### 個別機能テスト:
- **PDF生成**: 4/4テスト成功 + Base64 PDFデータ出力
- **拡張機能**: 5/5テスト成功 + ファイルサイズ表示
- **完全フロー**: 4/4フェーズ成功

#### Webアプリ:
- 音声録音ボタンが動作
- リアルタイム文字起こし表示
- HTML形式の学級通信生成
- PDF出力ボタンクリック可能

#### API:
- HTTP 200レスポンス
- `"success": true` を含むJSON
- HTMLコンテンツ生成

### ⚠️ **よくあるエラー**

1. **Vertex AI認証エラー**:
```json
{"error": "Publisher Model was not found"}
```
→ **対処**: 個別機能テストを使用（APIキー不要）

2. **Port already in use**:
```
Port 8081 is already in use
```
→ **対処**: 既にサーバー起動中のため、そのまま使用可能

3. **Flutter Chrome未検出**:
```
No supported devices found
```
→ **対処**: `flutter devices` で確認、Chromeインストール

## 🎯 機能別確認項目

### 📄 **PDF生成機能**
- ✅ 日本語文字化け対策
- ✅ レイアウト崩れ防止
- ✅ 辞書型入力→文字列変換
- ✅ 空コンテンツ処理

### 🖼️ **画像・メディア統合**
- ✅ 400x300 PNG画像生成
- ✅ 季節別カラースキーム
- ✅ プレースホルダー配置

### 📤 **配信・投稿機能**
- ✅ 受信者数推定（60名）
- ✅ マルチチャネル配信
- ✅ QRコード・URL生成

### 🤖 **ADKマルチエージェント**
- ✅ 8エージェント協調動作
- ✅ PDF・画像・配信統合
- ✅ 品質チェック機能

## 🎊 デモンストレーション例

### シナリオ: 運動会練習の学級通信作成

1. **音声入力**: 
   "今日は運動会の練習をしました。子どもたちは徒競走とダンスの練習を頑張っていました。特にたかしくんは走るのが上達しました。"

2. **期待される出力**:
   ```html
   <h1>学級通信 6月号</h1>
   <h2>運動会練習について</h2>
   <p>今日は運動会の練習をしました...</p>
   ```

3. **PDF出力**: A4サイズ、日本語対応、印刷最適化済み

4. **配信準備**: 60名の保護者向け、Web・Email・モバイル対応

## 🔧 トラブルシューティング

### 問題: テストが失敗する
**解決策**: 
```bash
# 依存関係再インストール
pip install -r requirements.txt

# ログ確認
tail -f server.log
```

### 問題: Flutterアプリが起動しない
**解決策**:
```bash
flutter clean
flutter pub get
flutter run -d chrome --web-port=5001  # ポート変更
```

### 問題: API認証エラー
**解決策**: 
- 個別機能テスト使用（認証不要）
- ローカル開発モード確認

## 📞 サポート

### 即座確認したい場合:
```bash
python test_pdf_layout_stability.py
```

### 詳細機能確認:
```bash
python test_adk_enhanced_features.py
```

### フル機能確認:
```bash  
python test_adk_complete_flow.py
```

**すべて100%成功すれば、システムは完璧に動作しています！** 🎉

---

**💡 TIP**: 最も簡単な確認方法は `python test_pdf_layout_stability.py` です。2分で全機能の動作確認ができます。