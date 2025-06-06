"""
PDF生成APIエンドポイント
"""
from fastapi import APIRouter, HTTPException, Depends, BackgroundTasks
from fastapi.responses import Response
from pydantic import BaseModel
from typing import Optional, Dict, Any
import tempfile
import os
from datetime import datetime

from services.pdf_service import pdf_service, PdfGenerationResult
from services.cloud_storage_service import cloud_storage_service
from config.gcloud_config import cloud_config

router = APIRouter(prefix="/api/v1/pdf", tags=["PDF生成"])


class PdfGenerationRequest(BaseModel):
    """PDF生成リクエスト"""
    html_content: str
    css_content: Optional[str] = None
    options: Optional[Dict[str, Any]] = None


class NewsletterPdfRequest(BaseModel):
    """学級通信PDF生成リクエスト"""
    title: str
    content: str
    teacher_name: str
    class_name: str
    date: Optional[str] = None
    season_theme: str = "spring"
    user_id: str
    save_to_storage: bool = True


class PdfResponse(BaseModel):
    """PDF生成レスポンス"""
    success: bool
    file_url: Optional[str] = None
    file_path: Optional[str] = None
    processing_time_ms: Optional[int] = None
    error_message: Optional[str] = None


@router.post("/generate", response_model=PdfResponse)
async def generate_pdf(request: PdfGenerationRequest):
    """
    HTMLからPDF生成
    """
    if not pdf_service:
        raise HTTPException(
            status_code=500,
            detail="PDF生成サービスが利用できません。WeasyPrintがインストールされていない可能性があります。"
        )
    
    try:
        result = pdf_service.generate_pdf_from_html(
            html_content=request.html_content,
            css_content=request.css_content,
            options=request.options
        )
        
        if not result.success:
            raise HTTPException(
                status_code=500,
                detail=result.error_message or "PDF生成に失敗しました"
            )
        
        # PDFデータをBase64エンコードしてレスポンス
        # 本番環境では署名付きURLまたはCloud Storageを使用
        return PdfResponse(
            success=True,
            processing_time_ms=result.processing_time_ms
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"PDF生成エラー: {str(e)}"
        )


@router.post("/newsletter", response_model=PdfResponse)
async def generate_newsletter_pdf(request: NewsletterPdfRequest, background_tasks: BackgroundTasks):
    """
    学級通信PDF生成・保存
    """
    if not pdf_service:
        raise HTTPException(
            status_code=500,
            detail="PDF生成サービスが利用できません"
        )
    
    try:
        # 日付設定
        date = request.date or datetime.now().strftime("%Y年%m月%d日")
        
        # PDF生成
        result = pdf_service.generate_newsletter_pdf(
            title=request.title,
            content=request.content,
            teacher_name=request.teacher_name,
            class_name=request.class_name,
            date=date,
            season_theme=request.season_theme
        )
        
        if not result.success:
            raise HTTPException(
                status_code=500,
                detail=result.error_message or "学級通信PDF生成に失敗しました"
            )
        
        file_url = None
        file_path = None
        
        # Cloud Storageに保存
        if request.save_to_storage and result.pdf_data:
            filename = f"{request.title}_{date.replace('年', '').replace('月', '').replace('日', '')}.pdf"
            
            upload_result = cloud_storage_service.upload_file(
                file_content=result.pdf_data,
                filename=filename,
                user_id=request.user_id,
                file_type="pdf",
                content_type="application/pdf"
            )
            
            if upload_result.success:
                file_url = upload_result.file_url
                file_path = upload_result.file_path
            
            # バックグラウンドでGoogle Driveにも保存
            if file_path:
                background_tasks.add_task(
                    save_to_google_drive,
                    file_path,
                    filename,
                    request.user_id
                )
        
        return PdfResponse(
            success=True,
            file_url=file_url,
            file_path=file_path,
            processing_time_ms=result.processing_time_ms
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"学級通信PDF生成エラー: {str(e)}"
        )


@router.get("/download/{file_path:path}")
async def download_pdf(file_path: str):
    """
    PDFファイルダウンロード
    """
    try:
        # Cloud Storageからファイル取得
        pdf_data = cloud_storage_service.download_file(file_path)
        
        # ファイル名抽出
        filename = file_path.split('/')[-1]
        
        return Response(
            content=pdf_data,
            media_type="application/pdf",
            headers={
                "Content-Disposition": f"attachment; filename={filename}",
                "Content-Type": "application/pdf"
            }
        )
        
    except FileNotFoundError:
        raise HTTPException(
            status_code=404,
            detail="PDFファイルが見つかりません"
        )
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"PDFダウンロードエラー: {str(e)}"
        )


@router.post("/preview")
async def generate_pdf_preview(request: PdfGenerationRequest):
    """
    PDF生成プレビュー（Base64エンコード）
    """
    if not pdf_service:
        raise HTTPException(
            status_code=500,
            detail="PDF生成サービスが利用できません"
        )
    
    try:
        result = pdf_service.generate_pdf_from_html(
            html_content=request.html_content,
            css_content=request.css_content,
            options=request.options
        )
        
        if not result.success:
            raise HTTPException(
                status_code=500,
                detail=result.error_message or "PDFプレビュー生成に失敗しました"
            )
        
        # Base64エンコード
        import base64
        pdf_base64 = base64.b64encode(result.pdf_data).decode('utf-8')
        
        return {
            "success": True,
            "pdf_data": pdf_base64,
            "processing_time_ms": result.processing_time_ms
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"PDFプレビュー生成エラー: {str(e)}"
        )


async def save_to_google_drive(file_path: str, filename: str, user_id: str):
    """
    Google Driveに保存（バックグラウンドタスク）
    """
    try:
        # TODO: Google Drive API統合
        # Google Drive APIを使ってファイルを保存
        print(f"Google Driveへの保存をスケジュール: {filename} (ユーザー: {user_id})")
        
        # 実装例:
        # drive_service = get_drive_service()
        # drive_service.upload_file(file_path, filename, user_id)
        
    except Exception as e:
        print(f"Google Drive保存エラー: {e}")


# ヘルスチェック
@router.get("/health")
async def pdf_service_health():
    """PDF生成サービスのヘルスチェック"""
    return {
        "status": "healthy" if pdf_service else "unavailable",
        "weasyprint_available": pdf_service is not None,
        "timestamp": datetime.now().isoformat()
    }