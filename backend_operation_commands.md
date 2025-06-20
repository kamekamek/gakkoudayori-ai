# バックエンド動作確認コマンド集

## 🚀 基本操作

### サーバー起動
```bash
# 基本起動
cd backend/functions
python main.py

# 別ポートで起動（競合時）
FLASK_RUN_PORT=5000 python main.py

# デバッグモードで起動
FLASK_DEBUG=1 python main.py
```

### サーバー停止
```bash
# ポート8081のプロセス終了
lsof -ti:8081 | xargs kill -9

# または Ctrl+C でサーバー停止
```

## 🔍 API動作確認

### ヘルスチェック
```bash
curl http://localhost:8081/health
```

### 音声→JSON変換API (従来システム)
```bash
curl -X POST http://localhost:8081/api/v1/ai/speech-to-json \
  -H "Content-Type: application/json" \
  -d '{
    "transcribed_text": "今日は運動会の練習をしました。",
    "style": "classic",
    "use_adk_compliant": false,
    "force_legacy": true
  }'
```

### 音声→JSON変換API (ADK準拠システム)
```bash
curl -X POST http://localhost:8081/api/v1/ai/speech-to-json \
  -H "Content-Type: application/json" \
  -d '{
    "transcribed_text": "今日は運動会の練習をしました。",
    "style": "modern",
    "use_adk_compliant": true,
    "teacher_profile": {"grade_level": "3年1組"}
  }'
```

## 📱 フロントエンド連携

### フロントエンド起動（開発環境）
```bash
cd frontend
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8081/api/v1/ai
```

### または Makefile使用
```bash
make dev
```

## 🧪 テスト実行

### API接続デモ実行
```bash
cd /Users/kamenonagare/gakkoudayori-ai-adk-phase2
python api_connection_demo.py
```

### バックエンドテスト
```bash
cd backend/functions
pytest test_adk_compliant_tools.py -v
```

### モックデモ（API無しでテスト）
```bash
python mock_demo_runner.py
```

## 📊 ログ確認

### リアルタイムログ表示
サーバー起動中のターミナルでリアルタイム表示されます。

### 環境変数設定（必要に応じて）
```bash
export FLASK_ENV=development
export FLASK_DEBUG=1
export ADK_MIGRATION_PERCENTAGE=50
```

## 🚨 トラブルシューティング

### ポート競合時
```bash
# ポート使用状況確認
lsof -i:8081

# プロセス強制終了
lsof -ti:8081 | xargs kill -9
```

### Gemini API認証エラー時
```bash
# Google Cloud認証確認
gcloud auth list
gcloud auth application-default login
```

### Firebase認証エラー時
```bash
# Firebase認証確認
firebase login
firebase use yutori-kyoshitu
```

## 🌐 利用可能エンドポイント

- **ヘルスチェック**: `GET /health`
- **音声→JSON**: `POST /api/v1/ai/speech-to-json`
- **音声文字起こし**: `POST /api/v1/ai/transcribe` (設計中)

## 📱 フロントエンド・バックエンド統合テスト

1. **バックエンド起動**: `python main.py`
2. **API確認**: `python api_connection_demo.py`
3. **フロントエンド起動**: `make dev`
4. **統合動作確認**: ブラウザで動作確認

## 💡 開発のポイント

- ADK準拠システムは段階的移行中（現在移行率5%）
- `use_adk_compliant: true` で新システム強制使用
- `force_legacy: true` で従来システム強制使用
- システム情報は `system_metadata` で確認可能