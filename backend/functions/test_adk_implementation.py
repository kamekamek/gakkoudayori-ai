"""
ADK実装のテストスイート

TDD要件に従ったテストコード:
- Red: まずテストを書いて失敗させる
- Green: 最小限のコードでテストを通す  
- Refactor: コード品質を向上
"""

import pytest
import asyncio
from unittest.mock import Mock, patch, AsyncMock
from datetime import datetime

from ai_service_interface import (
    AIConfig, 
    AIServiceFactory, 
    HybridAIService, 
    ContentRequest, 
    ContentResult
)
from vertex_ai_service import VertexAIService
from adk_multi_agent_service import ADKMultiAgentService, ADKAgent


class TestAIServiceInterface:
    """AIサービスインターフェースのテスト"""
    
    def test_ai_config_creation(self):
        """AI設定作成テスト"""
        config = AIConfig(
            provider="vertex_ai",
            model_name="gemini-1.5-flash",
            project_id="test-project",
            credentials_path="/path/to/creds.json"
        )
        
        assert config.provider == "vertex_ai"
        assert config.model_name == "gemini-1.5-flash"
        assert config.project_id == "test-project"
        assert config.multi_agent_enabled == False
    
    def test_ai_config_adk_creation(self):
        """ADK設定作成テスト"""
        config = AIConfig(
            provider="adk_multi_agent",
            model_name="gemini-1.5-flash",
            project_id="test-project",
            multi_agent_enabled=True
        )
        
        assert config.provider == "adk_multi_agent"
        assert config.multi_agent_enabled == True
    
    def test_content_request_creation(self):
        """コンテンツリクエスト作成テスト"""
        request = ContentRequest(
            text="今日は運動会の練習をしました",
            template_type="daily_report",
            include_greeting=True,
            target_audience="parents",
            season="autumn"
        )
        
        assert request["text"] == "今日は運動会の練習をしました"
        assert request["template_type"] == "daily_report"
        assert request["include_greeting"] == True


class TestAIServiceFactory:
    """AIサービスファクトリーのテスト"""
    
    def test_create_vertex_ai_service(self):
        """Vertex AIサービス作成テスト"""
        config = AIConfig(
            provider="vertex_ai",
            project_id="test-project"
        )
        
        service = AIServiceFactory.create_service(config)
        assert isinstance(service, VertexAIService)
    
    def test_create_adk_service(self):
        """ADKサービス作成テスト"""
        config = AIConfig(
            provider="adk_multi_agent",
            project_id="test-project"
        )
        
        service = AIServiceFactory.create_service(config)
        assert isinstance(service, ADKMultiAgentService)
    
    def test_invalid_provider_raises_error(self):
        """無効なプロバイダーでエラーテスト"""
        config = AIConfig(
            provider="invalid_provider",
            project_id="test-project"
        )
        
        with pytest.raises(ValueError) as excinfo:
            AIServiceFactory.create_service(config)
        
        assert "Unsupported AI provider" in str(excinfo.value)


class TestVertexAIService:
    """Vertex AIサービスのテスト"""
    
    def setup_method(self):
        """テストセットアップ"""
        self.config = AIConfig(
            provider="vertex_ai",
            project_id="test-project",
            credentials_path="test-creds.json"
        )
        self.service = VertexAIService(self.config)
    
    @patch('vertex_ai_service.generate_newsletter_from_speech')
    @pytest.mark.asyncio
    async def test_generate_newsletter_success(self, mock_generate):
        """学級通信生成成功テスト"""
        # モックレスポンス設定
        mock_generate.return_value = {
            "success": True,
            "data": {
                "newsletter_html": "<h1>テスト通信</h1>",
                "original_speech": "テスト音声",
                "template_type": "daily_report",
                "season": "autumn",
                "processing_time_ms": 1500,
                "generated_at": "2024-01-01T10:00:00",
                "word_count": 10,
                "character_count": 50
            }
        }
        
        request = ContentRequest(
            text="今日は運動会の練習をしました",
            template_type="daily_report",
            include_greeting=True,
            target_audience="parents",
            season="autumn"
        )
        
        result = await self.service.generate_newsletter(request)
        
        assert result["success"] == True
        assert result["data"]["newsletter_html"] == "<h1>テスト通信</h1>"
        assert len(result["processing_phases"]) == 1
        assert result["processing_phases"][0]["agent_name"] == "gemini_single_model"
    
    @patch('vertex_ai_service.generate_newsletter_from_speech')
    @pytest.mark.asyncio
    async def test_generate_newsletter_failure(self, mock_generate):
        """学級通信生成失敗テスト"""
        # モックエラーレスポンス設定
        mock_generate.return_value = {
            "success": False,
            "error": "API接続エラー",
            "processing_time_ms": 100
        }
        
        request = ContentRequest(
            text="テスト",
            template_type="daily_report",
            include_greeting=True,
            target_audience="parents",
            season="autumn"
        )
        
        result = await self.service.generate_newsletter(request)
        
        assert result["success"] == False
        assert result["error"]["code"] == "VERTEX_AI_ERROR"
        assert "API接続エラー" in result["error"]["message"]
    
    def test_get_service_info(self):
        """サービス情報取得テスト"""
        info = self.service.get_service_info()
        
        assert info["provider"] == "vertex_ai"
        assert info["model_name"] == "gemini-1.5-flash"
        assert info["capabilities"]["multi_agent"] == False
        assert "available_templates" in info


class TestADKMultiAgentService:
    """ADKマルチエージェントサービスのテスト"""
    
    def setup_method(self):
        """テストセットアップ"""
        self.config = AIConfig(
            provider="adk_multi_agent",
            project_id="test-project",
            multi_agent_enabled=True
        )
        self.service = ADKMultiAgentService(self.config)
    
    def test_agents_initialization(self):
        """エージェント初期化テスト"""
        assert "ContentAnalyzer" in self.service.agents
        assert "StyleWriter" in self.service.agents
        assert "LayoutDesigner" in self.service.agents
        assert "FactChecker" in self.service.agents
        assert "EngagementOptimizer" in self.service.agents
        
        # 各エージェントが正しいタイプであることを確認
        assert isinstance(self.service.agents["ContentAnalyzer"], ADKAgent)
    
    def test_processing_pipeline_setup(self):
        """処理パイプライン設定テスト"""
        expected_phases = [
            "content_analysis",
            "style_writing", 
            "layout_design",
            "fact_checking",
            "engagement_optimization"
        ]
        
        actual_phases = [phase for phase, _ in self.service.processing_pipeline]
        assert actual_phases == expected_phases
    
    @patch.object(ADKAgent, 'process')
    @pytest.mark.asyncio
    async def test_generate_newsletter_success(self, mock_process):
        """マルチエージェント学級通信生成成功テスト"""
        # 各エージェントの処理結果をモック
        mock_process.side_effect = [
            {  # ContentAnalyzer
                "success": True,
                "output_text": "分析済みコンテンツ",
                "processing_time_ms": 500
            },
            {  # StyleWriter
                "success": True,
                "output_text": "教師らしい文体のコンテンツ",
                "processing_time_ms": 600
            },
            {  # LayoutDesigner
                "success": True,
                "output_text": "<h1>美しいHTMLレイアウト</h1>",
                "processing_time_ms": 400
            },
            {  # FactChecker
                "success": True,
                "output_text": "<h1>事実確認済みHTML</h1>",
                "processing_time_ms": 300
            },
            {  # EngagementOptimizer
                "success": True,
                "output_text": "<h1>最適化済み学級通信</h1>",
                "processing_time_ms": 700
            }
        ]
        
        request = ContentRequest(
            text="今日は運動会の練習をしました",
            template_type="daily_report",
            include_greeting=True,
            target_audience="parents",
            season="autumn"
        )
        
        result = await self.service.generate_newsletter(request)
        
        assert result["success"] == True
        assert result["data"]["newsletter_html"] == "<h1>最適化済み学級通信</h1>"
        assert result["data"]["ai_metadata"]["multi_agent"] == True
        assert len(result["processing_phases"]) == 5
        
        # 各フェーズが正しく記録されているか確認
        phase_names = [phase["phase"] for phase in result["processing_phases"]]
        assert "content_analysis" in phase_names
        assert "engagement_optimization" in phase_names
    
    @patch.object(ADKAgent, 'process')
    @pytest.mark.asyncio
    async def test_generate_newsletter_failure_in_middle(self, mock_process):
        """中間エージェントでの失敗テスト"""
        # StyleWriterで失敗するケース
        mock_process.side_effect = [
            {  # ContentAnalyzer - 成功
                "success": True,
                "output_text": "分析済みコンテンツ",
                "processing_time_ms": 500
            },
            {  # StyleWriter - 失敗
                "success": False,
                "error": "文体変換に失敗",
                "processing_time_ms": 200
            }
        ]
        
        request = ContentRequest(
            text="テスト",
            template_type="daily_report",
            include_greeting=True,
            target_audience="parents",
            season="autumn"
        )
        
        result = await self.service.generate_newsletter(request)
        
        assert result["success"] == False
        assert result["error"]["code"] == "ADK_PHASE_ERROR"
        assert "style_writing" in result["error"]["message"]
        assert len(result["processing_phases"]) == 2  # 2つのフェーズまで実行された
    
    def test_get_service_info(self):
        """ADKサービス情報取得テスト"""
        info = self.service.get_service_info()
        
        assert info["provider"] == "adk_multi_agent"
        assert info["capabilities"]["multi_agent"] == True
        assert info["capabilities"]["specialized_agents"] == True
        assert len(info["agents"]) == 5
        assert len(info["processing_pipeline"]) == 5


class TestHybridAIService:
    """ハイブリッドAIサービスのテスト"""
    
    def setup_method(self):
        """テストセットアップ"""
        vertex_config = AIConfig(provider="vertex_ai", project_id="test")
        adk_config = AIConfig(provider="adk_multi_agent", project_id="test")
        
        # モックサービスを作成
        self.mock_vertex_service = Mock()
        self.mock_adk_service = Mock()
        
        with patch('ai_service_interface.AIServiceFactory.create_service') as mock_factory:
            mock_factory.side_effect = [self.mock_vertex_service, self.mock_adk_service]
            self.hybrid_service = HybridAIService(vertex_config, adk_config)
    
    def test_complexity_score_calculation(self):
        """複雑さスコア計算テスト"""
        # 簡単なリクエスト
        simple_request = ContentRequest(
            text="今日は楽しかった",
            template_type="daily_report",
            include_greeting=True,
            target_audience="parents",
            season="autumn"
        )
        
        score = self.hybrid_service._calculate_complexity_score(simple_request)
        assert score < 0.7  # 閾値未満
        
        # 複雑なリクエスト
        complex_request = ContentRequest(
            text="今日は運動会の準備をしました。" * 20 + "保護者会も開催されます。",  # 長いテキスト
            template_type="event_report",  # 複雑なテンプレート
            include_greeting=True,
            target_audience="parents",
            season="autumn",
            context=[{"role": "user", "content": "前回の話"}]  # コンテキストあり
        )
        
        score = self.hybrid_service._calculate_complexity_score(complex_request)
        assert score >= 0.7  # 閾値以上
    
    @pytest.mark.asyncio
    async def test_route_to_vertex_ai_for_simple_request(self):
        """簡単なリクエストでVertex AI使用テスト"""
        self.mock_vertex_service.generate_newsletter = AsyncMock(return_value={
            "success": True,
            "data": {"newsletter_html": "シンプル通信"}
        })
        
        simple_request = ContentRequest(
            text="短いテキスト",
            template_type="daily_report",
            include_greeting=True,
            target_audience="parents",
            season="autumn"
        )
        
        await self.hybrid_service.generate_newsletter(simple_request)
        
        # Vertex AIが呼ばれたことを確認
        self.mock_vertex_service.generate_newsletter.assert_called_once()
        self.mock_adk_service.generate_newsletter.assert_not_called()
    
    @pytest.mark.asyncio
    async def test_route_to_adk_for_complex_request(self):
        """複雑なリクエストでADK使用テスト"""
        self.mock_adk_service.generate_newsletter = AsyncMock(return_value={
            "success": True,
            "data": {"newsletter_html": "複雑な通信"}
        })
        
        complex_request = ContentRequest(
            text="今日は運動会の準備をしました。" * 30,  # 長いテキスト
            template_type="event_report",
            include_greeting=True,
            target_audience="parents",
            season="autumn"
        )
        
        await self.hybrid_service.generate_newsletter(complex_request)
        
        # ADKが呼ばれたことを確認
        self.mock_adk_service.generate_newsletter.assert_called_once()
        self.mock_vertex_service.generate_newsletter.assert_not_called()


# エンドツーエンドテスト
class TestADKIntegration:
    """ADK統合テスト"""
    
    @pytest.mark.integration
    @pytest.mark.asyncio
    async def test_full_newsletter_generation_pipeline(self):
        """フル学級通信生成パイプラインテスト"""
        # 実際のサービスを使った統合テスト
        # 注意: このテストは実際のGemini APIを呼び出すため、
        # 環境変数やモックが適切に設定されている必要があります
        
        config = AIConfig(
            provider="adk_multi_agent",
            project_id="test-project",
            credentials_path="test-creds.json"
        )
        
        # 実際にはモックを使用してAPIコールをシミュレート
        with patch('adk_multi_agent_service.ADKAgent._call_gemini_api') as mock_api:
            mock_api.return_value = {
                "success": True,
                "data": {
                    "text": "モック生成コンテンツ",
                    "ai_metadata": {"processing_time_ms": 1000}
                }
            }
            
            service = ADKMultiAgentService(config)
            
            request = ContentRequest(
                text="今日は運動会の練習をしました。子どもたちはとても頑張っていました。",
                template_type="daily_report",
                include_greeting=True,
                target_audience="parents",
                season="autumn"
            )
            
            result = await service.generate_newsletter(request)
            
            assert result["success"] == True
            assert "newsletter_html" in result["data"]
            assert len(result["processing_phases"]) == 5
            
            # 各エージェントが呼ばれたことを確認
            assert mock_api.call_count == 5


if __name__ == "__main__":
    # テスト実行
    pytest.main([__file__, "-v"])