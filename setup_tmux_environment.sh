#!/bin/bash
# yutori_parallel_setup.sh
# 学校だよりAI - tmux並列開発環境セットアップ

echo "🚀 ゆとり職員室 - tmux並列開発環境をセットアップします"

# メインセッション作成
echo "📱 メインセッション作成中..."
tmux new-session -d -s yutori -n "main"

# 並列実装ストリーム
echo "🏗️  並列実装ウィンドウ作成中..."
tmux new-window -t yutori:1 -n "gcp-setup"     # GCP Manual設定 → AI Infrastructure
tmux new-window -t yutori:2 -n "flutter-dev"   # Flutter開発 → Frontend Editor
tmux new-window -t yutori:3 -n "firebase-setup" # Firebase設定 → Data Layer
tmux new-window -t yutori:4 -n "integration"   # 統合・テスト・問題解決

# ペイン分割 (各ストリームでcode + logs)
echo "📂 ペイン分割中..."
tmux split-window -h -t yutori:1  # gcp-setup: 左=コマンド実行, 右=ログ監視
tmux split-window -h -t yutori:2  # flutter-dev: 左=開発, 右=テスト実行
tmux split-window -h -t yutori:3  # firebase-setup: 左=設定, 右=モニタリング
tmux split-window -h -t yutori:4  # integration: 左=統合テスト, 右=デバッグ

# 各ペインの初期化
echo "⚙️  各ペイン初期化中..."

# GCP Setup pane
tmux send-keys -t yutori:1.0 'echo "🔧 GCP Manual設定セッション"' Enter
tmux send-keys -t yutori:1.0 'echo "Task: T1-GCP-001-M → Google Cloudプロジェクト作成"' Enter

# Flutter Dev pane  
tmux send-keys -t yutori:2.0 'echo "🎨 Flutter開発セッション"' Enter
tmux send-keys -t yutori:2.0 'cd frontend' Enter
tmux send-keys -t yutori:2.0 'echo "Task: T1-FL-001-M → Flutter Web環境構築"' Enter

# Firebase Setup pane
tmux send-keys -t yutori:3.0 'echo "🔥 Firebase設定セッション"' Enter  
tmux send-keys -t yutori:3.0 'echo "Task: T1-FB-001-M → Firebaseプロジェクト設定"' Enter

# Integration pane
tmux send-keys -t yutori:4.0 'echo "🔄 統合・テストセッション"' Enter
tmux send-keys -t yutori:4.0 'echo "Ready for integration testing..."' Enter

# ログペインの設定
tmux send-keys -t yutori:1.1 'echo "📊 GCP操作ログ監視"' Enter
tmux send-keys -t yutori:2.1 'echo "🧪 Flutter テスト実行"' Enter  
tmux send-keys -t yutori:3.1 'echo "📈 Firebase モニタリング"' Enter
tmux send-keys -t yutori:4.1 'echo "🐛 デバッグ・問題解決"' Enter

# 最初のウィンドウをアクティブに
tmux select-window -t yutori:1

echo ""
echo "✅ tmux yutori session ready!"
echo ""
echo "🎯 接続方法:"
echo "   tmux attach -t yutori"
echo ""
echo "📋 セッション構成:"
echo "   yutori:1 - gcp-setup     (GCP Manual設定)"
echo "   yutori:2 - flutter-dev   (Flutter開発)"  
echo "   yutori:3 - firebase-setup(Firebase設定)"
echo "   yutori:4 - integration   (統合・テスト)"
echo ""
echo "⚡ 並列実行コマンド例:"
echo "   tmux send-keys -t yutori:1 'your-command' Enter"
echo ""
echo "🚀 Phase 1開始準備完了！" 