// @ts-check
const { test, expect } = require('@playwright/test');

/**
 * ホーム画面のE2Eテスト
 */
test.describe('ホーム画面テスト', () => {
  test('ホーム画面が正しく表示される', async ({ page }) => {
    // ホーム画面にアクセス
    await page.goto('/');
    
    // ページのタイトルを確認
    await expect(page).toHaveTitle(/学校だより/);
    
    // 画面のロードを待機（Flutterアプリが完全にロードされるまで）
    await page.waitForSelector('flt-glass-pane', { timeout: 10000 });
    
    // スクリーンショットを撮影（デバッグ用）
    await page.screenshot({ path: 'e2e-results/home-screen.png', fullPage: true });
    
    // 必要に応じて、画面上の特定の要素の存在を確認
    // 注: Flutterアプリの場合、DOMセレクタでの検証は難しいため、
    // 視覚的なテストやアクセシビリティテストを検討する
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
