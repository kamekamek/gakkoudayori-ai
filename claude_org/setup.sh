#!/bin/bash
set -e

echo "🤖 Multi-Agent Communication System Setup"
echo "=========================================="

# 既存セッションクリーンアップ
tmux kill-session -t multiagent 2>/dev/null || true
tmux kill-session -t president 2>/dev/null || true

# multiagentセッション作成（4ペイン）
tmux new-session -d -s multiagent -n "agents"
tmux split-window -h -t "multiagent:0"
tmux select-pane -t "multiagent:0.0"
tmux split-window -v
tmux select-pane -t "multiagent:0.2"
tmux split-window -v

# ペインタイトル設定
PANE_TITLES=("boss1" "worker1" "worker2" "worker3")
for i in {0..3}; do
    tmux select-pane -t "multiagent:0.$i" -T "${PANE_TITLES[$i]}"
    tmux send-keys -t "multiagent:0.$i" "cd $(pwd)" C-m
    
    if [ $i -eq 0 ]; then
        # boss1: 赤色
        tmux send-keys -t "multiagent:0.$i" "export PS1='(\\[\\033[1;31m\\]${PANE_TITLES[$i]}\\[\\033[0m\\]) \\[\\033[1;32m\\]\\w\\[\\033[0m\\]\\$ '" C-m
    else
        # workers: 青色
        tmux send-keys -t "multiagent:0.$i" "export PS1='(\\[\\033[1;34m\\]${PANE_TITLES[$i]}\\[\\033[0m\\]) \\[\\033[1;32m\\]\\w\\[\\033[0m\\]\\$ '" C-m
    fi
    
    tmux send-keys -t "multiagent:0.$i" "echo '=== ${PANE_TITLES[$i]} エージェント ==='" C-m
done

# presidentセッション作成
tmux new-session -d -s president
tmux send-keys -t president "cd $(pwd)" C-m
tmux send-keys -t president "export PS1='(\\[\\033[1;35m\\]PRESIDENT\\[\\033[0m\\]) \\[\\033[1;32m\\]\\w\\[\\033[0m\\]\\$ '" C-m
tmux send-keys -t president "echo '=== PRESIDENT セッション ==='" C-m

echo "✅ Setup完了！"
echo "次のステップ:"
echo "1. tmux attach-session -t president"
echo "2. tmux attach-session -t multiagent"