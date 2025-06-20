#!/usr/bin/env python3
"""
公式ADK統合テスト

公式Google ADKフレームワークとの統合をテストし、
カスタムシミュレーション vs 公式ADK の動作を比較検証
"""

import asyncio
import json
import time
from datetime import datetime
from typing import Dict, Any

# 公式ADKサービスのテスト
async def test_official_adk_service():
    """公式ADKサービス単体テスト"""
    print("🔧 公式ADKサービス単体テスト開始")
    
    try:
        from adk_official_service import generate_newsletter_with_official_adk
        
        test_transcript = """
        今日は運動会の練習をしました。
        子どもたちは徒競走とダンスの練習を頑張っていました。
        特にたかしくんは最初は走るのが苦手でしたが、
        毎日練習を重ねて今ではクラスで3番目に速くなりました。
        みんなで応援し合う姿が印象的でした。
        """
        
        test_teacher_profile = {
            "name": "田中花子",
            "writing_style": "温かく親しみやすい",
            "grade": "3年1組"
        }
        
        start_time = time.time()
        result = await generate_newsletter_with_official_adk(
            audio_transcript=test_transcript,
            teacher_profile=test_teacher_profile,
            grade_level="3年1組"
        )
        processing_time = time.time() - start_time
        
        print(f"⏱️ 処理時間: {processing_time:.2f}秒")
        print(f"✅ 成功: {result.get('success', False)}")
        
        if result.get('success'):
            adk_metadata = result.get('adk_metadata', {})
            print(f"🤖 ADKバージョン: {adk_metadata.get('adk_version', 'N/A')}")
            print(f"📊 品質スコア: {adk_metadata.get('quality_score', 'N/A')}")
            print(f"🎯 エンゲージメントスコア: {adk_metadata.get('engagement_score', 'N/A')}")
            print(f"👥 使用エージェント数: {len(adk_metadata.get('agents_used', []))}")
            
            # 生成されたコンテンツの検証
            data = result.get('data', {})
            content = data.get('content', '')
            html = data.get('html', '')
            sections = data.get('sections', [])
            
            print(f"📝 コンテンツ長: {len(content)}文字")
            print(f"🏗️ HTML長: {len(html)}文字")
            print(f"📋 セクション数: {len(sections)}")
            
            return {
                "success": True,
                "processing_time": processing_time,
                "content_length": len(content),
                "html_length": len(html),
                "sections_count": len(sections),
                "quality_score": adk_metadata.get('quality_score', 0),
                "engagement_score": adk_metadata.get('engagement_score', 0)
            }
        else:
            print(f"❌ エラー: {result.get('error', 'Unknown error')}")
            return {"success": False, "error": result.get('error')}
            
    except Exception as e:
        print(f"❌ 例外発生: {e}")
        return {"success": False, "error": str(e)}


# 統合API経由テスト
def test_api_integration():
    """audio_to_json_service経由での統合テスト"""
    print("\n🔗 API統合テスト開始")
    
    try:
        from audio_to_json_service import convert_speech_to_json
        
        test_data = {
            "transcribed_text": "今日は晴れでした。子どもたちは元気に遊んでいました。運動会の練習も頑張っています。",
            "project_id": "test-project",
            "credentials_path": "test-credentials.json",
            "style": "classic",
            "use_adk": True,
            "teacher_profile": {
                "name": "田中先生",
                "writing_style": "温かく親しみやすい",
                "grade": "3年1組"
            }
        }
        
        start_time = time.time()
        result = convert_speech_to_json(**test_data)
        processing_time = time.time() - start_time
        
        print(f"⏱️ 処理時間: {processing_time:.2f}秒")
        print(f"✅ 成功: {result.get('success', False)}")
        
        if result.get('success'):
            data = result.get('data', {})
            adk_metadata = result.get('adk_metadata', {})
            
            print(f"📋 生成方法: {adk_metadata.get('generation_method', 'N/A')}")
            print(f"📝 セクション数: {len(data.get('sections', []))}")
            
            # セクション詳細
            sections = data.get('sections', [])
            if sections:
                print(f"🎯 セクションタイプ: {', '.join([s.get('type', 'unknown') for s in sections[:3]])}")
            
            return {
                "success": True,
                "processing_time": processing_time,
                "sections_count": len(sections),
                "generation_method": adk_metadata.get('generation_method'),
                "has_adk_metadata": bool(adk_metadata)
            }
        else:
            print(f"❌ エラー: {result.get('error', 'Unknown error')}")
            return {"success": False, "error": result.get('error')}
            
    except Exception as e:
        print(f"❌ 例外発生: {e}")
        return {"success": False, "error": str(e)}


# 機能比較テスト
async def test_adk_vs_traditional():
    """ADK vs 従来方式の比較テスト"""
    print("\n⚖️ ADK vs 従来方式比較テスト")
    
    try:
        from audio_to_json_service import convert_speech_to_json
        
        test_transcript = "今日は図書の時間がありました。みんな静かに読書していました。"
        
        # 従来方式テスト
        print("\n📚 従来方式テスト")
        start_time = time.time()
        traditional_result = convert_speech_to_json(
            transcribed_text=test_transcript,
            project_id="test-project",
            credentials_path="test-credentials.json",
            style="classic",
            use_adk=False
        )
        traditional_time = time.time() - start_time
        
        # ADK方式テスト  
        print("\n🤖 ADK方式テスト")
        start_time = time.time()
        adk_result = convert_speech_to_json(
            transcribed_text=test_transcript,
            project_id="test-project", 
            credentials_path="test-credentials.json",
            style="classic",
            use_adk=True,
            teacher_profile={"name": "田中先生", "grade": "3年1組"}
        )
        adk_time = time.time() - start_time
        
        # 結果比較
        print(f"\n📊 結果比較")
        print(f"従来方式: {traditional_time:.2f}秒, 成功: {traditional_result.get('success', False)}")
        print(f"ADK方式: {adk_time:.2f}秒, 成功: {adk_result.get('success', False)}")
        
        if traditional_result.get('success') and adk_result.get('success'):
            trad_sections = len(traditional_result.get('data', {}).get('sections', []))
            adk_sections = len(adk_result.get('data', {}).get('sections', []))
            
            print(f"セクション数比較: 従来 {trad_sections} vs ADK {adk_sections}")
            
            # ADKメタデータの確認
            adk_metadata = adk_result.get('adk_metadata', {})
            if adk_metadata:
                print(f"🤖 ADKメタデータあり: 品質スコア {adk_metadata.get('quality_score', 'N/A')}")
            else:
                print(f"⚠️ ADKメタデータなし（フォールバック処理された可能性）")
        
        return {
            "traditional": {
                "success": traditional_result.get('success', False),
                "time": traditional_time,
                "sections": len(traditional_result.get('data', {}).get('sections', []))
            },
            "adk": {
                "success": adk_result.get('success', False),
                "time": adk_time,
                "sections": len(adk_result.get('data', {}).get('sections', [])),
                "has_metadata": bool(adk_result.get('adk_metadata'))
            }
        }
        
    except Exception as e:
        print(f"❌ 比較テスト例外: {e}")
        return {"error": str(e)}


# 公式ADKインポートテスト
def test_adk_imports():
    """公式ADKパッケージのインポートテスト"""
    print("\n📦 公式ADKインポートテスト")
    
    try:
        # 基本インポート
        from google.adk.agents import LlmAgent, SequentialAgent, ParallelAgent
        print("✅ 基本エージェントクラス: 正常インポート")
        
        from google.adk.tools import FunctionTool, BaseTool
        print("✅ ツールクラス: 正常インポート")
        
        # バージョン確認
        import google.adk
        if hasattr(google.adk, '__version__'):
            print(f"📋 ADKバージョン: {google.adk.__version__}")
        else:
            print("📋 ADKバージョン: 不明")
        
        return {"success": True, "adk_available": True}
        
    except ImportError as e:
        print(f"❌ インポートエラー: {e}")
        return {"success": False, "adk_available": False, "error": str(e)}
    except Exception as e:
        print(f"❌ その他エラー: {e}")
        return {"success": False, "error": str(e)}


# メイン統合テスト関数
async def run_comprehensive_adk_test():
    """総合ADKテスト実行"""
    print("🚀 公式Google ADK統合テスト開始")
    print("=" * 60)
    
    results = {}
    
    # 1. インポートテスト
    print("📦 Phase 1: パッケージインポートテスト")
    results["imports"] = test_adk_imports()
    
    # 2. 公式ADKサービステスト
    print("\n🔧 Phase 2: 公式ADKサービステスト")
    results["official_adk"] = await test_official_adk_service()
    
    # 3. API統合テスト
    print("\n🔗 Phase 3: API統合テスト")
    results["api_integration"] = test_api_integration()
    
    # 4. 比較テスト
    print("\n⚖️ Phase 4: ADK vs 従来方式比較")
    results["comparison"] = await test_adk_vs_traditional()
    
    # 総合結果
    print("\n" + "=" * 60)
    print("📊 総合テスト結果")
    print("-" * 40)
    
    success_count = sum(1 for result in results.values() 
                       if isinstance(result, dict) and result.get('success', False))
    total_tests = len(results)
    
    print(f"🎯 成功率: {success_count}/{total_tests} ({success_count/total_tests*100:.1f}%)")
    
    for test_name, result in results.items():
        status = "✅" if (isinstance(result, dict) and result.get('success', False)) else "❌"
        print(f"  {status} {test_name}")
    
    # 推奨事項
    print(f"\n📋 推奨事項:")
    if results["imports"]["success"]:
        print("  ✅ Google ADK正常インストール済み")
    else:
        print("  ⚠️ Google ADK要再インストール: pip install google-adk")
    
    if results["official_adk"]["success"]:
        print("  ✅ 公式ADKサービス動作中")
    else:
        print("  ⚠️ 公式ADKサービスはフォールバック機能で動作")
    
    return results


if __name__ == "__main__":
    # 統合テスト実行
    results = asyncio.run(run_comprehensive_adk_test())