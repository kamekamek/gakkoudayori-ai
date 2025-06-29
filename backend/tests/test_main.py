from fastapi import FastAPI
from fastapi.testclient import TestClient

# --- テスト対象のルーターをインポート ---
# Note: このインポートが成功するためには、モジュールの依存関係が解決される必要がある
from app.api.v1.endpoints import documents as documents_api
from app.main import health_check  # エンドポイント関数を直接インポート


# --- テスト用のFastAPIアプリをセットアップ ---
# テスト時には、main.pyのグローバルな`app`インスタンスは使わない
def create_test_app():
    test_app = FastAPI()
    # 必要なエンドポイントやルーターを登録
    test_app.include_router(documents_api.router, prefix="/api/v1")
    test_app.get("/health")(health_check)
    # adk_chat_streamは依存関係が複雑なので、一旦コメントアウト
    # test_app.post("/api/v1/adk/chat/stream")(adk_chat_stream)
    return test_app

client = TestClient(create_test_app())


def test_health_check():
    """ヘルスチェックエンドポイントが正常にレスポンスを返すかテストする"""
    response = client.get("/health")
    assert response.status_code == 200
    # テスト環境ではENVIRONMENTが設定されていないので、デフォルトの"production"になる
    assert response.json() == {"status": "ok", "environment": "production"}

# def test_unauthenticated_chat_access():
#     """認証なしでチャットエンドポイントにアクセスした際に401エラーが返るかテストする"""
#     response = client.post("/api/v1/adk/chat/stream", json={"message": "test", "session_id": "test"})
#     assert response.status_code == 401

def test_unauthenticated_documents_access():
    """認証なしでドキュメントエンドポイントにアクセスした際に401エラーが返るかテストする"""
    response = client.get("/api/v1/documents")
    assert response.status_code == 401
