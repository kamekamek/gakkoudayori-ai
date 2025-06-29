import os
import mimetypes
from typing import List, Optional

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile
from fastapi.responses import JSONResponse

from app.auth import User, get_current_user
from services.storage import upload_image_to_gcs

router = APIRouter(
    prefix="/upload",
    tags=["File Upload"],
)

# 対応する画像形式
SUPPORTED_MIME_TYPES = [
    'image/jpeg',
    'image/jpg', 
    'image/png',
    'image/gif',
    'image/webp',
    'image/bmp',
    'image/tiff',
]

# ファイルサイズ制限（10MB）
MAX_FILE_SIZE = 10 * 1024 * 1024


def validate_image_file(file: UploadFile) -> bool:
    """画像ファイルのバリデーション"""
    # ファイルサイズチェック
    if file.size and file.size > MAX_FILE_SIZE:
        raise HTTPException(
            status_code=400,
            detail=f"ファイルサイズが制限を超えています。最大{MAX_FILE_SIZE // (1024*1024)}MBまでです。"
        )
    
    # MIMEタイプチェック
    if file.content_type not in SUPPORTED_MIME_TYPES:
        raise HTTPException(
            status_code=400,
            detail=f"対応していないファイル形式です。対応形式: {', '.join(SUPPORTED_MIME_TYPES)}"
        )
    
    return True


def get_mime_type_from_filename(filename: str) -> str:
    """ファイル名からMIMEタイプを自動判定"""
    mime_type, _ = mimetypes.guess_type(filename)
    
    # 判定できない場合やサポート外の場合のデフォルト値
    if not mime_type or mime_type not in SUPPORTED_MIME_TYPES:
        # 拡張子による判定
        extension = os.path.splitext(filename)[1].lower()
        mime_type_map = {
            '.jpg': 'image/jpeg',
            '.jpeg': 'image/jpeg',
            '.png': 'image/png',
            '.gif': 'image/gif',
            '.webp': 'image/webp',
            '.bmp': 'image/bmp',
            '.tiff': 'image/tiff',
            '.tif': 'image/tiff',
        }
        mime_type = mime_type_map.get(extension, 'image/jpeg')
    
    return mime_type


@router.post("/images", summary="画像ファイルをアップロード")
async def upload_images(
    files: List[UploadFile] = File(..., description="アップロードする画像ファイル（複数可）"),
    session_id: Optional[str] = Form(None, description="セッションID（オプション）"),
    current_user: User = Depends(get_current_user)
):
    """
    画像ファイルをCloud Storageにアップロードします。
    複数ファイルの同時アップロードに対応しています。
    """
    if not files:
        raise HTTPException(status_code=400, detail="アップロードするファイルが指定されていません。")
    
    # 最大ファイル数チェック
    if len(files) > 10:
        raise HTTPException(status_code=400, detail="一度にアップロードできるファイル数は10個までです。")
    
    try:
        uploaded_files = []
        errors = []
        
        for file in files:
            try:
                # ファイルバリデーション
                validate_image_file(file)
                
                # ファイル内容読み込み
                file_content = await file.read()
                if not file_content:
                    errors.append(f"{file.filename}: ファイルが空です。")
                    continue
                
                # MIMEタイプ自動判定
                detected_mime_type = get_mime_type_from_filename(file.filename)
                
                # GCSにアップロード
                session_id_to_use = session_id or f"user_{current_user.uid}"
                public_url = await upload_image_to_gcs(
                    session_id=session_id_to_use,
                    image_content=file_content,
                    filename=file.filename,
                    content_type=detected_mime_type
                )
                
                uploaded_files.append({
                    "filename": file.filename,
                    "url": public_url,
                    "size": len(file_content),
                    "content_type": detected_mime_type,
                    "session_id": session_id_to_use
                })
                
            except HTTPException:
                # HTTPExceptionはそのまま再発生
                raise
            except Exception as e:
                errors.append(f"{file.filename}: {str(e)}")
                continue
        
        # 結果返却
        if not uploaded_files and errors:
            raise HTTPException(
                status_code=400,
                detail=f"すべてのファイルのアップロードに失敗しました: {'; '.join(errors)}"
            )
        
        response_data = {
            "success": True,
            "uploaded_files": uploaded_files,
            "uploaded_count": len(uploaded_files),
            "total_size": sum(f["size"] for f in uploaded_files)
        }
        
        if errors:
            response_data["warnings"] = errors
            response_data["message"] = f"{len(uploaded_files)}件のファイルをアップロードしました。{len(errors)}件のエラーがあります。"
        else:
            response_data["message"] = f"{len(uploaded_files)}件のファイルを正常にアップロードしました。"
        
        return JSONResponse(content=response_data)
        
    except HTTPException:
        # HTTPExceptionはそのまま再発生
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"画像のアップロード中に予期せぬエラーが発生しました: {str(e)}"
        )


@router.get("/images/{session_id}", summary="セッションの画像一覧を取得")
async def get_session_images(
    session_id: str,
    current_user: User = Depends(get_current_user)
):
    """
    指定されたセッションでアップロードされた画像の一覧を取得します。
    """
    try:
        # TODO: GCSから画像一覧を取得する実装
        # 現在は簡易実装
        return {
            "success": True,
            "session_id": session_id,
            "images": [],
            "message": "画像一覧機能は実装中です。"
        }
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"画像一覧の取得中にエラーが発生しました: {str(e)}"
        )


@router.delete("/images/{session_id}", summary="セッションの画像を削除")
async def delete_session_images(
    session_id: str,
    current_user: User = Depends(get_current_user)
):
    """
    指定されたセッションの画像を削除します。
    """
    try:
        # TODO: GCSから画像を削除する実装
        # 現在は簡易実装
        return {
            "success": True,
            "session_id": session_id,
            "message": "画像削除機能は実装中です。"
        }
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"画像削除中にエラーが発生しました: {str(e)}"
        )