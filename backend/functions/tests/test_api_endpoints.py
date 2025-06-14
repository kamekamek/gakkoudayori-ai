#!/usr/bin/env python3
"""
音声認識API エンドポイントテスト

Flask アプリケーションの音声認識エンドポイントをテスト
"""

import requests
import io
import json
from speech_recognition_service import create_test_audio_content

def test_transcribe_endpoint():
    """音声文字起こしエンドポイントテスト"""
    print("=== 音声文字起こしエンドポイントテスト ===")
    
    # テスト用音声データ
    audio_content = create_test_audio_content()
    
    # Flaskアプリをローカルで起動している場合のURL
    url = "http://localhost:8080/api/v1/ai/transcribe"
    
    try:
        # ファイルアップロード形式でPOSTリクエスト
        files = {
            'audio_file': ('test_audio.wav', io.BytesIO(audio_content), 'audio/wav')
        }
        data = {
            'language': 'ja-JP',
            'user_dictionary': '運動会,学習発表会,子どもたち'
        }
        
        print("音声ファイルをアップロード中...")
        response = requests.post(url, files=files, data=data, timeout=30)
        
        print(f"ステータスコード: {response.status_code}")
        print(f"レスポンス:")
        print(json.dumps(response.json(), indent=2, ensure_ascii=False))
        
        if response.status_code == 200:
            print("✅ 音声文字起こしエンドポイント正常動作")
        else:
            print("❌ 音声文字起こしエンドポイントエラー")
            
    except requests.exceptions.ConnectionError:
        print("❌ サーバーに接続できません。Flask アプリが起動していることを確認してください。")
        print("   起動コマンド: python main.py")
    except Exception as e:
        print(f"❌ テストエラー: {e}")

def test_formats_endpoint():
    """音声フォーマット情報エンドポイントテスト"""
    print("\n=== 音声フォーマット情報エンドポイントテスト ===")
    
    url = "http://localhost:8080/api/v1/ai/formats"
    
    try:
        response = requests.get(url, timeout=10)
        
        print(f"ステータスコード: {response.status_code}")
        print(f"レスポンス:")
        print(json.dumps(response.json(), indent=2, ensure_ascii=False))
        
        if response.status_code == 200:
            print("✅ フォーマット情報エンドポイント正常動作")
        else:
            print("❌ フォーマット情報エンドポイントエラー")
            
    except requests.exceptions.ConnectionError:
        print("❌ サーバーに接続できません。")
    except Exception as e:
        print(f"❌ テストエラー: {e}")

def test_health_endpoint():
    """ヘルスチェックエンドポイントテスト"""
    print("\n=== ヘルスチェックエンドポイントテスト ===")
    
    url = "http://localhost:8080/health"
    
    try:
        response = requests.get(url, timeout=10)
        
        print(f"ステータスコード: {response.status_code}")
        print(f"レスポンス:")
        print(json.dumps(response.json(), indent=2, ensure_ascii=False))
        
        if response.status_code == 200:
            print("✅ ヘルスチェックエンドポイント正常動作")
        else:
            print("❌ ヘルスチェックエンドポイントエラー")
            
    except requests.exceptions.ConnectionError:
        print("❌ サーバーに接続できません。")
    except Exception as e:
        print(f"❌ テストエラー: {e}")

def main():
    """メインテスト実行"""
    print("音声認識API エンドポイントテスト開始")
    print("注意: このテストを実行する前に、別のターミナルで 'python main.py' を実行してください。")
    
    # 各エンドポイントをテスト
    test_health_endpoint()
    test_formats_endpoint()
    test_transcribe_endpoint()
    
    print("\n=== テスト完了 ===")

if __name__ == "__main__":
    main() 