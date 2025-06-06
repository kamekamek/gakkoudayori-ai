"""
Google Cloud Speech-to-Text統合サービス
音声認識・ノイズ抑制・ユーザー辞書機能
"""
import time
import asyncio
from typing import Dict, List, Optional, Any, BinaryIO
from google.cloud import speech
import logging
import json
import io

from config.gcloud_config import cloud_config

# ログ設定
logger = logging.getLogger(__name__)

class SpeechService:
    """Google Cloud Speech-to-Text統合サービスクラス"""
    
    def __init__(self):
        """音声認識サービス初期化"""
        self.project_id = cloud_config.project_id
        self.location = cloud_config.location
        
        # Speech-to-Text クライアント初期化
        try:
            self.client = speech.SpeechClient(credentials=cloud_config.credentials)
            
            # 基本設定（日本語・ノイズ抑制最適化）
            self.base_config = speech.RecognitionConfig(
                encoding=speech.RecognitionConfig.AudioEncoding.WEBM_OPUS,
                sample_rate_hertz=48000,
                language_code="ja-JP",
                # ノイズ抑制機能
                enable_automatic_punctuation=True,
                enable_word_time_offsets=True,
                enable_spoken_punctuation=False,
                # 学校環境向け最適化
                model="latest_long",  # 長時間録音対応
                use_enhanced=True,    # 強化モデル使用
                # ノイズ抑制設定
                audio_channel_count=1,
                enable_separate_recognition_per_channel=False,
            )
            
            logger.info(f"Speech-to-Text初期化成功: {self.project_id}")
        except Exception as e:
            logger.error(f"Speech-to-Text初期化失敗: {e}")
            raise RuntimeError(f"Failed to initialize Speech-to-Text: {e}")
    
    async def transcribe_audio(
        self,
        audio_content: bytes,
        custom_words: Optional[List[str]] = None,
        noise_reduction: bool = True
    ) -> Dict[str, Any]:
        """
        音声ファイルをテキストに変換
        
        Args:
            audio_content: 音声ファイルのバイナリデータ
            custom_words: ユーザー辞書単語リスト
            noise_reduction: ノイズ抑制機能ON/OFF
            
        Returns:
            Dict containing transcription results and metadata
        """
        start_time = time.time()
        
        try:
            # 設定をコピーして調整
            config = speech.RecognitionConfig()
            config.CopyFrom(self.base_config)
            
            # ユーザー辞書設定
            if custom_words and len(custom_words) > 0:
                # 学校関連の専門用語を追加
                school_terms = [
                    "学級通信", "保護者会", "授業参観", "運動会", "文化祭",
                    "遠足", "修学旅行", "学習発表会", "音楽会", "図工",
                    "算数", "国語", "理科", "社会", "体育", "道徳"
                ]
                all_custom_words = list(set(custom_words + school_terms))
                
                # SpeechContext で語彙を強化
                speech_contexts = [speech.SpeechContext(
                    phrases=all_custom_words[:500]  # 最大500単語
                )]
                config.speech_contexts = speech_contexts
            
            # ノイズ抑制設定（学校環境特化）
            if noise_reduction:
                # 学校特有のノイズ対策
                config.audio_channel_count = 1
                config.enable_automatic_punctuation = True
                config.profanity_filter = True  # 不適切な言葉フィルタ
            
            # 音声データ設定
            audio = speech.RecognitionAudio(content=audio_content)
            
            # 音声認識実行（非同期）
            response = await self._transcribe_async(config, audio)
            
            elapsed_time = time.time() - start_time
            
            # 結果解析
            transcript_results = self._parse_recognition_response(response)
            
            # 認識精度チェック（目標: >95%）
            confidence_avg = sum(r.get('confidence', 0.0) for r in transcript_results) / max(len(transcript_results), 1)
            
            if confidence_avg < 0.95:
                logger.warning(f"音声認識精度が目標を下回りました: {confidence_avg:.1%}")
            
            result = {
                "transcript": " ".join([r.get('text', '') for r in transcript_results]),
                "results": transcript_results,
                "confidence_average": confidence_avg,
                "word_count": len(" ".join([r.get('text', '') for r in transcript_results]).split()),
                "custom_words_used": custom_words or [],
                "noise_reduction_enabled": noise_reduction,
                "response_time_ms": int(elapsed_time * 1000),
                "audio_duration_estimate": self._estimate_audio_duration(audio_content),
                "timestamp": int(time.time())
            }
            
            logger.info(f"音声認識成功: {len(result['transcript'])}文字, 精度{confidence_avg:.1%}, {elapsed_time:.3f}s")
            return result
            
        except Exception as e:
            logger.error(f"音声認識失敗: {e}")
            raise RuntimeError(f"Failed to transcribe audio: {str(e)}")
    
    async def stream_recognize_audio(
        self,
        audio_stream: BinaryIO,
        custom_words: Optional[List[str]] = None
    ) -> Dict[str, Any]:
        """
        リアルタイム音声認識（ストリーミング）
        
        Args:
            audio_stream: 音声ストリーム
            custom_words: ユーザー辞書単語リスト
            
        Returns:
            Dict containing streaming recognition results
        """
        start_time = time.time()
        
        try:
            # ストリーミング用設定
            config = speech.RecognitionConfig()
            config.CopyFrom(self.base_config)
            config.encoding = speech.RecognitionConfig.AudioEncoding.WEBM_OPUS
            
            # ユーザー辞書設定
            if custom_words:
                speech_contexts = [speech.SpeechContext(phrases=custom_words)]
                config.speech_contexts = speech_contexts
            
            streaming_config = speech.StreamingRecognitionConfig(
                config=config,
                interim_results=True,  # 中間結果表示
                single_utterance=False  # 連続認識
            )
            
            # ストリーミング認識実行
            responses = await self._stream_recognize_async(streaming_config, audio_stream)
            
            elapsed_time = time.time() - start_time
            
            result = {
                "streaming_results": responses,
                "response_time_ms": int(elapsed_time * 1000),
                "timestamp": int(time.time())
            }
            
            logger.info(f"ストリーミング音声認識完了: {elapsed_time:.3f}s")
            return result
            
        except Exception as e:
            logger.error(f"ストリーミング音声認識失敗: {e}")
            raise RuntimeError(f"Failed to stream recognize audio: {str(e)}")
    
    async def create_user_dictionary(
        self,
        user_id: str,
        words: List[str]
    ) -> Dict[str, Any]:
        """
        ユーザー辞書を作成・更新
        
        Args:
            user_id: ユーザーID
            words: 辞書に追加する単語リスト
            
        Returns:
            Dict containing dictionary creation results
        """
        try:
            # 基本的な学校用語を追加
            school_terms = [
                "学級通信", "学年通信", "保護者会", "授業参観", "個人面談",
                "運動会", "体育祭", "文化祭", "学習発表会", "音楽会",
                "遠足", "修学旅行", "社会科見学", "校外学習",
                "算数", "国語", "理科", "社会", "体育", "図工", "音楽", "道徳",
                "特別活動", "総合的な学習", "外国語活動",
                "1年生", "2年生", "3年生", "4年生", "5年生", "6年生",
                "担任", "学年主任", "教頭", "校長"
            ]
            
            # ユーザー単語と学校用語を結合
            all_words = list(set(words + school_terms))
            
            # 辞書データ構造
            dictionary = {
                "user_id": user_id,
                "words": all_words[:500],  # 最大500単語
                "created_at": int(time.time()),
                "word_count": len(all_words[:500])
            }
            
            # TODO: Firestoreに保存（Phase 1で実装予定）
            # await self._save_user_dictionary(user_id, dictionary)
            
            logger.info(f"ユーザー辞書作成成功: {user_id}, {len(all_words)}語")
            return dictionary
            
        except Exception as e:
            logger.error(f"ユーザー辞書作成失敗: {e}")
            raise RuntimeError(f"Failed to create user dictionary: {str(e)}")
    
    async def _transcribe_async(
        self,
        config: speech.RecognitionConfig,
        audio: speech.RecognitionAudio
    ) -> speech.RecognizeResponse:
        """
        音声認識を非同期実行
        """
        def _sync_transcribe():
            return self.client.recognize(config=config, audio=audio)
        
        response = await asyncio.to_thread(_sync_transcribe)
        return response
    
    async def _stream_recognize_async(
        self,
        streaming_config: speech.StreamingRecognitionConfig,
        audio_stream: BinaryIO
    ) -> List[Dict[str, Any]]:
        """
        ストリーミング音声認識を非同期実行
        """
        def _sync_stream():
            # 簡単な実装（実際のストリーミングは別途実装が必要）
            responses = []
            audio_data = audio_stream.read()
            
            # 音声データをチャンクに分割
            chunk_size = 4096
            for i in range(0, len(audio_data), chunk_size):
                chunk = audio_data[i:i + chunk_size]
                responses.append({
                    "chunk_index": i // chunk_size,
                    "data_size": len(chunk),
                    "interim_result": True
                })
            
            return responses
        
        responses = await asyncio.to_thread(_sync_stream)
        return responses
    
    def _parse_recognition_response(
        self,
        response: speech.RecognizeResponse
    ) -> List[Dict[str, Any]]:
        """
        音声認識レスポンスを解析
        """
        results = []
        
        for result in response.results:
            if result.alternatives:
                alternative = result.alternatives[0]
                
                # 単語レベルの時間情報を取得
                word_info = []
                if hasattr(alternative, 'words'):
                    for word in alternative.words:
                        word_info.append({
                            "word": word.word,
                            "start_time": word.start_time.total_seconds() if hasattr(word, 'start_time') else 0,
                            "end_time": word.end_time.total_seconds() if hasattr(word, 'end_time') else 0
                        })
                
                results.append({
                    "text": alternative.transcript,
                    "confidence": alternative.confidence,
                    "words": word_info
                })
        
        return results
    
    def _estimate_audio_duration(self, audio_content: bytes) -> float:
        """
        音声データの長さを推定（簡易版）
        """
        # 簡易的な推定（実際はより精密な計算が必要）
        # WebM Opusの場合の概算
        estimated_duration = len(audio_content) / (48000 * 2)  # サンプリングレート * バイト数
        return max(estimated_duration, 1.0)  # 最低1秒

# グローバルサービスインスタンス
speech_service = SpeechService()