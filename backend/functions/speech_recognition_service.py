"""
音声認識サービス

T3-AI-005-A: 音声認識API実装
- Speech-to-Text クライアント実装
- 音声ファイルアップロード処理
- 文字起こし結果処理
- 音声認識テスト通過
"""

import os
import logging
import time
from typing import Dict, List, Optional, Any, Tuple
from datetime import datetime
import io

# Google Cloud関連のインポート
from google.cloud import speech
from google.api_core import exceptions as gcp_exceptions

# 設定
logger = logging.getLogger(__name__)


# ==============================================================================
# 音声認識コア機能
# ==============================================================================

def initialize_speech_client(credentials_path: str) -> Optional[speech.SpeechClient]:
    """
    Speech-to-Textクライアントを初期化
    
    Args:
        credentials_path (str): サービスアカウントキーファイルのパス
        
    Returns:
        Optional[speech.SpeechClient]: 初期化されたクライアント、失敗時はNone
    """
    try:
        # 環境変数に認証情報を設定
        os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = credentials_path
        
        # Speech-to-Textクライアント作成
        client = speech.SpeechClient()
        
        logger.info("Speech-to-Text client initialized successfully")
        return client
        
    except Exception as e:
        logger.error(f"Failed to initialize Speech-to-Text client: {e}")
        return None


def transcribe_audio_file(
    audio_content: bytes,
    credentials_path: str,
    language_code: str = "ja-JP",
    sample_rate_hertz: int = None,  # サンプルレートを自動検出に変更
    encoding: speech.RecognitionConfig.AudioEncoding = speech.RecognitionConfig.AudioEncoding.WEBM_OPUS,  # WEBM_OPUSに変更
    enable_enhanced: bool = True,
    enable_punctuation: bool = True,
    enable_word_timestamps: bool = True,
    speech_contexts: Optional[List[str]] = None
) -> Dict[str, Any]:
    """
    音声ファイルを文字起こし
    
    Args:
        audio_content (bytes): 音声ファイルのバイナリデータ
        credentials_path (str): サービスアカウントキーファイルのパス
        language_code (str): 言語コード (デフォルト: "ja-JP")
        sample_rate_hertz (int): サンプリングレート (デフォルト: 48000)
        encoding: 音声エンコーディング (デフォルト: OGG_OPUS)
        enable_enhanced (bool): 強化モデル使用 (デフォルト: True)
        enable_punctuation (bool): 句読点自動挿入 (デフォルト: True)
        enable_word_timestamps (bool): 単語タイムスタンプ (デフォルト: True)
        speech_contexts (List[str]): 認識精度向上用語句リスト
        
    Returns:
        Dict[str, Any]: 文字起こし結果
    """
    start_time = time.time()
    
    try:
        # クライアント初期化
        client = initialize_speech_client(credentials_path)
        if not client:
            return {
                'success': False,
                'error': 'Failed to initialize Speech-to-Text client',
                'processing_time_ms': int((time.time() - start_time) * 1000)
            }
        
        # 音声データ設定
        audio = speech.RecognitionAudio(content=audio_content)
        
        # 認識設定（最もシンプルな設定に変更）
        config_params = {
            'encoding': encoding,
            'language_code': language_code,
            # 高度な設定を一時的に無効化
            # 'model': 'latest_long',
            # 'use_enhanced': enable_enhanced,
            # 'enable_automatic_punctuation': enable_punctuation,
            # 'enable_word_time_offsets': enable_word_timestamps,
        }
        
        # サンプルレートが指定されている場合のみ設定
        if sample_rate_hertz is not None:
            config_params['sample_rate_hertz'] = sample_rate_hertz
        
        config = speech.RecognitionConfig(**config_params)
        
        # 学校用語の認識精度向上設定
        if speech_contexts is None:
            speech_contexts = [
                '運動会', '学習発表会', '学級通信', '子どもたち', 
                '頑張っていました', '先生', '保護者', '授業', 
                '休み時間', '給食', '掃除', '帰りの会'
            ]
        
        if speech_contexts:
            config.speech_contexts = [
                speech.SpeechContext(phrases=speech_contexts)
            ]
        
        # 音声認識実行
        logger.info(f"Starting speech recognition. Audio size: {len(audio_content)} bytes")
        logger.info(f"Config: language={language_code}, sample_rate={sample_rate_hertz}, encoding={encoding}, model=latest_long")
        
        # 音声データの最初の部分をデバッグ用に確認
        if len(audio_content) > 4:
            header_bytes = audio_content[:4]
            logger.info(f"Audio header bytes: {header_bytes.hex()}")
        
        response = client.recognize(config=config, audio=audio)
        
        # レスポンスの詳細ログ
        logger.info(f"Speech API response: {len(response.results)} results found")
        
        if len(response.results) == 0:
            logger.warning("No speech results returned from API. Possible causes:")
            logger.warning("1. Audio contains no recognizable speech")
            logger.warning("2. Audio format is incompatible")
            logger.warning("3. Audio is too short or too quiet")
            logger.warning("4. Language code mismatch")
            
        for i, result in enumerate(response.results):
            # is_finalフィールドは使用しない（互換性のため）
            logger.info(f"Result {i}: {len(result.alternatives)} alternatives")
            if result.alternatives:
                alt = result.alternatives[0]
                logger.info(f"Alternative 0: transcript='{alt.transcript}', confidence={alt.confidence}")
                logger.info(f"Transcript length: {len(alt.transcript)}")
                if len(alt.transcript) == 0:
                    logger.warning(f"Empty transcript in result {i} - confidence was {alt.confidence}")
            else:
                logger.warning(f"No alternatives found in result {i}")
        
        # 結果処理
        transcripts = []
        sections = []
        overall_confidence = 0.0
        word_count = 0
        
        for i, result in enumerate(response.results):
            alternative = result.alternatives[0]
            transcript = alternative.transcript
            confidence = alternative.confidence
            
            transcripts.append(transcript)
            overall_confidence += confidence
            word_count += len(transcript.split())
            
            # セクション情報（タイムスタンプ付き）
            section = {
                'title': f'セクション {i+1}',
                'content': transcript,
                'confidence': confidence,
                'start_time': 0,  # 実際の実装では適切に計算
                'end_time': 0     # 実際の実装では適切に計算
            }
            
            # 単語タイムスタンプ処理
            if alternative.words:
                words_info = []
                for word in alternative.words:
                    start_time_sec = word.start_time.total_seconds()
                    end_time_sec = word.end_time.total_seconds()
                    words_info.append({
                        'word': word.word,
                        'start_time': start_time_sec,
                        'end_time': end_time_sec
                    })
                
                if words_info:
                    section['start_time'] = words_info[0]['start_time']
                    section['end_time'] = words_info[-1]['end_time']
                section['words'] = words_info
            
            sections.append(section)
        
        # 全体結果
        full_transcript = ' '.join(transcripts)
        if len(response.results) > 0:
            overall_confidence = overall_confidence / len(response.results)
        
        processing_time = time.time() - start_time
        
        result = {
            'success': True,
            'data': {
                'transcript': full_transcript,
                'confidence': overall_confidence,
                'processing_time_ms': int(processing_time * 1000),
                'word_count': word_count,
                'sections': sections,
                'audio_info': {
                    'size_bytes': len(audio_content),
                    'language': language_code,
                    'model': 'latest_long',
                    'enhanced': enable_enhanced
                },
                'timestamp': datetime.now().isoformat()
            }
        }
        
        logger.info(f"Speech recognition successful. Transcript length: {len(full_transcript)}, "
                   f"confidence: {overall_confidence:.3f}, time: {processing_time:.3f}s")
        
        return result
        
    except gcp_exceptions.InvalidArgument as e:
        error_msg = f"Invalid audio format or configuration: {str(e)}"
        logger.error(error_msg)
        return {
            'success': False,
            'error': error_msg,
            'error_type': 'invalid_format',
            'processing_time_ms': int((time.time() - start_time) * 1000)
        }
        
    except gcp_exceptions.PermissionDenied as e:
        error_msg = f"Permission denied for Speech-to-Text API: {str(e)}"
        logger.error(error_msg)
        return {
            'success': False,
            'error': error_msg,
            'error_type': 'permission_denied',
            'processing_time_ms': int((time.time() - start_time) * 1000)
        }
        
    except gcp_exceptions.DeadlineExceeded as e:
        error_msg = f"Speech recognition timeout: {str(e)}"
        logger.error(error_msg)
        return {
            'success': False,
            'error': error_msg,
            'error_type': 'timeout',
            'processing_time_ms': int((time.time() - start_time) * 1000)
        }
        
    except Exception as e:
        error_msg = f"Speech recognition failed: {str(e)}"
        logger.error(error_msg)
        return {
            'success': False,
            'error': error_msg,
            'error_type': 'unknown',
            'processing_time_ms': int((time.time() - start_time) * 1000)
        }


def validate_audio_format(audio_content: bytes) -> Dict[str, Any]:
    """
    音声ファイルフォーマットを検証
    
    Args:
        audio_content (bytes): 音声ファイルのバイナリデータ
        
    Returns:
        Dict[str, Any]: 検証結果
    """
    try:
        # ファイルサイズチェック
        file_size = len(audio_content)
        max_size = 10 * 1024 * 1024  # 10MB
        
        if file_size == 0:
            return {
                'valid': False,
                'error': 'Audio file is empty',
                'error_code': 'EMPTY_FILE'
            }
        
        if file_size > max_size:
            return {
                'valid': False,
                'error': f'Audio file too large: {file_size} bytes (max: {max_size} bytes)',
                'error_code': 'FILE_TOO_LARGE'
            }
        
        # 基本的なヘッダーチェック（WAV形式）
        if audio_content[:4] == b'RIFF' and audio_content[8:12] == b'WAVE':
            format_info = 'WAV'
        elif audio_content[:3] == b'ID3' or (audio_content[:2] == b'\xff\xfb'):
            format_info = 'MP3'
        elif audio_content[:4] == b'fLaC':
            format_info = 'FLAC'
        elif audio_content[:4] == b'OggS':
            format_info = 'OGG'
        else:
            format_info = 'UNKNOWN'
        
        return {
            'valid': True,
            'format': format_info,
            'size_bytes': file_size,
            'size_mb': round(file_size / (1024 * 1024), 2)
        }
        
    except Exception as e:
        return {
            'valid': False,
            'error': f'Audio validation failed: {str(e)}',
            'error_code': 'VALIDATION_ERROR'
        }


def create_test_audio_content() -> bytes:
    """
    テスト用の音声データを作成
    
    Returns:
        bytes: テスト用音声データ
    """
    # 簡単なWAVヘッダーを含むダミー音声データ
    # 実際のテストでは、本物の音声ファイルを使用することを推奨
    wav_header = b'RIFF\x24\x08\x00\x00WAVEfmt \x10\x00\x00\x00\x01\x00\x01\x00\x80>\x00\x00\x00}\x00\x00\x02\x00\x10\x00data\x00\x08\x00\x00'
    dummy_audio_data = b'\x00' * 2048  # 2KB のダミーデータ
    
    return wav_header + dummy_audio_data


# ==============================================================================
# ユーティリティ関数
# ==============================================================================

def get_supported_formats() -> List[Dict[str, Any]]:
    """
    サポートされている音声フォーマット一覧を取得
    
    Returns:
        List[Dict[str, Any]]: サポートフォーマット情報
    """
    return [
        {
            'format': 'LINEAR16',
            'description': 'WAV (推奨)',
            'quality': 'highest',
            'file_size': 'large'
        },
        {
            'format': 'MP3',
            'description': 'MP3',
            'quality': 'good',
            'file_size': 'medium'
        },
        {
            'format': 'FLAC',
            'description': 'FLAC',
            'quality': 'highest',
            'file_size': 'medium'
        },
        {
            'format': 'OGG_OPUS',
            'description': 'OGG Opus (Web推奨)',
            'quality': 'good',
            'file_size': 'small'
        }
    ]


def get_default_speech_contexts() -> List[str]:
    """
    学校関連の認識精度向上用語句リストを取得
    
    Returns:
        List[str]: 学校用語リスト
    """
    return [
        # 学校行事
        '運動会', '学習発表会', '参観日', '遠足', '修学旅行',
        '入学式', '卒業式', '始業式', '終業式', '体育祭',
        
        # 学習関連
        '授業', '宿題', 'テスト', '課題', '発表', '実験',
        '読書', '計算', '漢字', '音楽', '図工', '体育',
        
        # 学校生活
        '給食', '休み時間', '掃除', '帰りの会', '朝の会',
        '保健室', '図書室', '体育館', '運動場', '教室',
        
        # 人物
        '先生', '子どもたち', '児童', '生徒', '保護者',
        '校長先生', 'クラスメート', '友達',
        
        # 感情・評価
        '頑張っていました', '素晴らしい', '上達', '成長',
        '楽しそう', '一生懸命', '協力', '努力'
    ] 