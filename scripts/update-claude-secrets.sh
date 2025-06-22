#!/usr/bin/env bash
# ------------------------------------------------------------
#   update-claude-secrets.sh
#   キーチェーンからClaudeのトークンを取得し、
#   指定されたGitHubリポジトリのSecretsを更新します。
# ------------------------------------------------------------
set -euo pipefail

### 0. 依存チェック ---------------------------------------------------------
for cmd in gh jq; do
  command -v $cmd >/dev/null 2>&1 || { echo "❌  $cmd が必要です"; exit 1; }
done

### 1. Claude認証情報の取得 -----------------------------------------------
echo "🔑  キーチェーンからClaude Code認証情報を取得中..."
# コマンドが見つからない場合やデータがない場合でもエラーで終了しないようにする
KEYCHAIN_DATA=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null || true)

if [[ -z "$KEYCHAIN_DATA" ]]; then
  # フォールバック: 従来のcredentials.jsonファイル
  CRED_FILE="${HOME}/.claude/.credentials.json"
  echo "ℹ️   キーチェーンに情報がありません。${CRED_FILE} を確認します。"
  if [[ -f "$CRED_FILE" ]]; then
    echo "📁  ${CRED_FILE} から認証情報を取得"
    KEYCHAIN_DATA=$(cat "$CRED_FILE")
  else
    echo "❌  Claude Code認証情報が見つかりません"
    echo "   以下のいずれかを実行して、認証情報を取得してください："
    echo "   1. VSCodeのClaude Code拡張機能でログイン"
    echo "   2. Claude CLI (`claude` コマンド) で `/login` を実行"
    exit 1
  fi
else
  echo "✅  キーチェーンから認証情報を取得しました"
fi

### 2. トークン抽出 ---------------------------------------------------------
echo "🔧  トークン情報を抽出中..."
ACCESS=$(echo "$KEYCHAIN_DATA" | jq -r '.claudeAiOauth.accessToken // .access_token')
REFRESH=$(echo "$KEYCHAIN_DATA" | jq -r '.claudeAiOauth.refreshToken // .refresh_token')
EXPIRES=$(echo "$KEYCHAIN_DATA" | jq -r '.claudeAiOauth.expiresAt // .expires_at')

if [[ "$ACCESS" == "null" || -z "$ACCESS" ]]; then
  echo "❌  トークン情報の抽出に失敗しました。"
  echo "   取得したデータが正しいか、Claudeにログインできているか確認してください。"
  exit 1
fi
echo "✅  トークン情報を正常に抽出しました。"


### 3. 対象リポジトリの指定 -------------------------------------------------
read -p $'\n🎯  Secretsを更新したいリポジトリ (例: owner/repo): ' TARGET_REPO
if [[ -z "$TARGET_REPO" ]]; then
  echo "❌  リポジトリ名が入力されていません。処理を中止します。"
  exit 1
fi

### 4. Secrets 登録・更新 -------------------------------------------------
echo -e "\n🔒  リポジトリ '$TARGET_REPO' のSecretsを更新します..."
if ! gh secret set CLAUDE_ACCESS_TOKEN --body "$ACCESS" --repo "$TARGET_REPO"; then
  echo "❌  CLAUDE_ACCESS_TOKEN の設定に失敗しました。"
  echo "   リポジトリ名が正しいか、権限があるか確認してください。"
  exit 1
fi
echo "   - CLAUDE_ACCESS_TOKEN を更新しました"

if ! gh secret set CLAUDE_REFRESH_TOKEN --body "$REFRESH" --repo "$TARGET_REPO"; then
  echo "❌  CLAUDE_REFRESH_TOKEN の設定に失敗しました。"
  exit 1
fi
echo "   - CLAUDE_REFRESH_TOKEN を更新しました"

if ! gh secret set CLAUDE_EXPIRES_AT --body "$EXPIRES" --repo "$TARGET_REPO"; then
  echo "❌  CLAUDE_EXPIRES_AT の設定に失敗しました。"
  exit 1
fi
echo "   - CLAUDE_EXPIRES_AT を更新しました"


echo -e "\n🎉  すべてのSecretsが正常に更新されました！" 