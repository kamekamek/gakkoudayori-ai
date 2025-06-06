from fastapi import FastAPI, HTTPException, Depends, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from typing import Dict, Any, Optional
import uvicorn
import os
import io
import time
from dotenv import load_dotenv

# 環境変数を読み込み
load_dotenv()

from auth import get_current_user, optional_auth, firebase_auth

# FastAPIアプリケーション初期化
app = FastAPI(
    title="ゆとり職員室 API",
    description="グラレコ風学級通信作成システム",
    version="1.0.0"
)

# CORS設定
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",  # Flutter Web dev server
        "http://localhost:5000",  # 本番用
        "https://yutori-kyoshitu.web.app",  # Firebase Hosting
        "https://yutori-kyoshitu.firebaseapp.com",  # Firebase Hosting
    ],
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["*"],
)

# ヘルスチェックエンドポイント (タスク完了条件)
@app.get("/health")
async def health_check():
    """
    APIサーバーの動作確認用エンドポイント
    """
    return {
        "status": "healthy",
        "service": "yutori-kyoshitu-api"
    }

# Auth endpoints
@app.get("/auth/me")
async def get_me(current_user: Dict[str, Any] = Depends(get_current_user)):
    """現在のユーザー情報を取得"""
    try:
        # Firebase からユーザーの詳細情報を取得
        user_details = await firebase_auth.get_user_by_uid(current_user['uid'])
        
        return {
            "uid": current_user['uid'],
            "email": current_user['email'],
            "name": current_user.get('name'),
            "picture": current_user.get('picture'),
            "email_verified": current_user.get('email_verified', False),
            "user_details": user_details
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get user info: {str(e)}")

@app.post("/auth/verify")
async def verify_token(current_user: Dict[str, Any] = Depends(get_current_user)):
    """トークンの有効性を検証"""
    return {
        "valid": True,
        "uid": current_user['uid'],
        "email": current_user['email']
    }

# Document management endpoints (認証必須)
@app.get("/documents")
async def get_documents(current_user: Dict[str, Any] = Depends(get_current_user)):
    """ユーザーのドキュメント一覧を取得"""
    # TODO: Firestore からドキュメント一覧を取得
    return {
        "documents": [],
        "user_id": current_user['uid']
    }

@app.post("/documents")
async def create_document(
    request: Request,
    current_user: Dict[str, Any] = Depends(get_current_user)
):
    """新しいドキュメントを作成"""
    try:
        body = await request.json()
        title = body.get('title', 'Untitled')
        content = body.get('content', '')
        
        # TODO: Firestore にドキュメントを保存
        document_id = f"doc_{current_user['uid']}_{len(title)}"
        
        return {
            "document_id": document_id,
            "title": title,
            "created_by": current_user['uid'],
            "status": "created"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to create document: {str(e)}")

@app.get("/documents/{document_id}")
async def get_document(
    document_id: str,
    current_user: Dict[str, Any] = Depends(get_current_user)
):
    """特定のドキュメントを取得"""
    # TODO: Firestore からドキュメントを取得
    # TODO: アクセス権限チェック
    return {
        "document_id": document_id,
        "title": "Sample Document",
        "content": "<h1>サンプルコンテンツ</h1>",
        "owner": current_user['uid'],
        "created_at": "2024-01-01T00:00:00Z",
        "updated_at": "2024-01-01T00:00:00Z"
    }

@app.put("/documents/{document_id}")
async def update_document(
    document_id: str,
    request: Request,
    current_user: Dict[str, Any] = Depends(get_current_user)
):
    """ドキュメントを更新"""
    try:
        body = await request.json()
        title = body.get('title')
        content = body.get('content')
        
        # TODO: Firestore でドキュメントを更新
        # TODO: アクセス権限チェック
        
        return {
            "document_id": document_id,
            "updated": True,
            "updated_by": current_user['uid']
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to update document: {str(e)}")

@app.delete("/documents/{document_id}")
async def delete_document(
    document_id: str,
    current_user: Dict[str, Any] = Depends(get_current_user)
):
    """ドキュメントを削除"""
    # TODO: Firestore からドキュメントを削除
    # TODO: アクセス権限チェック
    return {
        "document_id": document_id,
        "deleted": True,
        "deleted_by": current_user['uid']
    }

# AI processing endpoints (認証必須)
@app.post("/ai/speech-to-text")
async def speech_to_text(
    request: Request,
    current_user: Dict[str, Any] = Depends(get_current_user)
):
    """音声をテキストに変換（ノイズ抑制機能込み）"""
    try:
        # リクエストボディから音声データとオプションを取得
        form_data = await request.form()
        audio_file = form_data.get('audio')
        custom_words = form_data.get('custom_words', '').split(',') if form_data.get('custom_words') else []
        noise_reduction = form_data.get('noise_reduction', 'true').lower() == 'true'
        
        if not audio_file:
            raise HTTPException(status_code=400, detail="音声ファイルが指定されていません")
        
        # 音声ファイルを読み込み
        audio_content = await audio_file.read()
        
        # Speech-to-Text サービスを呼び出し
        from services.speech_service import speech_service
        
        result = await speech_service.transcribe_audio(
            audio_content=audio_content,
            custom_words=custom_words,
            noise_reduction=noise_reduction
        )
        
        # ユーザー情報を追加
        result['processed_by'] = current_user['uid']
        
        return {
            "status": "success",
            "data": result,
            "message": "音声認識が完了しました"
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to process speech: {str(e)}")

@app.post("/ai/stream-speech-to-text")
async def stream_speech_to_text(
    request: Request,
    current_user: Dict[str, Any] = Depends(get_current_user)
):
    """リアルタイム音声認識（ストリーミング）"""
    try:
        form_data = await request.form()
        audio_file = form_data.get('audio')
        custom_words = form_data.get('custom_words', '').split(',') if form_data.get('custom_words') else []
        
        if not audio_file:
            raise HTTPException(status_code=400, detail="音声ストリームが指定されていません")
        
        from services.speech_service import speech_service
        
        result = await speech_service.stream_recognize_audio(
            audio_stream=audio_file.file,
            custom_words=custom_words
        )
        
        result['processed_by'] = current_user['uid']
        
        return {
            "status": "success",
            "data": result,
            "message": "ストリーミング音声認識が完了しました"
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to stream speech: {str(e)}")

@app.post("/ai/user-dictionary")
async def create_user_dictionary(
    request: Request,
    current_user: Dict[str, Any] = Depends(get_current_user)
):
    """ユーザー辞書を作成・更新"""
    try:
        body = await request.json()
        words = body.get('words', [])
        school_name = body.get('school_name')
        grade_level = body.get('grade_level', 'elementary')
        
        if not words:
            raise HTTPException(status_code=400, detail="辞書に追加する単語が指定されていません")
        
        from services.user_dictionary_service import user_dictionary_service
        
        result = await user_dictionary_service.create_user_dictionary(
            user_id=current_user['uid'],
            words=words,
            school_name=school_name,
            grade_level=grade_level
        )
        
        return {
            "status": "success",
            "data": result,
            "message": "ユーザー辞書が作成されました"
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to create user dictionary: {str(e)}")

@app.get("/ai/user-dictionary")
async def get_user_dictionary(
    current_user: Dict[str, Any] = Depends(get_current_user)
):
    """ユーザー辞書を取得"""
    try:
        from services.user_dictionary_service import user_dictionary_service
        
        result = await user_dictionary_service.get_user_dictionary(current_user['uid'])
        
        return {
            "status": "success",
            "data": result,
            "message": "ユーザー辞書を取得しました"
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get user dictionary: {str(e)}")

@app.put("/ai/user-dictionary")
async def update_user_dictionary(
    request: Request,
    current_user: Dict[str, Any] = Depends(get_current_user)
):
    """ユーザー辞書を更新（単語追加・削除）"""
    try:
        body = await request.json()
        new_words = body.get('new_words', [])
        remove_words = body.get('remove_words', [])
        
        from services.user_dictionary_service import user_dictionary_service
        
        result = await user_dictionary_service.update_user_dictionary(
            user_id=current_user['uid'],
            new_words=new_words,
            remove_words=remove_words
        )
        
        return {
            "status": "success",
            "data": result,
            "message": "ユーザー辞書が更新されました"
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to update user dictionary: {str(e)}")

@app.post("/ai/user-dictionary/import-csv")
async def import_dictionary_csv(
    request: Request,
    current_user: Dict[str, Any] = Depends(get_current_user)
):
    """CSVファイルからユーザー辞書を一括インポート"""
    try:
        form_data = await request.form()
        csv_file = form_data.get('csv_file')
        
        if not csv_file:
            raise HTTPException(status_code=400, detail="CSVファイルが指定されていません")
        
        csv_content = (await csv_file.read()).decode('utf-8')
        
        from services.user_dictionary_service import user_dictionary_service
        
        result = await user_dictionary_service.import_from_csv(
            user_id=current_user['uid'],
            csv_content=csv_content
        )
        
        return {
            "status": "success",
            "data": result,
            "message": "CSVから辞書をインポートしました"
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to import CSV: {str(e)}")

@app.get("/ai/user-dictionary/export-csv")
async def export_dictionary_csv(
    current_user: Dict[str, Any] = Depends(get_current_user)
):
    """ユーザー辞書をCSV形式でエクスポート"""
    try:
        from services.user_dictionary_service import user_dictionary_service
        from fastapi.responses import StreamingResponse
        
        csv_content = await user_dictionary_service.export_to_csv(current_user['uid'])
        
        return StreamingResponse(
            io.StringIO(csv_content),
            media_type="text/csv",
            headers={"Content-Disposition": "attachment; filename=user_dictionary.csv"}
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to export CSV: {str(e)}")

@app.post("/ai/enhance-text")
async def enhance_text(
    request: Request,
    current_user: Dict[str, Any] = Depends(get_current_user)
):
    """Gemini APIでテキストを学級通信風に変換"""
    try:
        body = await request.json()
        text = body.get('text', '')
        style = body.get('style', 'friendly')
        custom_instruction = body.get('custom_instruction')
        grade_level = body.get('grade_level', 'elementary')
        
        from services.ai_service import ai_service
        
        result = await ai_service.rewrite_text(
            original_text=text,
            style=style,
            custom_instruction=custom_instruction,
            grade_level=grade_level
        )
        
        # ユーザー情報を追加
        result['processed_by'] = current_user['uid']
        
        return {
            "status": "success",
            "data": result,
            "message": "テキストリライトが完了しました"
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to enhance text: {str(e)}")

@app.post("/ai/generate-layout")
async def generate_layout(
    request: Request,
    current_user: Dict[str, Any] = Depends(get_current_user)
):
    """コンテンツに基づいてレイアウトを自動生成"""
    try:
        body = await request.json()
        content = body.get('content', '')
        season = body.get('season', 'current')
        event_type = body.get('event_type')
        
        from services.ai_service import ai_service
        
        result = await ai_service.optimize_layout(
            content=content,
            season=season,
            event_type=event_type
        )
        
        # ユーザー情報を追加
        result['generated_by'] = current_user['uid']
        
        return {
            "status": "success",
            "data": result,
            "message": "レイアウト最適化が完了しました"
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to generate layout: {str(e)}")

@app.post("/ai/generate-headlines")
async def generate_headlines(
    request: Request,
    current_user: Dict[str, Any] = Depends(get_current_user)
):
    """コンテンツから見出しを自動生成（トピック分割・適切な見出し候補提示）"""
    try:
        body = await request.json()
        content = body.get('content', '')
        max_headlines = body.get('max_headlines', 5)
        topic_type = body.get('topic_type')  # 'event', 'study', 'announcement', 'daily'
        grade_level = body.get('grade_level', 'elementary')
        style = body.get('style', 'friendly')  # 'friendly', 'formal', 'energetic'
        
        if not content.strip():
            raise HTTPException(status_code=400, detail="コンテンツが空です")
        
        from services.ai_service import ai_service
        
        result = await ai_service.generate_headlines(
            content=content,
            max_headlines=max_headlines,
            topic_type=topic_type,
            grade_level=grade_level,
            style=style
        )
        
        # ユーザー情報を追加
        result['generated_by'] = current_user['uid']
        
        return {
            "status": "success",
            "data": result,
            "message": "見出し生成が完了しました"
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to generate headlines: {str(e)}")

@app.post("/ai/analyze-topics")
async def analyze_content_topics(
    request: Request,
    current_user: Dict[str, Any] = Depends(get_current_user)
):
    """コンテンツのトピック分析"""
    try:
        body = await request.json()
        content = body.get('content', '')
        
        if not content.strip():
            raise HTTPException(status_code=400, detail="コンテンツが空です")
        
        from services.ai_service import ai_service
        
        # トピック分析を実行
        topic_analysis = await ai_service._analyze_content_topics(content)
        
        result = {
            "content_preview": content[:100] + "..." if len(content) > 100 else content,
            "topic_analysis": topic_analysis,
            "analyzed_by": current_user['uid'],
            "timestamp": int(time.time())
        }
        
        return {
            "status": "success",
            "data": result,
            "message": "トピック分析が完了しました"
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to analyze topics: {str(e)}")

# カスタム指示機能エンドポイント
@app.post("/ai/apply-custom-instruction")
async def apply_custom_instruction(
    request: Request,
    current_user: Dict[str, Any] = Depends(get_current_user)
):
    """カスタム指示を適用してテキストを変換"""
    try:
        body = await request.json()
        original_text = body.get('original_text', '')
        instruction_id = body.get('instruction_id')  # プリセット指示ID
        custom_instruction = body.get('custom_instruction')  # カスタム指示文
        intensity = body.get('intensity', 'medium')  # 'light', 'medium', 'strong'
        preserve_facts = body.get('preserve_facts', True)
        
        if not original_text.strip():
            raise HTTPException(status_code=400, detail="変換対象のテキストが空です")
        
        if not instruction_id and not custom_instruction:
            raise HTTPException(status_code=400, detail="プリセット指示IDまたはカスタム指示のいずれかを指定してください")
        
        from services.custom_instruction_service import custom_instruction_service
        
        result = await custom_instruction_service.apply_custom_instruction(
            original_text=original_text,
            instruction_id=instruction_id,
            custom_instruction=custom_instruction,
            intensity=intensity,
            preserve_facts=preserve_facts
        )
        
        # ユーザー情報を追加
        result['applied_by'] = current_user['uid']
        
        return {
            "status": "success",
            "data": result,
            "message": "カスタム指示が適用されました"
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to apply custom instruction: {str(e)}")

@app.get("/ai/preset-instructions")
async def get_preset_instructions(
    category: Optional[str] = None,
    current_user: Dict[str, Any] = Depends(get_current_user)
):
    """プリセット指示一覧を取得"""
    try:
        from services.custom_instruction_service import custom_instruction_service
        
        result = await custom_instruction_service.get_preset_instructions(category=category)
        
        return {
            "status": "success",
            "data": result,
            "message": "プリセット指示一覧を取得しました"
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get preset instructions: {str(e)}")

@app.post("/ai/user-instructions")
async def create_user_instruction(
    request: Request,
    current_user: Dict[str, Any] = Depends(get_current_user)
):
    """ユーザー独自の指示を作成"""
    try:
        body = await request.json()
        name = body.get('name', '')
        instruction = body.get('instruction', '')
        description = body.get('description')
        examples = body.get('examples', [])
        
        if not name.strip():
            raise HTTPException(status_code=400, detail="指示名が空です")
        
        if not instruction.strip():
            raise HTTPException(status_code=400, detail="指示内容が空です")
        
        from services.custom_instruction_service import custom_instruction_service
        
        result = await custom_instruction_service.create_user_instruction(
            user_id=current_user['uid'],
            name=name,
            instruction=instruction,
            description=description,
            examples=examples
        )
        
        return {
            "status": "success",
            "data": result,
            "message": "ユーザー指示が作成されました"
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to create user instruction: {str(e)}")

@app.get("/ai/user-instructions")
async def get_user_instructions(
    current_user: Dict[str, Any] = Depends(get_current_user)
):
    """ユーザーの指示一覧を取得"""
    try:
        from services.custom_instruction_service import custom_instruction_service
        
        result = await custom_instruction_service.get_user_instructions(current_user['uid'])
        
        return {
            "status": "success",
            "data": result,
            "message": "ユーザー指示一覧を取得しました"
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get user instructions: {str(e)}")

# PDF generation endpoint (認証必須)
@app.post("/export/pdf")
async def export_to_pdf(
    request: Request,
    current_user: Dict[str, Any] = Depends(get_current_user)
):
    """HTMLコンテンツをPDFに変換"""
    try:
        body = await request.json()
        html_content = body.get('html', '')
        document_title = body.get('title', 'untitled')
        
        # TODO: WeasyPrint でPDF生成
        # TODO: Cloud Storage に保存
        
        pdf_url = f"https://storage.googleapis.com/yutori-kyoshitu/{current_user['uid']}/{document_title}.pdf"
        
        return {
            "pdf_url": pdf_url,
            "title": document_title,
            "generated_by": current_user['uid'],
            "status": "success"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to generate PDF: {str(e)}")

# Template endpoints (認証なしでも使用可能)
@app.get("/templates")
async def get_templates(current_user: Optional[Dict[str, Any]] = Depends(optional_auth)):
    """利用可能なテンプレート一覧を取得"""
    templates = [
        {
            "id": "basic_newsletter",
            "name": "基本的な学級通信",
            "description": "シンプルで読みやすい基本レイアウト",
            "preview_url": "/static/templates/basic_newsletter_preview.png",
            "season": "all"
        },
        {
            "id": "spring_newsletter",
            "name": "春の学級通信",
            "description": "桜や新学期をテーマにした明るいレイアウト",
            "preview_url": "/static/templates/spring_newsletter_preview.png",
            "season": "spring"
        },
        {
            "id": "summer_newsletter",
            "name": "夏の学級通信",
            "description": "海や夏祭りをテーマにした爽やかなレイアウト",
            "preview_url": "/static/templates/summer_newsletter_preview.png",
            "season": "summer"
        }
    ]
    
    return {
        "templates": templates,
        "user_authenticated": current_user is not None
    }

@app.get("/templates/{template_id}")
async def get_template(
    template_id: str,
    current_user: Optional[Dict[str, Any]] = Depends(optional_auth)
):
    """特定のテンプレートの詳細を取得"""
    # TODO: Cloud Storage からテンプレートHTMLを取得
    template_html = f"""
    <div class="newsletter-template" data-template="{template_id}">
        <h1>{{title}}</h1>
        <div class="content">{{content}}</div>
        <div class="footer">{{footer}}</div>
    </div>
    """
    
    return {
        "template_id": template_id,
        "html": template_html,
        "css": "/* Template specific CSS */",
        "user_authenticated": current_user is not None
    }

# Error handlers
@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException):
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "error": True,
            "detail": exc.detail,
            "status_code": exc.status_code
        }
    )

@app.exception_handler(Exception)
async def general_exception_handler(request: Request, exc: Exception):
    return JSONResponse(
        status_code=500,
        content={
            "error": True,
            "detail": "Internal server error",
            "status_code": 500
        }
    )

# 開発サーバー起動用
if __name__ == "__main__":
    port = int(os.getenv("PORT", 8000))
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=port,
        reload=True,
        log_level="info"
    )