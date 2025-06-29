```html
<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{school_name}} 学校だより - {{main_title}}</title>
    <style>
        /* === 共通スタイル === */
        body {
            font-family: 'Helvetica Neue', 'Arial', 'Hiragino Sans', 'Meiryo', sans-serif;
            color: #333333; /* 本文は読みやすい濃いグレーに固定 */
            margin: 0;
        }
        .container {
            background-color: white;
        }
        .header {
            border-bottom: 3px solid {{color_scheme.primary}};
            padding-bottom: 15px;
            margin-bottom: 25px;
            display: flex;
            justify-content: space-between;
            align-items: flex-end;
            flex-wrap: wrap;
        }
        .header-info p { 
            margin: 2px 0; 
            font-size: 14px; 
            color: #333333; /* ヘッダー情報も読みやすい濃いグレーに固定 */
        }
        .main-title {
            font-size: 28px;
            font-weight: bold;
            color: {{color_scheme.primary}};
            margin-top: 10px;
            margin-bottom: 15px;
            line-height: 1.2;
            text-align: center;
        }
        .section-title {
            font-size: 18px;
            font-weight: bold;
            color: {{color_scheme.secondary}};
            border-bottom: 2px solid {{color_scheme.accent}};
            padding-bottom: 5px;
            margin-bottom: 10px;
        }
        .section-content {
            font-size: 14px;
            line-height: 1.6;
            text-align: justify;
            margin-bottom: 15px;
            color: #333333; /* 本文は読みやすい濃いグレーに固定 */
        }
        .photo-placeholder {
            margin: 10px 0;
            text-align: center;
        }
        .photo-placeholder img {
            width: 100%;
            max-width: 200px;
            height: auto;
            aspect-ratio: 3/2;
            border-radius: 4px;
            border: 1px solid #ddd;
        }
        .photo-placeholder figcaption {
            font-size: 12px;
            text-align: center;
            color: #666666; /* キャプションは少し明るめのグレー */
            margin-top: 5px;
            font-style: italic;
        }
        .editor-note {
            background-color: #f8f9fa;
            border-left: 5px solid {{color_scheme.accent}};
            padding: 15px 20px;
            margin-top: 20px;
            font-style: italic;
            color: #333333; /* 編集後記も読みやすい濃いグレーに固定 */
        }
        .editor-note p { 
            margin: 0; 
            color: #333333; /* 編集後記の段落も読みやすい濃いグレーに固定 */
        }
        .highlight-box {
            background-color: #f0f8ff;
            border: 1px solid {{color_scheme.accent}};
            border-radius: 3px;
            padding: 10px;
            margin: 10px 0;
            font-size: 13px;
        }
        .important-points {
            font-weight: bold;
            color: #2e8b57;
            margin-bottom: 5px;
        }

        /* 強制改ページ要素 */
        .page-break { 
            page-break-after: always; 
            break-after: page;
        }

        /* === 画面表示用スタイル === */
        @media screen {
            body {
                background-color: {{color_scheme.background}};
                padding: 20px;
            }
            .container {
                /* A4比率 (210:297) に合わせた設定 */
                width: 210mm;
                height: 297mm;
                max-width: 794px; /* 210mm = 794px (96dpi) */
                max-height: 1123px; /* 297mm = 1123px (96dpi) */
                margin: 0 auto;
                padding: 30px 40px; /* 上下左右のパディングを縮小 */
                box-shadow: 0 4px 12px rgba(0,0,0,0.1);
                border-radius: 8px;
                overflow: hidden;
                display: flex;
                flex-direction: column; /* 縦方向のレイアウト制御 */
            }
            .content {
                column-count: 2;
                column-gap: 40px;
                flex-grow: 1; /* 余白を埋めるよう拡張 */
            }
        }

        /* === スマートフォン用レスポンシブ設定 === */
        @media screen and (max-width: 768px) {
            .content {
                column-count: 1;
            }
        }

        /* === 印刷用スタイル（v3.1強化版） === */
        @media print {
            /* 印刷紙面サイズの固定 */
            @page { 
                size: A4 portrait; 
                margin: 8mm 10mm 8mm 10mm; /* マージンを縮小して印刷領域を拡大 */
            }

            /* 印刷時の色再現を強制 */
            * {
                -webkit-print-color-adjust: exact !important;
                color-adjust: exact !important;
            }
            body {
                background-color: #fff;
                font-size: 13px; /* 印刷時はさらにフォントサイズを縮小 */
            }
            .container {
                width: 100%;
                margin: 0;
                padding: 0;
                box-shadow: none;
                border-radius: 0;
            }
            .content {
                column-count: 2;
                column-gap: 20px; /* さらに詰める */
                column-fill: balance;
            }
            
            /* 印刷時のフォントサイズをさらに調整 */
            .main-title {
                font-size: 24px; /* 28px→24px */
                margin-top: 5px;
                margin-bottom: 10px;
            }
            .section-title {
                font-size: 16px; /* 18px→16px */
                margin-bottom: 8px;
            }
            .section-content {
                font-size: 12px; /* 14px→12px */
                line-height: 1.5;
                margin-bottom: 10px;
            }
            .photo-placeholder {
                margin: 8px 0;
            }
            .photo-placeholder img {
                max-width: 150px; /* さらに小さく */
            }
            .highlight-box {
                padding: 8px;
                margin: 8px 0;
                font-size: 11px;
            }
            
            /* --- 改ページ制御を緩和 --- */
            .section-title, h2 {
                break-after: avoid;
            }
            /* セクション全体は分割可能にして、画像だけ分割禁止 */
            .photo-placeholder, .highlight-box {
                break-inside: avoid;
                page-break-inside: avoid;
            }
            /* 段落は分割可能に */
            p, .section-content {
                orphans: 1; /* 緩和 */
                widows: 1; /* 緩和 */
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <!-- ヘッダー情報 -->
        <header class="header">
            <div class="header-info">
                <p>{{school_name}} {{grade}}</p>
                <p>{{issue}}</p>
            </div>
            <div class="header-info">
                <p>発行日: {{issue_date}}</p>
                <p>発行者: {{author.title}} {{author.name}}</p>
            </div>
        </header>

        <!-- メインタイトル -->
        <h1 class="main-title">{{main_title}}</h1>

        <!-- 本文（2段組み） -->
        <main class="content">
            <!-- セクションはJSONのsections配列を元にループ処理で生成 -->
            {{#each sections}}
            <section class="section">
                {{#if this.title}}
                <h2 class="section-title">{{this.title}}</h2>
                {{/if}}
                <p class="section-content">{{this.content}}</p>
            </section>
            
            <!-- 写真の配置判定 -->
            {{#each ../photo_placeholders.suggested_positions}}
                {{#if (contains ../this.title this.section_type)}}
                <figure class="photo-placeholder">
                    <img src="https://placehold.co/600x400/{{../../color_scheme.primary_hex}}/FFFFFF?text=写真{{@index}}" alt="{{this.caption_suggestion}}">
                    <figcaption>{{this.caption_suggestion}}</figcaption>
                </figure>
                {{/if}}
            {{/each}}
            {{/each}}

            <!-- 編集後記 -->
            {{#if has_editor_note}}
            <div class="editor-note">
                <p>{{editor_note}}</p>
            </div>
            {{/if}}
        </main>
    </div>

    <!--
    [AUTO VOLUME DETECTION & OPTIMIZATION v3.2]
    1. 文字数カウント: totalChars = sum(all section.content.length)
    2. 画像数カウント: totalImages = photo_placeholders.count
    3. ボリューム判定: 
       - Light: totalChars < 800 && totalImages <= 3 → 印刷最適化CSS適用
       - Medium: totalChars < 1500 && totalImages <= 5 → 標準CSS
       - Heavy: totalChars >= 1500 || totalImages > 5 → 2ページ対応CSS
    4. force_single_page: true の場合は、必ずLight設定を適用
    5. max_pages制限がある場合は、その範囲内に収まるよう調整
    6. A4比率(210:297mm)を画面表示でも維持
    -->
</body>
</html> 
```