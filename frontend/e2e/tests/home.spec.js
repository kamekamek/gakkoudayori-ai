// @ts-check
const { test, expect } = require('@playwright/test');

/**
 * ホーム画面のE2Eテスト
 */
test.describe('ホーム画面テスト', () => {
  test('ホームページが正しく表示される', async ({ page }) => {
    // ホーム画面に移動（ローカルのHTTPサーバーを指定）
    await page.goto('http://localhost:8090/');

    // ページタイトルを検証
    await expect(page).toHaveTitle(/学校だよりAI - E2Eテスト用/);

    // ヘッダーが存在することを確認
    const header = page.locator('h1:has-text("学校だよりAI")');
    await expect(header).toBeVisible();

    // ホーム画面の主要コンポーネントが表示されていることを確認
    await expect(page.locator('h2:has-text("E2Eテスト用ホーム画面")')).toBeVisible();
    await expect(page.locator('button:has-text("テストボタン")')).toBeVisible();
  });

  test('ボタンクリックでメッセージが表示される', async ({ page }) => {
    // ホーム画面に移動
    await page.goto('http://localhost:8090/');

    // 初期状態ではメッセージが非表示であることを確認
    const message = page.locator('#message');
    await expect(message).toBeHidden();

    // ボタンをクリック
    await page.click('#test-button');

    // メッセージが表示されたことを確認
    await expect(message).toBeVisible();
    await expect(message).toContainText('ボタンがクリックされました');
  });
});

/**
 * アクセシビリティテスト
 */
test.describe('アクセシビリティテスト', () => {
  test('ホーム画面のアクセシビリティチェック', async ({ page }) => {
    await page.goto('/');
    
    // アクセシビリティスナップショットを取得
    const snapshot = await page.accessibility.snapshot();
    
    // アプリケーションのルート要素が存在することを確認
    expect(snapshot).toBeTruthy();
  });
});
