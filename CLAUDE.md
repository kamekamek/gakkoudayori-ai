# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 🏃‍♂️ Quick Start Commands

For immediate productivity, use these essential commands:

### Most Common Commands
```bash
# Start development with proper environment
make dev

# Run all tests and checks (before committing)
make test && make lint

# Deploy everything (backend + frontend)
make deploy

# Reset development environment when things break
make reset-dev

# Full CI pipeline locally (before commits)
make ci-test
```

### Flutter Web Development
```bash
cd frontend
flutter pub get                    # Install dependencies
flutter run -d chrome             # Start dev server
flutter test                      # Run tests
flutter analyze                   # Static analysis
```

### Backend Python Development
```bash
cd backend/functions
source venv/bin/activate          # Activate virtual environment
python start_server.py           # Start local server
pytest                           # Run tests
flake8 . && black .              # Lint and format
```

# 学校だよりAI - Claude Code Action ガイドライン

## 🎯 プロジェクト概要

**学校だよりAI**は、HTMLベースのグラフィックレコーディング風学級通信作成システムです。教師が音声入力とAIを活用して、効率的に魅力的な学級通信を作成できるWebアプリケーションです。

### 主要技術スタック
- **フロントエンド**: Flutter Web
- **バックエンド**: FastAPI (Python)
- **AI**: Google Vertex AI (Gemini 1.5 Pro, Speech-to-Text)
- **インフラ**: Google Cloud Platform (Cloud Run, Cloud Storage, Firestore)
- **認証**: Firebase Authentication

## 📋 開発ルール・方針

### 🧪 TDD (テスト駆動開発) 必須
すべての重要機能は **Red → Green → Refactor** サイクルで実装：

1. **🔴 Red**: 失敗するテストを先に作成
2. **🟢 Green**: テストが通る最小限のコードを実装
3. **🔵 Refactor**: コード品質向上・リファクタリング

**TDD必須対象**:
- 音声認識・Geminiリライト・PDF生成のコアロジック
- API エンドポイント・データベース操作
- 重要な UI コンポーネント

### 📁 プロジェクト構造
**実際のプロジェクト構造 (Clean Architecture + Feature-First)**
```
gakkoudayori-ai/
├── frontend/                    # Flutter Web アプリ
│   ├── lib/
│   │   ├── app/                # アプリケーション層
│   │   │   └── app.dart       # アプリ設定・ルーティング
│   │   ├── core/              # 共通機能・インフラ層
│   │   │   ├── models/        # ドメインモデル
│   │   │   ├── services/      # API・外部サービス
│   │   │   ├── theme/         # デザインシステム
│   │   │   ├── router/        # ルーティング
│   │   │   └── utils/         # ユーティリティ
│   │   ├── features/          # 機能別実装 (Feature-First)
│   │   │   ├── ai_assistant/  # AI機能
│   │   │   │   └── presentation/ # UI層 (Pages/Widgets)
│   │   │   ├── editor/        # エディタ機能
│   │   │   │   ├── presentation/
│   │   │   │   ├── providers/ # 状態管理
│   │   │   │   └── services/  # エディタ固有サービス
│   │   │   ├── home/          # ホーム画面
│   │   │   ├── layout/        # レイアウト
│   │   │   ├── settings/      # 設定
│   │   │   └── splash/        # スプラッシュ
│   │   ├── firebase_options.dart     # Firebase設定
│   │   └── main.dart          # エントリーポイント
│   ├── test/                  # テストコード
│   ├── web/                   # Web固有ファイル
│   │   ├── quill/index.html   # Quill.js統合
│   │   └── firebase-config.js # Firebase Web設定
│   └── pubspec.yaml           # Flutter依存関係
├── backend/functions/         # Firebase Functions (Python)
│   ├── main.py               # メインAPI
│   ├── firebase_service.py   # Firebase統合
│   ├── speech_recognition_service.py # 音声認識
│   ├── gemini_api_service.py # Gemini API
│   ├── html_constraint_service.py # HTML処理
│   ├── newsletter_generator.py # 通信生成
│   ├── requirements.txt      # Python依存関係
│   └── test_*.py            # テストファイル
└── docs/                    # ドキュメント
    ├── tasks.md            # 実装タスク管理 (58タスク)
    ├── 01_REQUIREMENT_overview.md # 要件定義
    ├── 11_DESIGN_database_schema.md # DB設計
    └── 30_API_endpoints.md  # API仕様
```

## 🎨 コーディング規約

### Dart/Flutter
- **命名規則**: lowerCamelCase (変数・関数), UpperCamelCase (クラス)
- **ファイル名**: snake_case.dart
- **行長**: 100文字以内
- **状態管理**: Provider パターンを使用
- **非同期処理**: async/await を適切に使用
- **エラーハンドリング**: try-catch で適切な例外処理

```dart
// ✅ 良い例
class DocumentProvider extends ChangeNotifier {
  Future<void> saveDocument(Document document) async {
    try {
      await _documentService.save(document);
      notifyListeners();
    } catch (e) {
      _handleError('ドキュメント保存に失敗しました: $e');
    }
  }
}
```

### Python/FastAPI
- **命名規則**: snake_case (変数・関数), PascalCase (クラス)
- **行長**: 100文字以内
- **型ヒント**: 必須 (Python 3.9+ 記法使用)
- **docstring**: 重要な関数・クラスには必須
- **エラーハンドリング**: HTTPException で適切なステータスコード

```python
# ✅ 良い例
async def generate_pdf(
    document_id: str,
    user_id: str
) -> PDFResponse:
    """HTMLドキュメントをPDFに変換して返す"""
    try:
        document = await get_document(document_id, user_id)
        pdf_bytes = await pdf_service.convert_html_to_pdf(document.html)
        return PDFResponse(content=pdf_bytes, filename=f"{document.title}.pdf")
    except DocumentNotFoundError:
        raise HTTPException(status_code=404, detail="ドキュメントが見つかりません")
```

## 🔍 コードレビュー基準

### 必須チェック項目
- [ ] **機能要件**: 仕様通りに動作するか
- [ ] **テストカバレッジ**: 重要機能は80%以上
- [ ] **エラーハンドリング**: 適切な例外処理とユーザーフレンドリーなメッセージ
- [ ] **パフォーマンス**: UI応答<100ms、API応答<500ms
- [ ] **セキュリティ**: 入力値検証、認証・認可チェック
- [ ] **アクセシビリティ**: WCAG 2.1 AA準拠
- [ ] **コード品質**: 可読性、保守性、再利用性

### レビュー観点
1. **アーキテクチャ**: 設計原則に従っているか
2. **命名**: 意図が明確に伝わるか
3. **重複**: DRY原則に従っているか
4. **依存関係**: 適切な抽象化・依存注入
5. **ドキュメント**: 複雑なロジックにコメント

## 🚀 PR作成・マージルール

### PR作成時
- **タイトル**: `[カテゴリ] 簡潔な変更内容`
- **説明**: 変更理由・影響範囲・テスト方法を記載
- **ベースブランチ**: `develop` ブランチに対してPR作成
- **サイズ**: 1PR = 1機能、大きすぎる場合は分割

### マージ前チェック
- [ ] すべてのテストが通過
- [ ] `flutter analyze` エラー0件
- [ ] `flake8` エラー0件
- [ ] 動作確認完了
- [ ] ドキュメント更新済み

## 🎯 AI活用ガイドライン

### 音声認識 (Speech-to-Text)
- **ノイズ抑制**: 教室環境での認識精度向上
- **ユーザー辞書**: 学校特有の用語・固有名詞対応
- **リアルタイム処理**: ストリーミング認識でUX向上

### Gemini活用
- **リライト機能**: 教師らしい語り口調への変換
- **見出し生成**: コンテンツに適した見出し自動生成
- **レイアウト最適化**: グラレコ風デザインの自動提案

### HTMLエディタ
- **WYSIWYG**: リアルタイムプレビュー機能
- **テンプレート**: 季節・行事に応じたデザインテンプレート
- **アクセシビリティ**: 印刷・PDF出力最適化

## 📊 品質メトリクス目標

### テストカバレッジ
- **全体**: 80%以上
- **重要機能**: 90%以上
- **API**: 95%以上

### パフォーマンス
- **UI応答時間**: <100ms
- **API応答時間**: <500ms
- **PDF生成時間**: <3秒
- **音声認識精度**: >95%

### ユーザビリティ
- **通信作成時間**: <20分 (従来の90%短縮)
- **エラー発生率**: <1%
- **SUSスコア**: >4.0/5.0

## 🔧 開発環境・ツール

### 必須ツール
- **Flutter**: SDK 3.4.0+ (現在の環境設定)
- **Python**: 3.9+
- **Node.js**: 18+ (開発ツール用)
- **Google Cloud CLI**: 最新版
- **Firebase CLI**: 最新版 (`firebase --version` で確認)

### 推奨VS Code拡張
- Dart/Flutter
- Python
- GitLens
- Error Lens
- Thunder Client (API テスト)

## 🛠️ 開発コマンド

### Flutter Web開発
```bash
# プロジェクトディレクトリ移動
cd frontend

# 依存関係インストール
flutter pub get

# 開発サーバー起動 (Chrome)
flutter run -d chrome

# Web特有の開発サーバー (Firebase機能込み)
flutter run -d chrome --web-port=5000

# ビルド (本番用)
flutter build web --release

# テスト実行
flutter test

# 静的解析
flutter analyze

# パッケージ更新確認
flutter pub outdated

# Widget/Integration テスト
flutter test integration_test/
```

### Backend Python開発
```bash
# バックエンドディレクトリ移動
cd backend/functions

# 仮想環境がない場合は作成
python -m venv venv
source venv/bin/activate  # macOS/Linux
# または venv\Scripts\activate  # Windows

# 依存関係インストール
pip install -r requirements.txt

# 開発サーバー起動
python start_server.py

# または Firebase Functions Emulator
firebase emulators:start --only functions

# テスト実行
pytest

# 特定テスト実行
pytest test_firebase_service.py -v

# カバレッジ付きテスト
pytest --cov=. --cov-report=html

# 型チェック (mypyが設定済みの場合)
mypy .

# コードフォーマット
black .
flake8 .
```

### Firebase運用
```bash
# Firebase ログイン
firebase login

# プロジェクト設定
firebase use yutori-kyoshitu

# Functions デプロイ
firebase deploy --only functions

# Hosting デプロイ
firebase deploy --only hosting

# Emulator起動 (全サービス)
firebase emulators:start

# Firestore ルール更新
firebase deploy --only firestore:rules
```

### E2E テスト実行
```bash
# E2Eテストディレクトリ移動
cd frontend/e2e

# 依存関係インストール
npm install

# Playwright テスト実行
npm run test

# または直接実行
px playwright test

# ヘッドレスモードでテスト
px playwright test --headed
```

### 品質チェック統合
```bash
# Frontend品質チェック (必須実行コマンド)
cd frontend && flutter analyze && flutter test

# Backend品質チェック  
cd backend/functions && pytest && flake8 .

# コードフォーマット確認
cd frontend && dart format --set-exit-if-changed .
cd backend/functions && black --check .

# テストカバレッジ
cd frontend && flutter test --coverage
cd backend/functions && pytest --cov=.

# 全体品質チェック (CI/CD前の最終確認)
cd frontend && flutter analyze && flutter test && cd ../backend/functions && pytest && flake8 .
```

### プロジェクト管理
```bash
# タスク進捗確認
cat docs/tasks.md

# ドキュメント一覧
ls docs/

# 設定ファイル確認
cat frontend/pubspec.yaml
cat backend/functions/requirements.txt

# Git状況確認
git status
git log --oneline -10
```

## 📝 コミットメッセージ規約

```
[カテゴリ] 簡潔な変更内容

詳細な説明（必要に応じて）

- 変更点1
- 変更点2

関連: #issue番号
```

**カテゴリ例**:
- `feat` 新機能追加
- `fix` バグ修正
- `docs` ドキュメント更新
- `refactor` リファクタリング
- `test` テスト追加・修正
- `style` コードスタイル調整

## 🎨 UI/UXガイドライン

### デザインシステム
- **カラーパレット**: 季節感のある温かみのある色調
- **フォント**: 手書き風・親しみやすいフォント
- **アイコン**: 学校・教育関連のアイコンセット
- **レスポンシブ**: スマートフォン・タブレット対応

### アクセシビリティ
- **色コントラスト**: WCAG 2.1 AA準拠
- **キーボード操作**: 全機能をキーボードで操作可能
- **スクリーンリーダー**: 適切なセマンティクス
- **フォントサイズ**: 拡大縮小対応

## 🔒 セキュリティガイドライン

### 認証・認可
- **Firebase Auth**: Google ログイン必須
- **JWT検証**: すべてのAPIエンドポイントで実装
- **権限チェック**: ユーザー自身のデータのみアクセス可能

### データ保護
- **個人情報**: 最小限の収集・適切な暗号化
- **ファイル管理**: Cloud Storage署名付きURL使用
- **ログ**: 個人情報を含まないログ設計

## 📚 参考ドキュメント

- [タスク管理](docs/tasks.md) - 実装進捗管理 (58タスク、現在4/58完了)
- [要件定義](docs/01_REQUIREMENT_overview.md) - 機能要件・非機能要件
- [システム設計](docs/archive/11_DESIGN_database_schema.md) - データベース・アーキテクチャ詳細
- [API仕様](docs/archive/30_API_endpoints.md) - エンドポイント設計

---

## 🎯 現在のプロジェクト状況

### 進捗サマリー
- **全体進捗**: 4/58タスク完了 (6.9%)
- **Phase 1進捗**: Google Cloud基盤・Firebase基盤・Flutter基盤の環境構築中
- **次のマイルストーン**: T1-FL-002-A Flutter Webプロジェクト初期化

### 重要な実装方針
1. **TDD必須**: すべてのコーディングタスクで Red→Green→Refactor サイクル
2. **並行開発**: 依存関係のないタスクは同時実行で効率化
3. **教育現場重視**: 教師の使いやすさを最優先に設計
4. **ハッカソン制約**: Google Cloud サービス使用が必須要件

### アーキテクチャの理解
- **Quill.js統合**: `web/quill/index.html` で Flutter Web と Quill.js を連携
- **Feature-First構造**: 機能別ディレクトリで横断的関心事を分離
- **Clean Architecture**: core層（共通）とfeatures層（機能固有）の分離
- **Firebase Functions**: Python FastAPIをFirebase Functionsで実行
- **音声-AI-HTML-PDF**: Speech-to-Text → Gemini → Quill.js → PDF の処理パイプライン
- **Provider状態管理**: 特にエディタの複雑な状態を `QuillEditorProvider` で管理
- **Web特化**: PWAとして動作、ネイティブアプリ非対応
- **Firebase認証**: 匿名認証とGoogle認証の併用
- **Cloud Storage**: 生成されたファイルの保存・共有

### 重要な技術的制約
- **Webオンリー**: モバイルアプリ非対応のWeb専用設計
- **Quill.js依存**: リッチテキストエディタはQuill.jsに完全依存
- **Firebase Ecosystem**: 認証・データベース・ストレージすべてFirebase
- **Google Cloud中心**: Speech-to-Text、Vertex AI Geminiがコア機能
- **ハッカソン制約**: Google Cloudサービス使用が必須要件

---

**🤖 Claude Code Action へのメッセージ**

このプロジェクトは教育現場の効率化を目指すWebアプリケーションです。コード品質・ユーザビリティ・アクセシビリティを重視し、教師が直感的に使える設計を心がけてください。TDD原則に従い、テストファーストで安全な実装をお願いします。

**開始時の必須チェック項目**:
1. `docs/tasks.md` で現在の進捗と次のタスクを確認
2. 実装前に必ずテストコードを作成 (TDD)
3. `flutter analyze && flutter test` で品質確認
4. 教育現場での使いやすさを常に意識

質問や不明点があれば、遠慮なく確認してください！

## 🤖 AIレビュー依頼テンプレート

PRを作成する際は、以下のテンプレートを使用してClaudeにレビューを依頼してください：

```markdown
## 🤖 AIレビュー依頼

@claude このPRをレビューしてください。以下の観点で確認をお願いします：

- **機能要件**: 仕様通りに動作しているか
- **コード品質**: 可読性、保守性、再利用性
- **セキュリティ**: 認証・認可、入力値検証、データ保護
- **パフォーマンス**: UI応答時間、API応答時間の最適化
- **テスト**: カバレッジ、エッジケースの考慮
- **アクセシビリティ**: WCAG 2.1 AA準拠、ユーザビリティ
- **教育現場での使いやすさ**: 教師目線での直感的な操作性

改善提案や潜在的な問題があれば、具体的な修正案と合わせて教えてください。

## 🔧 重要な開発注意事項

### Firebase設定管理
- `firebase_options.dart` は `.gitignore` 対象（機密情報含有）
- 初回は `firebase_options.dart.template` からコピーして実際の値を設定
- Web用Firebase設定は `web/firebase-config.js.sample` も参照

### Document Management Rules
Based on `.cursor/rules/document_management.mdc`, follow these conventions:
- File naming: `{Number}_{CATEGORY}_{title}.md` (e.g., `01_REQUIREMENT_overview.md`)
- Categories: REQUIREMENT (01-09), DESIGN (10-19), SPEC (20-29), API (30-39), etc.
- Include TL;DR section for 30-second understanding
- Keep documents under 10KB, split if larger
- Always include metadata: complexity, reading time, dependencies

### Architecture-Specific Notes
- **Web-only**: No mobile app support, Flutter Web PWA only
- **Quill.js Bridge**: JavaScript ↔ Flutter communication via `web/quill/index.html`
- **Audio Pipeline**: MediaRecorder API → Cloud Speech-to-Text → Gemini → Quill Delta
- **Firebase Functions**: Python FastAPI deployed as Firebase Functions
- **State Management**: Provider pattern, especially `QuillEditorProvider` for editor state

### Quill.js統合の理解
- `web/quill/index.html` が Quill.js の実装本体
- `lib/features/editor/services/javascript_bridge.dart` で Flutter ↔ JavaScript 通信
- `lib/features/editor/presentation/widgets/quill_editor_web.dart` でWebView制御

### 音声入力フロー
- `services/audio_service.dart`: ブラウザのMediaRecorder API使用
- `widgets/*_widget.dart`: UI制御とファイルアップロード
- Backend `speech_recognition_service.py`: Google Speech-to-Text処理
- Backend `gemini_api_service.py`: AIによるテキストリライト

### 現在の実装状況（プロジェクト完了）
このプロジェクトは**Google Cloud Japan AI Hackathon Vol.2**向けに完成しており、全62タスクが完了済みです。主要機能は全て実装されています。

### テスト戦略
- Unit Tests: `flutter test` (Dart/Flutter用)
- Integration Tests: `flutter test integration_test/` (Flutter統合)
- E2E Tests: `cd frontend/e2e && npm run test` (Playwright)
- Backend Tests: `cd backend/functions && pytest`

### デプロイメント
- Frontend: Firebase Hosting (`firebase deploy --only hosting`)
- Backend: Firebase Functions (`firebase deploy --only functions`)
- 開発環境: Firebase Emulators (`firebase emulators:start`)

### パフォーマンス注意点
- Quill.js の大きなドキュメントでのメモリ使用量
- Gemini API のレスポンス時間（ストリーミング対応推奨）
- 音声ファイルのサイズ制限（Cloud Speech-to-Text上限）
- PDF生成処理のタイムアウト

## 📋 Task Management & TDD Integration

### Required Task Management Flow
This project enforces strict task management based on `.cursor/rules/task_management_tdd.mdc`:

1. **Task Start**: Mark in progress in `docs/tasks.md` with timestamp
2. **TDD Implementation**: Follow Red → Green → Blue cycle for AI/HYBRID tasks
3. **Task Complete**: Update all completion conditions and record artifacts
4. **Dependency Check**: Verify and unlock dependent tasks

### TDD Phase Tracking
For any coding task, track TDD phases in task updates:
```markdown
#### T1-XX-001-A: Example Task
- **TDD Phase**: 🔴 RED - Test creation
- **TDD Phase**: 🟢 GREEN - Minimum implementation  
- **TDD Phase**: 🔵 BLUE - Refactoring
- **TDD Phase**: ✅ Complete
```

### Task Completion Requirements
Every task must satisfy ALL completion conditions before marking complete:
- All checkboxes marked [x]
- Test coverage recorded (for code tasks)
- Artifacts documented with file paths
- Dependencies verified and updated

## 🛠️ Critical Development Commands

### Makefile Integration
This project uses a comprehensive Makefile. Always prefer Makefile commands:

```bash
# Essential development workflow
make help           # Show all available commands
make dev            # Start development (Chrome with proper env vars)
make staging        # Test with staging environment
make test           # Run all tests (Flutter + Python)
make lint           # Run all static analysis
make format         # Format all code
make ci-test        # Full CI pipeline locally

# Deployment workflow
make build-prod     # Production build
make deploy         # Deploy everything (RECOMMENDED)
make deploy-frontend # Firebase Hosting only
make deploy-backend  # Cloud Run only
```

### Environment Variables (Critical)
The application uses dart-define for configuration:
- Development: `API_BASE_URL=http://localhost:8081/api/v1/ai`
- Staging: `API_BASE_URL=https://staging-yutori-backend.asia-northeast1.run.app/api/v1/ai`
- Production: `API_BASE_URL=https://yutori-backend-944053509139.asia-northeast1.run.app/api/v1/ai`
- Always use `make dev` or `make staging` to ensure proper environment setup

### Key Project Context
- **Project Status**: Completed for Google Cloud Japan AI Hackathon Vol.2
- **Architecture**: Web-only Flutter app with Python FastAPI backend
- **Main Flow**: Voice → Speech-to-Text → Gemini AI → Quill.js Editor → PDF
- **Target Users**: Teachers creating school newsletters efficiently
- **Goal**: Reduce newsletter creation time from 2-3 hours to under 20 minutes

### Testing Strategy
```bash
# Frontend testing
cd frontend
flutter test                    # Unit tests
flutter test integration_test/  # Integration tests

# Backend testing  
cd backend/functions
pytest                         # All tests
pytest test_firebase_service.py -v  # Specific test file
pytest --cov=. --cov-report=html    # With coverage

# E2E testing
cd frontend/e2e
npm run test                   # Playwright E2E tests
```