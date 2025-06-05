#!/bin/bash
set -e

# カラー設定
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 ゆとり職員室 - Google Cloud セットアップ開始${NC}"

# プロジェクトIDの確認
PROJECT_ID=$(gcloud config get-value project)
if [ -z "$PROJECT_ID" ]; then
    echo -e "${RED}❌ Google Cloud プロジェクトが設定されていません${NC}"
    echo "gcloud init を実行してプロジェクトを設定してください"
    exit 1
fi

echo -e "${YELLOW}📋 使用するプロジェクト: ${PROJECT_ID}${NC}"

# 必要なAPIを有効化
echo -e "${YELLOW}🔧 Google Cloud APIs を有効化中...${NC}"

APIs=(
    "firestore.googleapis.com"
    "storage.googleapis.com"
    "run.googleapis.com"
    "aiplatform.googleapis.com"
    "speech.googleapis.com"
    "texttospeech.googleapis.com"
    "cloudfunctions.googleapis.com"
    "cloudbuild.googleapis.com"
    "firebase.googleapis.com"
)

for api in "${APIs[@]}"; do
    echo -e "  📡 有効化中: $api"
    gcloud services enable $api --quiet
done

echo -e "${GREEN}✅ すべてのAPIが有効化されました${NC}"

# Firestore データベース設定
echo -e "${YELLOW}🗄️ Firestore データベースを設定中...${NC}"
if ! gcloud firestore databases describe --location=asia-northeast1 --quiet >/dev/null 2>&1; then
    echo -e "  📊 Firestore データベースを作成中..."
    gcloud firestore databases create --location=asia-northeast1 --quiet
    echo -e "${GREEN}✅ Firestore データベースが作成されました${NC}"
else
    echo -e "${GREEN}✅ Firestore データベースは既に存在します${NC}"
fi

# Cloud Storage バケット作成
echo -e "${YELLOW}🪣 Cloud Storage バケットを作成中...${NC}"

BUCKETS=(
    "${PROJECT_ID}-uploads"
    "${PROJECT_ID}-templates"
    "${PROJECT_ID}-exports"
)

for bucket in "${BUCKETS[@]}"; do
    if ! gsutil ls -b gs://$bucket >/dev/null 2>&1; then
        echo -e "  📦 バケット作成中: $bucket"
        gsutil mb -l asia-northeast1 gs://$bucket
        # アップロード用バケットのCORS設定
        if [[ $bucket == *"uploads"* ]]; then
            echo '[{"origin":["*"],"method":["GET","POST","PUT","DELETE"],"responseHeader":["Content-Type"],"maxAgeSeconds":3600}]' > cors.json
            gsutil cors set cors.json gs://$bucket
            rm cors.json
        fi
    else
        echo -e "${GREEN}✅ バケット $bucket は既に存在します${NC}"
    fi
done

echo -e "${GREEN}✅ すべてのバケットが準備されました${NC}"

# サービスアカウントキー作成（開発用）
echo -e "${YELLOW}🔑 サービスアカウントキーを作成中...${NC}"
SERVICE_ACCOUNT_NAME="yutori-dev-service"
SERVICE_ACCOUNT_EMAIL="${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

if ! gcloud iam service-accounts describe $SERVICE_ACCOUNT_EMAIL --quiet >/dev/null 2>&1; then
    echo -e "  👤 サービスアカウント作成中..."
    gcloud iam service-accounts create $SERVICE_ACCOUNT_NAME \
        --description="ゆとり職員室開発用サービスアカウント" \
        --display-name="Yutori Dev Service Account"
    
    # 必要な権限を付与
    ROLES=(
        "roles/datastore.user"
        "roles/storage.admin"
        "roles/aiplatform.user"
        "roles/firebase.admin"
    )
    
    for role in "${ROLES[@]}"; do
        gcloud projects add-iam-policy-binding $PROJECT_ID \
            --member="serviceAccount:$SERVICE_ACCOUNT_EMAIL" \
            --role=$role \
            --quiet
    done
    
    echo -e "${GREEN}✅ サービスアカウントが作成されました${NC}"
else
    echo -e "${GREEN}✅ サービスアカウントは既に存在します${NC}"
fi

# キーファイル作成
KEY_FILE="../backend/credentials/service-account-key.json"
mkdir -p ../backend/credentials
if [ ! -f "$KEY_FILE" ]; then
    echo -e "  🔐 サービスアカウントキー生成中..."
    gcloud iam service-accounts keys create $KEY_FILE \
        --iam-account=$SERVICE_ACCOUNT_EMAIL
    echo -e "${GREEN}✅ サービスアカウントキーが生成されました: $KEY_FILE${NC}"
else
    echo -e "${GREEN}✅ サービスアカウントキーは既に存在します${NC}"
fi

# Hello World デプロイテスト用アプリ作成
echo -e "${YELLOW}🧪 Hello World テストアプリを準備中...${NC}"
mkdir -p ../test-deploy
cat > ../test-deploy/main.py << 'EOF'
from fastapi import FastAPI
import os

app = FastAPI()

@app.get("/")
def hello_world():
    return {
        "message": "Hello from ゆとり職員室!",
        "service": "Cloud Run",
        "status": "success"
    }

@app.get("/health")
def health():
    return {"status": "healthy"}

if __name__ == "__main__":
    import uvicorn
    port = int(os.environ.get("PORT", 8000))
    uvicorn.run(app, host="0.0.0.0", port=port)
EOF

cat > ../test-deploy/requirements.txt << 'EOF'
fastapi==0.115.12
uvicorn==0.34.3
EOF

cat > ../test-deploy/Dockerfile << 'EOF'
FROM python:3.11-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt

COPY main.py .

EXPOSE 8000
CMD ["python", "main.py"]
EOF

echo -e "${GREEN}✅ セットアップ完了！${NC}"
echo -e "${YELLOW}📋 次のステップ:${NC}"
echo -e "  1. cd ../test-deploy"
echo -e "  2. gcloud run deploy yutori-test --source . --region asia-northeast1 --allow-unauthenticated"
echo -e "  3. デプロイされたURLにアクセスして動作確認"
echo ""
echo -e "${GREEN}🎉 Cloud Run・Cloud Storage・Firestore の有効化とセットアップが完了しました！${NC}" 