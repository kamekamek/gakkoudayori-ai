# 📚 ドキュメント一覧

**最終更新**: 2025-06-09

| No. | カテゴリ | タイトル | ファイル名 |
|-----|----------|----------|-----------|
| 01 | REQUIREMENT | overview | [01_REQUIREMENT_overview.md](01_REQUIREMENT_overview.md) |
| 10 | DESIGN | color palettes | [10_DESIGN_color_palettes.md](10_DESIGN_color_palettes.md) |
| 20 | SPEC | quill integration | [20_SPEC_quill_integration.md](20_SPEC_quill_integration.md) |
| 21 | SPEC | ai prompts | [21_SPEC_ai_prompts.md](21_SPEC_ai_prompts.md) |
| 22 | SPEC | ai assistant panel | [22_SPEC_ai_assistant_panel.md](22_SPEC_ai_assistant_panel.md) |
| 50 | STRATEGY | implementation | [50_STRATEGY_implementation.md](50_STRATEGY_implementation.md) |
| 51 | STRATEGY | restart | [51_STRATEGY_restart.md](51_STRATEGY_restart.md) |
| 52 | STRATEGY | plan overview | [52_STRATEGY_plan_overview.md](52_STRATEGY_plan_overview.md) |
| 60 | RULE | naming rules | [60_RULE_naming_rules.md](60_RULE_naming_rules.md) |

## 📁 その他のファイル

| ファイル名 | 説明 |
|-----------|------|
| [README.md](README.md) | プロジェクト概要 |
| [HACKASON_RULE.md](HACKASON_RULE.md) | ハッカソンルール |
| [INDEX.md](INDEX.md) | このファイル（ドキュメント一覧） |

## 📂 アーカイブ

- **Archive/**: 旧ドキュメントのアーカイブ
- **Archive/old-docs/**: 今回移動した旧ファイル群

## 🛠 ツール

### ドキュメント作成

```bash
# 新しいドキュメントを作成
./docs/scripts/new_doc.sh CATEGORY title

# 例: API仕様書を作成
./docs/scripts/new_doc.sh API firebase_auth

# 例: テスト仕様書を作成  
./docs/scripts/new_doc.sh TEST unit_testing
```

### 一覧生成

```bash
# 最新のドキュメント一覧を生成
./docs/scripts/list_docs.sh

# 出力をファイルに保存
./docs/scripts/list_docs.sh > docs/INDEX.md
```

## 📋 カテゴリ一覧

| 範囲 | カテゴリ | 説明 |
|-----|----------|------|
| 01-09 | REQUIREMENT | 要件定義 |
| 10-19 | DESIGN | 設計書 |
| 20-29 | SPEC | 技術仕様 |
| 30-39 | API | API仕様 |
| 40-49 | GUIDE | ガイド・手順書 |
| 50-59 | STRATEGY | 戦略・計画 |
| 60-69 | RULE | ルール・規約 |
| 70-79 | TEST | テスト・品質 |
| 80-89 | DEPLOY | デプロイ・運用 |
| 90-99 | MISC | その他・補助資料 |

---
**更新方法**: `./docs/scripts/list_docs.sh > docs/INDEX.md` 