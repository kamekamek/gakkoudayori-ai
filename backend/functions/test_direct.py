#!/usr/bin/env python3
"""
直接APIテスト
"""

import requests
import json
import time

# テスト用URL
BASE_URL = "http://localhost:8081"
API_ENDPOINT = f"{BASE_URL}/api/v1/ai/speech-to-json"

def test_simple():
    """シンプルなテスト"""
    print("🧪 シンプルAPIテスト開始")
    
    data = {
        "transcribed_text": "今日は晴れでした。",
        "style": "classic",
        "use_adk": False
    }
    
    try:
        print(f"📡 送信先: {API_ENDPOINT}")
        print(f"📋 送信データ: {json.dumps(data, ensure_ascii=False)}")
        
        response = requests.post(API_ENDPOINT, json=data, timeout=30)
        
        print(f"📊 ステータスコード: {response.status_code}")
        print(f"📄 レスポンスヘッダー: {dict(response.headers)}")
        
        if response.status_code == 200:
            result = response.json()
            print(f"✅ 成功!")
            print(f"📝 レスポンス概要:")
            print(f"   - success: {result.get('success')}")
            if result.get('data'):
                print(f"   - セクション数: {len(result['data'].get('sections', []))}")
            return True
        else:
            print(f"❌ エラー応答:")
            print(f"   {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ 例外発生: {e}")
        return False

def test_adk():
    """ADKテスト"""
    print("\n🤖 ADKテスト開始")
    
    data = {
        "transcribed_text": "今日は運動会の練習をしました。子どもたちは徒競走とダンスの練習を頑張っていました。",
        "style": "classic", 
        "use_adk": True,
        "teacher_profile": {
            "name": "田中先生",
            "writing_style": "温かく親しみやすい",
            "grade": "3年1組"
        }
    }
    
    try:
        print(f"📡 送信先: {API_ENDPOINT}")
        print(f"📋 ADK使用: True")
        
        start_time = time.time()
        response = requests.post(API_ENDPOINT, json=data, timeout=60)
        processing_time = time.time() - start_time
        
        print(f"📊 ステータスコード: {response.status_code}")
        print(f"⏱️ 処理時間: {processing_time:.2f}秒")
        
        if response.status_code == 200:
            result = response.json()
            print(f"✅ 成功!")
            print(f"📝 レスポンス概要:")
            print(f"   - success: {result.get('success')}")
            
            # ADKメタデータの確認
            adk_metadata = result.get('adk_metadata')
            if adk_metadata:
                print(f"   - ADKメタデータ: あり")
                print(f"   - エンゲージメントスコア: {adk_metadata.get('engagement_score', 'N/A')}")
            else:
                print(f"   - ADKメタデータ: なし（フォールバックの可能性）")
                
            return True
        else:
            print(f"❌ エラー応答:")
            print(f"   {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ 例外発生: {e}")
        return False

if __name__ == "__main__":
    print("🔍 直接APIテスト開始")
    print("=" * 40)
    
    # 1. シンプルテスト
    simple_result = test_simple()
    
    # 2. ADKテスト  
    adk_result = test_adk()
    
    # 3. 結果
    print("\n" + "=" * 40)
    print("📊 テスト結果:")
    print(f"   シンプルテスト: {'✅' if simple_result else '❌'}")
    print(f"   ADKテスト: {'✅' if adk_result else '❌'}")
    
    if simple_result and adk_result:
        print("🎉 全テスト成功！")
    elif simple_result:
        print("⚠️  基本機能は動作、ADKに問題")
    else:
        print("❌ 基本機能に問題あり")