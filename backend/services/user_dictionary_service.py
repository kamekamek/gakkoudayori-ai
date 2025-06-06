"""
ユーザー辞書機能サービス
音声認識精度向上のためのカスタム単語管理
"""
import time
import asyncio
import json
from typing import Dict, List, Optional, Any
import logging
import csv
import io

from config.gcloud_config import cloud_config

# ログ設定
logger = logging.getLogger(__name__)

class UserDictionaryService:
    """ユーザー辞書管理サービスクラス"""
    
    def __init__(self):
        """ユーザー辞書サービス初期化"""
        self.project_id = cloud_config.project_id
        
        # 基本的な学校用語辞書
        self.base_school_terms = [
            # 学校組織・役職
            "学級通信", "学年通信", "学校便り", "保護者会", "PTA",
            "担任", "学年主任", "教頭", "校長", "養護教諭",
            "事務職員", "用務員", "スクールカウンセラー",
            
            # 学習・授業関連
            "算数", "国語", "理科", "社会", "体育", "図工", "音楽", "道徳",
            "外国語活動", "総合的な学習", "特別活動", "生活科",
            "授業参観", "個人面談", "家庭訪問", "研究授業",
            
            # 行事・イベント
            "運動会", "体育祭", "文化祭", "学習発表会", "音楽会",
            "遠足", "修学旅行", "社会科見学", "校外学習",
            "入学式", "卒業式", "始業式", "終業式",
            "避難訓練", "引き渡し訓練", "防犯教室", "交通安全教室",
            
            # 学年・クラス
            "1年生", "2年生", "3年生", "4年生", "5年生", "6年生",
            "1組", "2組", "3組", "4組", "低学年", "中学年", "高学年",
            
            # 教材・設備
            "教科書", "ノート", "ワークブック", "ドリル", "プリント",
            "タブレット", "パソコン", "電子黒板", "プロジェクター",
            "体操着", "上履き", "ランドセル", "給食着",
            
            # 生活指導・安全
            "生活指導", "学級会", "委員会活動", "クラブ活動",
            "登校班", "下校指導", "見守り活動", "集団下校",
            "欠席", "遅刻", "早退", "保健室", "けが", "体調不良"
        ]
        
        logger.info(f"ユーザー辞書サービス初期化成功: {len(self.base_school_terms)}語のベース辞書")
    
    async def create_user_dictionary(
        self,
        user_id: str,
        words: List[str],
        school_name: Optional[str] = None,
        grade_level: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        ユーザー辞書を作成・更新
        
        Args:
            user_id: ユーザーID
            words: 追加する単語リスト
            school_name: 学校名（追加単語として含める）
            grade_level: 学年レベル（関連用語を追加）
            
        Returns:
            Dict containing dictionary creation results
        """
        try:
            start_time = time.time()
            
            # ユーザー固有の単語を追加
            custom_words = []
            if words:
                custom_words.extend([word.strip() for word in words if word.strip()])
            
            # 学校名関連の単語を追加
            if school_name:
                school_words = self._generate_school_specific_words(school_name)
                custom_words.extend(school_words)
            
            # 学年レベル関連の単語を追加
            if grade_level:
                grade_words = self._get_grade_specific_words(grade_level)
                custom_words.extend(grade_words)
            
            # ベース辞書と結合し、重複を除去
            all_words = list(set(custom_words + self.base_school_terms))
            
            # 最大500単語に制限（Speech-to-Text API制限）
            final_words = all_words[:500]
            
            # 辞書データ構造
            dictionary = {
                "user_id": user_id,
                "words": final_words,
                "custom_words": custom_words,
                "base_words_count": len(self.base_school_terms),
                "custom_words_count": len(custom_words),
                "total_words_count": len(final_words),
                "school_name": school_name,
                "grade_level": grade_level,
                "created_at": int(time.time()),
                "updated_at": int(time.time())
            }
            
            # TODO: Firestoreに保存（Phase 1で実装予定）
            # await self._save_to_firestore(user_id, dictionary)
            
            # 暫定的にメモリ内保存（開発用）
            await self._save_to_memory(user_id, dictionary)
            
            elapsed_time = time.time() - start_time
            
            logger.info(f"ユーザー辞書作成成功: {user_id}, {len(final_words)}語, {elapsed_time:.3f}s")
            return dictionary
            
        except Exception as e:
            logger.error(f"ユーザー辞書作成失敗: {e}")
            raise RuntimeError(f"Failed to create user dictionary: {str(e)}")
    
    async def get_user_dictionary(self, user_id: str) -> Dict[str, Any]:
        """
        ユーザー辞書を取得
        
        Args:
            user_id: ユーザーID
            
        Returns:
            Dict containing user dictionary
        """
        try:
            # TODO: Firestoreから取得（Phase 1で実装予定）
            # dictionary = await self._get_from_firestore(user_id)
            
            # 暫定的にメモリから取得（開発用）
            dictionary = await self._get_from_memory(user_id)
            
            if not dictionary:
                # デフォルト辞書を返す
                dictionary = {
                    "user_id": user_id,
                    "words": self.base_school_terms[:100],  # 基本用語の一部
                    "custom_words": [],
                    "base_words_count": len(self.base_school_terms),
                    "custom_words_count": 0,
                    "total_words_count": len(self.base_school_terms),
                    "school_name": None,
                    "grade_level": None,
                    "created_at": int(time.time()),
                    "updated_at": int(time.time())
                }
            
            logger.info(f"ユーザー辞書取得成功: {user_id}, {dictionary['total_words_count']}語")
            return dictionary
            
        except Exception as e:
            logger.error(f"ユーザー辞書取得失敗: {e}")
            raise RuntimeError(f"Failed to get user dictionary: {str(e)}")
    
    async def update_user_dictionary(
        self,
        user_id: str,
        new_words: List[str],
        remove_words: Optional[List[str]] = None
    ) -> Dict[str, Any]:
        """
        ユーザー辞書を更新
        
        Args:
            user_id: ユーザーID
            new_words: 追加する単語リスト
            remove_words: 削除する単語リスト
            
        Returns:
            Dict containing updated dictionary
        """
        try:
            # 既存辞書を取得
            current_dict = await self.get_user_dictionary(user_id)
            
            # 現在のカスタム単語リスト
            custom_words = set(current_dict.get("custom_words", []))
            
            # 新しい単語を追加
            if new_words:
                custom_words.update([word.strip() for word in new_words if word.strip()])
            
            # 指定された単語を削除
            if remove_words:
                for word in remove_words:
                    custom_words.discard(word.strip())
            
            # 辞書を再作成
            updated_dict = await self.create_user_dictionary(
                user_id=user_id,
                words=list(custom_words),
                school_name=current_dict.get("school_name"),
                grade_level=current_dict.get("grade_level")
            )
            
            logger.info(f"ユーザー辞書更新成功: {user_id}, +{len(new_words or [])}語, -{len(remove_words or [])}語")
            return updated_dict
            
        except Exception as e:
            logger.error(f"ユーザー辞書更新失敗: {e}")
            raise RuntimeError(f"Failed to update user dictionary: {str(e)}")
    
    async def import_from_csv(
        self,
        user_id: str,
        csv_content: str
    ) -> Dict[str, Any]:
        """
        CSVファイルから単語を一括インポート
        
        Args:
            user_id: ユーザーID
            csv_content: CSVファイルの内容
            
        Returns:
            Dict containing import results
        """
        try:
            # CSVを解析
            csv_reader = csv.reader(io.StringIO(csv_content))
            imported_words = []
            
            for row in csv_reader:
                if row and len(row) > 0:
                    word = row[0].strip()
                    if word and word not in imported_words:
                        imported_words.append(word)
            
            # 既存辞書を更新
            updated_dict = await self.update_user_dictionary(
                user_id=user_id,
                new_words=imported_words
            )
            
            result = {
                "imported_words_count": len(imported_words),
                "imported_words": imported_words[:10],  # 最初の10語のみ表示
                "total_words_after_import": updated_dict["total_words_count"],
                "import_time": int(time.time())
            }
            
            logger.info(f"CSV一括インポート成功: {user_id}, {len(imported_words)}語")
            return result
            
        except Exception as e:
            logger.error(f"CSV一括インポート失敗: {e}")
            raise RuntimeError(f"Failed to import from CSV: {str(e)}")
    
    async def export_to_csv(self, user_id: str) -> str:
        """
        ユーザー辞書をCSV形式でエクスポート
        
        Args:
            user_id: ユーザーID
            
        Returns:
            CSV format string
        """
        try:
            dictionary = await self.get_user_dictionary(user_id)
            
            # CSVコンテンツを生成
            output = io.StringIO()
            csv_writer = csv.writer(output)
            
            # ヘッダー行
            csv_writer.writerow(["単語", "タイプ", "追加日時"])
            
            # カスタム単語
            for word in dictionary.get("custom_words", []):
                csv_writer.writerow([word, "カスタム", ""])
            
            # ベース単語（一部のみ）
            for word in self.base_school_terms[:50]:  # 代表的な50語
                csv_writer.writerow([word, "基本", ""])
            
            csv_content = output.getvalue()
            output.close()
            
            logger.info(f"CSV エクスポート成功: {user_id}")
            return csv_content
            
        except Exception as e:
            logger.error(f"CSV エクスポート失敗: {e}")
            raise RuntimeError(f"Failed to export to CSV: {str(e)}")
    
    def _generate_school_specific_words(self, school_name: str) -> List[str]:
        """学校名に基づく関連単語を生成"""
        school_words = []
        
        if school_name:
            # 学校名自体
            school_words.append(school_name)
            
            # 学校名の略称パターン
            if "小学校" in school_name:
                short_name = school_name.replace("小学校", "小")
                school_words.append(short_name)
            
            # よくある学校関連の単語パターン
            base_name = school_name.replace("小学校", "").replace("中学校", "").replace("高等学校", "")
            if base_name:
                school_words.extend([
                    f"{base_name}っ子",
                    f"{base_name}小",
                    f"{base_name}祭り"
                ])
        
        return school_words
    
    def _get_grade_specific_words(self, grade_level: str) -> List[str]:
        """学年レベルに応じた専門用語を取得"""
        grade_words = []
        
        grade_mapping = {
            "elementary": [
                "ひらがな", "カタカナ", "漢字練習", "九九", "かけ算",
                "たし算", "ひき算", "わり算", "生活科", "図画工作",
                "学級会", "当番活動", "給食当番", "掃除当番"
            ],
            "middle": [
                "部活動", "定期テスト", "進路指導", "職業体験",
                "英語", "技術家庭科", "美術", "音楽", "保健体育"
            ],
            "high": [
                "進路選択", "大学受験", "就職活動", "インターンシップ",
                "選択科目", "文理選択", "模擬試験", "進学指導"
            ]
        }
        
        if grade_level in grade_mapping:
            grade_words.extend(grade_mapping[grade_level])
        
        return grade_words
    
    async def _save_to_memory(self, user_id: str, dictionary: Dict[str, Any]) -> None:
        """メモリ内にユーザー辞書を保存（開発用）"""
        if not hasattr(self, '_memory_storage'):
            self._memory_storage = {}
        
        self._memory_storage[user_id] = dictionary
    
    async def _get_from_memory(self, user_id: str) -> Optional[Dict[str, Any]]:
        """メモリからユーザー辞書を取得（開発用）"""
        if not hasattr(self, '_memory_storage'):
            return None
        
        return self._memory_storage.get(user_id)
    
    async def _save_to_firestore(self, user_id: str, dictionary: Dict[str, Any]) -> None:
        """Firestoreにユーザー辞書を保存（Phase 1で実装予定）"""
        # TODO: Firestore実装
        pass
    
    async def _get_from_firestore(self, user_id: str) -> Optional[Dict[str, Any]]:
        """Firestoreからユーザー辞書を取得（Phase 1で実装予定）"""
        # TODO: Firestore実装
        return None

# グローバルサービスインスタンス
user_dictionary_service = UserDictionaryService()