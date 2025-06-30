#!/usr/bin/env python3
"""
ユーザー設定反映機能のマルチユーザー環境テスト

このテストは以下を確認します:
1. ユーザー固有のファイルパス管理
2. セッション状態でのユーザーID管理
3. ユーザー設定の正しい反映
4. 異なるユーザー間でのデータ分離
"""

import asyncio
import json
import os
import sys
import tempfile
import shutil
from pathlib import Path

# プロジェクトのルートパスを追加
sys.path.insert(0, os.path.join(os.path.dirname(__file__)))

from agents.shared.file_utils import (
    get_user_artifacts_dir,
    get_user_outline_path,
    get_user_newsletter_path,
    save_user_outline,
    load_user_outline,
    save_user_newsletter,
    load_user_newsletter,
    get_user_id_from_session,
    cleanup_user_artifacts
)

# テスト用ユーザーID
TEST_USER_1 = "test_user_001"
TEST_USER_2 = "test_user_002"
TEST_USER_3 = "test_user_003"

class MockSession:
    """テスト用のモックセッション"""
    def __init__(self, user_id: str):
        self.state = {"user_id": user_id}
        self.user_id = user_id

def test_user_file_isolation():
    """ユーザー固有ファイル分離のテスト"""
    print("🧪 ユーザー固有ファイル分離テスト開始...")
    
    try:
        # 各ユーザーのディレクトリパス取得
        user1_dir = get_user_artifacts_dir(TEST_USER_1)
        user2_dir = get_user_artifacts_dir(TEST_USER_2)
        user3_dir = get_user_artifacts_dir(TEST_USER_3)
        
        print(f"✅ ユーザー1ディレクトリ: {user1_dir}")
        print(f"✅ ユーザー2ディレクトリ: {user2_dir}")
        print(f"✅ ユーザー3ディレクトリ: {user3_dir}")
        
        # ディレクトリが異なることを確認
        assert user1_dir != user2_dir != user3_dir, "ユーザーディレクトリが重複しています"
        
        # 各ディレクトリが実際に作成されていることを確認
        assert os.path.exists(user1_dir), f"ユーザー1ディレクトリが作成されていません: {user1_dir}"
        assert os.path.exists(user2_dir), f"ユーザー2ディレクトリが作成されていません: {user2_dir}"
        assert os.path.exists(user3_dir), f"ユーザー3ディレクトリが作成されていません: {user3_dir}"
        
        print("✅ ユーザー固有ディレクトリ分離テスト合格")
        return True
        
    except Exception as e:
        print(f"❌ ユーザー固有ディレクトリ分離テスト失敗: {e}")
        return False

def test_outline_data_isolation():
    """outline.json データ分離テスト"""
    print("🧪 outline.jsonデータ分離テスト開始...")
    
    try:
        # 各ユーザーの異なるデータを作成
        user1_data = {
            "school_name": "田中小学校",
            "class_name": "3年1組",
            "teacher_name": "田中先生",
            "content": "ユーザー1の学級通信内容"
        }
        
        user2_data = {
            "school_name": "佐藤中学校", 
            "class_name": "2年B組",
            "teacher_name": "佐藤先生",
            "content": "ユーザー2の学級通信内容"
        }
        
        user3_data = {
            "school_name": "山田高等学校",
            "class_name": "1年C組", 
            "teacher_name": "山田先生",
            "content": "ユーザー3の学級通信内容"
        }
        
        # 各ユーザーのデータを保存
        assert save_user_outline(TEST_USER_1, user1_data), "ユーザー1のoutline保存に失敗"
        assert save_user_outline(TEST_USER_2, user2_data), "ユーザー2のoutline保存に失敗"
        assert save_user_outline(TEST_USER_3, user3_data), "ユーザー3のoutline保存に失敗"
        
        # 各ユーザーのデータを読み込んで確認
        loaded_user1_data = load_user_outline(TEST_USER_1)
        loaded_user2_data = load_user_outline(TEST_USER_2)
        loaded_user3_data = load_user_outline(TEST_USER_3)
        
        # データが正しく分離されて保存されていることを確認
        assert loaded_user1_data["school_name"] == "田中小学校", "ユーザー1のデータが正しくありません"
        assert loaded_user2_data["school_name"] == "佐藤中学校", "ユーザー2のデータが正しくありません"
        assert loaded_user3_data["school_name"] == "山田高等学校", "ユーザー3のデータが正しくありません"
        
        # データが混同していないことを確認
        assert loaded_user1_data != loaded_user2_data, "ユーザー1と2のデータが同じです"
        assert loaded_user2_data != loaded_user3_data, "ユーザー2と3のデータが同じです"
        assert loaded_user1_data != loaded_user3_data, "ユーザー1と3のデータが同じです"
        
        print("✅ outline.jsonデータ分離テスト合格")
        return True
        
    except Exception as e:
        print(f"❌ outline.jsonデータ分離テスト失敗: {e}")
        return False

def test_html_data_isolation():
    """newsletter.html データ分離テスト"""
    print("🧪 newsletter.htmlデータ分離テスト開始...")
    
    try:
        # 各ユーザーの異なるHTMLを作成
        user1_html = """
        <!DOCTYPE html>
        <html><head><title>田中小学校 3年1組</title></head>
        <body><h1>田中先生の学級通信</h1><p>ユーザー1のHTML</p></body></html>
        """
        
        user2_html = """
        <!DOCTYPE html>
        <html><head><title>佐藤中学校 2年B組</title></head>
        <body><h1>佐藤先生の学級通信</h1><p>ユーザー2のHTML</p></body></html>
        """
        
        user3_html = """
        <!DOCTYPE html>
        <html><head><title>山田高等学校 1年C組</title></head>
        <body><h1>山田先生の学級通信</h1><p>ユーザー3のHTML</p></body></html>
        """
        
        # 各ユーザーのHTMLを保存
        assert save_user_newsletter(TEST_USER_1, user1_html), "ユーザー1のHTML保存に失敗"
        assert save_user_newsletter(TEST_USER_2, user2_html), "ユーザー2のHTML保存に失敗"
        assert save_user_newsletter(TEST_USER_3, user3_html), "ユーザー3のHTML保存に失敗"
        
        # 各ユーザーのHTMLを読み込んで確認
        loaded_user1_html = load_user_newsletter(TEST_USER_1)
        loaded_user2_html = load_user_newsletter(TEST_USER_2)
        loaded_user3_html = load_user_newsletter(TEST_USER_3)
        
        # HTMLが正しく分離されて保存されていることを確認
        assert "田中小学校" in loaded_user1_html, "ユーザー1のHTMLが正しくありません"
        assert "佐藤中学校" in loaded_user2_html, "ユーザー2のHTMLが正しくありません"
        assert "山田高等学校" in loaded_user3_html, "ユーザー3のHTMLが正しくありません"
        
        # HTMLが混同していないことを確認
        assert loaded_user1_html != loaded_user2_html, "ユーザー1と2のHTMLが同じです"
        assert loaded_user2_html != loaded_user3_html, "ユーザー2と3のHTMLが同じです"
        assert loaded_user1_html != loaded_user3_html, "ユーザー1と3のHTMLが同じです"
        
        print("✅ newsletter.htmlデータ分離テスト合格")
        return True
        
    except Exception as e:
        print(f"❌ newsletter.htmlデータ分離テスト失敗: {e}")
        return False

def test_session_user_id_extraction():
    """セッション状態からのユーザーID取得テスト"""
    print("🧪 セッション状態ユーザーID取得テスト開始...")
    
    try:
        # モックセッションを作成
        session1 = MockSession(TEST_USER_1)
        session2 = MockSession(TEST_USER_2)
        session3 = MockSession(TEST_USER_3)
        
        # ユーザーIDが正しく取得できることを確認
        extracted_user1 = get_user_id_from_session(session1)
        extracted_user2 = get_user_id_from_session(session2)
        extracted_user3 = get_user_id_from_session(session3)
        
        assert extracted_user1 == TEST_USER_1, f"ユーザー1ID取得失敗: {extracted_user1} != {TEST_USER_1}"
        assert extracted_user2 == TEST_USER_2, f"ユーザー2ID取得失敗: {extracted_user2} != {TEST_USER_2}"
        assert extracted_user3 == TEST_USER_3, f"ユーザー3ID取得失敗: {extracted_user3} != {TEST_USER_3}"
        
        print("✅ セッション状態ユーザーID取得テスト合格")
        return True
        
    except Exception as e:
        print(f"❌ セッション状態ユーザーID取得テスト失敗: {e}")
        return False

def test_cleanup_functionality():
    """クリーンアップ機能テスト"""
    print("🧪 クリーンアップ機能テスト開始...")
    
    try:
        # クリーンアップ前にファイルが存在することを確認
        user1_outline = get_user_outline_path(TEST_USER_1)
        user1_newsletter = get_user_newsletter_path(TEST_USER_1)
        
        assert os.path.exists(user1_outline), "クリーンアップ前にoutlineファイルが存在しません"
        assert os.path.exists(user1_newsletter), "クリーンアップ前にnewsletterファイルが存在しません"
        
        # ユーザー1のデータをクリーンアップ
        assert cleanup_user_artifacts(TEST_USER_1), "ユーザー1のクリーンアップに失敗"
        
        # クリーンアップ後にファイルが削除されていることを確認
        assert not os.path.exists(user1_outline), "クリーンアップ後にoutlineファイルが残っています"
        assert not os.path.exists(user1_newsletter), "クリーンアップ後にnewsletterファイルが残っています"
        
        # 他のユーザーのファイルは影響を受けていないことを確認
        user2_outline = get_user_outline_path(TEST_USER_2)
        user2_newsletter = get_user_newsletter_path(TEST_USER_2)
        
        assert os.path.exists(user2_outline), "クリーンアップがユーザー2のoutlineファイルに影響しました"
        assert os.path.exists(user2_newsletter), "クリーンアップがユーザー2のnewsletterファイルに影響しました"
        
        print("✅ クリーンアップ機能テスト合格")
        return True
        
    except Exception as e:
        print(f"❌ クリーンアップ機能テスト失敗: {e}")
        return False

def cleanup_test_environment():
    """テスト環境のクリーンアップ"""
    print("🧹 テスト環境クリーンアップ中...")
    
    try:
        cleanup_user_artifacts(TEST_USER_1)
        cleanup_user_artifacts(TEST_USER_2)
        cleanup_user_artifacts(TEST_USER_3)
        
        # ディレクトリも削除
        for user_id in [TEST_USER_1, TEST_USER_2, TEST_USER_3]:
            try:
                user_dir = get_user_artifacts_dir(user_id)
                if os.path.exists(user_dir):
                    shutil.rmtree(user_dir)
                    print(f"✅ ユーザーディレクトリ削除: {user_dir}")
            except Exception as e:
                print(f"⚠️ ディレクトリ削除中にエラー: {e}")
        
        print("✅ テスト環境クリーンアップ完了")
        
    except Exception as e:
        print(f"⚠️ テスト環境クリーンアップエラー: {e}")

def main():
    """メインテスト実行"""
    print("🚀 マルチユーザー環境ユーザー設定反映テスト開始")
    print("=" * 60)
    
    tests = [
        test_user_file_isolation,
        test_outline_data_isolation,
        test_html_data_isolation,
        test_session_user_id_extraction,
        test_cleanup_functionality
    ]
    
    passed = 0
    total = len(tests)
    
    for test_func in tests:
        try:
            if test_func():
                passed += 1
                print(f"✅ {test_func.__name__} 合格")
            else:
                print(f"❌ {test_func.__name__} 失敗")
        except Exception as e:
            print(f"❌ {test_func.__name__} 例外発生: {e}")
        print("-" * 40)
    
    # 最終クリーンアップ
    cleanup_test_environment()
    
    print("=" * 60)
    print(f"🏁 テスト結果: {passed}/{total} 合格")
    
    if passed == total:
        print("🎉 すべてのテストが合格しました！ユーザー設定反映機能は正常に動作しています。")
        return True
    else:
        print("⚠️ 一部のテストが失敗しました。修正が必要です。")
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)