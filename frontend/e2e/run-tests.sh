#!/bin/bash

# E2Eテスト実行スクリプト
# CI/CD環境でのテスト実行用

# エラー発生時に停止
set -e

# 作業ディレクトリを設定
cd "$(dirname "$0")"

# 必要なディレクトリを作成
mkdir -p e2e-results

# 依存関係をインストール
echo "📦 依存関係をインストール中..."
npm install

# ブラウザをインストール
echo "🌐 ブラウザをインストール中..."
npx playwright install --with-deps chromium

# テストを実行
echo "🧪 E2Eテストを実行中..."
CI=true npx playwright test --project=chromium

# テスト結果を表示
echo "📊 テスト結果レポート生成中..."
npx playwright show-report

echo "✅ E2Eテスト完了"
