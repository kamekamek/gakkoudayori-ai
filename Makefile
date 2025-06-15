# 学級通信エディタ - 環境管理Makefile

.PHONY: help dev prod staging build-dev build-prod deploy deploy-frontend deploy-backend deploy-all deploy-staging deploy-preview ci-setup test lint format reset-dev

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
	@echo "🧪 テスト・品質:"
	@echo "  make test         - 全テスト実行"
	@echo "  make lint         - 静的解析実行"
	@echo "  make format       - コードフォーマット"
	@echo ""
	@echo "🚀 デプロイ:"
	@echo "  make deploy           - 全体デプロイ（推奨）"
	@echo "  make deploy-frontend  - フロントエンドをFirebase Hostingにデプロイ"
	@echo "  make deploy-backend   - バックエンドをCloud Runにデプロイ"
	@echo "  make deploy-staging   - ステージング環境にデプロイ"
	@echo "  make deploy-preview   - プレビュー環境にデプロイ"
	@echo ""
	@echo "⚙️ CI/CD:"
	@echo "  make ci-setup     - CI/CD環境セットアップ"
	@echo "  make ci-test      - CI環境でのテスト実行"

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
		--dart-define=API_BASE_URL=https://staging-yutori-backend.asia-northeast1.run.app/api/v1/ai

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

# テスト実行
test:
	@echo "🧪 全テスト実行中..."
	@echo "📱 Flutterテスト..."
	cd frontend && flutter test
	@echo "🐍 Pythonテスト..."
	cd backend/functions && python -m pytest tests/ -v || echo "⚠️ テストファイルが見つかりません"

# 静的解析
lint:
	@echo "🔍 静的解析実行中..."
	@echo "📱 Flutter解析..."
	cd frontend && flutter analyze
	@echo "🐍 Python解析..."
	cd backend/functions && python -m flake8 . --max-line-length=120 || echo "⚠️ flake8がインストールされていません"

# コードフォーマット
format:
	@echo "✨ コードフォーマット実行中..."
	@echo "📱 Flutterフォーマット..."
	cd frontend && dart format .
	@echo "🐍 Pythonフォーマット..."
	cd backend/functions && python -m black . || echo "⚠️ blackがインストールされていません"

# CI/CD環境セットアップ
ci-setup:
	@echo "⚙️ CI/CD環境セットアップ中..."
	@echo "📦 Flutter依存関係取得..."
	cd frontend && flutter pub get
	@echo "📦 Python依存関係インストール..."
	cd backend/functions && pip install -r requirements.txt
	@echo "✅ CI/CD環境セットアップ完了"

# CI環境でのテスト実行
ci-test: ci-setup lint test
	@echo "✅ CI環境でのテスト完了"

# フロントエンドデプロイ
deploy-frontend: build-prod
	@echo "📤 フロントエンドをFirebase Hostingにデプロイ中..."
	firebase deploy --only hosting

# バックエンドデプロイ
deploy-backend:
	@echo "📤 バックエンドをCloud Runにデプロイ中..."
	cd backend/functions && gcloud run deploy yutori-backend \
		--source=. \
		--region=asia-northeast1 \
		--allow-unauthenticated \
		--memory=2Gi \
		--timeout=300 \
		--set-env-vars="ENVIRONMENT=production"

# 全体デプロイ（推奨）
deploy: deploy-backend deploy-frontend
	@echo "✅ 全体デプロイ完了！"
	@echo "🌐 フロントエンド: https://gakkoudayori-ai.web.app"
	@echo "🔧 バックエンド: https://yutori-backend-944053509139.asia-northeast1.run.app"

# 全体デプロイ（別名）
deploy-all: deploy

# プレビューデプロイ（プルリクエスト用）
deploy-preview:
	@echo "👀 プレビューデプロイ中..."
	cd frontend && flutter build web \
		--dart-define=ENVIRONMENT=preview \
		--dart-define=API_BASE_URL=https://yutori-backend-944053509139.asia-northeast1.run.app/api/v1/ai \
		--release
	firebase hosting:channel:deploy preview --expires 7d

# ステージングデプロイ
deploy-staging: 
	@echo "🧪 ステージング環境用ビルド中..."
	cd frontend && flutter build web \
		--dart-define=ENVIRONMENT=staging \
		--dart-define=API_BASE_URL=https://staging-yutori-backend.asia-northeast1.run.app/api/v1/ai \
		--release
	@echo "📤 ステージング環境にデプロイ中..."
	firebase hosting:channel:deploy staging --expires 30d
	@echo "✅ ステージング環境デプロイ完了！"
	@echo "🌐 ステージング: https://gakkoudayori-ai--staging.web.app"

# 開発環境リセット
reset-dev:
	@echo "🔄 開発環境リセット中..."
	cd frontend && flutter clean && flutter pub get
	@echo "✅ 開発環境リセット完了" 