#!/bin/bash
# ワンクリック並列開発環境起動スクリプト

echo "🚀 Phase 2ワンクリック並列開発環境起動"
echo "===================================="

PROJECT_ROOT="/Users/kamenonagare/yutorikyoshitu"
cd "$PROJECT_ROOT"

echo "ステップ1: 並列開発環境セットアップ..."
./scripts/setup_parallel_dev.sh

echo ""
echo "ステップ2: 実行権限設定..."
chmod +x scripts/start_parallel_agents.sh
chmod +x scripts/auto_start_claude_agents.sh

echo ""
echo "ステップ3: Claude Code並列エージェント自動起動..."
./scripts/auto_start_claude_agents.sh

echo ""
echo "🎉 Phase 2並列開発環境完全起動完了！"
echo ""
echo "📋 利用可能なコマンド:"
echo "  監視ダッシュボード: ./scripts/monitor_parallel_agents.sh"
echo "  セッション接続: tmux attach-session -t yutori-parallel"
echo ""
echo "🚀 並列実装が開始されました！各エージェントの進捗を監視してください。" 