from typing import List, Dict, Any
from datetime import datetime

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

# ユーザー辞書専用のルーター
router = APIRouter(
    prefix="/dictionary",
    tags=["User Dictionary"],
)

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

@router.get("/{user_id}")
async def get_user_dictionary(user_id: str):
    """ユーザー辞書を取得"""
    try:
        # 現時点ではデフォルト辞書を返す
        # 将来的にはFirestoreからユーザー固有の辞書を取得
        
        response_data = {
            "user_id": user_id,
            "dictionary": DEFAULT_SCHOOL_TERMS,
            "total_terms": len(DEFAULT_SCHOOL_TERMS),
            "last_updated": datetime.now().isoformat()
        }
        
        return UserDictionaryResponse(
            success=True,
            data=response_data
        )
        
    except Exception as e:
        return UserDictionaryResponse(
            success=False,
            error=f"Failed to get user dictionary: {str(e)}"
        )

@router.post("/{user_id}/terms")
async def add_dictionary_term(user_id: str, request: DictionaryTermRequest):
    """辞書に新しい用語を追加"""
    try:
        # 将来的にはFirestoreに保存
        # 現時点では成功レスポンスのみ返す
        
        response_data = {
            "user_id": user_id,
            "term": request.term,
            "variations": request.variations,
            "added_at": datetime.now().isoformat()
        }
        
        return UserDictionaryResponse(
            success=True,
            data=response_data
        )
        
    except Exception as e:
        return UserDictionaryResponse(
            success=False,
            error=f"Failed to add term: {str(e)}"
        )

@router.put("/{user_id}/terms/{term}")
async def update_dictionary_term(user_id: str, term: str, request: DictionaryTermRequest):
    """辞書の用語を更新"""
    try:
        response_data = {
            "user_id": user_id,
            "term": term,
            "new_variations": request.variations,
            "updated_at": datetime.now().isoformat()
        }
        
        return UserDictionaryResponse(
            success=True,
            data=response_data
        )
        
    except Exception as e:
        return UserDictionaryResponse(
            success=False,
            error=f"Failed to update term: {str(e)}"
        )

@router.delete("/{user_id}/terms/{term}")
async def delete_dictionary_term(user_id: str, term: str):
    """辞書から用語を削除"""
    try:
        response_data = {
            "user_id": user_id,
            "deleted_term": term,
            "deleted_at": datetime.now().isoformat()
        }
        
        return UserDictionaryResponse(
            success=True,
            data=response_data
        )
        
    except Exception as e:
        return UserDictionaryResponse(
            success=False,
            error=f"Failed to delete term: {str(e)}"
        )

@router.post("/{user_id}/correct")
async def correct_transcript(user_id: str, request: CorrectionRequest):
    """音声認識結果を辞書で補正"""
    try:
        # 簡単な補正ロジック（実際にはより高度な処理）
        corrected_text = request.transcript
        corrections_made = []
        
        # デフォルト辞書で補正
        for correct_term, variations in DEFAULT_SCHOOL_TERMS.items():
            for variation in variations:
                if variation in corrected_text:
                    corrected_text = corrected_text.replace(variation, correct_term)
                    corrections_made.append({
                        "original": variation,
                        "corrected": correct_term,
                        "confidence": 1.0
                    })
        
        response_data = {
            "user_id": user_id,
            "original_transcript": request.transcript,
            "corrected_transcript": corrected_text,
            "corrections": corrections_made,
            "processed_at": datetime.now().isoformat()
        }
        
        return UserDictionaryResponse(
            success=True,
            data=response_data
        )
        
    except Exception as e:
        return UserDictionaryResponse(
            success=False,
            error=f"Failed to correct transcript: {str(e)}"
        )

@router.post("/{user_id}/learn")
async def record_manual_correction(user_id: str, request: ManualCorrectionRequest):
    """手動修正を記録して学習"""
    try:
        # 将来的には学習エンジンで処理
        response_data = {
            "user_id": user_id,
            "original": request.original,
            "corrected": request.corrected,
            "context": request.context,
            "recorded_at": datetime.now().isoformat()
        }
        
        return UserDictionaryResponse(
            success=True,
            data=response_data
        )
        
    except Exception as e:
        return UserDictionaryResponse(
            success=False,
            error=f"Failed to record correction: {str(e)}"
        )

@router.get("/{user_id}/contexts")
async def get_speech_contexts(user_id: str):
    """Speech-to-Text用コンテキスト取得"""
    try:
        # 全ての辞書用語をコンテキストとして提供
        contexts = []
        for term, variations in DEFAULT_SCHOOL_TERMS.items():
            contexts.append(term)
            contexts.extend(variations)
        
        # 重複削除
        unique_contexts = list(set(contexts))
        unique_contexts.sort()
        
        response_data = {
            "user_id": user_id,
            "contexts": unique_contexts,
            "total_contexts": len(unique_contexts),
            "generated_at": datetime.now().isoformat()
        }
        
        return UserDictionaryResponse(
            success=True,
            data=response_data
        )
        
    except Exception as e:
        return UserDictionaryResponse(
            success=False,
            error=f"Failed to get speech contexts: {str(e)}"
        )
