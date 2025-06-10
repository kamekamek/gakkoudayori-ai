#!/bin/bash
# 並列エージェント監視スクリプト (Phase 2対応)

PROJECT_NAME="yutorikyoshitu"

check_agent_progress() {
    local task_key=$1
    local worktree_path="../${PROJECT_NAME}-${task_key}"
    
    if [[ ! -d "$worktree_path" ]]; then
        echo "❌ Worktree not found: $task_key"
        return 1
    fi
    
    cd "$worktree_path"
    
    # Git状況確認
    local branch=$(git branch --show-current)
    local commits=$(git rev-list HEAD --count 2>/dev/null || echo "0")
    local modified=$(git status --porcelain | wc -l)
    local last_commit=$(git log -1 --format="%h %s" 2>/dev/null || echo "No commits")
    
    echo "📋 Agent: $task_key"
    echo "  Branch: $branch"
    echo "  Commits: $commits"
    echo "  Modified files: $modified"
    echo "  Last commit: $last_commit"
    echo ""
    
    cd - > /dev/null
}

# メイン監視ループ
while true; do
    clear
    echo "🚀 Phase 2並列AI開発 監視ダッシュボード"
    echo "========================================"
    echo "更新時刻: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    
    # 各エージェントの状況確認
    for task in quill-html webview-integration gemini-api; do
        check_agent_progress "$task"
    done
    
    echo "📊 タスク進捗:"
    echo "  • T2-QU-001-A: Quill.js HTMLファイル作成 (45分)"
    echo "  • T2-QU-002-A: WebView Flutter統合 (55分)"
    echo "  • T3-AI-002-A: Gemini API基盤実装 (50分)"
    echo ""
    echo "🔄 30秒後に更新... (Ctrl+C で終了)"
    sleep 30
done 