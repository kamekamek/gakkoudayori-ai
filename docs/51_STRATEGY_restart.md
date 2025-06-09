# プロジェクト再開戦略

## 1. 判断の背景

既存プロジェクトから新プロジェクトへの**完全移行**を決定。理由：

- 技術スタック変更（html_editor_enhanced → Quill.js）
- ファイル構造の複雑化
- フロント・バックエンドパラレル開発の必要性
- 新要件への100%準拠

## 2. 新プロジェクト構造

```
school-letter-ai-v2/
├── frontend/                    # Flutter Web プロジェクト
│   ├── lib/
│   │   ├── main.dart
│   │   ├── providers/           # 状態管理
│   │   ├── services/           # API連携
│   │   ├── widgets/            # UIコンポーネント
│   │   └── models/             # データモデル
│   ├── web/
│   │   └── quill/              # Quill.js関連ファイル
│   └── pubspec.yaml
├── backend/                     # FastAPI プロジェクト
│   ├── app/
│   │   ├── main.py
│   │   ├── api/                # APIエンドポイント
│   │   ├── services/           # ビジネスロジック
│   │   ├── models/             # データモデル
│   │   └── utils/              # ユーティリティ
│   └── requirements.txt
├── docs/                        # 設計ドキュメント（既存活用）
├── shared/                      # 共有定義
│   ├── api-contracts/          # APIコントラクト
│   └── models/                 # 共有モデル定義
└── README.md
```

## 3. 段階的実装計画

### Phase 1: プロジェクト初期化 (1日)

**フロントエンド**:
```bash
# 新しいFlutterプロジェクト作成
flutter create school_letter_frontend
cd school_letter_frontend

# 必要パッケージ追加
flutter pub add provider
flutter pub add flutter_inappwebview
flutter pub add firebase_core
flutter pub add firebase_auth
flutter pub add cloud_firestore
flutter pub add firebase_storage
```

**バックエンド**:
```bash
# 新しいFastAPIプロジェクト作成
mkdir school_letter_backend
cd school_letter_backend

# 仮想環境作成
python -m venv venv
source venv/bin/activate

# 必要パッケージインストール
pip install fastapi uvicorn
pip install google-cloud-aiplatform
pip install firebase-admin
pip install weasyprint
```

### Phase 2: APIコントラクト定義 (1日)

**共有API仕様**:
```typescript
// shared/api-contracts/ai.ts
interface GenerateContentRequest {
  prompt: string;
  customInstruction?: string;
  constraints: {
    allowedTags: string[];
    disallowedTags: string[];
  };
}

interface GenerateContentResponse {
  htmlContent: string;
  deltaJson: string;
  generatedAt: string;
}
```

### Phase 3: パラレル開発開始 (7-10日)

**フロントエンド担当**:
- Quill.js + WebView統合
- UI/UXコンポーネント実装
- 状態管理（Provider）
- 季節テーマ実装

**バックエンド担当**:
- Gemini API連携
- Firestore/Storage操作
- PDF生成機能
- 認証・認可

### Phase 4: 統合・テスト (3-5日)

- API結合テスト
- E2Eテスト
- パフォーマンス最適化
- デプロイ

## 4. 既存プロジェクトからの資産活用

### 活用できるもの ✅
- `firebase.json`, `firestore.rules`
- `pubspec.yaml`の依存関係（部分的）
- `requirements.txt`の依存関係（部分的）
- 全ての設計ドキュメント
- UI/UXの設計思想

### 活用しないもの ❌
- `frontend/lib/`配下のDartコード
- `backend/`配下のPythonコード
- 複雑化したディレクトリ構造

## 5. 開発分担案

| 担当領域 | 開発者 | 主要タスク |
|---------|--------|-----------|
| **フロントエンド** | 亀ちゃん | Quill.js統合、Flutter UI、状態管理 |
| **バックエンド** | 亀ちゃん | Gemini API、Firebase、PDF生成 |
| **API設計** | 共同 | OpenAPI仕様、データモデル定義 |
| **テスト** | 共同 | E2Eテスト、統合テスト |

## 6. マイルストーン

| 日程 | マイルストーン | 成果物 |
|------|-------------- |--------|
| Day 1 | プロジェクト初期化 | 新プロジェクト構造 |
| Day 2 | APIコントラクト完成 | OpenAPI仕様書 |
| Day 5 | フロントエンド基本機能 | Quill.js統合完了 |
| Day 7 | バックエンド基本機能 | Gemini API連携完了 |
| Day 10 | アルファ版完成 | 基本フロー動作 |
| Day 12 | ベータ版完成 | 全機能実装 |
| Day 15 | リリース候補 | 品質保証完了 |

## 7. リスク軽減策

| リスク | 対策 |
|--------|------|
| **WebView連携の複雑さ** | 早期プロトタイプで検証 |
| **API連携エラー** | モックサーバーでの独立開発 |
| **パフォーマンス問題** | 段階的負荷テスト |
| **要件変更** | アジャイル開発プロセス |

## 8. 成功基準

- ✅ 20分以内でのドラフト完成
- ✅ 季節テーマのワンクリック適用
- ✅ AI補助機能の自然な統合
- ✅ PDF出力とGoogle連携
- ✅ 保護者にとって見やすいデザイン 