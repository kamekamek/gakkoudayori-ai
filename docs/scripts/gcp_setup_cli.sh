#!/bin/bash
# gcp_setup_cli.sh
# Google Cloud Platform CLI自動設定スクリプト

set -e  # エラー時に停止

echo "🔧 Google Cloud Platform CLI設定開始"

# プロジェクト設定
PROJECT_ID="gakkoudayori-ai"
REGION="asia-northeast1"
ZONE="asia-northeast1-a"

# カラー設定
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Google Cloud CLI確認
echo "📋 Google Cloud CLI確認中..."
if ! command -v gcloud &> /dev/null; then
    print_error "Google Cloud CLIがインストールされていません"
    echo "インストールURL: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

print_status "Google Cloud CLI確認完了"

# 認証確認
echo "🔐 認証状況確認中..."
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q "@"; then
    print_warning "Google Cloud認証が必要です"
    echo "以下のコマンドで認証してください:"
    echo "gcloud auth login"
    exit 1
fi

CURRENT_USER=$(gcloud auth list --filter=status:ACTIVE --format="value(account)")
print_status "認証済みユーザー: $CURRENT_USER"

# プロジェクト作成/設定
echo "🏗️  プロジェクト設定中..."

# プロジェクト存在確認
if gcloud projects describe $PROJECT_ID &>/dev/null; then
    print_status "プロジェクト $PROJECT_ID は既に存在します"
else
    print_warning "プロジェクト $PROJECT_ID を作成中..."
    if gcloud projects create $PROJECT_ID --name="Yutori Kyoshitu AI"; then
        print_status "プロジェクト作成完了"
    else
        print_error "プロジェクト作成失敗"
        exit 1
    fi
fi

# アクティブプロジェクト設定
gcloud config set project $PROJECT_ID
print_status "アクティブプロジェクト設定: $PROJECT_ID"

# デフォルトリージョン/ゾーン設定
gcloud config set compute/region $REGION
gcloud config set compute/zone $ZONE
print_status "デフォルトリージョン設定: $REGION"

# 課金アカウント確認（手動設定が必要な場合あり）
echo "💳 課金アカウント確認中..."
BILLING_ACCOUNTS=$(gcloud billing accounts list --format="value(name)" 2>/dev/null)
if [ -z "$BILLING_ACCOUNTS" ]; then
    print_warning "課金アカウントの設定は手動で行ってください"
    echo "URL: https://console.cloud.google.com/billing"
else
    print_status "課金アカウントが利用可能です"
fi

# 必要API一括有効化
echo "🔌 必要API有効化中..."

APIs=(
    "aiplatform.googleapis.com"      # Vertex AI
    "speech.googleapis.com"          # Speech-to-Text
    "storage.googleapis.com"         # Cloud Storage
    "run.googleapis.com"             # Cloud Run
    "firestore.googleapis.com"       # Cloud Firestore
    "firebase.googleapis.com"        # Firebase
    "cloudbuild.googleapis.com"      # Cloud Build
    "containerregistry.googleapis.com"  # Container Registry
)

for api in "${APIs[@]}"; do
    echo "有効化中: $api"
    if gcloud services enable $api; then
        print_status "$api 有効化完了"
    else
        print_error "$api 有効化失敗"
    fi
done

# サービスアカウント作成
echo "🔑 サービスアカウント作成中..."

SA_NAME="yutori-ai-service"
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

# サービスアカウント存在確認
if gcloud iam service-accounts describe $SA_EMAIL &>/dev/null; then
    print_status "サービスアカウント $SA_EMAIL は既に存在します"
else
    if gcloud iam service-accounts create $SA_NAME \
        --display-name="Yutori Kyoshitu AI Service Account" \
        --description="学校だよりAI システム用サービスアカウント"; then
        print_status "サービスアカウント作成完了: $SA_EMAIL"
    else
        print_error "サービスアカウント作成失敗"
        exit 1
    fi
fi

# 必要な権限付与
echo "🛡️  権限付与中..."

ROLES=(
    "roles/aiplatform.user"          # Vertex AI使用権限
    "roles/speech.admin"             # Speech-to-Text管理権限
    "roles/storage.admin"            # Cloud Storage管理権限
    "roles/run.developer"            # Cloud Run開発権限
    "roles/datastore.user"           # Firestore使用権限
    "roles/firebase.admin"           # Firebase管理権限
)

for role in "${ROLES[@]}"; do
    echo "権限付与中: $role"
    if gcloud projects add-iam-policy-binding $PROJECT_ID \
        --member="serviceAccount:$SA_EMAIL" \
        --role="$role"; then
        print_status "$role 付与完了"
    else
        print_error "$role 付与失敗"
    fi
done

# キーファイル作成準備
echo "🔐 サービスアカウントキー作成準備..."

# secretsディレクトリ作成
mkdir -p backend/secrets
mkdir -p .env

KEY_FILE="backend/secrets/service-account-key.json"

if [ -f "$KEY_FILE" ]; then
    print_warning "キーファイルは既に存在します: $KEY_FILE"
else
    if gcloud iam service-accounts keys create $KEY_FILE \
        --iam-account=$SA_EMAIL; then
        print_status "サービスアカウントキー作成完了: $KEY_FILE"
        chmod 600 $KEY_FILE  # 読み取り専用に設定
    else
        print_error "サービスアカウントキー作成失敗"
        exit 1
    fi
fi

# .gitignore更新
echo "📋 .gitignore更新中..."
if ! grep -q "backend/secrets/" .gitignore 2>/dev/null; then
    echo "" >> .gitignore
    echo "# Google Cloud secrets" >> .gitignore
    echo "backend/secrets/" >> .gitignore
    echo ".env" >> .gitignore
    print_status ".gitignore更新完了"
fi

# 環境変数ファイル作成
echo "🌍 環境変数ファイル作成中..."
cat > .env << EOF
# Google Cloud Platform設定
GOOGLE_CLOUD_PROJECT_ID=$PROJECT_ID
GOOGLE_CLOUD_REGION=$REGION
GOOGLE_CLOUD_ZONE=$ZONE
GOOGLE_APPLICATION_CREDENTIALS=backend/secrets/service-account-key.json

# サービスアカウント
SERVICE_ACCOUNT_EMAIL=$SA_EMAIL

# 作成日時
CREATED_AT=$(date '+%Y-%m-%d %H:%M:%S')
EOF

print_status "環境変数ファイル作成完了: .env"

# 設定確認
echo "🔍 設定確認中..."
echo "プロジェクト: $(gcloud config get-value project)"
echo "リージョン: $(gcloud config get-value compute/region)"
echo "サービスアカウント: $SA_EMAIL"
echo "キーファイル: $KEY_FILE"

print_status "Google Cloud Platform CLI設定完了！"

echo ""
echo "🎯 次の手順:"
echo "1. Firebase設定: firebase login && firebase init"
echo "2. Flutter環境確認: flutter doctor"
echo "3. 統合テスト実行"
echo ""
EOF 