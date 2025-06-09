// @ts-check
const { defineConfig, devices } = require('@playwright/test');

/**
 * @see https://playwright.dev/docs/test-configuration
 */
module.exports = defineConfig({
  testDir: './tests',
  /* テスト実行の最大時間 */
  timeout: 30 * 1000,
  expect: {
    /**
     * アサーションのタイムアウト
     */
    timeout: 5000
  },
  /* 失敗したテストのレポート */
  reporter: 'html',
  /* 並列実行の設定 */
  fullyParallel: true,
  /* 再試行回数 */
  retries: process.env.CI ? 2 : 0,
  /* テストワーカーの数 */
  workers: process.env.CI ? 1 : undefined,
  /* テスト実行前の準備 */
  use: {
    /* ベースURL */
    baseURL: 'http://localhost:8080',
    /* すべてのテストでトレースを取得 */
    trace: 'on-first-retry',
    /* スクリーンショットを取得 */
    screenshot: 'only-on-failure',
  },

  /* テスト実行環境の設定 */
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
    {
      name: 'firefox',
      use: { ...devices['Desktop Firefox'] },
    },
    {
      name: 'webkit',
      use: { ...devices['Desktop Safari'] },
    },
    /* モバイルビューポートのテスト */
    {
      name: 'Mobile Chrome',
      use: { ...devices['Pixel 5'] },
    },
    {
      name: 'Mobile Safari',
      use: { ...devices['iPhone 12'] },
    },
  ],

  /* Webサーバーの設定 */
  webServer: {
    command: 'cd .. && flutter run -d chrome --web-port=8080 --web-renderer=html',
    port: 8080,
    reuseExistingServer: !process.env.CI,
    timeout: 120 * 1000,
  },
});
