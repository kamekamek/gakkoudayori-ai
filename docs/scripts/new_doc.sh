#!/bin/bash
# docs/scripts/new_doc.sh
# 新規ドキュメント作成スクリプト

category=$1
title=$2

if [ -z "$category" ] || [ -z "$title" ]; then
    echo "Usage: ./new_doc.sh CATEGORY title"
    echo "Example: ./new_doc.sh SPEC ai_integration"
    echo ""
    echo "Available categories:"
    echo "  REQUIREMENT (01-09): 要件定義"
    echo "  DESIGN (10-19): 設計書"
    echo "  SPEC (20-29): 技術仕様"
    echo "  API (30-39): API仕様"
    echo "  GUIDE (40-49): ガイド・手順書"
    echo "  STRATEGY (50-59): 戦略・計画"
    echo "  RULE (60-69): ルール・規約"
    echo "  TEST (70-79): テスト・品質"
    echo "  DEPLOY (80-89): デプロイ・運用"
    echo "  MISC (90-99): その他・補助資料"
    exit 1
fi

# 次の空き番号を検索
case $category in
    "REQUIREMENT") range="01 02 03 04 05 06 07 08 09" ;;
    "DESIGN") range="10 11 12 13 14 15 16 17 18 19" ;;
    "SPEC") range="20 21 22 23 24 25 26 27 28 29" ;;
    "API") range="30 31 32 33 34 35 36 37 38 39" ;;
    "GUIDE") range="40 41 42 43 44 45 46 47 48 49" ;;
    "STRATEGY") range="50 51 52 53 54 55 56 57 58 59" ;;
    "RULE") range="60 61 62 63 64 65 66 67 68 69" ;;
    "TEST") range="70 71 72 73 74 75 76 77 78 79" ;;
    "DEPLOY") range="80 81 82 83 84 85 86 87 88 89" ;;
    "MISC") range="90 91 92 93 94 95 96 97 98 99" ;;
    *) echo "Unknown category: $category"; exit 1 ;;
esac

for num in $range; do
    filename="${num}_${category}_${title}.md"
    if [ ! -f "docs/$filename" ]; then
        echo "Creating: $filename"
        
        cat > "docs/$filename" << EOF
# ${title}

**カテゴリ**: ${category}
**作成日**: $(date +%Y-%m-%d)
**作成者**: $(whoami)

## 1. 概要

## 2. 詳細

## 3. 実装

## 4. 参考資料

EOF
        echo "✅ Created: docs/$filename"
        exit 0
    fi
done

echo "❌ No available number in range for $category"
exit 1 