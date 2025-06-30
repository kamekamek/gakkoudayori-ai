#!/usr/bin/env python3
"""
ADK Server 起動スクリプト (ADK 1.5.0対応)
"""

import os
import asyncio
import logging
from pathlib import Path

# ADK 1.5.0 imports
from google.adk.runners import Runner
from agents.main_conversation_agent.agent import create_main_conversation_agent

# ログ設定
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

async def main():
    """ADKサーバーを起動する"""
    try:
        logger.info("=== ADK Server 起動開始 (1.5.0対応) ===")
        
        # エージェントを作成
        logger.info("MainConversationAgent作成中...")
        root_agent = create_main_conversation_agent()
        logger.info(f"✅ Agent作成完了: {root_agent.name}")
        
        # Runnerを作成
        logger.info("ADK Runner作成中...")
        runner = Runner(
            agent=root_agent,
            port=8080,
            host="0.0.0.0"
        )
        logger.info("✅ Runner作成完了")
        
        # サーバー起動
        logger.info("🚀 ADKサーバー起動中...")
        logger.info("アクセス先: http://localhost:8080/adk/ui")
        
        await runner.run_async()
        
    except Exception as e:
        logger.error(f"❌ ADKサーバー起動エラー: {e}")
        import traceback
        logger.error(f"詳細エラー: {traceback.format_exc()}")
        raise

if __name__ == "__main__":
    asyncio.run(main())