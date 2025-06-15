#!/bin/bash

# 🔍 学級通信エディタ - 環境変数設定確認スクリプト

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

echo "🔍 環境変数設定確認スクリプト"
echo "================================"

# フロントエンド環境変数の確認
print_info "📱 フロントエンド環境変数:"
if [ -f "frontend/.env.development" ]; then
    print_success "✅ .env.development ファイル存在"
else
    print_error "❌ .env.development ファイルが見つかりません"
fi

if [ -f "frontend/.env.production" ]; then
    print_success "✅ .env.production ファイル存在"
else
    print_error "❌ .env.production ファイルが見つかりません"
fi

if [ -f "frontend/.env.staging" ]; then
    print_success "✅ .env.staging ファイル存在"
else
    print_warning "⚠️ .env.staging ファイルが見つかりません（オプション）"
fi

# バックエンド環境変数の確認
echo ""
print_info "🐍 バックエンド環境変数:"
if [ -f "backend/functions/.env" ]; then
    print_success "✅ .env ファイル存在"
else
    print_error "❌ .env ファイルが見つかりません"
fi

if [ -f "backend/functions/.env.development" ]; then
    print_success "✅ .env.development ファイル存在"
else
    print_warning "⚠️ .env.development ファイルが見つかりません（オプション）"
fi

if [ -f "backend/functions/.env.production" ]; then
    print_success "✅ .env.production ファイル存在"
else
    print_warning "⚠️ .env.production ファイルが見つかりません（オプション）"
fi

# 環境変数の確認
echo ""
print_info "🔑 環境変数設定:"
if [ -n "$GEMINI_API_KEY" ]; then
    print_success "✅ GEMINI_API_KEY 設定済み"
else
    print_error "❌ GEMINI_API_KEY 環境変数が設定されていません"
    print_info "   設定方法: export GEMINI_API_KEY=your_api_key_here"
fi

if [ -n "$SPEECH_TO_TEXT_API_KEY" ]; then
    print_success "✅ SPEECH_TO_TEXT_API_KEY 設定済み"
else
    print_warning "⚠️ SPEECH_TO_TEXT_API_KEY 環境変数が設定されていません"
    print_info "   設定方法: export SPEECH_TO_TEXT_API_KEY=your_api_key_here"
fi

# Google Cloud認証確認
echo ""
print_info "☁️ Google Cloud認証:"
if gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q "@"; then
    print_success "✅ Google Cloud認証済み"
    local current_project=$(gcloud config get-value project 2>/dev/null)
    if [ "$current_project" = "gakkoudayori-ai" ]; then
        print_success "✅ プロジェクト設定: $current_project"
    else
        print_warning "⚠️ プロジェクト設定: $current_project (推奨: gakkoudayori-ai)"
    fi
else
    print_error "❌ Google Cloud認証が必要です"
    print_info "   認証方法: gcloud auth login"
fi

# Firebase認証確認
echo ""
print_info "🔥 Firebase認証:"
if firebase projects:list > /dev/null 2>&1; then
    print_success "✅ Firebase認証済み"
else
    print_error "❌ Firebase認証が必要です"
    print_info "   認証方法: firebase login"
fi

# 必要なツールの確認
echo ""
print_info "🛠️ 必要ツール確認:"
local tools=("flutter" "firebase" "gcloud" "docker" "make")
for tool in "${tools[@]}"; do
    if command -v $tool &> /dev/null; then
        local version=$($tool --version 2>/dev/null | head -n1 || echo "バージョン不明")
        print_success "✅ $tool インストール済み"
    else
        if [ "$tool" = "make" ]; then
            print_warning "⚠️ $tool 未インストール（オプション）"
        else
            print_error "❌ $tool 未インストール"
        fi
    fi
done

# Google Cloud APIの有効化確認
echo ""
print_info "🔌 Google Cloud API確認:"
local apis=("generativelanguage.googleapis.com" "speech.googleapis.com" "run.googleapis.com" "cloudbuild.googleapis.com")
for api in "${apis[@]}"; do
    if gcloud services list --enabled --filter="name:$api" --format="value(name)" | grep -q "$api"; then
        print_success "✅ $api 有効化済み"
    else
        print_error "❌ $api 未有効化"
        print_info "   有効化方法: gcloud services enable $api"
    fi
done

# 推奨設定の確認
echo ""
print_info "📋 推奨設定確認:"

# .gitignoreの確認
if grep -q "\.env" .gitignore 2>/dev/null; then
    print_success "✅ .gitignore に環境変数ファイルが設定済み"
else
    print_warning "⚠️ .gitignore に環境変数ファイルの除外設定を追加することを推奨"
fi

# ファイル権限の確認
if [ -f "frontend/.env.production" ]; then
    local perm=$(stat -f "%A" frontend/.env.production 2>/dev/null || echo "不明")
    if [ "$perm" = "600" ]; then
        print_success "✅ 環境変数ファイルの権限設定適切"
    else
        print_warning "⚠️ 環境変数ファイルの権限を制限することを推奨: chmod 600 frontend/.env.*"
    fi
fi

echo ""
print_info "🎯 確認完了"

# 問題がある場合の対処法表示
echo ""
print_info "📝 次のステップ:"
print_info "1. 不足している環境変数ファイルを作成"
print_info "2. APIキーを取得して環境変数に設定"
print_info "3. 必要なツールをインストール"
print_info "4. Google Cloud / Firebase認証を実行"
print_info "5. 必要なAPIを有効化"
print_info ""
print_info "詳細な設定方法は docs/environment_setup.md を参照してください" 