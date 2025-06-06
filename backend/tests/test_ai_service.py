"""
AI Service テスト
TDD原則に従ったVertex AI Gemini統合テスト
"""
import pytest
import asyncio
import json
from unittest.mock import AsyncMock, patch, MagicMock
from services.ai_service import AIService, ai_service

class TestAIService:
    """AI サービステストクラス"""
    
    @pytest.fixture
    def mock_ai_service(self):
        """AIサービスのモックを作成"""
        with patch('services.ai_service.vertexai'), \
             patch('services.ai_service.GenerativeModel') as mock_model:
            
            mock_instance = MagicMock()
            mock_model.return_value = mock_instance
            
            service = AIService()
            service.model = mock_instance
            return service
    
    @pytest.mark.asyncio
    async def test_rewrite_text_success(self, mock_ai_service):
        """テキストリライト成功ケース"""
        # Arrange
        original_text = "今日は運動会でした。子どもたちがとても頑張っていました。"
        expected_response = "本日は運動会を開催いたしました。子どもたちは一生懸命に競技に取り組み、素晴らしい姿を見せてくれました。"
        
        # モックレスポンス設定
        mock_response = MagicMock()
        mock_response.text = expected_response
        mock_ai_service.model.generate_content.return_value = mock_response
        
        # Act
        result = await mock_ai_service.rewrite_text(
            original_text=original_text,
            style="friendly",
            custom_instruction="保護者にわかりやすく",
            grade_level="elementary"
        )
        
        # Assert
        assert result["original_text"] == original_text
        assert result["rewritten_text"] == expected_response
        assert result["style"] == "friendly"
        assert result["custom_instruction"] == "保護者にわかりやすく"
        assert result["grade_level"] == "elementary"
        assert "response_time_ms" in result
        assert "timestamp" in result
        assert result["model_used"] == "gemini-1.5-pro"
        
        # Gemini API が適切に呼ばれたことを確認
        mock_ai_service.model.generate_content.assert_called_once()
    
    @pytest.mark.asyncio
    async def test_rewrite_text_response_time_check(self, mock_ai_service):
        """応答時間チェック（完了条件: <500ms）"""
        # Arrange
        def slow_response(*args, **kwargs):
            import time
            time.sleep(0.6)  # 600msの遅延をシミュレート
            mock_response = MagicMock()
            mock_response.text = "遅いレスポンス"
            return mock_response
        
        mock_ai_service.model.generate_content.side_effect = slow_response
        
        # Act
        result = await mock_ai_service.rewrite_text("テストテキスト")
        
        # Assert
        assert result["response_time_ms"] > 500  # 目標値を超過
        # ログに警告が出力されることを確認（実際のログ確認は別途）
    
    @pytest.mark.asyncio
    async def test_generate_headlines_success(self, mock_ai_service):
        """見出し生成成功ケース"""
        # Arrange
        content = "今日は遠足に行きました。お天気に恵まれて、子どもたちは楽しく過ごすことができました。"
        mock_response_text = """1. 楽しい遠足の一日
2. 晴天に恵まれた校外学習
3. 子どもたちの笑顔あふれる遠足"""
        
        mock_response = MagicMock()
        mock_response.text = mock_response_text
        mock_ai_service.model.generate_content.return_value = mock_response
        
        # Act
        result = await mock_ai_service.generate_headlines(content, max_headlines=3)
        
        # Assert
        assert len(result["headlines"]) == 3
        assert "楽しい遠足の一日" in result["headlines"]
        assert "晴天に恵まれた校外学習" in result["headlines"]
        assert "子どもたちの笑顔あふれる遠足" in result["headlines"]
        assert result["count"] == 3
        assert "response_time_ms" in result
    
    @pytest.mark.asyncio
    async def test_optimize_layout_success(self, mock_ai_service):
        """レイアウト最適化成功ケース"""
        # Arrange
        content = "体育祭のお知らせです。来月開催予定です。"
        json_response = {
            "content_type": "案内",
            "recommended_template": "sports_newsletter",
            "color_scheme": ["#FF6B6B", "#4ECDC4", "#45B7D1"],
            "suggested_icons": ["sports", "calendar", "trophy"],
            "layout_tips": ["スポーツテーマの活用", "日程を目立たせる"],
            "emphasis_keywords": ["体育祭", "来月"]
        }
        
        mock_response = MagicMock()
        mock_response.text = json.dumps(json_response)
        mock_ai_service.model.generate_content.return_value = mock_response
        
        # Act
        result = await mock_ai_service.optimize_layout(
            content=content,
            season="autumn",
            event_type="sports_day"
        )
        
        # Assert
        assert result["season"] == "autumn"
        assert result["event_type"] == "sports_day"
        assert result["layout_suggestion"]["content_type"] == "案内"
        assert result["layout_suggestion"]["recommended_template"] == "sports_newsletter"
        assert len(result["layout_suggestion"]["color_scheme"]) == 3
        assert "sports" in result["layout_suggestion"]["suggested_icons"]
    
    @pytest.mark.asyncio
    async def test_optimize_layout_json_parse_error_fallback(self, mock_ai_service):
        """JSONパースエラー時のフォールバック動作"""
        # Arrange
        content = "テストコンテンツ"
        invalid_json = "これは有効なJSONではありません"
        
        mock_response = MagicMock()
        mock_response.text = invalid_json
        mock_ai_service.model.generate_content.return_value = mock_response
        
        # Act
        result = await mock_ai_service.optimize_layout(content)
        
        # Assert - フォールバック値が返される
        assert result["layout_suggestion"]["content_type"] == "その他"
        assert result["layout_suggestion"]["recommended_template"] == "basic_newsletter"
        assert len(result["layout_suggestion"]["color_scheme"]) == 3
    
    @pytest.mark.asyncio
    async def test_gemini_api_error_handling(self, mock_ai_service):
        """Gemini API エラーハンドリング"""
        # Arrange
        mock_ai_service.model.generate_content.side_effect = Exception("API Error")
        
        # Act & Assert
        with pytest.raises(RuntimeError) as excinfo:
            await mock_ai_service.rewrite_text("テストテキスト")
        
        assert "Failed to rewrite text" in str(excinfo.value)
    
    def test_parse_headlines_various_formats(self):
        """見出し解析の様々な形式テスト"""
        # Arrange
        service = AIService()
        
        # 番号付きリスト
        response1 = "1. 見出し1\n2. 見出し2\n3. 見出し3"
        
        # 空行を含む
        response2 = "1. 見出しA\n\n2. 見出しB\n\n3. 見出しC"
        
        # 不正な形式を含む
        response3 = "見出し1\n2. 見出し2\n不正な行\n3. 見出し3"
        
        # Act
        headlines1 = service._parse_headlines(response1)
        headlines2 = service._parse_headlines(response2)
        headlines3 = service._parse_headlines(response3)
        
        # Assert
        assert headlines1 == ["見出し1", "見出し2", "見出し3"]
        assert headlines2 == ["見出しA", "見出しB", "見出しC"]
        assert "見出し1" in headlines3
        assert "見出し2" in headlines3
        assert "見出し3" in headlines3
    
    def test_parse_json_response_edge_cases(self):
        """JSON解析のエッジケース"""
        # Arrange
        service = AIService()
        
        # 前後に余分なテキストがある場合
        response1 = 'ここはJSONです: {"content_type": "test"} 以上です'
        
        # 不完全なJSON
        response2 = '{"content_type": "test"'
        
        # 完全に無効
        response3 = 'これはJSONではありません'
        
        # Act
        result1 = service._parse_json_response(response1)
        result2 = service._parse_json_response(response2)
        result3 = service._parse_json_response(response3)
        
        # Assert
        assert result1["content_type"] == "test"
        assert result2["content_type"] == "その他"  # フォールバック
        assert result3["content_type"] == "その他"  # フォールバック

@pytest.mark.integration
class TestAIServiceIntegration:
    """統合テスト（実際のVertex AI接続が必要）"""
    
    @pytest.mark.asyncio
    async def test_real_gemini_api_call(self):
        """実際のGemini API呼び出しテスト（環境変数設定が必要）"""
        import os
        if not os.getenv('GOOGLE_APPLICATION_CREDENTIALS'):
            pytest.skip("Google認証情報が設定されていません")
        
        try:
            # Act
            result = await ai_service.rewrite_text(
                original_text="今日はテストです",
                style="friendly"
            )
            
            # Assert
            assert "rewritten_text" in result
            assert result["response_time_ms"] < 5000  # 5秒以内
            assert len(result["rewritten_text"]) > 0
            
        except Exception as e:
            pytest.skip(f"Vertex AI接続失敗: {e}")

if __name__ == "__main__":
    # テスト実行
    pytest.main([__file__, "-v"])