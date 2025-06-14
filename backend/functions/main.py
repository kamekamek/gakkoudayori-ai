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
from user_dictionary_service import (
    UserDictionaryService,
    create_user_dictionary_service
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

def get_firestore_client():
    """Firestoreクライアント取得"""
    try:
        if firebase_initialized:
            from firebase_admin import firestore
            return firestore.client()
        else:
            logger.warning("Firebase not initialized, returning None firestore client")
            return None
    except Exception as e:
        logger.error(f"Failed to get Firestore client: {e}")
        return None

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
        sample_rate = int(request.form.get('sample_rate', '48000'))  # 48kHzをデフォルトに
        user_id = request.form.get('user_id', 'default')  # ユーザーIDサポート
        
        # ユーザー辞書サービス初期化
        firestore_client = get_firestore_client()
        dict_service = create_user_dictionary_service(firestore_client)
        speech_contexts = dict_service.get_speech_contexts(user_id)
        
        # 認証情報パス
        credentials_path = os.getenv('GOOGLE_APPLICATION_CREDENTIALS', '../secrets/service-account-key.json')
        
        # 音声文字起こし実行
        result = transcribe_audio_file(
            audio_content=audio_content,
            credentials_path=credentials_path,
            language_code=language_code,
            sample_rate_hertz=sample_rate,
            speech_contexts=speech_contexts,
            user_id=user_id
        )
        
        # ユーザー辞書でポストプロセシング
        if result['success']:
            original_transcript = result['data']['transcript']
            corrected_transcript, corrections = dict_service.correct_transcription(original_transcript, user_id)
            result['data']['transcript'] = corrected_transcript
            result['data']['corrections'] = corrections
            result['data']['original_transcript'] = original_transcript
        
        if result['success']:
            # API仕様に合わせたレスポンス形式
            response_data = {
                'success': True,
                'data': {
                    'transcript': result['data']['transcript'],
                    'original_transcript': result['data'].get('original_transcript', ''),
                    'corrections': result['data'].get('corrections', []),
                    'confidence': result['data']['confidence'],
                    'processing_time_ms': result['data']['processing_time_ms'],
                    'sections': result['data']['sections'],
                    'audio_info': result['data']['audio_info'],
                    'validation_info': validation_result,
                    'user_dictionary_applied': len(result['data'].get('corrections', [])) > 0
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

# ==============================================================================
# ユーザー辞書エンドポイント
# ==============================================================================

@app.route('/api/v1/dictionary/<user_id>', methods=['GET'])
def get_user_dictionary(user_id: str):
    """ユーザー辞書取得"""
    try:
        firestore_client = get_firestore_client()
        dict_service = create_user_dictionary_service(firestore_client)
        dictionary = dict_service.get_user_dictionary(user_id)
        stats = dict_service.get_dictionary_stats(user_id)
        
        return jsonify({
            'success': True,
            'data': {
                'dictionary': dictionary,
                'stats': stats,
                'user_id': user_id
            }
        })
    except Exception as e:
        logger.error(f"Get user dictionary error: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/api/v1/dictionary/<user_id>/terms', methods=['POST'])
def add_custom_term(user_id: str):
    """カスタム用語追加"""
    try:
        logger.info(f"Add custom term called for user_id: {user_id}")
        
        # JSONデータ取得
        data = request.get_json()
        if not data:
            logger.error("No JSON data provided")
            return jsonify({
                'success': False,
                'error': 'No JSON data provided'
            }), 400
        
        logger.info(f"Request data: {data}")
        
        term = data.get('term')
        variations = data.get('variations', [])
        category = data.get('category', 'custom')
        
        if not term:
            logger.error("Term is required but not provided")
            return jsonify({
                'success': False,
                'error': 'Term is required'
            }), 400
        
        # 辞書サービス初期化
        logger.info("Creating user dictionary service...")
        
        # Firestoreクライアント取得
        from firebase_admin import firestore
        firestore_client = firestore.client() if firebase_initialized else None
        logger.info(f"Firestore client: {firestore_client}")
        
        dict_service = create_user_dictionary_service(firestore_client)
        logger.info(f"Dictionary service created: {type(dict_service)}")
        
        # カスタム用語追加
        logger.info(f"Adding custom term: {term} with variations: {variations}")
        success = dict_service.add_custom_term(user_id, term, variations, category)
        logger.info(f"Add custom term result: {success}")
        
        if success:
            return jsonify({
                'success': True,
                'data': {
                    'term': term,
                    'variations': variations,
                    'category': category
                }
            })
        else:
            logger.error("Failed to add custom term - service returned False")
            return jsonify({
                'success': False,
                'error': 'Failed to add custom term'
            }), 500
            
    except Exception as e:
        logger.error(f"Add custom term error: {e}", exc_info=True)
        return jsonify({
            'success': False,
            'error': str(e),
            'error_type': type(e).__name__
        }), 500

@app.route('/api/v1/dictionary/<user_id>/correct', methods=['POST'])
def correct_transcription(user_id: str):
    """文字起こし結果をユーザー辞書で修正"""
    try:
        data = request.get_json()
        transcript = data.get('transcript')
        
        if not transcript:
            return jsonify({
                'success': False,
                'error': 'Transcript is required'
            }), 400
        
        firestore_client = get_firestore_client()
        dict_service = create_user_dictionary_service(firestore_client)
        
        # 文字起こし結果を辞書で修正
        corrected_text, corrections = dict_service.correct_transcription(transcript, user_id)
        
        return jsonify({
            'success': True,
            'data': {
                'original_text': transcript,
                'corrected_text': corrected_text,
                'corrections': corrections,
                'processing_time_ms': 0  # 簡易実装のため0固定
            }
        })
        
    except Exception as e:
        logger.error(f"Transcription correction error: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/api/v1/dictionary/<user_id>/learn', methods=['POST'])
def manual_correction(user_id: str):
    """手動修正記録（学習用）"""
    try:
        data = request.get_json()
        original = data.get('original')
        corrected = data.get('corrected')
        context = data.get('context', '')
        
        if not original or not corrected:
            return jsonify({
                'success': False,
                'error': 'Original and corrected text are required'
            }), 400
        
        firestore_client = get_firestore_client()
        dict_service = create_user_dictionary_service(firestore_client)
        success = dict_service.manual_correction(user_id, original, corrected, context)
        
        if success:
            return jsonify({
                'success': True,
                'data': {
                    'original': original,
                    'corrected': corrected,
                    'context': context,
                    'learned': True
                }
            })
        else:
            return jsonify({
                'success': False,
                'error': 'Failed to record correction'
            }), 500
            
    except Exception as e:
        logger.error(f"Manual correction error: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/api/v1/dictionary/<user_id>/suggest', methods=['POST'])
def suggest_corrections(user_id: str):
    """修正候補提案"""
    try:
        data = request.get_json()
        text = data.get('text')
        
        if not text:
            return jsonify({
                'success': False,
                'error': 'Text is required'
            }), 400
        
        firestore_client = get_firestore_client()
        dict_service = create_user_dictionary_service(firestore_client)
        suggestions = dict_service.suggest_corrections(text, user_id)
        
        return jsonify({
            'success': True,
            'data': {
                'text': text,
                'suggestions': suggestions
            }
        })
        
    except Exception as e:
        logger.error(f"Suggest corrections error: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/api/v1/dictionary/<user_id>/stats', methods=['GET'])
def get_dictionary_stats(user_id: str):
    """辞書統計情報取得"""
    try:
        firestore_client = get_firestore_client()
        dict_service = create_user_dictionary_service(firestore_client)
        stats = dict_service.get_dictionary_stats(user_id)
        
        return jsonify({
            'success': True,
            'data': stats
        })
        
    except Exception as e:
        logger.error(f"Get dictionary stats error: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
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
# 新フロー: 音声→JSON→HTMLグラレコ エンドポイント
# ==============================================================================

@app.route('/api/v1/ai/speech-to-json', methods=['POST'])
def convert_speech_to_json():
    """音声認識結果をJSON構造化データに変換"""
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
        style = data.get('style', 'classic')
        custom_context = data.get('custom_context', '')
        
        # Google Cloud認証情報パス
        credentials_path = os.getenv('GOOGLE_APPLICATION_CREDENTIALS', '../secrets/service-account-key.json')
        project_id = os.getenv('GOOGLE_CLOUD_PROJECT', 'gakkoudayori-ai')
        
        # 音声→JSON変換サービスをインポート
        from audio_to_json_service import convert_speech_to_json
        
        # 変換実行
        result = convert_speech_to_json(
            transcribed_text=transcribed_text,
            project_id=project_id,
            credentials_path=credentials_path,
            style=style,
            custom_context=custom_context
        )
        
        return jsonify(result)
        
    except Exception as e:
        logger.error(f"Speech to JSON conversion error: {e}")
        return jsonify({
            'success': False,
            'error': f'Internal server error: {str(e)}',
            'error_code': 'INTERNAL_ERROR'
        }), 500


@app.route('/api/v1/ai/json-to-graphical-record', methods=['POST'])
def handle_json_to_graphical_record():
    """JSON構造化データからHTMLグラレコを生成"""
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
        json_data = data.get('json_data')
        if not json_data:
            return jsonify({
                'success': False,
                'error': 'JSON data is required',
                'error_code': 'MISSING_JSON_DATA'
            }), 400
        
        # オプションパラメータ
        template = data.get('template', 'classic')
        custom_style = data.get('custom_style', '')
        
        # Google Cloud認証情報パス
        credentials_path = os.getenv('GOOGLE_APPLICATION_CREDENTIALS', '../secrets/service-account-key.json')
        project_id = os.getenv('GOOGLE_CLOUD_PROJECT', 'gakkoudayori-ai')
        
        # JSON→HTMLグラレコ変換サービスをインポート
        from json_to_graphical_record_service import convert_json_to_graphical_record
        
        # 変換実行
        result = convert_json_to_graphical_record(
            json_data=json_data,
            project_id=project_id,
            credentials_path=credentials_path,
            template=template,
            custom_style=custom_style,
            max_output_tokens=8192  # HTMLが途中で切れないように増加
        )
        
        # サービスからの戻り値がシリアライズ可能か確認
        if not isinstance(result, dict) or 'success' not in result:
             logger.error(f"Invalid response from service: {result}")
             raise TypeError("Service returned a non-serializable object")

        if result.get("success"):
            return jsonify(result), 200
        else:
            # エラーレスポンスもJSONとして返す
            error_info = result.get("error", {"code": "UNKNOWN_ERROR", "message": "An unknown error occurred"})
            return jsonify({"success": False, "error": error_info}), 400

    except Exception as e:
        logger.error(f"JSON to graphical record conversion error: {e}", exc_info=True)
        # 予期せぬ例外をキャッチして500エラーを返す
        return jsonify({
            "success": False,
            "error": {
                "code": "INTERNAL_SERVER_ERROR",
                "message": str(e)
            }
        }), 500


# ==============================================================================
# 学級通信生成エンドポイント（従来フロー）
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
        project_id = os.getenv('GOOGLE_CLOUD_PROJECT', 'gakkoudayori-ai')
        
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
        project_id = os.getenv('GOOGLE_CLOUD_PROJECT', 'gakkoudayori-ai')
        
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
        
        # レスポンスハンドリングを改善
        html_content = None
        validation_info = None
        ai_metadata = None
        processing_time_ms = 0
        timestamp = datetime.utcnow().isoformat()

        if result.get('success'):
            # 完全に成功した場合
            data = result.get('data', {})
            html_content = data.get('html_content')
            validation_info = data.get('validation_info')
            ai_metadata = data.get('ai_metadata')
            processing_time_ms = data.get('processing_time_ms', 0)
            timestamp = result.get('timestamp', timestamp)

        elif result.get('code') == 'HTML_VALIDATION_FILTERING_ERROR':
            details = result.get('details', {})
            if 'filtered_html_preview' in details:
                # フィルタリングはされたが、コンテンツ自体は存在する場合
                logger.warning(f"HTML validation filtering occurred: {details.get('validation_issues')}")
                html_content = details['filtered_html_preview']
                validation_info = details  # フィルタリング情報を詳細として詰める
                ai_metadata = details.get('ai_metadata', {}) # 部分的なメタデータでも取得
                processing_time_ms = details.get('processing_time_ms', 0)
                timestamp = result.get('timestamp', timestamp)
        
        if html_content is not None:
            # 成功レスポンスを構築
            newsletter_data = {
                'success': True,
                'data': {
                    'newsletter_html': html_content,
                    'original_speech': speech_text,
                    'template_type': template_type,
                    'season': season,
                    'processing_time_ms': processing_time_ms,
                    'generated_at': timestamp,
                    'word_count': len(html_content.split()),
                    'character_count': len(html_content),
                    'validation_info': validation_info,
                    'ai_metadata': ai_metadata
                }
            }
            return jsonify(newsletter_data), 200
        else:
            # 上記以外のエラーは従来通り500エラーとして処理
            logger.error(f"Newsletter generation failed with unhandled error: {result}")
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
        margin = data.get('margin', '15mm')  # プレビューと統一
        include_header = data.get('include_header', False)
        include_footer = data.get('include_footer', False)
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
    # 本番環境とローカル開発の両方に対応
    import os
    port = int(os.environ.get('PORT', 8080))
    debug = os.environ.get('FLASK_ENV') != 'production'
    app.run(debug=debug, host='0.0.0.0', port=port)

# デバッグ用エンドポイント
@app.route('/api/v1/debug/dictionary', methods=['GET'])
def debug_dictionary():
    """辞書サービスのデバッグ情報"""
    try:
        logger.info("Debug dictionary service called")
        
        # サービス初期化テスト
        firestore_client = get_firestore_client()
        dict_service = create_user_dictionary_service(firestore_client)
        logger.info(f"Dictionary service created: {type(dict_service)}")
        
        # デフォルトユーザーの辞書取得テスト
        default_dict = dict_service.get_user_dictionary("default")
        logger.info(f"Default dictionary entries: {len(default_dict)}")
        
        # 統計情報取得テスト
        stats = dict_service.get_dictionary_stats("default")
        logger.info(f"Dictionary stats: {stats}")
        
        return jsonify({
            'success': True,
            'data': {
                'service_initialized': True,
                'default_dictionary_size': len(default_dict),
                'stats': stats,
                'firebase_initialized': firebase_initialized
            }
        })
        
    except Exception as e:
        logger.error(f"Debug dictionary error: {e}", exc_info=True)
        return jsonify({
            'success': False,
            'error': str(e),
            'error_type': type(e).__name__
        }), 500