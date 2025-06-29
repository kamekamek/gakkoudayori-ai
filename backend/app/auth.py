
import os
from functools import lru_cache

import firebase_admin
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from firebase_admin import auth, credentials
from pydantic import BaseModel


# --- Pydanticモデル定義 ---
class User(BaseModel):
    """認証されたユーザーの情報を格納するモデル"""
    uid: str
    email: str | None = None
    name: str | None = None
    picture: str | None = None

# --- Firebase Admin SDKの初期化 ---
@lru_cache()
def initialize_firebase_app():
    """
    Firebase Admin SDKを初期化する。
    環境変数に応じて認証情報を設定する。
    lru_cacheデコレータにより、この関数は一度しか実行されない。
    """
    try:
        # 環境変数からGCPプロジェクトIDを取得
        project_id = os.getenv("GCP_PROJECT")
        if not project_id:
            # ローカル開発環境などで環境変数が設定されていない場合
            # ADC (Application Default Credentials) から推測する
            try:
                from google.auth import default
                _, project_id = default()
            except Exception as e:
                # 認証情報が取得できない場合は警告を出すが、アプリケーションは継続
                print(f"⚠️ WARNING: Firebase初期化をスキップします: {e}")
                print("⚠️ Firebase認証機能は利用できません。")
                return None

        # サービスアカウントキーのJSON文字列を環境変数から取得
        # Cloud Runなどの本番環境では、サービスアカウントキーファイルではなく
        # 環境変数にJSONを直接設定することが推奨される
        service_account_json = os.getenv("FIREBASE_SERVICE_ACCOUNT_JSON")

        cred_options = {
            "project_id": project_id,
        }
        if service_account_json:
            # 環境変数から認証情報を読み込む
            cred = credentials.Certificate(service_account_json)
        else:
            # 環境変数がない場合 (ローカル開発など) は、ADCを使用
            cred = credentials.ApplicationDefault()
            print("⚠️ WARNING: FIREBASE_SERVICE_ACCOUNT_JSON not found. Using Application Default Credentials.")

        print(f"🔥 Initializing Firebase Admin SDK for project: {project_id}...")
        firebase_admin.initialize_app(credential=cred, options=cred_options)
        print("✅ Firebase Admin SDK initialized successfully.")
    except Exception as e:
        print(f"⚠️ WARNING: Firebase初期化に失敗しました: {e}")
        print("⚠️ Firebase認証機能は利用できません。")
        return None

# アプリケーションの起動時に一度だけ初期化処理を呼び出す
# initialize_firebase_app()


# --- FastAPIの依存性注入 ---
# "token"という名前で、AuthorizationヘッダーからBearerトークンを抽出する
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

async def get_current_user(token: str = Depends(oauth2_scheme)) -> User:
    """
    リクエストヘッダーから受け取ったFirebase IDトークンを検証し、
    対応するユーザー情報を返すFastAPIの依存関係。

    Args:
        token: `OAuth2PasswordBearer`によってヘッダーから抽出されたIDトークン。

    Returns:
        検証済みのユーザー情報を含むUserモデル。

    Raises:
        HTTPException: トークンが無効、または検証に失敗した場合。
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        # Firebase Admin SDKを使用してIDトークンを検証
        decoded_token = auth.verify_id_token(token)
        # デコードされたトークンからユーザー情報を抽出し、Userモデルを作成
        return User(
            uid=decoded_token.get("uid"),
            email=decoded_token.get("email"),
            name=decoded_token.get("name"),
            picture=decoded_token.get("picture"),
        )
    except auth.InvalidIdTokenError:
        # トークンが無効な場合
        print("❌ Invalid Firebase ID token.")
        raise credentials_exception
    except Exception as e:
        # その他のFirebase関連エラー
        print(f"❌ An unexpected error occurred during token verification: {e}")
        raise credentials_exception

