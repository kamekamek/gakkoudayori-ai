#!/bin/bash
# 統合監視ダッシュボード (Phase 2対応)

set -e

SESSION_NAME="yutori-parallel"
PROJECT_ROOT="/Users/kamenonagare/yutorikyoshitu"
PROJECT_NAME="yutorikyoshitu"

# 監視対象タスク
TASKS=(
    "quill-html:T2-QU-001-A:Quill.js HTMLファイル作成:PRIORITY"
    "gemini-api:T3-AI-002-A:Gemini API基盤実装:PARALLEL"
    "webview-integration:T2-QU-002-A:WebView Flutter統合:DEPENDENT"
)

# ダッシュボード表示
show_dashboard() {
    clear
    echo "🚀 Phase 2並列AI開発 統合監視ダッシュボード"
    echo "=============================================="
    echo "更新時刻: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    
    # 全体進捗概要
    show_overall_progress
    echo ""
    
    # 各エージェント詳細
    for task_def in "${TASKS[@]}"; do
        IFS=':' read -r task_key task_id description priority <<< "$task_def"
        show_agent_detail "$task_key" "$task_id" "$description" "$priority"
        echo ""
    done
    
    # 通信ログ
    show_communication_log
    echo ""
    
    # 操作メニュー
    show_operation_menu
}

# 全体進捗概要
show_overall_progress() {
    echo "📊 全体進捗概要"
    echo "=================="
    
    local total_tasks=3
    local completed_tasks=0
    local running_tasks=0
    local pending_tasks=0
    
    for task_def in "${TASKS[@]}"; do
        IFS=':' read -r task_key task_id description priority <<< "$task_def"
        local status=$(get_task_status "$task_key")
        
        case $status in
            "COMPLETED") ((completed_tasks++)) ;;
            "RUNNING") ((running_tasks++)) ;;
            "PENDING") ((pending_tasks++)) ;;
        esac
    done
    
    local progress_percent=$((completed_tasks * 100 / total_tasks))
    
    echo "  🎯 完了: $completed_tasks/$total_tasks タスク ($progress_percent%)"
    echo "  🚀 実行中: $running_tasks タスク"
    echo "  ⏳ 待機中: $pending_tasks タスク"
    
    # プログレスバー
    local bar_length=30
    local filled=$((progress_percent * bar_length / 100))
    local empty=$((bar_length - filled))
    
    printf "  進捗: ["
    printf "%*s" $filled | tr ' ' '█'
    printf "%*s" $empty | tr ' ' '░'
    printf "] %d%%\n" $progress_percent
}

# エージェント詳細表示
show_agent_detail() {
    local task_key=$1
    local task_id=$2
    local description=$3
    local priority=$4
    
    local worktree_path="../${PROJECT_NAME}-${task_key}"
    local status=$(get_task_status "$task_key")
    local status_icon=$(get_status_icon "$status")
    
    echo "$status_icon Agent: $task_key ($priority)"
    echo "────────────────────────────────────────────────"
    echo "  📋 タスク: $task_id"
    echo "  📝 説明: $description"
    echo "  📍 状態: $status"
    
    if [[ -d "$worktree_path" ]]; then
        cd "$worktree_path"
        
        local branch=$(git branch --show-current)
        local commits=$(git rev-list HEAD --count 2>/dev/null || echo "0")
        local modified=$(git status --porcelain | wc -l)
        local last_commit=$(git log -1 --format="%h %s" 2>/dev/null || echo "No commits")
        
        echo "  🌿 ブランチ: $branch"
        echo "  📝 コミット数: $commits"
        echo "  🔄 変更ファイル: $modified"
        echo "  📜 最終コミット: $last_commit"
        
        # TDDフェーズ検出
        local tdd_phase=$(detect_tdd_phase "$worktree_path")
        if [[ -n "$tdd_phase" ]]; then
            echo "  🔴🟢🔵 TDDフェーズ: $tdd_phase"
        fi
        
        # 成果物確認
        check_deliverables "$task_key"
        
        cd - > /dev/null
    else
        echo "  ❌ Worktreeが見つかりません: $worktree_path"
    fi
}

# タスク状態取得
get_task_status() {
    local task_key=$1
    local worktree_path="../${PROJECT_NAME}-${task_key}"
    
    if [[ ! -d "$worktree_path" ]]; then
        echo "ERROR"
        return
    fi
    
    cd "$worktree_path"
    
    # コミット数による状態判定
    local commits=$(git rev-list HEAD --count 2>/dev/null || echo "0")
    local modified=$(git status --porcelain | wc -l)
    
    if [[ $commits -gt 5 && $modified -eq 0 ]]; then
        echo "COMPLETED"
    elif [[ $commits -gt 0 || $modified -gt 0 ]]; then
        echo "RUNNING"
    else
        echo "PENDING"
    fi
    
    cd - > /dev/null
}

# 状態アイコン取得
get_status_icon() {
    local status=$1
    
    case $status in
        "COMPLETED") echo "✅" ;;
        "RUNNING") echo "🚀" ;;
        "PENDING") echo "⏳" ;;
        "ERROR") echo "❌" ;;
        *) echo "❓" ;;
    esac
}

# TDDフェーズ検出
detect_tdd_phase() {
    local worktree_path=$1
    
    cd "$worktree_path"
    
    # 最新コミットメッセージから判定
    local latest_commit=$(git log -1 --format="%s" 2>/dev/null || echo "")
    
    if [[ "$latest_commit" =~ "Red|red|RED|test.*fail|fail.*test" ]]; then
        echo "🔴 RED (テスト作成)"
    elif [[ "$latest_commit" =~ "Green|green|GREEN|test.*pass|pass.*test" ]]; then
        echo "🟢 GREEN (実装)"
    elif [[ "$latest_commit" =~ "Blue|blue|BLUE|refactor|Refactor|REFACTOR" ]]; then
        echo "🔵 BLUE (リファクタリング)"
    fi
    
    cd - > /dev/null
}

# 成果物確認
check_deliverables() {
    local task_key=$1
    
    case $task_key in
        "quill-html")
            if [[ -f "web/quill/index.html" ]]; then
                echo "  📄 成果物: web/quill/index.html ✅"
            else
                echo "  📄 成果物: web/quill/index.html ⏳"
            fi
            ;;
        "gemini-api")
            if [[ -f "backend/functions/services/gemini_client.py" ]]; then
                echo "  📄 成果物: backend/functions/services/gemini_client.py ✅"
            else
                echo "  📄 成果物: backend/functions/services/gemini_client.py ⏳"
            fi
            ;;
        "webview-integration")
            if [[ -f "lib/features/editor/presentation/widgets/webview_editor.dart" ]]; then
                echo "  📄 成果物: lib/features/editor/presentation/widgets/webview_editor.dart ✅"
            else
                echo "  📄 成果物: lib/features/editor/presentation/widgets/webview_editor.dart ⏳"
            fi
            ;;
    esac
}

# 通信ログ表示
show_communication_log() {
    echo "💬 エージェント間通信ログ (最新5件)"
    echo "=================================="
    
    if [[ -f "logs/agent_communication.log" ]]; then
        tail -5 "logs/agent_communication.log" | while read line; do
            echo "  $line"
        done
    else
        echo "  ℹ️  通信ログはまだありません"
    fi
}

# 操作メニュー
show_operation_menu() {
    echo "⚙️  操作メニュー"
    echo "================"
    echo "  [r] 画面更新"
    echo "  [s] エージェント状態確認"
    echo "  [c] エージェント通信"
    echo "  [t] Tmuxセッション接続"
    echo "  [q] 終了"
    echo ""
    echo -n "選択してください: "
}

# 対話型操作
interactive_mode() {
    while true; do
        show_dashboard
        
        read -n 1 -r choice
        echo ""
        
        case $choice in
            'r'|'R')
                # 画面更新（ループ継続）
                ;;
            's'|'S')
                echo ""
                ./scripts/agent_communication.sh --status
                echo ""
                echo "Enterキーで戻る..."
                read
                ;;
            'c'|'C')
                echo ""
                ./scripts/agent_communication.sh --list
                echo ""
                echo "Enterキーで戻る..."
                read
                ;;
            't'|'T')
                echo ""
                echo "Tmuxセッションに接続します..."
                tmux attach-session -t "$SESSION_NAME"
                ;;
            'q'|'Q')
                echo ""
                echo "監視を終了します"
                exit 0
                ;;
            *)
                echo ""
                echo "無効な選択です"
                sleep 1
                ;;
        esac
    done
}

# 自動更新モード
auto_update_mode() {
    local interval=${1:-30}
    
    echo "🔄 自動更新モード開始 (${interval}秒間隔)"
    echo "Ctrl+C で終了"
    echo ""
    
    while true; do
        show_dashboard
        echo ""
        echo "次回更新まで ${interval}秒... (Ctrl+C で終了)"
        sleep "$interval"
    done
}

# 使用方法表示
show_usage() {
    echo "📊 統合監視ダッシュボード"
    echo "========================"
    echo ""
    echo "使用方法:"
    echo "  $0                    # 対話型監視"
    echo "  $0 --auto [秒]       # 自動更新監視 (デフォルト: 30秒)"
    echo "  $0 --once            # 1回だけ表示"
    echo ""
    echo "機能:"
    echo "  - リアルタイム進捗監視"
    echo "  - TDDフェーズ検出"
    echo "  - エージェント間通信ログ"
    echo "  - 成果物確認"
    echo ""
}

# メイン処理
main() {
    cd "$PROJECT_ROOT"
    
    case "${1:-}" in
        "--auto")
            auto_update_mode "${2:-30}"
            ;;
        "--once")
            show_dashboard
            ;;
        "--help"|"-h")
            show_usage
            ;;
        "")
            interactive_mode
            ;;
        *)
            echo "❌ 不明なオプション: $1"
            show_usage
            exit 1
            ;;
    esac
}

main "$@" 