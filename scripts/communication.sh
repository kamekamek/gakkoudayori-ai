#!/usr/bin/env bash
# ------------------------------------------------------------
#   communication.sh
#   オーケストレーター通信ライブラリ
#   Claude Code コマンド統合用
# ------------------------------------------------------------

# 色設定
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# ログ関数
log_comm() { echo -e "${CYAN}[COMM]${NC} $1"; }
log_send() { echo -e "${GREEN}[SEND]${NC} $1"; }
log_recv() { echo -e "${YELLOW}[RECV]${NC} $1"; }

# ペイン番号マッピング
# Pane 0,1,2: Parent1(Quill) + Child1-1,1-2
# Pane 3,4,5: Parent2(WebView) + Child2-1,2-2  
# Pane 6,7,8: Parent3(Gemini) + Child3-1,3-2

# 親エージェントペイン番号取得
get_parent_pane() {
    local parent_id=$1
    case "$parent_id" in
        1) echo 0 ;;  # Parent1 (Quill)
        2) echo 3 ;;  # Parent2 (WebView)
        3) echo 6 ;;  # Parent3 (Gemini)
        *) echo -1 ;;
    esac
}

# 子エージェントペイン番号取得
get_child_pane() {
    local parent_id=$1
    local child_num=$2
    case "${parent_id}-${child_num}" in
        "1-1") echo 1 ;;  # Child1-1 (HTML)
        "1-2") echo 2 ;;  # Child1-2 (JS)
        "2-1") echo 4 ;;  # Child2-1 (Flutter)
        "2-2") echo 5 ;;  # Child2-2 (Bridge)
        "3-1") echo 7 ;;  # Child3-1 (API)
        "3-2") echo 8 ;;  # Child3-2 (Response)
        *) echo -1 ;;
    esac
}

# エージェント名取得
get_agent_name() {
    local parent_id=$1
    local child_num=$2
    
    if [[ -z "$child_num" ]]; then
        # 親エージェント
        case "$parent_id" in
            1) echo "Parent1(Quill)" ;;
            2) echo "Parent2(WebView)" ;;  
            3) echo "Parent3(Gemini)" ;;
            *) echo "Unknown" ;;
        esac
    else
        # 子エージェント
        case "${parent_id}-${child_num}" in
            "1-1") echo "Child1-1(HTML)" ;;
            "1-2") echo "Child1-2(JS)" ;;
            "2-1") echo "Child2-1(Flutter)" ;;
            "2-2") echo "Child2-2(Bridge)" ;;
            "3-1") echo "Child3-1(API)" ;;
            "3-2") echo "Child3-2(Response)" ;;
            *) echo "Unknown" ;;
        esac
    fi
}

# オーケストレーター → 親エージェント送信
send_to_parent() {
    local parent_id=$1
    local command=$2
    local pane_id=$(get_parent_pane "$parent_id")
    local agent_name=$(get_agent_name "$parent_id")
    
    if [[ "$pane_id" == -1 ]]; then
        echo -e "${RED}[ERROR]${NC} 無効な親ID: $parent_id"
        return 1
    fi
    
    if ! tmux has-session -t orchestrator 2>/dev/null; then
        echo -e "${RED}[ERROR]${NC} orchestratorセッションが見つかりません"
        return 1
    fi
    
    # コマンド送信
    tmux send-keys -t orchestrator:0.$pane_id "$command" Enter
    log_send "[ORCHESTRATOR→$agent_name] $command"
    
    # ログ記録
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ORCHESTRATOR→$agent_name: $command" >> logs/orchestrator/communication.log
}

# オーケストレーター → 子エージェント送信
send_to_child() {
    local parent_id=$1
    local child_num=$2
    local command=$3
    local pane_id=$(get_child_pane "$parent_id" "$child_num")
    local agent_name=$(get_agent_name "$parent_id" "$child_num")
    
    if [[ "$pane_id" == -1 ]]; then
        echo -e "${RED}[ERROR]${NC} 無効な子ID: $parent_id-$child_num"
        return 1
    fi
    
    if ! tmux has-session -t orchestrator 2>/dev/null; then
        echo -e "${RED}[ERROR]${NC} orchestratorセッションが見つかりません"
        return 1
    fi
    
    # コマンド送信
    tmux send-keys -t orchestrator:0.$pane_id "$command" Enter
    log_send "[ORCHESTRATOR→$agent_name] $command"
    
    # ログ記録
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ORCHESTRATOR→$agent_name: $command" >> logs/orchestrator/communication.log
}

# 親エージェント → 子エージェント送信（親から使用）
parent_send_to_child() {
    local parent_id=$1
    local child_num=$2
    local command=$3
    local pane_id=$(get_child_pane "$parent_id" "$child_num")
    local parent_name=$(get_agent_name "$parent_id")
    local child_name=$(get_agent_name "$parent_id" "$child_num")
    
    if [[ "$pane_id" == -1 ]]; then
        echo -e "${RED}[ERROR]${NC} 無効な子ID: $parent_id-$child_num"
        return 1
    fi
    
    # コマンド送信
    tmux send-keys -t orchestrator:0.$pane_id "$command" Enter
    log_send "[$parent_name→$child_name] $command"
    
    # ログ記録
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $parent_name→$child_name: $command" >> logs/orchestrator/communication.log
}

# 全エージェント状態確認
status_all() {
    log_comm "全エージェント状態確認中..."
    
    if ! tmux has-session -t orchestrator 2>/dev/null; then
        echo -e "${RED}[ERROR]${NC} orchestratorセッションが見つかりません"
        return 1
    fi
    
    # 実際のペイン数を取得
    local pane_count=$(tmux list-panes -t orchestrator:0 | wc -l | tr -d ' ')
    
    log_comm "実際のペイン数: $pane_count"
    
    echo "📍 現在のペイン配置："
    echo "┌─────────┬─────────┬─────────┐"
    echo "│ Pane 0  │ Pane 1  │ Pane 2  │"
    echo "│Parent1  │Child1-1 │Child1-2 │"
    echo "│ Quill   │  HTML   │   JS    │"
    echo "├─────────┼─────────┼─────────┤"
    echo "│ Pane 3  │ Pane 4  │ Pane 5  │"
    echo "│Parent2  │Child2-1 │Child2-2 │"
    echo "│ WebView │ Flutter │ Bridge  │"
    echo "├─────────┼─────────┼─────────┤"
    echo "│ Pane 6  │  [未作成] │ [未作成] │"
    echo "│Parent3  │   ---    │   ---   │"
    echo "│ Gemini  │          │         │"
    echo "└─────────┴─────────┴─────────┘"
    
    # 実際に存在するペインのみに送信
    for i in $(seq 0 $((pane_count - 1))); do
        if tmux send-keys -t orchestrator:0.$i "echo '[PANE-$i] Ready: $(date +%H:%M:%S)'" Enter 2>/dev/null; then
            log_send "Pane $i: 状態確認コマンド送信"
        else
            log_warning "Pane $i: 送信失敗"
        fi
    done
    
    log_comm "状態確認完了（有効ペイン: $pane_count）"
}

# 完了報告収集
collect_reports() {
    log_comm "完了報告収集中..."
    
    local pane_count=$(tmux list-panes -t orchestrator:0 | wc -l | tr -d ' ')
    
    # 実際に存在するペインのみに送信
    for i in $(seq 0 $((pane_count - 1))); do
        if tmux send-keys -t orchestrator:0.$i "echo '[REPORT-$i] Status: $(date +%H:%M:%S)'" Enter 2>/dev/null; then
            log_send "Pane $i: 報告要求送信"
        fi
    done
    
    log_comm "報告要求送信完了（有効ペイン: $pane_count）"
    echo "詳細ログ: logs/orchestrator/communication.log"
}

# 全エージェントリセット
reset_all() {
    log_comm "全エージェントリセット中..."
    
    local pane_count=$(tmux list-panes -t orchestrator:0 | wc -l | tr -d ' ')
    
    # 実際に存在するペインのみをクリア
    for i in $(seq 0 $((pane_count - 1))); do
        if tmux send-keys -t orchestrator:0.$i "clear" Enter 2>/dev/null; then
            tmux send-keys -t orchestrator:0.$i "echo '[RESET-$i] Ready for new tasks'" Enter
            log_send "Pane $i: リセット完了"
        fi
    done
    
    log_comm "全エージェントリセット完了（有効ペイン: $pane_count）"
}

# タスク分解・配布
task_distribute() {
    local description="$1"
    log_comm "タスク分解・配布: $description"
    
    # 簡単なタスク分解ロジック（後で拡張可能）
    case "$description" in
        *"quill"*|*"Quill"*|*"エディター"*|*"editor"*)
            send_to_parent 1 "Quill.js統合システム実装を開始してください"
            sleep 1
            send_to_parent 2 "WebView統合対応をお願いします"  
            sleep 1
            send_to_parent 3 "AI機能統合の準備をしてください"
            ;;
        *"webview"*|*"WebView"*|*"flutter"*|*"Flutter"*)
            send_to_parent 2 "WebView統合システム実装を開始してください"
            sleep 1
            send_to_parent 1 "HTML/JS基盤の準備をお願いします"
            sleep 1
            send_to_parent 3 "API統合の準備をしてください"
            ;;
        *"gemini"*|*"Gemini"*|*"AI"*|*"api"*)
            send_to_parent 3 "Gemini API統合システム実装を開始してください"
            sleep 1
            send_to_parent 1 "フロントエンド基盤の準備をお願いします"
            sleep 1
            send_to_parent 2 "統合インターフェースの準備をお願いします"
            ;;
        *)
            # デフォルト分解
            send_to_parent 1 "フロントエンド担当: $description"
            sleep 1
            send_to_parent 2 "統合・インターフェース担当: $description"
            sleep 1
            send_to_parent 3 "API・バックエンド担当: $description"
            ;;
    esac
    
    log_comm "タスク配布完了"
}

# Claude Codeコマンド（/で始まるコマンド用）
claude_command() {
    local cmd="$1"
    shift
    local args="$@"
    
    case "$cmd" in
        "task")
            task_distribute "$args"
            ;;
        "status")
            status_all
            ;;
        "parent")
            if [[ $# -ge 2 ]]; then
                local parent_id="$1"
                shift
                send_to_parent "$parent_id" "$*"
            else
                echo "使用方法: /parent <id> <command>"
            fi
            ;;
        "child")
            if [[ $# -ge 3 ]]; then
                local parent_id="$1"
                local child_num="$2"
                shift 2
                send_to_child "$parent_id" "$child_num" "$*"
            else
                echo "使用方法: /child <parent-id> <child-num> <command>"
            fi
            ;;
        "report")
            collect_reports
            ;;
        "reset")
            reset_all
            ;;
        *)
            echo "不明なコマンド: $cmd"
            echo "利用可能コマンド: task, status, parent, child, report, reset"
            ;;
    esac
}

# 使用例表示
show_usage() {
    echo "=== オーケストレーター通信ライブラリ ==="
    echo ""
    echo "📋 基本コマンド:"
    echo "  send_to_parent <id> <command>         # 親エージェントに指示"
    echo "  send_to_child <p-id> <c-id> <command> # 子エージェントに指示"
    echo "  status_all                           # 全状態確認"
    echo "  collect_reports                      # 完了報告収集"
    echo "  reset_all                           # 全リセット"
    echo "  task_distribute <description>        # タスク分解・配布"
    echo ""
    echo "🤖 Claude Codeコマンド:"
    echo "  claude_command task 'Quill.js統合'   # タスク分解・配布"
    echo "  claude_command status               # 状態確認"
    echo "  claude_command parent 1 'HTML実装'   # 親1に指示"
    echo "  claude_command child 1 2 'JS実装'    # 親1子2に指示"
    echo "  claude_command report               # 報告収集"
    echo "  claude_command reset                # リセット"
    echo ""
    echo "📍 ペイン配置:"
    echo "  Parent1(0), Child1-1(1), Child1-2(2)"
    echo "  Parent2(3), Child2-1(4), Child2-2(5)"  
    echo "  Parent3(6), Child3-1(7), Child3-2(8)"
    echo ""
}

# ライブラリ読み込み完了メッセージ
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    log_comm "オーケストレーター通信ライブラリ読み込み完了"
    echo "ヘルプ: show_usage"
fi 