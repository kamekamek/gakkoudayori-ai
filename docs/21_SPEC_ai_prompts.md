# Gemini HTML生成プロンプト仕様書

## 1. 概要

Gemini 1.5 ProにHTMLコンテンツを生成させるためのプロンプト設計仕様です。特に「学級通信」のコンテンツ生成に特化し、タグ制限をかけることで高品質なHTMLを出力させます。

## 2. HTML制約ルール

### 2.1 使用可能タグのみ

```
<h1>～<h3>, <p>, <ul>/<ol>/<li>, <strong>, <em>, <br>
```

### 2.2 禁止タグ

```
<style>, <class>, <div>タグは禁止
```

### 2.3 出力形式

```
<html>タグ不要、本文のみ出力
```

## 3. プロンプトテンプレート

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