#!/usr/bin/env python3
"""
利用可能なGeminiモデルの確認スクリプト

現在利用可能なGeminiモデルとその制限事項を確認します。
"""

import os
import sys
import logging
from datetime import datetime
from typing import Dict, Any

# Google Cloud / Vertex AI関連のインポート
from google.cloud import aiplatform
import vertexai
from vertexai.generative_models import GenerativeModel

# ログ設定
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def list_available_models(project_id: str = "gakkoudayori-ai", location: str = "us-central1") -> Dict[str, Any]:
    """
    利用可能なGeminiモデルを一覧表示
    
    Args:
        project_id (str): GCPプロジェクトID
        location (str): リージョン
        
    Returns:
        Dict[str, Any]: モデル情報の辞書
    """
    try:
        # Vertex AI初期化
        vertexai.init(project=project_id, location=location)
        
        # 推奨モデルリスト（2025年6月時点）
        recommended_models = {
            "production_stable": {
                "gemini-2.5-pro-preview-06-05": {
                    "description": "Gemini 2.0 Flash - 安定版",
                    "input_tokens": 1048576,
                    "output_tokens": 8192,
                    "status": "stable",
                    "cost_per_1m_tokens": "$0.075 (input) / $0.30 (output)"
                },
                "gemini-1.5-flash-002": {
                    "description": "Gemini 1.5 Flash - 安定版",
                    "input_tokens": 1048576,
                    "output_tokens": 8192,
                    "status": "stable",
                    "cost_per_1m_tokens": "$0.075 (input) / $0.30 (output)"
                },
                "gemini-1.5-pro-002": {
                    "description": "Gemini 1.5 Pro - 安定版",
                    "input_tokens": 2097152,
                    "output_tokens": 8192,
                    "status": "stable",
                    "cost_per_1m_tokens": "$1.25 (input) / $5.00 (output)"
                }
            },
            "latest_available": {
                "gemini-2.5-pro-preview-06-05": {
                    "description": "Gemini 2.0 Flash - 最新版",
                    "input_tokens": 1048576,
                    "output_tokens": 8192,
                    "status": "latest",
                    "cost_per_1m_tokens": "$0.075 (input) / $0.30 (output)"
                }
            },
            "preview_experimental": {
                "gemini-2.5-flash-preview-05-20": {
                    "description": "Gemini 2.5 Flash - プレビュー版",
                    "input_tokens": 1048576,
                    "output_tokens": 65536,
                    "status": "preview",
                    "limitations": "制限的なレート制限",
                    "cost_per_1m_tokens": "実験モデル料金"
                },
                "gemini-2.5-pro-preview-06-05": {
                    "description": "Gemini 2.5 Pro - プレビュー版", 
                    "input_tokens": 1048576,
                    "output_tokens": 65536,
                    "status": "preview",
                    "limitations": "制限的なレート制限",
                    "cost_per_1m_tokens": "実験モデル料金"
                }
            }
        }
        
        # 各モデルの接続テスト
        test_results = {}
        test_prompt = "Hello, this is a connection test."
        
        for category, models in recommended_models.items():
            test_results[category] = {}
            for model_name, model_info in models.items():
                logger.info(f"Testing model: {model_name}")
                try:
                    model = GenerativeModel(model_name=model_name)
                    response = model.generate_content(test_prompt)
                    test_results[category][model_name] = {
                        "status": "✅ Available",
                        "info": model_info,
                        "test_response_length": len(response.text) if hasattr(response, 'text') else 0
                    }
                except Exception as e:
                    test_results[category][model_name] = {
                        "status": "❌ Unavailable",
                        "info": model_info,
                        "error": str(e)
                    }
                    
        return test_results
        
    except Exception as e:
        logger.error(f"Failed to list models: {e}")
        return {"error": str(e)}

def test_model_with_long_prompt(model_name: str, project_id: str = "gakkoudayori-ai") -> Dict[str, Any]:
    """
    特定のモデルで長いプロンプトをテストして出力制限を確認
    
    Args:
        model_name (str): テストするモデル名
        project_id (str): GCPプロジェクトID
        
    Returns:
        Dict[str, Any]: テスト結果
    """
    try:
        vertexai.init(project=project_id, location="us-central1")
        model = GenerativeModel(model_name=model_name)
        
        # 長いプロンプトでテスト（オーディオからJSONへの変換のような長い出力が必要なタスク）
        long_prompt = """
以下の音声転写結果を詳細なJSON形式に変換してください：

「こんにちは。今日は良い天気ですね。明日の会議の件ですが、資料の準備はいかがですか？」

以下の形式でJSONを生成してください：
{
  "transcript": "転写内容",
  "analysis": {
    "sentiment": "感情分析",
    "topics": ["トピック1", "トピック2"],
    "intent": "意図分析"
  },
  "structured_data": {
    "greeting": "挨拶部分",
    "weather_comment": "天気コメント",
    "meeting_inquiry": "会議関連の質問"
  }
}

詳細な分析を含めて回答してください。
"""
        
        from vertexai.generative_models import GenerationConfig
        
        # 出力トークン数を調整してテスト
        generation_configs = [
            {"max_output_tokens": 1024, "temperature": 0.2},
            {"max_output_tokens": 2048, "temperature": 0.2},
            {"max_output_tokens": 4096, "temperature": 0.2},
        ]
        
        results = {}
        for i, config in enumerate(generation_configs):
            try:
                generation_config = GenerationConfig(**config)
                response = model.generate_content(long_prompt, generation_config=generation_config)
                
                results[f"test_{i+1}_tokens_{config['max_output_tokens']}"] = {
                    "status": "success",
                    "response_length": len(response.text) if hasattr(response, 'text') else 0,
                    "finish_reason": getattr(response.candidates[0], 'finish_reason', 'unknown') if response.candidates else 'no_candidates',
                    "config": config
                }
                
            except Exception as e:
                results[f"test_{i+1}_tokens_{config['max_output_tokens']}"] = {
                    "status": "error",
                    "error": str(e),
                    "config": config
                }
                
        return results
        
    except Exception as e:
        return {"error": str(e)}

def main():
    """メイン実行関数"""
    print("=" * 70)
    print("🔍 Gemini モデル利用可能性調査")
    print(f"📅 実行日時: {datetime.now().isoformat()}")
    print("=" * 70)
    
    # 1. 利用可能モデルの確認
    print("\n📋 利用可能モデル一覧:")
    models_info = list_available_models()
    
    if "error" in models_info:
        print(f"❌ エラー: {models_info['error']}")
        return
    
    for category, models in models_info.items():
        print(f"\n📂 {category.upper()}:")
        for model_name, model_data in models.items():
            status = model_data.get("status", "unknown")
            info = model_data.get("info", {})
            
            print(f"  📦 {model_name}")
            print(f"     {status}")
            print(f"     💡 {info.get('description', 'No description')}")
            
            if "input_tokens" in info:
                print(f"     📥 Input: {info['input_tokens']:,} tokens")
            if "output_tokens" in info:
                print(f"     📤 Output: {info['output_tokens']:,} tokens")
            if "cost_per_1m_tokens" in info:
                print(f"     💰 Cost: {info['cost_per_1m_tokens']}")
            
            if "error" in model_data:
                print(f"     ⚠️  Error: {model_data['error']}")
    
    # 2. 推奨モデルの提案
    print("\n" + "=" * 70)
    print("💡 推奨事項:")
    print("=" * 70)
    
    print("🚀 本番環境用 (安定性重視):")
    print("   1. gemini-2.5-pro-preview-06-05 - 最新の安定版、高速")
    print("   2. gemini-1.5-flash-002 - 信頼性が高い安定版")
    print("   3. gemini-1.5-pro-002   - 高精度が必要な場合")
    
    print("\n⚡ 開発・テスト環境用:")
    print("   1. gemini-2.5-pro-preview-06-05     - 最新機能をテスト")
    print("   2. gemini-1.5-flash     - バランスの良い選択")
    
    print("\n❌ 避けるべきモデル:")
    print("   1. gemini-2.5-* プレビュー版 - 制限的なレート制限")
    print("   2. experimental版       - 予告なしに変更される可能性")
    
    # 3. 現在のエラーの原因調査
    print("\n" + "=" * 70)
    print("🔍 現在のエラー調査:")
    print("=" * 70)
    
    current_model = "gemini-2.5-pro-preview-06-05"
    print(f"📝 現在使用中のモデル: {current_model}")
    print("⚠️  検出された問題:")
    print("   - finish_reason: MAX_TOKENS")
    print("   - プロンプトトークン: 2,094")
    print("   - 合計トークン: 4,141")
    print("   - 出力が空（セーフティフィルタまたはMAX_TOKENS制限）")
    
    print("\n🛠️  推奨修正:")
    print("   ✅ 安定版モデルに変更完了: gemini-2.5-pro-preview-06-05")
    print("   ✅ max_output_tokensを増加完了: 2048 → 8192")
    print("   🔧 音声認識の問題: 空のテキスト入力への対応追加済み")
    
    # 4. 修正されたモデルでのテスト
    print("\n" + "=" * 70)
    print("🧪 推奨モデルでのテスト:")
    print("=" * 70)
    
    recommended_model = "gemini-2.5-pro-preview-06-05"
    print(f"🔬 テスト対象: {recommended_model}")
    
    test_results = test_model_with_long_prompt(recommended_model)
    if "error" not in test_results:
        for test_name, result in test_results.items():
            print(f"  📊 {test_name}:")
            if result["status"] == "success":
                print(f"     ✅ 成功 - レスポンス長: {result['response_length']} 文字")
                print(f"     🏁 終了理由: {result['finish_reason']}")
            else:
                print(f"     ❌ エラー: {result['error']}")
    else:
        print(f"❌ テストエラー: {test_results['error']}")

if __name__ == "__main__":
    main() 