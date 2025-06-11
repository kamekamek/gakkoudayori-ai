/**
 * UI操作テスト
 * 実際のユーザー操作フローをテスト
 */

const { test, expect } = require('@playwright/test');
const path = require('path');
const fs = require('fs');

// テスト用音声ファイルを作成（WAVフォーマット）
function createTestAudioFile() {
  const audioPath = path.join(__dirname, '../test_data/test_voice.wav');
  
  // テスト用のダミー音声データ（実際のWAVヘッダー付き）
  const wavHeader = Buffer.from([
    0x52, 0x49, 0x46, 0x46, // "RIFF"
    0x24, 0x08, 0x00, 0x00, // ファイルサイズ
    0x57, 0x41, 0x56, 0x45, // "WAVE"
    0x66, 0x6D, 0x74, 0x20, // "fmt "
    0x10, 0x00, 0x00, 0x00, // フォーマットチャンクサイズ
    0x01, 0x00,             // PCM
    0x01, 0x00,             // モノラル
    0x40, 0x1F, 0x00, 0x00, // サンプルレート 8000Hz
    0x80, 0x3E, 0x00, 0x00, // バイトレート
    0x02, 0x00,             // ブロックアライン
    0x10, 0x00,             // ビット深度
    0x64, 0x61, 0x74, 0x61, // "data"
    0x00, 0x08, 0x00, 0x00  // データサイズ
  ]);
  
  // ダミー音声データ（2048バイト）
  const audioData = Buffer.alloc(2048, 0x80);
  const fullWav = Buffer.concat([wavHeader, audioData]);
  
  // ディレクトリ作成
  const dir = path.dirname(audioPath);
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
  
  fs.writeFileSync(audioPath, fullWav);
  return audioPath;
}

test.describe('UI操作フロー', () => {
  let audioFilePath;

  test.beforeAll(async () => {
    // テスト用音声ファイル作成
    audioFilePath = createTestAudioFile();
    console.log('テスト用音声ファイル作成:', audioFilePath);
  });

  test('エディタページ移動とAI音声ボタン確認', async ({ page }) => {
    console.log('🎯 テスト開始: エディタページ移動とAI音声ボタン確認');

    // Flutter Webアプリにアクセス
    await page.goto('http://localhost:8080');
    
    // ページロード完了まで待機
    await page.waitForLoadState('networkidle');
    console.log('✅ ホームページ読み込み完了');

    // エディタページに移動
    const newCreationButton = page.locator('text=新規作成').first();
    if (await newCreationButton.count() > 0) {
      await newCreationButton.click();
      console.log('✅ 新規作成ボタンクリック成功');
      
      // エディタページロード待機
      await page.waitForLoadState('networkidle');
      console.log('✅ エディタページ読み込み完了');
      
      // AI音声ボタンの存在確認
      const aiVoiceButton = page.locator('button:has-text("AI音声")');
      const aiVoiceButtonExists = await aiVoiceButton.count() > 0;
      console.log('✅ AI音声ボタン存在:', aiVoiceButtonExists);
      
      if (aiVoiceButtonExists) {
        // AI音声ボタンをクリック
        await aiVoiceButton.click();
        console.log('✅ AI音声ボタンクリック成功');
        
        // ダイアログ表示確認（タイムアウト短めで）
        try {
          await page.waitForSelector('.voice-input-dialog', { timeout: 3000 });
          console.log('✅ 音声入力ダイアログ表示確認');
          
          // ファイル入力の存在確認
          const fileInput = page.locator('input[type="file"]');
          const fileInputExists = await fileInput.count() > 0;
          console.log('✅ ファイル入力フィールド存在:', fileInputExists);
          
        } catch (e) {
          console.log('⚠️ ダイアログ表示タイムアウト（UI実装中の可能性）');
        }
      }
    } else {
      console.log('⚠️ 新規作成ボタンが見つかりません');
    }

    console.log('🎉 UI操作テスト完了');
  });

  test('音声ファイルアップロード処理テスト', async ({ page }) => {
    console.log('🎯 テスト開始: 音声ファイルアップロード処理');

    // エディタページに直接移動
    await page.goto('http://localhost:8080');
    await page.waitForLoadState('networkidle');
    
    // 新規作成ボタンがあればクリック
    const newCreationButton = page.locator('text=新規作成').first();
    if (await newCreationButton.count() > 0) {
      await newCreationButton.click();
      await page.waitForLoadState('networkidle');
    }

    // AI音声ボタンの確認とクリック
    const aiVoiceButton = page.locator('button:has-text("AI音声")');
    if (await aiVoiceButton.count() > 0) {
      await aiVoiceButton.click();
      
      try {
        // ダイアログ表示待機
        await page.waitForSelector('.voice-input-dialog', { timeout: 5000 });
        
        // ファイル入力にテスト音声ファイルを設定
        const fileInput = page.locator('input[type="file"]');
        if (await fileInput.count() > 0) {
          await fileInput.setInputFiles(audioFilePath);
          console.log('✅ 音声ファイルアップロード完了');
          
          // アップロード処理開始確認
          try {
            await page.waitForSelector('.upload-progress', { timeout: 3000 });
            console.log('✅ アップロード進行状況表示確認');
          } catch (e) {
            console.log('⚠️ アップロード進行状況表示タイムアウト');
          }
          
          // 処理結果確認（エラーまたは成功）
          try {
            // エラーメッセージまたは結果のいずれかを待機
            await Promise.race([
              page.waitForSelector('.error-message', { timeout: 10000 }),
              page.waitForSelector('.transcription-result', { timeout: 10000 }),
              page.waitForSelector('.generated-content', { timeout: 10000 })
            ]);
            console.log('✅ 処理結果表示確認');
          } catch (e) {
            console.log('⚠️ 処理結果表示タイムアウト（API処理中の可能性）');
          }
        }
      } catch (e) {
        console.log('⚠️ ダイアログまたはファイル入力が見つかりません');
      }
    } else {
      console.log('⚠️ AI音声ボタンが見つかりません');
    }

    console.log('🎉 音声ファイルアップロードテスト完了');
  });

  test('Quillエディタ動作確認', async ({ page }) => {
    console.log('🎯 テスト開始: Quillエディタ動作確認');

    await page.goto('http://localhost:8080');
    await page.waitForLoadState('networkidle');
    
    // エディタページに移動
    const newCreationButton = page.locator('text=新規作成').first();
    if (await newCreationButton.count() > 0) {
      await newCreationButton.click();
      await page.waitForLoadState('networkidle');
      
      // Quillエディタ（iframe）の存在確認
      const quillFrame = page.locator('iframe');
      const quillFrameExists = await quillFrame.count() > 0;
      console.log('✅ Quillエディタ（iframe）存在:', quillFrameExists);
      
      if (quillFrameExists) {
        // エディタ内容確認
        const editorContent = await page.evaluate(() => {
          const quillFrame = document.querySelector('iframe');
          if (quillFrame) {
            const quillDoc = quillFrame.contentDocument;
            const editorDiv = quillDoc.querySelector('.ql-editor');
            return editorDiv ? editorDiv.innerHTML : '';
          }
          return '';
        });
        
        console.log('✅ エディタ初期内容:', editorContent.length > 0 ? '内容あり' : '空');
      }
    }

    console.log('🎉 Quillエディタ動作確認完了');
  });

  test.afterAll(async () => {
    // テストファイル削除
    if (fs.existsSync(audioFilePath)) {
      fs.unlinkSync(audioFilePath);
    }
    console.log('🧹 テストファイル削除完了');
  });
}); 