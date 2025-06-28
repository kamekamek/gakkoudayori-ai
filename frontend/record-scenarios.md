# Playwrightレコーディング実行ガイド

## 🎬 基本的な録画手順

### 1. 事前準備
```bash
# Flutter Webアプリを起動（別ターミナル）
cd frontend
flutter run -d chrome --web-port 8080
```

### 2. レコーディング開始
```bash
# 簡単実行（スクリプト使用）
./record-test.sh

# 手動実行
npx playwright codegen http://localhost:8080
```

## 🎯 推奨テストシナリオ

### シナリオ1: 基本的な学級通信作成フロー
1. ホームページにアクセス
2. 「今日は運動会の練習をしました」とチャット入力
3. 送信ボタンをクリック
4. AIの応答を待つ
5. 生成されたHTMLプレビューを確認
6. 編集ボタンがあればクリック

### シナリオ2: 音声入力テスト
1. ホームページにアクセス
2. 音声録音ボタンをクリック
3. 録音開始の確認
4. 停止ボタンをクリック
5. 音声がテキストに変換されることを確認

### シナリオ3: レスポンシブテスト
1. デスクトップサイズでアクセス
2. ブラウザウィンドウを縮小してモバイルサイズに
3. レイアウトの変化を確認
4. タブ切り替えなどの動作確認

### シナリオ4: 画像アップロードテスト
1. 画像アップロード機能にアクセス
2. ファイル選択ダイアログを開く
3. 画像ファイルを選択
4. アップロード完了を確認
5. プレビュー表示を確認

## 🔧 レコーディング時のコツ

### Playwrightウィンドウの使い方
- **左側**: 実際のブラウザ操作画面
- **右側**: 生成されるコード（リアルタイム）
- **下部**: レコーディングコントロール

### 操作のベストプラクティス
1. **ゆっくり操作**: 急いで操作せず、要素の読み込みを待つ
2. **明示的な待機**: 必要に応じて少し待ってから次の操作
3. **エラー処理**: エラーが発生した場合の操作も録画
4. **アサーション追加**: 重要な状態変化は手動で検証コード追加

### 生成コードの改善
```javascript
// 生成されたコード例
await page.click('button');

// 改善後（より安全）
await page.waitForSelector('button:visible');
await page.click('button');
await expect(page.locator('.success-message')).toBeVisible();
```

## 📝 レコーディング後の作業

### 1. コードレビュー
```bash
# 生成されたファイルを確認
cat e2e/tests/recorded_*.spec.js
```

### 2. テスト実行
```bash
# 生成されたテストを実行
npm run test:e2e e2e/tests/recorded_*.spec.js
```

### 3. コード整理
- 不要な操作を削除
- 意味のあるテスト名に変更
- アサーション（検証）を追加
- テストデータを外部化

## 🚀 便利なコマンド集

```bash
# 特定の要素にフォーカスして録画
npx playwright codegen --target=javascript --save-trace=trace.zip http://localhost:8080

# モバイルビューポートで録画
npx playwright codegen --viewport-size=375,667 http://localhost:8080

# ダークモードで録画
npx playwright codegen --color-scheme=dark http://localhost:8080

# 特定のユーザーエージェントで録画
npx playwright codegen --user-agent="Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X)" http://localhost:8080
```