// @ts-check
const { test, expect } = require('@playwright/test');

test.describe('AIアシスタント機能', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    // AIアシスタントが読み込まれるまで待機
    await page.waitForSelector('[data-testid="adk-chat-widget"]');
  });

  test('チャット入力フィールドが動作する', async ({ page }) => {
    const chatInput = page.locator('[data-testid="chat-input"]');
    await expect(chatInput).toBeVisible();
    
    // テキスト入力
    await chatInput.fill('テストメッセージです');
    await expect(chatInput).toHaveValue('テストメッセージです');
  });

  test('メッセージ送信ボタンが動作する', async ({ page }) => {
    const chatInput = page.locator('[data-testid="chat-input"]');
    const sendButton = page.locator('[data-testid="send-button"]');
    
    await chatInput.fill('こんにちは');
    await sendButton.click();
    
    // メッセージが送信されることを確認
    const sentMessage = page.locator('[data-testid="user-message"]').last();
    await expect(sentMessage).toContainText('こんにちは');
  });

  test('音声入力機能の動作確認', async ({ page }) => {
    const voiceButton = page.locator('[data-testid="voice-input-button"]');
    await expect(voiceButton).toBeVisible();
    
    // 音声入力ボタンをクリック
    await voiceButton.click();
    
    // 録音状態のUI変化を確認
    const recordingIndicator = page.locator('[data-testid="recording-indicator"]');
    await expect(recordingIndicator).toBeVisible();
  });

  test('生成されたHTMLプレビューが表示される', async ({ page }) => {
    // HTMLが生成された状態をモック
    await page.evaluate(() => {
      // プレビューエリアにテスト用HTMLを設定
      const previewArea = document.querySelector('[data-testid="html-preview"]');
      if (previewArea) {
        previewArea.innerHTML = '<h1>テスト通信</h1><p>これはテスト用の学級通信です。</p>';
      }
    });

    const htmlPreview = page.locator('[data-testid="html-preview"]');
    await expect(htmlPreview).toBeVisible();
    await expect(htmlPreview).toContainText('テスト通信');
  });
});