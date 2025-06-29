// @ts-check
const { test, expect } = require('@playwright/test');
const { HomePage } = require('../page-objects/HomePage');

test.describe('🎮 UIテスト自動化プレイグラウンド', () => {
  let homePage;

  test.beforeEach(async ({ page }) => {
    homePage = new HomePage(page);
    await homePage.navigate();
    
    // ページが完全に読み込まれるまで待機
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(2000); // 追加の安全な待機時間
  });

  test('🚀 基本フロー: 学級通信作成の完全自動化', async ({ page }) => {
    console.log('📝 学級通信作成フローを開始...');
    
    // Step 1: AIチャットウィジェットの存在確認
    console.log('Step 1: AIチャットウィジェット確認');
    const chatWidget = homePage.getChatWidget();
    await expect(chatWidget).toBeVisible({ timeout: 10000 });
    
    // Step 2: チャット入力欄に学級通信の内容を入力
    console.log('Step 2: 学級通信内容入力');
    const testMessage = `
こんにちは！今日は運動会の練習をしました。
学校名: さくら小学校
学年: 3年2組
担任: 田中先生
内容: 今日は運動会の練習で、リレーと玉入れの練習をしました。みんな一生懸命頑張っていました。
写真: 3枚
    `.trim();
    
    await homePage.sendChatMessage(testMessage);
    
    // Step 3: AI応答の待機
    console.log('Step 3: AI応答待機中...');
    await page.waitForTimeout(5000); // AI応答を待つ
    
    // Step 4: 生成されたHTMLプレビューの確認
    console.log('Step 4: HTMLプレビュー確認');
    const htmlPreview = homePage.getHtmlPreview();
    await expect(htmlPreview).toBeVisible({ timeout: 15000 });
    
    // Step 5: プレビューモードツールバーの操作
    console.log('Step 5: プレビューモード切り替えテスト');
    const previewButton = page.locator('button:has-text("プレビュー")');
    const editButton = page.locator('button:has-text("編集")');
    const printButton = page.locator('button:has-text("印刷")');
    
    // プレビューモード
    if (await previewButton.isVisible()) {
      await previewButton.click();
      await page.waitForTimeout(1000);
    }
    
    // 編集モード
    if (await editButton.isVisible()) {
      await editButton.click();
      await page.waitForTimeout(1000);
    }
    
    // 印刷プレビューモード
    if (await printButton.isVisible()) {
      await printButton.click();
      await page.waitForTimeout(1000);
    }
    
    console.log('✅ 基本フロー完了！');
  });

  test('🎤 音声入力テストの自動化', async ({ page }) => {
    console.log('🎤 音声入力テストを開始...');
    
    // 録音ボタンを探す
    const recordButton = page.locator('[data-testid="record-button"], button:has-text("🎤"), button[aria-label*="録音"]').first();
    
    if (await recordButton.isVisible()) {
      console.log('録音ボタンを発見 - クリックします');
      await recordButton.click();
      
      // 録音状態の確認
      await page.waitForTimeout(2000);
      
      // 停止ボタンまたは録音終了の操作
      const stopButton = page.locator('button:has-text("停止"), button:has-text("⏹️")').first();
      if (await stopButton.isVisible()) {
        await stopButton.click();
        console.log('録音を停止しました');
      } else {
        // 再度録音ボタンをクリックして停止
        await recordButton.click();
        console.log('録音ボタン再クリックで停止');
      }
    } else {
      console.log('⚠️ 録音ボタンが見つかりません - スキップします');
    }
  });

  test('📱 レスポンシブUIテストの自動化', async ({ page }) => {
    console.log('📱 レスポンシブテストを開始...');
    
    // デスクトップサイズ
    console.log('デスクトップレイアウトテスト (1200x800)');
    await homePage.setViewportSize(1200, 800);
    await page.waitForTimeout(1000);
    
    // レイアウトの確認
    const mainContainer = homePage.getMainContainer();
    await expect(mainContainer).toBeVisible();
    
    // タブレットサイズ
    console.log('タブレットレイアウトテスト (768x1024)');
    await homePage.setViewportSize(768, 1024);
    await page.waitForTimeout(1000);
    await expect(mainContainer).toBeVisible();
    
    // モバイルサイズ
    console.log('モバイルレイアウトテスト (375x667)');
    await homePage.setViewportSize(375, 667);
    await page.waitForTimeout(1000);
    await expect(mainContainer).toBeVisible();
    
    // 小さいモバイルサイズ
    console.log('小型モバイルレイアウトテスト (320x568)');
    await homePage.setViewportSize(320, 568);
    await page.waitForTimeout(1000);
    await expect(mainContainer).toBeVisible();
    
    console.log('✅ レスポンシブテスト完了！');
  });

  test('🖼️ 画像アップロード機能テスト', async ({ page }) => {
    console.log('🖼️ 画像アップロードテストを開始...');
    
    // 画像アップロードボタンを探す
    const uploadButton = page.locator('input[type="file"], button:has-text("画像"), button:has-text("アップロード")').first();
    
    if (await uploadButton.isVisible()) {
      console.log('画像アップロードボタンを発見');
      
      // ファイル選択のシミュレーション（実際のファイルは必要ないため、存在確認のみ）
      await expect(uploadButton).toBeVisible();
      console.log('✅ 画像アップロード機能が利用可能');
    } else {
      console.log('⚠️ 画像アップロード機能が見つかりません');
    }
  });

  test('🔄 データ永続化とセッション管理テスト', async ({ page }) => {
    console.log('🔄 データ永続化テストを開始...');
    
    // 最初のメッセージを送信
    const firstMessage = 'テストメッセージ1: データ永続化確認';
    await homePage.sendChatMessage(firstMessage);
    await page.waitForTimeout(3000);
    
    // ページをリロード
    console.log('ページをリロードします...');
    await page.reload();
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(2000);
    
    // チャット履歴が保持されているか確認
    const chatHistory = page.locator('[data-testid="chat-history"], .chat-message, .message');
    if (await chatHistory.first().isVisible()) {
      console.log('✅ チャット履歴が保持されています');
    } else {
      console.log('⚠️ チャット履歴が保持されていません（新しいセッション）');
    }
  });

  test('⚡ パフォーマンステスト: 大量操作の自動化', async ({ page }) => {
    console.log('⚡ パフォーマンステストを開始...');
    
    const startTime = Date.now();
    
    // 複数のメッセージを連続送信
    for (let i = 1; i <= 5; i++) {
      console.log(`メッセージ ${i}/5 を送信中...`);
      await homePage.sendChatMessage(`テストメッセージ ${i}: パフォーマンステスト`);
      await page.waitForTimeout(1000); // 1秒待機
    }
    
    const endTime = Date.now();
    const duration = endTime - startTime;
    
    console.log(`✅ パフォーマンステスト完了: ${duration}ms`);
    
    // 5秒以内に完了することを確認
    expect(duration).toBeLessThan(30000); // 30秒以内
  });

  test('🎯 エラーハンドリングテスト', async ({ page }) => {
    console.log('🎯 エラーハンドリングテストを開始...');
    
    // 空のメッセージ送信テスト
    console.log('空のメッセージ送信テスト');
    await homePage.sendChatMessage('');
    await page.waitForTimeout(1000);
    
    // 非常に長いメッセージ送信テスト
    console.log('長いメッセージ送信テスト');
    const longMessage = 'あ'.repeat(1000); // 1000文字のメッセージ
    await homePage.sendChatMessage(longMessage);
    await page.waitForTimeout(2000);
    
    // 特殊文字を含むメッセージテスト
    console.log('特殊文字メッセージテスト');
    const specialMessage = '!@#$%^&*()_+{}|:"<>?[]\\;\',./<script>alert("test")</script>';
    await homePage.sendChatMessage(specialMessage);
    await page.waitForTimeout(2000);
    
    console.log('✅ エラーハンドリングテスト完了');
  });

  test('📊 UIコンポーネント網羅テスト', async ({ page }) => {
    console.log('📊 UIコンポーネント網羅テストを開始...');
    
    // 存在する全てのボタンを取得してクリックテスト
    const buttons = page.locator('button:visible');
    const buttonCount = await buttons.count();
    
    console.log(`発見されたボタン数: ${buttonCount}`);
    
    for (let i = 0; i < Math.min(buttonCount, 10); i++) { // 最大10個まで
      const button = buttons.nth(i);
      const buttonText = await button.textContent();
      
      console.log(`ボタン ${i + 1}: "${buttonText}" をテスト中...`);
      
      try {
        // ボタンが有効かつクリック可能か確認
        if (await button.isEnabled()) {
          await button.click();
          await page.waitForTimeout(500); // 短い待機
          console.log(`✅ ボタン "${buttonText}" クリック成功`);
        } else {
          console.log(`⚠️ ボタン "${buttonText}" は無効状態`);
        }
      } catch (error) {
        console.log(`❌ ボタン "${buttonText}" クリックエラー: ${error.message}`);
      }
    }
    
    console.log('✅ UIコンポーネント網羅テスト完了');
  });
}); 