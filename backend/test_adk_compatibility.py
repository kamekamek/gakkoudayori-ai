#!/usr/bin/env python3
"""
ADK v1.0.0 互換性テストスクリプト

このスクリプトは以下をテストします：
1. エージェントの正しい初期化
2. root_agent変数の存在
3. SequentialAgentの正しいパラメータ
4. InvocationContextの利用可能なメソッド
5. アーティファクト管理の動作
"""

import sys
import traceback
from pathlib import Path

def test_imports():
    """基本的なインポートをテストします。"""
    print("🔍 インポートテスト...")
    try:
        from google.adk.agents import LlmAgent, SequentialAgent
        from google.adk.agents.invocation_context import InvocationContext
        from google.adk.models.google_llm import Gemini
        from google.adk.tools import FunctionTool
        print("✅ 基本インポート成功")
        return True
    except Exception as e:
        print(f"❌ インポートエラー: {e}")
        return False

def test_sequential_agent_signature():
    """SequentialAgentの正しいパラメータ仕様をテストします。"""
    print("🔍 SequentialAgent署名テスト...")
    try:
        from google.adk.agents import SequentialAgent
        
        # 利用可能なフィールドを確認
        fields = SequentialAgent.model_fields.keys()
        print(f"  利用可能フィールド: {list(fields)}")
        
        # 必須フィールドを確認
        required_fields = ['sub_agents']
        for field in required_fields:
            if field not in fields:
                print(f"❌ 必須フィールド '{field}' が見つかりません")
                return False
        
        print("✅ SequentialAgent署名確認成功")
        return True
    except Exception as e:
        print(f"❌ SequentialAgent署名エラー: {e}")
        return False

def test_invocation_context_methods():
    """InvocationContextで利用可能なメソッドをテストします。"""
    print("🔍 InvocationContextメソッドテスト...")
    try:
        from google.adk.agents.invocation_context import InvocationContext
        
        # 利用可能なメソッドを確認
        methods = [attr for attr in dir(InvocationContext) if not attr.startswith('_')]
        print(f"  利用可能メソッド: {methods}")
        
        # 廃止されたメソッドをチェック
        deprecated_methods = ['artifact_exists', 'save_artifact', 'load_artifact']
        found_deprecated = []
        for method in deprecated_methods:
            if method in methods:
                found_deprecated.append(method)
        
        if found_deprecated:
            print(f"⚠️  廃止予定メソッドが見つかりました: {found_deprecated}")
        else:
            print("✅ 廃止メソッドは見つかりませんでした（期待通り）")
        
        return True
    except Exception as e:
        print(f"❌ InvocationContextメソッドエラー: {e}")
        return False

def test_agent_loading():
    """各エージェントの読み込みをテストします。"""
    print("🔍 エージェント読み込みテスト...")
    
    agents_to_test = [
        'orchestrator_agent',
        'planner_agent', 
        'generator_agent'
    ]
    
    results = {}
    
    # agents ディレクトリをPythonパスに追加
    agents_dir = Path.cwd() / "agents"
    if str(agents_dir) not in sys.path:
        sys.path.insert(0, str(agents_dir))
    
    for agent_name in agents_to_test:
        try:
            # エージェントモジュールをインポート
            module = __import__(f"{agent_name}.agent", fromlist=[''])
            
            # root_agent変数の存在確認
            if hasattr(module, 'root_agent'):
                print(f"✅ {agent_name}: root_agent変数が存在")
                results[agent_name] = True
            else:
                print(f"❌ {agent_name}: root_agent変数が見つかりません")
                results[agent_name] = False
                
        except Exception as e:
            print(f"❌ {agent_name}: インポートエラー - {e}")
            results[agent_name] = False
    
    return all(results.values())

def test_orchestrator_creation():
    """OrchestratorAgentの作成をテストします。"""
    print("🔍 OrchestratorAgent作成テスト...")
    try:
        # agents ディレクトリをPythonパスに追加
        agents_dir = Path.cwd() / "agents"
        if str(agents_dir) not in sys.path:
            sys.path.insert(0, str(agents_dir))
            
        from orchestrator_agent.agent import create_orchestrator_agent
        
        agent = create_orchestrator_agent()
        print(f"✅ OrchestratorAgent作成成功: {type(agent)}")
        
        # sub_agentsの存在確認
        if hasattr(agent, 'sub_agents'):
            print(f"  サブエージェント数: {len(agent.sub_agents)}")
            for i, sub_agent in enumerate(agent.sub_agents):
                print(f"  - {i}: {sub_agent.name} ({type(sub_agent).__name__})")
        
        return True
    except Exception as e:
        print(f"❌ OrchestratorAgent作成エラー: {e}")
        traceback.print_exc()
        return False

def test_artifact_directory():
    """アーティファクトディレクトリの作成をテストします。"""
    print("🔍 アーティファクトディレクトリテスト...")
    try:
        artifacts_dir = Path("/tmp/adk_artifacts")
        artifacts_dir.mkdir(exist_ok=True)
        
        if artifacts_dir.exists() and artifacts_dir.is_dir():
            print(f"✅ アーティファクトディレクトリ作成成功: {artifacts_dir}")
            return True
        else:
            print(f"❌ アーティファクトディレクトリ作成失敗: {artifacts_dir}")
            return False
    except Exception as e:
        print(f"❌ アーティファクトディレクトリエラー: {e}")
        return False

def main():
    """メインテスト実行関数"""
    print("🚀 ADK v1.0.0 互換性テスト開始")
    print("=" * 50)
    
    tests = [
        ("インポート", test_imports),
        ("SequentialAgent署名", test_sequential_agent_signature),
        ("InvocationContextメソッド", test_invocation_context_methods),
        ("エージェント読み込み", test_agent_loading),
        ("OrchestratorAgent作成", test_orchestrator_creation),
        ("アーティファクトディレクトリ", test_artifact_directory),
    ]
    
    results = {}
    
    for test_name, test_func in tests:
        print(f"\n📋 {test_name}テスト:")
        try:
            results[test_name] = test_func()
        except Exception as e:
            print(f"❌ {test_name}テストで予期しないエラー: {e}")
            results[test_name] = False
    
    print("\n" + "=" * 50)
    print("📊 テスト結果サマリー:")
    
    passed = 0
    total = len(tests)
    
    for test_name, result in results.items():
        status = "✅ PASS" if result else "❌ FAIL"
        print(f"  {status} {test_name}")
        if result:
            passed += 1
    
    print(f"\n🎯 総合結果: {passed}/{total} テスト通過")
    
    if passed == total:
        print("🎉 すべてのテストが通過しました！")
        return 0
    else:
        print("⚠️  いくつかのテストが失敗しました。上記のエラーを確認してください。")
        return 1

if __name__ == "__main__":
    sys.exit(main()) 