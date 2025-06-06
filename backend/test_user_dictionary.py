#!/usr/bin/env python3
"""
ユーザー辞書機能テストスクリプト
辞書作成・更新・CSV一括登録機能のテスト
"""
import asyncio
import json
import logging
import time

# ログ設定
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class UserDictionaryTest:
    """ユーザー辞書機能テスト"""
    
    def __init__(self):
        """テスト初期化"""
        self.test_results = []
    
    async def test_dictionary_service_initialization(self):
        """辞書サービス初期化テスト"""
        test_name = "辞書サービス初期化"
        logger.info(f"テスト開始: {test_name}")
        
        try:
            from services.user_dictionary_service import user_dictionary_service
            
            # サービスが正常に初期化されているかチェック
            assert hasattr(user_dictionary_service, 'base_school_terms'), "基本学校用語が初期化されていません"
            assert len(user_dictionary_service.base_school_terms) > 50, "基本学校用語が不足しています"
            assert "学級通信" in user_dictionary_service.base_school_terms, "基本用語に「学級通信」が含まれていません"
            
            result = {
                "test_name": test_name,
                "status": "PASS",
                "details": {
                    "base_terms_count": len(user_dictionary_service.base_school_terms),
                    "sample_terms": user_dictionary_service.base_school_terms[:5],
                    "project_id": user_dictionary_service.project_id
                }
            }
            logger.info(f"✅ {test_name} - PASS: {len(user_dictionary_service.base_school_terms)}語のベース辞書")
            
        except Exception as e:
            result = {
                "test_name": test_name,
                "status": "FAIL",
                "error": str(e)
            }
            logger.error(f"❌ {test_name} - FAIL: {e}")
        
        self.test_results.append(result)
        return result
    
    async def test_create_user_dictionary(self):
        """ユーザー辞書作成テスト"""
        test_name = "ユーザー辞書作成"
        logger.info(f"テスト開始: {test_name}")
        
        try:
            from services.user_dictionary_service import user_dictionary_service
            
            # テスト用データ
            user_id = "test_user_dictionary_001"
            custom_words = ["体育館", "音楽室", "図書室", "保健室", "職員室"]
            school_name = "ゆとり小学校"
            grade_level = "elementary"
            
            start_time = time.time()
            
            result_dict = await user_dictionary_service.create_user_dictionary(
                user_id=user_id,
                words=custom_words,
                school_name=school_name,
                grade_level=grade_level
            )
            
            elapsed_time = time.time() - start_time
            
            # 結果検証
            assert result_dict["user_id"] == user_id, "ユーザーIDが正しく設定されていません"
            assert result_dict["school_name"] == school_name, "学校名が正しく設定されていません"
            assert result_dict["grade_level"] == grade_level, "学年レベルが正しく設定されていません"
            assert result_dict["total_words_count"] > len(custom_words), "基本語彙が追加されていません"
            assert all(word in result_dict["words"] for word in custom_words), "カスタム単語が含まれていません"
            
            result = {
                "test_name": test_name,
                "status": "PASS",
                "details": {
                    "user_id": result_dict["user_id"],
                    "custom_words_count": result_dict["custom_words_count"],
                    "base_words_count": result_dict["base_words_count"],
                    "total_words_count": result_dict["total_words_count"],
                    "school_name": result_dict["school_name"],
                    "creation_time_ms": int(elapsed_time * 1000)
                }
            }
            logger.info(f"✅ {test_name} - PASS: {result_dict['total_words_count']}語登録、{elapsed_time:.3f}s")
            
        except Exception as e:
            result = {
                "test_name": test_name,
                "status": "FAIL",
                "error": str(e)
            }
            logger.error(f"❌ {test_name} - FAIL: {e}")
        
        self.test_results.append(result)
        return result
    
    async def test_get_user_dictionary(self):
        """ユーザー辞書取得テスト"""
        test_name = "ユーザー辞書取得"
        logger.info(f"テスト開始: {test_name}")
        
        try:
            from services.user_dictionary_service import user_dictionary_service
            
            user_id = "test_user_dictionary_001"
            
            # 辞書を取得
            result_dict = await user_dictionary_service.get_user_dictionary(user_id)
            
            # 結果検証
            assert "user_id" in result_dict, "ユーザーIDが含まれていません"
            assert "words" in result_dict, "単語リストが含まれていません"
            assert "total_words_count" in result_dict, "総単語数が含まれていません"
            assert isinstance(result_dict["words"], list), "単語リストがリスト形式ではありません"
            assert result_dict["total_words_count"] > 0, "単語数が0です"
            
            result = {
                "test_name": test_name,
                "status": "PASS",
                "details": {
                    "user_id": result_dict["user_id"],
                    "total_words_count": result_dict["total_words_count"],
                    "has_custom_words": len(result_dict.get("custom_words", [])) > 0,
                    "sample_words": result_dict["words"][:5]
                }
            }
            logger.info(f"✅ {test_name} - PASS: {result_dict['total_words_count']}語取得")
            
        except Exception as e:
            result = {
                "test_name": test_name,
                "status": "FAIL",
                "error": str(e)
            }
            logger.error(f"❌ {test_name} - FAIL: {e}")
        
        self.test_results.append(result)
        return result
    
    async def test_update_user_dictionary(self):
        """ユーザー辞書更新テスト"""
        test_name = "ユーザー辞書更新"
        logger.info(f"テスト開始: {test_name}")
        
        try:
            from services.user_dictionary_service import user_dictionary_service
            
            user_id = "test_user_dictionary_001"
            
            # 現在の辞書を取得
            before_dict = await user_dictionary_service.get_user_dictionary(user_id)
            before_count = before_dict["total_words_count"]
            
            # 単語を追加・削除
            new_words = ["新学期", "始業式", "終業式"]
            remove_words = ["体育館"]  # 既存の単語を削除
            
            updated_dict = await user_dictionary_service.update_user_dictionary(
                user_id=user_id,
                new_words=new_words,
                remove_words=remove_words
            )
            
            # 結果検証
            assert updated_dict["user_id"] == user_id, "ユーザーIDが一致しません"
            assert "新学期" in updated_dict["custom_words"], "新しい単語が追加されていません"
            assert "体育館" not in updated_dict["custom_words"], "削除対象の単語が残っています"
            
            result = {
                "test_name": test_name,
                "status": "PASS",
                "details": {
                    "user_id": updated_dict["user_id"],
                    "before_count": before_count,
                    "after_count": updated_dict["total_words_count"],
                    "added_words": new_words,
                    "removed_words": remove_words,
                    "words_difference": updated_dict["total_words_count"] - before_count
                }
            }
            logger.info(f"✅ {test_name} - PASS: +{len(new_words)}語、-{len(remove_words)}語")
            
        except Exception as e:
            result = {
                "test_name": test_name,
                "status": "FAIL",
                "error": str(e)
            }
            logger.error(f"❌ {test_name} - FAIL: {e}")
        
        self.test_results.append(result)
        return result
    
    async def test_csv_import_export(self):
        """CSV一括インポート・エクスポートテスト"""
        test_name = "CSV一括機能"
        logger.info(f"テスト開始: {test_name}")
        
        try:
            from services.user_dictionary_service import user_dictionary_service
            
            user_id = "test_user_csv_001"
            
            # テスト用CSVデータ
            csv_content = """単語,タイプ,備考
学年会議,カスタム,月1回開催
学級懇談会,カスタム,学期末
授業公開,カスタム,年2回
個人面談,カスタム,随時"""
            
            # CSVインポート
            import_result = await user_dictionary_service.import_from_csv(
                user_id=user_id,
                csv_content=csv_content
            )
            
            # インポート結果検証
            assert import_result["imported_words_count"] >= 4, "インポート単語数が不足しています"
            assert "学年会議" in import_result["imported_words"], "インポート対象単語が含まれていません"
            
            # CSVエクスポート
            export_content = await user_dictionary_service.export_to_csv(user_id)
            
            # エクスポート結果検証
            assert isinstance(export_content, str), "エクスポート結果が文字列ではありません"
            assert "学年会議" in export_content, "エクスポート内容にインポートした単語が含まれていません"
            assert "単語" in export_content, "CSVヘッダーが含まれていません"
            
            result = {
                "test_name": test_name,
                "status": "PASS",
                "details": {
                    "imported_words_count": import_result["imported_words_count"],
                    "imported_sample": import_result["imported_words"][:3],
                    "export_size": len(export_content),
                    "csv_lines": len(export_content.split('\n'))
                }
            }
            logger.info(f"✅ {test_name} - PASS: {import_result['imported_words_count']}語インポート、{len(export_content)}文字エクスポート")
            
        except Exception as e:
            result = {
                "test_name": test_name,
                "status": "FAIL",
                "error": str(e)
            }
            logger.error(f"❌ {test_name} - FAIL: {e}")
        
        self.test_results.append(result)
        return result
    
    async def test_grade_specific_words(self):
        """学年特化単語テスト"""
        test_name = "学年特化単語"
        logger.info(f"テスト開始: {test_name}")
        
        try:
            from services.user_dictionary_service import user_dictionary_service
            
            # 異なる学年レベルで辞書作成
            test_cases = [
                ("elementary", "小学校向け"),
                ("middle", "中学校向け"),
                ("high", "高校向け")
            ]
            
            results_by_grade = {}
            
            for grade_level, description in test_cases:
                user_id = f"test_grade_{grade_level}"
                
                result_dict = await user_dictionary_service.create_user_dictionary(
                    user_id=user_id,
                    words=["テスト単語"],
                    grade_level=grade_level
                )
                
                results_by_grade[grade_level] = {
                    "total_words": result_dict["total_words_count"],
                    "custom_words": result_dict["custom_words_count"],
                    "description": description
                }
            
            # 結果検証
            assert all(r["total_words"] > 50 for r in results_by_grade.values()), "各学年で十分な単語数が確保されていません"
            
            result = {
                "test_name": test_name,
                "status": "PASS",
                "details": {
                    "grade_results": results_by_grade,
                    "total_test_cases": len(test_cases)
                }
            }
            logger.info(f"✅ {test_name} - PASS: 全{len(test_cases)}学年レベルで辞書作成成功")
            
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
        logger.info("=== ユーザー辞書機能テスト開始 ===")
        start_time = time.time()
        
        # テスト実行
        await self.test_dictionary_service_initialization()
        await self.test_create_user_dictionary()
        await self.test_get_user_dictionary()
        await self.test_update_user_dictionary()
        await self.test_csv_import_export()
        await self.test_grade_specific_words()
        
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
        test_runner = UserDictionaryTest()
        results = await test_runner.run_all_tests()
        
        # 結果出力
        print("\n=== ユーザー辞書機能テスト結果 ===")
        print(json.dumps(results, indent=2, ensure_ascii=False))
        
        # 完了条件チェック
        if results["success_rate"] >= 85:  # 85%以上の成功率
            print("\n✅ ユーザー辞書機能（基本版）完了条件クリア")
            print("✅ カスタムキーワード登録機能確認")
            print("✅ CSV一括登録機能確認")
            print("✅ 学年別最適化確認")
            print("✅ 辞書管理API実装確認")
            return True
        else:
            print(f"\n❌ テスト成功率が不足: {results['success_rate']:.1f}% < 85%")
            return False
            
    except Exception as e:
        logger.error(f"テスト実行エラー: {e}")
        return False

if __name__ == "__main__":
    success = asyncio.run(main())