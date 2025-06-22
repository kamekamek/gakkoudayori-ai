import logging
import os
from typing import Dict, Any, Optional

from fastapi import APIRouter, HTTPException, Body
from pydantic import BaseModel, Field

from services.audio_to_json_service import convert_speech_to_json as speech_to_json_service
from services.json_to_graphical_record_service import convert_json_to_graphical_record
from services.pdf_generator import generate_pdf_from_html, get_pdf_info, _clean_html_for_pdf

logger = logging.getLogger(__name__)
router = APIRouter()

# --- Pydantic Models ---

class SpeechToJsonBody(BaseModel):
    transcribed_text: str = Field(..., description="構造化する文字起こしテキスト")
    style: str = Field("classic", description="生成するJSONのスタイル")
    custom_context: str = Field("", description="追加のコンテキスト情報")
    use_adk: bool = Field(False, description="ADKマルチエージェントを使用するかどうか")
    teacher_profile: Dict[str, Any] = Field({}, description="教師のプロファイル情報")

class JsonToGraphicalRecordBody(BaseModel):
    json_data: Dict[str, Any] = Field(..., description="HTMLに変換するJSONデータ")
    template: str = Field("classic", description="使用するHTMLテンプレート")
    custom_style: str = Field("", description="追加のカスタムCSSスタイル")

class GeneratePdfBody(BaseModel):
    html_content: str = Field(..., description="PDFに変換するHTMLコンテンツ")
    title: str = Field("学級通信", description="PDFのタイトル")
    page_size: str = Field("A4", description="ページサイズ")
    margin: str = Field("15mm", description="余白")
    include_header: bool = Field(False, description="ヘッダーを含めるか")
    include_footer: bool = Field(False, description="フッターを含めるか")
    custom_css: str = Field("", description="追加のカスタムCSS")

classApiResponse(BaseModel):
    success: bool
    data: Optional[Dict[str, Any]] = None
    error: Optional[str] = None
    error_code: Optional[str] = None

# --- API Endpoints ---

@router.post(
    "/speech-to-json",
    response_model=ApiResponse,
    summary="文字起こしテキストをJSONに構造化",
)
async def convert_speech_to_json(body: SpeechToJsonBody):
    """文字起こしされたテキストを、グラレコ生成に適したJSON形式に変換します。"""
    try:
        credentials_path = None if os.getenv('K_SERVICE') else os.getenv('GOOGLE_APPLICATION_CREDENTIALS')
        project_id = os.getenv('GOOGLE_CLOUD_PROJECT', 'gakkoudayori-ai')

        result = speech_to_json_service(
            transcribed_text=body.transcribed_text,
            project_id=project_id,
            credentials_path=credentials_path,
            style=body.style,
            custom_context=body.custom_context,
            use_adk=body.use_adk,
            teacher_profile=body.teacher_profile
        )
        if not result.get("success"):
            raise HTTPException(status_code=400, detail=result)
        return result
    except Exception as e:
        logger.error(f"Speech to JSON conversion error: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail={"success": False, "error": str(e), "error_code": "INTERNAL_ERROR"})


@router.post(
    "/json-to-graphical-record",
    response_model=ApiResponse,
    summary="JSONをHTMLグラレコに変換",
)
async def handle_json_to_graphical_record(body: JsonToGraphicalRecordBody):
    """構造化されたJSONデータを、HTML形式のグラフィカルレコードに変換します。"""
    try:
        credentials_path = None if os.getenv('K_SERVICE') else os.getenv('GOOGLE_APPLICATION_CREDENTIALS')
        project_id = os.getenv('GOOGLE_CLOUD_PROJECT', 'gakkoudayori-ai')

        result = convert_json_to_graphical_record(
            json_data=body.json_data,
            project_id=project_id,
            credentials_path=credentials_path,
            template=body.template,
            custom_style=body.custom_style,
            max_output_tokens=8192
        )
        if not result.get("success"):
            raise HTTPException(status_code=400, detail=result)
        return result
    except Exception as e:
        logger.error(f"JSON to graphical record error: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail={"success": False, "error": str(e), "error_code": "INTERNAL_SERVER_ERROR"})


@router.post(
    "/generate-pdf",
    response_model=ApiResponse,
    summary="HTMLをPDFに変換",
)
async def generate_pdf(body: GeneratePdfBody):
    """HTMLコンテンツからPDFファイルを生成し、Base64エンコードされた文字列として返します。"""
    try:
        html_content = _clean_html_for_pdf(body.html_content)
        result = generate_pdf_from_html(
            html_content=html_content,
            title=body.title,
            page_size=body.page_size,
            margin=body.margin,
            include_header=body.include_header,
            include_footer=body.include_footer,
            custom_css=body.custom_css
        )
        if not result.get("success"):
            raise HTTPException(status_code=500, detail=result)
        return result
    except Exception as e:
        logger.error(f"PDF generation error: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail={"success": False, "error": str(e), "error_code": "PDF_GENERATION_ERROR"})


@router.get(
    "/pdf-info/{pdf_id}",
    response_model=ApiResponse,
    summary="PDF情報の取得（ダミー）",
)
async def get_pdf_info_endpoint(pdf_id: str):
    """指定されたIDのPDF情報を取得します（現在はダミー実装）。"""
    try:
        pdf_path = f"/tmp/{pdf_id}.pdf"
        result = get_pdf_info(pdf_path)
        if not result['success']:
            raise HTTPException(status_code=404, detail=result)
        return result
    except Exception as e:
        logger.error(f"PDF info error for {pdf_id}: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail={"success": False, "error": str(e), "error_code": "PDF_INFO_ERROR"}) 