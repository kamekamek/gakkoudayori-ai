# データベース詳細設計書

**カテゴリ**: DESIGN | **レイヤー**: DETAIL | **更新**: 2025-01-09  
**担当**: 亀ちゃん | **依存**: 01_REQUIREMENT_overview.md | **タグ**: #database #firestore #schema

## 🎯 TL;DR（30秒で読める要約）

- **目的**: Firestore/Storage完全スキーマとセキュリティルール設計
- **対象**: バックエンド開発者、データベース担当者  
- **成果物**: コレクション構造、インデックス、セキュリティルール
- **次のアクション**: データベース構築・デプロイ

## 🔗 関連ドキュメント

| 種別 | ファイル名 | 関係性 |
|------|-----------|--------|
| 依存 | 01_REQUIREMENT_overview.md | 要件定義 |
| 関連 | 30_API_endpoints.md | API設計 |
| 派生 | firestore.rules | セキュリティルール |

## 📊 メタデータ

- **複雑度**: High
- **推定読了時間**: 15分
- **更新頻度**: 中

---

## 1. Firestoreデータベース設計

### 1.1 全体コレクション構造

```
yutori-kyoshitsu (Project)
├── users (Collection)
│   └── {userId} (Document)
│       ├── profile (subcollection)
│       ├── settings (subcollection)
│       └── usage_stats (subcollection)
├── documents (Collection)
│   └── {documentId} (Document)
│       ├── versions (subcollection)
│       └── ai_metadata (subcollection)
├── templates (Collection)
│   └── {templateId} (Document)
├── ai_requests (Collection)
│   └── {requestId} (Document)
└── system (Collection)
    └── config (Document)
```

### 1.2 詳細スキーマ定義

#### 1.2.1 users コレクション

```typescript
// users/{userId}
interface UserDocument {
  // 基本情報
  uid: string;                    // Firebase Auth UID
  email: string;                  // メールアドレス
  display_name: string;           // 表示名
  
  // 学校情報
  school_name: string;            // 学校名
  class_name: string;             // クラス名（例：3年1組）
  grade: number;                  // 学年（1-6）
  
  // システム情報
  created_at: Timestamp;          // 作成日時
  updated_at: Timestamp;          // 更新日時
  last_login_at: Timestamp;       // 最終ログイン
  
  // ユーザー設定
  settings: {
    default_season: "spring" | "summer" | "autumn" | "winter";
    auto_save_interval: number;   // 自動保存間隔（秒）
    ai_assistance_level: "basic" | "advanced";
    notification_enabled: boolean;
  };
  
  // 利用状況
  usage_stats: {
    documents_created: number;
    ai_generations_used: number;
    pdfs_generated: number;
    storage_used_mb: number;
  };
  
  // サブスクリプション
  subscription: {
    plan: "free" | "premium" | "school";
    expires_at: Timestamp | null;
    features: string[];           // 利用可能機能一覧
  };
}
```

#### 1.2.2 documents コレクション

```typescript
// documents/{documentId}
interface DocumentDocument {
  // 基本情報
  id: string;                     // ドキュメントID
  title: string;                  // タイトル
  status: "draft" | "published" | "archived";
  
  // ユーザー情報
  author_uid: string;             // 作成者UID
  author_name: string;            // 作成者名
  
  // コンテンツ
  html_content: string;           // HTML形式コンテンツ
  delta_json: string;             // Quill Delta JSON
  preview_text: string;           // プレビュー用テキスト（最初の100文字）
  word_count: number;             // 文字数
  
  // メタデータ
  season_theme: "spring" | "summer" | "autumn" | "winter";
  document_type: "class_newsletter" | "event_notice" | "homework_memo";
  tags: string[];                 // タグ一覧
  
  // タイムスタンプ
  created_at: Timestamp;
  updated_at: Timestamp;
  published_at: Timestamp | null;
  
  // AI関連
  ai_metadata: {
    generated_by_ai: boolean;
    model_version: string;        // "gemini-2.5-pro-preview-03-25"
    generation_time_ms: number;
    confidence_score: number;     // 0.0-1.0
    original_transcript: string;  // 元の音声文字起こし
  };
  
  // 共有・配信
  sharing: {
    is_public: boolean;
    shared_with: string[];        // 共有先UID一覧
    drive_file_id: string | null;
    classroom_post_id: string | null;
  };
  
  // バージョン管理
  version: number;                // バージョン番号
  parent_document_id: string | null; // 複製元文書ID
}
```

#### 1.2.3 documents/{documentId}/versions サブコレクション

```typescript
// documents/{documentId}/versions/{versionId}
interface DocumentVersion {
  version: number;
  html_content: string;
  delta_json: string;
  created_at: Timestamp;
  created_by: string;             // UID
  change_summary: string;         // 変更概要
  change_type: "auto_save" | "manual_save" | "ai_generation";
}
```

#### 1.2.4 ai_requests コレクション

```typescript
// ai_requests/{requestId}
interface AIRequestDocument {
  // リクエスト情報
  id: string;
  user_uid: string;
  request_type: "transcribe" | "generate_html" | "assist";
  
  // 入力データ
  input_data: {
    transcript?: string;          // 文字起こし結果
    selected_text?: string;       // 選択テキスト
    instruction?: string;         // カスタム指示
    season_theme?: string;
    constraints?: {
      allowed_tags: string[];
      max_word_count: number;
    };
  };
  
  // 出力データ
  output_data: {
    html_content?: string;
    delta_json?: string;
    suggestions?: Array<{
      text: string;
      confidence: number;
      explanation: string;
    }>;
  };
  
  // メタデータ
  processing_time_ms: number;
  model_used: string;
  confidence_score: number;
  tokens_used: number;            // API使用量
  
  // タイムスタンプ
  created_at: Timestamp;
  completed_at: Timestamp | null;
  
  // ステータス
  status: "pending" | "processing" | "completed" | "failed";
  error_message: string | null;
}
```

#### 1.2.5 templates コレクション

```typescript
// templates/{templateId}
interface TemplateDocument {
  id: string;
  title: string;
  description: string;
  category: "newsletter" | "notice" | "homework" | "event";
  
  // テンプレート内容
  html_template: string;          // HTMLテンプレート
  delta_template: string;         // Deltaテンプレート
  placeholder_instructions: {     // プレースホルダー説明
    [key: string]: string;
  };
  
  // メタデータ
  created_by: "system" | string;  // システム or ユーザーUID
  is_public: boolean;
  usage_count: number;
  season_theme: string;
  
  created_at: Timestamp;
  updated_at: Timestamp;
}
```

---

## 2. Cloud Storage設計

### 2.1 バケット構造

```
gs://yutori-storage-prod/
├── users/
│   └── {userId}/
│       ├── profile_images/
│       ├── audio_files/
│       └── exports/
├── documents/
│   └── {documentId}/
│       ├── generated_pdfs/
│       ├── images/
│       └── attachments/
├── templates/
│   └── assets/
│       ├── images/
│       └── css/
└── system/
    ├── backups/
    └── logs/
```

### 2.2 ファイル命名規則

| ファイル種別 | パス例 | 説明 |
|-------------|-------|------|
| 音声ファイル | `users/{uid}/audio_files/{timestamp}.wav` | 音声記録 |
| PDF出力 | `documents/{docId}/generated_pdfs/{timestamp}.pdf` | 生成PDF |
| 画像 | `documents/{docId}/images/{imageId}.{ext}` | 挿入画像 |
| プロフィール画像 | `users/{uid}/profile_images/avatar.jpg` | ユーザー画像 |

### 2.3 ストレージセキュリティルール

```javascript
// storage.rules
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // ユーザーファイルアクセス制御
    match /users/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // ドキュメントファイル制御
    match /documents/{documentId}/{allPaths=**} {
      allow read: if request.auth != null && 
        (resource.metadata.ownerUid == request.auth.uid ||
         resource.metadata.isPublic == "true");
      allow write: if request.auth != null && 
        resource.metadata.ownerUid == request.auth.uid;
    }
    
    // テンプレートアセット（読み取り専用）
    match /templates/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if false; // 管理者のみ
    }
  }
}
```

---

## 3. Firestoreセキュリティルール

### 3.1 基本セキュリティルール

```javascript
// firestore.rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // ユーザーコレクション
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // サブコレクション
      match /{subcollection=**} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
    
    // ドキュメントコレクション
    match /documents/{documentId} {
      // 読み取り権限
      allow read: if request.auth != null && 
        (resource.data.author_uid == request.auth.uid ||
         resource.data.sharing.is_public == true ||
         request.auth.uid in resource.data.sharing.shared_with);
      
      // 書き込み権限（所有者のみ）
      allow create: if request.auth != null && 
        request.resource.data.author_uid == request.auth.uid;
      allow update: if request.auth != null && 
        resource.data.author_uid == request.auth.uid;
      allow delete: if request.auth != null && 
        resource.data.author_uid == request.auth.uid;
      
      // バージョン履歴
      match /versions/{versionId} {
        allow read, create: if request.auth != null && 
          get(/databases/$(database)/documents/documents/$(documentId)).data.author_uid == request.auth.uid;
      }
    }
    
    // AI リクエスト
    match /ai_requests/{requestId} {
      allow read, write: if request.auth != null && 
        resource.data.user_uid == request.auth.uid;
    }
    
    // テンプレート（読み取り専用）
    match /templates/{templateId} {
      allow read: if request.auth != null;
      allow write: if false; // 管理者権限が必要
    }
    
    // システム設定（読み取り専用）
    match /system/config {
      allow read: if request.auth != null;
      allow write: if false;
    }
  }
}
```

### 3.2 高度なセキュリティ関数

```javascript
// セキュリティヘルパー関数
function isOwner(userId) {
  return request.auth != null && request.auth.uid == userId;
}

function isSharedWith(documentData) {
  return request.auth.uid in documentData.sharing.shared_with;
}

function isValidDocumentUpdate() {
  return request.resource.data.author_uid == resource.data.author_uid &&
         request.resource.data.created_at == resource.data.created_at;
}

function hasValidSubscription() {
  let userDoc = get(/databases/$(database)/documents/users/$(request.auth.uid));
  return userDoc.data.subscription.plan != "free" ||
         userDoc.data.usage_stats.documents_created < 10;
}
```

---

## 4. インデックス設計

### 4.1 Composite Indexes

```yaml
# firestore.indexes.json
{
  "indexes": [
    {
      "collectionGroup": "documents",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "author_uid", "order": "ASCENDING"},
        {"fieldPath": "status", "order": "ASCENDING"},
        {"fieldPath": "updated_at", "order": "DESCENDING"}
      ]
    },
    {
      "collectionGroup": "documents", 
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "author_uid", "order": "ASCENDING"},
        {"fieldPath": "season_theme", "order": "ASCENDING"},
        {"fieldPath": "created_at", "order": "DESCENDING"}
      ]
    },
    {
      "collectionGroup": "documents",
      "queryScope": "COLLECTION", 
      "fields": [
        {"fieldPath": "sharing.is_public", "order": "ASCENDING"},
        {"fieldPath": "created_at", "order": "DESCENDING"}
      ]
    },
    {
      "collectionGroup": "ai_requests",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "user_uid", "order": "ASCENDING"},
        {"fieldPath": "request_type", "order": "ASCENDING"},
        {"fieldPath": "created_at", "order": "DESCENDING"}
      ]
    }
  ]
}
```

### 4.2 Single Field Indexes

自動作成されるインデックス：
- `documents.title` (text search用)
- `documents.tags` (array-contains用)
- `users.email` (unique constraint用)
- `ai_requests.status` (filter用)

---

## 5. データ移行・初期化

### 5.1 初期システムデータ

```typescript
// system/config 初期データ
const systemConfig = {
  app_version: "1.0.0",
  maintenance_mode: false,
  ai_models: {
    current_version: "gemini-2.5-pro-preview-03-25",
    fallback_version: "gemini-1.0-pro"
  },
  rate_limits: {
    ai_requests_per_minute: 20,
    ai_requests_per_hour: 100,
    pdf_generations_per_hour: 30
  },
  feature_flags: {
    voice_transcription: true,
    advanced_ai_assist: true,
    google_classroom_integration: true
  }
};
```

### 5.2 デフォルトテンプレート

```typescript
// templates 初期データ
const defaultTemplates = [
  {
    id: "newsletter_basic",
    title: "基本学級通信テンプレート",
    category: "newsletter",
    html_template: `
      <h1>{{class_name}} 学級通信 第{{issue_number}}号</h1>
      <p>{{greeting}}</p>
      <h2>今週の出来事</h2>
      <p>{{this_week_events}}</p>
      <h2>来週の予定</h2>
      <ul>{{next_week_schedule}}</ul>
      <p>{{closing}}</p>
    `,
    placeholder_instructions: {
      "class_name": "クラス名（例：3年1組）",
      "issue_number": "通信の号数",
      "greeting": "保護者向けの挨拶文",
      "this_week_events": "今週の主な出来事",
      "next_week_schedule": "来週の予定一覧",
      "closing": "締めの挨拶"
    },
    season_theme: "spring",
    is_public: true,
    created_by: "system"
  }
];
```

---

## 6. バックアップ・災害復旧

### 6.1 自動バックアップ設定

```bash
# Cloud Scheduler設定
gcloud scheduler jobs create pubsub firestore-backup \
  --schedule="0 2 * * *" \
  --topic=firestore-backup \
  --message-body='{"collections": ["users", "documents", "templates"]}'
```

### 6.2 Point-in-time Recovery

```typescript
// バックアップ復元用クエリ
const restoreDocument = async (documentId: string, timestamp: Date) => {
  const versions = await firestore
    .collection('documents')
    .doc(documentId)
    .collection('versions')
    .where('created_at', '<=', timestamp)
    .orderBy('created_at', 'desc')
    .limit(1)
    .get();
    
  if (!versions.empty) {
    const latestVersion = versions.docs[0].data();
    return latestVersion;
  }
  return null;
};
```

---

## 7. パフォーマンス最適化

### 7.1 読み込み最適化

- **ページネーション**: 20件ずつ取得
- **キャッシュ戦略**: 頻繁アクセスデータは5分キャッシュ
- **遅延読み込み**: 大きなHTMLコンテンツは必要時のみ取得

### 7.2 書き込み最適化

- **バッチ処理**: 複数更新は transaction で実行
- **非同期処理**: AI処理結果は別途更新
- **重複削除**: 同一内容の自動保存は統合

### 7.3 ストレージ最適化

```typescript
// 古いファイル自動削除（30日後）
const cleanupOldFiles = async () => {
  const thirtyDaysAgo = new Date();
  thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
  
  const oldRequests = await firestore
    .collection('ai_requests')
    .where('created_at', '<', thirtyDaysAgo)
    .where('status', '==', 'completed')
    .get();
    
  const batch = firestore.batch();
  oldRequests.docs.forEach(doc => {
    batch.delete(doc.ref);
  });
  
  await batch.commit();
};
```

このデータベース設計により、要件書で求められる高度な学級通信AI機能を支える堅牢なデータ基盤が構築できます。 