import os
import datetime
from google.cloud import storage

# 環境変数からバケット名を取得。設定がなければデフォルト値を使用。
BUCKET_NAME = os.environ.get("GCS_BUCKET_NAME", "gakkoudayori-assets")

storage_client = storage.AsyncClient()

async def save_pdf_to_gcs(session_id: str, pdf_content: bytes) -> str:
    """
    生成されたPDFをGoogle Cloud Storageにアップロードし、署名付きURLを返します。

    Args:
        session_id: 現在のセッションID。ファイルパスに使用。
        pdf_content: PDFファイルのバイトデータ。

    Returns:
        ダウンロード用の署名付きURL。1日間有効。
    """
    bucket = storage_client.bucket(BUCKET_NAME)
    blob = bucket.blob(f"generated_pdfs/{session_id}/{datetime.datetime.utcnow().isoformat()}.pdf")

    await blob.upload_from_string(
        pdf_content,
        content_type="application/pdf"
    )

    signed_url = blob.generate_signed_url(
        version="v4",
        expiration=datetime.timedelta(days=1),
        method="GET",
    )
    return signed_url

async def upload_image_to_gcs(session_id: str, image_content: bytes, filename: str) -> str:
    """
    ユーザーがアップロードした画像をGCSに保存し、公開URLを返します。

    Args:
        session_id: 現在のセッションID。
        image_content: 画像ファイルのバイトデータ。
        filename: 元のファイル名。

    Returns:
        画像の公開URL。
    """
    bucket = storage_client.bucket(BUCKET_NAME)
    # ファイル名が重複しないように、セッションIDとタイムスタンプをパスに含める
    blob = bucket.blob(f"user_images/{session_id}/{datetime.datetime.utcnow().isoformat()}_{filename}")

    # TODO: content_typeを動的に判定する
    await blob.upload_from_string(
        image_content,
        content_type="image/jpeg" # 仮
    )
    
    # バケットが公開設定されていることを前提とします
    return blob.public_url
