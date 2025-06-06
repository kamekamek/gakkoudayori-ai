"""
PDF生成サービス
WeasyPrintを使ったHTML→PDF変換
"""
import io
import tempfile
from pathlib import Path
from typing import Optional, Dict, Any
from dataclasses import dataclass
import base64
import os

try:
    import weasyprint
    from weasyprint import HTML, CSS
    from weasyprint.text.fonts import FontConfiguration
    WEASYPRINT_AVAILABLE = True
except ImportError:
    WEASYPRINT_AVAILABLE = False
    weasyprint = None


@dataclass
class PdfGenerationResult:
    """PDF生成結果"""
    success: bool
    pdf_data: Optional[bytes] = None
    file_path: Optional[str] = None
    error_message: Optional[str] = None
    processing_time_ms: Optional[int] = None


class PdfService:
    """PDF生成サービス"""
    
    def __init__(self):
        """初期化"""
        if not WEASYPRINT_AVAILABLE:
            raise ImportError("WeasyPrint is not installed. Run: pip install weasyprint")
        
        # 日本語フォント設定
        self.font_config = FontConfiguration()
        self.default_css = self._get_default_css()
    
    def generate_pdf_from_html(
        self,
        html_content: str,
        css_content: Optional[str] = None,
        base_url: Optional[str] = None,
        options: Optional[Dict[str, Any]] = None
    ) -> PdfGenerationResult:
        """
        HTMLからPDFを生成
        
        Args:
            html_content: HTML内容
            css_content: 追加CSS（オプション）
            base_url: ベースURL（画像等のリソース用）
            options: PDF生成オプション
        
        Returns:
            PdfGenerationResult: PDF生成結果
        """
        try:
            start_time = self._get_current_time_ms()
            
            # デフォルトオプション
            default_options = {
                'page_size': 'A4',
                'margin_top': '20mm',
                'margin_bottom': '20mm',
                'margin_left': '15mm',
                'margin_right': '15mm',
                'encoding': 'utf-8'
            }
            
            if options:
                default_options.update(options)
            
            # CSS準備
            css_stylesheets = [CSS(string=self.default_css, font_config=self.font_config)]
            if css_content:
                css_stylesheets.append(CSS(string=css_content, font_config=self.font_config))
            
            # HTML準備（日本語対応）
            full_html = self._prepare_html_for_pdf(html_content, default_options)
            
            # PDF生成
            html_doc = HTML(
                string=full_html,
                base_url=base_url,
                encoding=default_options['encoding']
            )
            
            # メモリ上でPDF生成
            pdf_buffer = io.BytesIO()
            html_doc.write_pdf(
                pdf_buffer,
                stylesheets=css_stylesheets,
                font_config=self.font_config
            )
            
            pdf_data = pdf_buffer.getvalue()
            processing_time = self._get_current_time_ms() - start_time
            
            return PdfGenerationResult(
                success=True,
                pdf_data=pdf_data,
                processing_time_ms=processing_time
            )
            
        except Exception as e:
            return PdfGenerationResult(
                success=False,
                error_message=f"PDF生成エラー: {str(e)}"
            )
    
    def save_pdf_to_file(
        self,
        pdf_data: bytes,
        file_path: str
    ) -> bool:
        """
        PDFデータをファイルに保存
        
        Args:
            pdf_data: PDFデータ
            file_path: 保存先パス
        
        Returns:
            bool: 保存成功かどうか
        """
        try:
            # ディレクトリが存在しない場合は作成
            Path(file_path).parent.mkdir(parents=True, exist_ok=True)
            
            with open(file_path, 'wb') as f:
                f.write(pdf_data)
            
            return True
            
        except Exception as e:
            print(f"PDF保存エラー: {e}")
            return False
    
    def generate_newsletter_pdf(
        self,
        title: str,
        content: str,
        teacher_name: str,
        class_name: str,
        date: str,
        season_theme: str = 'spring'
    ) -> PdfGenerationResult:
        """
        学級通信用PDFを生成
        
        Args:
            title: タイトル
            content: HTMLコンテンツ
            teacher_name: 先生の名前
            class_name: クラス名
            date: 日付
            season_theme: 季節テーマ
        
        Returns:
            PdfGenerationResult: PDF生成結果
        """
        try:
            # 学級通信用HTMLテンプレート
            newsletter_html = self._create_newsletter_template(
                title=title,
                content=content,
                teacher_name=teacher_name,
                class_name=class_name,
                date=date,
                season_theme=season_theme
            )
            
            # 学級通信用CSS
            newsletter_css = self._get_newsletter_css(season_theme)
            
            # PDF生成オプション
            options = {
                'page_size': 'A4',
                'margin_top': '15mm',
                'margin_bottom': '15mm',
                'margin_left': '10mm',
                'margin_right': '10mm',
            }
            
            return self.generate_pdf_from_html(
                html_content=newsletter_html,
                css_content=newsletter_css,
                options=options
            )
            
        except Exception as e:
            return PdfGenerationResult(
                success=False,
                error_message=f"学級通信PDF生成エラー: {str(e)}"
            )
    
    def _prepare_html_for_pdf(self, html_content: str, options: Dict[str, Any]) -> str:
        """PDF用HTMLを準備"""
        return f"""
        <!DOCTYPE html>
        <html lang="ja">
        <head>
            <meta charset="{options.get('encoding', 'utf-8')}">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>学級通信</title>
        </head>
        <body>
            {html_content}
        </body>
        </html>
        """
    
    def _get_default_css(self) -> str:
        """デフォルトCSS（日本語フォント対応）"""
        return """
        @page {
            margin: 20mm 15mm;
            size: A4;
            
            @top-center {
                content: "学級通信";
                font-family: "Noto Sans CJK JP", "Yu Gothic", "Meiryo", sans-serif;
                font-size: 10pt;
                color: #666;
            }
            
            @bottom-right {
                content: counter(page) " / " counter(pages);
                font-family: "Noto Sans CJK JP", "Yu Gothic", "Meiryo", sans-serif;
                font-size: 10pt;
                color: #666;
            }
        }
        
        body {
            font-family: "Noto Sans CJK JP", "Yu Gothic", "Meiryo", sans-serif;
            font-size: 12pt;
            line-height: 1.6;
            color: #333;
            margin: 0;
            padding: 0;
        }
        
        h1, h2, h3, h4, h5, h6 {
            font-family: "Noto Sans CJK JP", "Yu Gothic", "Meiryo", sans-serif;
            font-weight: bold;
            margin-top: 1em;
            margin-bottom: 0.5em;
            page-break-after: avoid;
        }
        
        h1 { font-size: 18pt; }
        h2 { font-size: 16pt; }
        h3 { font-size: 14pt; }
        
        p {
            margin-bottom: 0.8em;
            orphans: 2;
            widows: 2;
        }
        
        .page-break {
            page-break-before: always;
        }
        
        .no-break {
            page-break-inside: avoid;
        }
        
        img {
            max-width: 100%;
            height: auto;
            page-break-inside: avoid;
        }
        
        .newsletter-header {
            text-align: center;
            margin-bottom: 20pt;
            padding-bottom: 10pt;
            border-bottom: 2pt solid #4caf50;
        }
        
        .newsletter-footer {
            margin-top: 20pt;
            padding-top: 10pt;
            border-top: 1pt solid #ccc;
            font-size: 10pt;
            color: #666;
        }
        """
    
    def _get_newsletter_css(self, season_theme: str) -> str:
        """季節テーマに応じたCSS"""
        theme_colors = {
            'spring': {'primary': '#ffb6c1', 'secondary': '#98fb98', 'accent': '#ffd700'},
            'summer': {'primary': '#87ceeb', 'secondary': '#ffeb3b', 'accent': '#ff6347'},
            'autumn': {'primary': '#daa520', 'secondary': '#cd853f', 'accent': '#ff8c00'},
            'winter': {'primary': '#b0c4de', 'secondary': '#ffffff', 'accent': '#4169e1'},
        }
        
        colors = theme_colors.get(season_theme, theme_colors['spring'])
        
        return f"""
        .seasonal-theme {{
            background: linear-gradient(45deg, {colors['primary']}, {colors['secondary']});
            border-radius: 10pt;
            padding: 15pt;
            margin: 10pt 0;
        }}
        
        .seasonal-accent {{
            color: {colors['accent']};
            font-weight: bold;
        }}
        
        .speech-bubble {{
            background: {colors['primary']};
            border-radius: 15pt;
            padding: 10pt;
            margin: 10pt 0;
            position: relative;
            box-shadow: 2pt 2pt 5pt rgba(0,0,0,0.1);
        }}
        
        .graphical-record {{
            font-family: "Comic Sans MS", "Klee One", cursive;
            background: linear-gradient(135deg, #fff9e6, #f0f8ff);
            border-radius: 15pt;
            padding: 20pt;
            margin: 15pt 0;
            border: 3pt solid {colors['accent']};
        }}
        """
    
    def _create_newsletter_template(
        self,
        title: str,
        content: str,
        teacher_name: str,
        class_name: str,
        date: str,
        season_theme: str
    ) -> str:
        """学級通信テンプレート作成"""
        return f"""
        <div class="newsletter-container">
            <header class="newsletter-header">
                <h1>{title}</h1>
                <div class="class-info">
                    <span class="class-name">{class_name}</span>
                    <span class="date">{date}</span>
                </div>
            </header>
            
            <main class="newsletter-content seasonal-theme">
                {content}
            </main>
            
            <footer class="newsletter-footer">
                <div class="teacher-info">
                    <span>担任: {teacher_name}</span>
                </div>
                <div class="generated-info">
                    <span>ゆとり職員室で作成 - HTMLベースグラレコ風学級通信システム</span>
                </div>
            </footer>
        </div>
        """
    
    def _get_current_time_ms(self) -> int:
        """現在時刻をミリ秒で取得"""
        import time
        return int(time.time() * 1000)


# グローバルインスタンス
pdf_service = PdfService() if WEASYPRINT_AVAILABLE else None