from fastapi import FastAPI, HTTPException, Depends, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from typing import Dict, Any, Optional
import uvicorn
import os

from auth import get_current_user, optional_auth, firebase_auth, require_auth

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
@require_auth
async def get_documents(current_user: Dict[str, Any] = Depends(get_current_user)):
    """ユーザーのドキュメント一覧を取得"""
    # TODO: Firestore からドキュメント一覧を取得
    return {
        "documents": [],
        "user_id": current_user['uid']
    }

@app.post("/documents")
@require_auth
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
@require_auth
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
@require_auth
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
@require_auth
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
@require_auth
async def speech_to_text(
    request: Request,
    current_user: Dict[str, Any] = Depends(get_current_user)
):
    """音声をテキストに変換"""
    # TODO: Speech-to-Text API統合
    return {
        "text": "サンプル変換テキスト",
        "confidence": 0.95,
        "processed_by": current_user['uid']
    }

@app.post("/ai/enhance-text")
@require_auth
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
@require_auth
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
@require_auth
async def generate_headlines(
    request: Request,
    current_user: Dict[str, Any] = Depends(get_current_user)
):
    """コンテンツから見出しを自動生成"""
    try:
        body = await request.json()
        content = body.get('content', '')
        max_headlines = body.get('max_headlines', 5)
        
        from services.ai_service import ai_service
        
        result = await ai_service.generate_headlines(
            content=content,
            max_headlines=max_headlines
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

# PDF generation endpoint (認証必須)
@app.post("/export/pdf")
@require_auth
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