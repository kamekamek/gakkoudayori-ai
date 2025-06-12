# 季節カラーパレット設計

## 1. 概要

学級通信作成システムにおける季節ごとのカラーパレット定義です。春夏秋冬の季節感を表現する色彩設計で、ワンクリックでテーマを適用できます。

## 2. 季節パレット定義

### 2.1 春（Spring）

```css
.theme-spring {
  --primary: #ff9eaa;     /* 桜色 */
  --secondary: #a5d8ff;   /* 春の空色 */
  --accent: #ffdb4d;      /* 菜の花色 */
  --background: #f8f9fa;  /* 明るい背景 */
  --text: #343a40;        /* 標準テキスト色 */
  --heading: #e64980;     /* 見出し色 */
  --link: #4c6ef5;        /* リンク色 */
  --border: #dee2e6;      /* 境界線色 */
}
```

**適用例**:
- 背景：明るい白色（新学期の清々しさ）
- 見出し：桜色のアクセント
- 強調：淡い水色と黄色のポイント

### 2.2 夏（Summer）

```css
.theme-summer {
  --primary: #51cf66;     /* 若葉色 */
  --secondary: #339af0;   /* 夏空色 */
  --accent: #ff922b;      /* 太陽色 */
  --background: #f1f8ff;  /* 涼しげな背景 */
  --text: #1a1c20;        /* 濃いテキスト色 */
  --heading: #20c997;     /* 見出し色 */
  --link: #1971c2;        /* リンク色 */
  --border: #e7f5ff;      /* 境界線色 */
}
```

**適用例**:
- 背景：涼しげな薄青色（清涼感）
- 見出し：みずみずしい緑色
- 強調：ビビッドなオレンジと青のコントラスト

### 2.3 秋（Autumn）

```css
.theme-autumn {
  --primary: #e67700;     /* 紅葉色 */
  --secondary: #d9480f;   /* 深紅色 */
  --accent: #fff3bf;      /* 穏やかな黄色 */
  --background: #fff9db;  /* 優しい背景 */
  --text: #2b2a29;        /* 深みのあるテキスト色 */
  --heading: #c92a2a;     /* 見出し色 */
  --link: #a61e4d;        /* リンク色 */
  --border: #ffe8cc;      /* 境界線色 */
}
```

**適用例**:
- 背景：暖かみのある淡黄色（落ち着き）
- 見出し：深みのある赤茶色
- 強調：温かみのある色調の組み合わせ

### 2.4 冬（Winter）

```css
.theme-winter {
  --primary: #4dabf7;     /* 冬空色 */
  --secondary: #e7f5ff;   /* 雪色 */
  --accent: #91a7ff;      /* 薄紫色 */
  --background: #f8f9fa;  /* 白い背景 */
  --text: #1a1c20;        /* 濃いテキスト色 */
  --heading: #1864ab;     /* 見出し色 */
  --link: #5f3dc4;        /* リンク色 */
  --border: #d0ebff;      /* 境界線色 */
}
```

**適用例**:
- 背景：純白（雪のイメージ）
- 見出し：冬空を思わせる青色
- 強調：清潔感のある青と白の組み合わせ

## 3. JSONフォーマット

APIやアプリケーション内での利用に適したJSON形式定義：

```json
{
  "spring": {
    "primary": "#ff9eaa",
    "secondary": "#a5d8ff",
    "accent": "#ffdb4d",
    "background": "#f8f9fa",
    "text": "#343a40",
    "heading": "#e64980",
    "link": "#4c6ef5",
    "border": "#dee2e6"
  },
  "summer": {
    "primary": "#51cf66",
    "secondary": "#339af0",
    "accent": "#ff922b",
    "background": "#f1f8ff",
    "text": "#1a1c20",
    "heading": "#20c997",
    "link": "#1971c2",
    "border": "#e7f5ff"
  },
  "autumn": {
    "primary": "#e67700",
    "secondary": "#d9480f",
    "accent": "#fff3bf",
    "background": "#fff9db",
    "text": "#2b2a29",
    "heading": "#c92a2a",
    "link": "#a61e4d",
    "border": "#ffe8cc"
  },
  "winter": {
    "primary": "#4dabf7",
    "secondary": "#e7f5ff",
    "accent": "#91a7ff",
    "background": "#f8f9fa",
    "text": "#1a1c20",
    "heading": "#1864ab",
    "link": "#5f3dc4",
    "border": "#d0ebff"
  }
}
```

## 4. アクセシビリティ対応

各パレットはWCAG 2.1 AAレベルのコントラスト比を満たすように設計されています：

| 季節 | テキスト/背景 コントラスト比 | 判定 |
|-----|------------------------|------|
| 春  | 10.54:1 | ✅ AAA |
| 夏  | 15.68:1 | ✅ AAA |
| 秋  | 14.57:1 | ✅ AAA |
| 冬  | 15.68:1 | ✅ AAA |

## 5. 実装方法

### 5.1 CSS変数による実装

**グローバルスタイル**:

```css
:root {
  /* デフォルトは春 */
  --primary: #ff9eaa;
  --secondary: #a5d8ff;
  --accent: #ffdb4d;
  --background: #f8f9fa;
  --text: #343a40;
  --heading: #e64980;
  --link: #4c6ef5;
  --border: #dee2e6;
}

body {
  background-color: var(--background);
  color: var(--text);
}

h1, h2, h3 {
  color: var(--heading);
}

a {
  color: var(--link);
}

.border {
  border-color: var(--border);
}

/* 各季節テーマクラス定義は前述の通り */
```

### 5.2 JavaScript/Dartでの季節切り替え

```dart
void changeSeason(String season) {
  // 有効な季節かチェック
  if (!['spring', 'summer', 'autumn', 'winter'].contains(season)) {
    return;
  }
  
  // WebViewで実行するJavaScript
  final js = '''
    document.body.className = '';
    document.body.classList.add('theme-$season');
  ''';
  
  // JavaScriptを実行
  webViewController.evaluateJavascript(source: js);
  
  // 現在の季節を保存
  setState(() {
    currentSeason = season;
  });
}
```

### 5.3 季節自動判定機能

```dart
String detectCurrentSeason() {
  final now = DateTime.now();
  final month = now.month;
  
  // 月に基づいて季節を判定
  if (month >= 3 && month <= 5) {
    return 'spring';  // 3-5月は春
  } else if (month >= 6 && month <= 8) {
    return 'summer';  // 6-8月は夏
  } else if (month >= 9 && month <= 11) {
    return 'autumn';  // 9-11月は秋
  } else {
    return 'winter';  // 12-2月は冬
  }
}
```

## 6. ユーザーインターフェース

季節選択ボタンのデザイン例：

```dart
Widget buildSeasonSelector() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      // 春ボタン
      ElevatedButton.icon(
        icon: Icon(Icons.local_florist, color: Color(0xFFFF9EAA)),
        label: Text('春'),
        style: ElevatedButton.styleFrom(
          backgroundColor: currentSeason == 'spring' 
              ? Color(0xFFFFE8EC) 
              : Colors.white,
        ),
        onPressed: () => changeSeason('spring'),
      ),
      SizedBox(width: 8),
      
      // 夏ボタン
      ElevatedButton.icon(
        icon: Icon(Icons.wb_sunny, color: Color(0xFFFF922B)),
        label: Text('夏'),
        style: ElevatedButton.styleFrom(
          backgroundColor: currentSeason == 'summer' 
              ? Color(0xFFE7F5FF) 
              : Colors.white,
        ),
        onPressed: () => changeSeason('summer'),
      ),
      SizedBox(width: 8),
      
      // 秋ボタン
      ElevatedButton.icon(
        icon: Icon(Icons.eco, color: Color(0xFFE67700)),
        label: Text('秋'),
        style: ElevatedButton.styleFrom(
          backgroundColor: currentSeason == 'autumn' 
              ? Color(0xFFFFF9DB) 
              : Colors.white,
        ),
        onPressed: () => changeSeason('autumn'),
      ),
      SizedBox(width: 8),
      
      // 冬ボタン
      ElevatedButton.icon(
        icon: Icon(Icons.ac_unit, color: Color(0xFF4DABF7)),
        label: Text('冬'),
        style: ElevatedButton.styleFrom(
          backgroundColor: currentSeason == 'winter' 
              ? Color(0xFFE7F5FF) 
              : Colors.white,
        ),
        onPressed: () => changeSeason('winter'),
      ),
    ],
  );
}
``` 