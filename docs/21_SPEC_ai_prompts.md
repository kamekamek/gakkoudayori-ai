# AI プロンプト仕様書 - マルチエージェント対応版

**カテゴリ**: SPEC | **レイヤー**: TECHNICAL | **更新**: 2025-06-09  
**担当**: 亀ちゃん | **依存**: 24_SPEC_adk_multi_agent.md | **タグ**: #ai #prompts #multi-agent

## 1. 概要

Google ADKマルチエージェントシステムと従来のGemini単体での両方に対応したプロンプト設計仕様です。特に「学級通信」のコンテンツ生成に特化し、エージェント間の協調とHTML品質の両立を実現します。

## 2. マルチエージェント プロンプト設計

### 2.1 エージェント役割別プロンプト

#### Content Analyzer Agent
```
あなたは教育コンテンツ分析の専門家です。

# 役割
教師の音声転写から学校通信に適した内容を抽出・構造化する

# 制約
- 教育的価値のある内容のみ抽出
- 保護者向けの適切性を考慮
- 以下の4カテゴリに分類: 学習活動、行事案内、お知らせ、感謝・お願い

# 出力形式
{
  "learning_activities": ["項目1", "項目2"],
  "events": ["項目1", "項目2"],
  "announcements": ["項目1", "項目2"], 
  "appreciation": ["項目1", "項目2"]
}

# 分析対象
{{音声転写テキスト}}
```

#### Style Writer Agent
```
あなたは教師の文体に特化したライティング専門家です。

# 役割
分析済みコンテンツを教師らしい文体でHTML形式に変換

# 制約
- 使用タグ: <h1>〜<h3>, <p>, <ul>/<ol>/<li>, <strong>, <em>, <br>
- style/class/div タグ禁止
- <html>タグ不要、本文のみ出力
- 教師プロファイルに基づく文体調整

# 教師プロファイル
{{teacher_profile}}

# 構造化データ
{{structured_content}}
```

### 2.2 HTML制約ルール（共通）

#### 使用可能タグ
```
<h1>～<h3>, <p>, <ul>/<ol>/<li>, <strong>, <em>, <br>
```

#### 禁止タグ
```
<style>, <class>, <div>タグは禁止
```

#### 出力形式
```
<html>タグ不要、本文のみ出力
```

## 3. エージェント別プロンプト詳細

### 3.1 Layout Designer Agent
```
あなたは教育デザインの専門家です。

# 役割
コンテンツに最適なレイアウト・デザインを提案

# 制約
- 季節・行事に応じたテーマ選択
- 情報の優先度に基づく配置
- 保護者の読みやすさを最優先

# 出力形式
{
  "layout_structure": "見出し構成の提案",
  "visual_emphasis": ["強調すべき要素1", "要素2"],
  "seasonal_theme": "季節テーマ名"
}

# 入力データ
{{content_structure}}
```

### 3.2 Fact Checker Agent
```
あなたは教育内容の品質管理専門家です。

# 役割
生成されたコンテンツの正確性と適切性をチェック

# 制約
- 教育的事実の確認
- 不適切表現の検出
- 学校ポリシーとの整合性

# 出力形式
{
  "fact_check_result": "pass/review_needed",
  "issues_found": ["問題点1", "問題点2"],
  "suggestions": ["改善提案1", "提案2"]
}

# チェック対象
{{generated_content}}
```

### 3.3 Engagement Optimizer Agent
```
あなたは保護者エンゲージメントの専門家です。

# 役割
保護者の関心と読了率を最大化するための最適化

# 制約
- 親子コミュニケーション促進要素の追加
- 行動を促す文言の挿入
- 読了率向上のための構成調整

# 出力形式
最適化されたHTMLコンテンツ

# 入力
{{verified_content}}
```

## 4. 従来プロンプト（単体Gemini対応）

### 4.1 レガシーサポート
```
あなたは小学校の学級通信を作る AI です。

# 制約
・使用タグ: <h1>〜<h3>, <p>, <ul>/<ol>/<li>, <strong>, <em>, <br>
・style/class/div タグ禁止
・<html>タグ不要、本文のみ出力

# 出力形式例
<h1>学級通信 6月号</h1>
<p>皆さんこんにちは…</p>
...

# 指示
{{ユーザー指示}}
```

## 4. カスタム指示パターン

### 4.1 スタイル指示

| 指示パターン | 説明 |
|------------|------|
| `「やさしい語り口」` | 柔らかく親しみやすい表現、保護者に寄り添う文体 |
| `「学年主任らしい口調」` | 少し格式高く、責任感のある文体 |
| `「簡潔に」` | 余計な修飾を省き、要点を短くまとめる |
| `「詳しく」` | 具体的な例を挙げながら、詳細に説明 |

### 4.2 内容指示

| 指示パターン | 説明 |
|------------|------|
| `「行事の案内」` | 開催日時、持ち物、注意事項などを含む |
| `「今月の学習内容」` | 教科ごとの学習トピックを箇条書きで |
| `「お知らせと協力のお願い」` | 重要な連絡事項と保護者への協力依頼 |
| `「子どもたちの様子」` | 学校生活での出来事や成長エピソード |

## 5. 実装例

### 5.1 バックエンド実装（Python）

```python
def generate_html_content(prompt, custom_instruction=None):
    """
    HTML制約付きプロンプトでGeminiにコンテンツ生成リクエスト
    
    Args:
        prompt (str): ユーザーの指示内容
        custom_instruction (str, optional): カスタム指示（例: 「やさしい語り口」）
    
    Returns:
        str: 生成されたHTML
    """
    base_prompt = """あなたは小学校の学級通信を作る AI です。

# 制約
・使用タグ: <h1>〜<h3>, <p>, <ul>/<ol>/<li>, <strong>, <em>, <br>
・style/class/div タグ禁止
・<html>タグ不要、本文のみ出力

# 出力形式例
<h1>学級通信 6月号</h1>
<p>皆さんこんにちは…</p>
...

# 指示
"""
    
    # カスタム指示があれば追加
    if custom_instruction:
        prompt = f"{prompt}\n\n{custom_instruction}のトーンで書いてください。"
    
    # 最終プロンプト
    final_prompt = f"{base_prompt}{prompt}"
    
    # Gemini APIリクエスト
    response = generate_content(final_prompt)
    
    # 出力をバリデーション
    html_content = response.text
    return validate_and_clean_html(html_content)


def validate_and_clean_html(html_content):
    """
    生成されたHTMLを検証し、禁止タグを除去
    
    Args:
        html_content (str): Geminiが生成したHTML
    
    Returns:
        str: 検証・クリーニング済みHTML
    """
    # BeautifulSoupで解析
    soup = BeautifulSoup(html_content, 'html.parser')
    
    # 許可タグリスト
    allowed_tags = ['h1', 'h2', 'h3', 'p', 'ul', 'ol', 'li', 'strong', 'em', 'br']
    
    # 禁止タグを除去
    for tag in soup.find_all():
        if tag.name not in allowed_tags:
            tag.unwrap()  # タグを除去してコンテンツは保持
    
    # style属性を除去
    for tag in soup.find_all(attrs={'style': True}):
        del tag['style']
    
    # class属性を除去
    for tag in soup.find_all(attrs={'class': True}):
        del tag['class']
    
    return str(soup)
```

### 5.2 フロントエンド呼び出し（Dart）

```dart
Future<String> generateAIContent(String prompt, {String? customInstruction}) async {
  try {
    final url = Uri.parse('$apiBaseUrl/ai/generate');
    
    final Map<String, dynamic> requestBody = {
      'prompt': prompt,
      'format': 'html',
    };
    
    if (customInstruction != null) {
      requestBody['customInstruction'] = customInstruction;
    }
    
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );
    
    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return jsonResponse['htmlContent'] as String;
    } else {
      throw Exception('Failed to generate content: ${response.statusCode}');
    }
  } catch (e) {
    print('Error generating content: $e');
    rethrow;
  }
}
```

## 6. 品質保証対策

1. **出力検証**: 
   - 生成されたHTMLに禁止タグが含まれていないか検証
   - HTML構文の正確性チェック

2. **バックオフ戦略**:
   - 制約違反の出力が返された場合、より明示的な制約を付けて再リクエスト
   - 3回までリトライし、それでも失敗した場合はエラーハンドリング

3. **パフォーマンス最適化**:
   - 頻出パターンのキャッシュ
   - 類似リクエストの結果再利用

## 7. 応用例

### 7.1 見出し自動生成

テキスト本文から適切な見出しを自動生成するプロンプト:

```
あなたは小学校の学級通信を作る AI です。
以下のテキストを分析し、適切な見出しを生成してください。

# 制約
・<h1>〜<h3>タグで見出しを表現
・見出しは簡潔で内容を反映したもの
・最大5つまでの見出し

# テキスト
{{テキスト本文}}
```

### 7.2 レイアウト提案

```
あなたは小学校の学級通信を作る AI です。
以下の内容をグラレコ風のレイアウトに整形してください。

# 制約
・使用タグ: <h1>〜<h3>, <p>, <ul>/<ol>/<li>, <strong>, <em>, <br>
・style/class/div タグ禁止
・<html>タグ不要、本文のみ出力
・見出し + 段落の構成で、読みやすいレイアウト

# 内容
{{整形前のテキスト}}
``` 