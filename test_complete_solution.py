#!/usr/bin/env python3
"""
Complete solution test for 学校だよりAI
Tests the full text input → AI generation workflow
"""

import sys
import os
import time
import subprocess
import requests
import json
from threading import Thread

def start_backend():
    """Start the backend server"""
    print("🚀 Starting backend server...")
    os.chdir('/Users/kamenonagare/gakkoudayori-ai/backend/functions')
    
    # Add current directory to Python path
    sys.path.insert(0, os.getcwd())
    
    try:
        from main import app
        app.run(host='0.0.0.0', port=8081, debug=False)
    except Exception as e:
        print(f"❌ Backend failed to start: {e}")

def test_backend_api():
    """Test the backend API endpoints"""
    api_base = 'http://localhost:8081/api/v1/ai'
    
    print("🧪 Testing backend API...")
    
    # Wait for backend to start
    for i in range(30):
        try:
            response = requests.get(f"{api_base}/health", timeout=2)
            print(f"✅ Backend is running! Status: {response.status_code}")
            break
        except requests.exceptions.ConnectionError:
            if i == 29:
                print("❌ Backend not responding after 30 seconds")
                return False
            print(f"⏳ Waiting for backend... ({i+1}/30)")
            time.sleep(1)
    
    # Test speech-to-json endpoint
    print("\n📝 Testing speech-to-json endpoint...")
    test_data = {
        "transcribed_text": "今日は運動会でした。子どもたちは最後まで頑張りました。",
        "custom_context": "style:classic"
    }
    
    try:
        response = requests.post(
            f"{api_base}/speech-to-json",
            json=test_data,
            headers={'Content-Type': 'application/json'},
            timeout=30
        )
        
        print(f"  Status: {response.status_code}")
        if response.status_code == 200:
            data = response.json()
            print(f"  Success: {data.get('success', False)}")
            if data.get('success'):
                print("  ✅ Speech-to-JSON API working!")
                
                # Test json-to-graphical-record endpoint
                print("\n🎨 Testing json-to-graphical-record endpoint...")
                html_data = {
                    "json_data": data['data'],
                    "template": "classic_newsletter",
                    "custom_style": "newsletter_optimized_for_print"
                }
                
                html_response = requests.post(
                    f"{api_base}/json-to-graphical-record",
                    json=html_data,
                    headers={'Content-Type': 'application/json'},
                    timeout=30
                )
                
                print(f"  Status: {html_response.status_code}")
                if html_response.status_code == 200:
                    html_result = html_response.json()
                    print(f"  Success: {html_result.get('success', False)}")
                    if html_result.get('success'):
                        print("  ✅ Complete workflow API working!")
                        return True
                
            else:
                print(f"  ❌ API returned error: {data.get('error', 'Unknown error')}")
        else:
            print(f"  ❌ API request failed: {response.text}")
    
    except Exception as e:
        print(f"  ❌ API test failed: {e}")
    
    return False

def start_flutter():
    """Start Flutter web development server"""
    print("\n🖥️ Starting Flutter web server...")
    os.chdir('/Users/kamenonagare/gakkoudayori-ai/frontend')
    
    cmd = [
        'flutter', 'run', '-d', 'chrome',
        '--web-port=8080',
        '--dart-define=ENVIRONMENT=development',
        '--dart-define=API_BASE_URL=http://localhost:8081/api/v1/ai'
    ]
    
    try:
        process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        print("✅ Flutter server starting...")
        return process
    except Exception as e:
        print(f"❌ Flutter failed to start: {e}")
        return None

def run_e2e_test():
    """Run the E2E test"""
    print("\n🧪 Running E2E test...")
    os.chdir('/Users/kamenonagare/gakkoudayori-ai/frontend')
    
    # Wait for Flutter to be ready
    time.sleep(20)
    
    cmd = ['npx', 'playwright', 'test', 'e2e/tests/fixed-workflow-test.spec.js', 
           '--grep', '正確な座標でのフルワークフロー実行', '--timeout', '120000']
    
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=180)
        print(f"Test exit code: {result.returncode}")
        print("STDOUT:", result.stdout)
        if result.stderr:
            print("STDERR:", result.stderr)
        return result.returncode == 0
    except Exception as e:
        print(f"❌ E2E test failed: {e}")
        return False

def main():
    print("🎯 Complete Solution Test for 学校だよりAI")
    print("=" * 50)
    
    # Start backend in a separate thread
    backend_thread = Thread(target=start_backend, daemon=True)
    backend_thread.start()
    
    # Test backend API
    if not test_backend_api():
        print("\n❌ Backend API test failed. Cannot proceed.")
        sys.exit(1)
    
    # Start Flutter
    flutter_process = start_flutter()
    if not flutter_process:
        print("\n❌ Flutter failed to start. Cannot proceed.")
        sys.exit(1)
    
    # Run E2E test
    test_success = run_e2e_test()
    
    # Results
    print("\n" + "=" * 50)
    print("📊 FINAL RESULTS:")
    print(f"  Backend API: ✅ Working")
    print(f"  Flutter Web: ✅ Started")
    print(f"  E2E Test: {'✅ PASSED' if test_success else '❌ FAILED'}")
    
    if test_success:
        print("\n🎉 SUCCESS: Text input → AI generation workflow is working!")
        print("✅ User's request completed: 全然音声がなくても文章入力でもAI生成できる")
    else:
        print("\n⚠️ E2E test failed, but APIs are working. Check frontend integration.")
    
    # Clean up
    if flutter_process:
        flutter_process.terminate()
    
    return test_success

if __name__ == "__main__":
    main()