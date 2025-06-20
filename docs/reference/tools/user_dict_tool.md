# UserDictTool API仕様

## 概要

学校特有の固有名詞や専門用語を正しく変換するためのローカル辞書Tool。音声認識後のテキストに対して固有名詞の置換を行います。

## 基本情報

- **Tool名**: `user_dict_tool`
- **責務**: 固有名詞・専門用語の置換処理
- **外部依存**: なし（ローカル辞書ファイル）
- **認証**: 不要

## API仕様

### 関数シグネチャ

```python
@tool
def user_dict_tool(
    text: str,
    dict_path: str = "user_dict.json",
    case_sensitive: bool = False
) -> str
```

### 入力パラメータ

| パラメータ名 | 型 | 必須 | デフォルト | 説明 |
|-------------|---|------|-----------|------|
| text | str | ✓ | - | 置換対象のテキスト |
| dict_path | str | - | "user_dict.json" | 辞書ファイルのパス |
| case_sensitive | bool | - | False | 大文字小文字を区別するか |

### 出力

| 型 | 説明 |
|----|------|
| str | 固有名詞が置換されたテキスト |

### 例外

| 例外クラス | 発生条件 | 説明 |
|-----------|----------|------|
| FileNotFoundError | 辞書ファイルが存在しない | 指定された辞書ファイルが見つからない |
| json.JSONDecodeError | 辞書ファイルが不正 | JSON形式が正しくない |
| ValueError | text が空文字列 | 入力テキストが無効 |

## 辞書ファイル形式

### JSON構造

```json
{
  "replacements": [
    {
      "from": "たなかたろう",
      "to": "田中太郎",
      "type": "person_name"
    },
    {
      "from": "やまださん",
      "to": "山田さん",
      "type": "person_name"
    },
    {
      "from": "たいくかん",
      "to": "体育館",
      "type": "facility"
    },
    {
      "from": "うんどうかい",
      "to": "運動会",
      "type": "event"
    }
  ],
  "patterns": [
    {
      "regex": "([0-9]+)じかんめ",
      "replacement": "\\1時間目",
      "type": "time_expression"
    }
  ]
}
```

### 置換タイプ

| type | 説明 | 例 |
|------|------|---|
| person_name | 人名 | たなかたろう → 田中太郎 |
| facility | 施設名 | たいくかん → 体育館 |
| event | 行事名 | うんどうかい → 運動会 |
| subject | 教科名 | さんすう → 算数 |
| time_expression | 時間表現 | 3じかんめ → 3時間目 |

## 使用例

### 基本的な使用例

```python
from tools.user_dict_tool import user_dict_tool

# 基本的な固有名詞置換
text = "今日はたなかたろうさんとやまださんがたいくかんでうんどうかいの準備をしました"
result = user_dict_tool(text=text)
print(result)
# "今日は田中太郎さんと山田さんが体育館で運動会の準備をしました"
```

### カスタム辞書の使用

```python
# 学級専用の辞書を使用
result = user_dict_tool(
    text="みなさん、さんすうのじゅぎょうを始めます",
    dict_path="class_1a_dict.json"
)
```

### Agent内での使用例

```python
class OrchestratorAgent(Agent):
    async def process_speech_result(self, speech_text: str) -> str:
        # 音声認識結果を固有名詞補正
        corrected_text = await self.use_tool(
            "user_dict_tool",
            text=speech_text,
            dict_path=f"dict/{self.user_context['class_id']}.json"
        )
        return corrected_text
```

## 辞書管理

### 辞書ファイルの作成

```python
# 辞書作成ヘルパー
def create_user_dict(class_id: str, replacements: list) -> str:
    dict_data = {
        "replacements": replacements,
        "patterns": []
    }
    
    dict_path = f"dict/{class_id}.json"
    with open(dict_path, 'w', encoding='utf-8') as f:
        json.dump(dict_data, f, ensure_ascii=False, indent=2)
    
    return dict_path

# 使用例
replacements = [
    {"from": "すずきせんせい", "to": "鈴木先生", "type": "person_name"},
    {"from": "1ねん2くみ", "to": "1年2組", "type": "class_name"}
]
create_user_dict("class_1_2", replacements)
```

### 辞書の更新

```python
def update_user_dict(dict_path: str, new_replacements: list):
    with open(dict_path, 'r', encoding='utf-8') as f:
        dict_data = json.load(f)
    
    dict_data["replacements"].extend(new_replacements)
    
    with open(dict_path, 'w', encoding='utf-8') as f:
        json.dump(dict_data, f, ensure_ascii=False, indent=2)
```

## パフォーマンス特性

- **処理時間**: <10ms（辞書サイズ100件）
- **メモリ使用量**: 辞書サイズに比例（通常1-2MB）
- **同時実行**: 並列処理対応（読み取り専用）

## テスト

### 単体テスト例

```python
import pytest
import tempfile
import json
from tools.user_dict_tool import user_dict_tool

class TestUserDictTool:
    def test_basic_replacement(self):
        # テスト用辞書作成
        test_dict = {
            "replacements": [
                {"from": "たろう", "to": "太郎", "type": "person_name"}
            ],
            "patterns": []
        }
        
        with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
            json.dump(test_dict, f, ensure_ascii=False)
            dict_path = f.name
        
        # テスト実行
        result = user_dict_tool("今日はたろうが来ました", dict_path=dict_path)
        assert result == "今日は太郎が来ました"
    
    def test_no_replacement_when_not_found(self):
        result = user_dict_tool("変換対象がない文章")
        assert result == "変換対象がない文章"
    
    def test_pattern_replacement(self):
        test_dict = {
            "replacements": [],
            "patterns": [
                {
                    "regex": "([0-9]+)じかんめ",
                    "replacement": "\\1時間目",
                    "type": "time_expression"
                }
            ]
        }
        
        with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
            json.dump(test_dict, f, ensure_ascii=False)
            dict_path = f.name
        
        result = user_dict_tool("3じかんめの授業", dict_path=dict_path)
        assert result == "3時間目の授業"
    
    def test_missing_dict_file(self):
        with pytest.raises(FileNotFoundError):
            user_dict_tool("test", dict_path="nonexistent.json")
```

## 実装詳細

### 処理アルゴリズム

1. 辞書ファイル読み込み（初回のみ、キャッシュ）
2. 固定文字列置換（replacements）の実行
3. 正規表現パターン（patterns）の実行
4. 置換結果の返却

### キャッシュ機能

```python
import functools
import os

@functools.lru_cache(maxsize=10)
def load_dict_file(dict_path: str, mtime: float):
    """辞書ファイルをキャッシュ付きで読み込み"""
    with open(dict_path, 'r', encoding='utf-8') as f:
        return json.load(f)

def get_dict_data(dict_path: str):
    """ファイル更新時刻をチェックしてキャッシュを管理"""
    mtime = os.path.getmtime(dict_path)
    return load_dict_file(dict_path, mtime)
```

## 設定

### 環境変数

| 変数名 | 必須 | デフォルト | 説明 |
|--------|------|-----------|------|
| USER_DICT_BASE_PATH | - | "." | 辞書ファイルのベースパス |
| USER_DICT_CACHE_SIZE | - | 10 | 辞書キャッシュサイズ |

### 辞書ファイル配置

```
dict/
├── default.json           # デフォルト辞書
├── class_1_1.json        # 1年1組専用
├── class_1_2.json        # 1年2組専用
└── school_common.json    # 学校共通用語
```

## ベストプラクティス

1. **辞書の階層化**
   - 学校共通 → 学年共通 → クラス専用の順で適用
   - 複数辞書の統合機能

2. **パフォーマンス最適化**
   - よく使用される辞書はメモリキャッシュ
   - 大きい辞書はインデックス化

3. **メンテナンス性**
   - 辞書更新のWeb UI提供
   - 使用頻度の統計取得
   - 置換ログの記録

## 関連ドキュメント

- [SpeechToTextTool](/reference/tools/speech_to_text_tool.md) - 前段処理
- [OrchestratorAgent](/reference/agents/orchestrator_agent.md) - 呼び出し元Agent
- [辞書管理UI仕様](/reference/ui/dict_management.md) - 辞書編集画面
- [ADKワークフローガイド](/guides/adk-workflow.md) - 全体フロー