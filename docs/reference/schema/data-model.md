# データモデル仕様

学校だよりAIのFirestoreデータベーススキーマとデータモデルの詳細仕様です。

## 🗄️ データベース構造概要

### コレクション階層

```
firestore/
├── users/                    # ユーザー情報
│   └── {userId}/
│       ├── profile          # プロフィール
│       ├── settings         # 設定
│       └── dictionary/      # ユーザー辞書
│           └── {wordId}/
├── documents/               # ドキュメント
│   └── {documentId}/
│       ├── metadata         # メタデータ
│       ├── content          # コンテンツ
│       ├── versions/        # バージョン履歴
│       │   └── {versionId}/
│       └── shares/          # 共有情報
│           └── {shareId}/
├── templates/               # テンプレート
│   └── {templateId}/
├── schools/                 # 学校情報
│   └── {schoolId}/
└── system/                  # システム設定
    ├── prompts/            # AIプロンプト
    └── config/             # 設定値
```

## 👤 ユーザーデータ

### users コレクション

```typescript
interface User {
  // 基本情報
  userId: string;              // Firebase Auth UID
  email: string;               // メールアドレス
  displayName: string;         // 表示名
  photoURL?: string;           // プロフィール画像URL
  
  // プロフィール情報
  profile: {
    schoolId?: string;         // 所属学校ID
    schoolName?: string;       // 学校名
    grade?: string;            // 担当学年
    className?: string;        // クラス名
    role: UserRole;            // 役割
    introduction?: string;     // 自己紹介
  };
  
  // 統計情報
  stats: {
    documentsCreated: number;  // 作成ドキュメント数
    totalWords: number;        // 総文字数
    lastActiveAt: Timestamp;   // 最終アクティブ日時
  };
  
  // システム情報
  createdAt: Timestamp;        // 作成日時
  updatedAt: Timestamp;        // 更新日時
  isActive: boolean;           // アクティブフラグ
  subscription?: {             // サブスクリプション情報
    plan: 'free' | 'pro' | 'school';
    expiresAt?: Timestamp;
  };
}

enum UserRole {
  TEACHER = 'teacher',         // 教師
  PRINCIPAL = 'principal',     // 校長
  ADMIN = 'admin',            // 管理者
  PARENT = 'parent'           // 保護者（閲覧のみ）
}
```

### users/{userId}/settings サブコレクション

```typescript
interface UserSettings {
  // エディタ設定
  editor: {
    fontSize: 'small' | 'medium' | 'large';
    fontFamily: string;
    autoSave: boolean;
    autoSaveInterval: number;  // 秒
    spellCheck: boolean;
  };
  
  // AI設定
  ai: {
    writingStyle: WritingStyle;
    autoSuggest: boolean;
    suggestionLevel: 'minimal' | 'moderate' | 'maximum';
    defaultGreeting: string;
  };
  
  // 通知設定
  notifications: {
    email: {
      documentShared: boolean;
      weeklyReport: boolean;
      systemUpdates: boolean;
    };
    push: {
      enabled: boolean;
      documentReminders: boolean;
    };
  };
  
  // プライバシー設定
  privacy: {
    shareAnalytics: boolean;
    allowTemplateSharing: boolean;
  };
}
```

### users/{userId}/dictionary サブコレクション

```typescript
interface DictionaryWord {
  wordId: string;              // 単語ID
  word: string;                // 単語
  reading: string;             // 読み方
  variations?: string[];       // 表記バリエーション
  category: WordCategory;      // カテゴリ
  priority: number;            // 優先度 (1-10)
  usageCount: number;          // 使用回数
  createdAt: Timestamp;        // 作成日時
  updatedAt: Timestamp;        // 更新日時
}

enum WordCategory {
  SCHOOL = 'school',           // 学校関連
  FACILITY = 'facility',       // 施設
  PERSON = 'person',           // 人名
  EVENT = 'event',             // 行事
  SUBJECT = 'subject',         // 教科
  CUSTOM = 'custom'            // カスタム
}
```

## 📄 ドキュメントデータ

### documents コレクション

```typescript
interface Document {
  // 識別情報
  documentId: string;          // ドキュメントID
  userId: string;              // 作成者ID
  
  // 基本情報
  title: string;               // タイトル
  type: DocumentType;          // ドキュメントタイプ
  status: DocumentStatus;      // ステータス
  
  // コンテンツ
  content: {
    delta: QuillDelta;         // Quill Delta形式
    html: string;              // HTML形式
    plainText: string;         // プレーンテキスト
    wordCount: number;         // 文字数
    imageCount: number;        // 画像数
  };
  
  // メタデータ
  metadata: {
    templateId?: string;       // 使用テンプレートID
    themeColor: string;        // テーマカラー
    layout: LayoutType;        // レイアウトタイプ
    tags: string[];            // タグ
    schoolYear?: string;       // 年度
    issueNumber?: number;      // 号数
  };
  
  // AI処理情報
  aiProcessing?: {
    originalText?: string;     // 元のテキスト
    processedAt: Timestamp;    // 処理日時
    model: string;             // 使用モデル
    tokensUsed: number;        // 使用トークン数
  };
  
  // 共有情報
  sharing: {
    isPublic: boolean;         // 公開フラグ
    shareUrl?: string;         // 共有URL
    password?: string;         // パスワード（ハッシュ）
    expiresAt?: Timestamp;     // 有効期限
  };
  
  // タイムスタンプ
  createdAt: Timestamp;        // 作成日時
  updatedAt: Timestamp;        // 更新日時
  publishedAt?: Timestamp;     // 公開日時
  deletedAt?: Timestamp;       // 削除日時（論理削除）
}

enum DocumentType {
  CLASS_NEWSLETTER = 'class_newsletter',      // 学級通信
  GRADE_NEWSLETTER = 'grade_newsletter',      // 学年通信
  SCHOOL_NEWSLETTER = 'school_newsletter',    // 学校通信
  EVENT_REPORT = 'event_report',              // 行事報告
  NOTICE = 'notice'                           // お知らせ
}

enum DocumentStatus {
  DRAFT = 'draft',             // 下書き
  REVIEW = 'review',           // レビュー中
  PUBLISHED = 'published',     // 公開済み
  ARCHIVED = 'archived'        // アーカイブ
}

enum LayoutType {
  STANDARD = 'standard',       // 標準
  IMAGE_HEAVY = 'image_heavy', // 画像多め
  TEXT_ONLY = 'text_only',     // テキストのみ
  MAGAZINE = 'magazine'        // 雑誌風
}
```

### documents/{documentId}/versions サブコレクション

```typescript
interface DocumentVersion {
  versionId: string;           // バージョンID
  versionNumber: number;       // バージョン番号
  content: {
    delta: QuillDelta;
    html: string;
    plainText: string;
  };
  changes: {
    summary: string;           // 変更概要
    addedWords: number;        // 追加文字数
    deletedWords: number;      // 削除文字数
  };
  createdBy: string;           // 作成者ID
  createdAt: Timestamp;        // 作成日時
  isAutoSave: boolean;         // 自動保存かどうか
}
```

## 🎨 テンプレートデータ

### templates コレクション

```typescript
interface Template {
  templateId: string;          // テンプレートID
  name: string;                // テンプレート名
  description: string;         // 説明
  category: TemplateCategory;  // カテゴリ
  
  // デザイン情報
  design: {
    thumbnail: string;         // サムネイルURL
    previewUrl: string;        // プレビューURL
    themeColors: string[];     // テーマカラー
    fonts: string[];           // 使用フォント
  };
  
  // コンテンツ
  content: {
    html: string;              // HTMLテンプレート
    css: string;               // スタイルシート
    variables: TemplateVariable[]; // 変数定義
    sections: TemplateSection[];   // セクション定義
  };
  
  // メタデータ
  metadata: {
    season?: Season;           // 季節
    events?: string[];         // 関連行事
    grades?: string[];         // 対象学年
    tags: string[];            // タグ
  };
  
  // 使用統計
  stats: {
    usageCount: number;        // 使用回数
    rating: number;            // 評価（1-5）
    ratingCount: number;       // 評価数
  };
  
  // システム情報
  createdBy: string;           // 作成者ID
  createdAt: Timestamp;        // 作成日時
  updatedAt: Timestamp;        // 更新日時
  isOfficial: boolean;         // 公式テンプレート
  isActive: boolean;           // アクティブフラグ
}

interface TemplateVariable {
  key: string;                 // 変数キー
  label: string;               // ラベル
  type: 'text' | 'date' | 'image' | 'list';
  defaultValue?: any;          // デフォルト値
  required: boolean;           // 必須フラグ
}

interface TemplateSection {
  id: string;                  // セクションID
  name: string;                // セクション名
  type: 'header' | 'content' | 'footer' | 'sidebar';
  isRepeatable: boolean;       // 繰り返し可能
  minItems?: number;           // 最小アイテム数
  maxItems?: number;           // 最大アイテム数
}

enum TemplateCategory {
  SEASONAL = 'seasonal',       // 季節
  EVENT = 'event',             // 行事
  REGULAR = 'regular',         // 定期
  SPECIAL = 'special'          // 特別
}

enum Season {
  SPRING = 'spring',           // 春
  SUMMER = 'summer',           // 夏
  AUTUMN = 'autumn',           // 秋
  WINTER = 'winter'            // 冬
}
```

## 🏫 学校データ

### schools コレクション

```typescript
interface School {
  schoolId: string;            // 学校ID
  name: string;                // 学校名
  type: SchoolType;            // 学校種別
  
  // 基本情報
  info: {
    address: string;           // 住所
    phone: string;             // 電話番号
    email: string;             // メールアドレス
    website?: string;          // ウェブサイト
    principalName: string;     // 校長名
  };
  
  // 設定
  settings: {
    allowedDomains: string[];  // 許可メールドメイン
    defaultTemplate?: string;  // デフォルトテンプレート
    customDictionary: DictionaryWord[]; // 学校共通辞書
  };
  
  // 統計
  stats: {
    teacherCount: number;      // 教師数
    studentCount: number;      // 生徒数
    documentsCreated: number;  // 作成ドキュメント数
  };
  
  // サブスクリプション
  subscription: {
    plan: 'basic' | 'standard' | 'premium';
    seats: number;             // ライセンス数
    expiresAt: Timestamp;      // 有効期限
  };
  
  createdAt: Timestamp;        // 作成日時
  updatedAt: Timestamp;        // 更新日時
}

enum SchoolType {
  ELEMENTARY = 'elementary',   // 小学校
  JUNIOR_HIGH = 'junior_high', // 中学校
  HIGH = 'high',               // 高等学校
  SPECIAL = 'special'          // 特別支援学校
}
```

## 🔧 システムデータ

### system/prompts コレクション

```typescript
interface AIPrompt {
  promptId: string;            // プロンプトID
  name: string;                // プロンプト名
  category: PromptCategory;    // カテゴリ
  
  // プロンプト内容
  content: {
    system: string;            // システムプロンプト
    user: string;              // ユーザープロンプトテンプレート
    variables: string[];       // 使用変数
  };
  
  // 設定
  settings: {
    model: string;             // 推奨モデル
    temperature: number;       // Temperature設定
    maxTokens: number;         // 最大トークン数
  };
  
  // メタデータ
  version: string;             // バージョン
  isActive: boolean;           // アクティブフラグ
  createdAt: Timestamp;        // 作成日時
  updatedAt: Timestamp;        // 更新日時
}

enum PromptCategory {
  REWRITE = 'rewrite',         // リライト
  HEADING = 'heading',         // 見出し生成
  SUMMARY = 'summary',         // 要約
  EXPANSION = 'expansion'      // 拡張
}
```

## 🔐 セキュリティルール

### Firestore セキュリティルール例

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // ユーザーは自分のデータのみアクセス可能
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      match /dictionary/{wordId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
    
    // ドキュメントは作成者のみ編集可能
    match /documents/{documentId} {
      allow read: if request.auth != null && 
        (resource.data.userId == request.auth.uid || 
         resource.data.sharing.isPublic == true);
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && 
        resource.data.userId == request.auth.uid;
    }
    
    // テンプレートは全ユーザー読み取り可能
    match /templates/{templateId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        request.auth.token.admin == true;
    }
  }
}
```

## 📊 インデックス設定

### 複合インデックス

```yaml
# firestore.indexes.json
{
  "indexes": [
    {
      "collectionGroup": "documents",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "updatedAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "documents",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "metadata.tags", "arrayConfig": "CONTAINS" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "templates",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "category", "order": "ASCENDING" },
        { "fieldPath": "stats.rating", "order": "DESCENDING" }
      ]
    }
  ]
}
```

## 🔄 データ移行

### スキーマバージョン管理

```typescript
interface SchemaVersion {
  version: string;             // バージョン番号
  appliedAt: Timestamp;        // 適用日時
  changes: string[];           // 変更内容
  migrationScript?: string;    // 移行スクリプト
}
```

### 移行スクリプト例

```typescript
// Migration v1.0.0 to v1.1.0
async function migrateToV110() {
  const batch = firestore.batch();
  
  // すべてのドキュメントに wordCount を追加
  const documents = await firestore.collection('documents').get();
  
  documents.forEach(doc => {
    const content = doc.data().content;
    const wordCount = content.plainText?.length || 0;
    
    batch.update(doc.ref, {
      'content.wordCount': wordCount
    });
  });
  
  await batch.commit();
}
```

---

*次のステップ: [アーキテクチャ決定記録](../../adr/)で設計の背景を理解*