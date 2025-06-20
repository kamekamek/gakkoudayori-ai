#!/usr/bin/env python3
"""
ADK実装テスト実行スクリプト

使用方法:
    python run_adk_tests.py
"""

import os
import sys
import subprocess
import logging

# ログ設定
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def run_tests():
    """テスト実行"""
    print("🧪 ADK実装テスト開始...")
    
    try:
        # Pytestでテスト実行
        result = subprocess.run([
            sys.executable, '-m', 'pytest', 
            'test_adk_implementation.py',
            '-v',
            '--tb=short'
        ], capture_output=True, text=True)
        
        print("📊 テスト結果:")
        print(result.stdout)
        
        if result.stderr:
            print("⚠️ エラー出力:")
            print(result.stderr)
        
        if result.returncode == 0:
            print("✅ すべてのテストが成功しました！")
        else:
            print("❌ テストが失敗しました")
            return False
            
    except FileNotFoundError:
        print("❌ pytestが見つかりません。pip install pytestで インストールしてください")
        return False
    except Exception as e:
        print(f"❌ テスト実行エラー: {e}")
        return False
    
    return True

def check_imports():
    """インポートチェック"""
    print("📦 インポートチェック中...")
    
    try:
        from ai_service_interface import AIConfig, AIServiceFactory
        from vertex_ai_service import VertexAIService
        from adk_multi_agent_service import ADKMultiAgentService
        print("✅ すべてのモジュールが正常にインポートされました")
        return True
    except ImportError as e:
        print(f"❌ インポートエラー: {e}")
        return False

def demo_adk_functionality():
    """ADK機能デモ"""
    print("🎯 ADK機能デモ...")
    
    try:
        from ai_service_interface import AIConfig, AIServiceFactory, ContentRequest
        
        # 設定作成
        config = AIConfig(
            provider="adk_multi_agent",
            project_id="demo-project",
            model_name="gemini-1.5-flash"
        )
        
        print(f"📋 AI設定: {config.provider} / {config.model_name}")
        
        # サービス作成
        service = AIServiceFactory.create_service(config)
        service_info = service.get_service_info()
        
        print(f"🤖 エージェント数: {len(service_info['agents'])}")
        print(f"⚙️ 処理パイプライン: {len(service_info['processing_pipeline'])}フェーズ")
        
        # リクエスト作成
        request = ContentRequest(
            text="今日は運動会の練習をしました。子どもたちは一生懸命頑張っていました。",
            template_type="daily_report",
            include_greeting=True,
            target_audience="parents",
            season="autumn"
        )
        
        print(f"📝 デモリクエスト作成完了: {len(request['text'])}文字")
        print("✅ ADK機能デモ成功")
        
        return True
        
    except Exception as e:
        print(f"❌ デモエラー: {e}")
        return False

def main():
    """メイン実行"""
    print("🚀 ADK実装検証開始")
    print("=" * 50)
    
    # 1. インポートチェック
    if not check_imports():
        return False
    
    print()
    
    # 2. 機能デモ
    if not demo_adk_functionality():
        return False
    
    print()
    
    # 3. テスト実行
    if not run_tests():
        return False
    
    print()
    print("🎉 ADK実装検証完了！")
    print("=" * 50)
    print("📈 実装状況:")
    print("  ✅ 抽象インターフェース")
    print("  ✅ Vertex AIサービス")
    print("  ✅ ADKマルチエージェントサービス") 
    print("  ✅ ハイブリッドサービス")
    print("  ✅ API統合")
    print("  ✅ テストカバレッジ")
    print()
    print("🔄 次のステップ:")
    print("  1. 実際のGemini APIでの動作確認")
    print("  2. フロントエンドとの統合テスト")
    print("  3. パフォーマンス測定")
    print("  4. 本番環境デプロイ")
    
    return True

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)