# 🚀 緊急：Firebase認証設定（今すぐ実行）

## 📋 **10分で完了する設定手順**

### ステップ1: Google People API を有効化 (最重要!)
```
https://console.cloud.google.com/apis/api/people.googleapis.com/overview?project=yutori-kyoshitu
```

1. **ENABLE** ボタンをクリック
2. API有効化完了まで **2-3分待機**

### ステップ2: Firebase Console を開く
```
https://console.firebase.google.com/project/yutori-kyoshitu
```

### ステップ3: Authentication を有効化
1. 左メニュー → **Authentication**
2. **Get started** をクリック

### ステップ4: Email/Password を有効化
1. **Sign-in method** タブ
2. **Email/Password** をクリック
3. **Enable** トグルを **ON** にする
4. **Save** をクリック

### ステップ5: Google Sign-in を有効化
1. **Sign-in method** タブ
2. **Google** をクリック
3. **Enable** トグルを **ON** にする
4. **Project support email** を選択
5. **Save** をクリック

### ステップ6: Web Client ID をコピー
1. **Sign-in method** → **Google** → **Edit**
2. **Web SDK configuration** セクション
3. **Web client ID** をコピー（例：`309920383305-xxxxx.apps.googleusercontent.com`）

### ステップ7: 認証ドメインを追加
1. **Authentication** → **Settings** → **Authorized domains**
2. **Add domain** をクリック
3. `localhost` を追加

### ステップ8: Google Cloud Console で認証元を設定
```
https://console.cloud.google.com/apis/credentials?project=yutori-kyoshitu
```
1. OAuth 2.0 Client ID をクリック
2. **Authorized JavaScript origins** に追加：
   - `http://localhost:60054`
   - `http://localhost:3000`
   - `https://localhost:8080`

## 🧪 **テスト実行**

```bash
cd frontend
flutter run -d chrome --web-port=60054
```

**期待結果：**
- People API エラーが解消
- メール認証が正常動作
- Google認証画面が表示される
- ログイン後、ユーザー情報が表示される

## 🚨 **トラブルシューティング**

### People API エラー (Error 403)
→ **Step 1のPeople API有効化が最重要**

### Error 400: redirect_uri_mismatch
→ Google Cloud Console の Authorized JavaScript origins をチェック

### Error 403: access_blocked  
→ OAuth consent screen の設定が必要

### Authentication fails silently
→ Chrome DevTools の Console タブでエラーを確認

## ✅ **設定完了チェックリスト**

- [ ] **Google People API 有効化済み** ← **最重要**
- [ ] Firebase Authentication 有効化済み
- [ ] Email/Password プロバイダー有効化済み
- [ ] Google Sign-in プロバイダー有効化済み
- [ ] Web Client ID 取得済み
- [ ] index.html の Client ID 更新済み
- [ ] localhost ドメイン認証済み
- [ ] Google Cloud Console 設定済み
- [ ] **API有効化後2-3分待機済み**
- [ ] テスト実行でログイン成功 