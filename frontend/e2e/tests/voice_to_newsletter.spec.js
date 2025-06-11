/**
 * 音声入力→学級通信自動生成 E2Eテスト
 * 
 * テストフロー:
 * 1. エディタページにアクセス
 * 2. AI音声ボタンをクリック
 * 3. 音声ファイルをアップロード
 * 4. Gemini APIで学級通信生成
 * 5. エディタに自動挿入確認
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

test.describe('音声入力→学級通信自動生成フロー', () => {
  let audioFilePath;

  test.beforeAll(async () => {
    // テスト用音声ファイル作成
    audioFilePath = createTestAudioFile();
    console.log('テスト用音声ファイル作成:', audioFilePath);
  });

  test.beforeEach(async ({ page }) => {
    // Flutter Webアプリにアクセス
    await page.goto('http://localhost:8080');
    
    // ページロード完了まで待機
    await page.waitForLoadState('networkidle');
    
    // エディタページに移動
    await page.click('text=新規作成');
    await page.waitForLoadState('networkidle');
  });

  test('音声ファイルアップロード→文字起こし→学級通信生成', async ({ page }) => {
    console.log('🎯 テスト開始: 音声入力→学級通信自動生成');

    // Step 1: AI音声ボタンをクリック
    console.log('Step 1: AI音声ボタンをクリック');
    await page.click('button:has-text("AI音声")');
    
    // 音声入力ダイアログが表示されるまで待機
    await page.waitForSelector('.voice-input-dialog', { timeout: 5000 });
    console.log('✅ 音声入力ダイアログ表示確認');

    // Step 2: 音声ファイルをアップロード
    console.log('Step 2: 音声ファイルアップロード');
    const fileInput = page.locator('input[type="file"]');
    await fileInput.setInputFiles(audioFilePath);
    console.log('✅ 音声ファイルアップロード完了');

    // Step 3: アップロード処理開始確認
    await page.waitForSelector('.upload-progress', { timeout: 3000 });
    console.log('✅ アップロード進行状況表示確認');

    // Step 4: 文字起こし処理完了待機
    console.log('Step 4: 文字起こし処理待機...');
    await page.waitForSelector('.transcription-result', { timeout: 30000 });
    
    const transcriptionText = await page.textContent('.transcription-result');
    console.log('✅ 文字起こし結果:', transcriptionText);
    expect(transcriptionText).toBeTruthy();

    // Step 5: AI生成処理開始
    console.log('Step 5: AI学級通信生成処理開始');
    await page.waitForSelector('.ai-generation-progress', { timeout: 5000 });
    console.log('✅ AI生成進行状況表示確認');

    // Step 6: 生成結果表示確認
    console.log('Step 6: 生成結果待機...');
    await page.waitForSelector('.generated-content', { timeout: 60000 });
    
    const generatedContent = await page.textContent('.generated-content');
    console.log('✅ 生成された学級通信:', generatedContent.substring(0, 100) + '...');
    expect(generatedContent).toContain('学級通信');

    // Step 7: エディタに挿入
    console.log('Step 7: エディタに挿入');
    await page.click('button:has-text("エディタに挿入")');
    
    // ダイアログが閉じるまで待機
    await page.waitForSelector('.voice-input-dialog', { state: 'hidden', timeout: 5000 });
    console.log('✅ ダイアログ閉じる確認');

    // Step 8: エディタ内容確認
    console.log('Step 8: エディタ内容確認');
    await page.waitForTimeout(2000); // エディタ更新待機
    
    // Quill エディタ内のコンテンツを確認
    const editorContent = await page.evaluate(() => {
      const quillFrame = document.querySelector('iframe');
      if (quillFrame) {
        const quillDoc = quillFrame.contentDocument;
        const editorDiv = quillDoc.querySelector('.ql-editor');
        return editorDiv ? editorDiv.innerHTML : '';
      }
      return '';
    });
    
    console.log('✅ エディタ内容:', editorContent.substring(0, 200) + '...');
    expect(editorContent).toContain('学級通信');

    console.log('🎉 テスト完了: 音声入力→学級通信自動生成フロー成功！');
  });

  test('エラーハンドリング: 無効な音声ファイル', async ({ page }) => {
    console.log('🎯 テスト開始: 無効ファイルエラーハンドリング');

    // AI音声ボタンをクリック
    await page.click('button:has-text("AI音声")');
    await page.waitForSelector('.voice-input-dialog');

    // 無効なファイル（テキストファイル）をアップロード
    const invalidFilePath = path.join(__dirname, '../test_data/invalid.txt');
    fs.writeFileSync(invalidFilePath, 'これは音声ファイルではありません');
    
    const fileInput = page.locator('input[type="file"]');
    await fileInput.setInputFiles(invalidFilePath);

    // エラーメッセージ表示確認
    await page.waitForSelector('.error-message', { timeout: 5000 });
    const errorMessage = await page.textContent('.error-message');
    console.log('✅ エラーメッセージ:', errorMessage);
    expect(errorMessage).toContain('サポートされていない');

    console.log('🎉 エラーハンドリングテスト完了');
  });

  test('API接続確認: バックエンドサーバー疎通', async ({ page }) => {
    console.log('🎯 テスト開始: API接続確認');

    // バックエンドAPI直接テスト
    const response = await page.request.get('http://localhost:8081/api/v1/ai/formats');
    expect(response.status()).toBe(200);
    
    const formats = await response.json();
    console.log('✅ サポート音声フォーマット:', formats);
    expect(formats.supported_formats).toContain('wav');

    console.log('🎉 API接続確認完了');
  });

  test('季節検出機能: 春の学級通信生成', async ({ page }) => {
    console.log('🎯 テスト開始: 季節検出機能');

    // 春の内容を含むテキストで直接API呼び出し
    const springText = '今日は桜が咲いて、新学期が始まりました。子どもたちは元気に登校しています。';
    
    const response = await page.request.post('http://localhost:8081/api/v1/ai/generate-newsletter', {
      data: {
        transcribed_text: springText,
        template_type: 'daily_report'
      }
    });

    expect(response.status()).toBe(200);
    const result = await response.json();
    
    console.log('✅ 生成された春の学級通信:', result.generated_content.substring(0, 100) + '...');
    console.log('✅ 検出された季節:', result.detected_season);
    
    expect(result.detected_season).toBe('spring');
    expect(result.generated_content).toContain('桜');

    console.log('🎉 季節検出機能テスト完了');
  });

  test.afterAll(async () => {
    // テストファイル削除
    if (fs.existsSync(audioFilePath)) {
      fs.unlinkSync(audioFilePath);
    }
    console.log('🧹 テストファイル削除完了');
  });
}); 