# ドキュメント命名規則

## 1. 概要

プロジェクトドキュメントの一貫した管理のための命名規則を定義します。

## 2. 命名ルール

### 2.1 基本フォーマット

```
{ナンバー}_{カテゴリ}_{タイトル}.md
```

- **ナンバー**: 2桁の数字（01, 02, 03...）
- **カテゴリ**: 大文字英語（REQUIREMENT, DESIGN, SPEC等）
- **タイトル**: アンダースコア区切りの英語

### 2.2 カテゴリ定義

| カテゴリ | 説明 | 例 |
|---------|------|-----|
| **REQUIREMENT** | 要件定義 | `01_REQUIREMENT_overview.md` |
| **DESIGN** | 設計書 | `02_DESIGN_architecture.md` |
| **SPEC** | 技術仕様 | `03_SPEC_quill_integration.md` |
| **API** | API仕様 | `04_API_endpoints.md` |
| **GUIDE** | ガイド・手順書 | `05_GUIDE_deployment.md` |
| **STRATEGY** | 戦略・計画 | `06_STRATEGY_implementation.md` |
| **RULE** | ルール・規約 | `07_RULE_coding_standards.md` |

### 2.3 ナンバリング体系

```
01-09: 要件・概要系
10-19: 設計・アーキテクチャ系
20-29: 技術仕様系
30-39: API・インターフェース系
40-49: ガイド・手順系
50-59: 戦略・計画系
60-69: ルール・規約系
70-79: テスト・品質系
80-89: デプロイ・運用系
90-99: その他・補助資料
```

## 3. 現在のファイル構造

```
docs/
├── 01_REQUIREMENT_overview.md        # メイン要件定義
├── 10_DESIGN_color_palettes.md       # 季節カラーパレット設計
├── 20_SPEC_quill_integration.md      # Quill.js統合仕様
├── 21_SPEC_ai_prompts.md             # AIプロンプト仕様
├── 22_SPEC_ai_assistant_panel.md     # AI補助UI仕様
├── 50_STRATEGY_implementation.md     # 実装計画
├── 51_STRATEGY_restart.md            # 再開戦略
├── 52_STRATEGY_plan_overview.md      # 計画概要
├── 60_RULE_naming_rules.md           # 本ファイル
├── README.md                         # プロジェクト概要
└── HACKASON_RULE.md                  # ハッカソンルール（特別）
```

## 4. ファイル作成・変更時のルール

### 4.1 新規作成時

1. **カテゴリを決定**
2. **適切なナンバーを割り当て**（空き番号を使用）
3. **タイトルは簡潔で分かりやすく**
4. **作成者・作成日を記載**

### 4.2 変更・更新時

1. **ファイル名は変更しない**（履歴保持のため）
2. **大幅な変更時は新バージョンを作成**
3. **古いバージョンはArchiveに移動**

### 4.3 削除・アーカイブ時

1. **削除前にArchive/old-docsに移動**
2. **削除理由をREADMEに記載**
3. **関連ファイルからの参照を更新**

## 5. 自動化スクリプト

### 5.1 新規ドキュメント作成

```bash
#!/bin/bash
# docs/scripts/new_doc.sh

category=$1
title=$2

if [ -z "$category" ] || [ -z "$title" ]; then
    echo "Usage: ./new_doc.sh CATEGORY title"
    echo "Example: ./new_doc.sh SPEC ai_integration"
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
        echo "Created: docs/$filename"
        exit 0
    fi
done

echo "No available number in range for $category"
exit 1
```

### 5.2 ドキュメントリスト生成

```bash
#!/bin/bash
# docs/scripts/list_docs.sh

echo "# ドキュメント一覧"
echo
echo "| ナンバー | カテゴリ | タイトル | ファイル名 |"
echo "|---------|---------|----------|-----------|"

for file in docs/[0-9][0-9]_*.md; do
    if [ -f "$file" ]; then
        basename=$(basename "$file" .md)
        number=$(echo "$basename" | cut -d'_' -f1)
        category=$(echo "$basename" | cut -d'_' -f2)
        title=$(echo "$basename" | cut -d'_' -f3-)
        
        echo "| $number | $category | $title | [$basename.md]($file) |"
    fi
done
```

## 6. 適用手順

1. **既存ファイルのリネーム**
2. **スクリプトの作成と権限設定**
3. **READMEの更新**
4. **チーム共有** 