# フロントエンド・バックエンド連携ガイド

## 🏗️ アーキテクチャ概要

```
Flutter Web (フロントエンド)    ←→    Python Flask (バックエンド)
├── config/app_config.dart           ├── main.py
├── services/ai_service.dart         ├── adk_compliant_orchestrator.py
├── services/audio_service.dart      ├── adk_compliant_tools.py
└── Web Audio API (JavaScript)       └── Gemini API / Speech-to-Text
```

## 🔌 API接続の仕組み

### 1. フロントエンド設定

**app_config.dart**: 環境別API URL設定
```dart
static const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8081/api/v1/ai',
);
```

**ai_service.dart**: HTTP通信とレスポンス処理
```dart
final response = await http.post(
  Uri.parse('$_baseUrl/speech-to-json'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    'transcribed_text': transcribedText,
    'use_adk_compliant': true,
    'teacher_profile': {'grade_level': '3年1組'}
  }),
);
```

### 2. バックエンド設定

**main.py**: Flask APIエンドポイント
```python
@app.route('/api/v1/ai/speech-to-json', methods=['POST'])
def speech_to_json():
    # ADK準拠システムまたは従来システム選択
    if should_use_new_system(migration_percentage):
        return adk_compliant_processing()
    else:
        return legacy_processing()
```

## 🎤 音声入力フロー

```
1. ユーザー音声入力
   ↓
2. Web Audio API (JavaScript) で録音
   ↓  
3. audio_service.dart でBase64エンコード
   ↓
4. POST /api/v1/ai/transcribe (バックエンド)
   ↓
5. Google Speech-to-Text API
   ↓
6. 文字起こし結果をフロントエンドに返却
   ↓
7. POST /api/v1/ai/speech-to-json (学級通信生成)
   ↓
8. Gemini API (ADK準拠処理)
   ↓
9. HTML学級通信をフロントエンドに返却
```

## 🚀 起動・テスト手順

### Step 1: バックエンド起動
```bash
cd backend/functions
python main.py
# → http://localhost:8081 で起動
```

### Step 2: API動作確認
```bash
# API接続テスト
python api_connection_demo.py

# ヘルスチェック単体
curl http://localhost:8081/health
```

### Step 3: フロントエンド起動
```bash
# 開発環境（localhost:8081接続）
make dev

# 本番環境（Cloud Run接続）
make staging
```

### Step 4: 統合テスト
1. ブラウザで Flutter アプリ開き
2. マイクボタンで音声録音
3. 自動文字起こし → 学級通信生成
4. プレビューでHTML確認

## 🔄 環境別接続設定

### 開発環境
```bash
flutter run -d chrome \
  --dart-define=API_BASE_URL=http://localhost:8081/api/v1/ai
```

### ステージング環境
```bash
flutter run -d chrome \
  --dart-define=API_BASE_URL=https://staging-yutori-backend.asia-northeast1.run.app/api/v1/ai
```

### 本番環境
```bash
flutter run -d chrome \
  --dart-define=API_BASE_URL=https://yutori-backend-944053509139.asia-northeast1.run.app/api/v1/ai
```

## 📊 レスポンス形式

### 成功レスポンス (ADK準拠)
```json
{
  "success": true,
  "data": {
    "html_content": "<h1>3年1組 学級通信</h1>...",
    "quality_score": 85,
    "processing_info": {
      "workflow_type": "hybrid_optimized",
      "processing_time": 1.5,
      "execution_id": "uuid-123"
    }
  },
  "system_metadata": {
    "system_used": "adk_compliant",
    "adk_compliant": true,
    "migration_percentage": 50
  }
}
```

### エラーレスポンス
```json
{
  "success": false,
  "error": "音声認識結果が空文字列です",
  "error_code": "EMPTY_TRANSCRIPT",
  "system_metadata": {
    "system_used": "adk_compliant",
    "fallback_used": true
  }
}
```

## 🛠️ デバッグ・トラブルシューティング

### フロントエンド側デバッグ
```dart
// app_config.dart で設定確認
AppConfig.printConfig();

// ai_service.dart でHTTPレスポンス確認
if (kDebugMode) debugPrint('API Response: ${response.body}');
```

### バックエンド側デバッグ
```python
# main.py でリクエスト内容確認
logger.info(f"Request data: {request.json}")

# adk_compliant_tools.py で処理時間確認
logger.info(f"Processing time: {processing_time}ms")
```

### CORS設定（必要に応じて）
```python
# main.py
from flask_cors import CORS
CORS(app, origins=['http://localhost:*', 'https://*.web.app'])
```

## 💡 開発のポイント

1. **段階的移行**: `migration_percentage` で新旧システム切り替え
2. **フォールバック**: ADKシステムでエラー時は従来システムに自動切り替え
3. **レスポンス互換性**: フロントエンドが期待する形式でレスポンス
4. **環境管理**: Makefileで環境別起動を統一
5. **デバッグ**: 各層でログ出力して問題特定しやすく

## 🔍 API仕様詳細

詳細は `api_connection_demo.py` 実行時の出力を参照してください。

## 📱 モバイル対応（将来対応）

現在はFlutter Web専用ですが、モバイル対応時は：
- `permission_handler` パッケージでマイク許可
- `record` パッケージで音声録音
- 同一APIエンドポイントで連携可能