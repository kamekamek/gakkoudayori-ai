// @ts-check
const { test, expect } = require('@playwright/test');

test.describe('ホームページ', () => {
  test.beforeEach(async ({ page }) => {
    // テスト前にホームページにアクセス
    await page.goto('/');
  });

  test('ページタイトルが正しく表示される', async ({ page }) => {
    await expect(page).toHaveTitle(/学校だよりAI/);
  });

  test('メインコンテナが表示される', async ({ page }) => {
    // メイン要素の存在確認
    const mainContainer = page.locator('[data-testid="main-container"]');
    await expect(mainContainer).toBeVisible();
  });

  test('AIアシスタントウィジェットが表示される', async ({ page }) => {
    // AIチャットウィジェットの存在確認
    const chatWidget = page.locator('[data-testid="adk-chat-widget"]');
    await expect(chatWidget).toBeVisible();
  });

  test('音声録音ボタンが機能する', async ({ page }) => {
    // 録音ボタンの存在と動作確認
    const recordButton = page.locator('[data-testid="record-button"]');
    await expect(recordButton).toBeVisible();
    await recordButton.click();
    
    // 録音状態のUI変化を確認
    await expect(recordButton).toHaveClass(/recording/);
  });

  test('レスポンシブレイアウトの動作確認', async ({ page }) => {
    // デスクトップレイアウト
    await page.setViewportSize({ width: 1200, height: 800 });
    const desktopLayout = page.locator('[data-testid="desktop-layout"]');
    await expect(desktopLayout).toBeVisible();

    // モバイルレイアウト
    await page.setViewportSize({ width: 400, height: 800 });
    const mobileLayout = page.locator('[data-testid="mobile-layout"]');
    await expect(mobileLayout).toBeVisible();
  });
});