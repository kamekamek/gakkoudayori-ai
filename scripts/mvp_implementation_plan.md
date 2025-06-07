# Phase 1.5 MVP優先実装計画

**🎯 目標**: チャット＋音声入力→HTMLグラレコ→PDF出力→配信の一連の流れを動作させる

## 📋 実装順序と依存関係

### 1. HTMLエディタ統合（基本版） - 最優先
**依存**: Flutter Web基盤完了 ✅
**実装期間**: 1-2日

#### 1.1 パッケージ追加
```bash
cd frontend
flutter pub add html_editor_enhanced
flutter pub add webview_flutter_web
```

#### 1.2 実装ファイル
- `lib/widgets/html_editor_widget.dart` - HTMLエディタウィジェット
- `lib/screens/editor_screen.dart` - エディタ画面の更新
- `lib/providers/editor_provider.dart` - エディタ状態管理

#### 1.3 テスト実装（TDD）
```bash
# テストファイル作成
touch test/widgets/html_editor_widget_test.dart
touch test/providers/editor_provider_test.dart
```

### 2. WebSocketチャット基盤実装
**依存**: FastAPI基盤完了 ✅
**実装期間**: 2-3日

#### 2.1 バックエンド実装
```bash
cd backend
pip install websockets
```

#### 2.2 実装ファイル
- `backend/api/websocket.py` - WebSocketエンドポイント
- `backend/services/chat_service.py` - チャット管理サービス
- `frontend/lib/services/websocket_service.dart` - WebSocket通信
- `frontend/lib/widgets/chat_widget.dart` - チャットUI

#### 2.3 テスト実装
```bash
# バックエンドテスト
touch backend/tests/test_websocket.py
# フロントエンドテスト
touch frontend/test/services/websocket_service_test.dart
```

### 3. リアルタイム編集提案UI
**依存**: WebSocketチャット基盤、Gemini統合 ✅
**実装期間**: 2-3日

#### 3.1 実装ファイル
- `backend/services/ai_editor_service.py` - AI編集提案サービス
- `frontend/lib/widgets/edit_suggestion_widget.dart` - 編集提案UI
- `frontend/lib/providers/edit_suggestion_provider.dart` - 提案状態管理

### 4. WeasyPrint PDF生成機能
**依存**: HTMLエディタ統合完了
**実装期間**: 2-3日

#### 4.1 バックエンド実装
```bash
cd backend
pip install weasyprint
pip install fonttools
```

#### 4.2 実装ファイル
- `backend/services/pdf_service.py` - PDF生成サービス
- `backend/api/pdf.py` - PDF生成エンドポイント
- `frontend/lib/services/pdf_service.dart` - PDF生成API呼び出し

#### 4.3 日本語フォント設定
```bash
# 日本語フォントのダウンロードと設定
mkdir -p backend/assets/fonts
# Noto Sans JPフォントの設定
```

### 5. Google Drive保存機能
**依存**: PDF生成機能、Google Cloud設定 ✅
**実装期間**: 2-3日

#### 5.1 実装ファイル
- `backend/services/drive_service.py` - Google Drive統合
- `backend/api/drive.py` - Drive APIエンドポイント
- `frontend/lib/services/drive_service.dart` - Drive連携

### 6. 基本グラレコテンプレート作成
**依存**: HTMLエディタ統合完了
**実装期間**: 2-3日

#### 6.1 実装ファイル
- `backend/templates/` - HTMLテンプレートファイル
- `backend/services/template_service.py` - テンプレート管理
- `frontend/lib/widgets/template_selector.dart` - テンプレート選択UI

### 7. 季節カラーパレット実装
**依存**: HTMLテンプレート基盤
**実装期間**: 1-2日

#### 7.1 実装ファイル
- `frontend/lib/theme/seasonal_colors.dart` - 季節カラー定義
- `frontend/lib/widgets/color_palette_widget.dart` - カラーパレットUI

### 8. 音声⇆チャット連携
**依存**: 音声入力UI ✅、WebSocketチャット基盤
**実装期間**: 2-3日

#### 8.1 実装ファイル
- `frontend/lib/services/voice_chat_service.dart` - 音声チャット連携
- `frontend/lib/widgets/voice_chat_widget.dart` - 音声チャットUI

## 🚀 実装開始スクリプト

### Phase 1: HTMLエディタ統合

```bash
#!/bin/bash
# mvp_phase1_html_editor.sh

echo "🚀 Phase 1: HTMLエディタ統合開始"

# 1. パッケージ追加
cd frontend
flutter pub add html_editor_enhanced
flutter pub add webview_flutter_web

# 2. テストファイル作成
mkdir -p test/widgets test/providers
touch test/widgets/html_editor_widget_test.dart
touch test/providers/editor_provider_test.dart

# 3. 実装ファイル作成
mkdir -p lib/widgets lib/providers
touch lib/widgets/html_editor_widget.dart
touch lib/providers/editor_provider.dart

echo "✅ Phase 1 セットアップ完了"
echo "次の実装ファイルを作成してください："
echo "- lib/widgets/html_editor_widget.dart"
echo "- lib/providers/editor_provider.dart"
echo "- test/widgets/html_editor_widget_test.dart"
echo "- test/providers/editor_provider_test.dart"
```

### Phase 2: WebSocketチャット基盤

```bash
#!/bin/bash
# mvp_phase2_websocket.sh

echo "🚀 Phase 2: WebSocketチャット基盤実装開始"

# 1. バックエンド依存関係追加
cd backend
pip install websockets

# 2. バックエンドファイル作成
mkdir -p api services tests
touch api/websocket.py
touch services/chat_service.py
touch tests/test_websocket.py

# 3. フロントエンドファイル作成
cd ../frontend
mkdir -p lib/services lib/widgets test/services
touch lib/services/websocket_service.dart
touch lib/widgets/chat_widget.dart
touch test/services/websocket_service_test.dart

echo "✅ Phase 2 セットアップ完了"
echo "次の実装ファイルを作成してください："
echo "Backend:"
echo "- backend/api/websocket.py"
echo "- backend/services/chat_service.py"
echo "Frontend:"
echo "- frontend/lib/services/websocket_service.dart"
echo "- frontend/lib/widgets/chat_widget.dart"
```

### Phase 3: PDF生成機能

```bash
#!/bin/bash
# mvp_phase3_pdf.sh

echo "🚀 Phase 3: PDF生成機能実装開始"

# 1. バックエンド依存関係追加
cd backend
pip install weasyprint fonttools

# 2. 日本語フォント設定
mkdir -p assets/fonts
echo "日本語フォント（Noto Sans JP）をダウンロードしてください"

# 3. 実装ファイル作成
touch services/pdf_service.py
touch api/pdf.py
touch tests/test_pdf_service.py

# 4. フロントエンド実装ファイル
cd ../frontend
touch lib/services/pdf_service.dart
touch test/services/pdf_service_test.dart

echo "✅ Phase 3 セットアップ完了"
echo "次の実装ファイルを作成してください："
echo "Backend:"
echo "- backend/services/pdf_service.py"
echo "- backend/api/pdf.py"
echo "Frontend:"
echo "- frontend/lib/services/pdf_service.dart"
```

## 📊 実装進捗チェックリスト

### Week 1 (Phase 1-2)
- [ ] HTMLエディタ統合完了
- [ ] WebSocketチャット基盤完了
- [ ] 基本的なチャット機能動作確認

### Week 2 (Phase 3-5)
- [ ] リアルタイム編集提案UI完了
- [ ] PDF生成機能完了
- [ ] Google Drive保存機能完了

### Week 3 (Phase 6-8)
- [ ] 基本グラレコテンプレート完了
- [ ] 季節カラーパレット完了
- [ ] 音声⇆チャット連携完了

## 🧪 TDD実装ガイドライン

### 各フェーズでのTDDサイクル

#### 1. 🔴 Red: テスト先行作成
```dart
// 例: HTMLエディタウィジェットのテスト
test('HTMLエディタが正常に初期化される', () {
  // Given
  final widget = HtmlEditorWidget();
  
  // When
  // テスト実行
  
  // Then
  // 期待される動作を検証
  expect(widget, isNotNull);
});
```

#### 2. 🟢 Green: 最小限の実装
```dart
// 例: HTMLエディタウィジェットの最小実装
class HtmlEditorWidget extends StatefulWidget {
  @override
  _HtmlEditorWidgetState createState() => _HtmlEditorWidgetState();
}

class _HtmlEditorWidgetState extends State<HtmlEditorWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(); // 最小限の実装
  }
}
```

#### 3. 🔵 Refactor: コード改善
- パフォーマンス最適化
- 可読性向上
- 重複コード除去

## 🎯 完了条件チェック

### 各タスクの完了条件
1. **HTMLエディタ統合**: エディタ表示、基本テキスト入力・書式設定動作
2. **WebSocketチャット**: リアルタイム双方向通信、セッション管理
3. **編集提案UI**: チャット入力→AI提案→受諾/拒否ボタン動作
4. **PDF生成**: レイアウト保持、日本語フォント対応、変換時間<3秒
5. **Drive保存**: 月別フォルダ自動作成・権限設定・共有リンク生成
6. **グラレコテンプレート**: 吹き出し・アイコン配置・手描き風スタイル 3パターン
7. **カラーパレット**: 4季節の色彩テーマ、ワンクリック適用
8. **音声チャット連携**: 音声で「ここを直して」→チャット画面に自動反映

## 🔧 開発環境セットアップ

### 必要なツール確認
```bash
# Flutter環境確認
flutter doctor

# Python環境確認
python --version
pip --version

# Google Cloud CLI確認
gcloud --version

# 依存関係インストール
cd frontend && flutter pub get
cd backend && pip install -r requirements.txt
```

### 開発サーバー起動
```bash
# バックエンド起動
cd backend
uvicorn main:app --reload --host 0.0.0.0 --port 8000

# フロントエンド起動
cd frontend
flutter run -d chrome --web-port 3000
```

---

**🎯 目標**: 2週間でMVPの一連の流れを完全動作させる
**📅 開始日**: 2025年1月
**�� 完了予定**: 2025年1月末 