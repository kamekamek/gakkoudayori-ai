# draw.io XML作成手順書 - 学校だよりAI アーキテクチャ図

## 🎯 XML直接編集のメリット
- 一括でコンポーネントを配置可能
- 精密な座標・サイズ指定
- カラー・スタイルの統一
- バージョン管理しやすい

## 📋 draw.io XMLの基本構造

### 基本フォーマット
```xml
<mxfile host="app.diagrams.net" ...>
  <diagram name="図の名前" id="unique_id">
    <mxGraphModel dx="1422" dy="794" grid="1" ...>
      <root>
        <mxCell id="0" />
        <mxCell id="1" parent="0" />
        
        <!-- ここにコンポーネントを記述 -->
        
      </root>
    </mxGraphModel>
  </diagram>
</mxfile>
```

## 🧩 コンポーネント別XML作成方法

### 1. テキスト要素
```xml
<!-- タイトル -->
<mxCell id="title" 
       value="🌸 学校だよりAI システムアーキテクチャ" 
       style="text;html=1;strokeColor=none;fillColor=none;align=center;verticalAlign=middle;whiteSpace=wrap;rounded=0;fontSize=24;fontStyle=1;fontColor=#FF6B9D;" 
       vertex="1" parent="1">
  <mxGeometry x="400" y="20" width="600" height="40" as="geometry" />
</mxCell>
```

### 2. 矩形コンポーネント（基本）
```xml
<!-- Flutter Web -->
<mxCell id="flutter" 
       value="📱&lt;br&gt;&lt;b&gt;Flutter Web&lt;/b&gt;&lt;br&gt;PWA対応&lt;br&gt;教師用UI" 
       style="rounded=1;whiteSpace=wrap;html=1;fillColor=#E3F2FD;strokeColor=#42A5F5;strokeWidth=2;align=center;" 
       vertex="1" parent="1">
  <mxGeometry x="50" y="200" width="120" height="100" as="geometry" />
</mxCell>
```

### 3. コンテナ（破線ボーダー）
```xml
<!-- GCPコンテナ -->
<mxCell id="gcp_container" 
       value="Google Cloud Platform" 
       style="rounded=1;whiteSpace=wrap;html=1;fillColor=#E8F0FE;strokeColor=#4285F4;strokeWidth=3;fontSize=16;fontStyle=1;dashed=1;" 
       vertex="1" parent="1">
  <mxGeometry x="300" y="80" width="700" height="500" as="geometry" />
</mxCell>
```

### 4. 矢印（データフロー）
```xml
<!-- Flutter → Cloud Run の矢印 -->
<mxCell id="arrow1" value="" 
       style="endArrow=classic;html=1;strokeColor=#4CAF50;strokeWidth=3;" 
       edge="1" parent="1" source="flutter" target="cloudrun">
  <mxGeometry width="50" height="50" relative="1" as="geometry">
    <mxPoint x="200" y="250" as="sourcePoint" />
    <mxPoint x="580" y="170" as="targetPoint" />
  </mxGeometry>
</mxCell>
```

### 5. ラベル付き矢印
```xml
<!-- ラベル付きの矢印 -->
<mxCell id="arrow_with_label" value="API呼び出し" 
       style="endArrow=classic;html=1;strokeColor=#4CAF50;strokeWidth=3;fontSize=10;fontColor=#4CAF50;" 
       edge="1" parent="1" source="flutter" target="cloudrun">
  <mxGeometry width="50" height="50" relative="1" as="geometry">
    <mxPoint x="170" y="250" as="sourcePoint" />
    <mxPoint x="580" y="170" as="targetPoint" />
  </mxGeometry>
</mxCell>
```

## 🎨 スタイル定義集

### カラーコード
```xml
<!-- フロントエンド系 -->
fillColor=#E3F2FD;strokeColor=#42A5F5  <!-- Flutter: 薄い青 -->

<!-- GCP系 -->
fillColor=#E8F0FE;strokeColor=#4285F4  <!-- GCP: 薄いGCP青 -->

<!-- ADK/AI系 -->
fillColor=#E8F5E8;strokeColor=#4CAF50  <!-- ADK: 薄い緑 -->
fillColor=#C8E6C9;strokeColor=#4CAF50  <!-- エージェント: 濃い薄緑 -->

<!-- Firebase系 -->
fillColor=#FFF3E0;strokeColor=#FF9800  <!-- Firebase: 薄いオレンジ -->

<!-- Gemini系 -->
fillColor=#FFF8E1;strokeColor=#FFC107  <!-- Gemini: 薄い黄色 -->

<!-- Classroom系 -->
fillColor=#E1F5FE;strokeColor=#0277BD  <!-- Classroom: 薄い水色 -->

<!-- 音声系 -->
fillColor=#F3E5F5;strokeColor=#9C27B0  <!-- 音声: 薄い紫 -->

<!-- 情報ボックス -->
fillColor=#F8F9FA;strokeColor=#DEE2E6  <!-- 一般情報: グレー -->
```

### 基本スタイルパターン
```xml
<!-- 通常コンポーネント -->
style="rounded=1;whiteSpace=wrap;html=1;fillColor=#COLOR;strokeColor=#COLOR;strokeWidth=2;align=center;"

<!-- コンテナ（破線） -->
style="rounded=1;whiteSpace=wrap;html=1;fillColor=#COLOR;strokeColor=#COLOR;strokeWidth=3;dashed=1;"

<!-- タイトルテキスト -->
style="text;html=1;strokeColor=none;fillColor=none;align=center;verticalAlign=middle;whiteSpace=wrap;rounded=0;fontSize=24;fontStyle=1;fontColor=#FF6B9D;"

<!-- 小さなツール -->
style="rounded=1;whiteSpace=wrap;html=1;fillColor=#E8F5E8;strokeColor=#4CAF50;fontSize=10;"

<!-- 矢印 -->
style="endArrow=classic;html=1;strokeColor=#4CAF50;strokeWidth=3;"
```

## 📐 座標計算システム

### グリッド設計
```
キャンバス: 1400 x 900
グリッド: 10px間隔

左ゾーン (ユーザー):
- X: 50-270
- Y: 100-600

中央ゾーン (GCP):
- X: 300-1000
- Y: 80-580

右ゾーン (外部サービス):
- X: 1100-1220
- Y: 120-620

下部情報エリア:
- X: 50-1400
- Y: 650-800
```

### コンポーネントサイズ標準
```xml
<!-- メインコンポーネント -->
width="120" height="100"

<!-- エージェント -->
width="100" height="80"

<!-- 小さなツール -->
width="80" height="25"

<!-- 情報ボックス -->
width="300" height="150"

<!-- コンテナ -->
width="700" height="500"
```

## 🔧 XML作成ワークフロー

### Step 1: ベースファイル作成
```xml
<?xml version="1.0" encoding="UTF-8"?>
<mxfile host="app.diagrams.net" modified="2025-06-24T12:00:00.000Z" agent="Claude Code" etag="v1.0" version="24.7.17" type="device">
  <diagram name="学校だよりAI システムアーキテクチャ" id="architecture">
    <mxGraphModel dx="1422" dy="794" grid="1" gridSize="10" guides="1" tooltips="1" connect="1" arrows="1" fold="1" page="1" pageScale="1" pageWidth="1400" pageHeight="900" math="0" shadow="0">
      <root>
        <mxCell id="0" />
        <mxCell id="1" parent="0" />
        
        <!-- ここに要素を追加 -->
        
      </root>
    </mxGraphModel>
  </diagram>
</mxfile>
```

### Step 2: 要素追加順序
```
1. タイトル
2. コンテナ（GCP等）
3. メインコンポーネント（Flutter, Cloud Run等）
4. エージェント群
5. ツール群  
6. 矢印・データフロー
7. 情報ボックス
```

### Step 3: ID命名規則
```xml
<!-- 基本コンポーネント -->
id="flutter"
id="cloudrun" 
id="firebase_auth"

<!-- エージェント -->
id="orchestrator"
id="planner"
id="generator"

<!-- ツール -->
id="tool_speech"
id="tool_dict"

<!-- 矢印 -->
id="arrow_flutter_to_cloudrun"
id="arrow_orchestrator_to_planner"

<!-- 情報ボックス -->
id="info_tech_stack"
id="info_features"
```

## 🧪 XMLデバッグ方法

### よくあるエラー
```xml
<!-- ❌ 間違い: HTMLエスケープされていない -->
value="<b>タイトル</b>"

<!-- ✅ 正しい: HTMLエスケープ済み -->
value="&lt;b&gt;タイトル&lt;/b&gt;"

<!-- ❌ 間違い: 閉じタグなし -->
<mxCell ... vertex="1" parent="1">

<!-- ✅ 正しい: 自己終了タグ -->
<mxCell ... vertex="1" parent="1">
  <mxGeometry ... />
</mxCell>
```

### 検証方法
```bash
# XML構文チェック
xmllint --valid your_file.drawio

# draw.ioでインポートして確認
1. app.diagrams.net を開く
2. File → Import from → Device
3. XMLファイルを選択
4. エラーがあれば赤で表示される
```

## 📝 HTMLエスケープ早見表
```
< → &lt;
> → &gt;
& → &amp;
" → &quot;
改行 → &lt;br&gt;
太字 → &lt;b&gt;テキスト&lt;/b&gt;
```

## 🔄 XML編集Tips

### 1. 一括座標調整
```bash
# sedを使って一括でX座標を50px右に移動
sed 's/x="\([0-9]*\)"/x="$((\\1+50))"/g' input.drawio > output.drawio
```

### 2. 色の一括変更
```bash
# 特定の色を一括変更
sed 's/#42A5F5/#1976D2/g' input.drawio > output.drawio
```

### 3. テンプレート化
```xml
<!-- 再利用可能なコンポーネントテンプレート -->
<mxCell id="COMPONENT_ID" 
       value="COMPONENT_ICON&lt;br&gt;&lt;b&gt;COMPONENT_NAME&lt;/b&gt;&lt;br&gt;COMPONENT_DESC" 
       style="rounded=1;whiteSpace=wrap;html=1;fillColor=FILL_COLOR;strokeColor=STROKE_COLOR;strokeWidth=2;align=center;" 
       vertex="1" parent="1">
  <mxGeometry x="X_COORD" y="Y_COORD" width="WIDTH" height="HEIGHT" as="geometry" />
</mxCell>
```

## ✅ 完成XMLチェックリスト

- [ ] XML宣言が正しい
- [ ] mxfileタグが正しく閉じられている
- [ ] 全てのHTMLがエスケープされている
- [ ] IDが重複していない
- [ ] 座標が適切に配置されている
- [ ] スタイルが統一されている
- [ ] 矢印のsource/targetが正しい
- [ ] draw.ioでインポートできる

---

この手順書に従って、XMLを直接編集することで、正確で美しいシステムアーキテクト図を効率的に作成できます！