# 🔧 Firebase Google認証設定手順

## 1. Firebase Console設定

### Authentication有効化
1. [Firebase Console](https://console.firebase.google.com) → `yutori-kyoshitu` プロジェクト
2. 左メニュー → **Authentication**
3. **Get started** ボタンクリック

### Google Sign-in有効化
1. **Sign-in method** タブ
2. **Google** プロバイダーを選択
3. **Enable** トグルをON
4. **Project support email** を選択
5. **Save** ボタンクリック

### Web OAuth Client ID取得
1. Firebase Console → **Project settings** (歯車アイコン)
2. **General** タブ → **Your apps** セクション
3. Web app `yutori-kyoshitu-app` の設定を確認
4. **Web API Key** と **OAuth 2.0 Client ID** をコピー

## 2. 必要なClient ID設定

### frontend/web/index.html の修正
```html
<!-- この部分を実際のClient IDに置き換え -->
<meta name="google-signin-client_id" content="309920383305-[実際のclient_id].apps.googleusercontent.com">
```

### 取得方法
1. Firebase Console → **Authentication** → **Sign-in method** 
2. **Google** プロバイダー設定画面
3. **Web SDK configuration** セクションの **Web client ID** をコピー

## 3. 開発環境設定

### 許可ドメイン設定
1. Firebase Console → **Authentication** → **Settings** → **Authorized domains**
2. 以下を追加:
   - `localhost` (開発用)
   - `yutori-kyoshitu.firebaseapp.com` (本番用)

### Google Cloud Console設定
1. [Google Cloud Console](https://console.cloud.google.com)
2. プロジェクト `yutori-kyoshitu` を選択
3. **APIs & Services** → **Credentials**
4. OAuth 2.0 Client ID の設定で **Authorized JavaScript origins** に追加:
   - `http://localhost:8080`
   - `http://localhost:3000` 
   - `https://localhost:8080`

## 4. テスト手順

### ローカル開発サーバー起動
```bash
cd frontend
flutter run -d chrome --web-port=8080
```

### 動作確認
1. ブラウザで `http://localhost:8080` にアクセス
2. **Googleでサインイン** ボタンをクリック
3. Google認証画面が表示されることを確認
4. 認証後、アプリに戻ってユーザー情報が表示されることを確認

## 5. トラブルシューティング

### よくあるエラー
- **Error 400: redirect_uri_mismatch**
  → Google Cloud ConsoleでAuthorized JavaScript originsを設定
  
- **Error 403: access_blocked**
  → OAuth consent screenの設定が必要
  
- **Firebase Auth Error: auth/invalid-api-key**
  → firebase_options.dartのAPIキーを確認

### デバッグ方法
```bash
# Flutter側のログ確認
flutter logs

# Chrome DevTools確認
# F12 → Console → Networkタブで認証リクエストを確認
```

## 6. セキュリティ考慮事項

### 本番環境設定
- API キーの環境変数化
- CORS設定の最適化
- Authorized domainsの限定

### OAuth scope設定
```dart
// lib/providers/auth_provider.dart で必要なscopeのみ設定
final GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: [
    'email',
    'profile',
    // 必要最小限のscopeのみ追加
  ],
);
```

## 🚀 Next Steps

1. ✅ Firebase Console でGoogle認証を有効化
2. ✅ 実際のClient IDを取得・設定
3. ⏳ ローカル環境でのテスト実行
4. ⏳ 認証フローの動作確認
5. ⏳ エラーハンドリングの改善 