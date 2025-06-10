#!/bin/bash
# 並列開発環境完全クリーンアップスクリプト

set -e

PROJECT_NAME="yutorikyoshitu"
SESSION_NAME="yutori-parallel"

echo "🧹 並列開発環境完全クリーンアップ開始"
echo "======================================"

# ログ関数
log_info() { echo "ℹ️  $1"; }
log_success() { echo "✅ $1"; }
log_warning() { echo "⚠️  $1"; }

# Tmuxセッション削除
cleanup_tmux_sessions() {
    log_info "Tmuxセッション削除中..."
    
    if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        tmux kill-session -t "$SESSION_NAME"
        log_success "セッション削除: $SESSION_NAME"
    else
        log_info "セッションが存在しません: $SESSION_NAME"
    fi
}

# Git worktree削除
cleanup_worktrees() {
    log_info "Git worktree削除中..."
    
    # worktreeリストを取得して削除
    git worktree list | grep -E "(quill-html|webview-integration|gemini-api)" | while read path hash branch; do
        if [[ -d "$path" ]]; then
            log_warning "Worktree削除: $path"
            rm -rf "$path"
        fi
    done
    
    # worktree情報をクリーンアップ
    git worktree prune
    log_success "全worktreeクリーンアップ完了"
}

# ブランチ削除
cleanup_branches() {
    log_info "並列開発用ブランチ削除中..."
    
    local branches=("feat/quill-html-base" "feat/webview-integration" "feat/gemini-api-client")
    
    for branch in "${branches[@]}"; do
        if git show-ref --verify --quiet refs/heads/"$branch"; then
            log_warning "ブランチ削除: $branch"
            git branch -D "$branch" 2>/dev/null || true
        fi
    done
    
    log_success "ブランチクリーンアップ完了"
}

# 一時ファイル削除
cleanup_temp_files() {
    log_info "一時ファイル削除中..."
    
    # 並列開発関連の一時ファイル削除
    rm -f logs/parallel_*.log 2>/dev/null || true
    rm -f tmp/agent_*.txt 2>/dev/null || true
    
    log_success "一時ファイルクリーンアップ完了"
}

# メイン実行
main() {
    echo ""
    cleanup_tmux_sessions
    echo ""
    cleanup_worktrees
    echo ""
    cleanup_branches
    echo ""
    cleanup_temp_files
    echo ""
    
    log_success "🎉 環境クリーンアップ完了！"
    echo ""
    echo "📋 次のステップ:"
    echo "  ./scripts/setup_parallel_v2.sh で新環境構築"
    echo ""
}

main "$@" 