"""
ユーザー辞書サービス

学校専用用語の管理と音声認識精度向上
"""

import os
import logging
import json
import time
from typing import Dict, List, Optional, Any
from datetime import datetime

# Firebase/Firestore関連
try:
    from firebase_admin import firestore
except ImportError:
    firestore = None

# 設定
logger = logging.getLogger(__name__)

# デフォルト学校用語辞書
DEFAULT_SCHOOL_TERMS = {
    # 行事・イベント
    "運動会": ["うんどうかい", "運動会"],
    "学習発表会": ["がくしゅうはっぴょうかい", "学習発表会"],
    "避難訓練": ["ひなんくんれん", "避難訓練"],
    "参観日": ["さんかんび", "参観日"],
    "遠足": ["えんそく", "遠足"],
    "修学旅行": ["しゅうがくりょこう", "修学旅行"],
    "卒業式": ["そつぎょうしき", "卒業式"],
    "入学式": ["にゅうがくしき", "入学式"],
    "始業式": ["しぎょうしき", "始業式"],
    "終業式": ["しゅうぎょうしき", "終業式"],
    
    # 教育活動
    "授業": ["じゅぎょう", "授業"],
    "休み時間": ["やすみじかん", "休み時間"],
    "給食": ["きゅうしょく", "給食"],
    "掃除時間": ["そうじじかん", "掃除時間"],
    "帰りの会": ["かえりのかい", "帰りの会"],
    "朝の会": ["あさのかい", "朝の会"],
    "学級会": ["がっきゅうかい", "学級会"],
    "委員会": ["いいんかい", "委員会"],
    "クラブ活動": ["クラブかつどう", "クラブ活動"],
    
    # 人物
    "子どもたち": ["こどもたち", "子どもたち", "子供たち"],
    "児童": ["じどう", "児童"],
    "生徒": ["せいと", "生徒"],
    "先生": ["せんせい", "先生"],
    "担任": ["たんにん", "担任"],
    "校長先生": ["こうちょうせんせい", "校長先生"],
    "教頭先生": ["きょうとうせんせい", "教頭先生"],
    "保護者": ["ほごしゃ", "保護者"],
    
    # 教科・学習
    "国語": ["こくご", "国語"],
    "算数": ["さんすう", "算数"],
    "理科": ["りか", "理科"],
    "社会": ["しゃかい", "社会"],
    "体育": ["たいいく", "体育"],
    "音楽": ["おんがく", "音楽"],
    "図工": ["ずこう", "図工"],
    "家庭科": ["かていか", "家庭科"],
    "道徳": ["どうとく", "道徳"],
    "総合": ["そうごう", "総合"],
    
    # 感情・評価表現
    "頑張っていました": ["がんばっていました", "頑張っていました"],
    "元気いっぱい": ["げんきいっぱい", "元気いっぱい"],
    "一生懸命": ["いっしょうけんめい", "一生懸命"],
    "協力して": ["きょうりょくして", "協力して"],
    "楽しそうに": ["たのしそうに", "楽しそうに"],
    "上手に": ["じょうずに", "上手に"],
    "素晴らしい": ["すばらしい", "素晴らしい"],
}

class UserDictionaryService:
    """ユーザー辞書管理サービス"""
    
    def __init__(self, firestore_client=None):
        self.db = firestore_client
        self.cache = {}
        self.cache_timestamp = None
        self.cache_duration = 300  # 5分間キャッシュ
        
    def get_user_dictionary(self, user_id: str = "default") -> Dict[str, List[str]]:
        """
        ユーザー辞書を取得
        
        Args:
            user_id (str): ユーザーID
            
        Returns:
            Dict[str, List[str]]: 辞書データ
        """
        try:
            # キャッシュチェック
            cache_key = f"dict_{user_id}"
            if self._is_cache_valid(cache_key):
                return self.cache[cache_key]
            
            # Firestoreから取得
            custom_terms = self._load_custom_dictionary(user_id)
            
            # デフォルト辞書と結合
            combined_dict = DEFAULT_SCHOOL_TERMS.copy()
            combined_dict.update(custom_terms)
            
            # キャッシュ更新
            self.cache[cache_key] = combined_dict
            self.cache_timestamp = time.time()
            
            logger.info(f"User dictionary loaded: {len(combined_dict)} terms for user {user_id}")
            return combined_dict
            
        except Exception as e:
            logger.error(f"Failed to load user dictionary: {e}")
            return DEFAULT_SCHOOL_TERMS
    
    def add_custom_term(self, user_id: str, term: str, variations: List[str]) -> bool:
        """
        カスタム用語を追加
        
        Args:
            user_id (str): ユーザーID
            term (str): 用語
            variations (List[str]): 読み方のバリエーション
            
        Returns:
            bool: 成功可否
        """
        try:
            if not self.db:
                logger.warning("Firestore client not available")
                return False
            
            # Firestore文書参照
            doc_ref = self.db.collection('user_dictionaries').document(user_id)
            
            # 既存データ取得
            doc = doc_ref.get()
            data = doc.to_dict() if doc.exists else {'custom_terms': {}}
            
            # 新規用語追加
            if 'custom_terms' not in data:
                data['custom_terms'] = {}
            
            data['custom_terms'][term] = variations
            data['updated_at'] = datetime.now()
            
            # Firestore更新
            doc_ref.set(data)
            
            # キャッシュクリア
            cache_key = f"dict_{user_id}"
            if cache_key in self.cache:
                del self.cache[cache_key]
            
            logger.info(f"Custom term added: {term} -> {variations}")
            return True
            
        except Exception as e:
            logger.error(f"Failed to add custom term: {e}")
            return False
    
    def get_speech_contexts(self, user_id: str = "default") -> List[str]:
        """
        Speech-to-Text用コンテキスト取得
        
        Args:
            user_id (str): ユーザーID
            
        Returns:
            List[str]: 認識精度向上用語句リスト
        """
        dictionary = self.get_user_dictionary(user_id)
        
        # 全ての用語を統合
        contexts = []
        for term, variations in dictionary.items():
            contexts.append(term)
            contexts.extend(variations)
        
        # 重複削除・ソート
        unique_contexts = list(set(contexts))
        unique_contexts.sort()
        
        return unique_contexts
    
    def correct_transcription(self, transcript: str, user_id: str = "default") -> str:
        """
        文字起こし結果を辞書で補正
        
        Args:
            transcript (str): 音声認識結果
            user_id (str): ユーザーID
            
        Returns:
            str: 補正後のテキスト
        """
        try:
            dictionary = self.get_user_dictionary(user_id)
            corrected = transcript
            
            corrections_made = []
            
            # 各辞書エントリで補正
            for correct_term, variations in dictionary.items():
                for variation in variations:
                    if variation.lower() in corrected.lower():
                        # 大文字小文字を無視して置換
                        import re
                        pattern = re.compile(re.escape(variation), re.IGNORECASE)
                        old_corrected = corrected
                        corrected = pattern.sub(correct_term, corrected)
                        
                        if old_corrected != corrected:
                            corrections_made.append(f"{variation} → {correct_term}")
            
            if corrections_made:
                logger.info(f"Transcription corrections: {corrections_made}")
            
            return corrected
            
        except Exception as e:
            logger.error(f"Failed to correct transcription: {e}")
            return transcript
    
    def get_dictionary_stats(self, user_id: str = "default") -> Dict[str, Any]:
        """
        辞書統計情報取得
        
        Args:
            user_id (str): ユーザーID
            
        Returns:
            Dict[str, Any]: 統計情報
        """
        dictionary = self.get_user_dictionary(user_id)
        custom_terms = self._load_custom_dictionary(user_id)
        
        return {
            'total_terms': len(dictionary),
            'default_terms': len(DEFAULT_SCHOOL_TERMS),
            'custom_terms': len(custom_terms),
            'total_variations': sum(len(variations) for variations in dictionary.values()),
            'categories': {
                '行事・イベント': len([t for t in dictionary if t in ['運動会', '学習発表会', '避難訓練', '参観日', '遠足']]),
                '教育活動': len([t for t in dictionary if t in ['授業', '休み時間', '給食', '掃除時間']]),
                '人物': len([t for t in dictionary if t in ['子どもたち', '児童', '先生', '担任']]),
                '教科': len([t for t in dictionary if t in ['国語', '算数', '理科', '社会', '体育']]),
            }
        }
    
    def _load_custom_dictionary(self, user_id: str) -> Dict[str, List[str]]:
        """Firestoreからカスタム辞書を読み込み"""
        try:
            if not self.db:
                return {}
            
            doc_ref = self.db.collection('user_dictionaries').document(user_id)
            doc = doc_ref.get()
            
            if doc.exists:
                data = doc.to_dict()
                return data.get('custom_terms', {})
            else:
                return {}
                
        except Exception as e:
            logger.error(f"Failed to load custom dictionary: {e}")
            return {}
    
    def _is_cache_valid(self, cache_key: str) -> bool:
        """キャッシュ有効性確認"""
        if cache_key not in self.cache:
            return False
        
        if self.cache_timestamp is None:
            return False
        
        elapsed = time.time() - self.cache_timestamp
        return elapsed < self.cache_duration


# ==============================================================================
# ユーティリティ関数
# ==============================================================================

def create_user_dictionary_service(firestore_client=None) -> UserDictionaryService:
    """ユーザー辞書サービスのファクトリ関数"""
    return UserDictionaryService(firestore_client)

def test_user_dictionary_service():
    """ユーザー辞書サービステスト"""
    print("=== ユーザー辞書サービステスト ===")
    
    service = UserDictionaryService()
    
    # 1. デフォルト辞書取得
    print("\n1. デフォルト辞書取得...")
    dictionary = service.get_user_dictionary("test_user")
    print(f"   辞書サイズ: {len(dictionary)} terms")
    print(f"   サンプル: {list(dictionary.keys())[:5]}")
    
    # 2. Speech-to-Textコンテキスト生成
    print("\n2. Speech-to-Textコンテキスト生成...")
    contexts = service.get_speech_contexts("test_user")
    print(f"   コンテキスト数: {len(contexts)}")
    print(f"   サンプル: {contexts[:10]}")
    
    # 3. 文字起こし補正テスト
    print("\n3. 文字起こし補正テスト...")
    test_transcript = "きょうは うんどうかい の れんしゅう を しました"
    corrected = service.correct_transcription(test_transcript, "test_user")
    print(f"   元: {test_transcript}")
    print(f"   補正: {corrected}")
    
    # 4. 統計情報
    print("\n4. 辞書統計...")
    stats = service.get_dictionary_stats("test_user")
    print(f"   統計: {stats}")
    
    print("\n✅ ユーザー辞書サービステスト完了")

if __name__ == '__main__':
    test_user_dictionary_service() 