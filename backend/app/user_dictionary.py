import logging
from datetime import datetime
from typing import Any, Dict, List, Optional

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

# Firestoreサービスをインポート
try:
    from google.cloud import firestore

    # 直接Firestoreクライアントを初期化
    db = firestore.AsyncClient()
    firestore_available = True
except Exception as e:
    firestore_available = False
    logging.warning(f"Firestore not available: {e}")

# ユーザー辞書専用のルーター
router = APIRouter(
    prefix="/dictionary",
    tags=["User Dictionary"],
)

logger = logging.getLogger(__name__)


class UserDictionaryResponse(BaseModel):
    success: bool
    data: Dict[str, Any] = None
    error: str = None


class DictionaryTermRequest(BaseModel):
    term: str
    variations: List[str]


class CorrectionRequest(BaseModel):
    transcript: str


class ManualCorrectionRequest(BaseModel):
    original: str
    corrected: str
    context: str = ""


# デフォルト学校用語辞書（元々のuser_dictionary_service.pyから移植）
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
    # 場所・施設
    "体育館": ["たいいくかん", "体育館"],
    "図書室": ["としょしつ", "図書室"],
    "音楽室": ["おんがくしつ", "音楽室"],
    "理科室": ["りかしつ", "理科室"],
    "校庭": ["こうてい", "校庭"],
    "職員室": ["しょくいんしつ", "職員室"],
    "保健室": ["ほけんしつ", "保健室"],
    # 感情・評価表現
    "頑張っていました": ["がんばっていました", "頑張っていました"],
    "元気いっぱい": ["げんきいっぱい", "元気いっぱい"],
    "一生懸命": ["いっしょうけんめい", "一生懸命"],
    "協力して": ["きょうりょくして", "協力して"],
    "楽しそうに": ["たのしそうに", "楽しそうに"],
    "上手に": ["じょうずに", "上手に"],
    "素晴らしい": ["すばらしい", "素晴らしい"],
}


# Firestoreヘルパー関数
async def get_user_custom_dictionary(user_id: str) -> Dict[str, Any]:
    """Firestoreからユーザーのカスタム辞書を取得"""
    if not firestore_available:
        return {}

    try:
        doc_ref = db.collection("user_dictionaries").document(user_id)
        doc = await doc_ref.get()

        if doc.exists:
            data = doc.to_dict()
            return data.get("custom_terms", {})
        return {}
    except Exception as e:
        # ログを控えめに
        return {}


async def save_user_custom_term(user_id: str, term: str, variations: List[str]) -> bool:
    """Firestoreにユーザーのカスタム用語を保存"""
    if not firestore_available:
        return False

    try:
        doc_ref = db.collection("user_dictionaries").document(user_id)

        # 既存データ取得
        doc = await doc_ref.get()
        data = doc.to_dict() if doc.exists else {}

        if "custom_terms" not in data:
            data["custom_terms"] = {}

        # 新しい用語追加
        data["custom_terms"][term] = {
            "variations": variations,
            "created_at": datetime.now().isoformat(),
            "usage_count": 0,
        }
        data["updated_at"] = datetime.now().isoformat()

        # Firestoreへ保存（mergeでなくsetを使用）
        await doc_ref.set(data)
        return True

    except Exception as e:
        # エラーログは最小限に
        return False


async def update_user_custom_term(
    user_id: str, term: str, variations: List[str]
) -> bool:
    """Firestoreのユーザーカスタム用語を更新"""
    if not firestore_available:
        return False

    try:
        doc_ref = db.collection("user_dictionaries").document(user_id)
        doc = await doc_ref.get()

        if not doc.exists:
            return False

        data = doc.to_dict()
        if "custom_terms" not in data or term not in data["custom_terms"]:
            return False

        # 用語更新（created_at は保持）
        data["custom_terms"][term]["variations"] = variations
        data["custom_terms"][term]["updated_at"] = datetime.now().isoformat()
        data["updated_at"] = datetime.now().isoformat()

        await doc_ref.set(data)
        return True

    except Exception as e:
        return False


async def delete_user_custom_term(user_id: str, term: str) -> bool:
    """Firestoreからユーザーカスタム用語を削除"""
    if not firestore_available:
        return False

    try:
        doc_ref = db.collection("user_dictionaries").document(user_id)
        doc = await doc_ref.get()

        if not doc.exists:
            return False

        data = doc.to_dict()
        if "custom_terms" not in data or term not in data["custom_terms"]:
            return False

        # 用語削除
        del data["custom_terms"][term]
        data["updated_at"] = datetime.now().isoformat()

        await doc_ref.set(data)
        return True

    except Exception as e:
        return False


async def record_correction_learning(
    user_id: str, original: str, corrected: str, context: str = ""
) -> bool:
    """ユーザーの修正を学習用に記録"""
    if not firestore_available:
        return False

    try:
        doc_ref = db.collection("user_dictionaries").document(user_id)

        # 既存データ取得
        doc = await doc_ref.get()
        data = doc.to_dict() if doc.exists else {}

        if "correction_history" not in data:
            data["correction_history"] = []

        # 修正履歴追加
        correction_entry = {
            "original": original,
            "corrected": corrected,
            "context": context,
            "timestamp": datetime.now().isoformat(),
            "confidence": 0.9,  # 手動修正なので高い信頼度
        }

        data["correction_history"].append(correction_entry)

        # 履歴が長すぎる場合は古いものを削除（最新1000件保持）
        if len(data["correction_history"]) > 1000:
            data["correction_history"] = data["correction_history"][-1000:]

        data["updated_at"] = datetime.now().isoformat()
        await doc_ref.set(data)
        return True

    except Exception as e:
        return False


@router.get("/{user_id}")
async def get_user_dictionary(user_id: str):
    """ユーザー辞書を取得（デフォルト辞書 + Firestoreのカスタム辞書）"""
    try:
        # デフォルト辞書を基本とする
        combined_dictionary = DEFAULT_SCHOOL_TERMS.copy()

        # Firestoreからカスタム辞書を取得して結合
        custom_terms = await get_user_custom_dictionary(user_id)
        custom_count = 0

        for term, term_data in custom_terms.items():
            if isinstance(term_data, dict) and "variations" in term_data:
                combined_dictionary[term] = term_data["variations"]
                custom_count += 1
            elif isinstance(term_data, list):
                # 古い形式への互換性
                combined_dictionary[term] = term_data
                custom_count += 1

        response_data = {
            "user_id": user_id,
            "dictionary": combined_dictionary,
            "total_terms": len(combined_dictionary),
            "default_terms": len(DEFAULT_SCHOOL_TERMS),
            "custom_terms": custom_count,
            "last_updated": datetime.now().isoformat(),
        }

        return UserDictionaryResponse(success=True, data=response_data)

    except Exception as e:
        return UserDictionaryResponse(
            success=False, error=f"Failed to get user dictionary: {str(e)}"
        )


@router.post("/{user_id}/terms")
async def add_dictionary_term(user_id: str, request: DictionaryTermRequest):
    """辞書に新しい用語を追加（Firestoreに保存）"""
    try:
        # Firestoreに保存
        success = await save_user_custom_term(user_id, request.term, request.variations)

        response_data = {
            "user_id": user_id,
            "term": request.term,
            "variations": request.variations,
            "added_at": datetime.now().isoformat(),
            "saved_to_firestore": success,
        }

        return UserDictionaryResponse(success=True, data=response_data)

    except Exception as e:
        return UserDictionaryResponse(
            success=False, error=f"Failed to add term: {str(e)}"
        )


@router.put("/{user_id}/terms/{term}")
async def update_dictionary_term(
    user_id: str, term: str, request: DictionaryTermRequest
):
    """辞書の用語を更新（Firestoreで更新）"""
    try:
        # Firestoreで更新
        success = await update_user_custom_term(user_id, term, request.variations)

        if not success:
            return UserDictionaryResponse(
                success=False, error=f"Term '{term}' not found or update failed"
            )

        response_data = {
            "user_id": user_id,
            "term": term,
            "new_variations": request.variations,
            "updated_at": datetime.now().isoformat(),
            "updated_in_firestore": success,
        }

        return UserDictionaryResponse(success=True, data=response_data)

    except Exception as e:
        return UserDictionaryResponse(
            success=False, error=f"Failed to update term: {str(e)}"
        )


@router.delete("/{user_id}/terms/{term}")
async def delete_dictionary_term(user_id: str, term: str):
    """辞書から用語を削除（Firestoreから削除）"""
    try:
        # Firestoreから削除
        success = await delete_user_custom_term(user_id, term)

        if not success:
            return UserDictionaryResponse(
                success=False, error=f"Term '{term}' not found or deletion failed"
            )

        response_data = {
            "user_id": user_id,
            "deleted_term": term,
            "deleted_at": datetime.now().isoformat(),
            "deleted_from_firestore": success,
        }

        return UserDictionaryResponse(success=True, data=response_data)

    except Exception as e:
        return UserDictionaryResponse(
            success=False, error=f"Failed to delete term: {str(e)}"
        )


@router.post("/{user_id}/correct")
async def correct_transcript(user_id: str, request: CorrectionRequest):
    """音声認識結果を辞書で補正（デフォルト + カスタム辞書使用）"""
    try:
        # デフォルト + カスタム辞書を取得
        custom_terms = await get_user_custom_dictionary(user_id)
        combined_dictionary = DEFAULT_SCHOOL_TERMS.copy()

        # カスタム辞書を統合
        for term, term_data in custom_terms.items():
            if isinstance(term_data, dict) and "variations" in term_data:
                combined_dictionary[term] = term_data["variations"]
            elif isinstance(term_data, list):
                combined_dictionary[term] = term_data

        # 補正処理
        corrected_text = request.transcript
        corrections_made = []

        for correct_term, variations in combined_dictionary.items():
            for variation in variations:
                if variation in corrected_text:
                    corrected_text = corrected_text.replace(variation, correct_term)
                    corrections_made.append(
                        {
                            "original": variation,
                            "corrected": correct_term,
                            "confidence": 1.0,
                            "source": (
                                "custom" if correct_term in custom_terms else "default"
                            ),
                        }
                    )

        response_data = {
            "user_id": user_id,
            "original_transcript": request.transcript,
            "corrected_transcript": corrected_text,
            "corrections": corrections_made,
            "processed_at": datetime.now().isoformat(),
            "dictionary_size": len(combined_dictionary),
        }

        return UserDictionaryResponse(success=True, data=response_data)

    except Exception as e:
        return UserDictionaryResponse(
            success=False, error=f"Failed to correct transcript: {str(e)}"
        )


@router.post("/{user_id}/learn")
async def record_manual_correction(user_id: str, request: ManualCorrectionRequest):
    """手動修正を記録して学習（Firestoreに保存）"""
    try:
        # Firestoreに学習データを記録
        success = await record_correction_learning(
            user_id, request.original, request.corrected, request.context
        )

        response_data = {
            "user_id": user_id,
            "original": request.original,
            "corrected": request.corrected,
            "context": request.context,
            "recorded_at": datetime.now().isoformat(),
            "saved_to_firestore": success,
        }

        return UserDictionaryResponse(success=True, data=response_data)

    except Exception as e:
        return UserDictionaryResponse(
            success=False, error=f"Failed to record correction: {str(e)}"
        )


@router.get("/{user_id}/contexts")
async def get_speech_contexts(user_id: str):
    """Speech-to-Text用コンテキスト取得（デフォルト + カスタム辞書）"""
    try:
        # デフォルト + カスタム辞書を統合
        custom_terms = await get_user_custom_dictionary(user_id)
        combined_dictionary = DEFAULT_SCHOOL_TERMS.copy()

        for term, term_data in custom_terms.items():
            if isinstance(term_data, dict) and "variations" in term_data:
                combined_dictionary[term] = term_data["variations"]
            elif isinstance(term_data, list):
                combined_dictionary[term] = term_data

        # 全ての辞書用語をコンテキストとして提供
        contexts = []
        for term, variations in combined_dictionary.items():
            contexts.append(term)
            contexts.extend(variations)

        # 重複削除・ソート
        unique_contexts = list(set(contexts))
        unique_contexts.sort()

        default_context_count = sum(
            len([term] + variations)
            for term, variations in DEFAULT_SCHOOL_TERMS.items()
        )
        custom_context_count = 0
        for term, term_data in custom_terms.items():
            if isinstance(term_data, dict) and "variations" in term_data:
                custom_context_count += len([term] + term_data["variations"])
            elif isinstance(term_data, list):
                custom_context_count += len([term] + term_data)

        response_data = {
            "user_id": user_id,
            "contexts": unique_contexts,
            "total_contexts": len(unique_contexts),
            "default_contexts": default_context_count,
            "custom_contexts": custom_context_count,
            "generated_at": datetime.now().isoformat(),
        }

        return UserDictionaryResponse(success=True, data=response_data)

    except Exception as e:
        return UserDictionaryResponse(
            success=False, error=f"Failed to get speech contexts: {str(e)}"
        )
