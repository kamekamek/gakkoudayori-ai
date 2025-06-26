from typing import List, Dict, Any

from fastapi import APIRouter, HTTPException
from google.api_core.exceptions import NotFound
from google.cloud import speech_v2
from pydantic import BaseModel

router = APIRouter(
    prefix="/phrase",
    tags=["Speech Adaptation"],
)

# 辞書関連のルーター（フロントエンド互換のため）
dictionary_router = APIRouter(
    prefix="/dictionary",
    tags=["User Dictionary"],
)

class PhraseRequest(BaseModel):
    project_id: str
    phrase_set_id: str
    phrases: List[str]
    boost_value: float = 10.0

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

# デフォルト学校用語辞書（元の実装から移植）
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
    
    # 施設・場所
    "○○小学校": ["まるまるしょうがっこう", "まるまる小学校"],
    "体育館": ["たいいくかん", "たいいく館"],
    "図書室": ["としょしつ", "としょ室"],
    "音楽室": ["おんがくしつ", "おんがく室"],
    "保健室": ["ほけんしつ", "ほけん室"],
    "職員室": ["しょくいんしつ"],
    
    # 感情・評価表現
    "頑張っていました": ["がんばっていました", "頑張っていました"],
    "元気いっぱい": ["げんきいっぱい", "元気いっぱい"],
    "一生懸命": ["いっしょうけんめい", "一生懸命"],
    "協力して": ["きょうりょくして", "協力して"],
    "楽しそうに": ["たのしそうに", "楽しそうに"],
    "上手に": ["じょうずに", "上手に"],
    "素晴らしい": ["すばらしい", "素晴らしい"],
}

@router.post(
    "/",
    summary="ユーザー辞書（フレーズセット）を作成・更新",
    response_description="処理結果"
)
async def register_phrases(req: PhraseRequest):
    """
    音声認識の精度向上のため、ユーザー辞書（フレーズセット）を作成または更新します。
    """
    try:
        client = speech_v2.SpeechAsyncClient()
        phrase_set_name = f"projects/{req.project_id}/locations/global/phraseSets/{req.phrase_set_id}"

        try:
            # 既存のフレーズセットを取得試行
            await client.get_phrase_set(name=phrase_set_name)
            # 存在する場合：更新
            phrase_set = speech_v2.PhraseSet(
                name=phrase_set_name,
                phrases=[{"value": p, "boost": req.boost_value} for p in req.phrases],
            )
            operation = await client.update_phrase_set(phrase_set=phrase_set)
            message = "既存のフレーズセットを更新しました。"
        except NotFound:
            # 存在しない場合：新規作成
            phrase_set = speech_v2.PhraseSet(
                phrases=[{"value": p, "boost": req.boost_value} for p in req.phrases],
            )
            operation = await client.create_phrase_set(
                parent=f"projects/{req.project_id}/locations/global",
                phrase_set_id=req.phrase_set_id,
                phrase_set=phrase_set,
            )
            message = "新しいフレーズセットを作成しました。"

        # オペレーション完了を待機
        await operation.result(timeout=300)

        return {"status": "success", "message": message, "phrase_set_name": phrase_set_name}

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"フレーズセットの登録中に予期せぬエラーが発生しました: {str(e)}"
        )

# ユーザー辞書エンドポイント（フロントエンド互換）
@dictionary_router.get("/{user_id}")
async def get_user_dictionary(user_id: str):
    """ユーザー辞書を取得（フロントエンド互換）"""
    try:
        print(f"📖 Fetching dictionary for user: {user_id}")
        
        # デフォルト辞書を返す（実際の実装ではFirestoreから取得）
        return UserDictionaryResponse(
            success=True,
            data={
                "dictionary": DEFAULT_SCHOOL_TERMS,
                "total_terms": len(DEFAULT_SCHOOL_TERMS),
                "user_id": user_id
            }
        )
    except Exception as e:
        print(f"❌ Error fetching dictionary: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"辞書取得エラー: {str(e)}"
        )

@dictionary_router.post("/{user_id}/terms")
async def add_dictionary_term(user_id: str, term_data: DictionaryTermRequest):
    """辞書に新しい用語を追加"""
    try:
        print(f"➕ Adding term for user {user_id}: {term_data.term} -> {term_data.variations}")
        # 実際の実装ではFirestoreやDBに保存
        return {"success": True, "message": "用語を追加しました"}
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"用語追加エラー: {str(e)}"
        )

@dictionary_router.put("/{user_id}/terms/{term}")
async def update_dictionary_term(user_id: str, term: str, term_data: DictionaryTermRequest):
    """辞書の既存用語を更新"""
    try:
        print(f"✏️ Updating term for user {user_id}: {term} -> {term_data.term}, {term_data.variations}")
        # 実際の実装ではFirestoreやDBで更新
        return {"success": True, "message": "用語を更新しました"}
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"用語更新エラー: {str(e)}"
        )

@dictionary_router.delete("/{user_id}/terms/{term}")
async def delete_dictionary_term(user_id: str, term: str):
    """辞書から用語を削除"""
    try:
        print(f"🗑️ Deleting term for user {user_id}: {term}")
        # 実際の実装ではFirestoreやDBから削除
        return {"success": True, "message": "用語を削除しました"}
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"用語削除エラー: {str(e)}"
        )

@dictionary_router.post("/{user_id}/correct")
async def correct_transcription(user_id: str, request_data: CorrectionRequest):
    """音声認識結果をユーザー辞書で修正"""
    try:
        transcript = request_data.transcript
        print(f"🔧 Correcting transcription for user {user_id}: '{transcript}'")
        
        # サンプル修正処理（実際の実装では辞書を使った置換処理）
        corrected_text = transcript
        corrections = []
        
        # 簡単な修正例
        replacements = {
            "まるまるしょうがっこう": "○○小学校",
            "たいいくかん": "体育館",
            "としょしつ": "図書室",
            "おんがくしつ": "音楽室",
            "ほけんしつ": "保健室",
            "うんどうかい": "運動会",
            "がくしゅうはっぴょうかい": "学習発表会"
        }
        
        for original, corrected in replacements.items():
            if original in corrected_text.lower():
                corrected_text = corrected_text.replace(original, corrected)
                corrections.append({
                    "original": original,
                    "corrected": corrected,
                    "position": corrected_text.find(corrected)
                })
        
        result = {
            "success": True,
            "data": {
                "original_text": transcript,
                "corrected_text": corrected_text,
                "corrections": corrections,
                "processing_time_ms": 50
            }
        }
        
        print(f"✅ Correction result: {len(corrections)} changes made")
        return result
        
    except Exception as e:
        print(f"❌ Error correcting transcription: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"修正処理エラー: {str(e)}"
        )

@dictionary_router.post("/{user_id}/learn")
async def record_manual_correction(user_id: str, correction_data: ManualCorrectionRequest):
    """手動修正を学習用に記録"""
    try:
        print(f"📚 Recording manual correction for user {user_id}: {correction_data.original} -> {correction_data.corrected}")
        # 実際の実装では学習データとしてDBに保存
        return {"success": True, "message": "修正内容を記録しました"}
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"学習記録エラー: {str(e)}"
        )
