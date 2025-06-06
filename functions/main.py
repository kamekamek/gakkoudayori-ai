# Welcome to Cloud Functions for Firebase for Python!
# To get started, simply uncomment the below code or create your own.
# Deploy with `firebase deploy`

import os
import json
import tempfile
from datetime import datetime
from typing import Dict, Any

from firebase_functions import https_fn, firestore_fn
from firebase_admin import initialize_app, firestore, storage
from google.cloud import storage as gcs
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload
from google.auth import default
import weasyprint
import requests

# Firebase初期化
initialize_app()

@https_fn.on_request(cors=True)
def generate_pdf(req: https_fn.Request) -> https_fn.Response:
    """HTML文書からPDFを生成する"""
    try:
        # リクエストデータの取得
        data = req.get_json()
        if not data or 'html_content' not in data:
            return https_fn.Response(
                json.dumps({'error': 'html_content is required'}),
                status=400,
                headers={'Content-Type': 'application/json'}
            )
        
        html_content = data['html_content']
        document_id = data.get('document_id', 'unknown')
        
        # WeasyPrintでPDF生成
        with tempfile.NamedTemporaryFile(suffix='.pdf', delete=False) as tmp_file:
            pdf_document = weasyprint.HTML(string=html_content)
            pdf_document.write_pdf(tmp_file.name)
            
            # Cloud Storageに保存
            bucket = storage.bucket()
            blob_name = f"pdfs/{document_id}/{datetime.now().strftime('%Y%m%d_%H%M%S')}.pdf"
            blob = bucket.blob(blob_name)
            
            with open(tmp_file.name, 'rb') as pdf_file:
                blob.upload_from_file(pdf_file, content_type='application/pdf')
            
            # 署名付きURLの生成（1時間有効）
            download_url = blob.generate_signed_url(
                expiration=datetime.utcnow().replace(hour=datetime.utcnow().hour + 1)
            )
            
            os.unlink(tmp_file.name)
            
            return https_fn.Response(
                json.dumps({
                    'success': True,
                    'pdf_url': download_url,
                    'blob_name': blob_name
                }),
                headers={'Content-Type': 'application/json'}
            )
            
    except Exception as e:
        return https_fn.Response(
            json.dumps({'error': str(e)}),
            status=500,
            headers={'Content-Type': 'application/json'}
        )

@https_fn.on_request(cors=True)
def upload_to_drive(req: https_fn.Request) -> https_fn.Response:
    """Google DriveにPDFをアップロードする"""
    try:
        data = req.get_json()
        if not data or 'blob_name' not in data:
            return https_fn.Response(
                json.dumps({'error': 'blob_name is required'}),
                status=400,
                headers={'Content-Type': 'application/json'}
            )
        
        blob_name = data['blob_name']
        file_name = data.get('file_name', 'untitled.pdf')
        folder_name = data.get('folder_name', datetime.now().strftime('%Y/%m'))
        
        # Cloud StorageからPDFファイルを取得
        bucket = storage.bucket()
        blob = bucket.blob(blob_name)
        
        with tempfile.NamedTemporaryFile(suffix='.pdf') as tmp_file:
            blob.download_to_filename(tmp_file.name)
            
            # Google Drive API認証
            credentials, project = default()
            service = build('drive', 'v3', credentials=credentials)
            
            # フォルダ作成または取得
            folder_id = get_or_create_folder(service, folder_name)
            
            # ファイルをDriveにアップロード
            file_metadata = {
                'name': file_name,
                'parents': [folder_id]
            }
            
            media = MediaFileUpload(tmp_file.name, mimetype='application/pdf')
            file = service.files().create(
                body=file_metadata,
                media_body=media,
                fields='id,webViewLink,webContentLink'
            ).execute()
            
            # 共有設定（誰でも表示可能）
            permission = {
                'type': 'anyone',
                'role': 'reader'
            }
            service.permissions().create(
                fileId=file.get('id'),
                body=permission
            ).execute()
            
            return https_fn.Response(
                json.dumps({
                    'success': True,
                    'file_id': file.get('id'),
                    'view_link': file.get('webViewLink'),
                    'download_link': file.get('webContentLink')
                }),
                headers={'Content-Type': 'application/json'}
            )
            
    except Exception as e:
        return https_fn.Response(
            json.dumps({'error': str(e)}),
            status=500,
            headers={'Content-Type': 'application/json'}
        )

def get_or_create_folder(service, folder_path: str) -> str:
    """Google Driveにフォルダを作成または取得する"""
    folder_parts = folder_path.split('/')
    parent_id = 'root'
    
    for folder_name in folder_parts:
        # 既存フォルダを検索
        query = f"name='{folder_name}' and parents in '{parent_id}' and mimeType='application/vnd.google-apps.folder'"
        results = service.files().list(q=query).execute()
        items = results.get('files', [])
        
        if items:
            parent_id = items[0]['id']
        else:
            # フォルダを作成
            folder_metadata = {
                'name': folder_name,
                'parents': [parent_id],
                'mimeType': 'application/vnd.google-apps.folder'
            }
            folder = service.files().create(body=folder_metadata).execute()
            parent_id = folder.get('id')
    
    return parent_id

@firestore_fn.on_document_created(document="documents/{documentId}")
def on_document_created(event: firestore_fn.Event[firestore_fn.DocumentSnapshot]) -> None:
    """新しいドキュメントが作成された時の処理"""
    try:
        # ドキュメントデータの取得
        document_data = event.data.to_dict()
        document_id = event.params['documentId']
        
        # Firestoreに初期メタデータを追加
        db = firestore.client()
        db.collection('documents').document(document_id).update({
            'createdAt': firestore.SERVER_TIMESTAMP,
            'updatedAt': firestore.SERVER_TIMESTAMP,
            'status': 'draft',
            'version': 1
        })
        
        print(f"Document {document_id} initialized successfully")
        
    except Exception as e:
        print(f"Error initializing document {document_id}: {str(e)}")

@firestore_fn.on_document_updated(document="documents/{documentId}")
def on_document_updated(event: firestore_fn.Event[firestore_fn.Change[firestore_fn.DocumentSnapshot]]) -> None:
    """ドキュメントが更新された時の処理"""
    try:
        document_id = event.params['documentId']
        before_data = event.data.before.to_dict() if event.data.before.exists else {}
        after_data = event.data.after.to_dict() if event.data.after.exists else {}
        
        # バージョン管理
        if before_data.get('content') != after_data.get('content'):
            version = before_data.get('version', 0) + 1
            
            # 履歴を保存
            db = firestore.client()
            db.collection('documents').document(document_id).collection('versions').add({
                'content': before_data.get('content'),
                'version': before_data.get('version', 0),
                'createdAt': firestore.SERVER_TIMESTAMP,
                'updatedBy': before_data.get('userId')
            })
            
            # バージョン番号を更新
            db.collection('documents').document(document_id).update({
                'version': version,
                'updatedAt': firestore.SERVER_TIMESTAMP
            })
        
        print(f"Document {document_id} updated successfully")
        
    except Exception as e:
        print(f"Error updating document {document_id}: {str(e)}")

@https_fn.on_request(cors=True)
def health_check(req: https_fn.Request) -> https_fn.Response:
    """ヘルスチェックエンドポイント"""
    return https_fn.Response(
        json.dumps({
            'status': 'healthy',
            'timestamp': datetime.now().isoformat(),
            'functions': [
                'generate_pdf',
                'upload_to_drive',
                'on_document_created',
                'on_document_updated'
            ]
        }),
        headers={'Content-Type': 'application/json'}
    )