# 🎮 UIテスト自動化プレイグラウンド

学校だよりAIアプリのUIを自動でテストするプレイグラウンド環境です。「ポチポチ」操作を自動化して、効率的にUIテストを実行できます。

## 🚀 クイックスタート

### 1. 事前準備

```bash
# Flutter Webアプリを起動（別ターミナル）
cd frontend
flutter run -d chrome --web-port 8080
```

### 2. プレイグラウンド実行

```bash
# インタラクティブメニューで実行
cd frontend
npm run playground

# または直接実行
./scripts/ui-playground.sh
```

## 🎯 利用可能なテストモード

### 🚀 基本フロー（学級通信作成）
- AIチャットでの学級通信作成フロー全体をテスト
- 入力 → AI応答 → HTMLプレビュー → モード切り替え

```bash
npm run playground:basic
```

### 🎤 音声入力テスト
- 録音ボタンの動作確認
- 音声入力UIの状態変化をテスト

```bash
npm run playground:voice
```

### 📱 レスポンシブテスト
- デスクトップ、タブレット、モバイルでのレイアウト確認
- 画面サイズ変更時のUI動作をテスト

```bash
npm run playground:responsive
```

### 🎮 全テスト実行
- すべてのテストを一括実行

```bash
npm run playground:all
```

## 🎬 操作録画モード（Codegen）

実際のUI操作を録画してテストコードを自動生成：

```bash
# 基本録画
npm run record:test

# モバイル録画
npm run record:mobile

# タブレット録画
npm run record:tablet
```

### 録画の流れ
1. ブラウザが自動で開く
2. 実際にUIを操作する
3. 操作がリアルタイムでテストコードに変換される
4. 完了後、生成されたコードを確認・実行

## 📊 テスト内容詳細

### 🚀 基本フローテスト
```javascript
// 学級通信作成の完全フロー
const testMessage = `
学校名: さくら小学校
学年: 3年2組
担任: 田中先生
内容: 今日は運動会の練習をしました...
`;
await homePage.sendChatMessage(testMessage);
```

### 🎤 音声入力テスト
```javascript
// 録音ボタンの動作確認
const recordButton = page.locator('[data-testid="record-button"]');
await recordButton.click();
```

### 📱 レスポンシブテスト
```javascript
// 複数画面サイズでのテスト
await page.setViewportSize({ width: 1200, height: 800 }); // デスクトップ
await page.setViewportSize({ width: 768, height: 1024 });  // タブレット
await page.setViewportSize({ width: 375, height: 667 });   // モバイル
```

### 🔄 データ永続化テスト
```javascript
// セッション管理の確認
await homePage.sendChatMessage('テストメッセージ');
await page.reload(); // ページリロード
// チャット履歴が保持されているか確認
```

### ⚡ パフォーマンステスト
```javascript
// 大量操作の処理時間測定
const startTime = Date.now();
for (let i = 1; i <= 5; i++) {
  await homePage.sendChatMessage(`テストメッセージ ${i}`);
}
const duration = Date.now() - startTime;
```

### 🎯 エラーハンドリングテスト
```javascript
// 異常系のテスト
await homePage.sendChatMessage(''); // 空メッセージ
await homePage.sendChatMessage('あ'.repeat(1000)); // 長すぎるメッセージ
await homePage.sendChatMessage('<script>alert("test")</script>'); // 特殊文字
```

### 📊 UIコンポーネント網羅テスト
```javascript
// 画面上の全ボタンを自動検出してクリックテスト
const buttons = page.locator('button:visible');
const buttonCount = await buttons.count();
for (let i = 0; i < buttonCount; i++) {
  await buttons.nth(i).click();
}
```

## 🔧 高度な使い方

### カスタムテストの作成

1. **新しいテストファイルを作成**
```bash
cp e2e/tests/ui-automation-playground.spec.js e2e/tests/my-custom-test.spec.js
```

2. **テスト内容をカスタマイズ**
```javascript
test('🎯 カスタムテスト', async ({ page }) => {
  // あなた独自のテストロジック
});
```

3. **実行**
```bash
npx playwright test e2e/tests/my-custom-test.spec.js --headed
```

### デバッグモード
```bash
# ステップバイステップでデバッグ
npx playwright test e2e/tests/ui-automation-playground.spec.js --debug

# UIモードでインタラクティブにテスト
npx playwright test --ui
```

### テストレポート
```bash
# HTMLレポートを生成・表示
npm run test:e2e:report
```

## 🎯 実践的な使用例

### 1. 新機能のテスト
```bash
# 新機能をリリース前にテスト
npm run playground:all
```

### 2. バグ再現テスト
```bash
# 操作録画でバグを再現
npm run record:test
# 録画した操作を自動実行してバグを確認
```

### 3. パフォーマンス監視
```bash
# 定期的にパフォーマンステストを実行
npm run playground:basic
```

### 4. レスポンシブ対応確認
```bash
# 新しいデバイスサイズでのテスト
npm run playground:responsive
```

## 🛠️ トラブルシューティング

### Flutter Webアプリが起動しない
```bash
# ポート8080が使用中の場合
flutter run -d chrome --web-port 8081
# playwright.config.jsのbaseURLも変更
```

### テストが失敗する
```bash
# 詳細なログを確認
npx playwright test --reporter=line

# スクリーンショットを確認
ls test-results/
```

### 要素が見つからない
```bash
# 要素のセレクタを確認
npx playwright codegen http://localhost:8080
```

## 📈 継続的な改善

1. **定期実行**: CI/CDパイプラインに組み込み
2. **カバレッジ拡大**: 新機能追加時にテストも追加
3. **パフォーマンス監視**: 定期的にパフォーマンステストを実行
4. **ユーザビリティ**: 実際のユーザー操作パターンを録画してテスト化

---

**🎮 Happy Testing!** UIテストの自動化で、より安全で効率的な開発を実現しましょう！ 