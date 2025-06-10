import os
from google.cloud import speech

def test_speech_recognition():
    """テスト音声ファイルでSpeech-to-Text APIをテスト"""
    client = speech.SpeechClient()
    
    # テスト音声ファイルを読み込み
    audio_file = 'test_audio.wav'
    
    with open(audio_file, 'rb') as f:
        content = f.read()
    
    audio = speech.RecognitionAudio(content=content)
    
    config = speech.RecognitionConfig(
        encoding=speech.RecognitionConfig.AudioEncoding.LINEAR16,
        sample_rate_hertz=16000,
        language_code='ja-JP',
        model='latest_long',
        use_enhanced=True,
        enable_automatic_punctuation=True,
        enable_word_time_offsets=True,
        speech_contexts=[
            speech.SpeechContext(
                phrases=['運動会', '学習発表会', '学級通信', '子どもたち', '頑張っていました']
            )
        ]
    )
    
    print('=== Speech-to-Text API Test ===')
    print(f'Audio file: {audio_file}')
    print(f'File size: {len(content)} bytes')
    
    try:
        response = client.recognize(config=config, audio=audio)
        
        print('\n=== Recognition Results ===')
        for i, result in enumerate(response.results):
            print(f'Alternative {i+1}:')
            print(f'  Transcript: {result.alternatives[0].transcript}')
            print(f'  Confidence: {result.alternatives[0].confidence:.2f}')
            
            if result.alternatives[0].words:
                print('  Words with timestamps:')
                for word in result.alternatives[0].words:
                    start_time = word.start_time.total_seconds()
                    end_time = word.end_time.total_seconds()
                    print(f'    {word.word} ({start_time:.1f}s - {end_time:.1f}s)')
        
        print('\n✅ Speech-to-Text API test completed successfully!')
        return True
        
    except Exception as e:
        print(f'❌ Error during speech recognition: {e}')
        return False

if __name__ == '__main__':
    success = test_speech_recognition()
    if success:
        print('\n🎉 T3-AI-004-M: Speech-to-Text設定 - すべての設定が完了しました!')
    else:
        print('\n⚠️  設定に問題があります。エラーを確認してください。')