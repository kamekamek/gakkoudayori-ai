#!/usr/bin/env python3
"""
音声認識API エンドポイントテスト

Flask アプリケーションの音声認識エンドポイントをテスト
"""

import sys
import os

# backend/functions ディレクトリを sys.path に追加
# スクリプトの場所 (tests) から一つ上の階層 (functions) を指す
current_dir = os.path.dirname(os.path.abspath(__file__))
functions_dir = os.path.dirname(current_dir) # functions ディレクトリ
# さらにその上の backend ディレクトリも追加する場合 (もし functions 内のモジュールが backend 内の別モジュールを参照する場合)
# backend_dir = os.path.dirname(functions_dir)
# sys.path.insert(0, backend_dir)
sys.path.insert(0, functions_dir)

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
    url = "http://localhost:8081/api/v1/ai/transcribe"
    
    try:
        # ファイルアップロード形式でPOSTリクエスト
        files = {
            'audio_file': ('test_audio.wav', io.BytesIO(audio_content), 'audio/wav')
        }
        data = {
            'language': 'ja-JP',
            'user_dictionary': '運動会,学習発表会,子どもたち',
            'sample_rate': '16000'
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
    
    url = "http://localhost:8081/api/v1/ai/formats"
    
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
    
    url = "http://localhost:8081/health"
    
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

def test_add_user_dictionary_term_endpoint(user_id="test_user", term="テスト単語", variations=["てすとたんご"], category="test_cat"):
    """ユーザー辞書用語追加エンドポイントテスト"""
    print("\n=== ユーザー辞書 用語追加エンドポイントテスト ===")
    url = f"http://localhost:8081/api/v1/dictionary/{user_id}/terms"
    payload = {
        "term": term,
        "variations": variations,
        "category": category
    }
    try:
        response = requests.post(url, json=payload, timeout=10)
        print(f"ステータスコード: {response.status_code}")
        print(f"レスポンス:")
        res_json = response.json()
        print(json.dumps(res_json, indent=2, ensure_ascii=False))
        
        if response.status_code == 200 and res_json.get('success'):
            print(f"✅ 用語追加エンドポイント正常動作: {term}")
            return True
        else:
            print(f"❌ 用語追加エンドポイントエラー: {term}")
            return False
            
    except requests.exceptions.ConnectionError:
        print("❌ サーバーに接続できません。")
        return False
    except Exception as e:
        print(f"❌ テストエラー: {e}")
        return False

def test_get_user_dictionary_endpoint(user_id="test_user"):
    """ユーザー辞書取得エンドポイントテスト"""
    print(f"\n=== ユーザー辞書取得エンドポイントテスト (User: {user_id}) ===")
    url = f"http://localhost:8081/api/v1/dictionary/{user_id}"
    try:
        response = requests.get(url, timeout=10)
        print(f"ステータスコード: {response.status_code}")
        res_json = response.json()
        # print(json.dumps(res_json, indent=2, ensure_ascii=False)) # 詳細表示は任意
        
        if response.status_code == 200 and res_json.get('success'):
            print(f"✅ 辞書取得エンドポイント正常動作")
            return res_json.get('data', {}).get('dictionary', {})
        else:
            print(f"❌ 辞書取得エンドポイントエラー")
            return None
            
    except requests.exceptions.ConnectionError:
        print("❌ サーバーに接続できません。")
        return None
    except Exception as e:
        print(f"❌ テストエラー: {e}")
        return None

def test_update_user_dictionary_term_endpoint():
    """ユーザー辞書用語更新エンドポイントテスト"""
    print("\n=== ユーザー辞書 用語更新エンドポイントテスト ===")
    user_id = "test_update_user"
    term_to_update = "更新前単語"
    initial_variations = ["こうしんぜんたんご"]
    initial_category = "initial_cat"
    
    updated_variations = ["こうしんごたんご", "アップデート後"]
    updated_category = "updated_cat"
    
    # 1. テスト用単語を追加
    if not test_add_user_dictionary_term_endpoint(user_id, term_to_update, initial_variations, initial_category):
        print("❌ 更新テスト失敗: 初期単語の追加に失敗しました。")
        return

    # 2. 用語を更新
    url_update = f"http://localhost:8081/api/v1/dictionary/{user_id}/terms/{term_to_update}"
    payload_update = {
        "variations": updated_variations,
        "category": updated_category
    }
    try:
        print(f"\n'{term_to_update}' を更新中...")
        response_update = requests.put(url_update, json=payload_update, timeout=10)
        print(f"更新 ステータスコード: {response_update.status_code}")
        res_update_json = response_update.json()
        print(json.dumps(res_update_json, indent=2, ensure_ascii=False))
        
        if not (response_update.status_code == 200 and res_update_json.get('success')):
            print("❌ 更新API呼び出しエラー")
            return

        # 3. 更新されたか確認
        print(f"\n更新後の辞書 '{user_id}' を取得中...")
        current_dictionary = test_get_user_dictionary_endpoint(user_id)
        if current_dictionary and term_to_update in current_dictionary:
            updated_term_data = current_dictionary[term_to_update]
            # user_dictionary_service.py の custom_terms は DictionaryTerm の to_dict() 形式で保存されるため、
            # variations は直接比較ではなく、辞書内のキーでアクセスする
            retrieved_variations = updated_term_data.get('variations')
            retrieved_category = updated_term_data.get('category')
            
            # variations の比較は順序も考慮する場合 list == list で良い
            if retrieved_variations == updated_variations and retrieved_category == updated_category:
                print(f"✅ 用語更新成功: '{term_to_update}' -> Variations: {retrieved_variations}, Category: {retrieved_category}")
            else:
                print(f"❌ 更新内容不一致: Expected Vars: {updated_variations}, Got: {retrieved_variations}. Expected Cat: {updated_category}, Got: {retrieved_category}")
        else:
            print(f"❌ 更新確認エラー: '{term_to_update}' が辞書に見つからない、または辞書取得失敗")
            
    except requests.exceptions.ConnectionError:
        print("❌ サーバーに接続できません。")
    except Exception as e:
        print(f"❌ 更新テストエラー: {e}")

def test_delete_user_dictionary_term_endpoint():
    """ユーザー辞書用語削除エンドポイントテスト"""
    print("\n=== ユーザー辞書 用語削除エンドポイントテスト ===")
    user_id = "test_delete_user"
    term_to_delete = "削除対象単語"
    
    # 1. テスト用単語を追加
    if not test_add_user_dictionary_term_endpoint(user_id, term_to_delete, ["さくじょたいしょうたんご"], "delete_cat"):
        print("❌ 削除テスト失敗: 初期単語の追加に失敗しました。")
        return

    # 2. 用語を削除
    url_delete = f"http://localhost:8081/api/v1/dictionary/{user_id}/terms/{term_to_delete}"
    try:
        print(f"\n'{term_to_delete}' を削除中...")
        response_delete = requests.delete(url_delete, timeout=10)
        print(f"削除 ステータスコード: {response_delete.status_code}")
        res_delete_json = response_delete.json()
        print(json.dumps(res_delete_json, indent=2, ensure_ascii=False))
        
        if not (response_delete.status_code == 200 and res_delete_json.get('success')):
            print("❌ 削除API呼び出しエラー")
            return

        # 3. 削除されたか確認
        print(f"\n削除後の辞書 '{user_id}' を取得中...")
        current_dictionary = test_get_user_dictionary_endpoint(user_id)
        if current_dictionary is not None: # 辞書取得自体は成功するはず
            if term_to_delete not in current_dictionary:
                print(f"✅ 用語削除成功: '{term_to_delete}' は辞書に存在しません。")
            else:
                print(f"❌ 削除失敗: '{term_to_delete}' がまだ辞書に存在します。")
        else:
            print(f"❌ 削除確認エラー: 辞書取得失敗")
            
    except requests.exceptions.ConnectionError:
        print("❌ サーバーに接続できません。")
    except Exception as e:
        print(f"❌ 削除テストエラー: {e}")

def main():
    """メインテスト実行"""
    print("音声認識API エンドポイントテスト開始")
    print("注意: このテストを実行する前に、別のターミナルで 'python main.py' を実行してください。")
    
    # 各エンドポイントをテスト
    test_health_endpoint()
    test_formats_endpoint()
    test_transcribe_endpoint()

    # ユーザー辞書関連テスト
    # (注意: これらのテストは互いに影響しあう可能性があるため、独立性を高める工夫が必要な場合がある)
    print("\n--- ユーザー辞書APIテスト --- ")
    # test_add_user_dictionary_term_endpoint() # 個別実行用、更新・削除テスト内で呼び出される
    # test_get_user_dictionary_endpoint()   # 個別実行用、更新・削除テスト内で呼び出される
    test_update_user_dictionary_term_endpoint()
    test_delete_user_dictionary_term_endpoint()
    
    print("\n=== 全テスト完了 ===")

if __name__ == "__main__":
    main() 