#!/bin/bash
# docs/scripts/analyze_docs.sh
# ドキュメント分析・最適化スクリプト

echo "# 📊 ドキュメント分析レポート"
echo "**生成日**: $(date +%Y-%m-%d)"
echo

echo "## 📏 サイズ分析"
echo "| ファイル | サイズ | 推奨アクション |"
echo "|---------|--------|---------------|"

total_size=0
large_files=0

for file in docs/[0-9][0-9]_*.md; do
    if [ -f "$file" ]; then
        size=$(wc -c < "$file")
        name=$(basename "$file")
        total_size=$((total_size + size))
        
        if [ $size -gt 10000 ]; then
            action="🔥 分割推奨"
            large_files=$((large_files + 1))
        elif [ $size -gt 7000 ]; then
            action="⚠️ 要注意"
        else
            action="✅ 適正"
        fi
        
        echo "| $name | ${size}B | $action |"
    fi
done

echo
echo "## 📊 統計"
echo "- **総サイズ**: ${total_size}B"
echo "- **大型ファイル数**: ${large_files}個（10KB超）"
echo "- **平均サイズ**: $((total_size / 9))B"

echo
echo "## 🔍 TL;DR存在チェック"
echo "| ファイル | TL;DR | アクション |"
echo "|---------|-------|-----------|"

for file in docs/[0-9][0-9]_*.md; do
    if [ -f "$file" ]; then
        name=$(basename "$file")
        if grep -q "TL;DR" "$file"; then
            echo "| $name | ✅ | - |"
        else
            echo "| $name | ❌ | TL;DR追加推奨 |"
        fi
    fi
done

echo
echo "## 📈 最適化提案"

if [ $large_files -gt 0 ]; then
    echo "### 🔥 優先度高：分割推奨ファイル"
    for file in docs/[0-9][0-9]_*.md; do
        if [ -f "$file" ]; then
            size=$(wc -c < "$file")
            if [ $size -gt 10000 ]; then
                name=$(basename "$file")
                echo "- **$name** (${size}B): 機能別または階層別で分割"
            fi
        fi
    done
fi

echo
echo "### 💡 全体的な改善案"
echo "1. **統一テンプレート適用**: すべてのファイルにTL;DRセクション追加"
echo "2. **関連ドキュメント表**: 依存関係の明確化"
echo "3. **メタデータ追加**: 複雑度・読了時間・更新頻度"
echo "4. **タグシステム**: #frontend #backend #ai などの分類"

echo
echo "---"
echo "**実行コマンド**: \`./docs/scripts/analyze_docs.sh\`" 