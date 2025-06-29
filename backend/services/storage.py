import asyncio
import datetime
import os
from functools import lru_cache

from google.cloud import storage


@lru_cache()
def get_storage_client() -> storage.Client:
    """Cloud Storageクライアントのシングルトンインスタンスを返す"""
    return storage.Client()

bucket_name = os.environ.get("GCS_BUCKET_NAME", "gakkoudayori-newsletters")


def _upload_and_get_url_sync(pdf_bytes: bytes, destination_blob_name: str) -> str:
    """
    【同期】GCSへアップロードし、署名付きURLを取得する内部関数。
    ブロッキングI/Oを別スレッドで実行するために使用します。
    """
    storage_client = get_storage_client()
    bucket = storage_client.bucket(bucket_name)
    blob = bucket.blob(destination_blob_name)

    # アップロード処理（ブロッキングI/O）
    blob.upload_from_string(pdf_bytes, content_type="application/pdf")

    # 署名付きURLの生成（CPU処理）
    expiration = datetime.timedelta(days=1)
    signed_url = blob.generate_signed_url(
        version="v4", expiration=expiration, method="GET"
    )
    return signed_url


async def save_pdf_to_gcs(pdf_bytes: bytes, destination_blob_name: str) -> str:
    """
    PDFのバイトデータをGCSに非同期でアップロードし、署名付きURLを返します。
    """
    loop = asyncio.get_running_loop()
    # ブロッキングI/O処理を別スレッドで実行し、イベントループの停止を防ぐ
    signed_url = await loop.run_in_executor(
        None,  # デフォルトのThreadPoolExecutorを使用
        _upload_and_get_url_sync,
        pdf_bytes,
        destination_blob_name,
    )
    return signed_url


async def upload_image_to_gcs(
    session_id: str, image_content: bytes, filename: str
) -> str:
    """
    ユーザーがアップロードした画像をGCSに保存し、公開URLを返します。

    Args:
        session_id: 現在のセッションID。
        image_content: 画像ファイルのバイトデータ。
        filename: 元のファイル名。

    Returns:
        画像の公開URL。
    """
    storage_client = get_storage_client()
    bucket = storage_client.bucket(bucket_name)
    # ファイル名が重複しないように、セッションIDとタイムスタンプをパスに含める
    blob = bucket.blob(
        f"user_images/{session_id}/{datetime.datetime.utcnow().isoformat()}_{filename}"
    )

    # TODO: content_typeを動的に判定する
    await blob.upload_from_string(image_content, content_type="image/jpeg")  # 仮

    # バケットが公開設定されていることを前提とします
    return blob.public_url
