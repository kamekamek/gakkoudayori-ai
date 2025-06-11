#!/bin/bash

# 🔗 階層型エージェント間通信システム
# 参考: https://github.com/kamekamek/Claude-Code-Communication.git の agent-send.sh

set -e

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# ログ関数
log_send() { echo -e "${CYAN}[SEND]${NC} $1"; }
log_receive() { echo -e "${GREEN}[RECEIVE]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_hierarchy() { echo -e "${PURPLE}[HIERARCHY]${NC} $1"; }

# エージェント定義
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

# 階層関係定義
declare -A HIERARCHY_RELATIONS=(
    ["COORDINATOR"]="PARENT1,PARENT2,PARENT3"
    ["PARENT1"]="CHILD1-1,CHILD1-2,CHILD1-3"
    ["PARENT2"]="CHILD2-1,CHILD2-2,CHILD2-3"
    ["PARENT3"]="CHILD3-1,CHILD3-2,CHILD3-3"
)

# ログディレクトリ準備
LOGS_DIR="logs/hierarchy"
mkdir -p "$LOGS_DIR"

# ヘルプ表示
show_help() {
    echo "🔗 階層型エージェント間通信システム"
    echo ""
    echo "使用法:"
    echo "  $0 <送信先エージェント> <メッセージ>"
    echo "  $0 --list                     # エージェント一覧表示"
    echo "  $0 --hierarchy               # 階層構造表示"
    echo "  $0 --broadcast <レベル> <メッセージ>  # 階層ブロードキャスト"
    echo "  $0 --status                  # エージェント状態確認"
    echo ""
    echo "階層ブロードキャスト例:"
    echo "  $0 --broadcast parents 'Phase2開始指示'"
    echo "  $0 --broadcast children 'TDD実装開始'"
    echo ""
    echo "エージェント一覧:"
    for agent in "${!AGENT_SESSIONS[@]}"; do
        session="${AGENT_SESSIONS[$agent]}"
        echo "  $agent -> tmux:$session"
    done
}

# エージェント一覧表示
list_agents() {
    echo "📋 階層型エージェント一覧"
    echo "========================"
    echo ""
    
    echo "🎯 COORDINATOR (統括責任者):"
    echo "  COORDINATOR -> tmux:coordinator"
    echo ""
    
    echo "📋 PARENTS (チームリーダー):"
    echo "  PARENT1 (Quill.js Boss) -> tmux:parents:0.0"
    echo "  PARENT2 (WebView Boss) -> tmux:parents:0.1"
    echo "  PARENT3 (Gemini Boss) -> tmux:parents:0.2"
    echo ""
    
    echo "👥 CHILDREN (ワーカー):"
    echo "  CHILD1-1 (HTML Worker) -> tmux:workers:0.0"
    echo "  CHILD1-2 (JS Worker) -> tmux:workers:0.1"
    echo "  CHILD1-3 (CSS Worker) -> tmux:workers:0.2"
    echo "  CHILD2-1 (WebView Worker) -> tmux:workers:0.3"
    echo "  CHILD2-2 (Bridge Worker) -> tmux:workers:0.4"
    echo "  CHILD2-3 (Test Worker) -> tmux:workers:0.5"
    echo "  CHILD3-1 (API Worker) -> tmux:workers:0.6"
    echo "  CHILD3-2 (Prompt Worker) -> tmux:workers:0.7"
    echo "  CHILD3-3 (Response Worker) -> tmux:workers:0.8"
}

# 階層構造表示
show_hierarchy() {
    echo "🏗️ 階層構造"
    echo "============"
    echo ""
    echo "🎯 COORDINATOR"
    echo "├── 📋 PARENT1 (Quill.js Boss)"
    echo "│   ├── 👤 CHILD1-1 (HTML Worker)"
    echo "│   ├── 👤 CHILD1-2 (JS Worker)" 
    echo "│   └── 👤 CHILD1-3 (CSS Worker)"
    echo "├── 📋 PARENT2 (WebView Boss)"
    echo "│   ├── 👤 CHILD2-1 (WebView Worker)"
    echo "│   ├── 👤 CHILD2-2 (Bridge Worker)"
    echo "│   └── 👤 CHILD2-3 (Test Worker)"
    echo "└── 📋 PARENT3 (Gemini Boss)"
    echo "    ├── 👤 CHILD3-1 (API Worker)"
    echo "    ├── 👤 CHILD3-2 (Prompt Worker)"
    echo "    └── 👤 CHILD3-3 (Response Worker)"
}

# エージェント状態確認
check_agent_status() {
    echo "📊 エージェント状態確認"
    echo "======================"
    echo ""
    
    # Tmuxセッション確認
    local sessions=("coordinator" "parents" "workers")
    for session in "${sessions[@]}"; do
        if tmux has-session -t "$session" 2>/dev/null; then
            echo "✅ セッション $session: アクティブ"
        else
            echo "❌ セッション $session: 非アクティブ"
        fi
    done
    echo ""
    
    # エージェント別状態確認
    echo "🎯 COORDINATOR:"
    if tmux has-session -t coordinator 2>/dev/null; then
        echo "  ✅ アクティブ"
    else
        echo "  ❌ 非アクティブ"
    fi
    echo ""
    
    echo "📋 PARENTS:"
    for i in 0 1 2; do
        parent_names=("PARENT1(Quill)" "PARENT2(WebView)" "PARENT3(Gemini)")
        if tmux has-session -t parents 2>/dev/null && tmux list-panes -t parents:0 2>/dev/null | grep -q "0.$i"; then
            echo "  ✅ ${parent_names[$i]}: アクティブ"
        else
            echo "  ❌ ${parent_names[$i]}: 非アクティブ"
        fi
    done
    echo ""
    
    echo "👥 WORKERS:"
    worker_names=("HTML" "JS" "CSS" "WebView" "Bridge" "Test" "API" "Prompt" "Response")
    for i in {0..8}; do
        if tmux has-session -t workers 2>/dev/null && tmux list-panes -t workers:0 2>/dev/null | grep -q "0.$i"; then
            echo "  ✅ CHILD$((i+1))(${worker_names[$i]}): アクティブ"
        else
            echo "  ❌ CHILD$((i+1))(${worker_names[$i]}): 非アクティブ"
        fi
    done
}

# メッセージ送信
send_message() {
    local target_agent="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local sender="${3:-SYSTEM}"
    
    # エージェント存在確認
    if [[ ! "${AGENT_SESSIONS[$target_agent]}" ]]; then
        log_error "エージェント '$target_agent' は存在しません"
        echo "使用可能エージェント: ${!AGENT_SESSIONS[*]}"
        return 1
    fi
    
    local session_target="${AGENT_SESSIONS[$target_agent]}"
    
    # セッション存在確認
    local session_name=$(echo "$session_target" | cut -d':' -f1)
    if ! tmux has-session -t "$session_name" 2>/dev/null; then
        log_error "Tmuxセッション '$session_name' が見つかりません"
        echo "先に環境をセットアップしてください: ./scripts/setup_hierarchical_v3.sh"
        return 1
    fi
    
    # メッセージ整形
    local formatted_message="[$sender→$target_agent] $message"
    
    # メッセージ送信
    log_send "$formatted_message"
    tmux send-keys -t "$session_target" "$formatted_message" Enter
    
    # ログ記録
    echo "$timestamp | $sender → $target_agent | $message" >> "$LOGS_DIR/communication.log"
    
    # 個別エージェントログ
    echo "$timestamp | FROM:$sender | $message" >> "$LOGS_DIR/${target_agent,,}.log"
    
    log_receive "メッセージ送信完了: $target_agent"
}

# 階層ブロードキャスト
broadcast_message() {
    local level="$1"
    local message="$2"
    local sender="${3:-COORDINATOR}"
    
    case "$level" in
        "parents"|"PARENTS")
            log_hierarchy "PARENTSへブロードキャスト中..."
            for parent in PARENT1 PARENT2 PARENT3; do
                send_message "$parent" "$message" "$sender"
                sleep 1  # 1秒間隔
            done
            ;;
        "children"|"CHILDREN"|"workers"|"WORKERS")
            log_hierarchy "CHILDRENへブロードキャスト中..."
            for child in CHILD1-1 CHILD1-2 CHILD1-3 CHILD2-1 CHILD2-2 CHILD2-3 CHILD3-1 CHILD3-2 CHILD3-3; do
                send_message "$child" "$message" "$sender"
                sleep 0.5  # 0.5秒間隔
            done
            ;;
        "all"|"ALL")
            log_hierarchy "全エージェントへブロードキャスト中..."
            for agent in "${!AGENT_SESSIONS[@]}"; do
                if [[ "$agent" != "$sender" ]]; then
                    send_message "$agent" "$message" "$sender"
                    sleep 0.5
                fi
            done
            ;;
        *)
            log_error "無効なブロードキャストレベル: $level"
            echo "有効なレベル: parents, children, all"
            return 1
            ;;
    esac
    
    log_hierarchy "ブロードキャスト完了: $level"
}

# 子エージェントへの一括送信 (PARENTから使用)
send_to_children() {
    local parent_agent="$1"
    local message="$2"
    
    if [[ ! "${HIERARCHY_RELATIONS[$parent_agent]}" ]]; then
        log_error "エージェント '$parent_agent' は子を持ちません"
        return 1
    fi
    
    IFS=',' read -ra children <<< "${HIERARCHY_RELATIONS[$parent_agent]}"
    
    log_hierarchy "$parent_agent から配下の子エージェントへ送信中..."
    for child in "${children[@]}"; do
        send_message "$child" "$message" "$parent_agent"
        sleep 0.5
    done
    
    log_hierarchy "$parent_agent の子エージェント送信完了"
}

# ログ確認
show_logs() {
    echo "📜 通信ログ確認"
    echo "=============="
    echo ""
    
    if [[ -f "$LOGS_DIR/communication.log" ]]; then
        echo "🔗 通信履歴 (最新10件):"
        tail -10 "$LOGS_DIR/communication.log"
    else
        echo "通信ログが見つかりません"
    fi
    echo ""
    
    echo "📁 個別エージェントログ:"
    for log_file in "$LOGS_DIR"/*.log; do
        if [[ -f "$log_file" && "$(basename "$log_file")" != "communication.log" ]]; then
            echo "  $(basename "$log_file" .log): $(wc -l < "$log_file") メッセージ"
        fi
    done
}

# メイン処理
main() {
    case "${1:-}" in
        "--list"|"-l")
            list_agents
            ;;
        "--hierarchy"|"-h")
            show_hierarchy
            ;;
        "--status"|"-s")
            check_agent_status
            ;;
        "--broadcast"|"-b")
            if [[ $# -lt 3 ]]; then
                log_error "ブロードキャスト使用法: $0 --broadcast <レベル> <メッセージ>"
                exit 1
            fi
            broadcast_message "$2" "$3"
            ;;
        "--children"|"-c")
            if [[ $# -lt 3 ]]; then
                log_error "子送信使用法: $0 --children <PARENT> <メッセージ>"
                exit 1
            fi
            send_to_children "$2" "$3"
            ;;
        "--logs"|"-L")
            show_logs
            ;;
        "--help"|"help"|"")
            show_help
            ;;
        *)
            if [[ $# -lt 2 ]]; then
                log_error "使用法: $0 <エージェント> <メッセージ>"
                echo "詳細: $0 --help"
                exit 1
            fi
            send_message "$1" "$2"
            ;;
    esac
}

# 実行
main "$@" 