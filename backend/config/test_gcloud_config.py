#!/usr/bin/env python3
"""
Google Cloud 設定テスト用スクリプト
"""

from gcloud_config import test_connections


def demo_dry_run_mode():
    """Dry runモードのデモンストレーション"""
    print("=" * 60)
    print("📋 Dry Run モードでのテスト (安全)")
    print("=" * 60)
    test_connections(dry_run=True)


def demo_live_mode():
    """実際のリソース操作モードのデモンストレーション"""
    print("\n" + "=" * 60)
    print("⚠️  Live モードでのテスト (要注意)")
    print("=" * 60)
    test_connections(dry_run=False)


if __name__ == "__main__":
    print("🚀 Google Cloud 接続テストデモ")
    print("\n1. まずは安全なDry Runモードでテスト")
    demo_dry_run_mode()
    
    print("\n2. 実際のリソース操作が必要な場合のみ以下を実行:")
    print("   demo_live_mode() # ユーザー確認プロンプトが表示されます")
    
    # 実際のデモでは安全のためコメントアウト
    # demo_live_mode() 