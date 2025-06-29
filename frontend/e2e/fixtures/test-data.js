// テストデータの定義
export const testData = {
  // サンプル学級通信データ
  newsletter: {
    title: '1年A組 学級通信',
    date: '2024年12月28日',
    content: 'これはテスト用の学級通信の内容です。',
    events: [
      '12月30日 冬休み開始',
      '1月8日 3学期開始式'
    ]
  },

  // テスト用チャットメッセージ
  chatMessages: [
    'こんにちは',
    '今日の出来事を学級通信にまとめてください',
    '運動会の準備について書いてください'
  ],

  // テスト用画像データ
  images: {
    sample: '/assets/images/sample.jpg',
    logo: '/assets/images/logo.png'
  },

  // APIレスポンスのモック
  mockResponses: {
    adkChat: {
      success: {
        type: 'assistant',
        content: 'AIが生成した返答です。',
        html: '<h2>生成された学級通信</h2><p>内容がここに入ります。</p>'
      },
      error: {
        type: 'error',
        content: 'エラーが発生しました。'
      }
    }
  }
};