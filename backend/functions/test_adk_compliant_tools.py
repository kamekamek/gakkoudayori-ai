"""
ADK準拠ツール関数の包括的テストスイート

Google ADK公式仕様準拠の確認とツール関数の動作検証
"""

import pytest
import unittest
from unittest.mock import patch, Mock
import json
import time
from datetime import datetime

# テスト対象のインポート
from adk_compliant_tools import (
    generate_newsletter_content,
    generate_design_specification,
    generate_html_newsletter,
    modify_html_content,
    validate_newsletter_quality,
    # ヘルパー関数
    validate_html_constraints,
    classify_modification_type,
    analyze_html_changes,
    evaluate_educational_value,
    evaluate_readability,
    evaluate_html_technical_quality,
    evaluate_parent_consideration,
    count_html_elements,
    calculate_readability_metrics
)


class TestADKCompliantTools(unittest.TestCase):
    """ADK準拠ツール関数テストクラス"""
    
    def setUp(self):
        """テスト前準備"""
        self.sample_transcript = "今日は運動会の練習をしました。子どもたちは徒競走とダンスの練習を頑張っていました。"
        self.sample_grade = "3年1組"
        self.sample_content = "保護者の皆様へ\n\n今日は3年1組の運動会練習を行いました..."
        self.sample_design_spec = {
            "color_scheme": {"primary": "#4CAF50", "secondary": "#81C784"},
            "fonts": {"heading": "Noto Sans JP", "body": "Hiragino Sans"}
        }
        self.sample_html = '<h1 style="color: #4CAF50;">学級通信</h1><p>内容...</p>'
    
    # ==============================================================================
    # 1. generate_newsletter_content テスト
    # ==============================================================================
    
    @patch('adk_compliant_tools.generate_text')
    def test_generate_newsletter_content_success(self, mock_generate_text):
        """正常ケース: 学級通信コンテンツ生成成功"""
        
        # Gemini APIレスポンスのモック
        mock_generate_text.return_value = {
            "success": True,
            "data": {"text": "生成された学級通信の内容です。保護者の皆様へ..."}
        }
        
        result = generate_newsletter_content(
            audio_transcript=self.sample_transcript,
            grade_level=self.sample_grade,
            content_type="newsletter"
        )
        
        # ADK準拠チェック
        self.assertIsInstance(result, dict)
        self.assertEqual(result["status"], "success")
        self.assertIn("content", result)
        self.assertIn("word_count", result)
        self.assertIn("grade_level", result)
        self.assertIn("processing_time_ms", result)
        
        # 内容検証
        self.assertTrue(len(result["content"]) > 0)
        self.assertEqual(result["grade_level"], self.sample_grade)
        self.assertIsInstance(result["word_count"], int)
        self.assertIsInstance(result["processing_time_ms"], int)
    
    def test_generate_newsletter_content_empty_transcript(self):
        """エラーケース: 空の音声認識結果"""
        
        result = generate_newsletter_content(
            audio_transcript="",
            grade_level=self.sample_grade,
            content_type="newsletter"
        )
        
        # ADK準拠エラーレスポンスチェック
        self.assertEqual(result["status"], "error")
        self.assertIn("error_message", result)
        self.assertIn("error_code", result)
        self.assertEqual(result["error_code"], "EMPTY_TRANSCRIPT")
        self.assertIn("processing_time_ms", result)
    
    def test_generate_newsletter_content_empty_grade_level(self):
        """エラーケース: 空の学年情報"""
        
        result = generate_newsletter_content(
            audio_transcript=self.sample_transcript,
            grade_level="",
            content_type="newsletter"
        )
        
        self.assertEqual(result["status"], "error")
        self.assertEqual(result["error_code"], "EMPTY_GRADE_LEVEL")
    
    @patch('adk_compliant_tools.generate_text')
    def test_generate_newsletter_content_api_failure(self, mock_generate_text):
        """エラーケース: Gemini API呼び出し失敗"""
        
        mock_generate_text.return_value = {
            "success": False,
            "error": {"message": "API rate limit exceeded"}
        }
        
        result = generate_newsletter_content(
            audio_transcript=self.sample_transcript,
            grade_level=self.sample_grade,
            content_type="newsletter"
        )
        
        self.assertEqual(result["status"], "error")
        self.assertEqual(result["error_code"], "API_CALL_FAILED")
        self.assertIn("API呼び出しに失敗", result["error_message"])
    
    @patch('adk_compliant_tools.generate_text')
    def test_generate_newsletter_content_exception_handling(self, mock_generate_text):
        """エラーケース: 予期せぬ例外処理"""
        
        mock_generate_text.side_effect = Exception("Unexpected error")
        
        result = generate_newsletter_content(
            audio_transcript=self.sample_transcript,
            grade_level=self.sample_grade,
            content_type="newsletter"
        )
        
        self.assertEqual(result["status"], "error")
        self.assertEqual(result["error_code"], "PROCESSING_ERROR")
        self.assertIn("予期せぬエラー", result["error_message"])
    
    # ==============================================================================
    # 2. generate_design_specification テスト
    # ==============================================================================
    
    def test_generate_design_specification_success(self):
        """正常ケース: デザイン仕様生成成功"""
        
        result = generate_design_specification(
            content=self.sample_content,
            theme="seasonal",
            grade_level=self.sample_grade
        )
        
        # ADK準拠チェック
        self.assertEqual(result["status"], "success")
        self.assertIn("design_spec", result)
        self.assertIn("season", result)
        self.assertIn("theme", result)
        self.assertIn("processing_time_ms", result)
        
        # デザイン仕様構造確認
        design_spec = result["design_spec"]
        self.assertIn("color_scheme", design_spec)
        self.assertIn("fonts", design_spec)
        self.assertIn("layout_sections", design_spec)
        self.assertIn("visual_elements", design_spec)
        
        # 季節判定確認
        self.assertIn(result["season"], ["spring", "summer", "autumn", "winter"])
    
    def test_generate_design_specification_empty_content(self):
        """エラーケース: 空のコンテンツ"""
        
        result = generate_design_specification(
            content="",
            theme="seasonal",
            grade_level=self.sample_grade
        )
        
        self.assertEqual(result["status"], "error")
        self.assertEqual(result["error_code"], "EMPTY_CONTENT")
    
    def test_generate_design_specification_theme_variations(self):
        """仕様確認: テーマバリエーション"""
        
        themes = ["classic", "modern", "seasonal"]
        
        for theme in themes:
            result = generate_design_specification(
                content=self.sample_content,
                theme=theme,
                grade_level=self.sample_grade
            )
            
            self.assertEqual(result["status"], "success")
            self.assertEqual(result["theme"], theme)
            
            design_spec = result["design_spec"]
            if theme == "classic":
                self.assertEqual(design_spec["fonts"]["heading"], "serif")
            elif theme == "modern":
                self.assertEqual(design_spec["layout_sections"][1]["columns"], 2)
    
    # ==============================================================================
    # 3. generate_html_newsletter テスト
    # ==============================================================================
    
    @patch('adk_compliant_tools.generate_text')
    def test_generate_html_newsletter_success(self, mock_generate_text):
        """正常ケース: HTML生成成功"""
        
        mock_generate_text.return_value = {
            "success": True,
            "data": {"text": self.sample_html}
        }
        
        result = generate_html_newsletter(
            content=self.sample_content,
            design_spec=self.sample_design_spec,
            template_type="newsletter"
        )
        
        # ADK準拠チェック
        self.assertEqual(result["status"], "success")
        self.assertIn("html", result)
        self.assertIn("char_count", result)
        self.assertIn("template_type", result)
        self.assertIn("validation_passed", result)
        self.assertIn("processing_time_ms", result)
        
        # 内容確認
        self.assertEqual(result["html"], self.sample_html)
        self.assertEqual(result["char_count"], len(self.sample_html))
        self.assertEqual(result["template_type"], "newsletter")
    
    def test_generate_html_newsletter_empty_content(self):
        """エラーケース: 空のコンテンツ"""
        
        result = generate_html_newsletter(
            content="",
            design_spec=self.sample_design_spec,
            template_type="newsletter"
        )
        
        self.assertEqual(result["status"], "error")
        self.assertEqual(result["error_code"], "EMPTY_CONTENT")
    
    def test_generate_html_newsletter_invalid_design_spec(self):
        """エラーケース: 不正なデザイン仕様"""
        
        # 空の辞書
        result = generate_html_newsletter(
            content=self.sample_content,
            design_spec={},
            template_type="newsletter"
        )
        
        self.assertEqual(result["status"], "error")
        self.assertEqual(result["error_code"], "EMPTY_DESIGN_SPEC")
        
        # 非辞書型
        result = generate_html_newsletter(
            content=self.sample_content,
            design_spec="invalid",
            template_type="newsletter"
        )
        
        self.assertEqual(result["status"], "error")
        self.assertEqual(result["error_code"], "INVALID_DESIGN_SPEC")
    
    # ==============================================================================
    # 4. modify_html_content テスト
    # ==============================================================================
    
    @patch('adk_compliant_tools.generate_text')
    def test_modify_html_content_success(self, mock_generate_text):
        """正常ケース: HTML修正成功"""
        
        modified_html = '<h1 style="color: #FF5722;">学級通信（修正版）</h1><p>内容...</p>'
        mock_generate_text.return_value = {
            "success": True,
            "data": {"text": modified_html}
        }
        
        result = modify_html_content(
            current_html=self.sample_html,
            modification_request="タイトルの色を赤色に変更してください"
        )
        
        # ADK準拠チェック
        self.assertEqual(result["status"], "success")
        self.assertIn("modified_html", result)
        self.assertIn("changes_made", result)
        self.assertIn("original_length", result)
        self.assertIn("modified_length", result)
        self.assertIn("modification_type", result)
        self.assertIn("processing_time_ms", result)
        
        # 内容確認
        self.assertEqual(result["modified_html"], modified_html)
        self.assertEqual(result["original_length"], len(self.sample_html))
        self.assertEqual(result["modified_length"], len(modified_html))
    
    def test_modify_html_content_empty_html(self):
        """エラーケース: 空のHTML"""
        
        result = modify_html_content(
            current_html="",
            modification_request="修正要求"
        )
        
        self.assertEqual(result["status"], "error")
        self.assertEqual(result["error_code"], "EMPTY_HTML")
    
    def test_modify_html_content_empty_request(self):
        """エラーケース: 空の修正要求"""
        
        result = modify_html_content(
            current_html=self.sample_html,
            modification_request=""
        )
        
        self.assertEqual(result["status"], "error")
        self.assertEqual(result["error_code"], "EMPTY_MODIFICATION_REQUEST")
    
    # ==============================================================================
    # 5. validate_newsletter_quality テスト
    # ==============================================================================
    
    def test_validate_newsletter_quality_success(self):
        """正常ケース: 品質検証成功"""
        
        result = validate_newsletter_quality(
            html_content=self.sample_html,
            original_content=self.sample_content
        )
        
        # ADK準拠チェック
        self.assertEqual(result["status"], "success")
        self.assertIn("quality_score", result)
        self.assertIn("assessment", result)
        self.assertIn("category_scores", result)
        self.assertIn("suggestions", result)
        self.assertIn("content_analysis", result)
        self.assertIn("processing_time_ms", result)
        
        # スコア範囲確認
        self.assertTrue(0 <= result["quality_score"] <= 100)
        self.assertIn(result["assessment"], ["excellent", "good", "acceptable", "needs_improvement"])
        
        # カテゴリ別スコア確認
        category_scores = result["category_scores"]
        required_categories = ["educational_value", "readability", "technical_accuracy", "parent_consideration"]
        for category in required_categories:
            self.assertIn(category, category_scores)
            self.assertTrue(0 <= category_scores[category] <= 100)
    
    def test_validate_newsletter_quality_insufficient_content(self):
        """エラーケース: 不十分なコンテンツ"""
        
        result = validate_newsletter_quality(
            html_content="",
            original_content=self.sample_content
        )
        
        self.assertEqual(result["status"], "error")
        self.assertEqual(result["error_code"], "INSUFFICIENT_CONTENT")
        
        result = validate_newsletter_quality(
            html_content=self.sample_html,
            original_content=""
        )
        
        self.assertEqual(result["status"], "error")
        self.assertEqual(result["error_code"], "INSUFFICIENT_CONTENT")


class TestHelperFunctions(unittest.TestCase):
    """ヘルパー関数テストクラス"""
    
    def test_validate_html_constraints(self):
        """HTML制約検証テスト"""
        
        # 許可されたHTML
        valid_html = '<h1>タイトル</h1><p><strong>強調</strong>テキスト</p>'
        self.assertTrue(validate_html_constraints(valid_html))
        
        # 禁止されたタグ
        invalid_html = '<div class="container"><p>内容</p></div>'
        self.assertFalse(validate_html_constraints(invalid_html))
    
    def test_classify_modification_type(self):
        """修正タイプ分類テスト"""
        
        test_cases = [
            ("色を変更してください", "style_modification"),
            ("新しい段落を追加してください", "content_addition"),
            ("この部分を削除してください", "content_removal"),
            ("文章を修正してください", "content_modification"),
            ("その他の要求", "general_modification")
        ]
        
        for request, expected_type in test_cases:
            result = classify_modification_type(request)
            self.assertEqual(result, expected_type)
    
    def test_analyze_html_changes(self):
        """HTML変更分析テスト"""
        
        original = "元のHTML"
        
        # 追加
        modified_longer = "元のHTML追加部分"
        result = analyze_html_changes(original, modified_longer)
        self.assertIn("追加", result)
        
        # 削除
        modified_shorter = "元の"
        result = analyze_html_changes(original, modified_shorter)
        self.assertIn("削除", result)
        
        # 同じ長さ
        modified_same = "変更HTML"
        result = analyze_html_changes(original, modified_same)
        self.assertIn("修正", result)
    
    def test_evaluate_educational_value(self):
        """教育的価値評価テスト"""
        
        # 高い教育的価値
        high_value_content = "子どもたちの成長が素晴らしく、学習への意欲も向上し、協力して頑張る姿が印象的でした。新しい発見もたくさんありました。"
        score = evaluate_educational_value(high_value_content)
        self.assertTrue(score >= 70)
        
        # 低い教育的価値
        low_value_content = "今日は普通の日でした。"
        score = evaluate_educational_value(low_value_content)
        self.assertTrue(score < 70)
    
    def test_count_html_elements(self):
        """HTML要素カウントテスト"""
        
        html = '<h1>タイトル</h1><p>段落1</p><p>段落2</p><ul><li>項目1</li><li>項目2</li></ul>'
        counts = count_html_elements(html)
        
        self.assertEqual(counts["h1"], 1)
        self.assertEqual(counts["p"], 2)
        self.assertEqual(counts["ul"], 1)
        self.assertEqual(counts["li"], 2)
    
    def test_calculate_readability_metrics(self):
        """読みやすさメトリクス計算テスト"""
        
        content = "これは第一文です。これは第二文です。これは第三文です。"
        metrics = calculate_readability_metrics(content)
        
        self.assertEqual(metrics["sentence_count"], 3)
        self.assertIsInstance(metrics["word_count"], int)
        self.assertIsInstance(metrics["avg_sentence_length"], float)
        self.assertIsInstance(metrics["complexity_score"], float)


class TestPerformanceAndIntegration(unittest.TestCase):
    """パフォーマンス・統合テストクラス"""
    
    @patch('adk_compliant_tools.generate_text')
    def test_performance_requirements(self, mock_generate_text):
        """パフォーマンス要件確認テスト"""
        
        # Gemini APIの高速レスポンスをシミュレート
        mock_generate_text.return_value = {
            "success": True,
            "data": {"text": "高速生成されたコンテンツ"}
        }
        
        start_time = time.time()
        
        result = generate_newsletter_content(
            audio_transcript="パフォーマンステスト用の音声認識結果",
            grade_level="3年1組",
            content_type="newsletter"
        )
        
        processing_time = time.time() - start_time
        
        # 5秒以内の要件確認
        self.assertTrue(processing_time < 5.0)
        self.assertEqual(result["status"], "success")
        self.assertTrue(result["processing_time_ms"] < 5000)
    
    @patch('adk_compliant_tools.generate_text')
    def test_full_workflow_integration(self, mock_generate_text):
        """完全ワークフロー統合テスト"""
        
        # Gemini APIレスポンスのモック
        mock_generate_text.return_value = {
            "success": True,
            "data": {"text": "モック生成コンテンツ"}
        }
        
        # Step 1: コンテンツ生成
        content_result = generate_newsletter_content(
            audio_transcript="統合テスト用音声認識結果",
            grade_level="3年1組",
            content_type="newsletter"
        )
        
        self.assertEqual(content_result["status"], "success")
        
        # Step 2: デザイン仕様生成
        design_result = generate_design_specification(
            content=content_result["content"],
            theme="seasonal",
            grade_level="3年1組"
        )
        
        self.assertEqual(design_result["status"], "success")
        
        # Step 3: HTML生成
        mock_generate_text.return_value = {
            "success": True,
            "data": {"text": '<h1>テスト学級通信</h1><p>内容...</p>'}
        }
        
        html_result = generate_html_newsletter(
            content=content_result["content"],
            design_spec=design_result["design_spec"],
            template_type="newsletter"
        )
        
        self.assertEqual(html_result["status"], "success")
        
        # Step 4: 品質検証
        quality_result = validate_newsletter_quality(
            html_content=html_result["html"],
            original_content=content_result["content"]
        )
        
        self.assertEqual(quality_result["status"], "success")
        
        # 全体結果確認
        self.assertTrue(all([
            content_result["status"] == "success",
            design_result["status"] == "success",
            html_result["status"] == "success",
            quality_result["status"] == "success"
        ]))


class TestErrorRecovery(unittest.TestCase):
    """エラー回復テストクラス"""
    
    @patch('adk_compliant_tools.generate_text')
    def test_partial_failure_handling(self, mock_generate_text):
        """部分的失敗時の処理確認"""
        
        # 最初は成功、次は失敗のシナリオ
        mock_generate_text.side_effect = [
            {"success": True, "data": {"text": "成功コンテンツ"}},  # content generation
            {"success": False, "error": {"message": "API error"}},  # HTML generation
        ]
        
        # コンテンツ生成は成功
        content_result = generate_newsletter_content(
            audio_transcript="テスト音声",
            grade_level="3年1組",
            content_type="newsletter"
        )
        self.assertEqual(content_result["status"], "success")
        
        # HTML生成は失敗
        design_spec = {"color_scheme": {"primary": "#000"}, "fonts": {"heading": "serif"}}
        html_result = generate_html_newsletter(
            content=content_result["content"],
            design_spec=design_spec,
            template_type="newsletter"
        )
        self.assertEqual(html_result["status"], "error")
        self.assertEqual(html_result["error_code"], "API_CALL_FAILED")


if __name__ == "__main__":
    # テスト実行設定
    unittest.main(
        verbosity=2,
        buffer=True,
        failfast=False,
        warnings='ignore'
    )