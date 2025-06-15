#!/bin/bash
# firebase_setup_cli.sh
# Firebase CLI自動設定スクリプト

set -e

echo "🔥 Firebase CLI設定開始"

PROJECT_ID="gakkoudayori-ai"

# カラー設定
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Firebase CLI確認
echo "📋 Firebase CLI確認中..."
if ! command -v firebase &> /dev/null; then
    print_warning "Firebase CLIがインストールされていません"
    echo "インストール中..."
    npm install -g firebase-tools
    print_status "Firebase CLI インストール完了"
else
    print_status "Firebase CLI確認完了"
fi

# Firebase認証確認
echo "🔐 Firebase認証確認中..."
if ! firebase projects:list &>/dev/null; then
    print_warning "Firebase認証が必要です"
    firebase login
fi

print_status "Firebase認証確認完了"

# Firebaseプロジェクト設定
echo "🏗️  Firebaseプロジェクト設定中..."

# プロジェクト使用設定
firebase use $PROJECT_ID
print_status "Firebaseプロジェクト設定: $PROJECT_ID"

# Firebase設定ファイル作成
echo "📋 Firebase設定ファイル作成中..."

# firebase.json設定
cat > firebase.json << 'EOF'
{
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  },
  "hosting": {
    "public": "frontend/build/web",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ]
  },
  "storage": {
    "rules": "storage.rules"
  },
  "emulators": {
    "auth": {
      "port": 9099
    },
    "firestore": {
      "port": 8080
    },
    "hosting": {
      "port": 5000
    },
    "storage": {
      "port": 9199
    },
    "ui": {
      "enabled": true,
      "port": 4000
    }
  }
}
EOF

print_status "firebase.json作成完了"

# Firestore ルール設定
echo "🛡️  Firestoreセキュリティルール設定中..."

cat > firestore.rules << 'EOF'
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // 認証済みユーザーのみアクセス可能
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
    
    // 学級通信ドキュメント
    match /letters/{documentId} {
      allow read, write: if request.auth != null 
        && request.auth.uid == resource.data.author;
    }
    
    // ユーザープロファイル
    match /users/{userId} {
      allow read, write: if request.auth != null 
        && request.auth.uid == userId;
    }
  }
}
EOF

print_status "Firestoreセキュリティルール作成完了"

# Storage ルール設定
echo "📦 Cloud Storageセキュリティルール設定中..."

cat > storage.rules << 'EOF'
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // 認証済みユーザーのドキュメント
    match /documents/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null 
        && request.auth.uid == userId;
    }
    
    // 一時的な音声ファイル
    match /temp/{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
EOF

print_status "Cloud Storageセキュリティルール作成完了"

# Firestore インデックス設定
echo "📊 Firestoreインデックス設定中..."

cat > firestore.indexes.json << 'EOF'
{
  "indexes": [
    {
      "collectionGroup": "letters",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "author",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "createdAt",
          "order": "DESCENDING"
        }
      ]
    },
    {
      "collectionGroup": "letters",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "status",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "updatedAt",
          "order": "DESCENDING"
        }
      ]
    }
  ],
  "fieldOverrides": []
}
EOF

print_status "Firestoreインデックス設定完了"

# Flutter Firebase設定ファイル作成
echo "🎨 Flutter Firebase設定ファイル作成中..."

mkdir -p frontend/web

cat > frontend/web/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
  <base href="$FLUTTER_BASE_HREF">
  <meta charset="UTF-8">
  <meta content="IE=Edge" http-equiv="X-UA-Compatible">
  <meta name="description" content="学校だよりAI - 音声入力で学級通信を自動生成">
  <meta name="apple-mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-status-bar-style" content="black">
  <meta name="apple-mobile-web-app-title" content="学校だよりAI">
  <link rel="apple-touch-icon" href="icons/Icon-192.png">
  <link rel="icon" type="image/png" href="favicon.png"/>
  <title>学校だよりAI</title>
  <link rel="manifest" href="manifest.json">
  
  <!-- Firebase configuration will be added here -->
  <script src="https://www.gstatic.com/firebasejs/9.15.0/firebase-app-compat.js"></script>
  <script src="https://www.gstatic.com/firebasejs/9.15.0/firebase-auth-compat.js"></script>
  <script src="https://www.gstatic.com/firebasejs/9.15.0/firebase-firestore-compat.js"></script>
  <script src="https://www.gstatic.com/firebasejs/9.15.0/firebase-storage-compat.js"></script>
</head>
<body>
  <script>
    window.addEventListener('load', function(ev) {
      // Download main.dart.js
      _flutter.loader.loadEntrypoint({
        serviceWorker: {
          serviceWorkerVersion: serviceWorkerVersion,
        }
      }).then(function(engineInitializer) {
        return engineInitializer.initializeEngine();
      }).then(function(appRunner) {
        return appRunner.runApp();
      });
    });
  </script>
</body>
</html>
EOF

print_status "Flutter Web設定ファイル作成完了"

# Firebase設定確認
echo "🔍 Firebase設定確認中..."
firebase projects:list
print_status "Firebase CLI設定完了！"

echo ""
echo "🎯 次の手順:"
echo "1. Firestore初期化: firebase firestore:rules deploy"
echo "2. Storage初期化: firebase storage:rules deploy"
echo "3. Flutter Firebase設定追加"
echo ""
EOF 