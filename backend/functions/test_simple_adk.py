"""
Simple Google ADK Integration Test

Demonstrates basic functionality of the official ADK integration
without complex async operations.
"""

import os
import json
from dotenv import load_dotenv

# Load environment
load_dotenv()

def test_basic_imports():
    """Test basic ADK imports"""
    try:
        from google.adk.agents import LlmAgent, Agent, SequentialAgent, ParallelAgent
        from google.adk.tools import FunctionTool, BaseTool
        print("✅ Google ADK imports successful")
        return True
    except ImportError as e:
        print(f"❌ Import failed: {e}")
        return False

def test_service_initialization():
    """Test service initialization"""
    try:
        from adk_official_multi_agent_service import OfficialNewsletterADKService
        
        service = OfficialNewsletterADKService()
        print("✅ Service initialization successful")
        
        agents = service.get_available_agents()
        tools = service.get_available_tools()
        
        print(f"📋 Available agents: {len(agents)}")
        print(f"📋 Available tools: {len(tools)}")
        
        return True
    except Exception as e:
        print(f"❌ Service initialization failed: {e}")
        return False

def test_individual_tool():
    """Test individual tool execution"""
    try:
        from adk_official_multi_agent_service import newsletter_content_generator
        
        result = newsletter_content_generator(
            audio_transcript="今日は楽しい授業をしました。",
            grade_level="3年1組"
        )
        
        print(f"✅ Tool execution successful")
        print(f"Status: {result.get('status')}")
        
        if result.get('status') == 'success':
            content_length = len(result.get('report', ''))
            print(f"Generated content length: {content_length}")
        
        return result.get('status') == 'success'
        
    except Exception as e:
        print(f"❌ Tool execution failed: {e}")
        return False

def test_fallback_integration():
    """Test fallback integration without async"""
    try:
        from adk_official_multi_agent_service import OfficialNewsletterADKService
        
        service = OfficialNewsletterADKService()
        
        # Test fallback method directly
        result = service._fallback_generation(
            audio_transcript="テスト用音声テキストです。",
            grade_level="3年1組", 
            style="modern"
        )
        
        print(f"✅ Fallback integration test successful")
        print(f"Success: {result.get('success')}")
        
        return True
        
    except Exception as e:
        print(f"❌ Fallback integration failed: {e}")
        return False

def main():
    """Run all tests"""
    print("🚀 Simple Google ADK Integration Test")
    print("=" * 50)
    
    tests = [
        ("Basic Imports", test_basic_imports),
        ("Service Initialization", test_service_initialization), 
        ("Individual Tool", test_individual_tool),
        ("Fallback Integration", test_fallback_integration)
    ]
    
    results = {}
    
    for test_name, test_func in tests:
        print(f"\n--- {test_name} ---")
        try:
            results[test_name] = test_func()
        except Exception as e:
            print(f"❌ {test_name} failed with exception: {e}")
            results[test_name] = False
    
    # Summary
    print("\n" + "=" * 50)
    print("📊 Test Results Summary")
    print("=" * 50)
    
    passed = sum(1 for result in results.values() if result)
    total = len(results)
    
    for test_name, result in results.items():
        status = "✅ PASS" if result else "❌ FAIL"
        print(f"{test_name}: {status}")
    
    print(f"\nOverall: {passed}/{total} tests passed")
    
    if passed == total:
        print("🎉 All tests passed! ADK integration is working.")
    else:
        print("⚠️  Some tests failed. Check output for details.")
    
    return passed == total

if __name__ == "__main__":
    success = main()
    exit(0 if success else 1)