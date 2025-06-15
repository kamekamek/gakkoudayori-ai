#!/bin/bash

# 🚀 学級通信エディタ - デプロイスクリプト
# 使用方法: ./scripts/deploy.sh [環境] [対象]
# 環境: dev, staging, prod
# 対象: frontend, backend, all

set -e  # エラー時に停止

# 色付きメッセージ用の関数
print_info() {
    echo -e "\033[34m[INFO]\033[0m $1"
}

print_success() {
    echo -e "\033[32m[SUCCESS]\033[0m $1"
}

print_error() {
    echo -e "\033[31m[ERROR]\033[0m $1"
}

print_warning() {
    echo -e "\033[33m[WARNING]\033[0m $1"
}

# ヘルプメッセージ
show_help() {
    echo "🚀 学級通信エディタ - デプロイスクリプト"
    echo ""
    echo "使用方法:"
    echo "  ./scripts/deploy.sh [環境] [対象]"
    echo ""
    echo "環境:"
    echo "  dev      - 開発環境（ローカル起動）"
    echo "  staging  - ステージング環境"
    echo "  prod     - 本番環境"
    echo ""
    echo "対象:"
    echo "  frontend - フロントエンドのみ"
    echo "  backend  - バックエンドのみ"
    echo "  all      - フロントエンド・バックエンド両方"
    echo ""
    echo "例:"
    echo "  ./scripts/deploy.sh prod all      # 本番環境に全体デプロイ"
    echo "  ./scripts/deploy.sh staging frontend  # ステージング環境にフロントエンドのみ"
    echo "  ./scripts/deploy.sh dev all       # 開発環境で起動"
}

# 引数チェック
if [ $# -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_help
    exit 0
fi

ENVIRONMENT=${1:-prod}
TARGET=${2:-all}

print_info "デプロイ開始: 環境=$ENVIRONMENT, 対象=$TARGET"

# 環境変数の設定
case $ENVIRONMENT in
    "dev")
        API_URL="https://yutori-api-dev.a.run.app"
        ;;
    "staging")
        API_URL="https://yutori-api-dev.a.run.app"
        ;;
    "prod")
        API_URL="https://yutori-api.a.run.app"
        ;;
    *)
        print_error "無効な環境: $ENVIRONMENT"
        show_help
        exit 1
        ;;
esac

# 事前チェック関数
check_prerequisites() {
    print_info "事前チェック実行中..."
    
    # 必要なツールの確認
    local tools=("flutter" "firebase" "gcloud" "docker")
    for tool in "${tools[@]}"; do
        if ! command -v $tool &> /dev/null; then
            print_error "$tool がインストールされていません"
            exit 1
        fi
    done
    
    # Google Cloud認証確認
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q "@"; then
        print_error "Google Cloud認証が必要です: gcloud auth login"
        exit 1
    fi
    
    # Firebase認証確認
    if ! firebase projects:list > /dev/null 2>&1; then
        print_error "Firebase認証が必要です: firebase login"
        exit 1
    fi
    
    # プロジェクト設定確認
    local current_project=$(gcloud config get-value project 2>/dev/null)
    if [ "$current_project" != "gakkoudayori-ai" ]; then
        print_warning "Google Cloudプロジェクトを設定中..."
        gcloud config set project gakkoudayori-ai
    fi
    
    print_success "事前チェック完了"
}

# APIキーの確認
check_api_keys() {
    print_info "APIキー設定確認中..."
    
    if [ -z "$GEMINI_API_KEY" ]; then
        print_error "GEMINI_API_KEY環境変数が設定されていません"
        print_info "以下のコマンドで設定してください:"
        print_info "export GEMINI_API_KEY=your_api_key_here"
        exit 1
    fi
    
    if [ -z "$SPEECH_TO_TEXT_API_KEY" ]; then
        print_warning "SPEECH_TO_TEXT_API_KEY環境変数が設定されていません"
        print_info "音声機能を使用する場合は設定してください:"
        print_info "export SPEECH_TO_TEXT_API_KEY=your_api_key_here"
    fi
    
    print_success "APIキー確認完了"
}

# バックエンドデプロイ
deploy_backend() {
    print_info "バックエンドデプロイ開始..."
    
    cd backend
    
    # Dockerイメージのビルド
    print_info "Dockerイメージビルド中..."
    gcloud builds submit --tag gcr.io/your-project-id/yutori-api
    
    # Cloud Runにデプロイ
    local service_name="yutori-api"
    if [ "$ENVIRONMENT" = "staging" ]; then
        service_name="yutori-api-dev"
    fi
    
    print_info "Cloud Runにデプロイ中..."
    gcloud run deploy $service_name \
        --image gcr.io/your-project-id/yutori-api \
        --platform managed \
        --region asia-northeast1 \
        --allow-unauthenticated \
        --port 8080 \
        --set-env-vars GEMINI_API_KEY="$GEMINI_API_KEY",SPEECH_TO_TEXT_API_KEY="$SPEECH_TO_TEXT_API_KEY"
    
    cd ..
    print_success "バックエンドデプロイ完了"
}

# フロントエンドデプロイ
deploy_frontend() {
    print_info "フロントエンドデプロイ開始..."
    
    cd frontend
    
    # 依存関係の取得
    print_info "依存関係取得中..."
    flutter pub get
    
    # ビルド
    print_info "フロントエンドビルド中..."
    local build_mode="--release"
    if [ "$ENVIRONMENT" = "dev" ]; then
        build_mode="--debug"
    fi
    
    flutter build web \
        --dart-define=ENVIRONMENT=$ENVIRONMENT \
        --dart-define=API_BASE_URL=$API_URL \
        --dart-define=GEMINI_API_KEY="$GEMINI_API_KEY" \
        --dart-define=SPEECH_TO_TEXT_API_KEY="$SPEECH_TO_TEXT_API_KEY" \
        $build_mode
    
    # デプロイ
    if [ "$ENVIRONMENT" = "dev" ]; then
        print_info "開発サーバー起動中..."
        flutter run -d chrome \
            --dart-define=ENVIRONMENT=$ENVIRONMENT \
            --dart-define=API_BASE_URL=$API_URL \
            --dart-define=GEMINI_API_KEY="$GEMINI_API_KEY" \
            --dart-define=SPEECH_TO_TEXT_API_KEY="$SPEECH_TO_TEXT_API_KEY"
    elif [ "$ENVIRONMENT" = "staging" ]; then
        print_info "ステージング環境にデプロイ中..."
        firebase hosting:channel:deploy staging --expires 30d
    else
        print_info "本番環境にデプロイ中..."
        firebase deploy --only hosting
    fi
    
    cd ..
    print_success "フロントエンドデプロイ完了"
}

# デプロイ後の確認
verify_deployment() {
    print_info "デプロイ確認中..."
    
    if [ "$ENVIRONMENT" != "dev" ]; then
        # バックエンドAPIの確認
        local backend_url
        if [ "$ENVIRONMENT" = "staging" ]; then
            backend_url="https://staging-yutori-backend.asia-northeast1.run.app"
        else
            backend_url="https://yutori-backend-944053509139.asia-northeast1.run.app"
        fi
        
        print_info "バックエンドAPI確認: $backend_url/health"
        if curl -f -s "$backend_url/health" > /dev/null; then
            print_success "バックエンドAPI正常"
        else
            print_warning "バックエンドAPIの応答に問題があります"
        fi
        
        # フロントエンドの確認
        local frontend_url
        if [ "$ENVIRONMENT" = "staging" ]; then
            frontend_url="https://gakkoudayori-ai--staging.web.app"
        else
            frontend_url="https://gakkoudayori-ai.web.app"
        fi
        
        print_info "フロントエンド確認: $frontend_url"
        if curl -f -s "$frontend_url" > /dev/null; then
            print_success "フロントエンド正常"
        else
            print_warning "フロントエンドの応答に問題があります"
        fi
    fi
    
    print_success "デプロイ確認完了"
}

# メイン処理
main() {
    print_info "🚀 学級通信エディタ デプロイスクリプト開始"
    print_info "環境: $ENVIRONMENT, 対象: $TARGET"
    
    # 事前チェック
    check_prerequisites
    
    # APIキー確認（開発環境以外）
    if [ "$ENVIRONMENT" != "dev" ]; then
        check_api_keys
    fi
    
    # デプロイ実行
    case $TARGET in
        "backend")
            if [ "$ENVIRONMENT" = "dev" ]; then
                print_info "開発環境でバックエンド起動中..."
                cd backend/functions && python main.py
            else
                deploy_backend
            fi
            ;;
        "frontend")
            deploy_frontend
            ;;
        "all")
            if [ "$ENVIRONMENT" = "dev" ]; then
                print_info "開発環境で全体起動中..."
                print_info "バックエンドを別ターミナルで起動してください: cd backend/functions && python main.py"
                deploy_frontend
            else
                deploy_backend
                deploy_frontend
            fi
            ;;
        *)
            print_error "無効な対象: $TARGET"
            show_help
            exit 1
            ;;
    esac
    
    # デプロイ後確認
    if [ "$ENVIRONMENT" != "dev" ]; then
        verify_deployment
    fi
    
    # 完了メッセージ
    print_success "🎉 デプロイ完了!"
    
    if [ "$ENVIRONMENT" = "staging" ]; then
        print_info "ステージング環境URL: https://gakkoudayori-ai--staging.web.app"
    elif [ "$ENVIRONMENT" = "prod" ]; then
        print_info "本番環境URL: https://gakkoudayori-ai.web.app"
    fi
}

# スクリプト実行
main "$@" 