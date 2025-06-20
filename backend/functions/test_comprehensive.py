#!/usr/bin/env python3
"""
総合動作確認テスト
"""

import requests
import json
import time
from datetime import datetime

BASE_URL = "http://localhost:8081"
API_ENDPOINT = f"{BASE_URL}/api/v1/ai/speech-to-json"

def run_comprehensive_test():
    """総合テスト実行"""
    print("🚀 ADK マルチエージェントシステム総合動作確認")
    print(f"⏰ 実行時刻: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 60)
    
    results = []
    
    # テストケース1: 従来システム（短い文章）
    test1_data = {
        "transcribed_text": "今日は晴れでした。",
        "style": "classic",
        "use_adk": False
    }
    
    print("📝 テスト1: 従来システム（短い文章）")
    result1 = send_request(test1_data, "従来システム")
    results.append(("従来システム(短)", result1))
    
    # テストケース2: 従来システム（中程度の文章）
    test2_data = {
        "transcribed_text": "今日は運動会の練習をしました。子どもたちは徒競走とダンスの練習を頑張っていました。",
        "style": "classic", 
        "use_adk": False
    }
    
    print("\n📝 テスト2: 従来システム（中程度の文章）")
    result2 = send_request(test2_data, "従来システム")
    results.append(("従来システム(中)", result2))
    
    # テストケース3: ADKシステム（複雑な文章）
    test3_data = {
        "transcribed_text": "今日は運動会の練習をしました。子どもたちは徒競走とダンスの練習を頑張っていました。特にたかしくんは最初は走るのが苦手でしたが、毎日練習を重ねて今ではクラスで3番目に速くなりました。きれいなレイアウトで見やすくデザインして、写真も入れて保護者の方に共有したいと思います。",
        "style": "classic",
        "use_adk": True,
        "teacher_profile": {
            "name": "田中花子",
            "writing_style": "温かく親しみやすい",
            "grade": "3年1組"
        }
    }
    
    print("\n📝 テスト3: ADKシステム（複雑な文章）")
    result3 = send_request(test3_data, "ADKシステム")
    results.append(("ADKシステム", result3))
    
    # 結果まとめ
    print("\n" + "=" * 60)
    print("📊 総合テスト結果")
    print("-" * 40)
    
    total_tests = len(results)
    passed_tests = sum(1 for _, result in results if result["success"])
    
    for test_name, result in results:
        status = "✅" if result["success"] else "❌"
        time_str = f"{result['time']:.2f}s" if result["success"] else "失敗"
        sections = len(result.get("sections", [])) if result["success"] else 0
        
        print(f"  {status} {test_name}: {time_str} ({sections}セクション)")
    
    print(f"\n📈 成功率: {passed_tests}/{total_tests} ({passed_tests/total_tests*100:.1f}%)")
    
    if passed_tests == total_tests:
        print("🎉 全テスト成功！ADKシステムは正常に動作しています。")
    elif passed_tests >= 2:
        print("⚠️  大部分のテストが成功。一部機能に問題があります。")
    else:
        print("❌ 多数のテスト失敗。システム設定を確認してください。")
    
    return results

def send_request(data, system_name):
    """APIリクエスト送信"""
    try:
        start_time = time.time()
        response = requests.post(API_ENDPOINT, json=data, timeout=90)
        processing_time = time.time() - start_time
        
        if response.status_code == 200:
            result = response.json()
            if result.get("success"):
                sections = result.get("data", {}).get("sections", [])
                adk_metadata = result.get("adk_metadata")
                
                print(f"  ✅ 成功: {processing_time:.2f}秒")
                print(f"  📝 セクション数: {len(sections)}")
                
                if adk_metadata:
                    print(f"  🚀 ADKメタデータ: あり")
                    if "engagement_score" in adk_metadata:
                        print(f"  📊 エンゲージメントスコア: {adk_metadata['engagement_score']}")
                else:
                    print(f"  📋 標準レスポンス")
                
                return {
                    "success": True,
                    "time": processing_time,
                    "sections": sections,
                    "adk_metadata": adk_metadata
                }
            else:
                print(f"  ❌ API失敗: {result.get('error', 'Unknown error')}")
                return {"success": False, "error": result.get("error")}
        else:
            print(f"  ❌ HTTP失敗: {response.status_code}")
            return {"success": False, "error": f"HTTP {response.status_code}"}
            
    except Exception as e:
        print(f"  ❌ 例外: {e}")
        return {"success": False, "error": str(e)}

if __name__ == "__main__":
    run_comprehensive_test()