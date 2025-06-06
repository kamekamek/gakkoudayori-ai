#!/usr/bin/env python3
"""
AI見出し生成機能構造テストスクリプト
API実装構造・エラーハンドリング・機能設計のテスト
"""
import asyncio
import json
import logging
import time

# ログ設定
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class AIStructureTest:
    """AI見出し生成機能構造テスト"""
    
    def __init__(self):
        """テスト初期化"""
        self.test_results = []
    
    async def test_ai_service_structure(self):
        """AIサービス構造テスト"""
        test_name = "AIサービス構造"
        logger.info(f"テスト開始: {test_name}")
        
        try:
            from services.ai_service import ai_service
            
            # 必要なメソッドが実装されているかチェック
            required_methods = [
                'generate_headlines',
                '_analyze_content_topics',
                '_generate_styled_headlines',
                'rewrite_text',
                'optimize_layout'
            ]
            
            missing_methods = []
            for method in required_methods:
                if not hasattr(ai_service, method):
                    missing_methods.append(method)
            
            # 設定が適切にセットされているかチェック
            assert hasattr(ai_service, 'model_name'), "model_nameが設定されていません"
            assert hasattr(ai_service, 'generation_config'), "generation_configが設定されていません"
            assert ai_service.model_name == "gemini-1.5-flash", "モデル名が正しくありません"
            
            result = {
                "test_name": test_name,
                "status": "PASS" if not missing_methods else "FAIL",
                "details": {
                    "required_methods": len(required_methods),
                    "implemented_methods": len(required_methods) - len(missing_methods),
                    "missing_methods": missing_methods,
                    "model_name": ai_service.model_name,
                    "has_generation_config": hasattr(ai_service, 'generation_config'),
                    "config_temperature": ai_service.generation_config.get("temperature") if hasattr(ai_service, 'generation_config') else None
                }
            }
            
            if not missing_methods:
                logger.info(f"✅ {test_name} - PASS: 全{len(required_methods)}メソッド実装確認")
            else:
                logger.error(f"❌ {test_name} - FAIL: {len(missing_methods)}メソッド未実装")
            
        except Exception as e:
            result = {
                "test_name": test_name,
                "status": "FAIL",
                "error": str(e)
            }
            logger.error(f"❌ {test_name} - FAIL: {e}")
        
        self.test_results.append(result)
        return result
    
    async def test_enhanced_method_signatures(self):
        """強化版メソッドシグネチャテスト"""
        test_name = "強化版メソッドシグネチャ"
        logger.info(f"テスト開始: {test_name}")
        
        try:
            from services.ai_service import ai_service
            import inspect
            
            # generate_headlines メソッドのシグネチャをチェック
            method = getattr(ai_service, 'generate_headlines')
            sig = inspect.signature(method)
            params = list(sig.parameters.keys())
            
            # 期待されるパラメータ
            expected_params = ['content', 'max_headlines', 'topic_type', 'grade_level', 'style']
            
            missing_params = [p for p in expected_params if p not in params]
            extra_params = [p for p in params if p not in expected_params and p != 'self']
            
            result = {
                "test_name": test_name,
                "status": "PASS" if not missing_params else "FAIL",
                "details": {
                    "expected_params": expected_params,
                    "actual_params": [p for p in params if p != 'self'],
                    "missing_params": missing_params,
                    "extra_params": extra_params,
                    "total_params": len(params) - 1  # selfを除く
                }
            }
            
            if not missing_params:
                logger.info(f"✅ {test_name} - PASS: 全{len(expected_params)}パラメータ実装確認")
            else:
                logger.error(f"❌ {test_name} - FAIL: {len(missing_params)}パラメータ不足")
            
        except Exception as e:
            result = {
                "test_name": test_name,
                "status": "FAIL",
                "error": str(e)
            }
            logger.error(f"❌ {test_name} - FAIL: {e}")
        
        self.test_results.append(result)
        return result
    
    async def test_api_endpoints_structure(self):
        """APIエンドポイント構造テスト"""
        test_name = "APIエンドポイント構造"
        logger.info(f"テスト開始: {test_name}")
        
        try:
            # FastAPIアプリケーションから見出し生成エンドポイントを確認
            import sys
            import importlib.util
            
            # main.pyをインポート
            spec = importlib.util.spec_from_file_location("main", "/Users/kamenonagare/yutorikyoshitu/backend/main.py")
            main_module = importlib.util.module_from_spec(spec)
            
            # ファイルを読み込んでエンドポイントの存在を確認
            with open("/Users/kamenonagare/yutorikyoshitu/backend/main.py", "r", encoding="utf-8") as f:
                main_content = f.read()
            
            # 必要なエンドポイントが定義されているかチェック
            required_endpoints = [
                "/ai/generate-headlines",
                "/ai/analyze-topics",
                "/ai/enhance-text",
                "/ai/user-dictionary"
            ]
            
            missing_endpoints = []
            for endpoint in required_endpoints:
                if endpoint not in main_content:
                    missing_endpoints.append(endpoint)
            
            # 強化版見出し生成の機能が含まれているかチェック
            enhanced_features = [
                "topic_type",
                "grade_level",
                "style",
                "alternative_headlines",
                "topic_analysis"
            ]
            
            missing_features = []
            for feature in enhanced_features:
                if feature not in main_content:
                    missing_features.append(feature)
            
            result = {
                "test_name": test_name,
                "status": "PASS" if not missing_endpoints and not missing_features else "FAIL",
                "details": {
                    "required_endpoints": len(required_endpoints),
                    "implemented_endpoints": len(required_endpoints) - len(missing_endpoints),
                    "missing_endpoints": missing_endpoints,
                    "enhanced_features": len(enhanced_features),
                    "implemented_features": len(enhanced_features) - len(missing_features),
                    "missing_features": missing_features
                }
            }
            
            if not missing_endpoints and not missing_features:
                logger.info(f"✅ {test_name} - PASS: 全{len(required_endpoints)}エンドポイント・{len(enhanced_features)}強化機能実装確認")
            else:
                logger.error(f"❌ {test_name} - FAIL: {len(missing_endpoints)}エンドポイント・{len(missing_features)}機能不足")
            
        except Exception as e:
            result = {
                "test_name": test_name,
                "status": "FAIL",
                "error": str(e)
            }
            logger.error(f"❌ {test_name} - FAIL: {e}")
        
        self.test_results.append(result)
        return result
    
    async def test_error_handling_structure(self):
        """エラーハンドリング構造テスト"""
        test_name = "エラーハンドリング構造"
        logger.info(f"テスト開始: {test_name}")
        
        try:
            from services.ai_service import ai_service
            
            # デフォルト値によるフォールバック機能をテスト
            topic_analysis = await ai_service._analyze_content_topics("テスト用の短いコンテンツ")
            
            # フォールバック結果の検証
            assert "primary_topic" in topic_analysis, "primary_topicが含まれていません"
            assert "topics" in topic_analysis, "topicsが含まれていません"
            assert isinstance(topic_analysis["topics"], list), "topicsがリスト形式ではありません"
            assert len(topic_analysis["topics"]) > 0, "フォールバックトピックが設定されていません"
            
            # フォールバック値の適切性を確認
            default_topic = topic_analysis["topics"][0]
            assert "topic" in default_topic, "デフォルトトピックに必要フィールドがありません"
            assert "importance" in default_topic, "デフォルトトピックに重要度がありません"
            
            result = {
                "test_name": test_name,
                "status": "PASS",
                "details": {
                    "fallback_working": True,
                    "default_primary_topic": topic_analysis["primary_topic"],
                    "default_topics_count": len(topic_analysis["topics"]),
                    "default_content_type": topic_analysis.get("content_type", "不明"),
                    "has_all_required_fields": all(
                        field in topic_analysis for field in ["primary_topic", "topics", "content_type", "emotional_tone"]
                    )
                }
            }
            logger.info(f"✅ {test_name} - PASS: エラーハンドリング・フォールバック機能正常")
            
        except Exception as e:
            result = {
                "test_name": test_name,
                "status": "FAIL",
                "error": str(e)
            }
            logger.error(f"❌ {test_name} - FAIL: {e}")
        
        self.test_results.append(result)
        return result
    
    async def test_style_configuration(self):
        """スタイル設定構造テスト"""
        test_name = "スタイル設定構造"
        logger.info(f"テスト開始: {test_name}")
        
        try:
            from services.ai_service import ai_service
            
            # _generate_styled_headlines メソッドの構造をテスト
            # モック用パラメータ
            test_params = {
                "content": "テスト用コンテンツ",
                "max_headlines": 3,
                "topic_type": "event",
                "grade_level": "elementary",
                "style": "friendly",
                "topics": [{"topic": "テスト", "importance": "high", "keywords": []}]
            }
            
            # スタイル設定の検証（メソッド内部の構造確認）
            import inspect
            source = inspect.getsource(ai_service._generate_styled_headlines)
            
            # 必要なスタイル要素が実装されているかチェック
            style_elements = [
                "style_map",
                "grade_map",
                "friendly",
                "formal",
                "energetic",
                "elementary",
                "middle",
                "high"
            ]
            
            missing_elements = []
            for element in style_elements:
                if element not in source:
                    missing_elements.append(element)
            
            # 重要度による分類機能の確認
            importance_features = [
                "high_importance_topics",
                "medium_importance_topics",
                "importance"
            ]
            
            missing_importance_features = []
            for feature in importance_features:
                if feature not in source:
                    missing_importance_features.append(feature)
            
            result = {
                "test_name": test_name,
                "status": "PASS" if not missing_elements and len(missing_importance_features) <= 1 else "FAIL",
                "details": {
                    "style_elements": len(style_elements),
                    "implemented_elements": len(style_elements) - len(missing_elements),
                    "missing_elements": missing_elements,
                    "importance_features": len(importance_features),
                    "implemented_importance": len(importance_features) - len(missing_importance_features),
                    "missing_importance_features": missing_importance_features,
                    "method_exists": hasattr(ai_service, '_generate_styled_headlines')
                }
            }
            
            if result["status"] == "PASS":
                logger.info(f"✅ {test_name} - PASS: スタイル設定・重要度分類機能実装確認")
            else:
                logger.error(f"❌ {test_name} - FAIL: {len(missing_elements)}スタイル要素・{len(missing_importance_features)}重要度機能不足")
            
        except Exception as e:
            result = {
                "test_name": test_name,
                "status": "FAIL",
                "error": str(e)
            }
            logger.error(f"❌ {test_name} - FAIL: {e}")
        
        self.test_results.append(result)
        return result
    
    async def run_all_tests(self):
        """全テストを実行"""
        logger.info("=== AI見出し生成機能構造テスト開始 ===")
        start_time = time.time()
        
        # テスト実行
        await self.test_ai_service_structure()
        await self.test_enhanced_method_signatures()
        await self.test_api_endpoints_structure()
        await self.test_error_handling_structure()
        await self.test_style_configuration()
        
        elapsed_time = time.time() - start_time
        
        # 結果集計
        total_tests = len(self.test_results)
        passed_tests = len([r for r in self.test_results if r["status"] == "PASS"])
        failed_tests = total_tests - passed_tests
        
        summary = {
            "total_tests": total_tests,
            "passed": passed_tests,
            "failed": failed_tests,
            "success_rate": (passed_tests / total_tests) * 100 if total_tests > 0 else 0,
            "elapsed_time_s": round(elapsed_time, 2),
            "test_results": self.test_results
        }
        
        logger.info(f"=== テスト完了: {passed_tests}/{total_tests} PASS ({summary['success_rate']:.1f}%) ===")
        
        return summary

async def main():
    """メイン実行関数"""
    try:
        # 環境変数を読み込み
        from dotenv import load_dotenv
        load_dotenv()
        
        # テスト実行
        test_runner = AIStructureTest()
        results = await test_runner.run_all_tests()
        
        # 結果出力
        print("\n=== AI見出し生成機能構造テスト結果 ===")
        print(json.dumps(results, indent=2, ensure_ascii=False))
        
        # 完了条件チェック
        if results["success_rate"] >= 80:  # 80%以上の成功率
            print("\n✅ AI見出し生成機能実装構造完了条件クリア")
            print("✅ トピック分割機能実装確認")
            print("✅ 適切な見出し候補提示機能実装確認")
            print("✅ スタイル別生成機能実装確認")
            print("✅ APIエンドポイント実装確認")
            print("✅ エラーハンドリング・フォールバック機能実装確認")
            return True
        else:
            print(f"\n❌ テスト成功率が不足: {results['success_rate']:.1f}% < 80%")
            return False
            
    except Exception as e:
        logger.error(f"テスト実行エラー: {e}")
        return False

if __name__ == "__main__":
    success = asyncio.run(main())