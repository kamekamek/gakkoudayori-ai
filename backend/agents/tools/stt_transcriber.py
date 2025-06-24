from google.cloud import speech
from typing import Optional

async def transcribe_audio(
    audio_content: bytes,
    phrase_set_resource: Optional[str] = None,
    sample_rate_hertz: int = 16000,
    encoding: str = "LINEAR16"
) -> dict:
    """
    与えられた音声データを文字起こしします。
    """
    client = speech.SpeechClient()
    audio = speech.RecognitionAudio(content=audio_content)

    adaptation_config = None
    if phrase_set_resource:
        adaptation_config = speech.SpeechAdaptation(
            phrase_sets=[
                speech.AdaptationPhraseSet(phrase_set=phrase_set_resource)
            ]
        )

    config = speech.RecognitionConfig(
        # `encoding`文字列を`AudioEncoding` enumにマッピング
        encoding=speech.RecognitionConfig.AudioEncoding[encoding],
        sample_rate_hertz=sample_rate_hertz,
        language_code="ja-JP",
        adaptation=adaptation_config,
    )

    try:
        response = client.recognize(config=config, audio=audio)
        
        if not response.results:
            return {"status": "success", "transcript": ""}

        transcript = "".join(
            result.alternatives[0].transcript for result in response.results
        )
        return {"status": "success", "transcript": transcript}

    except Exception as e:
        return {"status": "error", "message": f"音声文字起こし中にエラーが発生しました: {str(e)}"}
