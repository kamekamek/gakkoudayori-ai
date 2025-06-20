#!/usr/bin/env python3
"""
バックエンドAPI動作確認デモ

フロントエンドとの連携確認用ツール
"""

import json
import requests
import time
from datetime import datetime

def print_section(title: str):
    """セクション区切り表示"""
    print(f"\n{'='*60}")
    print(f"🎯 {title}")
    print('='*60)

def test_backend_health():
    """バックエンドヘルスチェック"""
    print_section("バックエンドヘルスチェック")
    
    api_urls = [
        'http://localhost:8081',  # ローカル開発
        'http://localhost:5000',  # Flask dev server
        'https://yutori-backend-944053509139.asia-northeast1.run.app',  # 本番
    ]
    
    for url in api_urls:
        try:
            print(f"\n🔍 テスト中: {url}")
            response = requests.get(f"{url}/health", timeout=5)
            
            if response.status_code == 200:
                data = response.json()
                print(f"✅ 接続成功")
                print(f"   サービス: {data.get('service', 'unknown')}")
                print(f"   ステータス: {data.get('status', 'unknown')}")
                print(f"   Firebase: {data.get('firebase_initialized', 'unknown')}")
                return url
            else:
                print(f"❌ ステータスコード: {response.status_code}")
                
        except requests.exceptions.RequestException as e:
            print(f"❌ 接続失敗: {e}")
    
    return None

def test_speech_to_json_api(base_url: str):
    """音声→JSON API テスト（ADK準拠）"""
    print_section("音声→JSON API テスト")
    
    # テストケース1: 従来システム
    test_data_legacy = {
        "transcribed_text": "今日は運動会の練習をしました。子どもたちは徒競走とダンスの練習を頑張っていました。",
        "style": "classic",
        "teacher_profile": {
            "grade_level": "3年1組"
        },
        "use_adk": False,
        "use_adk_compliant": False,
        "force_legacy": True
    }
    
    # テストケース2: ADK準拠システム
    test_data_adk = {
        "transcribed_text": "今日は運動会の練習をしました。子どもたちは徒競走とダンスの練習を頑張っていました。",
        "style": "modern", 
        "teacher_profile": {
            "grade_level": "3年1組"
        },
        "use_adk": False,
        "use_adk_compliant": True,
        "force_legacy": False
    }
    
    test_cases = [
        ("従来システム", test_data_legacy),
        ("ADK準拠システム", test_data_adk)
    ]
    
    for test_name, test_data in test_cases:
        print(f"\n🧪 {test_name}テスト")
        try:
            start_time = time.time()
            response = requests.post(
                f"{base_url}/api/v1/ai/speech-to-json",
                json=test_data,
                headers={'Content-Type': 'application/json'},
                timeout=30
            )
            processing_time = time.time() - start_time
            
            print(f"   ステータス: {response.status_code}")
            print(f"   処理時間: {processing_time:.2f}秒")
            
            if response.status_code == 200:
                data = response.json()
                print(f"✅ API呼び出し成功")
                print(f"   成功フラグ: {data.get('success')}")
                
                # システム情報
                system_metadata = data.get('system_metadata', {})
                if system_metadata:
                    print(f"   使用システム: {system_metadata.get('system_used', 'unknown')}")
                    print(f"   ADK準拠: {system_metadata.get('adk_compliant', False)}")
                    if 'migration_percentage' in system_metadata:
                        print(f"   移行率: {system_metadata['migration_percentage']}%")
                
                # データ内容
                response_data = data.get('data', {})
                if response_data:
                    print(f"   データキー: {list(response_data.keys())}")
                    
                    # HTMLコンテンツの確認
                    html_content = response_data.get('html_content', '')
                    if html_content:
                        print(f"   HTML長: {len(html_content)}文字")
                        print(f"   HTMLプレビュー: {html_content[:100]}...")
                    
                    # 品質スコア（ADK準拠システムの場合）
                    quality_score = response_data.get('quality_score')
                    if quality_score is not None:
                        print(f"   品質スコア: {quality_score}/100")
                        
                    # 処理情報（ADK準拠システムの場合）
                    processing_info = response_data.get('processing_info', {})
                    if processing_info:
                        workflow_type = processing_info.get('workflow_type')
                        if workflow_type:
                            print(f"   ワークフロー: {workflow_type}")
                
            else:
                print(f"❌ API呼び出し失敗")
                try:
                    error_data = response.json()
                    print(f"   エラー: {error_data.get('error', 'unknown')}")
                    print(f"   エラーコード: {error_data.get('error_code', 'unknown')}")
                except:
                    print(f"   レスポンス: {response.text[:200]}...")
                    
        except requests.exceptions.RequestException as e:
            print(f"❌ リクエストエラー: {e}")

def test_frontend_api_compatibility(base_url: str):
    """フロントエンド互換性テスト"""
    print_section("フロントエンド互換性テスト")
    
    # フロントエンドが期待する形式でのリクエスト
    frontend_request = {
        "transcribed_text": "保護者の皆様、今日は図書館見学に行きました。",
        "template_type": "daily_report",
        "include_greeting": True,
        "target_audience": "parents",
        "season": "auto",
        "custom_instruction": "温かい語り口で書いてください",
        
        # ADK準拠システム用パラメータ
        "use_adk_compliant": True,
        "teacher_profile": {
            "grade_level": "2年3組"
        }
    }
    
    try:
        print("\n📱 フロントエンド形式リクエスト送信中...")
        response = requests.post(
            f"{base_url}/api/v1/ai/speech-to-json",
            json=frontend_request,
            headers={'Content-Type': 'application/json'},
            timeout=30
        )
        
        print(f"   ステータス: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            print(f"✅ フロントエンド互換性確認完了")
            
            # Flutter AIService.dart が期待するレスポンス形式をチェック
            expected_fields = ['success', 'data']
            for field in expected_fields:
                if field in data:
                    print(f"   ✅ {field}: 存在")
                else:
                    print(f"   ❌ {field}: 不足")
            
            # データ詳細
            if data.get('success'):
                response_data = data.get('data', {})
                print(f"   データ構造: {list(response_data.keys())}")
                
                # AIGenerationResult.fromJson() が期待するフィールド
                ai_result_fields = [
                    'newsletter_html', 'original_speech', 'template_type',
                    'season', 'processing_time_ms', 'generated_at',
                    'word_count', 'character_count', 'ai_metadata'
                ]
                
                print(f"   AIGenerationResult互換性:")
                for field in ai_result_fields:
                    # フィールドのマッピング確認
                    if field in response_data:
                        print(f"     ✅ {field}")
                    elif field == 'newsletter_html' and 'html_content' in response_data:
                        print(f"     🔄 {field} (html_contentから取得可能)")
                    elif field == 'original_speech' and 'transcribed_text' in frontend_request:
                        print(f"     🔄 {field} (リクエストから取得可能)")
                    else:
                        print(f"     ❌ {field} (不足)")
        else:
            print(f"❌ フロントエンド互換性テスト失敗")
            
    except requests.exceptions.RequestException as e:
        print(f"❌ フロントエンド互換性テストエラー: {e}")

def test_audio_transcription_api(base_url: str):
    """音声文字起こしAPIテスト"""
    print_section("音声文字起こしAPIテスト")
    
    print("\n🎤 音声文字起こしAPIエンドポイント確認...")
    
    # サンプル音声データ（Base64エンコード想定）
    sample_audio_data = "UklGRjIAAABXQVZFZm10IBIAAAABAAEA..."  # ダミーデータ
    
    audio_request = {
        "audio_data": sample_audio_data,
        "language": "ja-JP",
        "sample_rate": 16000,
        "user_id": "test_user"
    }
    
    try:
        response = requests.post(
            f"{base_url}/api/v1/ai/transcribe",
            json=audio_request,
            headers={'Content-Type': 'application/json'},
            timeout=15
        )
        
        print(f"   ステータス: {response.status_code}")
        
        if response.status_code == 200:
            print(f"✅ 音声文字起こしAPI利用可能")
        elif response.status_code == 404:
            print(f"ℹ️ 音声文字起こしAPIエンドポイントが見つかりません")
            print(f"   利用可能エンドポイント:")
            print(f"     - POST /api/v1/ai/speech-to-json")
            print(f"     - GET /health")
        else:
            print(f"⚠️ 音声文字起こしAPI応答: {response.status_code}")
            
    except requests.exceptions.RequestException as e:
        print(f"❌ 音声文字起こしAPIエラー: {e}")

def generate_api_documentation(base_url: str):
    """API仕様書生成"""
    print_section("API仕様書")
    
    print(f"""
🌐 バックエンドAPI仕様 (ADK準拠版)

【ベースURL】
{base_url}

【主要エンドポイント】
1. GET /health
   - ヘルスチェック
   - レスポンス: {{"status": "ok", "service": "...", "firebase_initialized": true}}

2. POST /api/v1/ai/speech-to-json
   - 音声→学級通信JSON変換 (ADK準拠)
   - Content-Type: application/json
   
   【リクエスト例】
   {{
     "transcribed_text": "今日は...",
     "use_adk_compliant": true,     // ADK準拠システム使用
     "teacher_profile": {{"grade_level": "3年1組"}},
     "style": "modern",
     "force_legacy": false          // レガシーシステム強制使用しない
   }}
   
   【レスポンス例】
   {{
     "success": true,
     "data": {{
       "html_content": "<h1>...",    // 生成されたHTML
       "quality_score": 85,          // 品質スコア (ADK準拠のみ)
       "processing_info": {{         // 処理情報 (ADK準拠のみ)
         "workflow_type": "hybrid_optimized",
         "processing_time": 1.5,
         "execution_id": "uuid"
       }}
     }},
     "system_metadata": {{
       "system_used": "adk_compliant",  // 使用されたシステム
       "adk_compliant": true,
       "migration_percentage": 50,
       "timestamp": "2025-06-19T20:30:00Z"
     }}
   }}

【フロントエンド連携】
- Flutter Web アプリ
- config/app_config.dart で API_BASE_URL 設定
- services/ai_service.dart でAPI呼び出し
- 環境変数での切り替え対応

【開発環境】
- ローカル: http://localhost:8081/api/v1/ai
- ステージング: https://staging-yutori-backend.asia-northeast1.run.app/api/v1/ai  
- 本番: https://yutori-backend-944053509139.asia-northeast1.run.app/api/v1/ai

【ADK準拠システム特徴】
- 段階的移行対応 (migration_percentage で制御)
- 品質スコア付き出力
- ワークフロー情報付き
- 自動フォールバック機能
""")

def main():
    """メイン実行"""
    print("🚀 フロントエンド・バックエンド連携確認デモ")
    print(f"実行時刻: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    # Step 1: バックエンド接続確認
    active_url = test_backend_health()
    
    if not active_url:
        print("\n❌ 利用可能なバックエンドが見つかりません")
        print("\n🔧 バックエンド起動方法:")
        print("   cd backend/functions")
        print("   python main.py")
        print("   # または")
        print("   make dev")
        return
    
    print(f"\n✅ アクティブバックエンド: {active_url}")
    
    # Step 2: API機能テスト
    test_speech_to_json_api(active_url)
    
    # Step 3: フロントエンド互換性テスト
    test_frontend_api_compatibility(active_url)
    
    # Step 4: 音声APIテスト
    test_audio_transcription_api(active_url)
    
    # Step 5: API仕様書表示
    generate_api_documentation(active_url)
    
    print(f"\n🎉 連携確認デモ完了!")
    print(f"\n📱 フロントエンド起動方法:")
    print(f"   cd frontend")
    print(f"   flutter run -d chrome --dart-define=API_BASE_URL={active_url}/api/v1/ai")

if __name__ == "__main__":
    main()