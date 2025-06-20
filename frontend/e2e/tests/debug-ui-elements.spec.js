// @ts-check
const { test, expect } = require('@playwright/test');

/**
 * UI要素デバッグ用テスト
 * 実際のHTML構造を調査してテキスト入力エリアを特定する
 */

test.describe('UI要素の詳細調査', () => {
  
  test('HTML構造とDOM要素の完全調査', async ({ page }) => {
    console.log('🎯 テスト開始: HTML構造調査');
    
    await page.goto('/');
    await page.waitForLoadState('networkidle');
    
    // 1. 全てのHTML要素を取得
    console.log('📋 Step 1: 全HTML要素調査');
    
    const allElements = await page.evaluate(() => {
      const elements = [];
      
      // 全ての要素をトラバース
      function traverse(node, depth = 0) {
        if (node.nodeType === 1) { // Element node
          const info = {
            tagName: node.tagName,
            id: node.id || '',
            className: node.className || '',
            placeholder: node.placeholder || '',
            contentEditable: node.contentEditable || 'false',
            type: node.type || '',
            textContent: node.textContent ? node.textContent.substring(0, 50) : '',
            depth: depth
          };
          elements.push(info);
        }
        
        for (let child of node.childNodes) {
          traverse(child, depth + 1);
        }
      }
      
      traverse(document.body);
      return elements;
    });
    
    console.log(`📊 検出された要素数: ${allElements.length}`);
    
    // 入力関連要素を抽出
    const inputElements = allElements.filter(el => 
      el.tagName === 'INPUT' || 
      el.tagName === 'TEXTAREA' || 
      el.contentEditable === 'true' ||
      el.placeholder.includes('入力') ||
      el.textContent.includes('入力')
    );
    
    console.log(`📝 入力関連要素数: ${inputElements.length}`);
    inputElements.forEach((el, i) => {
      console.log(`  ${i + 1}. ${el.tagName} - id:"${el.id}" class:"${el.className}" placeholder:"${el.placeholder}" contentEditable:"${el.contentEditable}"`);
    });
    
    // 2. テキストエリア候補の特定
    console.log('🔍 Step 2: テキストエリア候補特定');
    
    // プレースホルダーテキストで検索
    const placeholderElements = await page.locator('[placeholder*="学級通信"]').all();
    console.log(`📍 プレースホルダー検索結果: ${placeholderElements.length}個`);
    
    for (let i = 0; i < placeholderElements.length; i++) {
      const el = placeholderElements[i];
      const tagName = await el.evaluate(node => node.tagName);
      const placeholder = await el.getAttribute('placeholder');
      const id = await el.getAttribute('id');
      const className = await el.getAttribute('class');
      
      console.log(`  候補${i + 1}: ${tagName} placeholder="${placeholder}" id="${id}" class="${className}"`);
    }
    
    // 3. contenteditable要素の検索
    console.log('📝 Step 3: contenteditable要素調査');
    
    const editableElements = await page.locator('[contenteditable]').all();
    console.log(`✏️ contenteditable要素数: ${editableElements.length}個`);
    
    for (let i = 0; i < editableElements.length; i++) {
      const el = editableElements[i];
      const tagName = await el.evaluate(node => node.tagName);
      const contentEditable = await el.getAttribute('contenteditable');
      const textContent = await el.textContent();
      
      console.log(`  編集可能${i + 1}: ${tagName} contenteditable="${contentEditable}" text="${textContent?.substring(0, 30)}"`);
    }
    
    // 4. 実際のクリック可能領域テスト
    console.log('🖱️ Step 4: クリック可能領域テスト');
    
    // プレースホルダーテキストが表示されている要素をクリック
    try {
      const textElement = page.locator('text="または、学級通信の内容をここに入力してください"');
      const count = await textElement.count();
      if (count > 0) {
        await textElement.click();
        console.log('✅ プレースホルダーテキストをクリック成功');
        
        // クリック後にアクティブになった要素を確認
        const activeElement = await page.evaluate(() => {
          const active = document.activeElement;
          return {
            tagName: active.tagName,
            id: active.id,
            className: active.className,
            contentEditable: active.contentEditable,
            placeholder: active.placeholder || ''
          };
        });
        
        console.log(`🎯 アクティブ要素: ${activeElement.tagName} id="${activeElement.id}" class="${activeElement.className}" contentEditable="${activeElement.contentEditable}"`);
      }
    } catch (error) {
      console.log(`⚠️ プレースホルダークリックエラー: ${error.message}`);
    }
    
    // 5. テキスト入力テスト
    console.log('⌨️ Step 5: テキスト入力テスト');
    
    try {
      // フォーカスされた要素に直接テキストを入力
      await page.keyboard.type('テスト入力');
      console.log('✅ キーボード入力成功');
      
      // 入力後の状態確認
      await page.waitForTimeout(1000);
      const pageContent = await page.textContent('body');
      if (pageContent.includes('テスト入力')) {
        console.log('✅ 入力テキストがページに反映されています');
      } else {
        console.log('⚠️ 入力テキストがページに見つかりません');
      }
    } catch (error) {
      console.log(`⚠️ テキスト入力エラー: ${error.message}`);
    }
    
    console.log('🎯 テスト完了: HTML構造調査終了');
  });

  test('実際のテキスト入力フロー検証', async ({ page }) => {
    console.log('🎯 テスト開始: 実際のテキスト入力フロー');
    
    await page.goto('/');
    await page.waitForLoadState('networkidle');
    
    // プレースホルダーテキストをクリックしてフォーカス
    const placeholderText = page.locator('text="または、学級通信の内容をここに入力してください"');
    const placeholderExists = await placeholderText.count() > 0;
    
    if (placeholderExists) {
      console.log('✅ プレースホルダーテキスト発見');
      
      // クリックしてフォーカス
      await placeholderText.click();
      console.log('✅ プレースホルダーをクリック');
      
      // テスト用コンテンツ入力
      const testContent = `
今日は楽しい学校生活でした。

【今日の出来事】
・算数の授業で新しい計算方法を学びました
・給食では皆で協力して配膳しました
・掃除の時間に教室をピカピカにしました

【明日の予定】
理科の実験があります。
みんなで観察しましょう。
      `.trim();
      
      await page.keyboard.type(testContent, { delay: 50 });
      console.log('✅ テストコンテンツ入力完了');
      
      // 入力確認
      await page.waitForTimeout(1000);
      const bodyContent = await page.textContent('body');
      const inputDetected = bodyContent.includes('今日は楽しい学校生活でした');
      
      console.log(`📝 入力内容検出: ${inputDetected}`);
      
      if (inputDetected) {
        console.log('✅ テキスト入力が正常に動作しています！');
        
        // 次のステップを探す
        const nextButtons = page.locator([
          'button',
          '[role="button"]',
          'text="次へ"',
          'text="生成"',
          'text="作成"'
        ].join(', '));
        
        const buttonCount = await nextButtons.count();
        console.log(`🔍 次ステップボタン検出数: ${buttonCount}`);
        
        if (buttonCount > 0) {
          // 最初のボタンをクリック
          await nextButtons.first().click();
          console.log('✅ 次ステップボタンをクリック');
          
          // 画面遷移を待機
          await page.waitForTimeout(3000);
          
          // 遷移後の状態確認
          const newContent = await page.textContent('body');
          console.log('📄 遷移後の画面状態:');
          console.log(newContent.substring(0, 200) + '...');
        }
      } else {
        console.log('❌ テキスト入力が検出されませんでした');
      }
    } else {
      console.log('❌ プレースホルダーテキストが見つかりません');
    }
    
    console.log('🎯 テスト完了: 実際のテキスト入力フロー検証終了');
  });
});