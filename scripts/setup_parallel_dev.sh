#!/bin/bash
# 並列AI開発環境セットアップスクリプト (Phase 2対応)

set -e

PROJECT_ROOT="/Users/kamenonagare/yutorikyoshitu"
PROJECT_NAME="yutorikyoshitu"

# ログ関数
log_info() { echo "ℹ️  $1"; }
log_success() { echo "✅ $1"; }
log_warning() { echo "⚠️  $1"; }
log_error() { echo "❌ $1"; }

# 並列タスクの定義（Phase 2中心）
TASKS=(
    "quill-html:T2-QU-001-A:Quill.js HTMLファイル作成:feat/quill-html-base:45"
    "webview-integration:T2-QU-002-A:WebView Flutter統合:feat/webview-integration:55"
    "gemini-api:T3-AI-002-A:Gemini API基盤実装:feat/gemini-api-client:50"
)

echo "🚀 Phase 2並列AI開発環境セットアップ"
echo "===================================="

# Git Worktreeの作成
setup_worktrees() {
    log_info "Git Worktreeを設定中..."
    
    # 既存のworktreeをクリーンアップ
    git worktree prune 2>/dev/null || true
    
    for task_def in "${TASKS[@]}"; do
        IFS=':' read -r task_key task_id description branch_name duration <<< "$task_def"
        
        worktree_path="../${PROJECT_NAME}-${task_key}"
        
        # 既存のworktreeディレクトリを削除
        if [[ -d "$worktree_path" ]]; then
            log_warning "既存のworktree削除: $worktree_path"
            rm -rf "$worktree_path"
        fi
        
        # 既存のブランチを削除（存在する場合）
        if git show-ref --verify --quiet refs/heads/"$branch_name"; then
            log_warning "既存のブランチ削除: $branch_name"
            git branch -D "$branch_name" 2>/dev/null || true
        fi
        
        # 新しいworktreeを作成
        log_info "Worktree作成: $task_id ($description)"
        git worktree add "$worktree_path" -b "$branch_name"
        
        log_success "Worktree作成完了: $worktree_path"
    done
    
    log_success "全てのWorktreeが作成されました"
    git worktree list
}

# Tmux セッションの作成
setup_tmux_sessions() {
    log_info "Tmux セッションを設定中..."
    
    session_name="yutori-parallel"
    
    # 既存セッションを終了
    if tmux has-session -t "$session_name" 2>/dev/null; then
        log_warning "既存のセッション終了: $session_name"
        tmux kill-session -t "$session_name"
    fi
    
    # 新しいセッションを作成
    tmux new-session -d -s "$session_name" -c "$PROJECT_ROOT"
    tmux rename-window -t "$session_name:0" "main"
    
    # メインウィンドウにダッシュボード表示
    tmux send-keys -t "$session_name:main" "clear" Enter
    tmux send-keys -t "$session_name:main" "echo '🚀 Phase 2並列AI開発セッション開始'" Enter
    tmux send-keys -t "$session_name:main" "echo '================================'" Enter
    tmux send-keys -t "$session_name:main" "echo '使用方法:'" Enter
    tmux send-keys -t "$session_name:main" "echo '1. C-b 1-3 で各エージェントウィンドウに移動'" Enter
    tmux send-keys -t "$session_name:main" "echo '2. 上ペインでClaude Code起動 (claude)'" Enter
    tmux send-keys -t "$session_name:main" "echo '3. 下ペインで開発サーバー/テスト実行'" Enter
    tmux send-keys -t "$session_name:main" "echo ''" Enter
    
    # 各タスク用のウィンドウを作成
    window_index=1
    for task_def in "${TASKS[@]}"; do
        IFS=':' read -r task_key task_id description branch_name duration <<< "$task_def"
        
        worktree_path="../${PROJECT_NAME}-${task_key}"
        window_name="${task_key}-agent"
        
        # 新しいウィンドウを作成
        tmux new-window -t "$session_name:$window_index" -c "$worktree_path" -n "$window_name"
        
        # 垂直分割してペインを作成
        tmux split-window -t "$session_name:$window_name" -v -c "$worktree_path"
        
        # 上ペイン: Claude Code実行準備
        tmux send-keys -t "$session_name:$window_name.0" "clear" Enter
        tmux send-keys -t "$session_name:$window_name.0" "echo '📋 $task_id: $description ($duration分)'" Enter
        tmux send-keys -t "$session_name:$window_name.0" "echo 'Branch: $branch_name'" Enter
        tmux send-keys -t "$session_name:$window_name.0" "echo 'Directory: $worktree_path'" Enter
        tmux send-keys -t "$session_name:$window_name.0" "echo ''" Enter
        tmux send-keys -t "$session_name:$window_name.0" "echo '🤖 Claude Code起動: claude'" Enter
        tmux send-keys -t "$session_name:$window_name.0" "echo ''" Enter
        
        # 下ペイン: 開発サーバー/テスト実行用
        tmux send-keys -t "$session_name:$window_name.1" "clear" Enter
        
        case $task_key in
            "quill-html")
                tmux send-keys -t "$session_name:$window_name.1" "echo '🌐 HTML/CSS/JS開発:'" Enter
                tmux send-keys -t "$session_name:$window_name.1" "echo 'open web/quill/index.html (プレビュー)'" Enter
                ;;
            "webview-integration") 
                tmux send-keys -t "$session_name:$window_name.1" "echo '📱 Flutter WebView開発:'" Enter
                tmux send-keys -t "$session_name:$window_name.1" "echo 'cd frontend && flutter run -d chrome'" Enter
                ;;
            "gemini-api")
                tmux send-keys -t "$session_name:$window_name.1" "echo '🔧 API テスト:'" Enter
                tmux send-keys -t "$session_name:$window_name.1" "echo 'cd backend/functions && python -m pytest'" Enter
                ;;
        esac
        
        ((window_index++))
    done
    
    # メインウィンドウに戻る
    tmux select-window -t "$session_name:0"
    
    log_success "Tmuxセッション '$session_name' が作成されました"
}

# Claude Code用の設定ファイル作成
setup_claude_configs() {
    log_info "Claude Code設定を作成中..."
    
    for task_def in "${TASKS[@]}"; do
        IFS=':' read -r task_key task_id description branch_name duration <<< "$task_def"
        
        worktree_path="../${PROJECT_NAME}-${task_key}"
        claude_md="$worktree_path/CLAUDE.md"
        
        # 各worktree用のCLAUDE.mdを作成
        cat > "$claude_md" << EOF
# $task_id: $description

## 🎯 タスク概要
- **ID**: $task_id
- **説明**: $description  
- **予想時間**: $duration分
- **TDD要件**: Red→Green→Refactor
- **Git Branch**: $branch_name

## 🔥 実行指示
1. **docs/tasks.md**で詳細な完了条件を確認
2. **関連仕様書を読み込み**、実装計画を立てる
3. **テストを先に実装**する (Red Phase)
4. **最小限の実装**でテストを通す (Green Phase)  
5. **リファクタリング**で品質向上 (Blue Phase)
6. **完了後、docs/tasks.mdのチェックボックス更新**

## 📂 プロジェクト構造
- **Frontend**: Flutter Web (lib/以下)
- **Backend**: Python Flask (backend/functions/以下)
- **Tests**: Dart/Python テストファイル

## ⚙️ 重要な設定
- **Git branch**: $branch_name
- **Base directory**: $worktree_path
- **TDD必須**: 全ての機能にテストを書く

## 📋 関連ファイル
- **タスク詳細**: docs/tasks.md  
- **API仕様**: docs/30_API_endpoints.md
- **設計仕様**: docs/20_SPEC_*.md

タスクを開始してください！
EOF

        log_success "Claude設定作成: $claude_md"
    done
}

# メイン実行
main() {
    cd "$PROJECT_ROOT"
    
    echo ""
    setup_worktrees
    echo ""
    setup_claude_configs
    echo ""
    setup_tmux_sessions
    echo ""
    
    echo "🎉 Phase 2並列開発環境セットアップ完了！"
    echo ""
    echo "📍 次のステップ:"
    echo "1. 監視ダッシュボード起動: ./scripts/monitor_parallel_agents.sh"
    echo "2. セッション接続: tmux attach-session -t yutori-parallel"
    echo "3. 各ウィンドウでClaude Code起動: claude"
    echo ""
    echo "🚀 効率的な並列実装をお楽しみください！"
}

main "$@" 