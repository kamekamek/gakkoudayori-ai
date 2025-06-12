# Welcome to Cloud Functions for Firebase for Python!
# To get started, simply uncomment the below code or create your own.
# Deploy with `firebase deploy`

from firebase_functions import https_fn
from firebase_admin import initialize_app
from flask import Flask, request, jsonify
from flask_cors import CORS
import logging
import os
import sys
from datetime import datetime

# カスタムサービスをインポート
from firebase_service import (
    initialize_firebase,
    initialize_firebase_with_credentials,
    health_check,
    get_firebase_config
)
from speech_recognition_service import (
    transcribe_audio_file,
    validate_audio_format,
    get_supported_formats,
    get_default_speech_contexts
)
from gemini_api_service import generate_text
from html_constraint_service import generate_constrained_html

# ログ設定
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Flaskアプリケーション作成
app = Flask(__name__)
CORS(app)  # CORS設定

# Firebase初期化
def init_firebase():
    """Firebase初期化"""
    try:
        # 環境変数または認証ファイルパスを確認
        credentials_path = os.getenv('GOOGLE_APPLICATION_CREDENTIALS')
        if credentials_path and os.path.exists(credentials_path):
            logger.info(f"Initializing Firebase with credentials: {credentials_path}")
            return initialize_firebase_with_credentials(credentials_path)
        else:
            logger.info("Initializing Firebase with default credentials")
            return initialize_firebase()
    except Exception as e:
        logger.error(f"Firebase initialization failed: {e}")
        return False

# アプリケーション起動時にFirebase初期化
firebase_initialized = init_firebase()

@app.route('/')
def hello_world():
    """ヘルスチェックエンドポイント"""
    return jsonify({
        'status': 'ok',
        'service': 'yutori-kyoshitu-backend',
        'timestamp': datetime.utcnow().isoformat(),
        'firebase_initialized': firebase_initialized
    })

@app.route('/health', methods=['GET'])
def health():
    """詳細ヘルスチェック"""
    try:
        health_result = health_check()
        status = 'healthy' if all([
            health_result.get('firebase_initialized'),
            health_result.get('firestore_accessible'),
            health_result.get('storage_accessible')
        ]) else 'unhealthy'
        
        health_result['status'] = status
        return jsonify(health_result), 200 if status == 'healthy' else 503
    except Exception as e:
        logger.error(f"Health check error: {e}")
        return jsonify({
            'status': 'error',
            'error': str(e),
            'timestamp': datetime.utcnow().isoformat()
        }), 500

@app.route('/config', methods=['GET'])
def config():
    """Firebase設定情報取得"""
    try:
        config_info = get_firebase_config()
        return jsonify(config_info)
    except Exception as e:
        logger.error(f"Config retrieval error: {e}")
        return jsonify({
            'error': str(e),
            'timestamp': datetime.utcnow().isoformat()
        }), 500

# ==============================================================================
# 音声認識エンドポイント
# ==============================================================================

@app.route('/api/v1/ai/transcribe', methods=['POST'])
def transcribe_audio():
    """音声文字起こしエンドポイント"""
    try:
        # ファイルアップロード確認
        if 'audio_file' not in request.files:
            return jsonify({
                'success': False,
                'error': 'No audio file provided',
                'error_code': 'MISSING_FILE'
            }), 400
        
        audio_file = request.files['audio_file']
        if audio_file.filename == '':
            return jsonify({
                'success': False,
                'error': 'No file selected',
                'error_code': 'EMPTY_FILENAME'
            }), 400
        
        # 音声データ読み込み
        audio_content = audio_file.read()
        
        # 音声フォーマット検証
        validation_result = validate_audio_format(audio_content)
        if not validation_result['valid']:
            return jsonify({
                'success': False,
                'error': validation_result['error'],
                'error_code': validation_result['error_code']
            }), 400
        
        # パラメータ取得
        language_code = request.form.get('language', 'ja-JP')
        custom_contexts = request.form.get('user_dictionary', '')
        speech_contexts = custom_contexts.split(',') if custom_contexts else None
        
        # 認証情報パス
        credentials_path = os.getenv('GOOGLE_APPLICATION_CREDENTIALS', '../secrets/service-account-key.json')
        
        # 音声文字起こし実行
        result = transcribe_audio_file(
            audio_content=audio_content,
            credentials_path=credentials_path,
            language_code=language_code,
            speech_contexts=speech_contexts
        )
        
        if result['success']:
            # API仕様に合わせたレスポンス形式
            response_data = {
                'success': True,
                'data': {
                    'transcript': result['data']['transcript'],
                    'confidence': result['data']['confidence'],
                    'processing_time_ms': result['data']['processing_time_ms'],
                    'sections': result['data']['sections'],
                    'audio_info': result['data']['audio_info'],
                    'validation_info': validation_result
                }
            }
            return jsonify(response_data)
        else:
            return jsonify({
                'success': False,
                'error': result['error'],
                'error_type': result.get('error_type', 'unknown'),
                'processing_time_ms': result.get('processing_time_ms', 0)
            }), 500
    
    except Exception as e:
        logger.error(f"Audio transcription error: {e}")
        return jsonify({
            'success': False,
            'error': f'Transcription failed: {str(e)}',
            'error_type': 'server_error'
        }), 500

@app.route('/api/v1/ai/formats', methods=['GET'])
def get_audio_formats():
    """サポートされている音声フォーマット一覧取得"""
    try:
        formats = get_supported_formats()
        contexts = get_default_speech_contexts()
        
        return jsonify({
            'success': True,
            'data': {
                'supported_formats': formats,
                'default_contexts': contexts,
                'max_file_size_mb': 10,
                'max_duration_seconds': 60,
                'supported_languages': [
                    {'code': 'ja-JP', 'name': '日本語'},
                    {'code': 'en-US', 'name': 'English (US)'},
                    {'code': 'en-GB', 'name': 'English (UK)'}
                ]
            }
        })
    except Exception as e:
        logger.error(f"Format info error: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

# ==============================================================================
# 学級通信生成エンドポイント
# ==============================================================================

# ==============================================================================
# Gemini HTML生成エンドポイント
# ==============================================================================

@app.route('/api/v1/ai/generate-html', methods=['POST'])
def generate_html_content():
    """音声認識結果からGemini APIでHTML生成"""
    try:
        # リクエストデータ取得
        data = request.get_json()
        if not data:
            return jsonify({
                'success': False,
                'error': 'No JSON data provided',
                'error_code': 'MISSING_DATA'
            }), 400
        
        # 必須パラメータチェック
        transcribed_text = data.get('transcribed_text', '')
        if not transcribed_text.strip():
            return jsonify({
                'success': False,
                'error': 'Transcribed text is required',
                'error_code': 'MISSING_TRANSCRIBED_TEXT'
            }), 400
        
        # オプションパラメータ
        custom_instruction = data.get('custom_instruction', '')
        season_theme = data.get('season_theme', '')
        document_type = data.get('document_type', 'class_newsletter')
        constraints = data.get('constraints', {})
        
        # Google Cloud認証情報パス
        credentials_path = os.getenv('GOOGLE_APPLICATION_CREDENTIALS', '../secrets/service-account-key.json')
        project_id = os.getenv('GOOGLE_CLOUD_PROJECT', 'yutori-kyoshitu-ai')
        
        # Gemini HTML生成実行
        result = generate_constrained_html(
            prompt=transcribed_text,
            project_id=project_id,
            credentials_path=credentials_path,
            custom_instruction=custom_instruction,
            season_theme=season_theme,
            document_type=document_type,
            constraints=constraints
        )
        
        if result['success']:
            return jsonify(result), 200
        else:
            return jsonify(result), 500
            
    except Exception as e:
        logger.error(f"HTML generation endpoint error: {e}")
        return jsonify({
            'success': False,
            'error': f'HTML generation failed: {str(e)}',
            'error_code': 'HTML_GENERATION_ERROR'
        }), 500

@app.route('/api/v1/ai/generate-newsletter', methods=['POST'])
def generate_newsletter():
    """学級通信自動生成エンドポイント（統合版）"""
    try:
        # リクエストデータ取得
        data = request.get_json()
        if not data:
            return jsonify({
                'success': False,
                'error': 'No JSON data provided',
                'error_code': 'MISSING_DATA'
            }), 400
        
        # 必須パラメータチェック
        speech_text = data.get('transcribed_text', '')
        if not speech_text.strip():
            return jsonify({
                'success': False,
                'error': 'Transcribed text is required',
                'error_code': 'MISSING_TRANSCRIBED_TEXT'
            }), 400
        
        # オプションパラメータ
        template_type = data.get('template_type', 'daily_report')
        include_greeting = data.get('include_greeting', True)
        target_audience = data.get('target_audience', 'parents')
        season = data.get('season', 'auto')
        custom_instruction = data.get('custom_instruction', '')
        
        # 認証情報パス
        credentials_path = os.getenv('GOOGLE_APPLICATION_CREDENTIALS', '../secrets/service-account-key.json')
        project_id = os.getenv('GOOGLE_CLOUD_PROJECT', 'yutori-kyoshitu-ai')
        
        # 季節自動判定
        if season == 'auto':
            season = _detect_season_from_text(speech_text)
        
        # カスタム指示を含むプロンプト構築
        newsletter_instruction = f"""
        形式: {template_type}形式の学級通信
        対象読者: {target_audience}
        季節: {season}
        挨拶文含める: {include_greeting}
        """
        if custom_instruction:
            newsletter_instruction += f"\n追加指示: {custom_instruction}"
        
        # 統合されたHTML生成APIを使用
        result = generate_constrained_html(
            prompt=speech_text,
            project_id=project_id,
            credentials_path=credentials_path,
            custom_instruction=newsletter_instruction,
            season_theme=season,
            document_type='class_newsletter'
        )
        
        if result['success']:
            # レスポンス形式を学級通信用に調整
            newsletter_data = {
                'success': True,
                'data': {
                    'newsletter_html': result['data']['html_content'],
                    'original_speech': speech_text,
                    'template_type': template_type,
                    'season': season,
                    'processing_time_ms': result['data']['processing_time_ms'],
                    'generated_at': result['timestamp'],
                    'word_count': len(result['data']['html_content'].split()),
                    'character_count': len(result['data']['html_content']),
                    'ai_metadata': result['data']['ai_metadata']
                }
            }
            return jsonify(newsletter_data), 200
        else:
            return jsonify(result), 500
            
    except Exception as e:
        logger.error(f"Newsletter generation endpoint error: {e}")
        return jsonify({
            'success': False,
            'error': f'Newsletter generation failed: {str(e)}',
            'error_code': 'GENERATION_ERROR'
        }), 500

def _detect_season_from_text(text: str) -> str:
    """テキストから季節を自動判定"""
    from datetime import datetime
    
    # 現在の月による基本判定
    current_month = datetime.now().month
    
    if 3 <= current_month <= 5:
        base_season = "spring"
    elif 6 <= current_month <= 8:
        base_season = "summer"
    elif 9 <= current_month <= 11:
        base_season = "autumn"
    else:
        base_season = "winter"
    
    # テキスト内のキーワードによる調整
    spring_keywords = ["桜", "入学", "新学期", "春", "お花見", "暖かく", "芽吹く"]
    summer_keywords = ["運動会", "プール", "夏休み", "暑い", "七夕", "夏祭り"]
    autumn_keywords = ["紅葉", "学習発表会", "秋", "文化祭", "涼しく", "収穫"]
    winter_keywords = ["雪", "寒い", "冬", "クリスマス", "正月", "温かく"]
    
    keyword_scores = {
        "spring": sum(1 for kw in spring_keywords if kw in text),
        "summer": sum(1 for kw in summer_keywords if kw in text),
        "autumn": sum(1 for kw in autumn_keywords if kw in text),
        "winter": sum(1 for kw in winter_keywords if kw in text)
    }
    
    # 最高得点の季節があれば使用、なければ月ベースの季節
    max_score = max(keyword_scores.values())
    if max_score > 0:
        for season, score in keyword_scores.items():
            if score == max_score:
                return season
    
    return base_season

@app.route('/api/v1/ai/newsletter-templates', methods=['GET'])
def get_newsletter_templates():
    """学級通信テンプレート一覧取得エンドポイント"""
    try:
        from newsletter_generator import get_newsletter_templates
        
        templates = get_newsletter_templates()
        
        return jsonify({
            'success': True,
            'data': {
                'templates': templates,
                'total_count': len(templates)
            }
        }), 200
        
    except Exception as e:
        logger.error(f"Templates endpoint error: {e}")
        return jsonify({
            'success': False,
            'error': f'Failed to get templates: {str(e)}',
            'error_code': 'TEMPLATES_ERROR'
        }), 500

# ==============================================================================
# PDF生成エンドポイント
# ==============================================================================

@app.route('/api/v1/ai/generate-pdf', methods=['POST'])
def generate_pdf():
    """HTML学級通信をPDFに変換"""
    try:
        # リクエストデータ取得
        data = request.get_json()
        if not data:
            return jsonify({
                'success': False,
                'error': 'No JSON data provided',
                'error_code': 'MISSING_DATA'
            }), 400
        
        # 必須パラメータチェック
        html_content = data.get('html_content', '')
        if not html_content.strip():
            return jsonify({
                'success': False,
                'error': 'HTML content is required',
                'error_code': 'MISSING_HTML_CONTENT'
            }), 400
        
        # オプションパラメータ
        title = data.get('title', '学級通信')
        page_size = data.get('page_size', 'A4')
        margin = data.get('margin', '20mm')
        include_header = data.get('include_header', True)
        include_footer = data.get('include_footer', True)
        custom_css = data.get('custom_css', '')
        
        # PDF生成実行
        from pdf_generator import generate_pdf_from_html
        
        result = generate_pdf_from_html(
            html_content=html_content,
            title=title,
            page_size=page_size,
            margin=margin,
            include_header=include_header,
            include_footer=include_footer,
            custom_css=custom_css
        )
        
        if result['success']:
            return jsonify(result), 200
        else:
            return jsonify(result), 500
            
    except Exception as e:
        logger.error(f"PDF generation endpoint error: {e}")
        return jsonify({
            'success': False,
            'error': f'PDF generation failed: {str(e)}',
            'error_code': 'PDF_GENERATION_ERROR'
        }), 500

@app.route('/api/v1/ai/pdf-info/<path:pdf_id>', methods=['GET'])
def get_pdf_info_endpoint(pdf_id):
    """PDF情報取得エンドポイント"""
    try:
        from pdf_generator import get_pdf_info
        
        # 実際の実装では、pdf_idからファイルパスを解決
        # ここではダミー実装
        pdf_path = f"/tmp/{pdf_id}.pdf"
        
        result = get_pdf_info(pdf_path)
        
        if result['success']:
            return jsonify(result), 200
        else:
            return jsonify(result), 404
            
    except Exception as e:
        logger.error(f"PDF info endpoint error: {e}")
        return jsonify({
            'success': False,
            'error': f'Failed to get PDF info: {str(e)}',
            'error_code': 'PDF_INFO_ERROR'
        }), 500

@app.errorhandler(404)
def not_found(error):
    """404エラーハンドラー"""
    return jsonify({
        'error': 'Not Found',
        'message': 'The requested endpoint was not found',
        'timestamp': datetime.utcnow().isoformat()
    }), 404

@app.errorhandler(500)
def internal_error(error):
    """500エラーハンドラー"""
    return jsonify({
        'error': 'Internal Server Error',
        'message': 'An unexpected error occurred',
        'timestamp': datetime.utcnow().isoformat()
    }), 500

# Cloud Functions用のエントリーポイント
@https_fn.on_request()
def api(req: https_fn.Request) -> https_fn.Response:
    """
    Firebase Cloud Functions用のHTTPSエンドポイント
    
    Args:
        req: HTTPSリクエスト
        
    Returns:
        HTTPSレスポンス
    """
    with app.request_context(req.environ):
        return app.full_dispatch_request()

# ローカル開発用
if __name__ == '__main__':
    # ローカル開発モード
    app.run(debug=True, host='0.0.0.0', port=8080)