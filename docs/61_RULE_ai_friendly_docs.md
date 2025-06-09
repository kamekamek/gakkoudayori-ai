# AIフレンドリーなドキュメント管理ルール

**カテゴリ**: RULE | **レイヤー**: SUMMARY | **更新**: 2025-06-09  
**担当**: システム | **依存**: 60_RULE_naming_rules.md | **タグ**: #docs #ai #efficiency

## 🎯 TL;DR（30秒で読める要約）

- **目的**: AIアシスタントが効率的に処理できるドキュメント構造の定義
- **対象**: ドキュメント作成者全員  
- **成果物**: コンテキスト超過を防ぐ最適化されたドキュメント
- **次のアクション**: 既存ドキュメントの分割・テンプレート適用

## 📋 基本原則

### 1. サイズ制限

| レイヤー | 推奨サイズ | 最大サイズ | 目的 |
|----------|------------|------------|------|
| SUMMARY | 2-3KB | 5KB | 全体把握・方針決定 |
| DETAIL | 5-7KB | 10KB | 設計・仕様理解 |
| IMPL | 3-5KB | 8KB | 実装時の詳細参照 |

### 2. 構造化原則

```
必須セクション:
✅ TL;DR（要約）
✅ 関連ドキュメント表
✅ メタデータ

推奨セクション:
📋 概要
📝 詳細  
✅ チェックリスト
```

### 3. 依存関係の明確化

- **循環参照禁止**: A→B→A の関係は避ける
- **階層構造**: 上位→下位の一方向参照
- **独立性**: 各ドキュメントが単体で理解可能

## 🔄 分割戦略

### パターン1: 機能分割

```
20_SPEC_quill_integration.md (15KB) →
├── 20_SPEC_quill_summary.md (3KB)      # 概要・方針
├── 21_SPEC_quill_setup.md (5KB)       # セットアップ
├── 22_SPEC_quill_features.md (4KB)    # 機能仕様
└── 23_SPEC_quill_implementation.md (3KB) # 実装詳細
```

### パターン2: レイヤー分割

```
50_STRATEGY_implementation.md →
├── 50_STRATEGY_implementation_summary.md  # 戦略概要
├── 51_STRATEGY_implementation_detail.md   # 詳細計画
└── 52_STRATEGY_implementation_timeline.md # スケジュール
```

## 🛠 自動化ツール

### ドキュメント分析スクリプト

```bash
#!/bin/bash
# docs/scripts/analyze_docs.sh

echo "# 📊 ドキュメント分析レポート"
echo "**生成日**: $(date +%Y-%m-%d)"
echo

echo "## サイズ分析"
echo "| ファイル | サイズ | 推奨アクション |"
echo "|---------|--------|---------------|"

for file in docs/[0-9][0-9]_*.md; do
    if [ -f "$file" ]; then
        size=$(wc -c < "$file")
        name=$(basename "$file")
        
        if [ $size -gt 10000 ]; then
            action="🔥 分割推奨"
        elif [ $size -gt 7000 ]; then
            action="⚠️ 要注意"
        else
            action="✅ 適正"
        fi
        
        echo "| $name | ${size}B | $action |"
    fi
done
```

### TL;DR生成支援

```bash
#!/bin/bash
# docs/scripts/generate_tldr.sh

file=$1
if [ -z "$file" ]; then
    echo "Usage: ./generate_tldr.sh filename.md"
    exit 1
fi

echo "## 🎯 TL;DR（30秒で読める要約）"
echo
echo "- **目的**: [このドキュメントの目的を1行で]"
echo "- **対象**: [誰が読むべきか]"  
echo "- **成果物**: [読了後に得られるもの]"
echo "- **次のアクション**: [読了後の推奨アクション]"
```

## 📊 AIの読み取りパターン

### 効率的な読み取り順序

1. **INDEX.md** で全体マップ確認
2. **XX_SUMMARY.md** で該当領域の概要把握
3. **XX_DETAIL.md** で必要な詳細のみ部分読み取り
4. **XX_IMPL.md** で実装時の具体的手順確認

### 避けるべきパターン

❌ **巨大ドキュメント**: 1ファイル15KB超
❌ **循環参照**: A→B→C→A の関係
❌ **情報重複**: 同じ内容が複数ファイルに散在
❌ **メタデータ不足**: 関連性・依存関係が不明

## ✅ 実装チェックリスト

- [ ] 既存大型ドキュメントの分割
- [ ] 統一テンプレートの適用
- [ ] 関連ドキュメント表の作成
- [ ] TL;DRセクションの追加
- [ ] 分析スクリプトの実行
- [ ] INDEX.mdの更新

## 📊 メタデータ

- **複雑度**: Medium
- **推定読了時間**: 8分
- **前提知識**: ドキュメント管理の基礎
- **更新頻度**: 中 