""" 
Gemini API基盤サービス

T3-AI-002-A: Gemini API基盤実装
- Gemini API クライアント実装
- 基本リクエスト・レスポンス処理
- エラーハンドリング実装
- API接続テスト通過

このモジュールは以下の機能を提供します：

1. Gemini APIクライアントの初期化と取得
2. テキスト生成とコンテキストベースのテキスト生成
3. API接続テスト機能
4. エラータイプ別の標準化されたエラーハンドリング

APIエンドポイント仕様書に対応： docs/30_API_endpoints.md

"""

import os
import logging
import time
from datetime import datetime
from typing import Dict, List, Any, Optional, Tuple, Union, TypedDict, Literal

# Google Cloud / Vertex AI関連のインポート
from google.auth import default
from google.oauth2 import service_account
from google.cloud import aiplatform
from google.api_core import exceptions as gcp_exceptions
import vertexai
from vertexai.generative_models import GenerativeModel, Part, GenerationConfig

# 認証サービスを利用
from gcp_auth_service import initialize_gcp_credentials

# ロギング設定
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# 型定義
GeminiErrorType = Literal[
    'QUOTA_EXCEEDED', 
    'PERMISSION_DENIED', 
    'MODEL_NOT_FOUND',
    'GENERAL_ERROR'
]

class GeminiResponse(TypedDict):
    """Gemini APIレスポンスの型定義"""
    text: str
    usage: Dict[str, int]
    response_time: float
    timestamp: str
    model_info: Dict[str, Any]

class GeminiError(TypedDict):
    """Gemini APIエラーの型定義"""
    error: str
    type: GeminiErrorType
    response_time: float
    timestamp: str

class ChatMessage(TypedDict):
    """Gemini APIチャットメッセージの型定義"""
    role: Literal['user', 'assistant']
    content: str

class ConnectionStatus(TypedDict):
    """Gemini API接続テスト結果の型定義"""
    success: bool
    model_info: Optional[Dict[str, Any]]
    error: Optional[str]
    response_time: float
    timestamp: str


# ==============================================================================
# Gemini APIクライアント
# ==============================================================================

def get_gemini_client(
    project_id: str,
    credentials_path: str,
    model_name: str = "gemini-1.5-flash",
    location: str = "us-central1"
) -> Optional[GenerativeModel]:
    """
    Gemini APIクライアントを取得します
    
    Args:
        project_id (str): Google CloudプロジェクトID
        credentials_path (str): サービスアカウントキーファイルのパス
        model_name (str, optional): 使用するGeminiモデル名. デフォルトは "gemini-2.0-flash-exp"
        location (str, optional): APIリージョン. デフォルトは "us-central1"
        
    Returns:
        Optional[GenerativeModel]: 初期化されたGemini APIクライアントまたはNone
        
    Note:
        テスト環境では test_credentials.json ファイルが存在しなくてもテスト用に認証が成功したとみなします
    """
    start_time = time.time()
    
    try:
        # Cloud Run環境ではデフォルト認証を使用、ローカル環境では認証ファイルを使用
        if os.getenv('K_SERVICE'):
            logger.info("Detected Cloud Run environment, using default credentials")
        elif credentials_path and os.path.exists(credentials_path):
            if not initialize_gcp_credentials(credentials_path):
                logger.error("Failed to initialize GCP credentials")
                return None
        else:
            logger.info("Using default credentials")
        
        # Vertex AI初期化
        vertexai.init(project=project_id, location=location)
        
        # Geminiモデルのクライアントを取得
        model = GenerativeModel(model_name=model_name)
        
        logger.info(f"Gemini API client initialized for model: {model_name} in {time.time() - start_time:.3f}s")
        return model
        
    except FileNotFoundError as e:
        logger.error(f"Credentials file not found: {credentials_path}, {e}")
        return None
    except gcp_exceptions.PermissionDenied as e:
        logger.error(f"Permission denied: {e}")
        return None
    except gcp_exceptions.NotFound as e:
        logger.error(f"Model not found: {model_name}, {e}")
        return None
    except Exception as e:
        logger.error(f"Failed to get Gemini API client: {e}")
        return None



# ==============================================================================
# テキスト生成機能
# ==============================================================================

def generate_text(
    prompt: str,
    project_id: str,
    credentials_path: str,
    model_name: str = "gemini-1.5-flash",
    temperature: float = 0.2,
    max_output_tokens: int = 1024,
    top_k: int = 40,
    top_p: float = 0.8,
    location: str = "us-central1"
) -> Dict[str, Any]:
    """
    Geminiを使用してテキストを生成します
    
    Args:
        prompt (str): プロンプトテキスト
        project_id (str): Google CloudプロジェクトID
        credentials_path (str): サービスアカウントキーファイルのパス
        model_name (str, optional): Geminiモデル名
        temperature (float, optional): 生成の温度パラメータ (0-1)
        max_output_tokens (int, optional): 最大出力トークン数
        top_k (int, optional): 生成時に考慮する上低k個のトークン
        top_p (float, optional): 生成時に考慮するtop-pトークン
        location (str, optional): APIリージョン
        
    Returns:
        Dict[str, Any]: API仕様書に準拠したレスポンス形式での生成結果またはエラー情報
    """
    start_time = time.time()
    timestamp = datetime.now().isoformat()
    
    try:
        # クライアント取得
        client = get_gemini_client(
            project_id=project_id,
            credentials_path=credentials_path,
            model_name=model_name,
            location=location
        )
        
        if client is None:
            return {
                "success": False,
                "error": {
                    "code": "CLIENT_INITIALIZATION_ERROR",
                    "message": "Gemini APIクライアントの初期化に失敗しました",
                    "details": {
                        "response_time": time.time() - start_time,
                        "timestamp": timestamp
                    }
                }
            }
        
        # 生成設定を渡す
        generation_config = GenerationConfig(
            temperature=temperature,
            max_output_tokens=max_output_tokens,
            top_p=top_p,
            top_k=top_k
        )
        
        # テキスト生成リクエスト
        response = client.generate_content(
            prompt,
            generation_config=generation_config
        )
        
        # レスポンスからテキストを取得
        generated_text = response.text
        response_time = time.time() - start_time
        
        # 使用量情報を取得 (利用可能な場合)
        usage_info = {}
        if hasattr(response, "usage_metadata"):
            usage_info = {
                "prompt_token_count": getattr(response.usage_metadata, "prompt_token_count", 0),
                "candidates_token_count": getattr(response.usage_metadata, "candidates_token_count", 0),
                "total_token_count": getattr(response.usage_metadata, "total_token_count", 0)
            }
        else:
            # 概算のトークン数を計算
            usage_info = {
                "prompt_token_count": len(prompt) // 4,  # 概算値
                "candidates_token_count": len(generated_text) // 4,  # 概算値
                "total_token_count": (len(prompt) + len(generated_text)) // 4  # 概算値
            }
        
        # API仕様書に合わせたレスポンス形式で返却
        result = {
            "success": True,
            "data": {
                "text": generated_text,
                "ai_metadata": {
                    "model": model_name,
                    "processing_time_ms": int(response_time * 1000),
                    "word_count": len(generated_text.split()),
                    "usage": usage_info
                },
                "timestamp": timestamp
            }
        }
        
        logger.info(f"Text generation successful. Total tokens: {usage_info['total_token_count']}, time: {response_time:.3f}s")
        return result
        
    except Exception as e:
        logger.error(f"Failed to generate text: {e}")
        return handle_gemini_error(e, start_time)


def generate_text_with_seasonal_enhancement(
    prompt: str,
    seasonal_data: Optional[Dict[str, Any]] = None,
    project_id: str = "yutori-kyoshitu",
    credentials_path: str = "secrets/gcp-credentials.json",
    model_name: str = "gemini-1.5-flash",
    temperature: float = 0.2,
    max_output_tokens: int = 1024,
    top_k: int = 40,
    top_p: float = 0.8,
    location: str = "us-central1"
) -> Dict[str, Any]:
    """
    🎨 季節感を考慮したテキスト生成（革新的新機能）
    
    Args:
        prompt (str): 基本プロンプトテキスト
        seasonal_data (Optional[Dict[str, Any]]): 季節感データ（季節、キーワード、カラーパレット等）
        project_id (str): Google CloudプロジェクトID
        credentials_path (str): サービスアカウントキーファイルのパス
        model_name (str, optional): Geminiモデル名
        temperature (float, optional): 生成の多様性
        max_output_tokens (int, optional): 最大出力トークン数
        top_k (int, optional): 生成時に考慮する上位k個のトークン
        top_p (float, optional): 生成時に考慮するtop-pトークン
        location (str, optional): APIリージョン
        
    Returns:
        Dict[str, Any]: 季節感を統合した生成結果またはエラー情報
    """
    start_time = time.time()
    
    # 季節感強化プロンプトを構築
    enhanced_prompt = prompt
    
    if seasonal_data:
        season_name = seasonal_data.get('season', '春')
        keywords = seasonal_data.get('keywords', [])
        colors = seasonal_data.get('colors', [])
        events = seasonal_data.get('events', [])
        themes = seasonal_data.get('themes', [])
        
        seasonal_context = f"""

🎨 SEASONAL_ENHANCEMENT_CONTEXT:
現在の季節: {season_name}
季節キーワード: {', '.join(keywords[:5])}
季節カラーパレット: {', '.join(colors[:3])}
学校行事: {', '.join(events)}
季節テーマ: {', '.join(themes)}

この季節情報を活用して、以下の要求に応じた学級通信コンテンツを生成してください：
- 季節に適した表現や語彙を使用
- 季節行事や自然の変化を織り込む
- 季節の色彩感覚を反映した表現
- 教師らしい温かみのある文体で
- 保護者が共感できる季節感を表現

オリジナルリクエスト: {prompt}
"""
        enhanced_prompt = seasonal_context

    return generate_text(
        prompt=enhanced_prompt,
        project_id=project_id,
        credentials_path=credentials_path,
        model_name=model_name,
        temperature=temperature,
        max_output_tokens=max_output_tokens,
        top_k=top_k,
        top_p=top_p,
        location=location
    )

def generate_text_with_context(
    prompt: str,
    context: List[Dict[str, str]],
    project_id: str,
    credentials_path: str,
    model_name: str = "gemini-1.5-flash",
    temperature: float = 0.2,
    max_output_tokens: int = 1024,
    top_k: int = 40,
    top_p: float = 0.8,
    location: str = "us-central1"
) -> Dict[str, Any]:
    """
    Geminiを使用してコンテキスト付きでテキストを生成
    
    Args:
        prompt (str): プロンプトテキスト
        context (List[Dict[str, str]]): 会話コンテキスト
        project_id (str): Google CloudプロジェクトID
        credentials_path (str): サービスアカウントキーファイルのパス
        model_name (str, optional): Geminiモデル名
        temperature (float, optional): 生成の多様性 (0-1)
        max_output_tokens (int, optional): 最大出力トークン数
        top_k (int, optional): 生成時に考慮する上位k個のトークン
        top_p (float, optional): 生成時に考慮するtop-pトークン
        location (str, optional): APIリージョン
        
    Returns:
        Dict[str, Any]: 生成結果または生成エラー情報
    """
    start_time = time.time()
    
    try:
        # クライアント取得
        client = get_gemini_client(
            project_id=project_id,
            credentials_path=credentials_path,
            model_name=model_name,
            location=location
        )
        
        if client is None:
            return {
                "success": False,
                "error": {
                    "code": "CLIENT_INITIALIZATION_ERROR",
                    "message": "Gemini APIクライアントの初期化に失敗しました",
                    "details": {
                        "response_time": time.time() - start_time,
                        "timestamp": datetime.now().isoformat()
                    }
                }
            }
        
        # 生成パラメータ設定
        generation_config = {
            "temperature": temperature,
            "max_output_tokens": max_output_tokens,
            "top_k": top_k,
            "top_p": top_p,
        }
        
        # チャット履歴を構築する代わりに、直接プロンプトを構築
        # Vertex AIのPythonクライアントライブラリではチャット履歴を簡易的に扱う
        full_prompt = ""
        
        # コンテキストからプロンプトを構築
        for item in context:
            if item["role"] == "user":
                full_prompt += f"User: {item['content']}\n"
            elif item["role"] == "assistant":
                full_prompt += f"Assistant: {item['content']}\n"
        
        # 新しいプロンプトを追加
        full_prompt += f"User: {prompt}\nAssistant: "
        
        # テキスト生成実行
        response = client.generate_content(
            full_prompt,
            generation_config=generation_config
        )
        
        # コンテキストに新しいメッセージを追加
        updated_context = context.copy()
        updated_context.append({"role": "user", "content": prompt})
        updated_context.append({"role": "assistant", "content": response.text})
        
        # 使用量情報を取得 (利用可能な場合)
        response_time = time.time() - start_time
        timestamp = datetime.now().isoformat()
        usage_info = {}
        if hasattr(response, "usage_metadata"):
            usage_info = {
                "prompt_token_count": getattr(response.usage_metadata, "prompt_token_count", 0),
                "candidates_token_count": getattr(response.usage_metadata, "candidates_token_count", 0),
                "total_token_count": getattr(response.usage_metadata, "total_token_count", 0)
            }
        else:
            # 概算のトークン数を計算
            usage_info = {
                "prompt_token_count": len(full_prompt) // 4,  # 概算値
                "candidates_token_count": len(response.text) // 4,  # 概算値
                "total_token_count": (len(full_prompt) + len(response.text)) // 4  # 概算値
            }

        # API仕様書に合わせたレスポンス形式で返却
        result = {
            "success": True,
            "data": {
                "text": response.text,
                "ai_metadata": {
                    "model": model_name,
                    "processing_time_ms": int(response_time * 1000),
                    "word_count": len(response.text.split()),
                    "usage": usage_info
                },
                "context": updated_context,
                "timestamp": timestamp
            }
        }
        
        logger.info(f"Text with context generation successful. Total tokens: {usage_info['total_token_count']}")
        return result
        
    except Exception as e:
        logger.error(f"Failed to generate text with context: {e}")
        return handle_gemini_error(e, start_time)


# ==============================================================================
# 接続テスト
# ==============================================================================

def check_gemini_connection(
    project_id: str,
    credentials_path: str,
    model_name: str = "gemini-1.5-flash",
    location: str = "us-central1"
) -> Dict[str, Any]:
    """
    Gemini API接続をテストします
    
    Args:
        project_id (str): Google CloudプロジェクトID
        credentials_path (str): サービスアカウントキーファイルのパス
        model_name (str, optional): Geminiモデル名
        location (str, optional): APIリージョン
        
    Returns:
        Dict[str, Any]: API仕様書に準拠したテスト結果
    """
    start_time = time.time()
    timestamp = datetime.now().isoformat()
    
    try:
        # クライアント取得
        client = get_gemini_client(
            project_id=project_id,
            credentials_path=credentials_path,
            model_name=model_name,
            location=location
        )
        
        if client is None:
            return {
                "success": False,
                "error": {
                    "code": "CLIENT_INITIALIZATION_ERROR",
                    "message": "Gemini APIクライアントの初期化に失敗しました",
                    "details": {
                        "processing_time_ms": int((time.time() - start_time) * 1000),
                        "timestamp": timestamp
                    }
                }
            }
        
        # 簡単な接続テスト（短いプロンプトで接続確認）
        response = client.generate_content("Hello, test connection.")
        
        # モデル情報と接続結果
        model_info = {
            "model": model_name,
            "project_id": project_id,
            "location": location,
            "version": getattr(client, "version", "unknown"),
            "capabilities": {
                "text_generation": True,
                "contextual_generation": True
            },
            "status": "available"
        }
        
        response_time = time.time() - start_time
        
        logger.info(f"Gemini API connection test successful for model {model_name} in {response_time:.3f}s")
        
        # API仕様書に準拠したレスポンス形式
        return {
            "success": True,
            "data": {
                "connection_status": "ok",
                "model_info": model_info,
                "processing_time_ms": int(response_time * 1000),
                "timestamp": timestamp
            }
        }
        
    except Exception as e:
        # 新しいエラーハンドリング関数を使用
        return handle_gemini_error(e, start_time)


# ==============================================================================
# エラーハンドリング
# ==============================================================================

def handle_gemini_error(error: Exception, start_time: Optional[float] = None) -> Dict[str, Any]:
    """
    Gemini APIエラーを処理しAPI仕様書に準拠した形式で返却します
    
    Args:
        error (Exception): 発生したエラー
        start_time (Optional[float], optional): 処理開始時間
        
    Returns:
        Dict[str, Any]: API仕様書で定義されたエラーレスポンス形式
    """
    error_msg = str(error)
    error_time = datetime.now().isoformat()
    processing_time_ms = None
    
    if start_time:
        processing_time_ms = int((time.time() - start_time) * 1000)
    
    # エラータイプとエラーコードの特定
    if "Quota exceeded" in error_msg or "quota" in error_msg.lower():
        error_code = "QUOTA_EXCEEDED"
        error_type = "API_RATE_LIMIT"
        logger.error(f"Quota exceeded error: {error_msg}")
    elif "Permission denied" in error_msg or "permission" in error_msg.lower():
        error_code = "PERMISSION_DENIED"
        error_type = "AUTHORIZATION_ERROR"
        logger.error(f"Permission denied error: {error_msg}")
    elif "Model not found" in error_msg:
        error_code = "MODEL_NOT_FOUND"
        error_type = "RESOURCE_ERROR"
        logger.error(f"Model not found error: {error_msg}")
    elif "Invalid argument" in error_msg:
        error_code = "INVALID_ARGUMENT"
        error_type = "VALIDATION_ERROR"
        logger.error(f"Invalid argument error: {error_msg}")
    elif "Network" in error_msg or "timeout" in error_msg.lower():
        error_code = "NETWORK_ERROR"
        error_type = "CONNECTION_ERROR"
        logger.error(f"Network error: {error_msg}")
    elif "File not found" in error_msg:
        error_code = "FILE_NOT_FOUND"
        error_type = "RESOURCE_ERROR"
        logger.error(f"File not found error: {error_msg}")
    else:
        error_code = "GENERAL_ERROR"
        error_type = "INTERNAL_ERROR"
        logger.error(f"General error: {error_msg}")
    
    # API仕様書に合わせたエラーレスポンス形式
    result = {
        "success": False,
        "error": {
            "code": error_code,
            "message": error_msg,
            "details": {
                "error_type": error_type,
                "timestamp": error_time
            }
        }
    }
    
    if processing_time_ms:
        result["error"]["details"]["processing_time_ms"] = processing_time_ms
    
    return result
