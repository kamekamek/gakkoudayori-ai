# ゆとり職員室 - Claude Code Action ガイドライン

## 🎯 プロジェクト概要

**ゆとり職員室**は、HTMLベースのグラフィックレコーディング風学級通信作成システムです。教師が音声入力とAIを活用して、効率的に魅力的な学級通信を作成できるWebアプリケーションです。

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
```
yutorikyoshitu/
├── frontend/          # Flutter Web アプリ
│   ├── lib/
│   │   ├── models/    # データモデル
│   │   ├── providers/ # 状態管理 (Provider)
│   │   ├── screens/   # 画面コンポーネント
│   │   ├── services/  # API・外部サービス連携
│   │   ├── widgets/   # 再利用可能ウィジェット
│   │   └── theme/     # デザインシステム
│   └── test/          # テストコード
├── backend/           # FastAPI バックエンド
│   ├── api/           # APIエンドポイント
│   ├── services/      # ビジネスロジック
│   ├── config/        # 設定管理
│   └── tests/         # テストコード
└── docs/              # ドキュメント
    ├── tasks.md       # 実装タスク管理
    ├── system_design.md # システム設計
    └── tdd_guide.md   # TDD実装ガイド
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
- **Flutter**: 最新安定版
- **Python**: 3.9+
- **Node.js**: 18+ (開発ツール用)
- **Google Cloud CLI**: 最新版

### 推奨VS Code拡張
- Dart/Flutter
- Python
- GitLens
- Error Lens
- Thunder Client (API テスト)

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

- [タスク管理](docs/tasks.md) - 実装進捗管理
- [システム設計](docs/system_design.md) - アーキテクチャ詳細
- [TDDガイド](docs/tdd_guide.md) - テスト駆動開発手順
- [要件定義](docs/REQUIREMENT.md) - 機能要件・非機能要件

---

**🤖 Claude Code Action へのメッセージ**

このプロジェクトは教育現場の効率化を目指すWebアプリケーションです。コード品質・ユーザビリティ・アクセシビリティを重視し、教師が直感的に使える設計を心がけてください。TDD原則に従い、テストファーストで安全な実装をお願いします。

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