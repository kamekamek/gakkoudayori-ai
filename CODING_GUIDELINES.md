# コード品質ガイドライン - ゆとり職員室

このドキュメントは「ゆとり職員室」プロジェクトでのコーディング規約とレビューチェックリストを定義します。

## 🎯 基本方針

### 品質目標
- **可読性**: チームメンバー全員が理解できるコード
- **保守性**: 変更・拡張が容易な設計
- **信頼性**: エラーハンドリングとテストカバレッジの徹底
- **セキュリティ**: 機密情報漏洩・脆弱性対策の実装

### 言語・フレームワーク
- **フロントエンド**: Flutter/Dart + Provider状態管理
- **バックエンド**: Python/FastAPI + Firestore
- **インフラ**: Google Cloud (Cloud Run, Vertex AI)

---

## 📱 Flutter/Dart コーディング規約

### 命名規則（厳格遵守）
```dart
// ✅ Good: ファイル名・ディレクトリ名
models/document.dart
screens/dashboard_screen.dart
widgets/voice_input_panel.dart

// ✅ Good: クラス・列挙型
class DocumentModel { }
enum VoiceInputState { recording, processing, completed }

// ✅ Good: 変数・関数・フィールド
String documentTitle = '';
void saveDocument() { }
bool isRecording = false;

// ✅ Good: 定数
static const String apiBaseUrl = 'https://api.example.com';
static const Duration voiceTimeout = Duration(seconds: 30);

// ❌ Bad: キャメルケース以外
String document_title = '';  // スネークケース禁止
void SaveDocument() { }      // パスカルケース禁止
```

### アーキテクチャパターン（MVVM + Provider）
```dart
// ✅ Good: Providerクラス構造
class DocumentProvider extends ChangeNotifier {
  DocumentModel? _currentDocument;
  DocumentModel? get currentDocument => _currentDocument;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  Future<void> saveDocument(DocumentModel document) async {
    _setLoading(true);
    try {
      await _documentService.save(document);
      _currentDocument = document;
      notifyListeners();
    } catch (e) {
      _handleError(e);
    } finally {
      _setLoading(false);
    }
  }
  
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _handleError(dynamic error) {
    // エラーログ・ユーザー通知処理
  }
}
```

### ウィジェット設計原則
```dart
// ✅ Good: 単一責任・再利用可能
class VoiceInputButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool isRecording;
  final String? tooltip;
  
  const VoiceInputButton({
    super.key,
    this.onPressed,
    required this.isRecording,
    this.tooltip,
  });
  
  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

// ✅ Good: Consumer での状態管理
class DocumentEditor extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<DocumentProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const CircularProgressIndicator();
        }
        
        return TextEditor(
          content: provider.currentDocument?.content ?? '',
          onChanged: provider.updateContent,
        );
      },
    );
  }
}
```

### エラーハンドリング（必須実装）
```dart
// ✅ Good: Try-catch + ログ + ユーザー通知
Future<void> uploadAudioFile(File audioFile) async {
  try {
    await _speechService.transcribe(audioFile);
  } on NetworkException catch (e) {
    _logger.error('音声アップロード失敗: ネットワークエラー', e);
    _showUserError('インターネット接続を確認してください');
  } on ApiException catch (e) {
    _logger.error('API エラー', e);
    _showUserError('音声認識サービスが利用できません');
  } catch (e) {
    _logger.error('予期しないエラー', e);
    _showUserError('エラーが発生しました。時間をおいて再試行してください');
  }
}
```

### 非同期処理・ライフサイクル
```dart
// ✅ Good: 適切なdispose処理
class VoiceInputWidget extends StatefulWidget {
  @override
  State<VoiceInputWidget> createState() => _VoiceInputWidgetState();
}

class _VoiceInputWidgetState extends State<VoiceInputWidget> {
  StreamSubscription<String>? _voiceSubscription;
  Timer? _recordingTimer;
  
  @override
  void initState() {
    super.initState();
    _initializeVoiceInput();
  }
  
  @override
  void dispose() {
    _voiceSubscription?.cancel();
    _recordingTimer?.cancel();
    super.dispose();
  }
  
  // ✅ Good: mounted チェック
  Future<void> _processVoiceInput(String text) async {
    final result = await _aiService.enhanceText(text);
    if (mounted) {
      setState(() {
        _transcribedText = result;
      });
    }
  }
}
```

---

## 🐍 Python/FastAPI コーディング規約

### 命名規則・ファイル構造
```python
# ✅ Good: ファイル名・パッケージ名
app/
├── api/endpoints/
│   ├── speech.py
│   ├── documents.py
│   └── auth.py
├── models/
│   ├── document.py
│   └── user.py
├── services/
│   ├── speech_service.py
│   └── ai_service.py
└── utils/
    ├── security.py
    └── validators.py

# ✅ Good: 変数・関数名
def process_voice_input(audio_data: bytes) -> str:
    """音声データをテキストに変換する"""
    pass

# ✅ Good: クラス名
class DocumentService:
    def __init__(self, firestore_client: Client):
        self.db = firestore_client

# ✅ Good: 定数
MAX_AUDIO_SIZE_MB = 10
DEFAULT_VOICE_TIMEOUT_SECONDS = 30
API_VERSION = "v1"
```

### 型ヒント（必須）
```python
# ✅ Good: 完全な型ヒント
from typing import Optional, List, Dict, Any
from pydantic import BaseModel

class DocumentRequest(BaseModel):
    title: str
    content: str
    template_id: Optional[str] = None
    settings: Dict[str, Any] = {}

async def create_document(
    request: DocumentRequest,
    user_id: str,
    db: Client
) -> Dict[str, Any]:
    """新しいドキュメントを作成する
    
    Args:
        request: ドキュメント作成リクエスト
        user_id: 作成者のユーザーID
        db: Firestoreクライアント
        
    Returns:
        作成されたドキュメントの情報
        
    Raises:
        ValidationError: リクエストデータが不正
        FirestoreError: データベース操作失敗
    """
    pass
```

### FastAPI エンドポイント設計
```python
# ✅ Good: ルーター分離・バリデーション・エラーハンドリング
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPBearer

router = APIRouter(prefix="/api/v1/documents", tags=["documents"])
security = HTTPBearer()

@router.post("/", response_model=DocumentResponse)
async def create_document(
    request: DocumentRequest,
    user_id: str = Depends(get_current_user_id),
    db: Client = Depends(get_firestore_client)
) -> DocumentResponse:
    """ドキュメント作成エンドポイント"""
    try:
        # バリデーション
        if not request.title.strip():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="タイトルは必須です"
            )
        
        # ビジネスロジック
        document = await document_service.create(request, user_id, db)
        return DocumentResponse.from_document(document)
        
    except ValidationError as e:
        logger.error(f"バリデーションエラー: {e}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        logger.error(f"ドキュメント作成エラー: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="ドキュメント作成に失敗しました"
        )
```

### セキュリティ実装（必須）
```python
# ✅ Good: JWT認証・環境変数・権限チェック
import jwt
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

security = HTTPBearer()

async def get_current_user_id(
    credentials: HTTPAuthorizationCredentials = Depends(security)
) -> str:
    """JWTトークンからユーザーIDを取得"""
    try:
        payload = jwt.decode(
            credentials.credentials,
            settings.JWT_SECRET,  # 環境変数から取得
            algorithms=["HS256"]
        )
        user_id: str = payload.get("sub")
        if user_id is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="無効なトークン"
            )
        return user_id
    except jwt.InvalidTokenError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="認証が必要です"
        )

# ✅ Good: 機密情報保護
import os
from pydantic import BaseSettings

class Settings(BaseSettings):
    jwt_secret: str = os.getenv("JWT_SECRET", "")
    google_credentials_path: str = os.getenv("GOOGLE_APPLICATION_CREDENTIALS", "")
    
    class Config:
        env_file = ".env"

settings = Settings()
```

### ログ・監視（推奨実装）
```python
# ✅ Good: 構造化ログ・パフォーマンス監視
import logging
import time
from functools import wraps

logger = logging.getLogger(__name__)

def log_performance(func_name: str):
    """パフォーマンス測定デコレータ"""
    def decorator(func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            start_time = time.time()
            try:
                result = await func(*args, **kwargs)
                elapsed = time.time() - start_time
                logger.info(f"{func_name} 完了", extra={
                    "elapsed_seconds": elapsed,
                    "status": "success"
                })
                return result
            except Exception as e:
                elapsed = time.time() - start_time
                logger.error(f"{func_name} エラー", extra={
                    "elapsed_seconds": elapsed,
                    "error": str(e),
                    "status": "error"
                })
                raise
        return wrapper
    return decorator

@log_performance("音声認識")
async def transcribe_audio(audio_data: bytes) -> str:
    # 音声認識処理
    pass
```

---

## 🧪 テスト戦略・TDD

### Flutter テスト
```dart
// ✅ Good: Widget テスト
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  group('VoiceInputButton', () {
    testWidgets('録音状態に応じてアイコンが変わる', (WidgetTester tester) async {
      // Arrange
      bool isPressed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: VoiceInputButton(
            isRecording: false,
            onPressed: () => isPressed = true,
          ),
        ),
      );
      
      // Act & Assert
      expect(find.byIcon(Icons.mic), findsOneWidget);
      
      await tester.tap(find.byType(VoiceInputButton));
      expect(isPressed, isTrue);
    });
  });
}

// ✅ Good: Provider テスト
void main() {
  group('DocumentProvider', () {
    test('ドキュメント保存成功時にnotifyListenersが呼ばれる', () async {
      // Arrange
      final mockService = MockDocumentService();
      final provider = DocumentProvider(mockService);
      bool notified = false;
      provider.addListener(() => notified = true);
      
      // Act
      await provider.saveDocument(testDocument);
      
      // Assert
      expect(notified, isTrue);
      expect(provider.currentDocument, equals(testDocument));
    });
  });
}
```

### Python テスト
```python
# ✅ Good: pytest + async テスト
import pytest
from unittest.mock import AsyncMock, patch
from app.services.speech_service import SpeechService

@pytest.fixture
def speech_service():
    return SpeechService()

@pytest.mark.asyncio
async def test_transcribe_audio_success(speech_service):
    """音声認識成功ケース"""
    # Arrange
    test_audio = b"fake_audio_data"
    expected_text = "こんにちは"
    
    with patch.object(speech_service, '_call_google_api') as mock_api:
        mock_api.return_value = expected_text
        
        # Act
        result = await speech_service.transcribe(test_audio)
        
        # Assert
        assert result == expected_text
        mock_api.assert_called_once_with(test_audio)

@pytest.mark.asyncio
async def test_transcribe_audio_network_error(speech_service):
    """ネットワークエラーケース"""
    # Arrange
    with patch.object(speech_service, '_call_google_api') as mock_api:
        mock_api.side_effect = NetworkException("接続エラー")
        
        # Act & Assert
        with pytest.raises(NetworkException):
            await speech_service.transcribe(b"test_data")
```

---

## 📋 コードレビューチェックリスト

### 🔍 必須チェック項目

#### 機能・ロジック
- [ ] 要件定義通りの機能実装
- [ ] エッジケース・エラーケースの処理
- [ ] 適切なバリデーション実装
- [ ] セキュリティ脆弱性の検証

#### コード品質
- [ ] 命名規則遵守（ファイル・クラス・変数）
- [ ] 適切なコメント・ドキュメント
- [ ] 重複コード・長い関数の分割
- [ ] SOLID原則の適用

#### パフォーマンス
- [ ] 不要な再描画・再計算の回避
- [ ] 適切なキャッシュ戦略
- [ ] 非同期処理の最適化
- [ ] メモリリーク対策

#### テスト
- [ ] 単体テスト実装・実行成功
- [ ] カバレッジ80%以上達成
- [ ] 統合テスト実行成功
- [ ] エラーケースのテストカバー

#### セキュリティ
- [ ] API キー・機密情報のハードコード禁止
- [ ] 適切な認証・認可実装
- [ ] 入力値検証・サニタイズ
- [ ] HTTPS・CORS設定確認

### 🎯 推奨チェック項目

#### アーキテクチャ
- [ ] MVVMパターン遵守（Flutter）
- [ ] レイヤードアーキテクチャ（FastAPI）
- [ ] 依存性注入の適切な使用
- [ ] 単一責任原則の適用

#### ユーザビリティ
- [ ] アクセシビリティ対応
- [ ] レスポンシブデザイン
- [ ] 適切なエラーメッセージ
- [ ] ローディング状態の表示

#### 保守性
- [ ] 設定の外部化（環境変数）
- [ ] ログ出力の適切性
- [ ] 国際化対応（i18n）
- [ ] 型安全性の確保

---

## 🚀 開発フロー・ツール設定

### 必須ツール設定
```bash
# Flutter: 静的解析
flutter analyze

# Flutter: テスト実行
flutter test

# Python: 静的解析・フォーマット
pip install flake8 black mypy
flake8 app/
black app/
mypy app/

# Python: テスト実行
pytest --cov=app tests/
```

### VS Code設定（推奨）
```json
// .vscode/settings.json
{
  "dart.lineLength": 100,
  "python.linting.enabled": true,
  "python.linting.flake8Enabled": true,
  "python.formatting.provider": "black",
  "[python]": {
    "editor.formatOnSave": true
  },
  "[dart]": {
    "editor.formatOnSave": true
  }
}
```

### pre-commit設定
```yaml
# .pre-commit-config.yaml
repos:
  - repo: local
    hooks:
      - id: flutter-analyze
        name: Flutter Analyze
        entry: flutter analyze
        language: system
        pass_filenames: false
        
      - id: flutter-test
        name: Flutter Test
        entry: flutter test
        language: system
        pass_filenames: false
        
      - id: python-black
        name: Black
        entry: black
        language: system
        types: [python]
        
      - id: python-flake8
        name: Flake8
        entry: flake8
        language: system
        types: [python]
```

---

## 📊 品質メトリクス

### 目標指標
- **テストカバレッジ**: 全体80%以上、重要機能90%以上
- **静的解析**: エラー0件、警告最小化
- **パフォーマンス**: UI応答<100ms、API応答<500ms
- **セキュリティ**: 脆弱性スキャン月1回実施

### 継続的改善
- コードレビューでの指摘事項の蓄積・改善
- テスト品質・カバレッジの定期確認
- パフォーマンス測定・改善
- セキュリティ監査・脆弱性対応

---

**🎯 このガイドラインに従い、品質・保守性・セキュリティを重視した実装を行う**