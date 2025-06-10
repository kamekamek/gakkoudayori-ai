#!/usr/bin/env bash
# ------------------------------------------------------------
#   orchestrator_setup.sh
#   Claude Code オーケストレーター環境セットアップ
#   3親+6子=9ペイン統合開発環境
# ------------------------------------------------------------
set -euo pipefail

# 色設定
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# ログ関数
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_orchestrator() { echo -e "${PURPLE}[ORCHESTRATOR]${NC} $1"; }

# プロジェクト設定
PROJECT_ROOT=$(pwd)
PROJECT_NAME=$(basename "$PROJECT_ROOT")

# 親エージェント定義
get_parent_config() {
    case "$1" in
        "quill") echo "Parent1:Quill.js統合Boss:feat/parent-quill" ;;
        "webview") echo "Parent2:WebView統合Boss:feat/parent-webview" ;;
        "gemini") echo "Parent3:Gemini API Boss:feat/parent-gemini" ;;
        *) echo "" ;;
    esac
}

# 子エージェント定義
get_child_config() {
    case "$1" in
        "quill-html") echo "Child1-1:HTML Worker:html:quill" ;;
        "quill-js") echo "Child1-2:JS Worker:js:quill" ;;
        "webview-flutter") echo "Child2-1:Flutter Worker:flutter:webview" ;;
        "webview-bridge") echo "Child2-2:Bridge Worker:bridge:webview" ;;
        "gemini-api") echo "Child3-1:API Worker:api:gemini" ;;
        "gemini-response") echo "Child3-2:Response Worker:response:gemini" ;;
        *) echo "" ;;
    esac
}

# 親リスト取得
get_parent_list() {
    echo "quill webview gemini"
}

# 子リスト取得
get_child_list() {
    echo "quill-html quill-js webview-flutter webview-bridge gemini-api gemini-response"
}

# 依存関係チェック
check_dependencies() {
    log_info "依存関係をチェック中..."
    
    command -v tmux >/dev/null 2>&1 || { log_error "tmux が必要です"; exit 1; }
    command -v git >/dev/null 2>&1 || { log_error "git が必要です"; exit 1; }
    
    if [[ ! -d ".git" ]]; then
        log_error "Gitリポジトリのルートで実行してください"
        exit 1
    fi
    
    log_success "依存関係確認完了"
}

# 既存環境のクリーンアップ
cleanup_existing() {
    log_info "既存環境をクリーンアップ中..."
    
    # Tmuxセッション削除
    if tmux has-session -t orchestrator 2>/dev/null; then
        log_warning "Tmuxセッション削除: orchestrator"
        tmux kill-session -t orchestrator
    fi
    
    # 旧階層セッション削除
    for session in coordinator parents workers; do
        if tmux has-session -t "$session" 2>/dev/null; then
            log_warning "旧Tmuxセッション削除: $session"
            tmux kill-session -t "$session"
        fi
    done
    
    # Git worktreeクリーンアップ
    git worktree prune
    rm -rf ../yutori-parent-* ../yutori-coordinator ../yutori-parent* ../yutori-child*
    
    # ログディレクトリ準備
    mkdir -p logs/orchestrator
    rm -f logs/orchestrator/*.log
    
    log_success "クリーンアップ完了"
}

# Git Worktree セットアップ（簡素化版）
setup_worktrees() {
    log_orchestrator "Git Worktree（3親のみ）作成中..."
    
    # 親用Worktree作成
    for parent_key in $(get_parent_list); do
        config=$(get_parent_config "$parent_key")
        IFS=':' read -r role description branch <<< "$config"
        parent_path="../yutori-parent-${parent_key}"
        
        log_info "Parent worktree作成: $role ($parent_path)"
        git worktree add "$parent_path" -b "$branch"
        
        # 子エージェント用サブディレクトリ作成
        case "$parent_key" in
            "quill")
                mkdir -p "$parent_path"/{html,js,shared}
                log_info "  ├── html/    (Child1-1 HTML Worker作業領域)"
                log_info "  ├── js/      (Child1-2 JS Worker作業領域)"
                log_info "  └── shared/  (共通リソース)"
                ;;
            "webview")
                mkdir -p "$parent_path"/{flutter,bridge,shared}
                log_info "  ├── flutter/ (Child2-1 Flutter Worker作業領域)"
                log_info "  ├── bridge/  (Child2-2 Bridge Worker作業領域)"
                log_info "  └── shared/  (共通リソース)"
                ;;
            "gemini")
                mkdir -p "$parent_path"/{api,response,shared}
                log_info "  ├── api/     (Child3-1 API Worker作業領域)"
                log_info "  ├── response/(Child3-2 Response Worker作業領域)"
                log_info "  └── shared/  (共通リソース)"
                ;;
        esac
    done
    
    log_success "全Worktree作成完了"
    git worktree list
}

# Tmux 3×3ペイン配置作成（改良版）
setup_tmux_layout() {
    log_orchestrator "Tmux 3×3ペイン配置構築中..."
    
    # セッション作成
    log_info "orchestratorセッション作成..."
    tmux new-session -d -s orchestrator -c "../yutori-parent-quill"
    tmux rename-window -t orchestrator:0 "main"
    
    # ペイン0: Parent1 (Quill.js Boss)
    tmux send-keys -t orchestrator:0.0 "# Parent1: Quill.js統合Boss" Enter
    tmux send-keys -t orchestrator:0.0 "echo 'Ready: Parent1 (Quill.js)'" Enter
    
    # まず2×2レイアウトを作成してから追加
    log_info "基本レイアウト作成中..."
    
    # 横に2分割
    tmux split-window -t orchestrator:0 -h -c "../yutori-parent-quill/html"
    tmux send-keys -t orchestrator:0.1 "# Child1-1: HTML Worker" Enter
    tmux send-keys -t orchestrator:0.1 "echo 'Ready: Child1-1 (HTML)'" Enter
    
    # 左側（ペイン0）を縦に分割
    tmux select-pane -t orchestrator:0.0
    tmux split-window -t orchestrator:0 -v -c "../yutori-parent-webview"
    tmux send-keys -t orchestrator:0.2 "# Parent2: WebView統合Boss" Enter
    tmux send-keys -t orchestrator:0.2 "echo 'Ready: Parent2 (WebView)'" Enter
    
    # 右上（ペイン1）を縦に分割
    tmux select-pane -t orchestrator:0.1
    tmux split-window -t orchestrator:0 -v -c "../yutori-parent-webview/flutter"
    tmux send-keys -t orchestrator:0.3 "# Child2-1: Flutter Worker" Enter
    tmux send-keys -t orchestrator:0.3 "echo 'Ready: Child2-1 (Flutter)'" Enter
    
    # 小さなペインを慎重に追加
    log_info "残りペイン追加中..."
    
    # 横分割でペインを追加（容量に注意）
    if tmux split-window -t orchestrator:0.1 -h -c "../yutori-parent-quill/js" 2>/dev/null; then
        tmux send-keys -t orchestrator:0.4 "# Child1-2: JS Worker" Enter
        tmux send-keys -t orchestrator:0.4 "echo 'Ready: Child1-2 (JS)'" Enter
    else
        log_warning "ペイン4作成失敗、レイアウトを簡素化します"
    fi
    
    if tmux split-window -t orchestrator:0.3 -h -c "../yutori-parent-webview/bridge" 2>/dev/null; then
        tmux send-keys -t orchestrator:0.5 "# Child2-2: Bridge Worker" Enter
        tmux send-keys -t orchestrator:0.5 "echo 'Ready: Child2-2 (Bridge)'" Enter
    else
        log_warning "ペイン5作成失敗、レイアウトを簡素化します"
    fi
    
    if tmux split-window -t orchestrator:0.2 -v -c "../yutori-parent-gemini" 2>/dev/null; then
        tmux send-keys -t orchestrator:0.6 "# Parent3: Gemini API Boss" Enter
        tmux send-keys -t orchestrator:0.6 "echo 'Ready: Parent3 (Gemini)'" Enter
    else
        log_warning "ペイン6作成失敗、レイアウトを簡素化します"
    fi
    
    # 可能であれば残りも追加
    if tmux list-panes -t orchestrator:0 | wc -l | grep -q "^6"; then
        tmux split-window -t orchestrator:0.6 -h -c "../yutori-parent-gemini/api" 2>/dev/null || true
        tmux split-window -t orchestrator:0.6 -h -c "../yutori-parent-gemini/response" 2>/dev/null || true
    fi
    
    # レイアウト調整（エラーを無視）
    tmux select-layout -t orchestrator:0 tiled 2>/dev/null || tmux select-layout -t orchestrator:0 even-horizontal
    
    log_success "Tmuxペイン配置完成（作成されたペイン数: $(tmux list-panes -t orchestrator:0 | wc -l)）"
    
    # ペイン情報表示
    log_info "ペイン配置マップ:"
    echo "┌─────────┬─────────┬─────────┐"
    echo "│ Pane 0  │ Pane 1  │ Pane 2  │"
    echo "│Parent1  │Child1-1 │Child1-2 │"
    echo "│ Quill   │  HTML   │   JS    │"
    echo "├─────────┼─────────┼─────────┤"
    echo "│ Pane 3  │ Pane 4  │ Pane 5  │"
    echo "│Parent2  │Child2-1 │Child2-2 │"
    echo "│ WebView │ Flutter │ Bridge  │"
    echo "├─────────┼─────────┼─────────┤"
    echo "│ Pane 6  │ Pane 7  │ Pane 8  │"
    echo "│Parent3  │Child3-1 │Child3-2 │"
    echo "│ Gemini  │   API   │Response │"
    echo "└─────────┴─────────┴─────────┘"
}

# 設定ディレクトリ作成
setup_configs() {
    log_orchestrator "設定ディレクトリ作成中..."
    
    mkdir -p configs/{parent_templates,child_templates}
    
    log_success "設定ディレクトリ作成完了"
}

# Claude設定作成
setup_claude_configs() {
    log_orchestrator "Claude設定作成中..."
    
    # オーケストレーター用設定（メインプロジェクトに配置）
    cat > CLAUDE.md << 'EOF'
# ORCHESTRATOR: Claude Code統合オーケストレーター

## 役割
全体統括責任者として、ユーザーからのタスクを分解し、3つの親エージェントに指示します。

## 利用可能コマンド
- `/task <description>` - タスク分解・配布
- `/status` - 全エージェント状態確認  
- `/parent <id> <command>` - 特定親への直接指示
- `/child <p-id> <c-id> <command>` - 特定子への直接指示
- `/report` - 完了報告収集
- `/reset` - 全エージェントリセット

## 実行方法
```bash
# システム起動
./scripts/orchestrator_start.sh

# セッション接続
tmux attach-session -t orchestrator

# 通信ライブラリ読み込み
source ./scripts/communication.sh
```

## ペイン配置
```
┌─────────┬─────────┬─────────┐
│ Pane 0  │ Pane 1  │ Pane 2  │  Parent1(Quill) + 子2つ
│ Pane 3  │ Pane 4  │ Pane 5  │  Parent2(WebView) + 子2つ  
│ Pane 6  │ Pane 7  │ Pane 8  │  Parent3(Gemini) + 子2つ
└─────────┴─────────┴─────────┘
```

## タスク分解例
**入力**: "Quill.jsエディターを統合したい"
**分解**:
1. Parent1(Quill): "HTML+JS基盤実装"
   - Child1-1: "web/quill/index.html作成"
   - Child1-2: "Quill.js統合スクリプト実装"
2. Parent2(WebView): "Flutter WebView統合"
3. Parent3(Gemini): "AI機能統合"
EOF

    # 親エージェント用テンプレート
    for parent_key in $(get_parent_list); do
        config=$(get_parent_config "$parent_key")
        IFS=':' read -r role description branch <<< "$config"
        
        cat > "../yutori-parent-${parent_key}/CLAUDE.md" << EOF
# $role

## 役割
$description として、オーケストレーターからの指示を受けて子エージェントを管理します。

## 担当領域
EOF

        case "$parent_key" in
            "quill")
                cat >> "../yutori-parent-${parent_key}/CLAUDE.md" << 'EOF'
- Quill.js統合システム全体
- HTML基本構造 (Child1-1)
- JavaScript統合スクリプト (Child1-2)

## 実行コマンド
```bash
# 子エージェントに指示送信
source ../scripts/communication.sh
send_to_child 1 1 "web/quill/index.html作成開始"
send_to_child 1 2 "Quill.js統合スクリプト実装開始"
```
EOF
                ;;
            "webview")
                cat >> "../yutori-parent-${parent_key}/CLAUDE.md" << 'EOF'
- WebView統合システム全体
- Flutter WebView実装 (Child2-1)  
- Bridge通信機能 (Child2-2)

## 実行コマンド
```bash
# 子エージェントに指示送信
source ../scripts/communication.sh
send_to_child 2 1 "Flutter WebView実装開始"
send_to_child 2 2 "Bridge通信機能実装開始"
```
EOF
                ;;
            "gemini")
                cat >> "../yutori-parent-${parent_key}/CLAUDE.md" << 'EOF'
- Gemini API統合システム全体
- API基盤実装 (Child3-1)
- レスポンス処理 (Child3-2)

## 実行コマンド
```bash
# 子エージェントに指示送信
source ../scripts/communication.sh
send_to_child 3 1 "Gemini API基盤実装開始"
send_to_child 3 2 "レスポンス処理実装開始"
```
EOF
                ;;
        esac
    done
    
    log_success "Claude設定完了"
}

# メイン実行
main() {
    log_orchestrator "🎯 Claude Code オーケストレーター環境セットアップ開始"
    
    check_dependencies
    cleanup_existing
    setup_worktrees
    setup_tmux_layout
    setup_configs
    setup_claude_configs
    
    log_success "🎉 オーケストレーター環境セットアップ完了！"
    
    echo ""
    log_orchestrator "📋 接続方法:"
    echo "tmux attach-session -t orchestrator"
    echo ""
    
    log_orchestrator "🚀 次のステップ:"
    echo "1. tmux セッションに接続"
    echo "2. 各ペインでClaude Code起動"
    echo "3. オーケストレーターから指示開始"
    echo ""
    
    log_orchestrator "📖 参考情報:"
    echo "設計書: scripts/21_DESIGN_orchestrator_architecture.md"
    echo "通信ライブラリ: scripts/communication.sh (次に作成)"
    echo ""
    
    log_warning "⚠️ 3×3=9ペイン構成です。ターミナルサイズを十分に確保してください。"
}

# 実行
main "$@" 