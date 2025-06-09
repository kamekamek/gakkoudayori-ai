# 📦 T1-FB-004-M: Cloud Storage設定手順書

**タスクID**: T1-FB-004-M  
**所要時間**: 20分  
**作業者**: 🔧 MANUAL  
**開始時刻**: 2025-06-10 00:17

---

## 🎯 完了条件
- [ ] Storage Bucket作成
- [ ] セキュリティルール設定
- [ ] CORS設定完了

---

## 📋 設定手順

### Step 1: Firebase Console へアクセス
1. [Firebase Console](https://console.firebase.google.com/) を開く
2. プロジェクト **yutori-kyoshitu-ai** を選択
3. 左メニューから **Storage** をクリック

### Step 2: Cloud Storage開始
1. **始める** ボタンをクリック
2. セキュリティルールの選択画面で **テストモードで開始** を選択
3. **次へ** をクリック

### Step 3: ロケーション設定
1. Cloud Storage ロケーション選択画面で以下を選択：
   - **asia-northeast1 (Tokyo)** を選択
2. **完了** をクリック

### Step 4: セキュリティルール設定
Storageルールタブで以下のルールを設定：

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // 認証済みユーザーのみ読み書き可能
    match /{allPaths=**} {
      allow read, write: if request.auth != null;
    }
    
    // 音声ファイル用（最大10MB）
    match /audio/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null 
                         && request.auth.uid == userId
                         && resource.size < 10 * 1024 * 1024;
    }
    
    // 画像ファイル用（最大5MB）
    match /images/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null 
                         && request.auth.uid == userId
                         && resource.size < 5 * 1024 * 1024;
    }
    
    // 学校だより用（最大2MB）
    match /newsletters/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null 
                         && request.auth.uid == userId
                         && resource.size < 2 * 1024 * 1024;
    }
  }
}
```

### Step 5: CORS設定（Firebase CLI使用）
Firebase CLIでCORS設定を行います：

1. ターミナルで以下を実行：
```bash
cd /Users/kamenonagare/yutori-firebase
```

2. CORS設定ファイル作成：
```bash
echo '[
  {
    "origin": ["http://localhost:3000", "https://yutori-kyoshitu-ai.web.app"],
    "method": ["GET", "POST", "PUT", "DELETE"],
    "maxAgeSeconds": 3600
  }
]' > storage-cors.json
```

3. CORS設定を適用：
```bash
gsutil cors set storage-cors.json gs://yutori-kyoshitu-ai.appspot.com
```

### Step 6: 設定確認
1. Firebase Console で Storage を確認
2. ルールが正しく設定されているか確認
3. バケット名を記録：`yutori-kyoshitu-ai.appspot.com`

---

## 📝 完了後の記録

### 成果物
- [ ] Storage Bucket: `yutori-kyoshitu-ai.appspot.com`
- [ ] セキュリティルール設定完了
- [ ] CORS設定完了
- [ ] storage-cors.json ファイル作成

### 設定情報
```
Bucket名: yutori-kyoshitu.firebasestorage.app
ロケーション: us-central1 (実際の設定)
ルール: 認証済みユーザーのみアクセス
CORS: localhost:3000, *.web.app, *.firebaseapp.com 対応
```

### Next Steps
完了後、以下のタスクが実行可能になります：
- **T1-FB-005-A**: Firebase SDK統合コード（AI・50分）

---

**設定開始時刻**: `開始時に記録`  
**設定完了時刻**: `完了時に記録`  
**実際の所要時間**: `計算して記録` 