/**
 * UI要素デバッグテスト
 * 実際のFlutter WebアプリのUI要素を調査
 */

const { test, expect } = require('@playwright/test');

test.describe('UI要素デバッグ', () => {
  test('Flutter Webアプリの実際のUI要素を調査', async ({ page }) => {
    console.log('🎯 テスト開始: UI要素調査');

    // Flutter Webアプリにアクセス
    await page.goto('http://localhost:8080');
    
    // ページロード完了まで待機
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(3000); // Flutter初期化待機
    
    console.log('✅ ページロード完了');

    // ページタイトル確認
    const title = await page.title();
    console.log('📄 ページタイトル:', title);

    // ページ全体のHTML構造を確認
    const bodyHTML = await page.locator('body').innerHTML();
    console.log('📝 Body HTML長さ:', bodyHTML.length);

    // Flutter要素の存在確認
    const flutterView = await page.locator('flutter-view').count();
    console.log('🎯 flutter-view要素数:', flutterView);

    const canvasElements = await page.locator('canvas').count();
    console.log('🎨 canvas要素数:', canvasElements);

    // 可能なボタン要素を全て検索
    const allButtons = await page.locator('button, [role="button"], flt-semantics[role="button"]').count();
    console.log('🔘 ボタン要素総数:', allButtons);

    // テキスト要素を検索
    const textElements = await page.locator('text="新規作成"').count();
    console.log('📝 "新規作成"テキスト要素数:', textElements);

    const createElements = await page.locator('text="作成"').count();
    console.log('📝 "作成"テキスト要素数:', createElements);

    const newElements = await page.locator('text="新規"').count();
    console.log('📝 "新規"テキスト要素数:', newElements);

    // Flutter特有のセマンティクス要素を確認
    const semanticsElements = await page.locator('flt-semantics').count();
    console.log('🔍 flt-semantics要素数:', semanticsElements);

    // 実際にクリック可能な要素を探す
    const clickableElements = await page.locator('[role="button"], button, [onclick]').count();
    console.log('👆 クリック可能要素数:', clickableElements);

    // スクリーンショットを撮影
    await page.screenshot({ path: 'e2e/test_data/ui_debug_screenshot.png', fullPage: true });
    console.log('📸 スクリーンショット保存: e2e/test_data/ui_debug_screenshot.png');

    // ページのアクセシビリティツリーを確認
    try {
      const accessibilityTree = await page.accessibility.snapshot();
      console.log('♿ アクセシビリティツリー取得成功');
      
      // ボタン要素を探す
      function findButtons(node, path = '') {
        if (node.role === 'button') {
          console.log(`🔘 ボタン発見: ${path} - "${node.name || 'unnamed'}"`);
        }
        if (node.children) {
          node.children.forEach((child, index) => {
            findButtons(child, `${path}[${index}]`);
          });
        }
      }
      
      if (accessibilityTree) {
        findButtons(accessibilityTree);
      }
    } catch (e) {
      console.log('⚠️ アクセシビリティツリー取得エラー:', e.message);
    }

    console.log('🎉 UI要素調査完了');
  });

  test('エディタページ直接アクセステスト', async ({ page }) => {
    console.log('🎯 テスト開始: エディタページ直接アクセス');

    // エディタページに直接アクセスを試行
    const editorUrls = [
      'http://localhost:8080/#/editor',
      'http://localhost:8080/editor',
      'http://localhost:8080/#/create',
      'http://localhost:8080/create'
    ];

    for (const url of editorUrls) {
      try {
        console.log(`🔗 アクセス試行: ${url}`);
        await page.goto(url);
        await page.waitForLoadState('networkidle');
        await page.waitForTimeout(2000);

        const title = await page.title();
        console.log(`📄 ${url} - タイトル: ${title}`);

        // AI音声ボタンを探す
        const aiVoiceButton = await page.locator('text="AI音声"').count();
        console.log(`🎤 ${url} - AI音声ボタン数: ${aiVoiceButton}`);

        // iframe（Quillエディタ）を探す
        const iframes = await page.locator('iframe').count();
        console.log(`🖼️ ${url} - iframe数: ${iframes}`);

        if (aiVoiceButton > 0 || iframes > 0) {
          console.log(`✅ ${url} - エディタページ発見！`);
          break;
        }
      } catch (e) {
        console.log(`❌ ${url} - アクセスエラー: ${e.message}`);
      }
    }

    console.log('🎉 エディタページ直接アクセステスト完了');
  });

  test('Flutter Webルーティング調査', async ({ page }) => {
    console.log('🎯 テスト開始: Flutter Webルーティング調査');

    await page.goto('http://localhost:8080');
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(3000);

    // 現在のURL確認
    const currentUrl = page.url();
    console.log('🔗 現在のURL:', currentUrl);

    // ページ内のリンク要素を全て取得
    const links = await page.locator('a').count();
    console.log('🔗 リンク要素数:', links);

    // ナビゲーション要素を探す
    const navElements = await page.locator('nav, [role="navigation"]').count();
    console.log('🧭 ナビゲーション要素数:', navElements);

    // Flutter特有のルーティング要素を探す
    const routerElements = await page.locator('[data-route], [href]').count();
    console.log('🛣️ ルーティング要素数:', routerElements);

    // 実際にクリックしてみる（Flutter Webの場合、セマンティクス要素をクリック）
    try {
      const semanticsButtons = await page.locator('flt-semantics[role="button"]').all();
      console.log(`🔘 セマンティクスボタン数: ${semanticsButtons.length}`);
      
      for (let i = 0; i < Math.min(semanticsButtons.length, 5); i++) {
        const button = semanticsButtons[i];
        const text = await button.textContent();
        console.log(`🔘 ボタン${i}: "${text}"`);
      }
    } catch (e) {
      console.log('⚠️ セマンティクスボタン取得エラー:', e.message);
    }

    console.log('🎉 Flutter Webルーティング調査完了');
  });
}); 