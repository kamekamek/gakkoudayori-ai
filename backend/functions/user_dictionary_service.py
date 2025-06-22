"""
ユーザー辞書サービス

学校専用用語の管理と音声認識精度向上
"""

import os
import logging
import json
import time
import re
from typing import Dict, List, Optional, Any, Tuple
from datetime import datetime
from dataclasses import dataclass, asdict
from difflib import SequenceMatcher

# Firebase/Firestore関連
try:
    from firebase_admin import firestore
except ImportError:
    firestore = None

# 設定
logger = logging.getLogger(__name__)

@dataclass
class DictionaryTerm:
    """辞書エントリのデータクラス"""
    term: str
    variations: List[str]
    confidence: float = 1.0
    usage_count: int = 0
    phonetic_key: str = ""
    created_at: Optional[datetime] = None
    last_used: Optional[datetime] = None
    
    def to_dict(self) -> Dict[str, Any]:
        """辞書形式に変換"""
        data = asdict(self)
        if self.created_at:
            data['created_at'] = self.created_at.isoformat()
        if self.last_used:
            data['last_used'] = self.last_used.isoformat()
        return data

class JapanesePhoneticMatcher:
    """日本語音韻マッチングクラス"""
    
    def __init__(self):
        # ひらがな・カタカナ変換マップ
        self.hiragana_katakana_map = {
            'あ': 'ア', 'い': 'イ', 'う': 'ウ', 'え': 'エ', 'お': 'オ',
            'か': 'カ', 'き': 'キ', 'く': 'ク', 'け': 'ケ', 'こ': 'コ',
            'が': 'ガ', 'ぎ': 'ギ', 'ぐ': 'グ', 'げ': 'ゲ', 'ご': 'ゴ',
            'さ': 'サ', 'し': 'シ', 'す': 'ス', 'せ': 'セ', 'そ': 'ソ',
            'ざ': 'ザ', 'じ': 'ジ', 'ず': 'ズ', 'ぜ': 'ゼ', 'ぞ': 'ゾ',
            'た': 'タ', 'ち': 'チ', 'つ': 'ツ', 'て': 'テ', 'と': 'ト',
            'だ': 'ダ', 'ぢ': 'ヂ', 'づ': 'ヅ', 'で': 'デ', 'ど': 'ド',
            'な': 'ナ', 'に': 'ニ', 'ぬ': 'ヌ', 'ね': 'ネ', 'の': 'ノ',
            'は': 'ハ', 'ひ': 'ヒ', 'ふ': 'フ', 'へ': 'ヘ', 'ほ': 'ホ',
            'ば': 'バ', 'び': 'ビ', 'ぶ': 'ブ', 'べ': 'ベ', 'ぼ': 'ボ',
            'ぱ': 'パ', 'ぴ': 'ピ', 'ぷ': 'プ', 'ぺ': 'ペ', 'ぽ': 'ポ',
            'ま': 'マ', 'み': 'ミ', 'む': 'ム', 'め': 'メ', 'も': 'モ',
            'や': 'ヤ', 'ゆ': 'ユ', 'よ': 'ヨ',
            'ら': 'ラ', 'り': 'リ', 'る': 'ル', 'れ': 'レ', 'ろ': 'ロ',
            'わ': 'ワ', 'ゐ': 'ヰ', 'ゑ': 'ヱ', 'を': 'ヲ', 'ん': 'ン'
        }
    
    def get_phonetic_key(self, text: str) -> str:
        """テキストを音韻キーに変換"""
        # ひらがなをカタカナに統一
        normalized = ""
        for char in text:
            if char in self.hiragana_katakana_map:
                normalized += self.hiragana_katakana_map[char]
            elif 'ア' <= char <= 'ン':
                normalized += char
            else:
                normalized += char
        return normalized
    
    def calculate_similarity(self, text1: str, text2: str) -> float:
        """音韻類似度を計算"""
        key1 = self.get_phonetic_key(text1)
        key2 = self.get_phonetic_key(text2)
        return SequenceMatcher(None, key1, key2).ratio()

class LearningEngine:
    """ユーザー修正から学習するエンジン"""
    
    def __init__(self, firestore_client=None):
        self.db = firestore_client
        self.phonetic_matcher = JapanesePhoneticMatcher()
    
    def record_correction(self, user_id: str, original: str, corrected: str, context: str = "") -> bool:
        """ユーザーの修正を記録して学習"""
        try:
            if not self.db:
                return False
            
            correction_data = {
                'original': original,
                'corrected': corrected,
                'context': context,
                'timestamp': datetime.now(),
                'confidence': self._calculate_correction_confidence(original, corrected),
                'phonetic_similarity': self.phonetic_matcher.calculate_similarity(original, corrected)
            }
            
            # 修正履歴に追加
            doc_ref = self.db.collection('user_dictionaries').document(user_id)
            doc = doc_ref.get()
            data = doc.to_dict() if doc.exists else {'correction_history': []}
            
            if 'correction_history' not in data:
                data['correction_history'] = []
            
            data['correction_history'].append(correction_data)
            
            # 履歴が長すぎる場合は古いものを削除
            if len(data['correction_history']) > 1000:
                data['correction_history'] = data['correction_history'][-1000:]
            
            doc_ref.set(data, merge=True)
            
            # 自動で辞書エントリを提案
            self._suggest_dictionary_entry(user_id, original, corrected)
            
            logger.info(f"Correction recorded: {original} → {corrected}")
            return True
            
        except Exception as e:
            logger.error(f"Failed to record correction: {e}")
            return False
    
    def _calculate_correction_confidence(self, original: str, corrected: str) -> float:
        """修正の信頼度を計算"""
        # 長さの違い、文字の類似度などから信頼度を算出
        length_ratio = min(len(original), len(corrected)) / max(len(original), len(corrected))
        phonetic_similarity = self.phonetic_matcher.calculate_similarity(original, corrected)
        return (length_ratio + phonetic_similarity) / 2
    
    def _suggest_dictionary_entry(self, user_id: str, original: str, corrected: str):
        """修正から辞書エントリを提案"""
        # 一定の条件を満たす場合、自動で辞書に追加
        confidence = self._calculate_correction_confidence(original, corrected)
        if confidence > 0.7:  # 信頼度が高い場合
            # 既存の辞書サービスを使用して追加
            pass  # 実装は後で追加

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
        self.phonetic_matcher = JapanesePhoneticMatcher()
        self.learning_engine = LearningEngine(firestore_client)
        
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
            
            # DictionaryTermオブジェクトとして保存
            term_obj = DictionaryTerm(
                term=term,
                variations=variations,
                phonetic_key=self.phonetic_matcher.get_phonetic_key(term),
                created_at=datetime.now()
            )
            
            data['custom_terms'][term] = term_obj.to_dict()
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

    def update_custom_term(self, user_id: str, term: str, variations: List[str]) -> bool:
        """
        カスタム用語を更新
        
        Args:
            user_id (str): ユーザーID
            term (str): 更新対象の用語
            variations (List[str]): 新しい読み方のバリエーション
            
        Returns:
            bool: 成功可否
        """
        try:
            if not self.db:
                logger.warning("Firestore client not available")
                return False
            
            doc_ref = self.db.collection('user_dictionaries').document(user_id)
            doc = doc_ref.get()
            
            if not doc.exists:
                logger.warning(f"User dictionary not found for user {user_id}")
                return False
                
            data = doc.to_dict()
            if 'custom_terms' not in data or term not in data['custom_terms']:
                logger.warning(f"Term '{term}' not found in user dictionary for user {user_id}")
                return False
            
            # 用語更新
            term_obj = DictionaryTerm(
                term=term,
                variations=variations,
                phonetic_key=self.phonetic_matcher.get_phonetic_key(term),
                # created_at は既存のものを維持、last_used は更新時に設定も可能
                created_at=datetime.fromisoformat(data['custom_terms'][term]['created_at']) if data['custom_terms'][term].get('created_at') else datetime.now(),
                last_used=datetime.now() # 更新時にも last_used を更新する例
            )
            data['custom_terms'][term] = term_obj.to_dict()
            data['updated_at'] = datetime.now()
            
            doc_ref.set(data)
            
            cache_key = f"dict_{user_id}"
            if cache_key in self.cache:
                del self.cache[cache_key]
            
            logger.info(f"Custom term updated: {term} -> {variations}")
            return True
            
        except Exception as e:
            logger.error(f"Failed to update custom term: {e}")
            return False

    def delete_custom_term(self, user_id: str, term: str) -> bool:
        """
        カスタム用語を削除
        
        Args:
            user_id (str): ユーザーID
            term (str): 削除対象の用語
            
        Returns:
            bool: 成功可否
        """
        try:
            if not self.db:
                logger.warning("Firestore client not available")
                return False
            
            doc_ref = self.db.collection('user_dictionaries').document(user_id)
            doc = doc_ref.get()
            
            if not doc.exists:
                logger.warning(f"User dictionary not found for user {user_id}")
                return False
                
            data = doc.to_dict()
            if 'custom_terms' not in data or term not in data['custom_terms']:
                logger.warning(f"Term '{term}' not found in user dictionary for user {user_id}")
                return False
            
            # 用語削除
            del data['custom_terms'][term]
            data['updated_at'] = datetime.now()
            
            doc_ref.set(data)
            
            cache_key = f"dict_{user_id}"
            if cache_key in self.cache:
                del self.cache[cache_key]
            
            logger.info(f"Custom term deleted: {term}")
            return True
            
        except Exception as e:
            logger.error(f"Failed to delete custom term: {e}")
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
    
    def correct_transcription(self, transcript: str, user_id: str = "default") -> Tuple[str, List[Dict[str, Any]]]:
        """
        文字起こし結果を辞書で補正（高度な音韻マッチング付き）
        
        Args:
            transcript (str): 音声認識結果
            user_id (str): ユーザーID
            
        Returns:
            Tuple[str, List[Dict]]: (補正後のテキスト, 修正詳細リスト)
        """
        try:
            dictionary = self.get_user_dictionary(user_id)
            corrected = transcript
            corrections_made = []
            
            # 1. 完全一致による補正
            for correct_term, variations in dictionary.items():
                for variation in variations:
                    if variation.lower() in corrected.lower():
                        pattern = re.compile(re.escape(variation), re.IGNORECASE)
                        old_corrected = corrected
                        corrected = pattern.sub(correct_term, corrected)
                        
                        if old_corrected != corrected:
                            corrections_made.append({
                                'type': 'exact_match',
                                'original': variation,
                                'corrected': correct_term,
                                'confidence': 1.0
                            })
            
            # 2. 音韻類似による補正（あいまいマッチング）
            corrected, fuzzy_corrections = self._fuzzy_correct(corrected, dictionary)
            corrections_made.extend(fuzzy_corrections)
            
            if corrections_made:
                logger.info(f"Transcription corrections: {len(corrections_made)} changes made")
                # 使用統計を更新
                self._update_usage_stats(user_id, corrections_made)
            
            return corrected, corrections_made
            
        except Exception as e:
            logger.error(f"Failed to correct transcription: {e}")
            return transcript, []
    
    def _fuzzy_correct(self, text: str, dictionary: Dict[str, List[str]]) -> Tuple[str, List[Dict[str, Any]]]:
        """音韻類似による曖昧補正"""
        corrected = text
        corrections = []
        words = text.split()
        
        for i, word in enumerate(words):
            best_match = None
            best_similarity = 0.0
            best_correct_term = ""
            
            # 各辞書エントリと比較
            for correct_term, variations in dictionary.items():
                for variation in variations:
                    similarity = self.phonetic_matcher.calculate_similarity(word, variation)
                    if similarity > best_similarity and similarity > 0.8:  # 閾値80%
                        best_similarity = similarity
                        best_match = variation
                        best_correct_term = correct_term
            
            # 類似度が高い場合は置換
            if best_match and best_similarity > 0.8:
                words[i] = best_correct_term
                corrections.append({
                    'type': 'fuzzy_match',
                    'original': word,
                    'corrected': best_correct_term,
                    'confidence': best_similarity
                })
        
        return ' '.join(words), corrections
    
    def _update_usage_stats(self, user_id: str, corrections: List[Dict[str, Any]]):
        """使用統計を更新"""
        try:
            if not self.db:
                return
            
            doc_ref = self.db.collection('user_dictionaries').document(user_id)
            doc = doc_ref.get()
            data = doc.to_dict() if doc.exists else {'usage_stats': {}}
            
            if 'usage_stats' not in data:
                data['usage_stats'] = {}
            
            for correction in corrections:
                term = correction['corrected']
                if term not in data['usage_stats']:
                    data['usage_stats'][term] = {'count': 0, 'last_used': None}
                
                data['usage_stats'][term]['count'] += 1
                data['usage_stats'][term]['last_used'] = datetime.now().isoformat()
            
            doc_ref.set(data, merge=True)
            
        except Exception as e:
            logger.error(f"Failed to update usage stats: {e}")
    
    
    
    def suggest_corrections(self, text: str, user_id: str = "default") -> List[Dict[str, Any]]:
        """テキストに対する修正候補を提案"""
        dictionary = self.get_user_dictionary(user_id)
        suggestions = []
        words = text.split()
        
        for word in words:
            candidates = []
            for correct_term, variations in dictionary.items():
                for variation in variations:
                    similarity = self.phonetic_matcher.calculate_similarity(word, variation)
                    if 0.6 < similarity < 0.95:  # 微妙に似ている場合に提案
                        candidates.append({
                            'original': word,
                            'suggested': correct_term,
                            'confidence': similarity,
                            'reason': f"'{variation}'との類似度: {similarity:.2f}"
                        })
            
            # 信頼度でソートして上位3つを追加
            candidates.sort(key=lambda x: x['confidence'], reverse=True)
            suggestions.extend(candidates[:3])
        
        return suggestions
    
    def manual_correction(self, user_id: str, original: str, corrected: str, context: str = "") -> bool:
        """手動修正を記録し学習"""
        return self.learning_engine.record_correction(user_id, original, corrected, context)
    
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
    
    print("\n✅ ユーザー辞書サービステスト完了")

if __name__ == '__main__':
    test_user_dictionary_service() 