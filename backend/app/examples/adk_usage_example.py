#!/usr/bin/env python3
# Copyright 2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""
ADK Agent使用例

このスクリプトは、Google ADKエージェントとの統合を直接テストするために使用できます。
"""

import asyncio
import os
import logging
from google.adk.runners import Runner
from google.adk.sessions import InMemorySessionService
from google.genai import types

# 現在のディレクトリをPythonパスに追加
import sys
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from adk.agents.orchestrator_agent import create_orchestrator_agent

# ログ設定
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


async def test_adk_orchestrator():
    """オーケストレーターエージェントのテスト"""
    
    print("🤖 ADKオーケストレーターエージェントのテストを開始します...")
    
    try:
        # エージェントを作成
        orchestrator = create_orchestrator_agent()
        print(f"✅ エージェント作成完了: {orchestrator.name}")
        
        # セッションサービスを作成（インメモリ）
        session_service = InMemorySessionService()
        
        # ランナーを作成
        runner = Runner(
            app_name="adk_test",
            agent=orchestrator,
            session_service=session_service
        )
        print("✅ ランナー作成完了")
        
        # テストメッセージ
        user_message = types.Content(
            role="user",
            parts=[types.Part(text="来週の運動会についての学級通信を作りたいです")]
        )
        
        print("📝 メッセージ送信中...")
        
        # エージェントを実行
        events_async = runner.run_async(
            session_id="test_session_123",
            user_id="test_user",
            new_message=user_message
        )
        
        # イベントを処理
        response_parts = []
        html_output = None
        
        async for event in events_async:
            print(f"📨 イベント受信: {type(event).__name__}")
            
            if hasattr(event, 'content') and event.content:
                if hasattr(event.content, 'parts'):
                    for part in event.content.parts:
                        if hasattr(part, 'text'):
                            text = part.text
                            response_parts.append(text)
                            print(f"💬 応答: {text[:100]}...")
                            
                            # HTMLコンテンツかチェック
                            if text.strip().startswith('<!DOCTYPE html>'):
                                html_output = text
                                print("🎉 HTML生成完了！")
            
            elif hasattr(event, 'error'):
                print(f"❌ エラー: {event.error}")
        
        # 結果を表示
        print("\n" + "="*50)
        print("📊 実行結果")
        print("="*50)
        
        if response_parts:
            full_response = '\n'.join(response_parts)
            print(f"✅ 応答内容: {len(full_response)} 文字")
            
            if html_output:
                print("✅ HTML生成: 成功")
                print(f"📄 HTMLサイズ: {len(html_output)} 文字")
                
                # HTMLファイルとして保存
                output_file = "test_newsletter.html"
                with open(output_file, 'w', encoding='utf-8') as f:
                    f.write(html_output)
                print(f"💾 HTMLファイル保存: {output_file}")
            else:
                print("⚠️  HTML生成: なし")
        else:
            print("❌ 応答なし")
    
    except Exception as e:
        print(f"❌ エラーが発生しました: {e}")
        logger.exception("Detailed error information:")


async def test_individual_agents():
    """個別エージェントのテスト"""
    
    print("\n🔧 個別エージェントのテストを開始します...")
    
    try:
        # Plannerエージェントのテスト
        from adk.agents.planner_agent import create_planner_agent
        from adk.agents.generator_agent import create_generator_agent
        
        planner = create_planner_agent()
        print(f"✅ Plannerエージェント作成: {planner.name}")
        
        generator = create_generator_agent()
        print(f"✅ Generatorエージェント作成: {generator.name}")
        
        # テスト用のJSON（Plannerが生成するであろう形式）
        test_json = """
        {
          "school_name": "テスト小学校",
          "grade": "1年3組", 
          "main_title": "運動会のお知らせ",
          "sections": [
            {
              "type": "announcement",
              "title": "運動会について",
              "content": "来週土曜日に運動会を開催します。"
            }
          ],
          "color_scheme": {
            "primary": "#ff6b6b",
            "secondary": "#4ecdc4", 
            "accent": "#45b7d1"
          },
          "layout_suggestion": {
            "columns": 2,
            "blocks": ["header", "main_content"]
          }
        }
        """
        
        print("📝 テスト用JSONでHTML生成テスト...")
        
        # GeneratorエージェントでHTMLを生成
        session_service = InMemorySessionService()
        generator_runner = Runner(
            app_name="generator_test",
            agent=generator,
            session_service=session_service
        )
        
        generator_message = types.Content(
            role="user",
            parts=[types.Part(text=test_json)]
        )
        
        events_async = generator_runner.run_async(
            session_id="generator_test_session",
            user_id="test_user",
            new_message=generator_message
        )
        
        async for event in events_async:
            if hasattr(event, 'content') and event.content:
                if hasattr(event.content, 'parts'):
                    for part in event.content.parts:
                        if hasattr(part, 'text') and part.text.strip().startswith('<!DOCTYPE html>'):
                            print("✅ Generatorエージェント: HTML生成成功")
                            
                            # HTMLファイルとして保存
                            output_file = "generator_test.html"
                            with open(output_file, 'w', encoding='utf-8') as f:
                                f.write(part.text)
                            print(f"💾 GeneratorテストHTML保存: {output_file}")
                            return
        
        print("⚠️  Generatorエージェント: HTMLが生成されませんでした")
        
    except Exception as e:
        print(f"❌ 個別エージェントテストでエラー: {e}")
        logger.exception("Detailed error information:")


if __name__ == "__main__":
    print("🚀 ADK Agent統合テストを開始します")
    print("=" * 60)
    
    # オーケストレーターのテスト
    asyncio.run(test_adk_orchestrator())
    
    # 個別エージェントのテスト
    asyncio.run(test_individual_agents())
    
    print("\n🎯 テスト完了")
    print("=" * 60)