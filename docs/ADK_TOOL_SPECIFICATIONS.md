# ADK準拠ツール仕様書

## 📋 概要

Google ADK公式仕様に完全準拠したツール関数の設計仕様書。全ツールが統一されたインターフェース、エラーハンドリング、ドキュメント形式に従う。

## 🎯 ADK準拠要件

### 必須要件
1. **返却値:** 必ず`dict`型を返却
2. **ステータス:** `status`キーで成功/失敗を明示
3. **デフォルト値:** パラメータにデフォルト値を設定しない
4. **型注釈:** 全パラメータと返却値に型注釈必須
5. **docstring:** 目的、引数、返却値の完全な説明

### 推奨要件
- JSON serializable な値のみ使用
- 明確で説明的な関数名・パラメータ名
- LLMが理解しやすい説明文
- 一貫したエラーメッセージ形式

---

## 📝 ツール関数一覧

### 1. 学級通信コンテンツ生成

#### `generate_newsletter_content`

```python
def generate_newsletter_content(
    audio_transcript: str,
    grade_level: str,
    content_type: str
) -> dict:
    """学級通信の文章を生成するツール
    
    音声認識結果から教師らしい温かい語り口調の学級通信文章を生成します。
    保護者向けの親しみやすい内容を800-1200文字程度で作成します。
    学年に応じた適切な表現と具体的なエピソードを重視します。
    
    Args:
        audio_transcript: 音声認識結果のテキスト。空文字列不可。
        grade_level: 対象学年（例：3年1組、4年2組）
        content_type: コンテンツタイプ（newsletter固定値）
        
    Returns:
        生成結果を含む辞書：
        - status (str): 'success' | 'error'
        - content (str): 生成された文章（成功時のみ）
        - word_count (int): 生成された文字数（成功時のみ）
        - grade_level (str): 処理対象学年（成功時のみ）
        - error_message (str): エラーの詳細説明（失敗時のみ）
        - error_code (str): エラー分類コード（失敗時のみ）
    """
```

**入力例:**
```python
generate_newsletter_content(
    audio_transcript="今日は運動会の練習をしました。子どもたちは...",
    grade_level="3年1組",
    content_type="newsletter"
)
```

**成功時返却例:**
```python
{
    "status": "success",
    "content": "保護者の皆様へ\n\n今日は3年1組の運動会練習...",
    "word_count": 1024,
    "grade_level": "3年1組"
}
```

**失敗時返却例:**
```python
{
    "status": "error",
    "error_message": "音声認識結果が空文字列です",
    "error_code": "EMPTY_TRANSCRIPT"
}
```

### 2. デザイン仕様生成

#### `generate_design_specification`

```python
def generate_design_specification(
    content: str,
    theme: str,
    grade_level: str
) -> dict:
    """デザイン仕様をJSON形式で生成するツール
    
    学級通信の内容に基づいて、季節感のあるデザイン仕様を生成します。
    カラースキーム、レイアウト構成、視覚的要素を含む完全な設計仕様を
    JSON形式で提供し、後続のHTML生成に活用されます。
    
    Args:
        content: 学級通信の文章内容。空文字列不可。
        theme: デザインテーマ（seasonal, modern, classic等）
        grade_level: 対象学年（デザイン調整に使用）
        
    Returns:
        デザイン仕様を含む辞書：
        - status (str): 'success' | 'error'
        - design_spec (dict): 完全なデザイン仕様（成功時のみ）
        - season (str): 判定された季節（成功時のみ）
        - theme (str): 適用されたテーマ（成功時のみ）
        - error_message (str): エラーの詳細説明（失敗時のみ）
    """
```

**design_spec構造:**
```python
{
    "layout_type": "modern",
    "color_scheme": {
        "primary": "#4CAF50",
        "secondary": "#81C784",
        "accent": "#FFC107",
        "background": "#FFFFFF"
    },
    "fonts": {
        "heading": "Noto Sans JP",
        "body": "Hiragino Sans"
    },
    "layout_sections": [
        {
            "type": "header",
            "position": "top",
            "content_type": "title"
        }
    ],
    "visual_elements": {
        "photo_placeholders": 2,
        "illustration_style": "spring",
        "border_style": "rounded"
    }
}
```

### 3. HTML生成

#### `generate_html_newsletter`

```python
def generate_html_newsletter(
    content: str,
    design_spec: dict,
    template_type: str
) -> dict:
    """HTMLニュースレターを生成するツール
    
    文章内容とデザイン仕様に基づいて、厳格な制約に準拠したHTMLを生成します。
    指定されたHTMLタグのみを使用し、アクセシブルで印刷適応性の高い
    マークアップを作成します。
    
    Args:
        content: 学級通信の文章内容。空文字列不可。
        design_spec: デザイン仕様辞書。必須キーを含む必要あり。
        template_type: テンプレートタイプ（newsletter, announcement等）
        
    Returns:
        HTML生成結果を含む辞書：
        - status (str): 'success' | 'error'
        - html (str): 生成されたHTML文字列（成功時のみ）
        - char_count (int): HTML文字数（成功時のみ）
        - template_type (str): 使用されたテンプレート（成功時のみ）
        - validation_passed (bool): HTML制約チェック結果（成功時のみ）
        - error_message (str): エラーの詳細説明（失敗時のみ）
    """
```

**HTML制約:**
- 使用可能タグ: `<h1>`, `<h2>`, `<h3>`, `<p>`, `<ul>`, `<ol>`, `<li>`, `<strong>`, `<em>`, `<br>`
- インラインスタイルのみ許可
- `<div>`, `class`, `id`属性は禁止
- 完全なHTMLドキュメントではなく、本文部分のみ

### 4. HTML修正

#### `modify_html_content`

```python
def modify_html_content(
    current_html: str,
    modification_request: str
) -> dict:
    """HTML修正を実行するツール
    
    既存のHTMLコンテンツに対して修正要求を適用します。
    元の構造とスタイル制約を保持しながら、必要な変更のみを実施し、
    変更履歴も記録します。
    
    Args:
        current_html: 修正対象の現在のHTML内容。空文字列不可。
        modification_request: 修正要求の詳細説明
        
    Returns:
        修正結果を含む辞書：
        - status (str): 'success' | 'error'
        - modified_html (str): 修正後のHTML（成功時のみ）
        - changes_made (str): 実施した変更の説明（成功時のみ）
        - original_length (int): 元HTML文字数（成功時のみ）
        - modified_length (int): 修正後HTML文字数（成功時のみ）
        - modification_type (str): 修正タイプ分類（成功時のみ）
        - error_message (str): エラーの詳細説明（失敗時のみ）
    """
```

### 5. 品質検証

#### `validate_newsletter_quality`

```python
def validate_newsletter_quality(
    html_content: str,
    original_content: str
) -> dict:
    """学級通信の品質を検証するツール
    
    生成された学級通信の内容適切性、技術的正確性、教育的価値を
    多角的に評価します。数値化されたスコアと具体的な改善提案を
    含む包括的な品質レポートを作成します。
    
    Args:
        html_content: 検証対象のHTML内容。空文字列不可。
        original_content: 元の文章内容。比較分析に使用。
        
    Returns:
        品質検証結果を含む辞書：
        - status (str): 'success' | 'error'
        - quality_score (int): 総合品質スコア 0-100（成功時のみ）
        - assessment (str): 全体評価カテゴリ（成功時のみ）
        - category_scores (dict): カテゴリ別スコア（成功時のみ）
        - suggestions (list): 改善提案リスト（成功時のみ）
        - content_analysis (dict): 内容分析結果（成功時のみ）
        - error_message (str): エラーの詳細説明（失敗時のみ）
    """
```

**category_scores構造:**
```python
{
    "educational_value": 85,      # 教育的価値 (25%)
    "readability": 90,           # 読みやすさ (25%)
    "technical_accuracy": 95,    # 技術的正確性 (25%)
    "parent_consideration": 88   # 保護者への配慮 (25%)
}
```

---

## 🔧 Phase 2拡張ツール

### 6. PDF生成

#### `generate_pdf_output`

```python
def generate_pdf_output(
    html_content: str,
    newsletter_metadata: dict,
    pdf_options: dict
) -> dict:
    """学級通信PDFを生成するツール
    
    HTMLコンテンツからA4印刷最適化されたPDFを生成します。
    日本語フォント対応、品質分析、自動ファイル名生成を含む
    完全なPDF出力ソリューションを提供します。
    
    Args:
        html_content: PDF化するHTML内容。空文字列不可。
        newsletter_metadata: 学級通信メタデータ（タイトル、学年等）
        pdf_options: PDF生成オプション（ページサイズ、品質等）
        
    Returns:
        PDF生成結果を含む辞書：
        - status (str): 'success' | 'error'
        - pdf_base64 (str): Base64エンコードされたPDF（成功時のみ）
        - file_size_mb (float): ファイルサイズ（成功時のみ）
        - filename (str): 生成されたファイル名（成功時のみ）
        - quality_analysis (dict): PDF品質分析結果（成功時のみ）
        - processing_time_ms (int): 処理時間（成功時のみ）
        - error_message (str): エラーの詳細説明（失敗時のみ）
    """
```

### 7. メディア強化

#### `enhance_with_media`

```python
def enhance_with_media(
    html_content: str,
    newsletter_data: dict,
    media_options: dict
) -> dict:
    """学級通信にメディア要素を追加するツール
    
    Vertex AI Imageを活用して、コンテンツに適した画像を生成・挿入し、
    視覚的魅力を向上させます。教育現場に適した安全で効果的な
    画像配置を自動最適化します。
    
    Args:
        html_content: メディア強化対象のHTML。空文字列不可。
        newsletter_data: 学級通信データ（セクション情報等）
        media_options: メディア生成オプション（画像数、スタイル等）
        
    Returns:
        メディア強化結果を含む辞書：
        - status (str): 'success' | 'error'
        - enhanced_html (str): 画像挿入済みHTML（成功時のみ）
        - images_added (int): 追加された画像数（成功時のみ）
        - image_metadata (list): 画像メタデータリスト（成功時のみ）
        - optimization_applied (bool): 最適化適用状況（成功時のみ）
        - error_message (str): エラーの詳細説明（失敗時のみ）
    """
```

### 8. Classroom配布

#### `distribute_to_classroom`

```python
def distribute_to_classroom(
    pdf_path: str,
    newsletter_data: dict,
    classroom_settings: dict
) -> dict:
    """Google Classroomに学級通信を配布するツール
    
    生成されたPDFをGoogle Classroomに自動投稿し、保護者への
    効率的な配布を実現します。投稿タイミング最適化、権限管理、
    配布状況トラッキングを含む包括的な配布ソリューションです。
    
    Args:
        pdf_path: 配布するPDFファイルパス。存在確認必須。
        newsletter_data: 学級通信データ（タイトル、学年等）
        classroom_settings: Classroom配布設定（認証、コース等）
        
    Returns:
        配布結果を含む辞書：
        - status (str): 'success' | 'error'
        - post_url (str): 投稿URL（成功時のみ）
        - post_id (str): 投稿ID（成功時のみ）
        - distribution_summary (dict): 配布サマリー（成功時のみ）
        - recipients_notified (bool): 受信者通知状況（成功時のみ）
        - error_message (str): エラーの詳細説明（失敗時のみ）
    """
```

---

## 🚨 エラーハンドリング仕様

### 統一エラー形式

```python
{
    "status": "error",
    "error_message": "人間が読める詳細なエラー説明",
    "error_code": "ERROR_CATEGORY_SPECIFIC_CODE",
    "timestamp": "2024-06-19T10:30:00Z",
    "context": {
        "function_name": "generate_newsletter_content",
        "input_validation": "failed",
        "step_failed": "content_generation"
    }
}
```

### エラーコード分類

#### 入力検証エラー
- `EMPTY_INPUT` - 必須パラメータが空
- `INVALID_FORMAT` - フォーマット不正
- `MISSING_REQUIRED_KEY` - 必須キーが不足

#### 処理エラー
- `API_CALL_FAILED` - 外部API呼び出し失敗
- `GENERATION_TIMEOUT` - 生成処理タイムアウト
- `PROCESSING_ERROR` - 一般的な処理エラー

#### システムエラー
- `INSUFFICIENT_RESOURCES` - リソース不足
- `SERVICE_UNAVAILABLE` - サービス利用不可
- `CONFIGURATION_ERROR` - 設定エラー

---

## 📊 品質指標

### パフォーマンス要件
- **応答時間:** 各ツール5秒以内
- **メモリ使用量:** 1GB以下
- **成功率:** 95%以上

### 品質要件
- **エラーメッセージ:** 100%人間可読
- **ログ出力:** 全処理ステップ記録
- **入力検証:** 100%実装

---

## 🧪 テスト仕様

### 単体テスト要件

各ツール関数に対して以下をテスト：

```python
def test_generate_newsletter_content():
    # 正常ケース
    result = generate_newsletter_content(
        "正常な音声認識結果",
        "3年1組",
        "newsletter"
    )
    assert result["status"] == "success"
    assert "content" in result
    assert result["word_count"] > 0
    
    # エラーケース: 空入力
    result = generate_newsletter_content("", "3年1組", "newsletter")
    assert result["status"] == "error"
    assert "error_message" in result
    
    # エラーケース: 不正な学年
    result = generate_newsletter_content("内容", "不正学年", "newsletter")
    assert result["status"] == "error"
```

### 統合テスト要件

```python
def test_tool_chain_integration():
    # ツール連携テスト
    content_result = generate_newsletter_content(...)
    design_result = generate_design_specification(
        content_result["content"], "seasonal", "3年1組"
    )
    html_result = generate_html_newsletter(
        content_result["content"],
        design_result["design_spec"],
        "newsletter"
    )
    
    assert all([
        content_result["status"] == "success",
        design_result["status"] == "success", 
        html_result["status"] == "success"
    ])
```

---

## 📚 実装ガイドライン

### 1. コーディング規約

```python
# ✅ 良い例
def generate_newsletter_content(
    audio_transcript: str,
    grade_level: str,
    content_type: str
) -> dict:
    """完全なdocstring"""
    
    # 入力検証
    if not audio_transcript.strip():
        return {
            "status": "error",
            "error_message": "音声認識結果が空です",
            "error_code": "EMPTY_TRANSCRIPT"
        }
    
    try:
        # 処理実行
        result = process_content(...)
        
        return {
            "status": "success",
            "content": result,
            "word_count": len(result)
        }
        
    except Exception as e:
        logger.error(f"Content generation failed: {e}")
        return {
            "status": "error",
            "error_message": f"処理中にエラーが発生: {str(e)}",
            "error_code": "PROCESSING_ERROR"
        }
```

### 2. ログ出力規約

```python
# 処理開始ログ
logger.info(f"Starting {function_name} with inputs: {safe_input_summary}")

# 成功ログ
logger.info(f"{function_name} completed successfully in {processing_time}ms")

# エラーログ
logger.error(f"{function_name} failed: {error_message}", exc_info=True)
```

### 3. 返却値検証

```python
def validate_tool_response(response: dict, required_keys: list) -> bool:
    """ツール応答の妥当性検証"""
    if not isinstance(response, dict):
        return False
    
    if response.get("status") not in ["success", "error"]:
        return False
    
    if response["status"] == "success":
        return all(key in response for key in required_keys)
    else:
        return "error_message" in response
```

---

## 🔄 バージョン管理

### バージョン履歴
- **v1.0.0** - 初期仕様策定
- **v1.1.0** - Phase 2ツール追加
- **v1.2.0** - エラーハンドリング強化

### 互換性ポリシー
- **後方互換性:** メジャーバージョン内で保持
- **非推奨機能:** 1バージョン前に警告
- **削除機能:** メジャーバージョン更新時のみ

---

**📅 仕様書作成日:** 2024年6月19日  
**📝 最終更新日:** 2024年6月19日  
**👤 作成者:** Claude Code AI Assistant  
**📋 バージョン:** v1.0.0