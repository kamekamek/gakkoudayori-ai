#!/bin/bash

# 🎯 階層型並列AI開発環境 v3.0 ワンクリック完全実行
# COORDINATOR → 3 PARENTS → 9 CHILDREN の13エージェント協調システム

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

# ログ関数
log_title() { echo -e "${WHITE}$1${NC}"; }
log_phase() { echo -e "${PURPLE}[PHASE]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }

# 設定
MONITORING=${MONITORING:-true}  # 監視ダッシュボード自動起動
DRY_RUN=${DRY_RUN:-false}      # ドライラン（確認のみ）

# エラーハンドリング
handle_error() {
    log_error "実行中にエラーが発生しました: $1"
    echo ""
    echo "🔧 トラブルシューティング:"
    echo "  1. 依存関係確認: tmux, git, claude (Cursor拡張)"
    echo "  2. 権限確認: ./scripts/ ディレクトリの実行権限"
    echo "  3. 既存環境クリーンアップ: ./scripts/clean_parallel_env.sh"
    echo ""
    exit 1
}

# 依存関係チェック
check_dependencies() {
    log_phase "依存関係チェック中..."
    
    # 必須コマンド確認
    local missing_deps=()
    
    command -v tmux >/dev/null 2>&1 || missing_deps+=("tmux")
    command -v git >/dev/null 2>&1 || missing_deps+=("git")
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "必須依存関係が不足しています: ${missing_deps[*]}"
        echo "インストール方法:"
        echo "  macOS: brew install tmux git"
        echo "  Ubuntu: sudo apt install tmux git"
        exit 1
    fi
    
    # Git リポジトリ確認
    if [[ ! -d ".git" ]]; then
        log_error "Gitリポジトリのルートで実行してください"
        exit 1
    fi
    
    # スクリプト実行権限確認
    local scripts=(
        "scripts/setup_hierarchical_v3.sh"
        "scripts/agent_hierarchy_communication.sh"
        "scripts/start_hierarchical_agents.sh"
        "scripts/monitor_hierarchy.sh"
    )
    
    for script in "${scripts[@]}"; do
        if [[ ! -x "$script" ]]; then
            log_warning "$script に実行権限がありません。追加中..."
            chmod +x "$script"
        fi
    done
    
    log_success "依存関係チェック完了"
}

# 実行前確認
pre_execution_check() {
    log_phase "実行前確認"
    
    log_info "階層型並列AI開発環境 v3.0 を構築します"
    echo ""
    echo "📊 構築内容:"
    echo "  🎯 COORDINATOR: 1エージェント (プロジェクト統括)"
    echo "  📋 PARENTS: 3エージェント (チームリーダー)"
    echo "  👥 CHILDREN: 9エージェント (専門ワーカー)"
    echo "  🔗 通信システム: 階層型メッセージング"
    echo "  📈 監視システム: リアルタイムダッシュボード"
    echo ""
    
    echo "🎯 Phase 2 並列実装目標:"
    echo "  - Quill.js HTML基盤 (3ワーカー並列)"
    echo "  - WebView Flutter統合 (3ワーカー並列)"
    echo "  - Gemini API基盤 (3ワーカー並列)"
    echo ""
    
    echo "⏱️ 予想効率化:"
    echo "  従来: 150分 (順次実行)"
    echo "  v3.0: 50分 (13エージェント並列)"
    echo "  効率: 200% 向上"
    echo ""
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_warning "ドライランモード - 実際の構築は行いません"
        return 0
    fi
    
    # 既存セッション確認
    local existing_sessions=()
    for session in coordinator parents workers; do
        if tmux has-session -t "$session" 2>/dev/null; then
            existing_sessions+=("$session")
        fi
    done
    
    if [[ ${#existing_sessions[@]} -gt 0 ]]; then
        log_warning "既存のTmuxセッションが検出されました: ${existing_sessions[*]}"
        echo "続行すると既存セッションは削除されます。"
        echo ""
        echo -n "続行しますか？ (y/N): "
        read -r confirm
        if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
            echo "処理をキャンセルしました"
            exit 0
        fi
    fi
    
    log_success "実行前確認完了"
}

# フェーズ1: 環境構築
phase1_environment_setup() {
    log_phase "Phase 1: 階層型環境構築"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] 環境構築をシミュレート"
        sleep 2
        return 0
    fi
    
    log_info "Git worktree + Tmux階層セッション構築中..."
    ./scripts/setup_hierarchical_v3.sh
    
    # 構築確認
    local required_sessions=("coordinator" "parents" "workers")
    for session in "${required_sessions[@]}"; do
        if ! tmux has-session -t "$session" 2>/dev/null; then
            handle_error "Tmuxセッション '$session' の作成に失敗"
        fi
    done
    
    log_success "Phase 1 完了: 階層型環境構築済み"
    sleep 3
}

# フェーズ2: エージェント起動
phase2_agent_startup() {
    log_phase "Phase 2: 階層型エージェント起動"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] エージェント起動をシミュレート"
        sleep 3
        return 0
    fi
    
    log_info "13エージェント段階的起動中..."
    ./scripts/start_hierarchical_agents.sh
    
    # 起動確認
    sleep 5
    log_info "エージェント状態確認中..."
    ./scripts/agent_hierarchy_communication.sh --status
    
    log_success "Phase 2 完了: 全エージェント起動済み"
    sleep 2
}

# フェーズ3: 監視システム起動
phase3_monitoring_setup() {
    log_phase "Phase 3: 統合監視システム起動"
    
    if [[ "$MONITORING" != "true" ]]; then
        log_info "監視システムはスキップされました"
        return 0
    fi
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] 監視システム起動をシミュレート"
        sleep 2
        return 0
    fi
    
    log_info "リアルタイム監視ダッシュボード起動中..."
    
    # バックグラウンドで監視開始
    nohup ./scripts/monitor_hierarchy.sh --interval 10 > logs/hierarchy/monitor_bg.log 2>&1 &
    echo $! > logs/hierarchy/monitor.pid
    
    sleep 3
    
    log_success "Phase 3 完了: 監視システム起動済み"
}

# フェーズ4: 初期通信・準備完了
phase4_initial_communication() {
    log_phase "Phase 4: 初期通信・システム準備完了"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] 初期通信をシミュレート"
        sleep 2
        return 0
    fi
    
    log_info "システム準備完了メッセージ送信中..."
    
    # COORDINATORに準備完了通知
    ./scripts/agent_hierarchy_communication.sh COORDINATOR "階層型並列AI開発環境 v3.0 準備完了。Phase2並列開発を開始してください。"
    
    # 全体に準備完了をブロードキャスト
    sleep 2
    ./scripts/agent_hierarchy_communication.sh --broadcast all "システム全体準備完了。13エージェント協調動作開始。"
    
    # 通信ログ確認
    log_info "通信ログ確認中..."
    ./scripts/agent_hierarchy_communication.sh --logs
    
    log_success "Phase 4 完了: システム準備完了"
}

# 完了サマリー表示
show_completion_summary() {
    echo ""
    log_title "🎉 ============================================="
    log_title "   階層型並列AI開発環境 v3.0 構築完了！"
    log_title "==============================================="
    echo ""
    
    echo "📊 構築されたシステム:"
    echo "  🎯 COORDINATOR: プロジェクト統括責任者"
    echo "  📋 PARENT1: Quill.js統合チームリーダー"
    echo "  📋 PARENT2: WebView統合チームリーダー"
    echo "  📋 PARENT3: Gemini APIチームリーダー"
    echo "  👥 CHILDREN: 9専門ワーカー (各チーム3名)"
    echo ""
    
    echo "🔗 接続コマンド:"
    echo "  tmux attach-session -t coordinator   # 統括者コンソール"
    echo "  tmux attach-session -t parents       # チームリーダーコンソール"
    echo "  tmux attach-session -t workers       # ワーカーコンソール"
    echo ""
    
    echo "💻 有用なコマンド:"
    echo "  ./scripts/agent_hierarchy_communication.sh --help     # 通信システム操作"
    echo "  ./scripts/monitor_hierarchy.sh                        # 監視ダッシュボード"
    echo "  ./scripts/agent_hierarchy_communication.sh --status   # システム状態確認"
    echo ""
    
    echo "🚀 Phase 2 並列開発の開始手順:"
    echo "1. COORDINATORセッションに接続"
    echo "   tmux attach-session -t coordinator"
    echo ""
    echo "2. COORDINATORから開発指示を送信"
    echo "   'Phase2並列開発を開始してください。Quill.js、WebView、Gemini APIの3系統で並列実装。'"
    echo ""
    echo "3. 各PARENTが自動的にタスク分解→CHILDへ指示"
    echo "4. 9つのCHILDが同時にTDD実装開始"
    echo "5. 監視ダッシュボードで進捗確認"
    echo ""
    
    if [[ "$MONITORING" == "true" ]]; then
        echo "📈 監視ダッシュボード:"
        echo "  バックグラウンド監視: 稼働中"
        echo "  ログファイル: logs/hierarchy/monitor_bg.log"
        echo "  手動監視: ./scripts/monitor_hierarchy.sh"
        echo ""
    fi
    
    echo "⚠️ 重要事項:"
    echo "  • 13エージェントの協調システムです"
    echo "  • 各エージェントでClaude Code認証が必要です"
    echo "  • 通信は階層構造に従ってください (COORDINATOR→PARENT→CHILD)"
    echo "  • TDDフェーズ (🔴Red → 🟢Green → 🔵Blue) に従って実装"
    echo ""
    
    log_success "階層型並列AI開発システム v3.0 準備完了！"
    echo ""
    
    # 次のアクション提案
    if [[ "$DRY_RUN" != "true" ]]; then
        echo "🎯 推奨次ステップ:"
        echo "1. システム状態確認: ./scripts/agent_hierarchy_communication.sh --status"
        echo "2. COORDINATOR接続: tmux attach-session -t coordinator"
        echo "3. Phase2開発開始の指示送信"
        echo ""
        echo -n "COORDINATORセッションに接続しますか？ (y/N): "
        read -r connect_choice
        if [[ "$connect_choice" == "y" || "$connect_choice" == "Y" ]]; then
            log_info "COORDINATORセッションに接続中..."
            tmux attach-session -t coordinator
        fi
    fi
}

# メイン実行
main() {
    trap 'handle_error "予期しないエラー"' ERR
    
    # オプション処理
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                DRY_RUN=true
                log_warning "ドライランモード有効"
                ;;
            --no-monitoring)
                MONITORING=false
                log_info "監視システム無効"
                ;;
            --help|-h)
                echo "🎯 階層型並列AI開発環境 v3.0 ワンクリック実行"
                echo "使用法: $0 [--dry-run] [--no-monitoring] [--help]"
                exit 0
                ;;
            *)
                log_error "不明なオプション: $1"
                echo "使用法: $0 --help"
                exit 1
                ;;
        esac
        shift
    done
    
    # タイトル表示
    log_title "🏗️ 階層型並列AI開発環境 v3.0 構築開始"
    echo ""
    
    # 実行フロー
    check_dependencies
    pre_execution_check
    phase1_environment_setup
    phase2_agent_startup
    phase3_monitoring_setup
    phase4_initial_communication
    show_completion_summary
}

# 実行
main "$@" 