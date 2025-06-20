// @ts-check
const { test, expect } = require('@playwright/test');

/**
 * 修正済み完全ワークフローテスト
 * 正確な座標でボタンクリックを実行
 */

test.describe('修正済み完全ワークフロー', () => {
  
  test('正確な座標でのフルワークフロー実行', async ({ page }) => {
    console.log('🎯 テスト開始: 修正済み完全ワークフロー');
    
    // API監視
    const apiCalls = [];
    page.on('request', request => {
      if (request.url().includes('localhost:8081') || request.url().includes('/api/')) {
        apiCalls.push({
          url: request.url(),
          method: request.method(),
          timestamp: new Date().toISOString()
        });
        console.log(`📤 API Call: ${request.method()} ${request.url()}`);
      }
    });
    
    page.on('response', response => {
      if (response.url().includes('localhost:8081') || response.url().includes('/api/')) {
        console.log(`📥 API Response: ${response.status()} ${response.url()}`);
      }
    });
    
    await page.goto('/');
    await page.waitForLoadState('networkidle');
    
    // Step 1: テキスト入力 - より短く実用的な内容
    console.log('📝 Step 1: テキスト入力');
    const simpleContent = '今日は運動会でした。子どもたちは最後まで頑張りました。';
    
    await page.mouse.click(640, 450); // テキストエリア
    await page.waitForTimeout(500);
    await page.keyboard.type(simpleContent, { delay: 50 });
    console.log('✅ テキスト入力完了');
    
    await page.waitForTimeout(1000);
    
    // Step 2: スタイル選択 - より正確な座標
    console.log('🎨 Step 2: スタイル選択');
    await page.mouse.click(487, 645); // クラシックボタンの中央
    console.log('✅ クラシック選択完了');
    
    await page.waitForTimeout(1000);
    
    // 現在の画面状態を確認
    await page.screenshot({ path: 'test-results/before-create-button.png' });
    
    // Step 3: 学級通信作成ボタンクリック - 正確な座標
    console.log('🚀 Step 3: 作成ボタンクリック');
    
    // 緑色の「学級通信を作成する」ボタンをクリック
    await page.mouse.click(640, 695); // 緑ボタンの中央
    console.log('✅ 作成ボタンクリック完了');
    
    // Step 4: 短時間でのAPI呼び出し確認
    console.log('🤖 Step 4: API呼び出し確認');
    
    // 5秒待ってAPI呼び出しをチェック
    await page.waitForTimeout(5000);
    
    if (apiCalls.length > 0) {
      console.log(`✅ API呼び出し検出: ${apiCalls.length}件`);
      apiCalls.forEach((call, index) => {
        console.log(`  ${index + 1}. ${call.method} ${call.url}`);
      });
      
      // さらに待機してレスポンスを確認
      console.log('⏳ AI処理完了を待機...');
      await page.waitForTimeout(30000); // 30秒待機
      
      // プレビュータブに切り替えて結果確認
      await page.mouse.click(950, 105); // プレビュータブ
      await page.waitForTimeout(2000);
      
      await page.screenshot({ path: 'test-results/after-processing.png' });
      
      const pageContent = await page.textContent('body');
      const hasResult = pageContent.includes('運動会') && (
        pageContent.includes('PDF') || 
        pageContent.includes('プレビュー') ||
        pageContent.includes('再生成')
      );
      
      if (hasResult) {
        console.log('🎉 学級通信生成成功！');
        
        // PDFボタンがあるかテスト
        try {
          await page.mouse.click(600, 530); // PDFボタン位置
          console.log('✅ PDFボタンクリックテスト完了');
          await page.waitForTimeout(3000);
        } catch (error) {
          console.log('⚠️ PDFボタンテストスキップ');
        }
      } else {
        console.log('⚠️ 学級通信生成が未完了または結果が見つかりません');
      }
      
    } else {
      console.log('❌ API呼び出しが発生していません');
      
      // デバッグ: 現在の画面状態を確認
      const currentContent = await page.textContent('body');
      console.log('📄 現在の画面内容 (抜粋):');
      console.log(currentContent.substring(0, 200));
    }
    
    // 最終結果
    console.log('\n📊 テスト結果サマリー:');
    console.log(`  API呼び出し: ${apiCalls.length}件`);
    console.log(`  成功判定: ${apiCalls.length > 0 ? 'SUCCESS' : 'FAILED'}`);
    
    // APIが呼び出されていることを必須条件とする
    expect(apiCalls.length).toBeGreaterThan(0);
    
    console.log('🎯 テスト完了: 修正済み完全ワークフロー');
  });

  test('ボタン座標の詳細調査', async ({ page }) => {
    console.log('🎯 テスト開始: ボタン座標調査');
    
    await page.goto('/');
    await page.waitForLoadState('networkidle');
    
    // 簡単なテキスト入力
    await page.mouse.click(640, 450);
    await page.keyboard.type('テスト');
    await page.waitForTimeout(1000);
    
    // スタイル選択
    await page.mouse.click(487, 645);
    await page.waitForTimeout(1000);
    
    // ボタンが表示された状態のスクリーンショット
    await page.screenshot({ path: 'test-results/button-coordinates-debug.png' });
    
    // 複数の座標でクリックテスト
    const buttonCoordinates = [
      { x: 640, y: 695, name: '中央' },
      { x: 640, y: 700, name: '少し下' },
      { x: 640, y: 690, name: '少し上' },
      { x: 620, y: 695, name: '少し左' },
      { x: 660, y: 695, name: '少し右' },
    ];
    
    for (const coord of buttonCoordinates) {
      console.log(`🖱️ ${coord.name}座標 (${coord.x}, ${coord.y}) をクリック`);
      await page.mouse.click(coord.x, coord.y);
      await page.waitForTimeout(2000);
      
      // 画面が変化したかチェック
      const content = await page.textContent('body');
      if (content.includes('AI生成中') || content.includes('処理中')) {
        console.log(`✅ ${coord.name}座標で処理開始を確認`);
        break;
      }
    }
    
    console.log('🎯 テスト完了: ボタン座標調査');
  });
});