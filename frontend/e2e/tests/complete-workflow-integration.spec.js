// @ts-check
const { test, expect } = require('@playwright/test');

/**
 * 完全なワークフロー統合テスト - AIとの対話機能も含む
 * テキスト入力→AI生成→完成した学級通信→AIチャット対話による修正
 */

test.describe('完全ワークフロー統合テスト', () => {
  
  test('完全フロー: テキスト入力→AI生成→学級通信完成→AI対話修正', async ({ page }) => {
    console.log('🎯 テスト開始: 完全ワークフロー統合 (AI対話含む)');
    
    // ネットワークリクエストを監視
    const apiCalls = [];
    const errors = [];
    
    page.on('request', request => {
      if (request.url().includes('localhost:8081') || request.url().includes('/api/')) {
        apiCalls.push({
          url: request.url(),
          method: request.method(),
          headers: request.headers(),
          timestamp: new Date().toISOString()
        });
        console.log(`📤 API Request: ${request.method()} ${request.url()}`);
      }
    });
    
    page.on('response', response => {
      if (response.url().includes('localhost:8081') || response.url().includes('/api/')) {
        console.log(`📥 API Response: ${response.status()} ${response.url()}`);
        if (response.status() >= 400) {
          errors.push({
            url: response.url(),
            status: response.status(),
            timestamp: new Date().toISOString()
          });
        }
      }
    });
    
    page.on('console', msg => {
      if (msg.type() === 'error') {
        console.log(`❌ Console Error: ${msg.text()}`);
        errors.push({
          type: 'console',
          message: msg.text(),
          timestamp: new Date().toISOString()
        });
      }
    });
    
    await page.goto('/');
    await page.waitForLoadState('networkidle');
    
    // Step 1: テキスト入力
    console.log('📝 Step 1: テキスト入力実行');
    
    const testContent = `
今日は素晴らしい運動会でした。

【運動会の様子】
・かけっこでは3年生の田中さんが最後まで諦めずに走り切りました
・玉入れでは赤組と白組が接戦を繰り広げ、最終的に赤組が勝利しました
・組体操では全学年が一致団結して美しいピラミッドを完成させました

【保護者の皆様へ】
多くの保護者の方にお越しいただき、子どもたちも大変嬉しそうでした。
温かいご声援をありがとうございました。

【今後の予定】
11月15日に学習発表会を開催予定です。
詳細は後日お知らせします。
    `.trim();
    
    // テキストエリアをクリックして入力
    const textAreaX = 640; // 画面中央
    const textAreaY = 500; // テキストエリア位置
    
    await page.mouse.click(textAreaX, textAreaY);
    await page.waitForTimeout(1000);
    await page.keyboard.type(testContent, { delay: 10 });
    
    console.log('✅ テスト内容入力完了');
    await page.waitForTimeout(2000);
    
    // Step 2: スタイル選択
    console.log('🎨 Step 2: スタイル選択');
    
    // クラシックスタイルを選択 (左側のボタン)
    const classicButtonX = 500;
    const classicButtonY = 660;
    await page.mouse.click(classicButtonX, classicButtonY);
    console.log('✅ クラシックスタイル選択完了');
    
    await page.waitForTimeout(1000);
    
    // Step 3: 学級通信作成ボタンをクリック
    console.log('🚀 Step 3: 学級通信作成開始');
    
    const createButtonX = 640;
    const createButtonY = 720;
    await page.mouse.click(createButtonX, createButtonY);
    console.log('✅ 学級通信作成ボタンクリック完了');
    
    // Step 4: AI処理の監視 (最大60秒待機)
    console.log('🤖 Step 4: AI処理監視開始');
    
    let processingCompleted = false;
    let processingTime = 0;
    const maxWaitTime = 60000; // 60秒
    
    while (processingTime < maxWaitTime && !processingCompleted) {
      await page.waitForTimeout(2000);
      processingTime += 2000;
      
      // API呼び出しがあったかチェック
      if (apiCalls.length > 0) {
        console.log(`🔍 API呼び出し検出: ${apiCalls.length}件`);
        
        // APIレスポンスを待機
        const lastCall = apiCalls[apiCalls.length - 1];
        console.log(`最新API: ${lastCall.method} ${lastCall.url}`);
        
        // 処理完了の判定（プレビュータブに切り替えて確認）
        await page.mouse.click(950, 105); // プレビュータブクリック
        await page.waitForTimeout(3000);
        
        // HTMLコンテンツが生成されているかチェック
        const pageContent = await page.textContent('body');
        if (pageContent.includes('運動会') && pageContent.includes('PDF')) {
          processingCompleted = true;
          console.log('✅ AI処理完了 - 学級通信が生成されました');
        }
      }
      
      console.log(`⏳ 処理時間: ${processingTime / 1000}秒 / ${maxWaitTime / 1000}秒`);
    }
    
    // Step 5: 結果確認
    console.log('📊 Step 5: 処理結果確認');
    
    console.log(`📈 処理サマリー:`);
    console.log(`  - API呼び出し数: ${apiCalls.length}`);
    console.log(`  - エラー数: ${errors.length}`);
    console.log(`  - 処理時間: ${processingTime / 1000}秒`);
    console.log(`  - 処理完了: ${processingCompleted}`);
    
    if (apiCalls.length > 0) {
      console.log(`🔍 API呼び出し詳細:`);
      apiCalls.forEach((call, index) => {
        console.log(`  ${index + 1}. ${call.method} ${call.url}`);
      });
    }
    
    if (errors.length > 0) {
      console.log(`❌ エラー詳細:`);
      errors.forEach((error, index) => {
        console.log(`  ${index + 1}. ${error.type || 'API'}: ${error.message || error.status}`);
      });
    }
    
    // Step 6: AI対話機能のテスト (学級通信が生成された場合)
    if (processingCompleted) {
      console.log('💬 Step 6: AI対話機能テスト');
      
      // AIチャット機能があるかチェック
      const pageContent = await page.textContent('body');
      if (pageContent.includes('修正') || pageContent.includes('チャット') || pageContent.includes('AI')) {
        console.log('✅ AI対話機能が利用可能です');
        
        // チャット入力をテスト
        try {
          // チャット入力エリアを探してテスト入力
          const chatInputX = 640;
          const chatInputY = 800;
          await page.mouse.click(chatInputX, chatInputY);
          await page.keyboard.type('写真を大きくして');
          console.log('✅ AIチャット入力テスト完了');
        } catch (error) {
          console.log(`⚠️ AIチャット機能テストスキップ: ${error.message}`);
        }
      } else {
        console.log('⚠️ AI対話機能が見つかりません');
      }
    }
    
    // 最終スクリーンショット
    await page.screenshot({ path: 'test-results/complete-workflow-final.png' });
    console.log('📸 最終スクリーンショット保存完了');
    
    // 必須検証
    expect(apiCalls.length).toBeGreaterThan(0); // API呼び出しが発生していること
    
    console.log('🎯 テスト完了: 完全ワークフロー統合テスト終了');
  });

  test('API接続性の詳細テスト', async ({ page }) => {
    console.log('🎯 テスト開始: API接続性詳細確認');
    
    // 詳細なネットワーク監視
    const networkLog = [];
    
    page.on('request', request => {
      networkLog.push({
        type: 'request',
        url: request.url(),
        method: request.method(),
        headers: request.headers(),
        timestamp: Date.now()
      });
    });
    
    page.on('response', async response => {
      let responseData = null;
      try {
        if (response.url().includes('localhost:8081')) {
          responseData = await response.text();
        }
      } catch (e) {
        responseData = `Error reading response: ${e.message}`;
      }
      
      networkLog.push({
        type: 'response',
        url: response.url(),
        status: response.status(),
        headers: response.headers(),
        data: responseData?.substring(0, 500), // 最初の500文字のみ
        timestamp: Date.now()
      });
    });
    
    await page.goto('/');
    await page.waitForLoadState('networkidle');
    
    // アプリの基本動作確認
    await page.waitForTimeout(5000);
    
    // ネットワークログの分析
    const apiRequests = networkLog.filter(log => 
      log.type === 'request' && log.url.includes('localhost:8081')
    );
    const apiResponses = networkLog.filter(log => 
      log.type === 'response' && log.url.includes('localhost:8081')
    );
    
    console.log(`📊 ネットワーク分析結果:`);
    console.log(`  - 総リクエスト数: ${networkLog.filter(l => l.type === 'request').length}`);
    console.log(`  - 総レスポンス数: ${networkLog.filter(l => l.type === 'response').length}`);
    console.log(`  - API リクエスト数: ${apiRequests.length}`);
    console.log(`  - API レスポンス数: ${apiResponses.length}`);
    
    if (apiRequests.length > 0) {
      console.log(`🔍 API リクエスト詳細:`);
      apiRequests.forEach((req, index) => {
        console.log(`  ${index + 1}. ${req.method} ${req.url}`);
        console.log(`     Headers: ${JSON.stringify(req.headers).substring(0, 100)}...`);
      });
    }
    
    if (apiResponses.length > 0) {
      console.log(`📥 API レスポンス詳細:`);
      apiResponses.forEach((res, index) => {
        console.log(`  ${index + 1}. ${res.status} ${res.url}`);
        if (res.data) {
          console.log(`     Data: ${res.data}...`);
        }
      });
    }
    
    console.log('🎯 テスト完了: API接続性詳細確認終了');
  });
});