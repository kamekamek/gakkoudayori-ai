#!/bin/bash
# docs/scripts/list_docs.sh
# ドキュメント一覧生成スクリプト

echo "# 📚 ドキュメント一覧"
echo
echo "**最終更新**: $(date +%Y-%m-%d)"
echo
echo "| No. | カテゴリ | タイトル | ファイル名 |"
echo "|-----|----------|----------|-----------|"

# 番号順にソートして表示
for file in $(ls docs/[0-9][0-9]_*.md 2>/dev/null | sort); do
    if [ -f "$file" ]; then
        basename=$(basename "$file" .md)
        number=$(echo "$basename" | cut -d'_' -f1)
        category=$(echo "$basename" | cut -d'_' -f2)
        title=$(echo "$basename" | cut -d'_' -f3- | tr '_' ' ')
        
        echo "| $number | $category | $title | [$basename.md]($file) |"
    fi
done

echo
echo "## 📁 その他のファイル"
echo
echo "| ファイル名 | 説明 |"
echo "|-----------|------|"

# 特別なファイル
if [ -f "docs/README.md" ]; then
    echo "| [README.md](docs/README.md) | プロジェクト概要 |"
fi

if [ -f "docs/HACKASON_RULE.md" ]; then
    echo "| [HACKASON_RULE.md](docs/HACKASON_RULE.md) | ハッカソンルール |"
fi

echo
echo "## 📂 アーカイブ"
echo
if [ -d "docs/Archive" ]; then
    archive_count=$(find docs/Archive -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
    echo "- **Archive/**: $archive_count 個のアーカイブファイル"
fi

echo
echo "---"
echo "**生成コマンド**: \`./docs/scripts/list_docs.sh\`" 