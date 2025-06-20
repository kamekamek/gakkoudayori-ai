# Welcome to Cloud Functions for Firebase for Python!
# To get started, simply uncomment the below code or create your own.
# Deploy with `firebase deploy`

from firebase_functions import https_fn
from datetime import datetime
from google.cloud import speech  # speechモジュールをインポート
from firebase_admin import initialize_app
from flask import Flask, request, jsonify
from flask_cors import CORS
import logging
import os
import re
import sys
from datetime import datetime

# カスタムサービスをインポート
from firebase_service import (
    initialize_firebase,

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

# ADK準拠システム（条件付きインポート）
try:
    from adk_compliant_orchestrator import generate_newsletter_with_adk_compliant
    ADK_COMPLIANT_AVAILABLE = True
    logger.info("ADK準拠システムが利用可能です")
except ImportError as e:
    ADK_COMPLIANT_AVAILABLE = False
    logger.warning(f"ADK準拠システムのインポートに失敗: {e}")
    
# 既存システム
from audio_to_json_service import convert_speech_to_json

# 対話式システム（新規追加）
try:
    from conversational_api_service import (
        start_conversational_newsletter,
        process_conversation_response,
        get_conversation_status,
        get_conversation_history
    )
    CONVERSATIONAL_AVAILABLE = True
    logger.info("対話式システムが利用可能です")
except ImportError as e:
    CONVERSATIONAL_AVAILABLE = False
    logger.warning(f"対話式システムのインポートに失敗: {e}")

# Flaskアプリケーション作成
app = Flask(__name__)
# CORS設定 - 本番とローカル開発環境の両方を許可
# プレビュー環境のURLパターン (例: https://gakkoudayori-ai--pr-123.web.app) にマッチする正規表現
preview_origin_pattern = r"https://gakkoudayori-ai--pr-\d+\.web\.app"
# ステージング環境のURLパターン (例: https://gakkoudayori-ai--staging-abc123.web.app) にマッチする正規表現
staging_origin_pattern = r"https://gakkoudayori-ai--staging-[a-z0-9]+\.web\.app"

CORS(app, origins=[
    "https://gakkoudayori-ai.web.app",  # 本番フロントエンド
    "https://gakkoudayori-ai--staging.web.app",  # ステージングフロントエンド (固定)
    re.compile(staging_origin_pattern), # ステージング環境 (可変ID付き)
    re.compile(preview_origin_pattern), # プレビュー環境 (正規表現)
    "http://localhost:3000",
    "http://localhost:5000",
    "http://localhost:8080"
])

# Firebase初期化
def init_firebase():
    """Firebase初期化"""
    try:
        # firebase_service.pyのinitialize_firebase()を使用（Secret Manager対応済み）
        from firebase_service import initialize_firebase
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
        logger.error(f"Exception type: {type(e).__name__}")
        import traceback
        logger.error(f"Full traceback: {traceback.format_exc()}")
        return None

# アプリケーション起動時にFirebase初期化
firebase_initialized = init_firebase()

# ==============================================================================
# ADK準拠システム移行制御
# ==============================================================================

def get_migration_percentage() -> int:
    """現在の移行率を取得"""
    # 環境変数から移行率を取得（デフォルト5%）
    migration_rate = int(os.getenv('ADK_MIGRATION_PERCENTAGE', '5'))
    # 最大100%に制限
    return min(migration_rate, 100)

def should_use_new_system(migration_percentage: int) -> bool:
    """新システム使用判定"""
    # リクエストIPアドレスベースの一貫した振り分け
    try:
        user_hash = hash(request.remote_addr or 'default') % 100
        return user_hash < migration_percentage
    except:
        # フォールバック: ランダム
        import random
        return random.randint(0, 99) < migration_percentage

def emergency_fallback(
    transcribed_text: str, 
    project_id: str, 
    credentials_path: str,
    style: str,
    teacher_profile: dict
) -> dict:
    """緊急時フォールバック処理"""
    try:
        logger.info("Executing emergency fallback")
        result = convert_speech_to_json(
            transcribed_text=transcribed_text,
            project_id=project_id,
            credentials_path=credentials_path,
            style=style,
            custom_context='',
            use_adk=False,
            teacher_profile=teacher_profile
        )
        
        # フォールバック情報を追加
        result['system_metadata'] = {
            "system_used": "emergency_fallback",
            "fallback_triggered": True,
            "timestamp": datetime.now().isoformat()
        }
        
        return result
        
    except Exception as e:
        logger.error(f"Emergency fallback also failed: {e}")
        return {
            'success': False,
            'error': f'All systems failed: {str(e)}',
            'error_code': 'COMPLETE_SYSTEM_FAILURE',
            'system_metadata': {
                "system_used": "none",
                "complete_failure": True,
                "timestamp": datetime.now().isoformat()
            }
        }

@app.route('/')
def hello_world():
    """ヘルスチェックエンドポイント"""
    return jsonify({
        'status': 'ok',
        'service': 'gakkoudayori-ai-backend',
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
            'message': "Health check failed (simplified error response)"  # datetimeを削除
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
            "status": "ok",
            "message": "Health check successful (simplified)"
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
        
        # 認証情報パス (Cloud Run環境では不要)
        credentials_path = os.getenv('GOOGLE_APPLICATION_CREDENTIALS')
        if credentials_path and not os.path.exists(credentials_path):
            credentials_path = None
        
        # 音声文字起こし実行
        result = transcribe_audio_file(
            audio_content=audio_content,
            credentials_path=credentials_path,
            language_code=language_code,
            sample_rate_hertz=sample_rate,
            speech_contexts=speech_contexts,
            user_id=user_id,
            encoding=speech.RecognitionConfig.AudioEncoding.LINEAR16 if validation_result.get('format') == 'WAV' else speech.RecognitionConfig.AudioEncoding.WEBM_OPUS  # ファイル形式に応じてエンコーディングを設定 (デフォルトはWEBM_OPUS)
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
        
        return jsonify({
            'success': True,
            'data': {
                'dictionary': dictionary,
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
        success = dict_service.add_custom_term(user_id, term, variations)
        logger.info(f"Add custom term result: {success}")
        
        if success:
            return jsonify({
                'success': True,
                'data': {
                    'term': term,
                    'variations': variations
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

@app.route('/api/v1/dictionary/<user_id>/terms/<term_name>', methods=['PUT'])
def update_user_dictionary_term(user_id: str, term_name: str):
    """ユーザー辞書の特定の用語を更新"""
    try:
        data = request.get_json()
        if not data:
            return jsonify({'success': False, 'error': 'No JSON data provided'}), 400
        
        variations = data.get('variations')
        
        if variations is None: # variations は空リストを許容するが、キー自体がないのはエラー
            return jsonify({'success': False, 'error': 'Variations are required'}), 400

        firestore_client = get_firestore_client()
        dict_service = create_user_dictionary_service(firestore_client)
        
        success = dict_service.update_custom_term(user_id, term_name, variations)
        
        if success:
            return jsonify({
                'success': True,
                'data': {
                    'term': term_name,
                    'variations': variations,
                    'message': f'Term "{term_name}" updated successfully.'
                }
            })
        else:
            # サービス側で term が見つからない場合などは False が返るので、それを適切に処理
            return jsonify({'success': False, 'error': f'Failed to update term "{term_name}". It might not exist or an internal error occurred.'}), 404 # もしくは500
            
    except Exception as e:
        logger.error(f"Update custom term error for term '{term_name}': {e}", exc_info=True)
        return jsonify({'success': False, 'error': str(e), 'error_type': type(e).__name__}), 500

@app.route('/api/v1/dictionary/<user_id>/terms/<term_name>', methods=['DELETE'])
def delete_user_dictionary_term(user_id: str, term_name: str):
    """ユーザー辞書の特定の用語を削除"""
    try:
        firestore_client = get_firestore_client()
        dict_service = create_user_dictionary_service(firestore_client)
        
        success = dict_service.delete_custom_term(user_id, term_name)
        
        if success:
            return jsonify({
                'success': True,
                'data': {
                    'term': term_name,
                    'message': f'Term "{term_name}" deleted successfully.'
                }
            })
        else:
            return jsonify({'success': False, 'error': f'Failed to delete term "{term_name}". It might not exist or an internal error occurred.'}), 404 # もしくは500

    except Exception as e:
        logger.error(f"Delete custom term error for term '{term_name}': {e}", exc_info=True)
        return jsonify({'success': False, 'error': str(e), 'error_type': type(e).__name__}), 500

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
        use_adk = data.get('use_adk', False)  # ADKマルチエージェント使用フラグ
        teacher_profile = data.get('teacher_profile', {})  # 教師プロファイル
        
        # ADK準拠システム制御（新規追加）
        use_adk_compliant = data.get('use_adk_compliant', False)  # ADK準拠システム使用フラグ
        migration_percentage = get_migration_percentage()  # 段階的移行率
        force_legacy = data.get('force_legacy', False)  # 強制レガシーモード
        
        # Phase 2拡張パラメータ
        enable_pdf = data.get('enable_pdf', True)  # PDF生成有効化
        enable_images = data.get('enable_images', True)  # 画像生成有効化
        classroom_settings = data.get('classroom_settings', None)  # Classroom配布設定
        
        # Google Cloud認証情報パス（Cloud Run環境ではNone）
        credentials_path = None if os.getenv('K_SERVICE') else os.getenv('GOOGLE_APPLICATION_CREDENTIALS')
        project_id = os.getenv('GOOGLE_CLOUD_PROJECT', 'gakkoudayori-ai')
        
        # 音声→JSON変換サービスをインポート
        from audio_to_json_service import convert_speech_to_json
        
        # システム選択ロジック（段階的移行対応）
        should_use_adk_compliant = (
            ADK_COMPLIANT_AVAILABLE and 
            not force_legacy and
            (use_adk_compliant or should_use_new_system(migration_percentage))
        )
        
        logger.info(f"System selection: ADK_COMPLIANT={should_use_adk_compliant}, migration_rate={migration_percentage}%")
        
        try:
            if should_use_adk_compliant:
                # ADK準拠システム使用
                logger.info("Using ADK compliant system")
                import asyncio
                
                # 非同期実行のためのラッパー
                loop = asyncio.new_event_loop()
                asyncio.set_event_loop(loop)
                
                try:
                    result = loop.run_until_complete(
                        generate_newsletter_with_adk_compliant(
                            audio_transcript=transcribed_text,
                            project_id=project_id,
                            credentials_path=credentials_path,
                            grade_level=teacher_profile.get('grade_level', '3年1組'),
                            style=style,
                            use_parallel_processing=True,
                            quality_threshold=80
                        )
                    )
                    
                    # ADK準拠結果の適応
                    if result.get('status') == 'success':
                        adk_result = {
                            "success": True,
                            "data": {
                                "json_data": result.get('final_output', {}),
                                "html_content": result.get('final_output', {}).get('html_result', {}).get('html', ''),
                                "quality_score": result.get('quality_check', {}).get('score', 0),
                                "processing_info": {
                                    "workflow_type": result.get('workflow_type'),
                                    "processing_time": result.get('processing_time_seconds'),
                                    "execution_id": result.get('execution_id')
                                }
                            },
                            "system_metadata": {
                                "system_used": "adk_compliant",
                                "adk_compliant": True,
                                "migration_percentage": migration_percentage,
                                "timestamp": result.get('timestamp')
                            }
                        }
                        result = adk_result
                    else:
                        # ADK準拠システム失敗時のフォールバック
                        logger.warning("ADK compliant system failed, falling back to legacy")
                        result = emergency_fallback(transcribed_text, project_id, credentials_path, style, teacher_profile)
                        
                finally:
                    loop.close()
                    
            elif use_adk and (enable_pdf or enable_images or classroom_settings):
                # 既存ADKマルチエージェント（Phase 2機能付き）使用
                logger.info("Using legacy ADK multi-agent system")
                import asyncio
                from adk_multi_agent_service import generate_newsletter_with_adk
                
                # 非同期実行のためのラッパー
                loop = asyncio.new_event_loop()
                asyncio.set_event_loop(loop)
                
                try:
                    result = loop.run_until_complete(
                        generate_newsletter_with_adk(
                            audio_transcript=transcribed_text,
                            project_id=project_id,
                            credentials_path=credentials_path,
                            grade_level=teacher_profile.get('grade_level', '3年1組'),
                            style=style,
                            enable_pdf=enable_pdf,
                            enable_images=enable_images,
                            classroom_settings=classroom_settings
                        )
                    )
                    
                    # 従来形式への適応
                    if result.get("success"):
                        # ADK結果を従来のJSON形式にラップ
                        adk_result = {
                            "success": True,
                            "data": {
                                "json_data": result,  # ADK結果全体を含む
                                "html_content": result.get("html"),
                                "pdf_data": result.get("pdf_output"),
                                "media_data": result.get("media_enhancement"),
                                "classroom_data": result.get("classroom_distribution")
                            },
                            "system_metadata": {
                                "system_used": "legacy_adk",
                                "generation_method": result.get("generation_method"),
                                "agents_used": result.get("agents_used"),
                                "phase2_features": result.get("phase2_features")
                            }
                        }
                        result = adk_result
                        
                finally:
                    loop.close()
            else:
                # 従来の変換処理
                logger.info("Using legacy system")
                result = convert_speech_to_json(
                    transcribed_text=transcribed_text,
                    project_id=project_id,
                    credentials_path=credentials_path,
                    style=style,
                    custom_context=custom_context,
                    use_adk=use_adk,
                    teacher_profile=teacher_profile
                )
                
                # システム情報追加
                result['system_metadata'] = {
                    "system_used": "legacy",
                    "migration_percentage": migration_percentage,
                    "timestamp": datetime.now().isoformat()
                }
            
        except Exception as e:
            logger.error(f"Primary system failed, attempting emergency fallback: {e}")
            result = emergency_fallback(transcribed_text, project_id, credentials_path, style, teacher_profile)
        
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
        
        # Google Cloud認証情報パス（Cloud Run環境ではNone）
        credentials_path = None if os.getenv('K_SERVICE') else os.getenv('GOOGLE_APPLICATION_CREDENTIALS')
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
        
        # Google Cloud認証情報パス（Cloud Run環境ではNone）
        credentials_path = None if os.getenv('K_SERVICE') else os.getenv('GOOGLE_APPLICATION_CREDENTIALS')
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
        
        # 認証情報パス（Cloud Run環境ではNone）
        credentials_path = None if os.getenv('K_SERVICE') else os.getenv('GOOGLE_APPLICATION_CREDENTIALS')
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
            # \n や \\n を <br> に置換して、HTMLでの改行を確実にする
            # プレビューで意図しない \n が表示される問題への対処
            html_content = html_content.replace('\\n', '<br />').replace('\n', '<br />')

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
        
        # 【重要】HTMLコンテンツのMarkdownコードブロッククリーンアップ
        html_content = _clean_html_for_pdf(html_content)
        
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

# ==============================================================================
# ヘルパー関数
# ==============================================================================

def _clean_html_for_pdf(html_content: str) -> str:
    """
    PDF生成前にHTMLからMarkdownコードブロックを除去 - 強化版
    
    Args:
        html_content (str): クリーンアップするHTMLコンテンツ
        
    Returns:
        str: Markdownコードブロックが除去されたHTMLコンテンツ
    """
    if not html_content:
        return html_content
    
    import re
    
    content = html_content.strip()
    
    # Markdownコードブロックの様々なパターンを削除 - 強化版
    patterns = [
        r'```html\s*',          # ```html
        r'```HTML\s*',          # ```HTML  
        r'```\s*html\s*',       # ``` html
        r'```\s*HTML\s*',       # ``` HTML
        r'```\s*',              # 一般的なコードブロック開始
        r'\s*```',              # コードブロック終了
        r'`html\s*',            # `html（単一バッククォート）
        r'`HTML\s*',            # `HTML（単一バッククォート）
        r'\s*`\s*$',            # 末尾の単一バッククォート
        r'^\s*`',               # 先頭の単一バッククォート
    ]
    
    for pattern in patterns:
        content = re.sub(pattern, '', content, flags=re.IGNORECASE | re.MULTILINE)
    
    # HTMLの前後にある説明文を削除（より積極的に）
    explanation_patterns = [
        r'^[^<]*(?=<)',                           # HTML開始前の説明文
        r'>[^<]*$',                               # HTML終了後の説明文  
        r'以下のHTML.*?です[。：]?\s*',              # 「以下のHTML〜です」パターン
        r'HTML.*?を出力.*?[。：]?\s*',             # 「HTMLを出力〜」パターン
        r'こちらが.*?HTML.*?[。：]?\s*',           # 「こちらがHTML〜」パターン
        r'生成された.*?HTML.*?[。：]?\s*',         # 「生成されたHTML〜」パターン
        r'【[^】]*】',                               # 【〜】形式のラベル
    ]
    
    for pattern in explanation_patterns:
        content = re.sub(pattern, '', content, flags=re.IGNORECASE)
    
    # 空白の正規化
    content = re.sub(r'\n\s*\n', '\n', content)
    content = content.strip()
    
    # デバッグログ：PDFエンドポイントでのクリーンアップチェック（強化）
    if '```' in content or '`' in content:
        logger.warning(f"PDF endpoint: Markdown/backtick remnants detected after enhanced cleanup: {content[:100]}...")
    
    return content

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
    port = int(os.environ.get('PORT', 8081))
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
        
        return jsonify({
            'success': True,
            'data': {
                'service_initialized': True,
                'default_dictionary_size': len(default_dict),
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

# ==============================================================================
# 対話式学級通信作成API（新規追加）
# ==============================================================================

@app.route("/api/v1/ai/conversation/start", methods=["POST"])
def start_conversation():
    """対話式学級通信作成開始"""
    try:
        if not CONVERSATIONAL_AVAILABLE:
            return jsonify({
                "success": False,
                "error": "対話式システムが利用できません",
                "error_code": "CONVERSATIONAL_NOT_AVAILABLE"
            }), 503
        
        data = request.get_json()
        if not data:
            return jsonify({
                "success": False,
                "error": "No JSON data provided",
                "error_code": "MISSING_DATA"
            }), 400
        
        # 必須パラメータ
        audio_transcript = data.get("audio_transcript", "")
        if not audio_transcript.strip():
            return jsonify({
                "success": False,
                "error": "Audio transcript is required",
                "error_code": "MISSING_TRANSCRIPT"
            }), 400
        
        # オプションパラメータ
        user_id = data.get("user_id", "default")
        teacher_profile = data.get("teacher_profile", {})
        
        # 対話開始
        result = start_conversational_newsletter(
            audio_transcript=audio_transcript,
            user_id=user_id,
            teacher_profile=teacher_profile
        )
        
        if result["success"]:
            return jsonify(result), 200
        else:
            return jsonify(result), 500
            
    except Exception as e:
        logger.error(f"Start conversation error: {e}")
        return jsonify({
            "success": False,
            "error": f"対話開始エラー: {str(e)}",
            "error_code": "CONVERSATION_START_ERROR"
        }), 500

@app.route("/api/v1/ai/conversation/<session_id>/respond", methods=["POST"])
def respond_to_conversation(session_id: str):
    """対話応答処理"""
    try:
        if not CONVERSATIONAL_AVAILABLE:
            return jsonify({
                "success": False,
                "error": "対話式システムが利用できません",
                "error_code": "CONVERSATIONAL_NOT_AVAILABLE"
            }), 503
        
        data = request.get_json()
        if not data:
            return jsonify({
                "success": False,
                "error": "No JSON data provided",
                "error_code": "MISSING_DATA"
            }), 400
        
        # ユーザー応答処理
        result = process_conversation_response(
            session_id=session_id,
            user_response=data
        )
        
        if result["success"]:
            return jsonify(result), 200
        else:
            return jsonify(result), 400 if "SESSION_NOT_FOUND" in result.get("error_code", "") else 500
            
    except Exception as e:
        logger.error(f"Conversation response error: {e}")
        return jsonify({
            "success": False,
            "error": f"対話応答エラー: {str(e)}",
            "error_code": "CONVERSATION_RESPONSE_ERROR"
        }), 500

@app.route("/api/v1/ai/conversation/<session_id>/status", methods=["GET"])
def get_conversation_status_endpoint(session_id: str):
    """対話状態取得"""
    try:
        if not CONVERSATIONAL_AVAILABLE:
            return jsonify({
                "success": False,
                "error": "対話式システムが利用できません",
                "error_code": "CONVERSATIONAL_NOT_AVAILABLE"
            }), 503
        
        result = get_conversation_status(session_id)
        
        if result["success"]:
            return jsonify(result), 200
        else:
            return jsonify(result), 404 if "SESSION_NOT_FOUND" in result.get("error_code", "") else 500
            
    except Exception as e:
        logger.error(f"Get conversation status error: {e}")
        return jsonify({
            "success": False,
            "error": f"対話状態取得エラー: {str(e)}",
            "error_code": "CONVERSATION_STATUS_ERROR"
        }), 500

@app.route("/api/v1/ai/conversation/<session_id>/history", methods=["GET"])
def get_conversation_history_endpoint(session_id: str):
    """対話履歴取得"""
    try:
        if not CONVERSATIONAL_AVAILABLE:
            return jsonify({
                "success": False,
                "error": "対話式システムが利用できません",
                "error_code": "CONVERSATIONAL_NOT_AVAILABLE"
            }), 503
        
        result = get_conversation_history(session_id)
        
        if result["success"]:
            return jsonify(result), 200
        else:
            return jsonify(result), 404 if "SESSION_NOT_FOUND" in result.get("error_code", "") else 500
            
    except Exception as e:
        logger.error(f"Get conversation history error: {e}")
        return jsonify({
            "success": False,
            "error": f"対話履歴取得エラー: {str(e)}",
            "error_code": "CONVERSATION_HISTORY_ERROR"
        }), 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8081, debug=True)

