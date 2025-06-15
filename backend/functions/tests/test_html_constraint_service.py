"""
HTML制約プロンプトサービスのテスト
"""

import unittest
from unittest.mock import patch, MagicMock
import os

# テスト対象のモジュール
from backend.functions.html_constraint_service import generate_constrained_html, ALLOWED_TAGS, DEFAULT_FORBIDDEN_ATTRIBUTES

class TestHTMLConstraintService(unittest.TestCase):

    def setUp(self):
        """テストケース実行前の共通設定"""
        self.project_id = "test-project"
        self.credentials_path = "test_credentials.json" # ダミーの認証情報パス
        # テスト用のダミー認証ファイルを作成 (必要な場合)
        if not os.path.exists(self.credentials_path):
            with open(self.credentials_path, 'w') as f:
                f.write('{"type": "service_account"}') # ダミーの内容

    def tearDown(self):
        """テストケース実行後のクリーンアップ"""
        if os.path.exists(self.credentials_path):
            os.remove(self.credentials_path)

    @patch('backend.functions.html_constraint_service.get_gemini_client')
    @patch('backend.functions.html_constraint_service.generate_text')
    def test_generate_constrained_html_success(self, mock_generate_text, mock_get_gemini_client):
        """HTML生成が成功し、実際の検証ロジックを通過するケース"""
        mock_gemini_model = MagicMock()
        mock_get_gemini_client.return_value = mock_gemini_model
        
        # Gemini APIからの期待されるレスポンス (モック)
        mock_api_response = {
            "success": True,
            "data": {
                "text": "<h1>こんにちは</h1><p>これはテストです。</p><ul><li>項目1</li></ul>",
                "ai_metadata": {
                    "model": "gemini-2.0-flash-exp",
                    "processing_time_ms": 500,
                    "word_count": 10,
                    "usage": {"total_token_count": 50}
                },
                "timestamp": "2025-06-11T02:30:00Z"
            }
        }
        mock_generate_text.return_value = mock_api_response

        prompt_text = "学校だよりの冒頭部分を作成してください。"
        constraints = {
            "allowed_tags": ALLOWED_TAGS,
            "max_word_count": 100
        }

        response = generate_constrained_html(
            prompt=prompt_text,
            project_id=self.project_id,
            credentials_path=self.credentials_path,
            constraints=constraints
        )
        
        self.assertTrue(response.get("success"))
        self.assertIn("html_content", response.get("data", {}))
        html_output = response["data"]["html_content"]
        
        # 簡単なタグ検証 (より厳密な検証は _validate_html_tags で行う想定)
        self.assertIn("<h1>こんにちは</h1>", html_output)
        self.assertIn("<p>これはテストです。</p>", html_output)
        self.assertIn("<ul><li>項目1</li></ul>", html_output)
        
        # 禁止タグが含まれていないことの確認 (例: <script>)
        self.assertNotIn("<script>", html_output.lower())
        mock_generate_text.assert_called_once() # Gemini APIが1回呼ばれたことを確認

    @patch('backend.functions.html_constraint_service.get_gemini_client')
    @patch('backend.functions.html_constraint_service.generate_text')
    def test_allowed_tags_only_and_filtering(self, mock_generate_text, mock_get_gemini_client):
        """許可リスト外のタグや禁止属性が含まれる場合、フィルタリングされエラーとなることを確認します。"""
        mock_gemini_model = MagicMock()
        mock_get_gemini_client.return_value = mock_gemini_model

        raw_html_from_api = "<h1>タイトル</h1><p class='important'>段落です。</p><div>これは許可されていないdivです。</div><em>強調</em>"
        expected_filtered_html = "<h1>タイトル</h1><p>段落です。</p><em>強調</em>"
        mock_api_response = {
            "success": True,
            "data": {
                "text": raw_html_from_api,
                "ai_metadata": { "model": "gemini-2.0-flash-exp"}
            }
        }
        mock_generate_text.return_value = mock_api_response

        constraints = {
            "allowed_tags": ALLOWED_TAGS, 
            "forbidden_tags": ["script", "style", "div"], # div を禁止
            # "forbidden_attributes" は指定しないので DEFAULT_FORBIDDEN_ATTRIBUTES ('class', 'id', 'style', ...) が適用される
        }

        response = generate_constrained_html(
            prompt="フィルタリングテスト",
            project_id=self.project_id,
            credentials_path=self.credentials_path,
            constraints=constraints
        )

        self.assertFalse(response.get("success"))
        self.assertEqual(response.get("error", {}).get("code"), "HTML_VALIDATION_FILTERING_ERROR")
        self.assertIn("生成されたHTMLに制約違反があり", response.get("error", {}).get("message"))
        
        details = response.get("error", {}).get("details", {})
        self.assertIn(raw_html_from_api[:100], details.get("original_html_preview", ""))
        self.assertIn(expected_filtered_html, details.get("filtered_html_preview", ""))
        self.assertEqual(details.get("allowed_tags"), ALLOWED_TAGS)
        self.assertEqual(details.get("forbidden_tags_applied"), ["script", "style", "div"])
        self.assertEqual(details.get("forbidden_attributes_applied"), DEFAULT_FORBIDDEN_ATTRIBUTES)

        validation_issues = details.get("validation_issues", [])
        self.assertTrue(any("FORBIDDEN_ATTRIBUTE_REMOVED: Attribute 'class'" in issue for issue in validation_issues))
        self.assertTrue(any("FORBIDDEN_TAG_REMOVED: Tag '<div>'" in issue for issue in validation_issues) or 
                        any("DISALLOWED_TAG_REMOVED: Tag '<div>'" in issue for issue in validation_issues)) # divはforbidden_tagsにも含まれる

        mock_generate_text.assert_called_once()

    @patch('backend.functions.html_constraint_service.get_gemini_client')
    @patch('backend.functions.html_constraint_service.generate_text')
    def test_forbidden_tags_and_attributes_filtered(self, mock_generate_text, mock_get_gemini_client):
        """明示的に禁止されたタグや属性が含まれる場合、フィルタリングされエラーとなることを確認します。"""
        mock_gemini_model = MagicMock()
        mock_get_gemini_client.return_value = mock_gemini_model

        raw_html_from_api = (
            "<h1 style='color:red;'>重要なお知らせ</h1>"
            "<p>詳細は<strong id='notice'>こちら</strong>をご覧ください。</p>"
            "<script>doEvil();</script>"
        )
        expected_filtered_html = "<h1>重要なお知らせ</h1><p>詳細は<strong>こちら</strong>をご覧ください。</p>"
        mock_api_response = {
            "success": True,
            "data": {
                "text": raw_html_from_api,
                "ai_metadata": { "model": "gemini-2.0-flash-exp"}
            }
        }
        mock_generate_text.return_value = mock_api_response

        constraints = {
            "allowed_tags": ALLOWED_TAGS,
            "forbidden_tags": ["script"], 
            "forbidden_attributes": ["style", "id"]
        }

        response = generate_constrained_html(
            prompt="禁止タグフィルタリングテスト",
            project_id=self.project_id,
            credentials_path=self.credentials_path,
            constraints=constraints
        )

        self.assertFalse(response.get("success"))
        self.assertEqual(response.get("error", {}).get("code"), "HTML_VALIDATION_FILTERING_ERROR")
        self.assertIn("生成されたHTMLに制約違反があり", response.get("error", {}).get("message"))
        
        details = response.get("error", {}).get("details", {})
        self.assertIn(raw_html_from_api[:100], details.get("original_html_preview", ""))
        self.assertIn(expected_filtered_html, details.get("filtered_html_preview", ""))
        self.assertEqual(details.get("allowed_tags"), ALLOWED_TAGS)
        self.assertEqual(details.get("forbidden_tags_applied"), ["script"])
        self.assertEqual(details.get("forbidden_attributes_applied"), ["style", "id"])

        validation_issues = details.get("validation_issues", [])
        self.assertTrue(any("FORBIDDEN_TAG_REMOVED: Tag '<script>'" in issue for issue in validation_issues))
        self.assertTrue(any("FORBIDDEN_ATTRIBUTE_REMOVED: Attribute 'style'" in issue for issue in validation_issues))
        self.assertTrue(any("FORBIDDEN_ATTRIBUTE_REMOVED: Attribute 'id'" in issue for issue in validation_issues))

        mock_generate_text.assert_called_once()

    @patch('backend.functions.html_constraint_service.get_gemini_client')
    @patch('backend.functions.html_constraint_service.generate_text')
    def test_basic_html_structure(self, mock_generate_text, mock_get_gemini_client):
        """基本的なHTML構造が正しく生成され、実際の検証ロジックを通過するケース"""
        mock_gemini_model = MagicMock()
        mock_get_gemini_client.return_value = mock_gemini_model
        # _validate_html_tags のモックは解除したので、この行は不要
        # mock_validate_html_tags.return_value = True

        # Gemini APIからの期待される応答 (基本的な構造を含む)
        expected_html_structure = (
            "<h1>イベントのお知らせ</h1>"
            "<h2>運動会について</h2>"
            "<p>来る10月10日に運動会が開催されます。詳細は以下の通りです。</p>"
            "<h3>主な競技</h3>"
            "<ul>"
            "<li>徒競走</li>"
            "<li>玉入れ</li>"
            "<li>リレー</li>"
            "</ul>"
            "<p><strong>持ち物:</strong> 体操服、水筒、タオル</p>"
            "<em>雨天時は体育館で行います。</em>"
        )
        mock_api_response = {
            "success": True,
            "data": {
                "text": expected_html_structure,
                "ai_metadata": { "model": "gemini-2.0-flash-exp", "usage": {"total_token_count": 100}},
                "timestamp": "2025-06-11T03:10:00Z"
            }
        }
        mock_generate_text.return_value = mock_api_response

        constraints = {
            "allowed_tags": ALLOWED_TAGS,
            "ensure_structure": ["h1", "p", "ul>li"] # 期待する構造のヒント (実装次第)
        }

        response = generate_constrained_html(
            prompt="運動会のお知らせを作成してください。",
            project_id=self.project_id,
            credentials_path=self.credentials_path,
            constraints=constraints
        )

        # generate_constrained_html の実装により、成功レスポンスを期待
        self.assertTrue(response.get("success"))
        html_output = response.get("data", {}).get("html_content", "")

        # GREENフェーズでは、モックされたGemini APIからのexpected_html_structureが
        # そのままhtml_contentとして返されることを検証します。
        self.assertEqual(html_output, expected_html_structure)

        mock_generate_text.assert_called_once()
        # mock_validate_html_tags の呼び出し確認は、generate_constrained_html の実装による
        # mock_validate_html_tags.assert_called_once_with(expected_html_structure, ALLOWED_TAGS, None)

    @patch('backend.functions.html_constraint_service.generate_text')
    def test_gemini_api_error_handling(self, mock_generate_text):
        """Gemini API呼び出しでエラーが発生した場合のテスト"""
        mock_generate_text.return_value = {
            "success": False,
            "error": {
                "code": "API_RATE_LIMIT",
                "message": "Quota exceeded for an API. Please try again later."
            }
        }
        
        response = generate_constrained_html(
            prompt="エラーテスト",
            project_id=self.project_id,
            credentials_path=self.credentials_path
        )
        self.assertFalse(response.get("success"))
        self.assertEqual(response.get("error", {}).get("code"), "API_RATE_LIMIT")

    # 他にも、プロンプトエンジニアリングのテスト、制約違反時のテストなどを追加

    @patch('backend.functions.html_constraint_service.get_gemini_client')
    @patch('backend.functions.html_constraint_service.generate_text')
    def test_no_filtering_needed_for_valid_html(self, mock_generate_text, mock_get_gemini_client):
        """有効なHTMLが生成された場合、フィルタリングが不要で成功することを確認します。"""
        mock_gemini_model = MagicMock()
        mock_get_gemini_client.return_value = mock_gemini_model

        valid_html = "<h1>タイトル</h1><p>これは完全に有効なHTMLです。</p><ul><li>リスト項目</li></ul>"
        mock_api_response = {
            "success": True,
            "data": {
                "text": valid_html,
                "ai_metadata": { "model": "gemini-2.0-flash-exp"}
            }
        }
        mock_generate_text.return_value = mock_api_response

        constraints = {
            "allowed_tags": ALLOWED_TAGS,
            "forbidden_tags": ["script"],
            "forbidden_attributes": ["style", "id"]
        }

        response = generate_constrained_html(
            prompt="有効HTMLテスト",
            project_id=self.project_id,
            credentials_path=self.credentials_path,
            constraints=constraints
        )

        self.assertTrue(response.get("success"))
        self.assertIsNotNone(response.get("data"))
        self.assertEqual(response.get("data", {}).get("html_content"), valid_html)
        # validation_issues が存在しないか、空であることを確認（エラーレスポンスではないので直接は取得できない）
        # このテストでは、エラーが発生しないことを確認することで間接的に検証
        self.assertIsNone(response.get("error"))
        mock_generate_text.assert_called_once()

    @patch('backend.functions.html_constraint_service.get_gemini_client')
    @patch('backend.functions.html_constraint_service.generate_text')
    @patch('backend.functions.html_constraint_service.BeautifulSoup') # BeautifulSoupをモック
    def test_html_parsing_error(self, mock_beautiful_soup, mock_generate_text, mock_get_gemini_client):
        """HTMLパースエラーが発生した場合、適切にエラー処理されることを確認します。"""
        mock_gemini_model = MagicMock()
        mock_get_gemini_client.return_value = mock_gemini_model

        # BeautifulSoupコンストラクタが例外を投げるように設定
        mock_beautiful_soup.side_effect = Exception("Simulated parsing error")

        # APIからのテキストはどんなものでも良い（パース時にエラーになるため）
        some_html_text = "<h1 class='foo'>Valid on surface, but will fail parsing due to mock</h1>"
        mock_api_response = {
            "success": True, # API呼び出し自体は成功したと仮定
            "data": {
                "text": some_html_text,
                "ai_metadata": { "model": "gemini-2.0-flash-exp"}
            }
        }
        mock_generate_text.return_value = mock_api_response

        response = generate_constrained_html(
            prompt="パースエラーテスト",
            project_id=self.project_id,
            credentials_path=self.credentials_path,
            constraints={}
        )

        self.assertFalse(response.get("success"))
        self.assertEqual(response.get("error", {}).get("code"), "HTML_VALIDATION_FILTERING_ERROR")
        self.assertIn("生成されたHTMLに制約違反があり", response.get("error", {}).get("message"))
        
        details = response.get("error", {}).get("details", {})
        self.assertIn(some_html_text[:100], details.get("original_html_preview", ""))
        self.assertEqual(details.get("filtered_html_preview", ""), "") # パースエラー時は空のHTMLが返る
        
        validation_issues = details.get("validation_issues", [])
        self.assertTrue(any("PARSE_ERROR: HTML parsing failed: Simulated parsing error" in issue for issue in validation_issues))
        mock_generate_text.assert_called_once()
        mock_beautiful_soup.assert_called_once_with(some_html_text, 'html.parser')

if __name__ == '__main__':
    unittest.main()

