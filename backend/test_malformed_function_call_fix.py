#!/usr/bin/env python3
"""
MALFORMED_FUNCTION_CALL修正後のテストスクリプト
"""
import asyncio
import json
import sys
from typing import Optional

import google.genai.types as genai_types
from google.adk.sessions.in_memory_session_service import InMemorySessionService
from google.adk.runners import Runner

# エージェントをインポート
from agents.main_conversation_agent.agent import create_main_conversation_agent

def print_divider(title: str):
    """視覚的な区切り線を出力"""
    print("\n" + "="*60)
    print(f"  {title}")
    print("="*60)

async def test_conversation_flow():
    """対話フローのテスト"""
    print_divider("MALFORMED_FUNCTION_CALL修正後のテスト開始")
    
    # ADKセットアップ
    session_service = InMemorySessionService()
    root_agent = create_main_conversation_agent()
    runner = Runner(
        app_name="test-gakkoudayori-agent", 
        agent=root_agent, 
        session_service=session_service
    )
    
    user_id = "test_user"
    session_id = "test_session"
    
    # セッション作成
    await session_service.create_session(
        app_name="test-gakkoudayori-agent",
        user_id=user_id,
        session_id=session_id,
    )
    
    # テストケース1: 基本情報収集
    print_divider("テスト1: 基本情報収集")
    
    test_messages = [
        "道草小学校の6年3組の亀先生です。学級通信を作りたいです。",
        "運動会の総練習について書きたいです。",
        "雨天で日程変更があったけど、無事に木曜日に実施できました。",
        "はい、大丈夫です。この内容で作成してください。"
    ]
    
    for i, message in enumerate(test_messages, 1):
        print(f"\n--- メッセージ {i}: {message} ---")
        
        try:
            async for event in runner.run_async(
                user_id=user_id,
                session_id=session_id,
                new_message=genai_types.Content(
                    role="user", 
                    parts=[genai_types.Part(text=message)]
                ),
            ):
                # イベントの詳細を出力
                author = getattr(event, 'author', 'unknown')
                print(f"📤 {author}: ", end='')
                
                if hasattr(event, 'content') and event.content:
                    if hasattr(event.content, 'parts'):
                        for part in event.content.parts:
                            if hasattr(part, 'text') and part.text:
                                # 長いテキストは省略
                                text = part.text[:200] + "..." if len(part.text) > 200 else part.text
                                print(text)
                    else:
                        print(str(event.content)[:200] + "...")
                else:
                    print("(コンテンツなし)")
                
                # 特別なエラーチェック
                if "MALFORMED_FUNCTION_CALL" in str(event):
                    print("❌ MALFORMED_FUNCTION_CALL エラーが発生しました")
                    return False
                    
        except Exception as e:
            print(f"❌ エラー発生: {e}")
            return False
    
    # セッション状態の確認
    print_divider("セッション状態確認")
    
    session = await session_service.get_session(
        app_name="test-gakkoudayori-agent",
        user_id=user_id,
        session_id=session_id
    )
    
    if session and hasattr(session, 'state'):
        print("📋 セッション状態:")
        for key, value in session.state.items():
            if isinstance(value, str) and len(value) > 100:
                print(f"  - {key}: {value[:100]}...")
            else:
                print(f"  - {key}: {value}")
                
        # 重要な状態チェック
        has_outline = 'outline' in session.state and session.state['outline']
        has_html = 'html' in session.state and session.state['html']
        user_approved = session.state.get('user_approved', False)
        
        print(f"\n📊 重要指標:")
        print(f"  - JSON構成案生成: {'✅' if has_outline else '❌'}")
        print(f"  - HTML生成: {'✅' if has_html else '❌'}")
        print(f"  - ユーザー承認: {'✅' if user_approved else '❌'}")
        
        if has_outline:
            try:
                outline_data = json.loads(session.state['outline'])
                print(f"  - 学校名: {outline_data.get('school_name', 'なし')}")
                print(f"  - 学年: {outline_data.get('grade', 'なし')}")
                print(f"  - 発行者: {outline_data.get('author', {}).get('name', 'なし')}")
            except:
                print("  - JSON解析エラー")
        
        return has_outline and user_approved
    else:
        print("❌ セッション状態が取得できません")
        return False

async def main():
    """メイン実行関数"""
    try:
        success = await test_conversation_flow()
        
        print_divider("テスト結果")
        if success:
            print("✅ テスト成功: MALFORMED_FUNCTION_CALL エラーが解決されました")
            print("✅ ユーザー情報の収集とJSON生成が正常に動作しています")
            sys.exit(0)
        else:
            print("❌ テスト失敗: 問題が残っています")
            sys.exit(1)
            
    except Exception as e:
        print(f"❌ テスト実行エラー: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    asyncio.run(main())