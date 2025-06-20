#!/usr/bin/env python3
"""
ADK API動作確認スクリプト

ローカルサーバーに対してAPIテストを実行
"""

import requests
import json
import time
import sys
from datetime import datetime

# テスト用URL
BASE_URL = "http://localhost:8081"
API_ENDPOINT = f"{BASE_URL}/api/v1/ai/speech-to-json"

def test_server_health():
    """サーバーの稼働確認"""
    try:
        response = requests.get(f"{BASE_URL}/api/v1/health")
        if response.status_code == 200:
            print("✅ サーバー稼働確認 OK")
            return True
        else:
            print(f"❌ サーバー応答エラー: {response.status_code}")
            return False
    except requests.exceptions.ConnectionError:
        print("❌ サーバーに接続できません。start_server.pyが起動していますか？")
        return False
    except Exception as e:
        print(f"❌ サーバー確認エラー: {e}")
        return False

def test_traditional_system():
    """従来システムのテスト"""
    print("\n🔍 従来システム（単一Gemini）テスト開始")
    
    data = {
        "transcribed_text": "今日は朝の会でみんな元気に挨拶ができました。算数の授業では九九の練習をしました。",
        "style": "classic",
        "use_adk": False
    }
    
    try:
        start_time = time.time()
        response = requests.post(API_ENDPOINT, json=data, timeout=60)
        processing_time = time.time() - start_time
        
        print(f"  📊 処理時間: {processing_time:.2f}秒")
        print(f"  📋 ステータスコード: {response.status_code}")
        
        if response.status_code == 200:
            result = response.json()
            print(f"  ✅ 成功: {result.get('success', False)}")
            
            if result.get('success'):
                data_info = result.get('data', {})
                print(f"  📝 セクション数: {len(data_info.get('sections', []))}")
                print(f"  🎨 カラースキーム: {bool(data_info.get('color_scheme'))}")
                return True, processing_time, result
            else:
                print(f"  ❌ API処理失敗: {result.get('error', 'Unknown error')}")
                return False, processing_time, result
        else:
            print(f"  ❌ HTTPエラー: {response.text}")
            return False, processing_time, None
            
    except requests.exceptions.Timeout:
        print("  ❌ タイムアウト（60秒）")
        return False, 60, None
    except Exception as e:
        print(f"  ❌ リクエストエラー: {e}")
        return False, 0, None

def test_adk_system():
    """ADKシステムのテスト"""
    print("\n🤖 ADKマルチエージェントシステムテスト開始")
    
    data = {
        "transcribed_text": "今日は運動会の練習をしました。子どもたちは徒競走とダンスの練習を頑張っていました。特にたかしくんは最初は走るのが苦手でしたが、毎日練習を重ねて今ではクラスで3番目に速くなりました。きれいなレイアウトで見やすくデザインして、写真も入れて保護者の方に共有したいと思います。",
        "style": "classic",
        "use_adk": True,
        "teacher_profile": {
            "name": "田中花子",
            "writing_style": "温かく親しみやすい",
            "grade": "3年1組"
        }
    }
    
    try:
        start_time = time.time()
        response = requests.post(API_ENDPOINT, json=data, timeout=120)
        processing_time = time.time() - start_time
        
        print(f"  📊 処理時間: {processing_time:.2f}秒")
        print(f"  📋 ステータスコード: {response.status_code}")
        
        if response.status_code == 200:
            result = response.json()
            print(f"  ✅ 成功: {result.get('success', False)}")
            
            if result.get('success'):
                data_info = result.get('data', {})
                adk_metadata = result.get('adk_metadata', {})
                
                print(f"  📝 セクション数: {len(data_info.get('sections', []))}")
                print(f"  🎨 カラースキーム: {bool(data_info.get('color_scheme'))}")
                
                if adk_metadata:
                    print(f"  🚀 エンゲージメントスコア: {adk_metadata.get('engagement_score', 'N/A')}")
                    processing_times = adk_metadata.get('processing_times', {})
                    if processing_times:
                        print(f"  ⏱️ エージェント処理時間: {processing_times}")
                
                return True, processing_time, result
            else:
                print(f"  ❌ API処理失敗: {result.get('error', 'Unknown error')}")
                return False, processing_time, result
        else:
            print(f"  ❌ HTTPエラー: {response.text}")
            return False, processing_time, None
            
    except requests.exceptions.Timeout:
        print("  ❌ タイムアウト（120秒）")
        return False, 120, None
    except Exception as e:
        print(f"  ❌ リクエストエラー: {e}")
        return False, 0, None

def test_simple_json():
    """シンプルなJSONテスト（エラー再現用）"""
    print("\n🧪 シンプルJSONテスト（curlエラー再現確認）")
    
    # シンプルなテストデータ
    simple_data = {
        "transcribed_text": "今日は晴れでした。",
        "style": "classic",
        "use_adk": False
    }
    
    try:
        response = requests.post(API_ENDPOINT, json=simple_data, timeout=30)
        print(f"  📋 ステータスコード: {response.status_code}")
        
        if response.status_code == 200:
            result = response.json()
            print(f"  ✅ シンプルテスト成功: {result.get('success', False)}")
            return True
        else:
            print(f"  ❌ シンプルテストエラー: {response.text}")
            return False
    except Exception as e:
        print(f"  ❌ シンプルテストエラー: {e}")
        return False

def print_comparison(traditional_result, adk_result):
    """比較結果表示"""
    print("\n📊 システム比較結果")
    print("-" * 50)
    
    trad_success, trad_time, trad_data = traditional_result
    adk_success, adk_time, adk_data = adk_result
    
    print(f"従来システム:")
    print(f"  処理時間: {trad_time:.2f}秒")
    print(f"  成功率: {'✅' if trad_success else '❌'}")
    
    print(f"ADKマルチエージェント:")
    print(f"  処理時間: {adk_time:.2f}秒") 
    print(f"  成功率: {'✅' if adk_success else '❌'}")
    
    if trad_time > 0:
        efficiency = ((trad_time - adk_time) / trad_time * 100)
        print(f"  時間効率: {efficiency:+.1f}%")

def main():
    """メインテスト実行"""
    print("🚀 ADK マルチエージェントシステム動作確認開始")
    print(f"⏰ 実行時刻: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 60)
    
    # 1. サーバー稼働確認
    if not test_server_health():
        print("\n❌ サーバーが起動していません。以下を実行してください：")
        print("   python start_server.py")
        sys.exit(1)
    
    # 2. シンプルテスト
    simple_ok = test_simple_json()
    
    # 3. 従来システムテスト
    traditional_result = test_traditional_system()
    
    # 4. ADKシステムテスト
    adk_result = test_adk_system()
    
    # 5. 結果比較
    print_comparison(traditional_result, adk_result)
    
    # 6. 総合評価
    print("\n" + "=" * 60)
    print("🎯 テスト完了")
    
    all_tests = [simple_ok, traditional_result[0], adk_result[0]]
    passed_tests = sum(all_tests)
    
    print(f"📈 成功率: {passed_tests}/3 テスト")
    
    if passed_tests == 3:
        print("✨ 全テスト成功！ADKシステムは正常に動作しています。")
    elif passed_tests >= 2:
        print("⚠️  一部テスト失敗。ログを確認してください。")
    else:
        print("❌ 多数のテストが失敗しました。設定を確認してください。")

if __name__ == "__main__":
    main()