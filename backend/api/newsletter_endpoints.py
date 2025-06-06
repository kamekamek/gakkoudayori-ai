"""
学級通信統合APIエンドポイント
音声入力→Gemini編集→HTMLエディタ→PDF生成→Classroom配信の全フロー
"""
from fastapi import APIRouter, HTTPException, BackgroundTasks, Depends
from pydantic import BaseModel
from typing import Optional, List, Dict, Any
from datetime import datetime
import asyncio

from services.ai_service import ai_service
from services.pdf_service import pdf_service
from services.classroom_service import get_classroom_service
from services.cloud_storage_service import cloud_storage_service
from services.speech_service import speech_service

router = APIRouter(prefix="/api/v1/newsletter", tags=["学級通信統合"])


class VoiceToNewsletterRequest(BaseModel):
    """音声→学級通信変換リクエスト"""
    user_id: str
    teacher_name: str
    class_name: str
    title: Optional[str] = None
    season_theme: str = "spring"
    custom_instruction: Optional[str] = "やさしい語り口で"
    user_dictionary: List[str] = []
    
    # 音声ファイル（Base64エンコード）
    audio_data: Optional[str] = None
    audio_filename: Optional[str] = None
    
    # 直接テキスト入力
    text_input: Optional[str] = None


class NewsletterGenerationRequest(BaseModel):
    """学級通信生成リクエスト"""
    user_id: str
    title: str
    content: str  # HTMLコンテンツ
    teacher_name: str
    class_name: str
    season_theme: str = "spring"
    
    # 配信設定
    generate_pdf: bool = True
    save_to_storage: bool = True
    post_to_classroom: bool = False
    classroom_course_id: Optional[str] = None
    send_line_notification: bool = False


class NewsletterResponse(BaseModel):
    """学級通信生成レスポンス"""
    success: bool
    newsletter_id: Optional[str] = None
    
    # 生成物
    html_content: Optional[str] = None
    pdf_url: Optional[str] = None
    
    # 配信結果
    storage_path: Optional[str] = None
    classroom_post_id: Optional[str] = None
    classroom_url: Optional[str] = None
    
    # 処理時間
    processing_stats: Optional[Dict[str, int]] = None
    error_message: Optional[str] = None


@router.post("/voice-to-newsletter", response_model=NewsletterResponse)
async def create_newsletter_from_voice(
    request: VoiceToNewsletterRequest,
    background_tasks: BackgroundTasks
):
    """
    音声入力から学級通信を自動生成
    
    フロー:
    1. 音声→テキスト変換（Speech-to-Text + ユーザー辞書）
    2. Geminiでリライト・見出し生成
    3. HTMLグラレコ風テンプレート適用
    4. PDF生成
    5. Cloud Storage保存
    6. (オプション) Classroom投稿
    """
    try:
        start_time = datetime.now()
        processing_stats = {}
        
        # 1. 音声認識 または テキスト入力
        if request.audio_data:
            # 音声ファイルをデコード
            import base64
            audio_bytes = base64.b64decode(request.audio_data)
            
            # 音声認識
            stt_start = _get_current_time_ms()
            transcription_result = await speech_service.transcribe_audio(
                audio_content=audio_bytes,
                user_dictionary=request.user_dictionary,
                language_code="ja-JP"
            )
            processing_stats["speech_to_text_ms"] = _get_current_time_ms() - stt_start
            
            if not transcription_result.success:
                raise HTTPException(
                    status_code=400,
                    detail=f"音声認識エラー: {transcription_result.error_message}"
                )
            
            raw_text = transcription_result.transcript
            
        elif request.text_input:
            raw_text = request.text_input
            processing_stats["speech_to_text_ms"] = 0
            
        else:
            raise HTTPException(
                status_code=400,
                detail="音声データまたはテキスト入力が必要です"
            )
        
        # 2. Gemini AIによるリライト・見出し生成
        ai_start = _get_current_time_ms()
        
        # リライト
        rewrite_result = await ai_service.enhance_text(
            text=raw_text,
            style=request.custom_instruction or "やさしい語り口",
            grade_level="elementary"
        )
        
        if not rewrite_result.get("success", False):
            raise HTTPException(
                status_code=500,
                detail="テキストリライトに失敗しました"
            )
        
        enhanced_text = rewrite_result["enhanced_text"]
        
        # 見出し生成
        heading_result = await ai_service.generate_headings(enhanced_text)
        headings = heading_result.get("headings", [])
        
        processing_stats["ai_processing_ms"] = _get_current_time_ms() - ai_start
        
        # 3. HTMLグラレコ風テンプレート生成
        html_start = _get_current_time_ms()
        
        title = request.title or (headings[0] if headings else "学級通信")
        html_content = _generate_graphical_html(
            title=title,
            content=enhanced_text,
            headings=headings,
            season_theme=request.season_theme
        )
        
        processing_stats["html_generation_ms"] = _get_current_time_ms() - html_start
        
        # 4. PDF生成
        pdf_start = _get_current_time_ms()
        
        pdf_result = pdf_service.generate_newsletter_pdf(
            title=title,
            content=html_content,
            teacher_name=request.teacher_name,
            class_name=request.class_name,
            date=datetime.now().strftime("%Y年%m月%d日"),
            season_theme=request.season_theme
        )
        
        if not pdf_result.success:
            raise HTTPException(
                status_code=500,
                detail=f"PDF生成エラー: {pdf_result.error_message}"
            )
        
        processing_stats["pdf_generation_ms"] = _get_current_time_ms() - pdf_start
        
        # 5. Cloud Storage保存
        storage_start = _get_current_time_ms()
        
        filename = f"{title}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.pdf"
        upload_result = cloud_storage_service.upload_file(
            file_content=pdf_result.pdf_data,
            filename=filename,
            user_id=request.user_id,
            file_type="pdf",
            content_type="application/pdf"
        )
        
        if not upload_result.success:
            raise HTTPException(
                status_code=500,
                detail="PDF保存に失敗しました"
            )
        
        processing_stats["storage_upload_ms"] = _get_current_time_ms() - storage_start
        
        # レスポンス構築
        response = NewsletterResponse(
            success=True,
            newsletter_id=f"newsletter_{datetime.now().strftime('%Y%m%d_%H%M%S')}",
            html_content=html_content,
            pdf_url=upload_result.file_url,
            storage_path=upload_result.file_path,
            processing_stats=processing_stats
        )
        
        # バックグラウンドでClassroom投稿（オプション）
        # background_tasks.add_task(
        #     post_to_classroom_background,
        #     request, html_content, pdf_result.pdf_data, response
        # )
        
        return response
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"学級通信生成エラー: {str(e)}"
        )


@router.post("/generate", response_model=NewsletterResponse)
async def generate_newsletter(
    request: NewsletterGenerationRequest,
    background_tasks: BackgroundTasks
):
    """
    HTMLコンテンツから学級通信を生成・配信
    """
    try:
        processing_stats = {}
        
        # PDF生成
        if request.generate_pdf:
            pdf_start = _get_current_time_ms()
            
            pdf_result = pdf_service.generate_newsletter_pdf(
                title=request.title,
                content=request.content,
                teacher_name=request.teacher_name,
                class_name=request.class_name,
                date=datetime.now().strftime("%Y年%m月%d日"),
                season_theme=request.season_theme
            )
            
            if not pdf_result.success:
                raise HTTPException(
                    status_code=500,
                    detail=f"PDF生成エラー: {pdf_result.error_message}"
                )
            
            processing_stats["pdf_generation_ms"] = _get_current_time_ms() - pdf_start
        
        response = NewsletterResponse(
            success=True,
            newsletter_id=f"newsletter_{datetime.now().strftime('%Y%m%d_%H%M%S')}",
            html_content=request.content,
            processing_stats=processing_stats
        )
        
        # Cloud Storage保存
        if request.save_to_storage and request.generate_pdf:
            storage_start = _get_current_time_ms()
            
            filename = f"{request.title}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.pdf"
            upload_result = cloud_storage_service.upload_file(
                file_content=pdf_result.pdf_data,
                filename=filename,
                user_id=request.user_id,
                file_type="pdf",
                content_type="application/pdf"
            )
            
            if upload_result.success:
                response.pdf_url = upload_result.file_url
                response.storage_path = upload_result.file_path
            
            processing_stats["storage_upload_ms"] = _get_current_time_ms() - storage_start
        
        # Classroom投稿
        if request.post_to_classroom and request.classroom_course_id:
            background_tasks.add_task(
                post_to_classroom_background,
                request.classroom_course_id,
                request.title,
                request.content,
                pdf_result.pdf_data if request.generate_pdf else None,
                request.teacher_name,
                request.class_name,
                response
            )
        
        return response
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"学級通信生成エラー: {str(e)}"
        )


@router.get("/templates/graphical")
async def get_graphical_templates():
    """グラレコ風テンプレート一覧を取得"""
    return {
        "templates": [
            {
                "id": "basic_graphical",
                "name": "基本グラレコ風",
                "description": "吹き出しとアイコンを使った親しみやすいデザイン",
                "preview_html": "<div style='font-family: Comic Sans MS; background: linear-gradient(45deg, #fff9e6, #f0f8ff);'>サンプル</div>"
            },
            {
                "id": "seasonal_spring",
                "name": "春テーマ",
                "description": "桜色とグリーンを基調とした春らしいデザイン",
                "preview_html": "<div style='background: linear-gradient(45deg, #ffb6c1, #98fb98);'>🌸 春のお知らせ 🌸</div>"
            },
            {
                "id": "seasonal_summer",
                "name": "夏テーマ",
                "description": "青空とひまわり色の爽やかなデザイン",
                "preview_html": "<div style='background: linear-gradient(45deg, #87ceeb, #ffeb3b);'>☀️ 夏のお知らせ ☀️</div>"
            }
        ]
    }


def _generate_graphical_html(
    title: str,
    content: str,
    headings: List[str],
    season_theme: str
) -> str:
    """グラレコ風HTMLを生成"""
    
    # 季節テーマの色設定
    theme_colors = {
        'spring': {'bg': 'linear-gradient(45deg, #fff9e6, #f0f8ff)', 'accent': '#ffeb3b', 'text': '#4caf50'},
        'summer': {'bg': 'linear-gradient(45deg, #e3f2fd, #fff3e0)', 'accent': '#ff9800', 'text': '#1976d2'},
        'autumn': {'bg': 'linear-gradient(45deg, #fbe9e7, #f3e5f5)', 'accent': '#ff5722', 'text': '#8e24aa'},
        'winter': {'bg': 'linear-gradient(45deg, #e8f5e8, #f3e5f5)', 'accent': '#2196f3', 'text': '#424242'},
    }
    
    colors = theme_colors.get(season_theme, theme_colors['spring'])
    
    # 季節絵文字
    season_emojis = {
        'spring': '🌸',
        'summer': '☀️',
        'autumn': '🍂',
        'winter': '⛄'
    }
    
    emoji = season_emojis.get(season_theme, '🌸')
    
    html_template = f"""
    <div style="font-family: 'Comic Sans MS', cursive; padding: 20px; background: {colors['bg']}; border-radius: 15px; min-height: 600px;">
      <!-- ヘッダー -->
      <div style="text-align: center; margin-bottom: 30px;">
        <div style="background: {colors['accent']}; border-radius: 20px; padding: 15px; box-shadow: 3px 3px 10px rgba(0,0,0,0.1); margin: 0 auto; max-width: 400px; position: relative;">
          <h1 style="margin: 0; color: #333; font-size: 24px; font-weight: bold;">{emoji} {title} {emoji}</h1>
          <div style="position: absolute; bottom: -8px; left: 50%; transform: translateX(-50%); width: 0; height: 0; border-left: 10px solid transparent; border-right: 10px solid transparent; border-top: 10px solid {colors['accent']};"></div>
        </div>
      </div>
      
      <!-- コンテンツセクション -->
      <div style="background: white; border-radius: 15px; padding: 25px; margin-bottom: 20px; box-shadow: 2px 2px 8px rgba(0,0,0,0.05); border: 3px solid {colors['accent']};">
        {_format_content_with_headings(content, headings, colors)}
      </div>
      
      <!-- フッター装飾 -->
      <div style="text-align: center; margin-top: 30px;">
        <div style="background: #f8f9fa; border-radius: 10px; padding: 15px; border: 2px dashed #ccc;">
          <p style="margin: 0; color: #666; font-size: 14px;">✨ ゆとり職員室で作成 ✨</p>
        </div>
      </div>
    </div>
    """
    
    return html_template


def _format_content_with_headings(content: str, headings: List[str], colors: Dict[str, str]) -> str:
    """コンテンツを見出し付きでフォーマット"""
    if not headings:
        return f'<p style="line-height: 1.8; color: #333; font-size: 16px;">{content}</p>'
    
    # 見出しでコンテンツを分割（簡単な実装）
    sections = []
    content_parts = content.split('\n')
    
    for i, heading in enumerate(headings[:3]):  # 最大3つの見出し
        section_content = '\n'.join(content_parts[i*2:(i+1)*2]) if i*2 < len(content_parts) else ""
        
        section_html = f"""
        <div style="margin-bottom: 25px;">
          <h2 style="color: {colors['text']}; font-size: 20px; margin-bottom: 15px; display: flex; align-items: center;">
            <span style="background: {colors['accent']}; border-radius: 50%; width: 30px; height: 30px; display: inline-flex; align-items: center; justify-content: center; margin-right: 10px; font-size: 14px;">📝</span>
            {heading}
          </h2>
          <p style="line-height: 1.8; color: #333; font-size: 16px; margin-left: 40px;">
            {section_content or "内容がここに入ります..."}
          </p>
        </div>
        """
        sections.append(section_html)
    
    return ''.join(sections)


async def post_to_classroom_background(
    course_id: str,
    title: str,
    content: str,
    pdf_data: Optional[bytes],
    teacher_name: str,
    class_name: str,
    response: NewsletterResponse
):
    """Classroom投稿（バックグラウンドタスク）"""
    try:
        classroom_service = get_classroom_service()
        if not classroom_service or not pdf_data:
            return
        
        result = classroom_service.post_newsletter_to_classroom(
            course_id=course_id,
            title=title,
            content=content,
            pdf_data=pdf_data,
            teacher_name=teacher_name,
            class_name=class_name
        )
        
        if result.success:
            response.classroom_post_id = result.post_id
            response.classroom_url = result.shared_url
        
    except Exception as e:
        print(f"Classroom投稿エラー: {e}")


def _get_current_time_ms() -> int:
    """現在時刻をミリ秒で取得"""
    import time
    return int(time.time() * 1000)


# ヘルスチェック
@router.get("/health")
async def newsletter_service_health():
    """学級通信サービスのヘルスチェック"""
    return {
        "status": "healthy",
        "services": {
            "ai_service": ai_service is not None,
            "pdf_service": pdf_service is not None,
            "speech_service": speech_service is not None,
            "storage_service": cloud_storage_service is not None,
            "classroom_service": get_classroom_service() is not None
        },
        "timestamp": datetime.now().isoformat()
    }