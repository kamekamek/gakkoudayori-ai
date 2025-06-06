"""
PDF生成サービスのテスト
TDD Red → Green → Refactor
"""
import pytest
from unittest.mock import Mock, patch, MagicMock
import io
from datetime import datetime

from services.pdf_service import PdfService, PdfGenerationResult


class TestPdfService:
    """PDF生成サービステストクラス"""

    @pytest.fixture
    def mock_weasyprint(self):
        """Mock WeasyPrint"""
        with patch('services.pdf_service.weasyprint') as mock_wp:
            mock_wp.HTML.return_value = Mock()
            mock_wp.CSS.return_value = Mock()
            mock_wp.text.fonts.FontConfiguration.return_value = Mock()
            yield mock_wp

    @pytest.fixture
    def pdf_service(self, mock_weasyprint):
        """PdfService インスタンス"""
        with patch('services.pdf_service.WEASYPRINT_AVAILABLE', True):
            return PdfService()

    def test_generate_pdf_from_html_success(self, pdf_service, mock_weasyprint):
        """🔴 Red: HTML→PDF変換成功テスト"""
        # Arrange
        test_html = "<h1>テスト学級通信</h1><p>今日は運動会でした。</p>"
        test_css = "body { font-family: 'Yu Gothic', sans-serif; }"
        
        mock_pdf_data = b"PDF binary data"
        mock_buffer = io.BytesIO()
        mock_buffer.write(mock_pdf_data)
        mock_buffer.seek(0)
        
        mock_html_doc = Mock()
        mock_weasyprint.HTML.return_value = mock_html_doc
        mock_html_doc.write_pdf.return_value = None
        
        # Mock write_pdf to simulate PDF generation
        def mock_write_pdf(target, **kwargs):
            target.write(mock_pdf_data)
            return None
        
        mock_html_doc.write_pdf.side_effect = mock_write_pdf

        # Act
        result = pdf_service.generate_pdf_from_html(
            html_content=test_html,
            css_content=test_css
        )

        # Assert
        assert isinstance(result, PdfGenerationResult)
        assert result.success is True
        assert result.pdf_data is not None
        assert len(result.pdf_data) > 0
        assert result.processing_time_ms is not None
        assert result.processing_time_ms > 0
        mock_weasyprint.HTML.assert_called_once()

    def test_generate_pdf_from_html_failure(self, pdf_service, mock_weasyprint):
        """🔴 Red: HTML→PDF変換失敗テスト"""
        # Arrange
        test_html = "<h1>テスト</h1>"
        
        mock_html_doc = Mock()
        mock_weasyprint.HTML.return_value = mock_html_doc
        mock_html_doc.write_pdf.side_effect = Exception("PDF generation failed")

        # Act
        result = pdf_service.generate_pdf_from_html(html_content=test_html)

        # Assert
        assert isinstance(result, PdfGenerationResult)
        assert result.success is False
        assert result.pdf_data is None
        assert result.error_message is not None
        assert "PDF generation failed" in result.error_message

    def test_generate_newsletter_pdf_success(self, pdf_service, mock_weasyprint):
        """🔴 Red: 学級通信PDF生成成功テスト"""
        # Arrange
        title = "3年1組 学級通信 第5号"
        content = "<h2>運動会について</h2><p>みんな頑張りました！</p>"
        teacher_name = "田中 太郎"
        class_name = "3年1組"
        date = "2025年6月7日"
        season_theme = "spring"
        
        mock_pdf_data = b"Newsletter PDF data"
        mock_html_doc = Mock()
        mock_weasyprint.HTML.return_value = mock_html_doc
        
        def mock_write_pdf(target, **kwargs):
            target.write(mock_pdf_data)
            return None
        
        mock_html_doc.write_pdf.side_effect = mock_write_pdf

        # Act
        result = pdf_service.generate_newsletter_pdf(
            title=title,
            content=content,
            teacher_name=teacher_name,
            class_name=class_name,
            date=date,
            season_theme=season_theme
        )

        # Assert
        assert isinstance(result, PdfGenerationResult)
        assert result.success is True
        assert result.pdf_data is not None
        assert len(result.pdf_data) > 0
        assert result.processing_time_ms is not None
        mock_weasyprint.HTML.assert_called_once()

    def test_save_pdf_to_file_success(self, pdf_service):
        """🔴 Red: PDFファイル保存成功テスト"""
        # Arrange
        pdf_data = b"Test PDF content"
        
        with patch('pathlib.Path') as mock_path, \
             patch('builtins.open', create=True) as mock_open:
            
            mock_file = MagicMock()
            mock_open.return_value.__enter__.return_value = mock_file
            mock_path.return_value.parent.mkdir.return_value = None
            
            file_path = "/tmp/test_newsletter.pdf"

            # Act
            result = pdf_service.save_pdf_to_file(pdf_data, file_path)

            # Assert
            assert result is True
            mock_file.write.assert_called_once_with(pdf_data)

    def test_save_pdf_to_file_failure(self, pdf_service):
        """🔴 Red: PDFファイル保存失敗テスト"""
        # Arrange
        pdf_data = b"Test PDF content"
        file_path = "/invalid/path/test.pdf"
        
        with patch('builtins.open', side_effect=PermissionError("Permission denied")):
            # Act
            result = pdf_service.save_pdf_to_file(pdf_data, file_path)

            # Assert
            assert result is False

    def test_newsletter_template_creation(self, pdf_service):
        """🔴 Red: 学級通信テンプレート作成テスト"""
        # Arrange
        title = "テスト通信"
        content = "<p>テスト内容</p>"
        teacher_name = "テスト先生"
        class_name = "1年A組"
        date = "2025年6月7日"
        season_theme = "spring"

        # Act
        template_html = pdf_service._create_newsletter_template(
            title=title,
            content=content,
            teacher_name=teacher_name,
            class_name=class_name,
            date=date,
            season_theme=season_theme
        )

        # Assert
        assert title in template_html
        assert content in template_html
        assert teacher_name in template_html
        assert class_name in template_html
        assert date in template_html
        assert "newsletter-container" in template_html
        assert "newsletter-header" in template_html
        assert "newsletter-content" in template_html
        assert "newsletter-footer" in template_html

    def test_seasonal_css_generation(self, pdf_service):
        """🔴 Red: 季節CSS生成テスト"""
        # Test different seasons
        seasons = ['spring', 'summer', 'autumn', 'winter']
        
        for season in seasons:
            # Act
            css = pdf_service._get_newsletter_css(season)
            
            # Assert
            assert css is not None
            assert "seasonal-theme" in css
            assert "seasonal-accent" in css
            assert "speech-bubble" in css
            assert "graphical-record" in css
            assert "#" in css  # Contains color codes

    def test_default_css_contains_japanese_fonts(self, pdf_service):
        """🔴 Red: デフォルトCSSに日本語フォントが含まれているテスト"""
        # Act
        css = pdf_service._get_default_css()

        # Assert
        assert "Noto Sans CJK JP" in css or "Yu Gothic" in css or "Meiryo" in css
        assert "font-family" in css
        assert "@page" in css
        assert "A4" in css

    def test_html_preparation_for_pdf(self, pdf_service):
        """🔴 Red: PDF用HTML準備テスト"""
        # Arrange
        html_content = "<h1>テスト</h1><p>内容</p>"
        options = {"encoding": "utf-8"}

        # Act
        prepared_html = pdf_service._prepare_html_for_pdf(html_content, options)

        # Assert
        assert "<!DOCTYPE html>" in prepared_html
        assert 'lang="ja"' in prepared_html
        assert 'charset="utf-8"' in prepared_html
        assert html_content in prepared_html
        assert "<title>学級通信</title>" in prepared_html

    def test_processing_time_measurement(self, pdf_service, mock_weasyprint):
        """🔴 Red: 処理時間計測テスト"""
        # Arrange
        test_html = "<h1>処理時間テスト</h1>"
        
        mock_pdf_data = b"PDF data"
        mock_html_doc = Mock()
        mock_weasyprint.HTML.return_value = mock_html_doc
        
        def mock_write_pdf(target, **kwargs):
            target.write(mock_pdf_data)
            return None
        
        mock_html_doc.write_pdf.side_effect = mock_write_pdf

        # Act
        result = pdf_service.generate_pdf_from_html(html_content=test_html)

        # Assert
        assert result.success is True
        assert result.processing_time_ms is not None
        assert result.processing_time_ms >= 0
        assert isinstance(result.processing_time_ms, int)

    def test_error_handling_with_invalid_html(self, pdf_service, mock_weasyprint):
        """🔴 Red: 無効なHTML処理エラーハンドリングテスト"""
        # Arrange
        invalid_html = "<html><head><title>Test</head><body><h1>Unclosed"
        
        mock_html_doc = Mock()
        mock_weasyprint.HTML.return_value = mock_html_doc
        mock_html_doc.write_pdf.side_effect = ValueError("Invalid HTML structure")

        # Act
        result = pdf_service.generate_pdf_from_html(html_content=invalid_html)

        # Assert
        assert result.success is False
        assert result.error_message is not None
        assert "Invalid HTML structure" in result.error_message or "PDF生成エラー" in result.error_message