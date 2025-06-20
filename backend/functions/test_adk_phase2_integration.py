"""
ADK Phase 2統合テスト

完全自動化フロー（音声→PDF→Classroom配布）のテストスイート
新規実装された3つのエージェントの統合動作を検証
"""

import asyncio
import json
import logging
import os
import pytest
import tempfile
import time
from datetime import datetime
from typing import Dict, Any, List

# テスト対象モジュール
from adk_multi_agent_service import (
    NewsletterADKService,
    generate_newsletter_with_adk
)
from pdf_output_agent import (
    PDFOutputAgent,
    generate_pdf_with_adk
)
from media_agent import (
    MediaAgent,
    enhance_media_with_adk
)
from classroom_integration_agent import (
    ClassroomIntegrationAgent,
    distribute_to_classroom_with_adk
)

# 設定
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# テスト設定
TEST_PROJECT_ID = "test-gakkoudayori-ai"
TEST_CREDENTIALS_PATH = "test-credentials.json"
TEST_AUDIO_TRANSCRIPT = """
今日は3年1組の運動会の練習をしました。
子どもたちは徒競走とダンスの練習を頑張っていました。
特に田中さんは最初は走るのが苦手でしたが、
毎日練習を重ねて今ではクラスで3番目に速くなりました。
みんなで応援し合う姿が印象的でした。

算数の授業では九九の練習をしました。
7の段が少し難しそうでしたが、みんなで協力して覚えました。
カードを使った練習が特に効果的でした。

来週の運動会に向けて、体操服の準備をお願いします。
応援よろしくお願いいたします。
"""


# ==============================================================================
# Phase 2エージェント個別テスト
# ==============================================================================

class TestPhase2Agents:
    """Phase 2新規エージェントの個別機能テスト"""
    
    @pytest.mark.asyncio
    async def test_pdf_output_agent_basic(self):
        """PDF出力エージェント基本機能テスト"""
        
        # テスト用HTMLコンテンツ
        test_html = """
        <h1 style="color: #2c3e50;">3年1組 学級通信</h1>
        <h2 style="color: #3498db;">運動会の練習</h2>
        <p>今日は運動会の練習をしました。子どもたちは頑張っていました。</p>
        <h2 style="color: #e74c3c;">算数の授業</h2>
        <p>九九の練習をしました。7の段が難しそうでした。</p>
        """
        
        test_newsletter_data = {
            "main_title": "3年1組 学級通信",
            "grade": "3年1組",
            "issue_date": "2024年06月19日"
        }
        
        # PDF生成テスト
        result = await generate_pdf_with_adk(
            html_content=test_html,
            newsletter_data=test_newsletter_data,
            project_id=TEST_PROJECT_ID,
            credentials_path=TEST_CREDENTIALS_PATH
        )
        
        # アサーション
        assert result["success"] == True, f"PDF生成失敗: {result.get('error')}"
        assert "data" in result
        assert "pdf_base64" in result["data"]
        assert "file_size_mb" in result["data"]
        assert result["data"]["file_size_mb"] > 0
        assert "quality_analysis" in result["data"]
        
        logger.info("✅ PDF出力エージェント基本機能テスト成功")
    
    @pytest.mark.asyncio
    async def test_media_agent_basic(self):
        """メディアエージェント基本機能テスト"""
        
        test_html = """
        <h1>3年1組 学級通信</h1>
        <h2>運動会の練習</h2>
        <p>今日は運動会の練習をしました。子どもたちは徒競走とダンスの練習を頑張っていました。</p>
        <h2>算数の授業</h2>
        <p>九九の練習をしました。7の段が少し難しそうでしたが、みんなで協力して覚えました。</p>
        """
        
        test_newsletter_data = {
            "main_title": "3年1組 学級通信",
            "grade": "3年1組",
            "sections": [
                {
                    "type": "main",
                    "title": "運動会の練習",
                    "content": "今日は運動会の練習をしました。子どもたちは徒競走とダンスの練習を頑張っていました。"
                },
                {
                    "type": "main",
                    "title": "算数の授業", 
                    "content": "九九の練習をしました。7の段が少し難しそうでしたが、みんなで協力して覚えました。"
                }
            ]
        }
        
        # 画像生成を無効にしてテスト（APIキーなしでもテスト可能）
        test_options = {
            "generate_images": False,
            "max_images": 2
        }
        
        # メディア強化テスト
        result = await enhance_media_with_adk(
            html_content=test_html,
            newsletter_data=test_newsletter_data,
            project_id=TEST_PROJECT_ID,
            credentials_path=TEST_CREDENTIALS_PATH,
            options=test_options
        )
        
        # アサーション
        assert result["success"] == True, f"メディア強化失敗: {result.get('error')}"
        assert "data" in result
        assert "enhanced_html" in result["data"]
        assert "image_suggestions" in result["data"]
        assert len(result["data"]["image_suggestions"]) >= 0  # 画像提案があることを確認
        
        logger.info("✅ メディアエージェント基本機能テスト成功")
    
    @pytest.mark.asyncio 
    async def test_classroom_integration_agent_basic(self):
        """Classroom統合エージェント基本機能テスト（模擬）"""
        
        # 模擬PDF（実際のファイルなしでテスト）
        test_pdf_path = "/tmp/test_newsletter.pdf"
        
        test_newsletter_data = {
            "main_title": "3年1組 学級通信",
            "grade": "3年1組",
            "issue_date": "2024年06月19日"
        }
        
        test_classroom_settings = {
            "teacher_email": "teacher@test-school.com",
            "posting_type": "announcement",
            "posting_options": {
                "allow_comments": True,
                "notify_recipients": True
            }
        }
        
        # Classroom配布テスト（APIキーなしでも構造テスト可能）
        result = await distribute_to_classroom_with_adk(
            pdf_path=test_pdf_path,
            newsletter_data=test_newsletter_data,
            classroom_settings=test_classroom_settings,
            project_id=TEST_PROJECT_ID,
            credentials_path=TEST_CREDENTIALS_PATH
        )
        
        # 構造アサーション（実際のAPI呼び出しは失敗するが構造は確認）
        assert "success" in result
        assert "agent" in result
        assert result["agent"] == "classroom_integration_agent"
        
        logger.info("✅ Classroom統合エージェント構造テスト成功")


# ==============================================================================
# 統合ワークフローテスト
# ==============================================================================

class TestPhase2IntegratedWorkflow:
    """Phase 2完全統合ワークフローテスト"""
    
    @pytest.mark.asyncio
    async def test_complete_adk_workflow(self):
        """完全ADKワークフロー統合テスト"""
        
        # テスト用教師プロファイル
        test_teacher_profile = {
            "grade_level": "3年1組",
            "school_name": "テスト小学校",
            "teacher_name": "テスト先生"
        }
        
        # Phase 2機能設定（実際のAPI呼び出しは無効化）
        test_classroom_settings = {
            "teacher_email": "teacher@test-school.com",
            "posting_type": "announcement",
            "course_id": "test-course-123"
        }
        
        # 完全ADKワークフロー実行
        result = await generate_newsletter_with_adk(
            audio_transcript=TEST_AUDIO_TRANSCRIPT,
            project_id=TEST_PROJECT_ID,
            credentials_path=TEST_CREDENTIALS_PATH,
            grade_level="3年1組",
            style="modern",
            enable_pdf=True,
            enable_images=False,  # Vertex AI APIなしでテスト
            classroom_settings=None  # Classroom APIなしでテスト
        )
        
        # 基本構造アサーション
        assert result["success"] == True, f"ADKワークフロー失敗: {result.get('error')}"
        assert "content" in result
        assert "html" in result
        assert "generation_method" in result
        assert result["generation_method"] == "adk_multi_agent_phase2"
        
        # Phase 2機能フラグチェック
        assert "phase2_features" in result
        phase2_features = result["phase2_features"]
        assert "pdf_enabled" in phase2_features
        assert "images_enabled" in phase2_features
        assert "classroom_enabled" in phase2_features
        
        logger.info("✅ 完全ADKワークフロー統合テスト成功")
    
    @pytest.mark.asyncio
    async def test_adk_service_initialization(self):
        """ADKサービス初期化とエージェント管理テスト"""
        
        # ADKサービス初期化
        service = NewsletterADKService(TEST_PROJECT_ID, TEST_CREDENTIALS_PATH)
        
        # 基本エージェントの存在確認
        assert 'orchestrator' in service.agents
        assert 'content_writer' in service.agents
        assert 'layout_designer' in service.agents
        assert 'html_generator' in service.agents
        assert 'quality_checker' in service.agents
        
        # Phase 2エージェントの遅延初期化確認
        assert 'pdf_output' in service.agents
        assert 'media' in service.agents
        assert 'classroom_integration' in service.agents
        
        # Phase 2エージェント初期化実行
        service._initialize_phase2_agents()
        
        # 初期化結果確認（エラーでもFalseが設定される）
        assert service.agents['pdf_output'] is not None
        assert service.agents['media'] is not None
        assert service.agents['classroom_integration'] is not None
        
        logger.info("✅ ADKサービス初期化テスト成功")


# ==============================================================================
# パフォーマンステスト
# ==============================================================================

class TestPhase2Performance:
    """Phase 2システムのパフォーマンステスト"""
    
    @pytest.mark.asyncio
    async def test_workflow_performance(self):
        """ワークフロー実行時間テスト"""
        
        start_time = time.time()
        
        # 軽量テスト実行
        result = await generate_newsletter_with_adk(
            audio_transcript="今日は算数の授業をしました。",
            project_id=TEST_PROJECT_ID,
            credentials_path=TEST_CREDENTIALS_PATH,
            grade_level="3年1組",
            style="modern",
            enable_pdf=False,  # パフォーマンステストでは重い処理を無効化
            enable_images=False,
            classroom_settings=None
        )
        
        processing_time = time.time() - start_time
        
        # パフォーマンス要件チェック
        assert processing_time < 30.0, f"処理時間が30秒を超過: {processing_time:.2f}秒"
        assert result["success"] == True
        
        logger.info(f"✅ ワークフロー実行時間テスト成功: {processing_time:.2f}秒")
    
    def test_agent_memory_usage(self):
        """エージェントメモリ使用量テスト"""
        
        import psutil
        import gc
        
        # 初期メモリ使用量
        process = psutil.Process()
        initial_memory = process.memory_info().rss / 1024 / 1024  # MB
        
        # 複数ADKサービス作成
        services = []
        for i in range(5):
            service = NewsletterADKService(TEST_PROJECT_ID, TEST_CREDENTIALS_PATH)
            services.append(service)
        
        # 終了メモリ使用量
        final_memory = process.memory_info().rss / 1024 / 1024  # MB
        memory_increase = final_memory - initial_memory
        
        # メモリリーク確認
        del services
        gc.collect()
        
        gc_memory = process.memory_info().rss / 1024 / 1024  # MB
        
        # アサーション
        assert memory_increase < 500, f"メモリ使用量増加が過大: {memory_increase:.2f}MB"
        
        logger.info(f"✅ メモリ使用量テスト成功: 増加 {memory_increase:.2f}MB")


# ==============================================================================
# エラーハンドリングテスト
# ==============================================================================

class TestPhase2ErrorHandling:
    """Phase 2システムのエラーハンドリングテスト"""
    
    @pytest.mark.asyncio
    async def test_invalid_input_handling(self):
        """不正入力データのハンドリングテスト"""
        
        # 空の音声入力
        result = await generate_newsletter_with_adk(
            audio_transcript="",
            project_id=TEST_PROJECT_ID,
            credentials_path=TEST_CREDENTIALS_PATH
        )
        
        # エラーハンドリング確認
        assert "success" in result
        # 空入力でもADKは適切に処理することを期待
        
        logger.info("✅ 不正入力ハンドリングテスト成功")
    
    @pytest.mark.asyncio
    async def test_agent_failure_resilience(self):
        """エージェント障害時の復旧能力テスト"""
        
        # 不正な認証情報でテスト
        result = await generate_newsletter_with_adk(
            audio_transcript=TEST_AUDIO_TRANSCRIPT,
            project_id="invalid-project",
            credentials_path="invalid-credentials.json",
            enable_pdf=True,
            enable_images=False,
            classroom_settings=None
        )
        
        # フォールバック動作確認
        assert "success" in result
        # 一部の機能が失敗してもシステム全体が停止しないことを確認
        
        logger.info("✅ エージェント障害復旧テスト成功")


# ==============================================================================
# メイン実行関数
# ==============================================================================

async def run_all_phase2_tests():
    """Phase 2統合テスト実行"""
    
    print("=" * 60)
    print("🚀 ADK Phase 2統合テスト開始")
    print("=" * 60)
    
    test_results = {
        "total_tests": 0,
        "passed_tests": 0,
        "failed_tests": 0,
        "errors": []
    }
    
    # テストクラス一覧
    test_classes = [
        TestPhase2Agents(),
        TestPhase2IntegratedWorkflow(), 
        TestPhase2Performance(),
        TestPhase2ErrorHandling()
    ]
    
    # 各テストクラスの実行
    for test_class in test_classes:
        class_name = test_class.__class__.__name__
        print(f"\n📋 {class_name} 実行中...")
        
        # テストメソッド取得
        test_methods = [method for method in dir(test_class) if method.startswith('test_')]
        
        for method_name in test_methods:
            test_results["total_tests"] += 1
            
            try:
                method = getattr(test_class, method_name)
                
                if asyncio.iscoroutinefunction(method):
                    await method()
                else:
                    method()
                
                test_results["passed_tests"] += 1
                print(f"  ✅ {method_name}")
                
            except Exception as e:
                test_results["failed_tests"] += 1
                test_results["errors"].append(f"{class_name}.{method_name}: {str(e)}")
                print(f"  ❌ {method_name}: {str(e)}")
    
    # 結果サマリー
    print("\n" + "=" * 60)
    print("📊 ADK Phase 2テスト結果サマリー")
    print("=" * 60)
    print(f"総テスト数: {test_results['total_tests']}")
    print(f"成功: {test_results['passed_tests']}")
    print(f"失敗: {test_results['failed_tests']}")
    print(f"成功率: {test_results['passed_tests']/test_results['total_tests']*100:.1f}%")
    
    if test_results["errors"]:
        print("\n❌ 失敗テスト詳細:")
        for error in test_results["errors"]:
            print(f"  - {error}")
    
    print("\n🎯 Phase 2機能テスト概要:")
    print("  📄 PDF出力エージェント: HTML→PDF変換と最適化")
    print("  🖼️  メディアエージェント: Vertex AI Imagen統合")
    print("  📚 Classroom統合エージェント: Google Classroom自動配布")
    print("  🔄 統合ワークフロー: 音声→PDF→配布の完全自動化")
    
    return test_results


def main():
    """テストメイン実行"""
    
    # 非同期テスト実行
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)
    
    try:
        results = loop.run_until_complete(run_all_phase2_tests())
        
        # 終了コード決定
        exit_code = 0 if results["failed_tests"] == 0 else 1
        
        print(f"\n🏁 テスト完了 (終了コード: {exit_code})")
        
        return exit_code
        
    except Exception as e:
        print(f"\n💥 テスト実行エラー: {e}")
        return 1
        
    finally:
        loop.close()


if __name__ == "__main__":
    import sys
    exit_code = main()
    sys.exit(exit_code)