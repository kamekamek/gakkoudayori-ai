#!/bin/bash

# Playwright Code Generation用のスクリプト

echo "🎬 Playwright Code Generation を開始します"
echo "ブラウザが開いたら、実際にUIを操作してください。"
echo "操作が完了したら、Playwrightウィンドウを閉じてください。"
echo ""

# Flutter Webアプリが起動しているかチェック
if ! curl -s http://localhost:8080 > /dev/null; then
    echo "⚠️  Flutter Webアプリが http://localhost:8080 で起動していません"
    echo "別ターミナルで以下を実行してください："
    echo "cd frontend && flutter run -d chrome --web-port 8080"
    exit 1
fi

echo "✅ Flutter Webアプリが起動中です"
echo ""

# レコーディング開始
echo "🎥 レコーディングを開始します..."

# 日時を含むファイル名を生成
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
OUTPUT_FILE="e2e/tests/recorded_${TIMESTAMP}.spec.js"

npx playwright codegen \
    --target=javascript \
    --output="$OUTPUT_FILE" \
    --browser=chromium \
    --viewport-size=1280,720 \
    http://localhost:8080

echo ""
echo "✅ レコーディング完了！"
echo "📁 生成されたテストファイル: $OUTPUT_FILE"
echo ""
echo "🔍 生成されたテストを確認："
echo "cat $OUTPUT_FILE"
echo ""
echo "🚀 テストを実行："
echo "npm run test:e2e $OUTPUT_FILE"