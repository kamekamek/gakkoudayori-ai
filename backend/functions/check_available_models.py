"""
Vertex AIで利用可能なモデルを確認するスクリプト
"""

import os
import logging
from google.cloud import aiplatform
import vertexai
from vertexai.generative_models import GenerativeModel
from gcp_auth_service import initialize_gcp_credentials

# ロギング設定
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def check_available_models():
    """利用可能なGeminiモデルを確認"""
    
    # 設定
    project_id = "gakkoudayori-ai"
    location = "us-central1"
    credentials_path = "credentials/gcp_service_account.json"
    
    # 認証初期化
    if not initialize_gcp_credentials(credentials_path):
        logger.error("認証に失敗しました")
        return
    
    # Vertex AI初期化
    vertexai.init(project=project_id, location=location)
    
    # テスト対象のモデル一覧
    models_to_test = [
        "gemini-2.0-flash-exp",
        "gemini-2.0-flash",
        "gemini-1.5-flash",
        "gemini-2.0-flash-exp",
        "gemini-1.0-pro",
    ]
    
    available_models = []
    
    for model_name in models_to_test:
        try:
            logger.info(f"Testing model: {model_name}")
            
            # モデルインスタンス作成
            model = GenerativeModel(model_name=model_name)
            
            # 簡単なテストプロンプト
            test_prompt = "Hello, please respond with 'OK' if you can understand this."
            
            # テスト実行
            response = model.generate_content(test_prompt)
            
            if response and response.text:
                logger.info(f"✅ {model_name}: 利用可能")
                available_models.append(model_name)
            else:
                logger.warning(f"⚠️ {model_name}: レスポンスなし")
                
        except Exception as e:
            logger.error(f"❌ {model_name}: エラー - {str(e)}")
    
    # 結果サマリー
    print("\n" + "="*50)
    print("📊 利用可能なモデル一覧")
    print("="*50)
    
    if available_models:
        for model in available_models:
            print(f"✅ {model}")
        print(f"\n推奨モデル: {available_models[0]}")
    else:
        print("❌ 利用可能なモデルが見つかりませんでした")
    
    print("="*50)
    
    return available_models

if __name__ == "__main__":
    check_available_models() 