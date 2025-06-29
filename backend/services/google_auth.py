import google.auth
from fastapi import HTTPException


def get_credentials():
    """
    Google Cloudのデフォルト認証情報を取得します。
    アプリケーションのデフォルトクレデンシャル（ADC）が設定されていることを前提とします。
    必要なスコープを自動的に判断します。
    """
    try:
        # スコープを広めに設定しておくことで、他のGoogle APIでも利用可能
        scopes = [
            "https://www.googleapis.com/auth/cloud-platform",
            "https://www.googleapis.com/auth/classroom.announcements",
            "https://www.googleapis.com/auth/drive",
            "https://www.googleapis.com/auth/speech",
        ]
        credentials, project_id = google.auth.default(scopes=scopes)
        return credentials
    except Exception as e:
        raise HTTPException(
            status_code=500, detail=f"Google認証情報の取得に失敗しました: {str(e)}"
        ) from e
