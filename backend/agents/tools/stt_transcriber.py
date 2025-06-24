from google.cloud import speech
from google.adk.tools import BaseTool
from pydantic import BaseModel, Field
from typing import Optional

class SttTranscriberTool(BaseTool):
    """
    Google Cloud Speech-to-Textを使用して音声をテキストに変換するツール。
    """
    class SttTranscriberToolSchema(BaseModel):
        audio_content: bytes = Field(..., description="文字起こしする音声データ(bytes)。")
        # フレーズセットは完全なリソース名（例: projects/PROJECT/locations/global/phraseSets/ID）
        phrase_set_resource: Optional[str] = Field(
            default=None, 
            description="音声認識精度向上のために使用するフレーズセットの完全なリソース名。"
        )
        sample_rate_hertz: int = Field(default=16000, description="音声のサンプルレート。")
        encoding: str = Field(default="LINEAR16", description="音声のエンコーディング形式。")

    def __init__(self):
        super().__init__(
            name="stt_transcriber",
            description="音声ファイルを受け取り、テキストに変換します。",
            schema=self.SttTranscriberToolSchema,
        )

    def _run(self, audio_content: bytes, phrase_set_resource: Optional[str] = None, sample_rate_hertz: int = 16000, encoding: str = "LINEAR16") -> dict:
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
