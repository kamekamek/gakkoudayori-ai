# Firebase Web SDK 設定ガイド

**最終更新**: 2025-06-10  
**作成者**: AI アシスタント

## 🎯 概要

このドキュメントでは、学校だよりAIアプリケーションにFirebase Web SDKを設定する方法を説明します。

## 📋 前提条件

- Firebase プロジェクトが作成済み（T1-FB-001-M完了）
- Firebase Authentication設定完了（T1-FB-002-M完了）

## 🔧 設定手順

### 1. Firebase設定ファイルの作成

`web/firebase-config.js.sample` をコピーして `web/firebase-config.js` を作成し、Firebase Consoleから取得した設定値を入力してください。

```javascript
// Firebase設定
const firebaseConfig = {
  apiKey: "YOUR_API_KEY",
  authDomain: "YOUR_AUTH_DOMAIN",
  projectId: "YOUR_PROJECT_ID",
  storageBucket: "YOUR_STORAGE_BUCKET",
  messagingSenderId: "YOUR_MESSAGING_SENDER_ID",
  appId: "YOUR_APP_ID"
};

// Firebase初期化
firebase.initializeApp(firebaseConfig);
```

### 2. Firebase Optionsの更新

`lib/firebase_options.dart` ファイル内の `web` オプションを実際のプロジェクト設定値に更新してください。

```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'YOUR_API_KEY',
  appId: 'YOUR_APP_ID',
  messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
  projectId: 'YOUR_PROJECT_ID',
  authDomain: 'YOUR_AUTH_DOMAIN',
  storageBucket: 'YOUR_STORAGE_BUCKET',
  measurementId: 'YOUR_MEASUREMENT_ID',
);
```

## 🧪 動作確認

1. 依存関係のインストール
```bash
flutter pub get
```

2. アプリケーションの実行
```bash
flutter run -d chrome
```

3. コンソールログでFirebaseの初期化が成功していることを確認

## 🔍 トラブルシューティング

### Firebase初期化エラー

コンソールに以下のようなエラーが表示される場合：

```
FirebaseError: Firebase: Error (auth/invalid-api-key)
```

- Firebase設定値が正しいか確認してください
- `firebase-config.js` と `firebase_options.dart` の両方を確認してください

### CORS エラー

```
Access to fetch at 'https://firestore.googleapis.com/...' has been blocked by CORS policy
```

- Firebase Consoleで適切なドメインが許可されているか確認してください
- ローカル開発の場合は `localhost` が許可されているか確認してください

## 📚 参考リンク

- [Firebase Web SDK ドキュメント](https://firebase.google.com/docs/web/setup)
- [FlutterFire ドキュメント](https://firebase.flutter.dev/docs/overview/)
