# 🚀 緊急：Firebase認証設定（今すぐ実行）

## 📋 **5分で完了する設定手順**

### 1. Firebase Console を開く
```
https://console.firebase.google.com/project/yutori-kyoshitu
```

### 2. Authentication を有効化
1. 左メニュー → **Authentication**
2. **Get started** をクリック

### 3. Google Sign-in を有効化
1. **Sign-in method** タブ
2. **Google** をクリック
3. **Enable** トグルを **ON** にする
4. **Project support email** を選択
5. **Save** をクリック

### 4. Web Client ID をコピー
1. **Sign-in method** → **Google** → **Edit**
2. **Web SDK configuration** セクション
3. **Web client ID** をコピー（例：`309920383305-xxxxx.apps.googleusercontent.com`）

### 5. Client ID を設定
```bash
# frontend/web/index.html の22行目を編集
<meta name="google-signin-client_id" content="【コピーしたClient ID】">
```

### 6. 認証ドメインを追加
1. **Authentication** → **Settings** → **Authorized domains**
2. **Add domain** をクリック
3. `localhost` を追加

### 7. Google Cloud Console で認証元を設定
```
https://console.cloud.google.com/apis/credentials?project=yutori-kyoshitu
```
1. OAuth 2.0 Client ID をクリック
2. **Authorized JavaScript origins** に追加：
   - `http://localhost:8080`
   - `http://localhost:3000`
   - `https://localhost:8080`

## 🧪 **テスト実行**

```bash
cd frontend
flutter run -d chrome --web-port=8080
```

**期待結果：**
- Google認証画面が表示される
- ログイン後、ユーザー情報が表示される

## 🚨 **トラブルシューティング**

### Error 400: redirect_uri_mismatch
→ Google Cloud Console の Authorized JavaScript origins をチェック

### Error 403: access_blocked  
→ OAuth consent screen の設定が必要

### Authentication fails silently
→ Chrome DevTools の Console タブでエラーを確認

## ✅ **設定完了チェックリスト**

- [ ] Firebase Authentication 有効化済み
- [ ] Google Sign-in プロバイダー有効化済み
- [ ] Web Client ID 取得済み
- [ ] index.html の Client ID 更新済み
- [ ] localhost ドメイン認証済み
- [ ] Google Cloud Console 設定済み
- [ ] テスト実行でログイン成功 