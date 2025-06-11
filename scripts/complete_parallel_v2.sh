#!/bin/bash
# Phase 2並列開発環境v2.0 ワンクリック完全実行

set -e

PROJECT_ROOT="/Users/kamenonagare/yutorikyoshitu"

echo "🚀 Phase 2並列開発環境v2.0 ワンクリック起動"
echo "==========================================="
echo ""
echo "Claude-Code-Communication手法統合"
echo "Git worktree + Claude Code完全自動化"
echo ""

cd "$PROJECT_ROOT"

# 実行権限設定
echo "🔧 実行権限設定中..."
chmod +x scripts/*.sh
echo "✅ 実行権限設定完了"
echo ""

# Step 1: 完全初期化
echo "🧹 Step 1: 環境完全初期化中..."
./scripts/clean_parallel_env.sh
echo ""

# Step 2: v2.0環境セットアップ
echo "🏗️  Step 2: v2.0環境セットアップ中..."
./scripts/setup_parallel_v2.sh
echo ""

# Step 3: Claude Code段階起動
echo "🤖 Step 3: Claude Code段階起動中..."
./scripts/start_claude_sequential.sh
echo ""

# Step 4: 監視システム案内
echo "📊 Step 4: 監視システム準備完了"
echo "=============================="
echo ""
echo "🎉 Phase 2並列開発環境v2.0起動完了！"
echo ""
echo "📋 利用可能なコマンド："
echo ""
echo "【監視・管理】"
echo "  監視ダッシュボード:      ./scripts/monitor_integration.sh"
echo "  エージェント通信:        ./scripts/agent_communication.sh"
echo "  エージェント状態確認:    ./scripts/agent_communication.sh --status"
echo ""
echo "【エージェント制御】"
echo "  WebView統合手動起動:     ./scripts/start_claude_sequential.sh --webview"
echo "  起動状況確認:            ./scripts/start_claude_sequential.sh --status"
echo ""
echo "【Tmux操作】"
echo "  セッション接続:          tmux attach-session -t yutori-parallel"
echo "  セッション一覧:          tmux list-sessions"
echo ""
echo "【通信・通知】"
echo "  メッセージ送信例:        ./scripts/agent_communication.sh quill-html-agent '作業状況はいかがですか？'"
echo "  タスク完了通知:          ./scripts/agent_communication.sh --notify T2-QU-001-A"
echo ""
echo "🚀 実行中のエージェント："
echo "  🎨 quill-html-agent      (T2-QU-001-A: Quill.js HTMLファイル作成)"
echo "  🤖 gemini-api-agent      (T3-AI-002-A: Gemini API基盤実装)"
echo "  ⏳ webview-integration-agent (T2-QU-002-A: 待機中)"
echo ""
echo "📈 Phase 2期待される成果："
echo "  ✅ web/quill/index.html"
echo "  ✅ backend/functions/services/gemini_client.py"
echo "  ✅ Flutter WebView統合"
echo ""
echo "🎯 並列実装が開始されました！各エージェントの進捗を監視してください。"
echo ""

# 監視ダッシュボード自動起動オプション
echo -n "監視ダッシュボードを自動起動しますか？ [y/N]: "
read -r choice

if [[ "$choice" =~ ^[Yy]$ ]]; then
    echo ""
    echo "📊 監視ダッシュボードを起動中..."
    sleep 2
    ./scripts/monitor_integration.sh
fi 