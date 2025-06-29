import pytest
from pytest_mock import MockerFixture


@pytest.fixture(autouse=True)
def mock_google_cloud_apis(mocker: MockerFixture):
    """
    テスト実行中にGoogle Cloud関連のAPI初期化を自動的にモックする。
    """
    # Firebase Admin SDKの初期化をモック
    mocker.patch('firebase_admin.initialize_app', return_value=None)

    # Firebase IDトークン検証をモック
    mocker.patch(
        'firebase_admin.auth.verify_id_token',
        return_value={
            'uid': 'test_uid',
            'email': 'test@example.com',
            'name': 'Test User',
            'picture': 'https://example.com/test.jpg'
        }
    )

    # Firestoreクライアントの取得関数をモック
    mocker.patch('services.firestore_service.get_db_client', return_value=mocker.MagicMock())

    # Storageクライアントの取得関数をモック
    mocker.patch('services.storage.get_storage_client', return_value=mocker.MagicMock())
