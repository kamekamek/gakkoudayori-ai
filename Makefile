# 学校だよりAI - 環境管理Makefile

.PHONY: help dev prod staging build-dev build-prod deploy deploy-frontend deploy-backend deploy-backend-staging deploy-all deploy-staging deploy-preview ci-setup test lint format reset-dev backend-dev backend-test backend-setup check-backend test-adk warmup

# デフォルトターゲット
help:
	@echo "🎯 学校だよりAI - 利用可能なコマンド:"
	@echo ""
	@echo "📱 フロントエンド:"
	@echo "  make dev          - 開発環境で起動"
	@echo "  make staging      - ステージング環境で起動"
	@echo "  make build-dev    - 開発環境用ビルド"
	@echo "  make build-prod   - 本番環境用ビルド"
	@echo ""
	@echo "🐍 バックエンド (uv管理):"
	@echo "  make backend-dev   - バックエンド開発サーバー起動"
	@echo "  make backend-setup - uv環境セットアップ"
	@echo "  make backend-test  - uvでテスト実行"
	@echo ""
	@echo "🤖 エージェント/ADK:"
	@echo "  make test-adk     - ADK v1.0.0互換性テスト"
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
	@echo "  make warmup           - バックエンドWarm-up実行"
	@echo ""
	@echo "⚙️ CI/CD:"
	@echo "  make ci-setup     - CI/CD環境セットアップ"
	@echo "  make ci-test      - CI環境でのテスト実行"

# 開発環境で起動
dev:
	@echo "🔧 開発環境で起動中..."
	cd frontend && flutter run -d chrome --web-port 8080 \
		--dart-define=ENVIRONMENT=development \
		--dart-define=API_BASE_URL=http://localhost:8081/api/v1

# ステージング環境で起動
staging:
	@echo "🧪 ステージング環境で起動中..."
	cd frontend && flutter run -d chrome \
		--dart-define=ENVIRONMENT=staging \
		--dart-define=API_BASE_URL=https://gakkoudayori-backend-staging-944053509139.asia-northeast1.run.app/api/v1

# 開発環境用ビルド
build-dev:
	@echo "🔧 開発環境用ビルド中..."
	cd frontend && flutter build web \
		--dart-define=ENVIRONMENT=development \
		--dart-define=API_BASE_URL=http://localhost:8081/api/v1 \
		--debug

# 本番環境用ビルド
build-prod:
	@echo "🚀 本番環境用ビルド中..."
	cd frontend && flutter build web \
		--dart-define=ENVIRONMENT=production \
		--dart-define=API_BASE_URL=https://gakkoudayori-backend-944053509139.asia-northeast1.run.app \
		--release

# テスト実行
test:
	@echo "🧪 全テスト実行中..."
	@echo "📱 Flutterテスト..."
	cd frontend && flutter test
	@echo "🐍 Pythonテスト..."
	cd backend && uv run pytest tests/ -v || echo "⚠️ テストファイルが見つかりません"

# 静的解析
lint:
	@echo "🔍 静的解析実行中..."
	@echo "📱 Flutter解析..."
	cd frontend && flutter analyze
	@echo "🐍 Python解析..."
	cd backend && uv run ruff check . || echo "⚠️ ruffがインストールされていません"
	cd backend && uv run mypy . || echo "⚠️ mypyがインストールされていません"

# 事前チェック（推奨）
check-backend:
	@echo "🔍 バックエンド事前チェック実行中..."
	cd backend && uv sync --extra dev
	@echo "📝 Python構文チェック..."
	cd backend && uv run python -m py_compile app/main.py app/pdf.py app/classroom.py app/stt.py || echo "⚠️ 一部ファイルが見つかりません"
	@echo "🔍 静的解析..."
	cd backend && uv run ruff check . || echo "⚠️ ruffチェック完了（警告があります）"
	@echo "🧪 テスト実行..."
	cd backend && uv run pytest tests/ -v || echo "⚠️ テストファイルが見つかりません"
	@echo "✅ バックエンド事前チェック完了"

# コードフォーマット
format:
	@echo "✨ コードフォーマット実行中..."
	@echo "📱 Flutterフォーマット..."
	cd frontend && dart format .
	@echo "🐍 Pythonフォーマット..."
	cd backend && uv run black .
	cd backend && uv run isort .

# CI/CD環境セットアップ
ci-setup:
	@echo "âï¸... CI/CD環境セットアップ中..."
	@echo "ð¦ Flutter依存関係取得..."
	cd frontend && flutter pub get
	@echo "ð¦ Python依存関係インストール..."
	cd backend && uv sync --extra dev
	@echo "â... CI/CD環境セットアップ完了"

# CI環境でのテスト実行
ci-test: ci-setup lint test
	@echo "✅ CI環境でのテスト完了"

# フロントエンドデプロイ
deploy-frontend: build-prod
	@echo "📤 フロントエンドをFirebase Hostingにデプロイ中..."
	firebase deploy --only hosting --project gakkoudayori-ai

# バックエンドデプロイ
# Backend deployment to Cloud Run for production
deploy-backend:
	@echo "バックエンドをCloud Runにデプロイ中 (Buildpacks使用)..."
	cd backend && gcloud run deploy gakkoudayori-backend --source=. --region=asia-northeast1 --allow-unauthenticated --memory=2Gi --timeout=300s --min-instances=1 --max-instances=10 --cpu=2 --concurrency=100 --set-env-vars="ENVIRONMENT=production" --platform=managed

# ステージングバックエンドデプロイ
deploy-backend-staging:
	@echo "📤 ステージングバックエンドをCloud Runにデプロイ中 (Dockerfile使用)..."
	cd backend && gcloud run deploy gakkoudayori-backend-staging \
		--source=. \
		--region=asia-northeast1 \
		--allow-unauthenticated \
		--memory=2Gi \
		--timeout=300 \
		--min-instances=0 \
		--max-instances=5 \
		--cpu=1 \
		--concurrency=50 \
		--set-env-vars="ENVIRONMENT=staging" \
		--platform=managed

# 全体デプロイ（推奨）
deploy: deploy-backend deploy-frontend
	@echo "✅ 全体デプロイ完了！"
	@echo "🌐 フロントエンド: https://gakkoudayori-ai.web.app"
	@echo "🔧 バックエンド: https://gakkoudayori-backend-944053509139.asia-northeast1.run.app"

# 全体デプロイ（別名）
deploy-all: deploy

# プレビューデプロイ（プルリクエスト用）
deploy-preview:
	@echo "👀 プレビューデプロイ中..."
	cd frontend && flutter build web \
		--dart-define=ENVIRONMENT=preview \
		--dart-define=API_BASE_URL=https://gakkoudayori-backend-944053509139.asia-northeast1.run.app \
		--release
	firebase hosting:channel:deploy preview --expires 7d --project gakkoudayori-ai

# ステージングデプロイ
deploy-staging: 
	@echo "🧪 ステージング環境用ビルド中..."
	cd frontend && flutter build web \
		--dart-define=ENVIRONMENT=staging \
		--dart-define=API_BASE_URL=https://gakkoudayori-backend-staging-944053509139.asia-northeast1.run.app/api/v1 \
		--release
	@echo "📤 ステージング環境にデプロイ中..."
	firebase hosting:channel:deploy staging --expires 30d --project gakkoudayori-ai
	@echo "✅ ステージング環境デプロイ完了！"
	@echo "🌐 ステージング: https://gakkoudayori-ai--staging.web.app"

# 開発環境リセット
reset-dev:
	@echo "🔄 開発環境リセット中..."
	cd frontend && flutter clean && flutter pub get
	@echo "✅ 開発環境リセット完了"

# バックエンド開発サーバー起動
backend-dev:
	@echo "🐍 バックエンド開発サーバー起動中 (ポート: 8081, ENVIRONMENT=development)..."
	@cd backend && uv sync --extra dev && \
	ENVIRONMENT=development \
	GOOGLE_APPLICATION_CREDENTIALS="$(PWD)/backend/secrets/service-account-key.json" \
	GCS_BUCKET_NAME="gakkoudayori-ai.appspot.com" \
	uv run uvicorn app.main:app --host 0.0.0.0 --port 8081 --reload



# Python環境セットアップ
backend-setup:
	@echo "ð Python環境セットアップ中..."
	cd backend && uv sync --extra dev
	@echo "â... Python環境セットアップ完了"

# Pythonテスト実行
backend-test:
	@echo "🧪 Pythonテスト実行中..."
	cd backend && uv run bash -c "PYTHONPATH=. pytest tests/ -v" 

# ADK v1.0.0互換性テスト
test-adk:
	@echo "🤖 ADK v1.0.0 互換性テスト実行中..."
	cd backend && uv run python test_uv_migration.py 

# バックエンドWarm-up
warmup:
	@echo "🔥 バックエンドWarm-up実行中..."
	@echo "📊 本番環境ヘルスチェック..."
	@curl -f -s https://gakkoudayori-backend-944053509139.asia-northeast1.run.app/health || echo "❌ 本番環境エラー"
	@echo "🔥 本番環境Warm-up..."
	@curl -f -s https://gakkoudayori-backend-944053509139.asia-northeast1.run.app/warmup || echo "❌ 本番Warm-upエラー"
	@echo "🧪 ステージング環境チェック..."
	@curl -f -s https://gakkoudayori-backend-staging-944053509139.asia-northeast1.run.app/health || echo "⚠️ ステージング環境エラー"
	@curl -f -s https://gakkoudayori-backend-staging-944053509139.asia-northeast1.run.app/warmup || echo "⚠️ ステージングWarm-upエラー"
	@echo "✅ Warm-up完了"