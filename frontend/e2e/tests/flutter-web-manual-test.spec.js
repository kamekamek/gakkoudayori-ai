// @ts-check
const { test, expect } = require('@playwright/test');

/**
 * Flutter Web手動操作テスト
 * 座標ベースのクリックとキーボード操作でフローを検証
 */

test.describe('Flutter Web手動操作テスト', () => {
  
  test('座標ベースのFlutter Web操作', async ({ page }) => {
    console.log('🎯 テスト開始: Flutter Web手動操作');
    
    await page.goto('/');
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(3000); // Flutterアプリの完全ロードを待機
    
    // スクリーンショットを撮影
    await page.screenshot({ path: 'test-results/flutter-web-initial.png' });
    console.log('📸 初期画面スクリーンショット撮影完了');
    
    // 1. テキスト入力エリアをクリック（座標ベース）
    console.log('🖱️ Step 1: テキスト入力エリアをクリック');
    
    // 画面の中央下部のテキストエリア付近をクリック
    const viewportSize = page.viewportSize();
    const centerX = viewportSize.width / 2;
    const textAreaY = viewportSize.height * 0.6; // 画面の60%の位置
    
    await page.mouse.click(centerX, textAreaY);
    console.log(`✅ 座標 (${centerX}, ${textAreaY}) をクリック`);
    
    await page.waitForTimeout(1000);
    
    // 2. テキスト入力
    console.log('⌨️ Step 2: テキスト入力実行');
    
    const testContent = '今日は運動会がありました。子どもたちは最後まで頑張りました。';
    
    // キーボードで直接入力
    await page.keyboard.type(testContent, { delay: 100 });
    console.log('✅ テキスト入力完了');
    
    await page.waitForTimeout(2000);
    
    // 入力後のスクリーンショット
    await page.screenshot({ path: 'test-results/flutter-web-after-input.png' });
    console.log('📸 入力後スクリーンショット撮影完了');
    
    // 3. 次のステップボタンを探してクリック
    console.log('🔘 Step 3: 次ステップボタン検索');
    
    // 画面下部のボタンエリアをクリック
    const buttonY = viewportSize.height * 0.8; // 画面の80%の位置
    
    // 複数の位置を試行
    const buttonPositions = [
      { x: centerX, y: buttonY, name: '中央ボタン' },
      { x: centerX - 200, y: buttonY, name: '左ボタン' },
      { x: centerX + 200, y: buttonY, name: '右ボタン' },
      { x: centerX, y: buttonY + 50, name: '下部ボタン' }
    ];
    
    for (const pos of buttonPositions) {
      try {
        console.log(`🎯 ${pos.name} (${pos.x}, ${pos.y}) をクリック試行`);
        await page.mouse.click(pos.x, pos.y);
        await page.waitForTimeout(2000);
        
        // クリック後のスクリーンショット
        await page.screenshot({ path: `test-results/flutter-web-after-${pos.name.replace(/\s+/g, '-')}.png` });
        console.log(`📸 ${pos.name}クリック後スクリーンショット撮影`);
        
      } catch (error) {
        console.log(`⚠️ ${pos.name}クリックエラー: ${error.message}`);
      }
    }
    
    // 4. 画面遷移の確認
    console.log('🔄 Step 4: 画面遷移確認');
    
    await page.waitForTimeout(3000);
    
    // ページのタイトルやURLの変化を確認
    const finalUrl = page.url();
    console.log(`🌐 最終URL: ${finalUrl}`);
    
    // 最終状態のスクリーンショット
    await page.screenshot({ path: 'test-results/flutter-web-final.png' });
    console.log('📸 最終状態スクリーンショット撮影完了');
    
    console.log('🎯 テスト完了: Flutter Web手動操作終了');
  });

  test('ネットワーク通信監視', async ({ page }) => {
    console.log('🎯 テスト開始: ネットワーク通信監視');
    
    // ネットワークリクエストを記録
    const requests = [];
    const responses = [];
    
    page.on('request', request => {
      requests.push({
        url: request.url(),
        method: request.method(),
        timestamp: new Date().toISOString()
      });
      console.log(`📤 Request: ${request.method()} ${request.url()}`);
    });
    
    page.on('response', response => {
      responses.push({
        url: response.url(),
        status: response.status(),
        timestamp: new Date().toISOString()
      });
      console.log(`📥 Response: ${response.status()} ${response.url()}`);
    });
    
    await page.goto('/');
    await page.waitForLoadState('networkidle');
    
    // 30秒間の通信を監視
    await page.waitForTimeout(30000);
    
    console.log(`📊 監視結果:`);
    console.log(`  - リクエスト数: ${requests.length}`);
    console.log(`  - レスポンス数: ${responses.length}`);
    
    // API呼び出しの分析
    const apiRequests = requests.filter(req => 
      req.url.includes('localhost:8081') || 
      req.url.includes('/api/') ||
      req.url.includes('firebase')
    );
    
    console.log(`🔍 API関連リクエスト: ${apiRequests.length}個`);
    apiRequests.forEach((req, index) => {
      console.log(`  ${index + 1}. ${req.method} ${req.url}`);
    });
    
    console.log('🎯 テスト完了: ネットワーク通信監視終了');
  });

  test('実際のユーザー操作シミュレーション', async ({ page }) => {
    console.log('🎯 テスト開始: 実ユーザー操作シミュレーション');
    
    await page.goto('/');
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(3000);
    
    console.log('👤 実際のユーザー行動をシミュレート');
    
    // 1. ページをスクロールして内容を確認（ユーザーの自然な行動）
    await page.mouse.wheel(0, 300);
    await page.waitForTimeout(1000);
    await page.mouse.wheel(0, -300);
    await page.waitForTimeout(1000);
    
    // 2. マウスを動かす（実際のユーザーのように）
    await page.mouse.move(400, 300);
    await page.waitForTimeout(500);
    await page.mouse.move(600, 400);
    await page.waitForTimeout(500);
    
    // 3. テキストエリア付近をクリック
    const viewport = page.viewportSize();
    const textAreaX = viewport.width * 0.5;
    const textAreaY = viewport.height * 0.6;
    
    await page.mouse.click(textAreaX, textAreaY);
    console.log('✅ テキストエリアクリック');
    
    // 4. 段階的にテキストを入力（実際のタイピングのように）
    const content = '今日は楽しい一日でした。';
    for (let i = 0; i < content.length; i++) {
      await page.keyboard.type(content[i]);
      await page.waitForTimeout(150 + Math.random() * 100); // 自然なタイピング間隔
    }
    
    console.log('✅ 自然なタイピング完了');
    
    // 5. 少し待ってから次の行を追加
    await page.waitForTimeout(2000);
    await page.keyboard.press('Enter');
    await page.keyboard.press('Enter');
    await page.keyboard.type('明日も頑張りましょう。');
    
    console.log('✅ 追加入力完了');
    
    // 6. 完了ボタンを探してクリック
    await page.waitForTimeout(1000);
    
    // Tab キーでナビゲーション（アクセシビリティの確認も兼ねる）
    await page.keyboard.press('Tab');
    await page.waitForTimeout(500);
    await page.keyboard.press('Tab');
    await page.waitForTimeout(500);
    
    // Enter キーでボタンを押す
    await page.keyboard.press('Enter');
    console.log('✅ Enterキーでアクション実行');
    
    await page.waitForTimeout(5000);
    
    // 最終スクリーンショット
    await page.screenshot({ path: 'test-results/user-simulation-final.png' });
    
    console.log('🎯 テスト完了: 実ユーザー操作シミュレーション終了');
  });
});