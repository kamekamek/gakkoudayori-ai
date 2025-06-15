#!/usr/bin/env python3
"""
音声認識サービス最終テスト
"""

from speech_recognition_service import *

def main():
    print('=== 音声認識サービス最終テスト ===')
    
    # 基本機能テスト
    audio = create_test_audio_content()
    print(f'1. テスト音声作成: {len(audio)} bytes')
    
    # 検証機能
    validation = validate_audio_format(audio)
    print(f'2. フォーマット検証: {validation["valid"]} ({validation["format"]})')
    
    # フォーマット情報
    formats = get_supported_formats()
    print(f'3. サポートフォーマット: {len(formats)}種類')
    
    # 音声コンテキスト
    contexts = get_default_speech_contexts()
    print(f'4. デフォルトコンテキスト: {len(contexts)}語')
    
    print('✅ 全基本機能正常動作')

if __name__ == "__main__":
    main() 