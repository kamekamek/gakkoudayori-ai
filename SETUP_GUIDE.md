# 🔧 学校だよりAI セットアップガイド

実装されたPDF保存機能とGoogle Classroom統合機能を動作させるための設定手順です。

## 📋 必要な設定一覧

### 1. Google Cloud Console設定（OAuth認証）

#### 1.1 プロジェクト作成・選択
1. [Google Cloud Console](https://console.cloud.google.com/) にアクセス
2. プロジェクトを作成または既存プロジェクトを選択

#### 1.2 API有効化
以下のAPIを有効化してください：
```
- Google Classroom API
- Google Drive API 
- Google Sign-In API
```

#### 1.3 OAuth 2.0認証情報の作成
1. `認証情報` → `認証情報を作成` → `OAuth 2.0 クライアント ID`
2. アプリケーションの種類: `ウェブアプリケーション`
3. 承認済みのJavaScript生成元に追加:
   ```
   http://localhost:5000 (開発用)
   https://yourdomain.com (本番用)
   ```
4. 承認済みのリダイレクトURIに追加:
   ```
   http://localhost:5000 (開発用)
   https://yourdomain.com (本番用)
   ```

#### 1.4 クライアントIDの取得
- 作成したクライアント認証情報からクライアントIDをコピー

### 2. Firebase設定

#### 2.1 firebase_options.dart の更新
`frontend/lib/firebase_options.dart` の以下の値を実際のFirebaseプロジェクトの値に置き換えてください：

```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'YOUR_ACTUAL_API_KEY',           // ← 実際のAPIキー
  appId: 'YOUR_ACTUAL_APP_ID',             // ← 実際のアプリID
  messagingSenderId: 'YOUR_SENDER_ID',     // ← 実際のSender ID
  projectId: 'your-project-id',            // ← 実際のプロジェクトID
  authDomain: 'your-project.firebaseapp.com',
  storageBucket: 'your-project.appspot.com',
  measurementId: 'G-XXXXXXXXXX',           // ← 実際のMeasurement ID
);
```

#### 2.2 Web用Firebase設定
`frontend/web/firebase-config.js.sample` をコピーして `firebase-config.js` を作成し、実際の値を設定してください：

```javascript
const firebaseConfig = {
  apiKey: "YOUR_ACTUAL_API_KEY",
  authDomain: "your-project.firebaseapp.com",
  projectId: "your-project-id",
  storageBucket: "your-project.appspot.com",
  messagingSenderId: "YOUR_SENDER_ID",
  appId: "YOUR_ACTUAL_APP_ID"
};
```

### 3. Google Sign-In設定

#### 3.1 web/index.html の更新
`frontend/web/index.html` にGoogle Sign-In用のmetaタグを追加：

```html
<meta name="google-signin-client_id" content="YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com">
```

### 4. バックエンド設定

#### 4.1 Python環境の準備
```bash
cd backend/app
python -m venv venv
source venv/bin/activate  # macOS/Linux
# または venv\Scripts\activate  # Windows
pip install -r requirements.txt
```

#### 4.2 環境変数の設定
`.env` ファイルを作成して以下を設定：
```env
GOOGLE_CLOUD_PROJECT=your-project-id
OPENAI_API_KEY=your-openai-key (必要な場合)
```

## 🚀 起動手順

### 1. バックエンド起動
```bash
cd backend/app
source venv/bin/activate
python main.py
# または
uvicorn main:app --reload --port 8081
```

### 2. フロントエンド起動
```bash
cd frontend
flutter run -d chrome --web-port=5000
```

## ✅ 動作確認手順

### Phase 1: 基本機能確認
1. ブラウザで `http://localhost:5000` にアクセス
2. アプリが正常に起動することを確認
3. サンプル学級通信を読み込み
4. PDFボタンでPDF保存が動作することを確認

### Phase 2: Google認証確認
1. Classroomボタンをクリック
2. Googleアカウントでログインできることを確認
3. 権限の承認画面が表示されることを確認

### Phase 3: Classroom機能確認
1. ログイン後、コース一覧が取得できることを確認
2. テスト投稿を作成
3. 投稿が正常に完了することを確認

## 🔧 トラブルシューティング

### よくある問題

#### 1. Firebase初期化エラー
```
Firebase: No Firebase App '[DEFAULT]' has been created
```
**解決策**: firebase_options.dartの値を確認し、Firebase.initializeApp()が呼ばれているか確認

#### 2. Google Sign-Inエラー
```
popup_closed_by_user
```
**解決策**: クライアントIDが正しく設定されているか確認、リダイレクトURIが登録されているか確認

#### 3. CORS エラー
```
Access to XMLHttpRequest has been blocked by CORS policy
```
**解決策**: バックエンドのCORS設定を確認、正しいオリジンが許可されているか確認

#### 4. PDF生成エラー
```
PDF generation failed: Network error
```
**解決策**: バックエンドサーバーが起動しているか確認、APIエンドポイントが正しいか確認

### デバッグ用コマンド

#### Flutter
```bash
# 分析実行
flutter analyze

# テスト実行
flutter test

# 依存関係の確認
flutter doctor
```

#### バックエンド
```bash
# 健康状態チェック
curl http://localhost:8081/health

# PDF生成テスト
curl -X POST http://localhost:8081/api/v1/pdf/generate \
  -H "Content-Type: application/json" \
  -d '{"html_content": "<h1>Test</h1>", "title": "Test PDF"}'
```

## 📚 参考リンク

- [Firebase Setup](https://firebase.google.com/docs/flutter/setup)
- [Google Sign-In Setup](https://pub.dev/packages/google_sign_in)
- [Google Classroom API](https://developers.google.com/classroom/reference/rest)
- [Google Drive API](https://developers.google.com/drive/api/guides/about-sdk)

## 🔒 セキュリティ注意事項

1. **APIキーの管理**: 
   - 本番環境では環境変数を使用
   - GitHubにAPIキーをコミットしない

2. **OAuth設定**: 
   - 本番環境では適切なドメインのみ許可
   - 不要な権限は要求しない

3. **Firebase Security Rules**: 
   - 適切なFirestoreセキュリティルールを設定
   - Cloud Storageのアクセス制御を確認

---

これらの設定を完了すると、PDF保存とGoogle Classroom投稿機能が動作するようになります。