"""
公式Google ADK統合テスト

実際の公式ADKフレームワークを使用したマルチエージェントシステムの
統合テストを実行します。
"""

import asyncio
import json
import logging
import os
import sys
from datetime import datetime
from typing import Dict, Any

# ログ設定
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def test_adk_availability():
    """ADK可用性テスト"""
    print("=== ADK Availability Test ===")
    
    try:
        from google.adk.agents import LlmAgent, Agent, SequentialAgent, ParallelAgent
        from google.adk.tools import FunctionTool, BaseTool
        print("✅ Google ADK successfully imported")
        return True
    except ImportError as e:
        print(f"❌ Google ADK import failed: {e}")
        print("💡 Install with: pip install google-adk")
        return False

def test_environment_setup():
    """環境設定テスト"""
    print("\n=== Environment Setup Test ===")
    
    required_env_vars = [
        'GOOGLE_CLOUD_PROJECT',
        'GOOGLE_CLOUD_LOCATION'
    ]
    
    missing_vars = []
    for var in required_env_vars:
        value = os.getenv(var)
        if value:
            print(f"✅ {var}: {value}")
        else:
            print(f"❌ {var}: Not set")
            missing_vars.append(var)
    
    # Optional authentication check
    auth_method = os.getenv('GOOGLE_GENAI_USE_VERTEXAI', 'TRUE')
    print(f"📋 Authentication method: {'Vertex AI' if auth_method == 'TRUE' else 'Google AI Studio'}")
    
    if missing_vars:
        print(f"⚠️  Missing environment variables: {missing_vars}")
        print("💡 Create .env file with required variables")
        return False
    
    return True

async def test_official_adk_service():
    """公式ADKサービステスト"""
    print("\n=== Official ADK Service Test ===")
    
    try:
        from adk_official_multi_agent_service import (
            OfficialNewsletterADKService,
            generate_newsletter_with_official_adk
        )
        
        print("✅ Official ADK service imported successfully")
        
        # サービスインスタンス作成テスト
        service = OfficialNewsletterADKService()
        print(f"✅ Service instance created")
        
        # 利用可能エージェント確認
        available_agents = service.get_available_agents()
        print(f"📋 Available agents: {available_agents}")
        
        # 利用可能ツール確認
        available_tools = service.get_available_tools()
        print(f"📋 Available tools: {available_tools}")
        
        return True
        
    except ImportError as e:
        print(f"❌ Official ADK service import failed: {e}")
        return False
    except Exception as e:
        print(f"❌ Official ADK service test failed: {e}")
        return False

async def test_individual_tools():
    """個別ツールテスト"""
    print("\n=== Individual Tools Test ===")
    
    try:
        from adk_official_multi_agent_service import (
            newsletter_content_generator,
            design_specification_generator,
            html_content_generator,
            html_quality_checker
        )
        
        test_transcript = "今日は運動会の練習をしました。子どもたちは徒競走とダンスの練習を頑張っていました。"
        
        # 1. コンテンツ生成ツールテスト
        print("Testing newsletter_content_generator...")
        content_result = newsletter_content_generator(
            audio_transcript=test_transcript,
            grade_level="3年1組"
        )
        print(f"Content generation status: {content_result.get('status', 'unknown')}")
        if content_result.get('status') == 'success':
            print(f"Content length: {len(content_result.get('report', ''))}")
        
        # 2. デザイン仕様生成ツールテスト
        print("Testing design_specification_generator...")
        design_result = design_specification_generator(
            content=content_result.get('report', ''),
            grade_level="3年1組"
        )
        print(f"Design generation status: {design_result.get('status', 'unknown')}")
        
        # 3. HTML生成ツールテスト
        print("Testing html_content_generator...")
        html_result = html_content_generator(
            content=content_result.get('report', ''),
            design_spec_json=design_result.get('report', '{}')
        )
        print(f"HTML generation status: {html_result.get('status', 'unknown')}")
        if html_result.get('status') == 'success':
            print(f"HTML length: {len(html_result.get('report', ''))}")
        
        # 4. 品質チェックツールテスト
        print("Testing html_quality_checker...")
        quality_result = html_quality_checker(
            html_content=html_result.get('report', ''),
            original_content=content_result.get('report', '')
        )
        print(f"Quality check status: {quality_result.get('status', 'unknown')}")
        
        return all(result.get('status') == 'success' for result in [
            content_result, design_result, html_result, quality_result
        ])
        
    except Exception as e:
        print(f"❌ Individual tools test failed: {e}")
        return False

async def test_full_integration():
    """完全統合テスト"""
    print("\n=== Full Integration Test ===")
    
    try:
        from adk_official_multi_agent_service import generate_newsletter_with_official_adk
        
        test_transcript = """
        今日は運動会の練習をしました。
        子どもたちは徒競走とダンスの練習を頑張っていました。
        特にたかしくんは最初は走るのが苦手でしたが、
        毎日練習を重ねて今ではクラスで3番目に速くなりました。
        みんなで応援し合う姿が印象的でした。
        また、ダンスでは新しい振り付けを覚えるのに苦労していましたが、
        みんなで教え合いながら楽しく練習できています。
        """
        
        print("Starting full ADK multi-agent generation...")
        start_time = datetime.now()
        
        result = await generate_newsletter_with_official_adk(
            audio_transcript=test_transcript,
            grade_level="3年1組",
            style="modern"
        )
        
        end_time = datetime.now()
        processing_time = (end_time - start_time).total_seconds()
        
        print(f"✅ Generation completed in {processing_time:.2f} seconds")
        print(f"Success: {result.get('success', False)}")
        print(f"Generation method: {result.get('generation_method', 'unknown')}")
        
        if result.get('success'):
            agents_executed = result.get('agents_executed', [])
            print(f"Agents executed: {agents_executed}")
            
            # 各フェーズの結果確認
            phases = ['content_generation', 'design_generation', 'html_generation', 'quality_check']
            for phase in phases:
                phase_result = result.get(phase, {})
                status = phase_result.get('status', 'unknown')
                print(f"  {phase}: {status}")
            
            # 最終HTML確認
            final_html = result.get('final_html')
            if final_html:
                print(f"Final HTML length: {len(final_html)}")
                print("✅ HTML generation successful")
            else:
                print("⚠️  No final HTML generated")
        
        return result.get('success', False)
        
    except Exception as e:
        print(f"❌ Full integration test failed: {e}")
        import traceback
        print(f"Traceback: {traceback.format_exc()}")
        return False

async def test_api_integration():
    """API統合テスト"""
    print("\n=== API Integration Test ===")
    
    try:
        from audio_to_json_service import convert_speech_to_json
        
        test_transcript = "今日は図画工作の時間に、みんなで秋の葉っぱを使った作品作りをしました。"
        
        print("Testing API integration with use_adk=True...")
        
        result = convert_speech_to_json(
            transcribed_text=test_transcript,
            project_id=os.getenv('GOOGLE_CLOUD_PROJECT', 'test-project'),
            credentials_path=os.getenv('GOOGLE_APPLICATION_CREDENTIALS'),
            style='modern',
            use_adk=True,
            teacher_profile={'grade_level': '3年1組'}
        )
        
        print(f"API integration success: {result.get('success', False)}")
        
        if result.get('success'):
            adk_metadata = result.get('adk_metadata', {})
            print(f"Generation method: {adk_metadata.get('generation_method', 'unknown')}")
            print(f"Agents executed: {adk_metadata.get('agents_executed', [])}")
            
            # データ形式確認
            data = result.get('data', {})
            required_keys = ['school_name', 'grade', 'sections', 'visual_elements']
            missing_keys = [key for key in required_keys if key not in data]
            
            if missing_keys:
                print(f"⚠️  Missing required keys in data: {missing_keys}")
            else:
                print("✅ All required data keys present")
                print(f"Sections count: {len(data.get('sections', []))}")
                print(f"HTML available: {bool(data.get('generated_html'))}")
        
        return result.get('success', False)
        
    except Exception as e:
        print(f"❌ API integration test failed: {e}")
        import traceback
        print(f"Traceback: {traceback.format_exc()}")
        return False

async def run_all_tests():
    """全テスト実行"""
    print("🚀 Starting Official Google ADK Integration Tests")
    print("=" * 60)
    
    test_results = {}
    
    # 1. ADK可用性テスト
    test_results['adk_availability'] = test_adk_availability()
    
    # 2. 環境設定テスト
    test_results['environment_setup'] = test_environment_setup()
    
    # ADKが利用可能でない場合は残りのテストをスキップ
    if not test_results['adk_availability']:
        print("\n❌ ADK not available, skipping remaining tests")
        print("💡 Install ADK with: pip install google-adk")
        return test_results
    
    # 3. ADKサービステスト
    test_results['adk_service'] = await test_official_adk_service()
    
    # 4. 個別ツールテスト
    test_results['individual_tools'] = await test_individual_tools()
    
    # 5. 完全統合テスト
    test_results['full_integration'] = await test_full_integration()
    
    # 6. API統合テスト
    test_results['api_integration'] = await test_api_integration()
    
    # 結果サマリー
    print("\n" + "=" * 60)
    print("📊 Test Results Summary")
    print("=" * 60)
    
    total_tests = len(test_results)
    passed_tests = sum(1 for result in test_results.values() if result)
    
    for test_name, result in test_results.items():
        status = "✅ PASS" if result else "❌ FAIL"
        print(f"{test_name}: {status}")
    
    print(f"\nOverall: {passed_tests}/{total_tests} tests passed")
    
    if passed_tests == total_tests:
        print("🎉 All tests passed! Official ADK integration is working correctly.")
    else:
        print("⚠️  Some tests failed. Check the output above for details.")
    
    return test_results

if __name__ == "__main__":
    print("Official Google ADK Integration Test Suite")
    print("==========================================")
    
    # 環境変数の読み込み
    from dotenv import load_dotenv
    load_dotenv()
    
    # テスト実行
    results = asyncio.run(run_all_tests())
    
    # 終了コード設定
    all_passed = all(results.values())
    sys.exit(0 if all_passed else 1)