# プロンプト管理システム改善計画

## 🎯 目標
現在のファイルベースプロンプト管理を、よりシンプルで保守性の高いシステムに改善する。

## 📊 現状分析

### 現在の実装
```python
# newsletter_generator.py
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
PROMPT_DIR = os.path.join(BASE_DIR, "prompts")

def load_newsletter_prompt(template_type: str) -> Optional[str]:
    if 'modern' in template_type.lower():
        prompt_filename = "MODERN_TENSAKU.md"
    else:
        prompt_filename = "CLASSIC_TENSAKU.md"
```

### 問題点
- ❌ ファイルシステム依存
- ❌ 環境間での同期が困難 
- ❌ 動的更新不可
- ❌ バージョン管理が複雑
- ❌ A/Bテストが困難

## 🚀 改善案比較

### Option 1: 環境変数管理 ⭐⭐⭐
```python
CLASSIC_TENSAKU_PROMPT = os.getenv('CLASSIC_TENSAKU_PROMPT', 'default_prompt')
MODERN_TENSAKU_PROMPT = os.getenv('MODERN_TENSAKU_PROMPT', 'default_prompt')
```

**メリット**:
- ✅ 超シンプル
- ✅ 環境別設定が容易
- ✅ クラウド環境で標準的

**デメリット**:
- ❌ 長いプロンプトには不向き
- ❌ 複数行管理が困難

### Option 2: Firestoreベース管理 ⭐⭐⭐⭐⭐
```python
async def load_prompt_from_firestore(template_type: str) -> str:
    doc = db.collection('prompts').document(template_type).get()
    return doc.to_dict()['content']
```

**メリット**:
- ✅ 動的更新可能
- ✅ バージョン履歴
- ✅ A/Bテスト対応
- ✅ UI管理画面作成可能
- ✅ 権限管理
- ✅ 監査ログ

**デメリット**:
- ❌ 初期設定が複雑
- ❌ 依存関係追加

### Option 3: Cloud Storageベース ⭐⭐⭐
```python
def load_prompt_from_storage(template_type: str) -> str:
    blob = storage_client.bucket('prompts').blob(f'{template_type}.md')
    return blob.download_as_text()
```

**メリット**:
- ✅ ファイル管理の使い慣れた感覚
- ✅ 大容量対応
- ✅ CDN配信可能

**デメリット**:
- ❌ ネットワーク依存
- ❌ バージョン管理が手動

### Option 4: 設定ファイル統合 ⭐⭐⭐⭐
```python
# prompts.json
{
  "classic_tensaku": "あなたは経験豊富な...",
  "modern_tensaku": "モダンな学級通信を...",
  "classic_layout": "<!DOCTYPE html>...",
  "modern_layout": "<!DOCTYPE html>..."
}
```

**メリット**:
- ✅ シンプル
- ✅ 一元管理
- ✅ Git管理可能
- ✅ IDE支援

**デメリット**:
- ❌ JSON エスケープが必要
- ❌ 動的更新不可

## 🎯 推奨アプローチ: **段階的移行**

### Phase 1: 設定ファイル統合 (即座に実装可能)
```python
# config/prompts.json
{
  "templates": {
    "classic_tensaku": {
      "name": "クラシック添削",
      "content": "...",
      "version": "1.0"
    },
    "modern_tensaku": {
      "name": "モダン添削", 
      "content": "...",
      "version": "1.0"
    }
  }
}
```

### Phase 2: Firestore移行 (将来的拡張)
- 管理画面での編集機能
- バージョン履歴機能
- A/Bテスト機能

## 🔧 実装計画

### Step 1: プロンプト設定ファイル作成
1. `config/prompts.json` 作成
2. 既存`.md`ファイルをJSONに変換
3. プロンプトローダー関数の更新

### Step 2: プロンプトマネージャークラス実装
```python
class PromptManager:
    def __init__(self, config_path: str = "config/prompts.json"):
        self.prompts = self._load_prompts(config_path)
    
    def get_prompt(self, template_type: str) -> str:
        return self.prompts['templates'].get(template_type, {}).get('content', '')
    
    def get_system_prompt(self, service: str, template_type: str) -> str:
        key = f"{service}_{template_type}"
        return self.get_prompt(key)
```

### Step 3: 既存コード更新
- `newsletter_generator.py`
- `json_to_graphical_record_service.py`

### Step 4: テスト実装
- プロンプト読み込みテスト
- フォールバック機能テスト

## 📈 期待効果

### 即時効果
- ✅ 設定の一元化
- ✅ 保守性向上
- ✅ デプロイ簡素化

### 中長期効果  
- ✅ 動的プロンプト更新
- ✅ A/Bテスト対応
- ✅ 管理画面による運用改善

## 🚦 マイグレーション戦略

### 1. 後方互換性維持
```python
def load_newsletter_prompt(template_type: str) -> Optional[str]:
    # 新システム試行
    try:
        return prompt_manager.get_system_prompt('newsletter', template_type)
    except:
        # 既存システムフォールバック
        return _load_from_file(template_type)
```

### 2. 段階的移行
1. Week 1: 設定ファイル実装
2. Week 2: テスト＆デバッグ
3. Week 3: 本番適用
4. Week 4: 旧システム削除

### 3. ロールバック計画
- 設定ファイル破損時は既存ファイルシステムへ自動フォールバック
- 環境変数での強制フォールバック機能

## 📋 チェックリスト

### Phase 1 実装
- [ ] `config/prompts.json` 作成
- [ ] `PromptManager` クラス実装
- [ ] 既存コード更新
- [ ] テスト作成
- [ ] ドキュメント更新

### Phase 2 拡張（将来）
- [ ] Firestore移行
- [ ] 管理画面実装
- [ ] バージョン管理機能
- [ ] A/Bテスト機能 