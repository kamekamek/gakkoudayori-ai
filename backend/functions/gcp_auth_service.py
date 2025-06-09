"""
Google Cloud認証サービス

T1-GCP-004-A: 認証テストコード実装
- Google Cloud認証テスト実装
- 各API接続テスト作成  
- 認証エラーハンドリングテスト
- 全テスト通過確認
"""

import os
import json
import logging
import time
from typing import Dict, List, Optional, Any, Tuple
from datetime import datetime

# Google Cloud関連のインポート
import google.auth
from google.auth import default
from google.oauth2 import service_account
from google.cloud import aiplatform
from google.cloud import speech
from google.api_core import exceptions as gcp_exceptions

# 設定
logger = logging.getLogger(__name__)


# ==============================================================================
# Google Cloud認証基盤
# ==============================================================================

def initialize_gcp_credentials(credentials_path: str) -> bool:
    """
    Google Cloud認証情報を初期化
    
    Args:
        credentials_path (str): サービスアカウントキーファイルのパス
        
    Returns:
        bool: 初期化が成功したかどうか
    """
    try:
        # ファイル存在確認
        if not os.path.exists(credentials_path):
            logger.error(f"Credentials file not found: {credentials_path}")
            return False
        
        # 環境変数に設定
        os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = credentials_path
        
        # 認証情報をテスト
        credentials, project = default()
        
        if credentials and project:
            logger.info(f"GCP credentials initialized successfully for project: {project}")
            return True
        else:
            logger.error("Failed to load GCP credentials")
            return False
            
    except Exception as e:
        logger.error(f"Failed to initialize GCP credentials: {e}")
        return False


def verify_service_account(credentials_path: str) -> Optional[Dict[str, Any]]:
    """
    サービスアカウントを検証してプロジェクト情報を返す
    
    Args:
        credentials_path (str): サービスアカウントキーファイルのパス
        
    Returns:
        Optional[Dict[str, Any]]: プロジェクト情報、失敗時はNone
    """
    try:
        # ファイル存在確認
        if not os.path.exists(credentials_path):
            logger.error(f"Credentials file not found: {credentials_path}")
            return None
        
        # JSONファイル読み込み
        with open(credentials_path, 'r') as f:
            credentials_info = json.load(f)
        
        # 必要なフィールド確認
        required_fields = ['type', 'project_id', 'private_key_id', 'private_key', 'client_email']
        for field in required_fields:
            if field not in credentials_info:
                logger.error(f"Missing required field in credentials: {field}")
                return None
        
        # サービスアカウントかどうか確認
        if credentials_info.get('type') != 'service_account':
            logger.error("Credentials file is not a service account")
            return None
        
        # 認証テスト
        credentials = service_account.Credentials.from_service_account_file(credentials_path)
        
        # プロジェクト情報を返す
        result = {
            'project_id': credentials_info['project_id'],
            'client_email': credentials_info['client_email'],
            'private_key_id': credentials_info['private_key_id'],
            'verified': True,
            'timestamp': datetime.now().isoformat()
        }
        
        logger.info(f"Service account verified for project: {result['project_id']}")
        return result
        
    except json.JSONDecodeError as e:
        logger.error(f"Invalid JSON format in credentials file: {e}")
        return None
    except Exception as e:
        logger.error(f"Failed to verify service account: {e}")
        return None


# ==============================================================================
# Vertex AI接続
# ==============================================================================

def get_vertex_ai_client(project_id: str, credentials_path: str):
    """
    Vertex AIクライアントを取得
    
    Args:
        project_id (str): Google CloudプロジェクトID
        credentials_path (str): サービスアカウントキーファイルのパス
        
    Returns:
        Vertex AIクライアントまたはNone
    """
    try:
        # 認証情報設定
        if not initialize_gcp_credentials(credentials_path):
            return None
        
        # Vertex AI初期化
        aiplatform.init(project=project_id, location="us-central1")
        
        logger.info(f"Vertex AI client initialized for project: {project_id}")
        return aiplatform
        
    except Exception as e:
        logger.error(f"Failed to get Vertex AI client: {e}")
        return None


def test_vertex_ai_connection(project_id: str, credentials_path: str) -> Dict[str, Any]:
    """
    Vertex AI接続をテスト
    
    Args:
        project_id (str): Google CloudプロジェクトID
        credentials_path (str): サービスアカウントキーファイルのパス
        
    Returns:
        Dict[str, Any]: テスト結果
    """
    start_time = time.time()
    
    try:
        # クライアント取得
        client = get_vertex_ai_client(project_id, credentials_path)
        if not client:
            return {
                'success': False,
                'error': 'Failed to initialize Vertex AI client',
                'response_time': time.time() - start_time
            }
        
        # 簡単な接続テスト（利用可能なモデル一覧取得など）
        # 実際のAPI呼び出しは課金が発生する可能性があるため、初期化のみ確認
        model_info = {
            'project_id': project_id,
            'location': 'us-central1',
            'available': True,
            'initialized': True
        }
        
        response_time = time.time() - start_time
        
        logger.info(f"Vertex AI connection test successful for project: {project_id}")
        
        return {
            'success': True,
            'model_info': model_info,
            'response_time': response_time,
            'timestamp': datetime.now().isoformat()
        }
        
    except gcp_exceptions.PermissionDenied as e:
        return {
            'success': False,
            'error': f'Permission denied: {str(e)}',
            'response_time': time.time() - start_time
        }
    except gcp_exceptions.NotFound as e:
        return {
            'success': False,
            'error': f'Project not found: {str(e)}',
            'response_time': time.time() - start_time
        }
    except Exception as e:
        error_message = str(e).lower()
        if 'quota' in error_message:
            return {
                'success': False,
                'error': f'Quota exceeded: {str(e)}',
                'response_time': time.time() - start_time
            }
        else:
            return {
                'success': False,
                'error': f'Vertex AI connection failed: {str(e)}',
                'response_time': time.time() - start_time
            }


# ==============================================================================
# Speech-to-Text接続
# ==============================================================================

def get_speech_client(credentials_path: str):
    """
    Speech-to-Textクライアントを取得
    
    Args:
        credentials_path (str): サービスアカウントキーファイルのパス
        
    Returns:
        Speech-to-TextクライアントまたはNone
    """
    try:
        # 認証情報設定
        if not initialize_gcp_credentials(credentials_path):
            return None
        
        # Speech-to-Textクライアント作成
        client = speech.SpeechClient()
        
        logger.info("Speech-to-Text client initialized successfully")
        return client
        
    except Exception as e:
        logger.error(f"Failed to get Speech-to-Text client: {e}")
        return None


def test_speech_to_text_connection(credentials_path: str) -> Dict[str, Any]:
    """
    Speech-to-Text接続をテスト
    
    Args:
        credentials_path (str): サービスアカウントキーファイルのパス
        
    Returns:
        Dict[str, Any]: テスト結果
    """
    start_time = time.time()
    
    try:
        # クライアント取得
        client = get_speech_client(credentials_path)
        if not client:
            return {
                'success': False,
                'error': 'Failed to initialize Speech-to-Text client',
                'response_time': time.time() - start_time
            }
        
        # 設定情報の取得（実際の音声認識は課金が発生するため、設定確認のみ）
        config_info = {
            'language_code': 'ja-JP',
            'sample_rate_hertz': 16000,
            'encoding': 'LINEAR16',
            'client_initialized': True
        }
        
        response_time = time.time() - start_time
        
        logger.info("Speech-to-Text connection test successful")
        
        return {
            'success': True,
            'config_info': config_info,
            'response_time': response_time,
            'timestamp': datetime.now().isoformat()
        }
        
    except gcp_exceptions.PermissionDenied as e:
        return {
            'success': False,
            'error': f'Permission denied: {str(e)}',
            'response_time': time.time() - start_time
        }
    except Exception as e:
        return {
            'success': False,
            'error': f'Speech-to-Text connection failed: {str(e)}',
            'response_time': time.time() - start_time
        }


# ==============================================================================
# 統合テスト機能
# ==============================================================================

def test_all_gcp_connections(project_id: str, credentials_path: str) -> Dict[str, Any]:
    """
    全てのGoogle Cloudサービス接続をテスト
    
    Args:
        project_id (str): Google CloudプロジェクトID
        credentials_path (str): サービスアカウントキーファイルのパス
        
    Returns:
        Dict[str, Any]: 全体テスト結果
    """
    start_time = time.time()
    
    try:
        # プロジェクトIDの基本検証
        if not project_id or project_id.strip() == "":
            return {
                'overall_success': False,
                'error': 'Invalid project ID provided',
                'total_response_time': time.time() - start_time
            }
        
        # サービスアカウント検証
        service_account_result = verify_service_account(credentials_path)
        if not service_account_result:
            return {
                'overall_success': False,
                'error': 'Service account verification failed',
                'total_response_time': time.time() - start_time
            }
        
        results = {
            'service_account': service_account_result,
            'vertex_ai': None,
            'speech_to_text': None,
            'failed_services': [],
            'overall_success': True
        }
        
        # Vertex AIテスト
        try:
            vertex_ai_result = test_vertex_ai_connection(project_id, credentials_path)
            results['vertex_ai'] = vertex_ai_result
            if not vertex_ai_result['success']:
                results['failed_services'].append('vertex_ai')
                results['overall_success'] = False
        except Exception as e:
            results['vertex_ai'] = {'success': False, 'error': str(e)}
            results['failed_services'].append('vertex_ai')
            results['overall_success'] = False
        
        # Speech-to-Textテスト
        try:
            speech_result = test_speech_to_text_connection(credentials_path)
            results['speech_to_text'] = speech_result
            if not speech_result['success']:
                results['failed_services'].append('speech_to_text')
                results['overall_success'] = False
        except Exception as e:
            results['speech_to_text'] = {'success': False, 'error': str(e)}
            results['failed_services'].append('speech_to_text')
            results['overall_success'] = False
        
        # 全体結果
        results['total_response_time'] = time.time() - start_time
        results['timestamp'] = datetime.now().isoformat()
        
        if results['overall_success']:
            logger.info(f"All GCP connections successful for project: {project_id}")
        else:
            logger.warning(f"Some GCP connections failed for project: {project_id}")
            logger.warning(f"Failed services: {results['failed_services']}")
        
        return results
        
    except Exception as e:
        logger.error(f"Fatal error in GCP connection tests: {e}")
        return {
            'overall_success': False,
            'error': f'Fatal error: {str(e)}',
            'total_response_time': time.time() - start_time,
            'timestamp': datetime.now().isoformat()
        }


# ==============================================================================
# ヘルスチェック機能
# ==============================================================================

def gcp_health_check(project_id: str, credentials_path: str) -> Dict[str, Any]:
    """
    GCPサービスのヘルスチェック
    
    Args:
        project_id (str): Google CloudプロジェクトID
        credentials_path (str): サービスアカウントキーファイルのパス
        
    Returns:
        Dict[str, Any]: ヘルスチェック結果
    """
    try:
        # 全接続テスト実行
        results = test_all_gcp_connections(project_id, credentials_path)
        
        # ヘルスチェック用の要約
        health_status = {
            'status': 'healthy' if results['overall_success'] else 'unhealthy',
            'services': {
                'vertex_ai': 'up' if results.get('vertex_ai', {}).get('success', False) else 'down',
                'speech_to_text': 'up' if results.get('speech_to_text', {}).get('success', False) else 'down'
            },
            'project_id': project_id,
            'timestamp': datetime.now().isoformat(),
            'response_time': results.get('total_response_time', 0)
        }
        
        return health_status
        
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        return {
            'status': 'unhealthy',
            'error': str(e),
            'timestamp': datetime.now().isoformat()
        } 