#!/usr/bin/env python3
"""
音声認識API統合テスト

実際のGoogle Cloud Speech-to-Text APIとの統合確認
"""

import sys
import os
from speech_recognition_service import (
    transcribe_audio_file, 
    create_test_audio_content,
    validate_audio_format
)

def main():
    print("=== 音声認識API統合テスト ===")
    
    # テスト音声データ作成
    audio_content = create_test_audio_content()
    credentials_path = "../secrets/service-account-key.json"
    
    # 1. 音声フォーマット検証
    print("\n1. 音声フォーマット検証...")
    validation_result = validate_audio_format(audio_content)
    print(f"   Valid: {validation_result['valid']}")
    print(f"   Format: {validation_result.get('format', 'Unknown')}")
    print(f"   Size: {validation_result.get('size_mb', 0):.2f} MB")
    
    # 2. 実際のAPI呼び出し
    print("\n2. Speech-to-Text API呼び出し...")
    result = transcribe_audio_file(audio_content, credentials_path)
    
    if result['success']:
        print("   ✅ API呼び出し成功")
        print(f"   処理時間: {result['data']['processing_time_ms']}ms")
        print(f"   音声情報: {result['data']['audio_info']}")
        print(f"   セクション数: {len(result['data']['sections'])}")
        print(f"   文字起こし結果: {result['data']['transcript'][:100]}...")
        print(f"   信頼度: {result['data']['confidence']:.3f}")
    else:
        print("   ❌ API呼び出し失敗")
        print(f"   エラー: {result['error']}")
        print(f"   エラータイプ: {result.get('error_type', 'unknown')}")
    
    # 3. 異なる設定でのテスト
    print("\n3. 設定バリエーションテスト...")
    
    # 英語設定
    result_en = transcribe_audio_file(
        audio_content, 
        credentials_path,
        language_code="en-US"
    )
    print(f"   英語設定: {'✅ 成功' if result_en['success'] else '❌ 失敗'}")
    
    # カスタムコンテキスト
    custom_contexts = ["テスト", "音声認識", "Google Cloud"]
    result_custom = transcribe_audio_file(
        audio_content,
        credentials_path,
        speech_contexts=custom_contexts
    )
    print(f"   カスタムコンテキスト: {'✅ 成功' if result_custom['success'] else '❌ 失敗'}")
    
    print("\n=== 統合テスト完了 ===")
    return result['success']

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1) 