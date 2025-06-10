#!/bin/bash

# E2Eテスト用のシンプルなFlutterアプリを起動するスクリプト
# Firebase依存関係のエラーをバイパスするため、最小構成で実行

# 現在のディレクトリを保存
CURRENT_DIR=$(pwd)

# 必要なディレクトリに移動
cd "$(dirname "$0")/.."

echo "🚀 E2Eテスト用の最小構成アプリをビルドします..."
flutter build web --web-port=8080 -t e2e/e2e_test.dart --dart-define=FLUTTER_WEB_USE_SKIA=true

echo "🌐 Webサーバーを起動しています..."
cd build/web
python3 -m http.server 8080 &
SERVER_PID=$!

echo "🔍 Playwrightでテストを実行します..."
cd ../../e2e
npx playwright test

# 終了時にサーバープロセスをクリーンアップ
echo "🧹 クリーンアップ中..."
kill $SERVER_PID

# 元のディレクトリに戻る
cd "$CURRENT_DIR"

echo "✅ テスト完了しました"
