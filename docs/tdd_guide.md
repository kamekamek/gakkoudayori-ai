# TDD実践ガイド - ゆとり職員室

**音声入力→AIチャット編集→グラレコ風HTML→PDF配信システムのテスト駆動開発**

---

**📚 ドキュメントナビ**: [📋 Index](index.md) | [📖 Overview](README.md) | [📝 要件定義](REQUIREMENT.md) | [🏗️ システム設計](system_design.md) | [📋 タスク](tasks.md) | **🧪 TDD**

---

## 🏗️ テスト環境セットアップ

### Flutter Web テスト環境

```yaml
# pubspec.yaml に追加
dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.4.2           # モック作成
  build_runner: ^2.4.7      # コード生成
  http_mock_adapter: ^0.4.4 # HTTP モック
  integration_test:
    sdk: flutter
```

### FastAPI テスト環境

```python
# requirements-dev.txt
pytest==7.4.2
pytest-asyncio==0.21.1
httpx==0.24.1              # テスト用HTTPクライアント
pytest-mock==3.11.1       # モック機能
pytest-cov==4.1.0         # カバレッジ測定
faker==19.6.2              # テストデータ生成
```

---

## 🎯 機能別TDD実践例

### 1. 音声認識機能のTDD

#### 🔴 Step 1: 失敗するテストを書く

```dart
// test/services/speech_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:yutorikyoshitu/services/speech_service.dart';

class MockSpeechToText extends Mock implements SpeechToText {}

void main() {
  group('SpeechService', () {
    late SpeechService speechService;
    late MockSpeechToText mockSpeechToText;

    setUp(() {
      mockSpeechToText = MockSpeechToText();
      speechService = SpeechService(speechToText: mockSpeechToText);
    });

    test('音声ファイルからテキストに変換できる', () async {
      // Arrange
      const expectedText = '今日の運動会についてお知らせします';
      const audioFilePath = 'test_audio.wav';
      
      when(mockSpeechToText.transcribe(audioFilePath))
          .thenAnswer((_) async => expectedText);

      // Act
      final result = await speechService.transcribeAudio(audioFilePath);

      // Assert
      expect(result.text, equals(expectedText));
      expect(result.confidence, greaterThan(0.9));
      verify(mockSpeechToText.transcribe(audioFilePath)).called(1);
    });

    test('ユーザー辞書を使用して固有名詞を正確に認識する', () async {
      // Arrange
      const userDict = ['田中太郎', '3年1組', '運動会'];
      const expectedText = '田中太郎君は3年1組の運動会で活躍しました';
      
      when(mockSpeechToText.transcribeWithDict(any, userDict))
          .thenAnswer((_) async => expectedText);

      // Act
      final result = await speechService.transcribeWithUserDict(
        'test_audio.wav', 
        userDict
      );

      // Assert
      expect(result.text, contains('田中太郎'));
      expect(result.text, contains('3年1組'));
      expect(result.text, contains('運動会'));
    });
  });
}
```

#### 🟢 Step 2: 最小限の実装でテストを通す

```dart
// lib/services/speech_service.dart
class SpeechResult {
  final String text;
  final double confidence;
  
  SpeechResult({required this.text, required this.confidence});
}

class SpeechService {
  final SpeechToText speechToText;
  
  SpeechService({required this.speechToText});

  Future<SpeechResult> transcribeAudio(String audioFilePath) async {
    final text = await speechToText.transcribe(audioFilePath);
    return SpeechResult(text: text, confidence: 0.95);
  }

  Future<SpeechResult> transcribeWithUserDict(
    String audioFilePath, 
    List<String> userDict
  ) async {
    final text = await speechToText.transcribeWithDict(audioFilePath, userDict);
    return SpeechResult(text: text, confidence: 0.97);
  }
}
```

#### 🔵 Step 3: リファクタリング

```dart
// lib/services/speech_service.dart (改善版)
class SpeechService {
  final SpeechToText speechToText;
  final double _minimumConfidence = 0.9;
  
  SpeechService({required this.speechToText});

  Future<SpeechResult> transcribeAudio(String audioFilePath) async {
    try {
      final text = await speechToText.transcribe(audioFilePath);
      final confidence = _calculateConfidence(text);
      
      if (confidence < _minimumConfidence) {
        throw SpeechRecognitionException('認識精度が低すぎます: $confidence');
      }
      
      return SpeechResult(text: text, confidence: confidence);
    } catch (e) {
      throw SpeechRecognitionException('音声認識に失敗しました: $e');
    }
  }

  double _calculateConfidence(String text) {
    // 実際の信頼度計算ロジック
    return text.isNotEmpty ? 0.95 : 0.0;
  }
}
```

### 2. Geminiリライト機能のTDD

#### 🔴 失敗するテストを書く

```python
# backend/tests/test_gemini_service.py
import pytest
from unittest.mock import Mock, AsyncMock
from app.services.gemini_service import GeminiService, RewriteRequest, RewriteResult

@pytest.fixture
def mock_gemini_client():
    return Mock()

@pytest.fixture
def gemini_service(mock_gemini_client):
    return GeminiService(client=mock_gemini_client)

@pytest.mark.asyncio
async def test_rewrite_text_for_newsletter(gemini_service, mock_gemini_client):
    """学級通信向けの文章リライト機能"""
    # Arrange
    original_text = "今日運動会やった。みんな頑張ってた。"
    expected_rewritten = "本日は運動会を開催いたしました。子どもたちは皆、一生懸命に取り組んでいました。"
    
    mock_gemini_client.generate_content = AsyncMock(return_value=expected_rewritten)
    
    request = RewriteRequest(
        text=original_text,
        style="polite",
        audience="parents"
    )
    
    # Act
    result = await gemini_service.rewrite_text(request)
    
    # Assert
    assert result.rewritten_text == expected_rewritten
    assert result.original_text == original_text
    assert "敬語" in result.improvements
    assert result.processing_time_ms < 500  # パフォーマンス要件

@pytest.mark.asyncio
async def test_generate_headings_from_content(gemini_service, mock_gemini_client):
    """コンテンツから見出し自動生成"""
    # Arrange
    content = """
    今日は運動会でした。天気もよく、子どもたちは元気いっぱいでした。
    午前中は徒競走がありました。みんな最後まで諦めずに走りました。
    午後は団体競技でした。クラス一丸となって頑張りました。
    """
    
    expected_headings = [
        "晴天の運動会開催",
        "徒競走での頑張り",
        "団体競技でのチームワーク"
    ]
    
    mock_gemini_client.generate_content = AsyncMock(return_value=expected_headings)
    
    # Act
    result = await gemini_service.generate_headings(content)
    
    # Assert
    assert len(result.headings) == 3
    assert all("運動会" in heading or "競技" in heading or "チーム" in heading 
              for heading in result.headings)
    assert result.confidence > 0.8
```

#### 🟢 最小限の実装

```python
# backend/app/services/gemini_service.py
from dataclasses import dataclass
from typing import List
import time

@dataclass
class RewriteRequest:
    text: str
    style: str = "polite"
    audience: str = "parents"

@dataclass
class RewriteResult:
    original_text: str
    rewritten_text: str
    improvements: List[str]
    processing_time_ms: int

@dataclass
class HeadingResult:
    headings: List[str]
    confidence: float

class GeminiService:
    def __init__(self, client):
        self.client = client
    
    async def rewrite_text(self, request: RewriteRequest) -> RewriteResult:
        start_time = time.time()
        
        rewritten = await self.client.generate_content(request.text)
        
        processing_time = int((time.time() - start_time) * 1000)
        
        return RewriteResult(
            original_text=request.text,
            rewritten_text=rewritten,
            improvements=["敬語調整", "読みやすさ向上"],
            processing_time_ms=processing_time
        )
    
    async def generate_headings(self, content: str) -> HeadingResult:
        headings = await self.client.generate_content(content)
        return HeadingResult(headings=headings, confidence=0.9)
```

### 3. HTMLエディタ機能のTDD

#### 🔴 失敗するテストを書く

```dart
// test/widgets/html_editor_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yutorikyoshitu/widgets/newsletter_html_editor.dart';

void main() {
  group('NewsletterHtmlEditor', () {
    testWidgets('HTMLエディタが正常に表示される', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NewsletterHtmlEditor(
              onContentChanged: (String html) {},
            ),
          ),
        ),
      );

      // Act & Assert
      expect(find.byType(NewsletterHtmlEditor), findsOneWidget);
      expect(find.text('学級通信の内容を入力...'), findsOneWidget);
    });

    testWidgets('テキスト入力でHTML生成される', (WidgetTester tester) async {
      // Arrange
      String capturedHtml = '';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NewsletterHtmlEditor(
              onContentChanged: (String html) {
                capturedHtml = html;
              },
            ),
          ),
        ),
      );

      // Act
      await tester.enterText(find.byType(TextField), '今日の運動会について');
      await tester.pump();

      // Assert
      expect(capturedHtml, contains('今日の運動会について'));
      expect(capturedHtml, contains('<p>'));  // HTMLタグが含まれる
    });
  });
}
```

---

## 🔧 統合テストの実装

### API統合テスト

```python
# backend/tests/test_api_integration.py
import pytest
from httpx import AsyncClient
from app.main import app

@pytest.mark.asyncio
async def test_speech_to_text_to_rewrite_flow():
    """音声認識→リライトの統合フロー"""
    async with AsyncClient(app=app, base_url="http://test") as client:
        # Step 1: 音声アップロード
        with open("test_audio.wav", "rb") as audio_file:
            response = await client.post(
                "/api/v1/speech/transcribe",
                files={"audio_file": audio_file},
                data={"user_dict": ["運動会", "3年1組"]}
            )
        
        assert response.status_code == 200
        transcript_data = response.json()
        
        # Step 2: リライト実行
        rewrite_response = await client.post(
            "/api/v1/content/generate",
            json={
                "text": transcript_data["transcript"],
                "operations": ["rewrite"],
                "custom_instruction": "やさしい語り口で"
            }
        )
        
        assert rewrite_response.status_code == 200
        rewrite_data = rewrite_response.json()
        
        # 統合テストの検証
        assert "rewritten_text" in rewrite_data
        assert rewrite_data["processing_time_ms"] < 1000  # 全体で1秒以内
```

---

## 📊 テストカバレッジ管理

### カバレッジ測定コマンド

```bash
# Flutter テストカバレッジ
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html

# Python テストカバレッジ  
pytest --cov=app --cov-report=html tests/
```

### カバレッジ目標
- **全体**: 80% 以上
- **重要な機能**: 90% 以上
- **API エンドポイント**: 95% 以上

---

## 🚀 TDD実践のコツ

### 1. 小さなステップで進む
```
❌ 悪い例: 音声認識機能全体を一度にテスト
✅ 良い例: ファイルアップロード → 音声認識 → エラーハンドリング の順

# タスクを細分化
- [ ] 🔴 音声ファイルのバリデーション
- [ ] 🔴 Speech-to-Text API呼び出し  
- [ ] 🔴 ユーザー辞書適用
- [ ] 🔴 結果の信頼度チェック
- [ ] 🔴 エラーハンドリング
```

### 2. テストファーストの習慣化

**毎朝のルーティン**:
1. 昨日のテストがすべて通るか確認
2. 今日実装する機能のテスト設計
3. 失敗するテストを先に書く
4. 実装開始

### 3. リファクタリングのタイミング
- 同じようなコードが3回出現したら
- メソッドが50行を超えたら
- テストの実行時間が遅くなったら

---

## 🎯 tasks.md との連携

各タスクの完了条件にテスト要件を含める：

```markdown
- [ ] **🔴** Speech-to-Text API統合
  - **完了条件**: 
    ✅ 機能実装: API呼び出し成功
    ✅ テスト通過: 単体テスト95%以上、統合テスト実行
    ✅ 品質確認: エラーハンドリング、ユーザー辞書対応
    ✅ 動作検証: 実際の音声ファイルで認識精度95%以上
```

---

## ⚠️ 注意点

### モックの適切な使用
```dart
// ✅ 外部依存はモック
when(mockSpeechToText.transcribe(any)).thenAnswer(...);

// ❌ ビジネスロジックはモックしない  
// 実際のGeminiServiceを使ってテスト
```

### テストデータの管理
```python
# テスト用の音声ファイル・HTMLファイルを用意
test_data/
├── audio_samples/
│   ├── clear_speech.wav      # クリアな音声
│   ├── noisy_speech.wav      # ノイズ有り
│   └── multiple_speakers.wav # 複数話者
├── html_templates/
│   └── newsletter_sample.html
└── expected_outputs/
    └── rewritten_texts.json
```

これで**音声入力→AIチャット編集→PDF配信**の全フローを確実にテスト駆動で開発できます！🎉

早速、最初のタスクから TDD で始めてみましょう！ 