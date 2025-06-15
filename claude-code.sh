#!/usr/bin/env bash
# ------------------------------------------------------------
#   all_in_one_claude_setup.sh
#   Qiita「Claude Maxプラン料金内でClaude Code GitHub Actionsを使うためのガイドまとめ」
#   に書かれた全プロセスを完全自動化
#   + Pro/Maxプラン対応、既存workflow保護、developブランチ対応
# ------------------------------------------------------------
set -euo pipefail

### 0. 依存チェック ---------------------------------------------------------
for cmd in gh git jq sed; do
  command -v $cmd >/dev/null 2>&1 || { echo "❌  $cmd が必要です"; exit 1; }
done

### 1. 基本情報 ------------------------------------------------------------
GH_USER=$(gh api user -q .login)                     # ログイン中の GitHub ID
echo "👤  GitHub ユーザー名: $GH_USER"

# Claude Code認証情報の取得（キーチェーンから）
echo "🔑  キーチェーンからClaude Code認証情報を取得中..."
KEYCHAIN_DATA=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null)
if [[ -z "$KEYCHAIN_DATA" ]]; then
  # フォールバック: 従来のcredentials.jsonファイル
  CRED_FILE="${HOME}/.claude/.credentials.json"
  if [[ -f "$CRED_FILE" ]]; then
    echo "📁  ~/.claude/.credentials.json から認証情報を取得"
    KEYCHAIN_DATA=$(cat "$CRED_FILE")
  else
    echo "❌  Claude Code認証情報が見つかりません"
    echo "   以下のいずれかを実行してください："
    echo "   1. Claude CLI で /login を実行"
    echo "   2. Claude Code拡張機能でログイン"
    exit 1
  fi
else
  echo "✅  キーチェーンから認証情報を取得しました"
fi

# Claude トークン抽出
ACCESS=$(echo "$KEYCHAIN_DATA" | jq -r '.claudeAiOauth.accessToken // .access_token')
REFRESH=$(echo "$KEYCHAIN_DATA" | jq -r '.claudeAiOauth.refreshToken // .refresh_token')
EXPIRES=$(echo "$KEYCHAIN_DATA" | jq -r '.claudeAiOauth.expiresAt // .expires_at')
[[ "$ACCESS" == "null" || -z "$ACCESS" ]] && { echo "❌  トークン抽出に失敗"; exit 1; }

### 2. Fork 必要リポジトリ ---------------------------------------------------
echo -e "\n🚀  claude-code-action / base-action を fork します"
for R in claude-code-action claude-code-base-action; do
  SRC="Akira-Papa/${R}"                               # オリジナル
  gh repo fork "$SRC" --clone=false --remote=false >/dev/null
  echo "   - Forked: $GH_USER/$R"
done

### 3. claude-code-action の中身を修正 ------------------------------------
WORK_DIR="$(mktemp -d)"
echo "📁  一時ディレクトリ: $WORK_DIR"
gh repo clone "$GH_USER/claude-code-action" "$WORK_DIR" >/dev/null

# action.ymlファイルの存在確認
if [[ ! -f "$WORK_DIR/action.yml" ]]; then
  echo "❌  action.yml が見つかりません"
  ls -la "$WORK_DIR"
  rm -rf "$WORK_DIR"
  exit 1
fi

echo "🔧  action.yml を修正中..."
sed -i.bak "s#Akira-Papa/claude-code-base-action#$GH_USER/claude-code-base-action#g" \
  "$WORK_DIR"/action.yml

# 変更内容を確認
echo "📝  変更内容:"
diff "$WORK_DIR/action.yml.bak" "$WORK_DIR/action.yml" || true

(
  cd "$WORK_DIR"
  git config user.name  "$GH_USER"
  git config user.email "${GH_USER}@users.noreply.github.com"
  
  # 変更があるかチェック
  if git diff --quiet; then
    echo "⚠️   変更がありません。既に修正済みの可能性があります"
  else
    echo "💾  変更をコミット中..."
    git commit -am "chore: point to my base-action"
    echo "🚀  プッシュ中..."
    git push origin main
  fi
)
rm -rf "$WORK_DIR"
echo "✅  claude-code-action を自分の base-action 参照に更新"

### 4. GitHub App のインストール確認 ----------------------------------------
echo -e "\n🔍  Claude GitHub App のインストールを確認"
# GitHub App インストール確認をスキップ（権限の問題があるため）
echo "ℹ️   GitHub App インストール確認をスキップします"
echo "   Claude GitHub App が未インストールの場合は以下のURLから手動でインストールしてください："
echo "   https://github.com/apps/claude"

### 5. Claude を使いたい対象リポジトリ ------------------------------------
read -p $'\n🎯  Claude を有効化したいリポジトリ (owner/repo): ' TARGET_REPO
[[ -z "$TARGET_REPO" ]] && { echo "❌  入力必須"; exit 1; }

### 6. プラン選択 ----------------------------------------------------------
echo -e "\n📋  Claude プランを選択してください:"
echo "   1) Pro プラン (model指定あり: claude-sonnet-4-20250514)"
echo "   2) Max プラン (model指定なし)"
read -p "選択 (1/2): " PLAN_CHOICE

MODEL_CONFIG=""
case "$PLAN_CHOICE" in
  1)
    MODEL_CONFIG="          model: 'claude-sonnet-4-20250514'"
    echo "✅  Pro プラン用設定を適用します"
    ;;
  2)
    echo "✅  Max プラン用設定を適用します"
    ;;
  *)
    echo "❌  無効な選択です"
    exit 1
    ;;
esac

### 7. Secrets 登録（Step4） ------------------------------------------------
echo "🔑  Secrets を追加します -> $TARGET_REPO"
gh secret set CLAUDE_ACCESS_TOKEN  --body "$ACCESS"  --repo "$TARGET_REPO"
gh secret set CLAUDE_REFRESH_TOKEN --body "$REFRESH" --repo "$TARGET_REPO"
gh secret set CLAUDE_EXPIRES_AT    --body "$EXPIRES" --repo "$TARGET_REPO"

### 8. ブランチ戦略の確認 ---------------------------------------------------
TMP_DIR="$(mktemp -d)"
gh repo clone "$TARGET_REPO" "$TMP_DIR" -- -q >/dev/null

# デフォルトブランチを取得
DEFAULT_BRANCH=$(gh repo view "$TARGET_REPO" --json defaultBranchRef -q .defaultBranchRef.name)
echo -e "\n🌿  ブランチ戦略を選択してください:"
echo "   1) ${DEFAULT_BRANCH} ブランチベース → ${DEFAULT_BRANCH} へマージ"
echo "   2) develop ブランチベース → develop へマージ"
echo "   3) develop ブランチベース → ${DEFAULT_BRANCH} へマージ"
read -p "選択 (1/2/3): " BRANCH_CHOICE

case "$BRANCH_CHOICE" in
  1)
    BASE_BRANCH="$DEFAULT_BRANCH"
    TARGET_BRANCH="$DEFAULT_BRANCH"
    ;;
  2)
    BASE_BRANCH="develop"
    TARGET_BRANCH="develop"
    ;;
  3)
    BASE_BRANCH="develop"
    TARGET_BRANCH="$DEFAULT_BRANCH"
    ;;
  *)
    echo "❌  無効な選択です"
    exit 1
    ;;
esac

### 9. Workflow 作成 → ブランチ → PR --------------------------------------
(
  cd "$TMP_DIR"
  
  # ベースブランチに切り替え（存在しない場合はデフォルトブランチから作成）
  if git show-ref --verify --quiet "refs/remotes/origin/$BASE_BRANCH"; then
    git checkout "$BASE_BRANCH" >/dev/null
    git pull origin "$BASE_BRANCH" >/dev/null
  else
    echo "⚠️   $BASE_BRANCH ブランチが存在しません。$DEFAULT_BRANCH から作成します"
    git checkout -b "$BASE_BRANCH" >/dev/null
    git push -u origin "$BASE_BRANCH" >/dev/null
  fi
  
  # 作業ブランチ作成
  WORK_BRANCH="add-claude-workflow-$(date +%Y%m%d-%H%M%S)"
  
  # 既存の同名ブランチがある場合は削除
  if git show-ref --verify --quiet "refs/heads/$WORK_BRANCH"; then
    echo "⚠️   既存のブランチ $WORK_BRANCH を削除します"
    git branch -D "$WORK_BRANCH" >/dev/null
  fi
  
  git checkout -b "$WORK_BRANCH" >/dev/null
  echo "🌿  作業ブランチ作成: $WORK_BRANCH"
  
  mkdir -p .github/workflows
  
  # 既存のclaude.ymlをチェック
  if [[ -f ".github/workflows/claude.yml" ]]; then
    echo "⚠️   既存の claude.yml を発見しました"
    BACKUP_FILE=".github/workflows/claude.yml.backup.$(date +%Y%m%d-%H%M%S)"
    cp ".github/workflows/claude.yml" "$BACKUP_FILE"
    echo "📁  バックアップを作成: $BACKUP_FILE"
    
    read -p "🔄  既存ファイルを上書きしますか？ (y/N): " OVERWRITE
    if [[ ! "$OVERWRITE" =~ ^[Yy]$ ]]; then
      echo "❌  処理を中止しました"
      exit 1
    fi
  fi
  
  # claude.yml生成
  cat > .github/workflows/claude.yml <<EOF
name: Claude Code
on:
  issue_comment:
    types: [created]
  pull_request_review_comment:
    types: [created]
  issues:
    types: [opened, assigned]
  pull_request_review:
    types: [submitted]

jobs:
  claude:
    if: |
      (github.event_name == 'issue_comment' && contains(github.event.comment.body, '@claude')) ||
      (github.event_name == 'pull_request_review_comment' && contains(github.event.comment.body, '@claude')) ||
      (github.event_name == 'pull_request_review' && contains(github.event.review.body, '@claude')) ||
      (github.event_name == 'issues' && (contains(github.event.issue.body, '@claude') || contains(github.event.issue.title, '@claude')))
    runs-on: ubuntu-latest
    permissions:
      contents: write
      pull-requests: write
      issues: write
      id-token: write
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 1
      - name: Run Claude Code
        uses: ${GH_USER}/claude-code-action@main
        with:
          use_oauth: 'true'
          claude_access_token: \${{ secrets.CLAUDE_ACCESS_TOKEN }}
          claude_refresh_token: \${{ secrets.CLAUDE_REFRESH_TOKEN }}
          claude_expires_at: \${{ secrets.CLAUDE_EXPIRES_AT }}${MODEL_CONFIG:+
$MODEL_CONFIG}
EOF

  git add .github/workflows/
  
  # コミットメッセージを動的生成
  COMMIT_MSG="Add Claude GitHub Action workflow"
  [[ -n "$MODEL_CONFIG" ]] && COMMIT_MSG="$COMMIT_MSG (Pro plan with model config)"
  [[ -f "$BACKUP_FILE" ]] && COMMIT_MSG="$COMMIT_MSG - backup existing config"
  
  git commit -m "$COMMIT_MSG" >/dev/null
  git push -u origin "$WORK_BRANCH" >/dev/null
  
  # PR作成
  PR_TITLE="🤖 Add Claude GitHub Action workflow"
  PR_BODY="## 概要
Claude Code GitHub Action を追加します。

## 変更内容
- Claude GitHub Action workflow を追加
- プラン: $([ -n "$MODEL_CONFIG" ] && echo "Pro (model指定あり)" || echo "Max (model指定なし)")
- ベースブランチ: $BASE_BRANCH
- マージ先: $TARGET_BRANCH

$([ -f "$BACKUP_FILE" ] && echo "## 注意
既存の claude.yml のバックアップを作成しました: \`$BACKUP_FILE\`")

## 使用方法
Issue や PR で \`@claude\` とメンションしてください。

## 関連
- [Claude Code GitHub Actions ガイド](https://qiita.com/example)"

  echo "🔄  PR作成中..."
  
  # PR作成（ラベルなしで実行、エラーハンドリング付き）
  if gh pr create --title "$PR_TITLE" --body "$PR_BODY" \
                  --repo "$TARGET_REPO" --head "$WORK_BRANCH" --base "$TARGET_BRANCH" \
                  --assignee "$GH_USER" 2>/dev/null; then
    echo "✅  PR作成成功"
    # 作成されたPR番号を取得
    PR_NUMBER=$(gh pr list --repo "$TARGET_REPO" --head "$WORK_BRANCH" --json number -q '.[0].number')
    echo "📝  PR番号: #$PR_NUMBER"
    
    # ラベル追加を試行（失敗しても続行）
    if gh pr edit "$PR_NUMBER" --add-label "automation" --repo "$TARGET_REPO" 2>/dev/null; then
      echo "🏷️   ラベル 'automation' を追加しました"
    else
      echo "⚠️   ラベル 'automation' の追加に失敗（ラベルが存在しない可能性があります）"
    fi
  else
    echo "❌  PR作成に失敗しました"
    echo "   手動でPRを作成してください："
    echo "   ブランチ: $WORK_BRANCH → $TARGET_BRANCH"
    exit 1
  fi
)

# PR作成結果の確認
echo ""
if PR_URL=$(gh pr list --repo "$TARGET_REPO" --head "add-claude-workflow-*" --json url -q '.[0].url' 2>/dev/null) && [[ -n "$PR_URL" ]]; then
  echo "✅  PR を作成しました → $PR_URL"
  
  read -p "🔄  $TARGET_BRANCH ブランチへ自動マージしますか？ (y/N): " AUTO_MERGE
  if [[ "$AUTO_MERGE" =~ ^[Yy]$ ]]; then
    # 最新のPR番号を取得
    LATEST_PR=$(gh pr list --repo "$TARGET_REPO" --head "add-claude-workflow-*" --json number -q '.[0].number' 2>/dev/null)
    if [[ -n "$LATEST_PR" ]]; then
      if gh pr merge "$LATEST_PR" --squash --delete-branch --repo "$TARGET_REPO" 2>/dev/null; then
        echo "🎉  マージ完了！"
      else
        echo "❌  マージに失敗しました。手動でマージしてください"
      fi
    else
      echo "❌  PR番号の取得に失敗しました"
    fi
  else
    echo "🕒  GitHub 上でレビュー → Merge してください"
  fi
else
  echo "⚠️   PR作成の確認に失敗しました"
  echo "   GitHub上で手動確認してください: https://github.com/$TARGET_REPO/pulls"
fi

# クリーンアップ
rm -rf "$TMP_DIR"

echo -e "\n🚀  セットアップ完了！ Issue や PR で \`@claude\` とメンションして動作を確認してみてください 🎩"
echo -e "📋  設定内容:"
echo -e "   - プラン: $([ -n "$MODEL_CONFIG" ] && echo "Pro (model指定あり)" || echo "Max (model指定なし)")"
echo -e "   - ベースブランチ: $BASE_BRANCH"
echo -e "   - マージ先: $TARGET_BRANCH"
