#!/bin/bash

# ゆとり職員室 - セキュアビルドスクリプト
# 使用方法: ./scripts/build.sh [development|production]

set -e

# 環境の設定
ENVIRONMENT=${1:-development}

echo "🚀 ゆとり職員室 ビルド開始 (環境: $ENVIRONMENT)"

# 環境変数ファイルの確認
ENV_FILE="scripts/env/$ENVIRONMENT.env"
if [ ! -f "$ENV_FILE" ]; then
    echo "❌ 環境変数ファイルが見つかりません: $ENV_FILE"
    echo "📝 scripts/env/$ENVIRONMENT.env.example をコピーして設定してください"
    exit 1
fi

# 環境変数の読み込み
source "$ENV_FILE"

# 必須環境変数の確認
if [ -z "$FIREBASE_API_KEY" ] || [ -z "$GOOGLE_CLIENT_ID" ]; then
    echo "❌ 必須環境変数が設定されていません"
    echo "📝 $ENV_FILE で以下を設定してください:"
    echo "   - FIREBASE_API_KEY"
    echo "   - GOOGLE_CLIENT_ID"
    exit 1
fi

echo "✅ 環境変数確認完了"

# frontendディレクトリに移動
cd frontend

# 依存関係のインストール
echo "📦 依存関係をインストール中..."
flutter pub get

# Web用config.jsの生成
echo "⚙️  Web設定ファイルを生成中..."
cat > web/config.js << EOF
// Google OAuth設定（自動生成 - Git管理対象外）
window.googleConfig = {
  clientId: '$GOOGLE_CLIENT_ID',
};
EOF

# ビルド実行
echo "🔨 Flutter Webビルド実行中..."
flutter build web \
  --dart-define=FIREBASE_API_KEY="$FIREBASE_API_KEY" \
  --dart-define=FIREBASE_APP_ID="$FIREBASE_APP_ID" \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID="$FIREBASE_MESSAGING_SENDER_ID" \
  --dart-define=FIREBASE_PROJECT_ID="$FIREBASE_PROJECT_ID" \
  --dart-define=FIREBASE_AUTH_DOMAIN="$FIREBASE_AUTH_DOMAIN" \
  --dart-define=FIREBASE_STORAGE_BUCKET="$FIREBASE_STORAGE_BUCKET" \
  --dart-define=GOOGLE_CLIENT_ID="$GOOGLE_CLIENT_ID" \
  --dart-define=ENVIRONMENT="$ENVIRONMENT" \
  --release

echo "✅ ビルド完了!"
echo "📁 ビルド成果物: frontend/build/web/"

# 本番環境の場合は追加チェック
if [ "$ENVIRONMENT" = "production" ]; then
    echo "🔍 本番環境向け最終チェック..."
    
    # config.jsが存在することを確認
    if [ ! -f "web/config.js" ]; then
        echo "❌ web/config.js が生成されていません"
        exit 1
    fi
    
    echo "✅ 本番環境チェック完了"
    echo "🚀 Firebase Hostingへのデプロイ準備完了"
fi 