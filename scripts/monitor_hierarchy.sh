#!/bin/bash

# 📊 階層型エージェント監視ダッシュボード
# 13エージェント (COORDINATOR + 3 PARENTS + 9 CHILDREN) の統合監視

set -e

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# 監視設定
REFRESH_INTERVAL=15  # 更新間隔（秒）
AUTO_MODE=true       # 自動更新モード

# エージェント定義
declare -A AGENT_ROLES=(
    ["COORDINATOR"]="🎯 統括責任者"
    ["PARENT1"]="📋 Quill.js Boss"
    ["PARENT2"]="📋 WebView Boss"
    ["PARENT3"]="📋 Gemini Boss"
    ["CHILD1-1"]="👤 HTML Worker"
    ["CHILD1-2"]="👤 JS Worker"
    ["CHILD1-3"]="👤 CSS Worker"
    ["CHILD2-1"]="👤 WebView Worker"
    ["CHILD2-2"]="👤 Bridge Worker"
    ["CHILD2-3"]="👤 Test Worker"
    ["CHILD3-1"]="👤 API Worker"
    ["CHILD3-2"]="👤 Prompt Worker"
    ["CHILD3-3"]="👤 Response Worker"
)

declare -A AGENT_SESSIONS=(
    ["COORDINATOR"]="coordinator"
    ["PARENT1"]="parents:0.0"
    ["PARENT2"]="parents:0.1"
    ["PARENT3"]="parents:0.2"
    ["CHILD1-1"]="workers:0.0"
    ["CHILD1-2"]="workers:0.1"
    ["CHILD1-3"]="workers:0.2"
    ["CHILD2-1"]="workers:0.3"
    ["CHILD2-2"]="workers:0.4"
    ["CHILD2-3"]="workers:0.5"
    ["CHILD3-1"]="workers:0.6"
    ["CHILD3-2"]="workers:0.7"
    ["CHILD3-3"]="workers:0.8"
)

# ログディレクトリ準備
LOGS_DIR="logs/hierarchy"
mkdir -p "$LOGS_DIR"

# ヘッダー表示
show_header() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local uptime_file="$LOGS_DIR/startup/startup.log"
    local uptime="不明"
    
    if [[ -f "$uptime_file" ]]; then
        local start_time=$(head -1 "$uptime_file" | cut -d' ' -f1-2)
        if [[ -n "$start_time" ]]; then
            local start_epoch=$(date -j -f "%Y-%m-%d %H:%M:%S" "$start_time" +%s 2>/dev/null || echo "0")
            local current_epoch=$(date +%s)
            local diff=$((current_epoch - start_epoch))
            local hours=$((diff / 3600))
            local minutes=$(((diff % 3600) / 60))
            uptime="${hours}時間${minutes}分"
        fi
    fi
    
    echo -e "${WHITE}╔════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}║                  🏗️ 階層型並列AI開発監視ダッシュボード v3.0                    ║${NC}"
    echo -e "${WHITE}╠════════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${WHITE}║ 更新時刻: ${CYAN}$timestamp${WHITE}     システム稼働時間: ${GREEN}$uptime${WHITE}     ║${NC}"
    echo -e "${WHITE}╚════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# エージェント状態確認
check_agent_status() {
    local agent="$1"
    local session="${AGENT_SESSIONS[$agent]}"
    local session_name=$(echo "$session" | cut -d':' -f1)
    
    # セッション存在確認
    if ! tmux has-session -t "$session_name" 2>/dev/null; then
        echo "❌ 非アクティブ"
        return 1
    fi
    
    # ペイン存在確認
    if [[ "$session" == *":"* ]]; then
        local pane=$(echo "$session" | cut -d':' -f2)
        if ! tmux list-panes -t "$session_name:0" 2>/dev/null | grep -q "$pane"; then
            echo "❌ ペイン未検出"
            return 1
        fi
    fi
    
    echo "✅ アクティブ"
    return 0
}

# Git状況確認
check_git_status() {
    local agent="$1"
    local worktree_path=""
    
    case "$agent" in
        "COORDINATOR") worktree_path="../yutori-coordinator" ;;
        "PARENT1") worktree_path="../yutori-parent1" ;;
        "PARENT2") worktree_path="../yutori-parent2" ;;
        "PARENT3") worktree_path="../yutori-parent3" ;;
        "CHILD"*) worktree_path="../yutori-${agent,,}" ;;
    esac
    
    if [[ ! -d "$worktree_path" ]]; then
        echo "N/A (worktree未検出)"
        return 1
    fi
    
    cd "$worktree_path" 2>/dev/null || return 1
    
    local branch=$(git branch --show-current 2>/dev/null || echo "unknown")
    local commits=$(git rev-list HEAD --count 2>/dev/null || echo "0")
    local modified=$(git status --porcelain 2>/dev/null | wc -l)
    
    echo "$branch (${commits}commits, ${modified}modified)"
    cd - >/dev/null
}

# 通信活動確認
check_communication_activity() {
    local agent="$1"
    local agent_log="$LOGS_DIR/${agent,,}.log"
    
    if [[ ! -f "$agent_log" ]]; then
        echo "0メッセージ"
        return
    fi
    
    local total_messages=$(wc -l < "$agent_log")
    local recent_messages=$(tail -10 "$agent_log" | wc -l)
    
    if [[ $total_messages -gt 0 ]]; then
        local last_message_time=$(tail -1 "$agent_log" | cut -d'|' -f1 | xargs)
        echo "${total_messages}メッセージ (最新: $last_message_time)"
    else
        echo "0メッセージ"
    fi
}

# TDDフェーズ検出
detect_tdd_phase() {
    local agent="$1"
    local agent_log="$LOGS_DIR/${agent,,}.log"
    
    if [[ ! -f "$agent_log" ]]; then
        echo "⚪ 待機"
        return
    fi
    
    # 最新の10メッセージから TDD フェーズを検出
    local recent_log=$(tail -10 "$agent_log" 2>/dev/null || echo "")
    
    if echo "$recent_log" | grep -qi "red\|テスト.*作成\|test.*creat"; then
        echo "🔴 RED"
    elif echo "$recent_log" | grep -qi "green\|実装\|implement"; then
        echo "🟢 GREEN"
    elif echo "$recent_log" | grep -qi "blue\|refactor\|リファクタ"; then
        echo "🔵 BLUE"
    elif echo "$recent_log" | grep -qi "完了\|complete\|done"; then
        echo "✅ 完了"
    elif echo "$recent_log" | grep -qi "開始\|start\|begin"; then
        echo "🚀 進行中"
    else
        echo "⚪ 待機"
    fi
}

# COORDINATOR監視
show_coordinator_status() {
    echo -e "${PURPLE}🎯 COORDINATOR (統括責任者)${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    local status=$(check_agent_status "COORDINATOR")
    local git_info=$(check_git_status "COORDINATOR")
    local comm_activity=$(check_communication_activity "COORDINATOR")
    local phase=$(detect_tdd_phase "COORDINATOR")
    
    printf "%-15s: %s\n" "セッション状態" "$status"
    printf "%-15s: %s\n" "Git状況" "$git_info"
    printf "%-15s: %s\n" "通信活動" "$comm_activity"
    printf "%-15s: %s\n" "進行フェーズ" "$phase"
    echo ""
}

# PARENTS監視
show_parents_status() {
    echo -e "${BLUE}📋 PARENTS (チームリーダー)${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    local parents=("PARENT1" "PARENT2" "PARENT3")
    local descriptions=("Quill.js Boss" "WebView Boss" "Gemini Boss")
    
    for i in {0..2}; do
        local parent="${parents[$i]}"
        local desc="${descriptions[$i]}"
        
        local status=$(check_agent_status "$parent")
        local git_info=$(check_git_status "$parent")
        local comm_activity=$(check_communication_activity "$parent")
        local phase=$(detect_tdd_phase "$parent")
        
        echo -e "${CYAN}$parent ($desc):${NC}"
        printf "  %-13s: %s\n" "状態" "$status"
        printf "  %-13s: %s\n" "Git" "$git_info"
        printf "  %-13s: %s\n" "通信" "$comm_activity"
        printf "  %-13s: %s\n" "フェーズ" "$phase"
        echo ""
    done
}

# CHILDREN監視
show_children_status() {
    echo -e "${GREEN}👥 CHILDREN (ワーカー)${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    local children=("CHILD1-1" "CHILD1-2" "CHILD1-3" "CHILD2-1" "CHILD2-2" "CHILD2-3" "CHILD3-1" "CHILD3-2" "CHILD3-3")
    local descriptions=("HTML Worker" "JS Worker" "CSS Worker" "WebView Worker" "Bridge Worker" "Test Worker" "API Worker" "Prompt Worker" "Response Worker")
    
    # 3x3グリッド表示
    echo -e "${YELLOW}Quill.js チーム:${NC}"
    for i in {0..2}; do
        local child="${children[$i]}"
        local desc="${descriptions[$i]}"
        local status=$(check_agent_status "$child")
        local phase=$(detect_tdd_phase "$child")
        
        printf "  %-10s %-15s: %s | %s\n" "$child" "($desc)" "$status" "$phase"
    done
    echo ""
    
    echo -e "${YELLOW}WebView チーム:${NC}"
    for i in {3..5}; do
        local child="${children[$i]}"
        local desc="${descriptions[$i]}"
        local status=$(check_agent_status "$child")
        local phase=$(detect_tdd_phase "$child")
        
        printf "  %-10s %-15s: %s | %s\n" "$child" "($desc)" "$status" "$phase"
    done
    echo ""
    
    echo -e "${YELLOW}Gemini チーム:${NC}"
    for i in {6..8}; do
        local child="${children[$i]}"
        local desc="${descriptions[$i]}"
        local status=$(check_agent_status "$child")
        local phase=$(detect_tdd_phase "$child")
        
        printf "  %-10s %-15s: %s | %s\n" "$child" "($desc)" "$status" "$phase"
    done
    echo ""
}

# システム全体サマリー
show_system_summary() {
    echo -e "${WHITE}📊 システムサマリー${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # アクティブエージェント数
    local active_count=0
    local total_count=13
    
    for agent in "${!AGENT_SESSIONS[@]}"; do
        if check_agent_status "$agent" >/dev/null 2>&1; then
            ((active_count++))
        fi
    done
    
    # 通信統計
    local total_messages=0
    if [[ -f "$LOGS_DIR/communication.log" ]]; then
        total_messages=$(wc -l < "$LOGS_DIR/communication.log")
    fi
    
    # TDDフェーズ統計
    local red_count=0 green_count=0 blue_count=0 complete_count=0 waiting_count=0
    
    for agent in "${!AGENT_SESSIONS[@]}"; do
        if [[ "$agent" == CHILD* ]]; then
            local phase=$(detect_tdd_phase "$agent")
            case "$phase" in
                *"RED"*) ((red_count++)) ;;
                *"GREEN"*) ((green_count++)) ;;
                *"BLUE"*) ((blue_count++)) ;;
                *"完了"*) ((complete_count++)) ;;
                *) ((waiting_count++)) ;;
            esac
        fi
    done
    
    printf "%-20s: %d/%d エージェント\n" "アクティブエージェント" "$active_count" "$total_count"
    printf "%-20s: %d メッセージ\n" "総通信数" "$total_messages"
    printf "%-20s: 🔴%d 🟢%d 🔵%d ✅%d ⚪%d\n" "TDDフェーズ分布" "$red_count" "$green_count" "$blue_count" "$complete_count" "$waiting_count"
    
    # 稼働率計算
    local uptime_percentage=$((active_count * 100 / total_count))
    printf "%-20s: %d%%\n" "システム稼働率" "$uptime_percentage"
    echo ""
}

# 通信ログ表示
show_recent_communications() {
    echo -e "${CYAN}📞 最近の通信 (最新10件)${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    if [[ -f "$LOGS_DIR/communication.log" ]]; then
        tail -10 "$LOGS_DIR/communication.log" | while IFS='|' read -r timestamp sender_receiver message; do
            echo "$(echo "$timestamp" | xargs) | $(echo "$sender_receiver" | xargs) | $(echo "$message" | xargs)"
        done
    else
        echo "通信ログが見つかりません"
    fi
    echo ""
}

# 対話型操作
interactive_mode() {
    while true; do
        echo -e "${YELLOW}対話モード${NC} - 選択してください:"
        echo "1) エージェント状態詳細"
        echo "2) 通信ログ詳細"
        echo "3) メッセージ送信"
        echo "4) 自動監視再開"
        echo "5) 終了"
        echo -n "選択 (1-5): "
        
        read -r choice
        
        case "$choice" in
            1)
                echo "エージェント名を入力してください (例: COORDINATOR, PARENT1, CHILD1-1): "
                read -r agent_name
                if [[ "${AGENT_SESSIONS[$agent_name]}" ]]; then
                    echo "=== $agent_name 詳細状態 ==="
                    check_agent_status "$agent_name"
                    check_git_status "$agent_name"
                    check_communication_activity "$agent_name"
                    detect_tdd_phase "$agent_name"
                else
                    echo "無効なエージェント名です"
                fi
                ;;
            2)
                echo "エージェント名を入力してください: "
                read -r agent_name
                local log_file="$LOGS_DIR/${agent_name,,}.log"
                if [[ -f "$log_file" ]]; then
                    echo "=== $agent_name 通信ログ ==="
                    cat "$log_file"
                else
                    echo "ログファイルが見つかりません"
                fi
                ;;
            3)
                echo "送信先エージェント: "
                read -r target_agent
                echo "メッセージ: "
                read -r message
                ./scripts/agent_hierarchy_communication.sh "$target_agent" "$message"
                ;;
            4)
                AUTO_MODE=true
                break
                ;;
            5)
                echo "監視を終了します"
                exit 0
                ;;
            *)
                echo "無効な選択です"
                ;;
        esac
        
        echo ""
        echo "続行するにはEnterキーを押してください..."
        read -r
    done
}

# メイン監視ループ
main_monitor() {
    # 自動監視モード
    while $AUTO_MODE; do
        clear
        show_header
        show_coordinator_status
        show_parents_status
        show_children_status
        show_system_summary
        show_recent_communications
        
        echo -e "${YELLOW}自動更新モード${NC} - ${REFRESH_INTERVAL}秒後に更新 (Ctrl+C で対話モード)"
        
        # タイムアウト付き入力待機
        if read -t "$REFRESH_INTERVAL" -n 1; then
            AUTO_MODE=false
            interactive_mode
        fi
    done
}

# シグナルハンドラー
handle_interrupt() {
    echo -e "\n${YELLOW}自動更新を中断しました${NC}"
    AUTO_MODE=false
    interactive_mode
}

# メイン実行
main() {
    trap handle_interrupt INT
    
    case "${1:-}" in
        "--help"|"-h")
            echo "📊 階層型エージェント監視ダッシュボード"
            echo ""
            echo "使用法:"
            echo "  $0                    # 自動監視モード"
            echo "  $0 --once            # 1回のみ表示"
            echo "  $0 --interactive     # 対話モード"
            echo "  $0 --interval <秒>   # 更新間隔指定"
            echo ""
            echo "自動監視中:"
            echo "  Ctrl+C: 対話モードに移行"
            echo "  任意キー: 対話モードに移行"
            ;;
        "--once")
            clear
            show_header
            show_coordinator_status
            show_parents_status
            show_children_status
            show_system_summary
            show_recent_communications
            ;;
        "--interactive")
            AUTO_MODE=false
            interactive_mode
            ;;
        "--interval")
            if [[ -n "${2:-}" && "$2" =~ ^[0-9]+$ ]]; then
                REFRESH_INTERVAL="$2"
                main_monitor
            else
                echo "無効な間隔です。数値を指定してください。"
                exit 1
            fi
            ;;
        *)
            main_monitor
            ;;
    esac
}

# 実行
main "$@" 