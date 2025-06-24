from google.cloud import speech_v1p1beta1 as speech
from google.api_core.exceptions import AlreadyExists
from typing import List

async def register_user_dictionary(
    project_id: str,
    phrase_set_id: str,
    phrases: List[str],
    boost_value: float = 10.0
) -> dict:
    """
    フレーズセットを作成または更新します。
    """
    client = speech.AdaptationClient()
    location = "global"
    parent = f"projects/{project_id}/locations/{location}"
    phrase_set_path = client.phrase_set_path(project_id, location, phrase_set_id)

    phrase_set_payload = speech.PhraseSet(
        name=phrase_set_path,
        phrases=[speech.PhraseSet.Phrase(value=p, boost_value=boost_value) for p in phrases]
    )

    try:
        # まず作成を試みる
        response = client.create_phrase_set(
            parent=parent,
            phrase_set_id=phrase_set_id,
            phrase_set=phrase_set_payload,
        )
        return {"status": "success", "name": response.name, "action": "created"}
    except AlreadyExists:
        # 既に存在する場合は更新する
        try:
            updated_response = client.update_phrase_set(
                phrase_set=phrase_set_payload
            )
            return {"status": "success", "name": updated_response.name, "action": "updated"}
        except Exception as e:
            return {"status": "error", "message": f"既存フレーズセットの更新に失敗しました: {str(e)}"}
    except Exception as e:
        return {"status": "error", "message": f"フレーズセットの作成中にエラーが発生しました: {str(e)}"}
