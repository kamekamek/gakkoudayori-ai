# 学級通信エディタ - 環境管理Makefile

.PHONY: help dev prod staging build-dev build-prod deploy-frontend deploy-backend

# デフォルトターゲット
help:
	@echo "🎯 学級通信エディタ - 利用可能なコマンド:"
	@echo ""
	@echo "📱 フロントエンド:"
	@echo "  make dev          - 開発環境で起動"
	@echo "  make staging      - ステージング環境で起動"
	@echo "  make build-dev    - 開発環境用ビルド"
	@echo "  make build-prod   - 本番環境用ビルド"
	@echo ""
	@echo "🚀 デプロイ:"
	@echo "  make deploy-frontend  - フロントエンドをFirebase Hostingにデプロイ"
	@echo "  make deploy-backend   - バックエンドをCloud Runにデプロイ"
	@echo "  make deploy-all       - フロントエンド・バックエンド両方デプロイ"

# 開発環境で起動
dev:
	@echo "🔧 開発環境で起動中..."
	cd frontend && flutter run -d chrome \
		--dart-define=ENVIRONMENT=development \
		--dart-define=API_BASE_URL=http://localhost:8081/api/v1/ai

# ステージング環境で起動
staging:
	@echo "🧪 ステージング環境で起動中..."
	cd frontend && flutter run -d chrome \
		--dart-define=ENVIRONMENT=staging \
		--dart-define=API_BASE_URL=https://staging-backend.example.com/api/v1/ai

# 開発環境用ビルド
build-dev:
	@echo "🔧 開発環境用ビルド中..."
	cd frontend && flutter build web \
		--dart-define=ENVIRONMENT=development \
		--dart-define=API_BASE_URL=http://localhost:8081/api/v1/ai \
		--debug

# 本番環境用ビルド
build-prod:
	@echo "🚀 本番環境用ビルド中..."
	cd frontend && flutter build web \
		--dart-define=ENVIRONMENT=production \
		--dart-define=API_BASE_URL=https://yutori-backend-944053509139.asia-northeast1.run.app/api/v1/ai \
		--release

# フロントエンドデプロイ
deploy-frontend: build-prod
	@echo "📤 フロントエンドをFirebase Hostingにデプロイ中..."
	firebase deploy --only hosting

# バックエンドデプロイ
deploy-backend:
	@echo "📤 バックエンドをCloud Runにデプロイ中..."
	cd backend && gcloud builds submit --tag gcr.io/gakkoudayori-ai/yutori-backend
	gcloud run deploy yutori-backend \
		--image gcr.io/gakkoudayori-ai/yutori-backend \
		--platform managed \
		--region asia-northeast1 \
		--allow-unauthenticated \
		--port 8080

# 全体デプロイ
deploy-all: deploy-backend deploy-frontend
	@echo "✅ 全体デプロイ完了！"
	@echo "🌐 フロントエンド: https://gakkoudayori-ai.web.app"
	@echo "🔧 バックエンド: https://yutori-backend-944053509139.asia-northeast1.run.app" 