#!/bin/bash

# 🚀 階層型エージェント段階的起動システム
# 参考リポジトリの手法に基づく段階的Claude Code起動

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
log_phase() { echo -e "${PURPLE}[PHASE]${NC} $1"; }
log_start() { echo -e "${CYAN}[START]${NC} $1"; }
log_wait() { echo -e "${YELLOW}[WAIT]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 設定
STARTUP_DELAY=3  # Claude Code起動待ち時間（秒）
PHASE_DELAY=10   # フェーズ間待ち時間（秒）

# セッション確認
check_sessions() {
    log_phase "Tmuxセッション状態確認中..."
    
    local required_sessions=("coordinator" "parents" "workers")
    local missing_sessions=()
    
    for session in "${required_sessions[@]}"; do
        if ! tmux has-session -t "$session" 2>/dev/null; then
            missing_sessions+=("$session")
        fi
    done
    
    if [[ ${#missing_sessions[@]} -gt 0 ]]; then
        log_error "必要なTmuxセッションが見つかりません: ${missing_sessions[*]}"
        echo "先に環境をセットアップしてください:"
        echo "  ./scripts/setup_hierarchical_v3.sh"
        exit 1
    fi
    
    log_success "全てのTmuxセッションが確認できました"
}

# Claude Code起動確認
wait_for_claude_startup() {
    local session_target="$1"
    local agent_name="$2"
    
    log_wait "$agent_name でClaude Code起動待機中... (${STARTUP_DELAY}秒)"
    sleep "$STARTUP_DELAY"
    
    # Claude Code起動確認メッセージ送信
    tmux send-keys -t "$session_target" "# Claude Code起動確認: $agent_name" Enter
    tmux send-keys -t "$session_target" "# 準備完了後、指示を待機中..." Enter
    
    log_success "$agent_name 起動完了"
}

# Phase 0: 環境確認・準備
phase0_preparation() {
    log_phase "Phase 0: 環境確認・準備フェーズ"
    
    check_sessions
    
    # ログディレクトリ準備
    mkdir -p logs/hierarchy/startup
    echo "$(date '+%Y-%m-%d %H:%M:%S') | 階層型エージェント起動開始" > logs/hierarchy/startup/startup.log
    
    # 各セッションの初期メッセージ
    tmux send-keys -t coordinator "# 🎯 COORDINATOR 準備中..." Enter
    tmux send-keys -t parents:0.0 "# 📋 PARENT1 (Quill.js Boss) 準備中..." Enter
    tmux send-keys -t parents:0.1 "# 📋 PARENT2 (WebView Boss) 準備中..." Enter
    tmux send-keys -t parents:0.2 "# 📋 PARENT3 (Gemini Boss) 準備中..." Enter
    
    # Workers準備メッセージ
    for i in {0..8}; do
        worker_names=("HTML" "JS" "CSS" "WebView" "Bridge" "Test" "API" "Prompt" "Response")
        tmux send-keys -t workers:0.$i "# 👤 CHILD$((i+1)) (${worker_names[$i]} Worker) 準備中..." Enter
    done
    
    log_success "Phase 0 完了"
    sleep "$PHASE_DELAY"
}

# Phase 1: COORDINATOR起動
phase1_coordinator() {
    log_phase "Phase 1: COORDINATOR エージェント起動"
    
    log_start "COORDINATOR でClaude Code起動中..."
    tmux send-keys -t coordinator "claude" Enter
    
    wait_for_claude_startup "coordinator" "COORDINATOR"
    
    # COORDINATOR初期化メッセージ
    sleep 2
    tmux send-keys -t coordinator "あなたはCOORDINATORです。instructions/coordinator.md の指示に従って、Phase2タスクを3つの大カテゴリに分解し、各PARENTに指示してください。" Enter
    
    echo "$(date '+%Y-%m-%d %H:%M:%S') | COORDINATOR 起動完了" >> logs/hierarchy/startup/startup.log
    
    log_success "Phase 1 完了: COORDINATOR 起動済み"
    sleep "$PHASE_DELAY"
}

# Phase 2: PARENTS起動
phase2_parents() {
    log_phase "Phase 2: PARENT エージェント並列起動"
    
    # PARENT1 (Quill.js Boss) 起動
    log_start "PARENT1 (Quill.js Boss) でClaude Code起動中..."
    tmux send-keys -t parents:0.0 "claude" Enter &
    
    # PARENT2 (WebView Boss) 起動
    log_start "PARENT2 (WebView Boss) でClaude Code起動中..."
    tmux send-keys -t parents:0.1 "claude" Enter &
    
    # PARENT3 (Gemini Boss) 起動
    log_start "PARENT3 (Gemini Boss) でClaude Code起動中..."
    tmux send-keys -t parents:0.2 "claude" Enter &
    
    # 全PARENT起動待機
    wait_for_claude_startup "parents:0.0" "PARENT1"
    wait_for_claude_startup "parents:0.1" "PARENT2"
    wait_for_claude_startup "parents:0.2" "PARENT3"
    
    # PARENT初期化メッセージ
    sleep 2
    tmux send-keys -t parents:0.0 "あなたはPARENT1です。instructions/parent.md の指示に従って、Quill.js統合システムを3つに分解して配下のCHILDに指示してください。" Enter
    tmux send-keys -t parents:0.1 "あなたはPARENT2です。instructions/parent.md の指示に従って、WebView統合システムを3つに分解して配下のCHILDに指示してください。" Enter
    tmux send-keys -t parents:0.2 "あなたはPARENT3です。instructions/parent.md の指示に従って、Gemini APIシステムを3つに分解して配下のCHILDに指示してください。" Enter
    
    echo "$(date '+%Y-%m-%d %H:%M:%S') | 全PARENT 起動完了" >> logs/hierarchy/startup/startup.log
    
    log_success "Phase 2 完了: 全PARENT 起動済み"
    sleep "$PHASE_DELAY"
}

# Phase 3: CHILDREN起動 (9エージェント並列)
phase3_children() {
    log_phase "Phase 3: CHILD エージェント並列起動 (9エージェント)"
    
    # 9つのCHILDを並列起動
    log_start "全CHILD エージェントでClaude Code並列起動中..."
    
    for i in {0..8}; do
        tmux send-keys -t workers:0.$i "claude" Enter &
    done
    
    # 全CHILD起動待機
    worker_names=("HTML" "JS" "CSS" "WebView" "Bridge" "Test" "API" "Prompt" "Response")
    for i in {0..8}; do
        wait_for_claude_startup "workers:0.$i" "CHILD$((i+1))(${worker_names[$i]})"
    done
    
    # CHILD初期化メッセージ
    sleep 2
    child_roles=(
        "CHILD1-1です。instructions/child.md の指示に従って、HTML基本構造作成をTDDで実装してください。"
        "CHILD1-2です。instructions/child.md の指示に従って、Quill.js統合スクリプト実装をTDDで実装してください。"
        "CHILD1-3です。instructions/child.md の指示に従って、CSS・レスポンシブ対応をTDDで実装してください。"
        "CHILD2-1です。instructions/child.md の指示に従って、WebView Flutter実装をTDDで実装してください。"
        "CHILD2-2です。instructions/child.md の指示に従って、Bridge通信機能をTDDで実装してください。"
        "CHILD2-3です。instructions/child.md の指示に従って、統合テスト作成をTDDで実装してください。"
        "CHILD3-1です。instructions/child.md の指示に従って、Gemini API基盤実装をTDDで実装してください。"
        "CHILD3-2です。instructions/child.md の指示に従って、プロンプト管理をTDDで実装してください。"
        "CHILD3-3です。instructions/child.md の指示に従って、レスポンス処理をTDDで実装してください。"
    )
    
    for i in {0..8}; do
        tmux send-keys -t workers:0.$i "あなたは${child_roles[$i]}" Enter
    done
    
    echo "$(date '+%Y-%m-%d %H:%M:%S') | 全CHILD 起動完了" >> logs/hierarchy/startup/startup.log
    
    log_success "Phase 3 完了: 全CHILD 起動済み"
    sleep "$PHASE_DELAY"
}

# Phase 4: 統合監視システム起動
phase4_monitoring() {
    log_phase "Phase 4: 統合監視システム起動"
    
    # 監視ダッシュボード起動（バックグラウンド）
    log_start "統合監視ダッシュボード起動中..."
    nohup ./scripts/monitor_hierarchy.sh > logs/hierarchy/monitor.log 2>&1 &
    echo $! > logs/hierarchy/monitor.pid
    
    # 通信システム確認
    log_start "エージェント間通信システム確認中..."
    ./scripts/agent_hierarchy_communication.sh --status
    
    echo "$(date '+%Y-%m-%d %H:%M:%S') | 監視システム起動完了" >> logs/hierarchy/startup/startup.log
    
    log_success "Phase 4 完了: 監視システム起動済み"
}

# Phase 5: 初期通信テスト
phase5_initial_communication() {
    log_phase "Phase 5: 初期通信テスト・システム確認"
    
    # COORDINATORから確認メッセージ送信
    log_start "COORDINATOR → PARENTS 確認メッセージ送信中..."
    ./scripts/agent_hierarchy_communication.sh --broadcast parents "システム起動完了。Phase2並列開発準備OK。指示待機中。" COORDINATOR
    
    sleep 3
    
    # PARENTSから確認メッセージ送信
    log_start "PARENTS → CHILDREN 確認メッセージ送信中..."
    ./scripts/agent_hierarchy_communication.sh --children PARENT1 "PARENT1チーム準備完了。Quill.js統合システム待機中。"
    ./scripts/agent_hierarchy_communication.sh --children PARENT2 "PARENT2チーム準備完了。WebView統合システム待機中。"
    ./scripts/agent_hierarchy_communication.sh --children PARENT3 "PARENT3チーム準備完了。Gemini APIシステム待機中。"
    
    # 通信ログ確認
    log_start "通信ログ確認中..."
    ./scripts/agent_hierarchy_communication.sh --logs
    
    echo "$(date '+%Y-%m-%d %H:%M:%S') | 初期通信テスト完了" >> logs/hierarchy/startup/startup.log
    
    log_success "Phase 5 完了: 初期通信テスト成功"
}

# 起動完了サマリー表示
show_startup_summary() {
    echo ""
    echo "🎉========================================"
    echo "🏗️ 階層型並列AI開発環境 v3.0 起動完了！"
    echo "========================================🎉"
    echo ""
    
    echo "📊 システム構成:"
    echo "  🎯 COORDINATOR: 1エージェント (統括責任者)"
    echo "  📋 PARENTS: 3エージェント (チームリーダー)"
    echo "  👥 CHILDREN: 9エージェント (ワーカー)"
    echo "  📈 監視システム: アクティブ"
    echo ""
    
    echo "🔗 接続コマンド:"
    echo "  tmux attach-session -t coordinator   # 統括者セッション"
    echo "  tmux attach-session -t parents       # ボスセッション"
    echo "  tmux attach-session -t workers       # ワーカーセッション"
    echo ""
    
    echo "🚀 次のステップ:"
    echo "1. COORDINATORセッションに接続"
    echo "2. Phase2並列開発指示を送信"
    echo "3. 階層通信で13エージェント協調動作"
    echo ""
    
    echo "💡 有用なコマンド:"
    echo "  ./scripts/agent_hierarchy_communication.sh --help    # 通信システム"
    echo "  ./scripts/monitor_hierarchy.sh                      # 監視ダッシュボード"
    echo "  ./scripts/agent_hierarchy_communication.sh --status # システム状態"
    echo ""
    
    log_success "階層型並列AI開発システム v3.0 準備完了！"
}

# エラーハンドリング
handle_error() {
    log_error "起動プロセスでエラーが発生しました"
    echo "$(date '+%Y-%m-%d %H:%M:%S') | エラー発生: $1" >> logs/hierarchy/startup/startup.log
    
    echo ""
    echo "🔧 トラブルシューティング:"
    echo "1. 環境セットアップ確認: ./scripts/setup_hierarchical_v3.sh"
    echo "2. Tmuxセッション確認: tmux list-sessions"
    echo "3. Claude Code認証確認: Cursor拡張設定"
    echo ""
    
    exit 1
}

# メイン実行
main() {
    trap 'handle_error "予期しないエラー"' ERR
    
    log_phase "🏗️ 階層型エージェント段階的起動開始"
    echo ""
    
    phase0_preparation
    phase1_coordinator
    phase2_parents
    phase3_children
    phase4_monitoring
    phase5_initial_communication
    
    show_startup_summary
    
    echo "$(date '+%Y-%m-%d %H:%M:%S') | 全起動プロセス完了" >> logs/hierarchy/startup/startup.log
}

# 実行オプション処理
case "${1:-}" in
    "--help"|"-h")
        echo "🚀 階層型エージェント段階的起動システム"
        echo ""
        echo "使用法:"
        echo "  $0              # 全フェーズ実行"
        echo "  $0 --phase <N>  # 特定フェーズのみ実行"
        echo "  $0 --status     # 起動状態確認"
        echo ""
        echo "フェーズ一覧:"
        echo "  0: 環境確認・準備"
        echo "  1: COORDINATOR起動"
        echo "  2: PARENTS起動"
        echo "  3: CHILDREN起動"
        echo "  4: 監視システム起動"
        echo "  5: 初期通信テスト"
        ;;
    "--phase")
        if [[ -z "${2:-}" ]]; then
            log_error "フェーズ番号を指定してください (0-5)"
            exit 1
        fi
        
        case "$2" in
            0) phase0_preparation ;;
            1) phase1_coordinator ;;
            2) phase2_parents ;;
            3) phase3_children ;;
            4) phase4_monitoring ;;
            5) phase5_initial_communication ;;
            *) log_error "無効なフェーズ番号: $2"; exit 1 ;;
        esac
        ;;
    "--status")
        ./scripts/agent_hierarchy_communication.sh --status
        ;;
    *)
        main "$@"
        ;;
esac 