#!/usr/bin/env python3
"""
uvで管理された環境でのADKテスト
"""
import sys
print(f'Python path: {sys.executable}')
print(f'Python version: {sys.version}')
print()

try:
    # Google ADKのインポートテスト
    import google.adk
    print(f'✅ Google ADK {google.adk.__version__} imported successfully')
    
    # エージェントのテスト
    from agents.conversation_agent.agent import create_conversation_agent
    from agents.layout_agent.agent import create_layout_agent
    
    conversation_agent = create_conversation_agent()
    layout_agent = create_layout_agent()
    
    print('✅ Conversation agent created successfully')
    print('✅ Layout agent created successfully')
    
    # サンプルJSON生成テスト
    sample_json = conversation_agent._generate_sample_json()
    import json
    parsed = json.loads(sample_json)
    
    print('✅ Sample JSON generation successful')
    print(f'   Schema version: {parsed.get("schema_version")}')
    print(f'   Issue date: {parsed.get("issue_date")}')
    
    print()
    print('🎉 uv migration successful! All ADK agents working correctly.')
    
except Exception as e:
    print(f'❌ Test failed: {e}')
    import traceback
    traceback.print_exc()