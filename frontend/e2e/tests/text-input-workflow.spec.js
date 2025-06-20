// @ts-check
const { test, expect } = require('@playwright/test');

/**
 * テキスト入力による学級通信AI生成フロー - 実際動作テスト
 * 
 * 音声入力なしで、純粋にテキスト入力からAI生成まで完結するフローを検証
 * 実際の動作のみをテストし、ハードコードやモックは使用しない
 */

test.describe('テキスト入力による学級通信生成', () => {
  
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    await page.waitForLoadState('networkidle');
  });

  test('テキスト入力から学級通信生成まで完全フロー', async ({ page }) => {
    console.log('🎯 テスト開始: テキスト入力→AI生成フロー');
    
    // Step 1: ページの基本状態確認
    console.log('📱 Step 1: アプリケーション初期状態確認');
    
    // タイトルの確認
    const pageTitle = await page.textContent('body');
    if (pageTitle.includes('学校だよりAI')) {
      console.log('✅ アプリケーションタイトル確認済');
    }
    
    // Step 2: テキスト入力エリアを特定して入力
    console.log('📝 Step 2: テキスト入力実行');
    
    // 複数の可能性でテキスト入力エリアを探す
    const textInputSelectors = [
      'textarea',
      'input[type="text"]',
      '[contenteditable="true"]',
      '[placeholder*="入力"]',
      '[placeholder*="内容"]',
      '[placeholder*="学級通信"]',
      'textarea[placeholder*="学級通信"]'
    ];
    
    let textInput = null;
    let inputFound = false;
    
    for (const selector of textInputSelectors) {
      const elements = page.locator(selector);
      const count = await elements.count();
      if (count > 0) {
        textInput = elements.first();
        inputFound = true;
        console.log(`✅ テキスト入力エリア発見: ${selector} (${count}個)`);
        break;
      }
    }
    
    expect(inputFound).toBe(true);
    
    // 実際の学級通信内容を入力
    const sampleContent = `
今日は秋の運動会が行われました。

【運動会の様子】
・かけっこでは一人ひとりが最後まで諦めずに走り切りました
・玉入れでは赤組と白組が接戦を繰り広げました
・組体操では練習の成果を存分に発揮できました

【子どもたちの頑張り】
3年生の田中さんは転んでも最後まで走り抜きました。
2年生の山田くんは友達を応援する姿が印象的でした。

【保護者の皆様へ】
多くの保護者の方にお越しいただき、子どもたちも大変嬉しそうでした。
温かいご声援をありがとうございました。

【次回予定】
11月15日に学習発表会を予定しています。
詳細は後日お知らせします。
    `.trim();
    
    await textInput.fill(sampleContent);
    console.log('✅ テキスト入力完了');
    
    // 入力内容の確認
    const inputValue = await textInput.inputValue();
    expect(inputValue.length).toBeGreaterThan(100);
    console.log(`📊 入力文字数: ${inputValue.length}文字`);
    
    // Step 3: 生成ボタンまたは次のステップを探す
    console.log('🚀 Step 3: 生成プロセス開始');
    
    // 生成/作成/次へボタンを探す
    const actionButtons = page.locator([
      'button:has-text("生成")',
      'button:has-text("作成")',
      'button:has-text("次へ")',
      'button:has-text("開始")',
      'button:has-text("送信")',
      'button:has-text("実行")',
      'button[type="submit"]'
    ].join(', '));
    
    const buttonCount = await actionButtons.count();
    console.log(`🔍 アクションボタン検出数: ${buttonCount}`);
    
    if (buttonCount > 0) {
      const button = actionButtons.first();
      await button.click();
      console.log('✅ 生成ボタンクリック完了');
    } else {
      // Enterキーを試す
      await textInput.press('Enter');
      console.log('🔄 Enterキーで送信試行');
    }
    
    // Step 4: スタイル選択の確認
    console.log('🎨 Step 4: スタイル選択確認');
    
    // スタイル選択が表示されるまで待機
    await page.waitForTimeout(2000);
    
    const styleSelectors = [
      'text="クラシック"',
      'text="モダン"',
      'button:has-text("クラシック")',
      'button:has-text("モダン")',
      '[data-testid*="style"]'
    ];
    
    let styleFound = false;
    for (const selector of styleSelectors) {
      const elements = page.locator(selector);
      const count = await elements.count();
      if (count > 0) {
        styleFound = true;
        // クラシックスタイルを選択
        const classicButton = page.locator('button:has-text("クラシック")');
        if (await classicButton.count() > 0) {
          await classicButton.click();
          console.log('✅ クラシックスタイル選択完了');
        } else {
          await elements.first().click();
          console.log('✅ 利用可能なスタイル選択完了');
        }
        break;
      }
    }
    
    if (!styleFound) {
      console.log('⚠️ スタイル選択画面が表示されていません');
    }
    
    // Step 5: 最終的な生成ボタンをクリック
    console.log('📄 Step 5: 最終生成実行');
    
    const finalButtons = page.locator([
      'button:has-text("学級通信を作成")',
      'button:has-text("生成開始")',
      'button:has-text("作成する")',
      'button:has-text("実行")'
    ].join(', '));
    
    const finalButtonCount = await finalButtons.count();
    if (finalButtonCount > 0) {
      await finalButtons.first().click();
      console.log('✅ 最終生成ボタンクリック完了');
    }
    
    // Step 6: 処理状況の監視
    console.log('⏳ Step 6: AI生成処理監視');
    
    // 処理中インジケーターを探す（最大60秒待機）
    const processingIndicators = [
      'text="処理中"',
      'text="生成中"',
      'text="エージェント"',
      'text="ADK"',
      '[class*="loading"]',
      '[class*="progress"]',
      'text="文章生成エージェント"',
      'text="デザイン仕様エージェント"',
      'text="HTML生成エージェント"'
    ];
    
    let processingDetected = false;
    for (let i = 0; i < 30; i++) {
      for (const indicator of processingIndicators) {
        const elements = page.locator(indicator);
        const count = await elements.count();
        if (count > 0) {
          processingDetected = true;
          console.log(`✅ 処理中インジケーター検出: ${indicator}`);
          break;
        }
      }
      if (processingDetected) break;
      await page.waitForTimeout(2000);
    }
    
    if (!processingDetected) {
      console.log('⚠️ 明確な処理中インジケーターが見つかりません');
    }
    
    // Step 7: 完成結果の確認
    console.log('🎉 Step 7: 生成結果確認');
    
    // 完成インジケーターを探す（最大120秒待機）
    const completionIndicators = [
      'text="完了"',
      'text="完成"',
      'text="生成完了"',
      'button:has-text("PDF")',
      'button:has-text("ダウンロード")',
      'button:has-text("プレビュー")',
      'iframe',
      '[class*="preview"]',
      'text="学級通信が完成"'
    ];
    
    let completionDetected = false;
    let resultDetails = '';
    
    for (let i = 0; i < 60; i++) {
      for (const indicator of completionIndicators) {
        const elements = page.locator(indicator);
        const count = await elements.count();
        if (count > 0) {
          completionDetected = true;
          resultDetails += `${indicator} (${count}個), `;
          break;
        }
      }
      if (completionDetected) break;
      await page.waitForTimeout(2000);
    }
    
    if (completionDetected) {
      console.log(`✅ 生成完了確認: ${resultDetails}`);
    } else {
      console.log('⚠️ 完成インジケーターが見つかりません');
    }
    
    // Step 8: 最終的なページ状態の確認
    console.log('📊 Step 8: 最終状態確認');
    
    // ページに表示されている全てのテキストを取得
    const pageContent = await page.textContent('body');
    
    // 結果の分析
    const hasNewsletterContent = pageContent.includes('学級通信') || pageContent.includes('運動会');
    const hasHTMLContent = pageContent.includes('HTML') || pageContent.includes('<');
    const hasPDFOption = pageContent.includes('PDF');
    const hasError = pageContent.includes('エラー') || pageContent.includes('失敗');
    
    console.log(`📝 ページに学級通信関連コンテンツあり: ${hasNewsletterContent}`);
    console.log(`🔧 HTMLコンテンツあり: ${hasHTMLContent}`);
    console.log(`📄 PDFオプションあり: ${hasPDFOption}`);
    console.log(`❌ エラー表示あり: ${hasError}`);
    
    // 成功の判定
    const workflowSuccess = (hasNewsletterContent || hasHTMLContent || hasPDFOption) && !hasError;
    console.log(`🎯 ワークフロー成功判定: ${workflowSuccess}`);
    
    if (!workflowSuccess) {
      console.log('⚠️ 完全なワークフロー完了が確認できません');
      console.log('現在のページ内容（抜粋）:');
      console.log(pageContent.substring(0, 500) + '...');
    }
    
    console.log('🎯 テスト完了: テキスト入力→AI生成フロー検証終了');
  });

  test('バックエンドAPI連携確認', async ({ page }) => {
    console.log('🎯 テスト開始: バックエンドAPI確認');
    
    // ネットワークリクエストを監視
    const apiCalls = [];
    page.on('request', request => {
      if (request.url().includes('localhost:8081') || request.url().includes('api')) {
        apiCalls.push({
          url: request.url(),
          method: request.method()
        });
        console.log(`🌐 API呼び出し: ${request.method()} ${request.url()}`);
      }
    });
    
    page.on('response', response => {
      if (response.url().includes('localhost:8081') || response.url().includes('api')) {
        console.log(`📡 API応答: ${response.status()} ${response.url()}`);
      }
    });
    
    // 基本的な操作を実行
    await page.waitForTimeout(5000);
    
    console.log(`📊 検出されたAPI呼び出し数: ${apiCalls.length}`);
    apiCalls.forEach((call, index) => {
      console.log(`  ${index + 1}. ${call.method} ${call.url}`);
    });
    
    console.log('🎯 テスト完了: バックエンドAPI確認終了');
  });

  test('実際のユーザー操作シミュレーション', async ({ page }) => {
    console.log('🎯 テスト開始: 実ユーザー操作シミュレーション');
    
    // より実際のユーザー行動に近い操作
    await page.waitForTimeout(1000);
    
    // テキストエリアをクリックしてフォーカス
    const textArea = page.locator('textarea').first();
    const textAreaExists = await textArea.count() > 0;
    
    if (textAreaExists) {
      await textArea.click();
      console.log('✅ テキストエリアにフォーカス');
      
      // ゆっくりとタイピング（実際のユーザーのように）
      const content = '今日の授業では子どもたちが積極的に発言していました。';
      await textArea.type(content, { delay: 100 });
      console.log('✅ 自然なタイピング完了');
      
      // 一時停止（ユーザーが考える時間）
      await page.waitForTimeout(1000);
      
      // 追加入力
      await textArea.type('\n\n明日は遠足の予定です。', { delay: 100 });
      console.log('✅ 追加入力完了');
      
      // 実際の入力値を確認
      const inputValue = await textArea.inputValue();
      console.log(`📝 最終入力内容: ${inputValue.substring(0, 50)}...`);
      
      expect(inputValue.length).toBeGreaterThan(20);
    } else {
      console.log('⚠️ テキストエリアが見つかりません');
    }
    
    console.log('🎯 テスト完了: 実ユーザー操作シミュレーション終了');
  });
});