#!/usr/bin/env python3
"""
ADK拡張機能テスト

Phase 5で追加されたPDF出力・画像生成・教室投稿機能のテスト
"""

import asyncio
import json
import time
from datetime import datetime
from typing import Dict, Any

# 拡張機能のテスト
def test_pdf_generator():
    """PDF生成ツールのテスト"""
    print("📄 PDF生成ツールテスト開始")
    
    try:
        from adk_enhanced_service import pdf_generator_tool
        
        test_html = '''
        <h1 style="color: #4CAF50;">学級通信 6月号</h1>
        <h2>今日の様子</h2>
        <p>今日は運動会の練習をしました。子どもたちは徒競走とダンスの練習を頑張っていました。</p>
        <p>特にたかしくんは最初は走るのが苦手でしたが、毎日練習を重ねて今ではクラスで3番目に速くなりました。</p>
        <div class="highlight">
        <p><strong>保護者の皆様へ</strong></p>
        <p>運動会当日は、子どもたちの頑張りをぜひ応援してください。</p>
        </div>
        '''
        
        metadata = {
            "title": "学級通信 6月号",
            "author": "田中花子先生",
            "subject": "運動会練習の様子",
            "creator": "学校だよりAI"
        }
        
        start_time = time.time()
        result = pdf_generator_tool(test_html, metadata, "A4")
        processing_time = time.time() - start_time
        
        print(f"⏱️ 処理時間: {processing_time:.2f}秒")
        print(f"✅ 成功: {result.get('status') == 'success'}")
        
        if result.get('status') == 'success':
            metadata = result.get('metadata', {})
            print(f"📊 ファイルサイズ: {metadata.get('file_size', 0)} bytes")
            print(f"📑 推定ページ数: {metadata.get('pages_estimated', 1)}")
            print(f"📋 タイトル: {metadata.get('title', 'N/A')}")
            
            # Base64データの確認
            pdf_data = result.get('report', '')
            print(f"📦 PDF Base64データ長: {len(pdf_data)} 文字")
            
            return {"success": True, "file_size": metadata.get('file_size', 0), "time": processing_time}
        else:
            print(f"❌ エラー: {result.get('report', 'Unknown error')}")
            return {"success": False, "error": result.get('report')}
            
    except Exception as e:
        print(f"❌ 例外発生: {e}")
        return {"success": False, "error": str(e)}


def test_image_generator():
    """画像生成ツールのテスト"""
    print("\n🖼️ 画像生成ツールテスト開始")
    
    try:
        from adk_enhanced_service import image_generator_tool
        
        style_preferences = {
            "color_scheme": "warm",
            "season": "summer",
            "target_age": "elementary"
        }
        
        start_time = time.time()
        result = image_generator_tool(
            "運動会の練習風景 - 子どもたちが徒競走の練習をしている様子",
            style_preferences,
            "illustration"
        )
        processing_time = time.time() - start_time
        
        print(f"⏱️ 処理時間: {processing_time:.2f}秒")
        print(f"✅ 成功: {result.get('status') == 'success'}")
        
        if result.get('status') == 'success':
            metadata = result.get('metadata', {})
            print(f"🖼️ 画像サイズ: {metadata.get('width')}x{metadata.get('height')}")
            print(f"🎨 スタイル: {metadata.get('style', {})}")
            print(f"📦 フォーマット: {metadata.get('format', 'N/A')}")
            
            # Base64データの確認
            img_data = result.get('report', '')
            print(f"📦 画像 Base64データ長: {len(img_data)} 文字")
            
            return {"success": True, "size": f"{metadata.get('width')}x{metadata.get('height')}", "time": processing_time}
        else:
            print(f"❌ エラー: {result.get('report', 'Unknown error')}")
            return {"success": False, "error": result.get('report')}
            
    except Exception as e:
        print(f"❌ 例外発生: {e}")
        return {"success": False, "error": str(e)}


def test_classroom_publishing():
    """教室投稿ツールのテスト"""
    print("\n📤 教室投稿ツールテスト開始")
    
    try:
        from adk_enhanced_service import classroom_publishing_tool
        
        newsletter_data = {
            "title": "学級通信 6月号",
            "content": "今日は運動会の練習をしました。子どもたちは一生懸命取り組んでいました。",
            "author": "田中花子",
            "grade": "3年1組",
            "images": ["運動会練習.jpg", "集合写真.jpg"]
        }
        
        distribution_settings = {
            "target_audience": ["parents", "students"],
            "delivery_method": ["email", "web_portal", "mobile_app"],
            "schedule": "immediate",
            "format": ["html", "pdf"]
        }
        
        start_time = time.time()
        result = classroom_publishing_tool(newsletter_data, distribution_settings)
        processing_time = time.time() - start_time
        
        print(f"⏱️ 処理時間: {processing_time:.2f}秒")
        print(f"✅ 成功: {result.get('status') == 'success'}")
        
        if result.get('status') == 'success':
            metadata = result.get('metadata', {})
            print(f"📄 出版ID: {metadata.get('publication_id', 'N/A')}")
            print(f"👥 推定受信者数: {metadata.get('recipients_count', 0)}")
            print(f"📡 配信方法数: {metadata.get('delivery_methods', 0)}")
            
            # 配信レポートの詳細確認
            report_data = json.loads(result.get('report', '{}'))
            distribution_report = report_data.get('distribution_report', {})
            
            print(f"🌐 Web Portal URL: {distribution_report.get('web_portal_url', 'N/A')}")
            print(f"📱 モバイル最適化: {distribution_report.get('mobile_optimized', False)}")
            print(f"♿ アクセシビリティ対応: {distribution_report.get('accessibility_compliant', False)}")
            
            return {
                "success": True, 
                "publication_id": metadata.get('publication_id'),
                "recipients": metadata.get('recipients_count', 0),
                "time": processing_time
            }
        else:
            print(f"❌ エラー: {result.get('report', 'Unknown error')}")
            return {"success": False, "error": result.get('report')}
            
    except Exception as e:
        print(f"❌ 例外発生: {e}")
        return {"success": False, "error": str(e)}


def test_media_integration():
    """メディア統合ツールのテスト"""
    print("\n🎬 メディア統合ツールテスト開始")
    
    try:
        from adk_enhanced_service import media_integration_tool
        
        media_requests = [
            {
                "type": "image",
                "description": "運動会練習の様子",
                "position": "center"
            },
            {
                "type": "video",
                "description": "ダンス練習動画",
                "position": "inline"
            },
            {
                "type": "audio",
                "description": "子どもたちの声援",
                "position": "sidebar"
            }
        ]
        
        content_context = "運動会の練習について書かれた学級通信で、子どもたちの成長を保護者に伝える内容"
        
        start_time = time.time()
        result = media_integration_tool(media_requests, content_context)
        processing_time = time.time() - start_time
        
        print(f"⏱️ 処理時間: {processing_time:.2f}秒")
        print(f"✅ 成功: {result.get('status') == 'success'}")
        
        if result.get('status') == 'success':
            metadata = result.get('metadata', {})
            print(f"📦 メディア総数: {metadata.get('media_count', 0)}")
            print(f"📖 コンテキスト解析: {metadata.get('context_analyzed', False)}")
            
            # 統合レポートの詳細確認
            report_data = json.loads(result.get('report', '{}'))
            integration_report = report_data.get('integration_report', {})
            processed_media = report_data.get('processed_media', [])
            
            print(f"🖼️ 画像数: {integration_report.get('images', 0)}")
            print(f"🎥 動画数: {integration_report.get('videos', 0)}")
            print(f"🔊 音声数: {integration_report.get('audio', 0)}")
            print(f"💾 推定ファイルサイズ: {integration_report.get('file_size_estimated', 'N/A')}")
            
            # 処理されたメディアの詳細
            for i, media in enumerate(processed_media):
                print(f"  #{i+1}: {media['type']} - {media['description']} ({media['position']})")
            
            return {
                "success": True,
                "media_count": metadata.get('media_count', 0),
                "images": integration_report.get('images', 0),
                "videos": integration_report.get('videos', 0),
                "audio": integration_report.get('audio', 0),
                "time": processing_time
            }
        else:
            print(f"❌ エラー: {result.get('report', 'Unknown error')}")
            return {"success": False, "error": result.get('report')}
            
    except Exception as e:
        print(f"❌ 例外発生: {e}")
        return {"success": False, "error": str(e)}


def test_enhanced_service_architecture():
    """拡張サービスアーキテクチャのテスト"""
    print("\n🏗️ 拡張サービスアーキテクチャテスト開始")
    
    try:
        from adk_enhanced_service import EnhancedADKNewsletterService
        
        start_time = time.time()
        service = EnhancedADKNewsletterService()
        initialization_time = time.time() - start_time
        
        print(f"⏱️ 初期化時間: {initialization_time:.2f}秒")
        print(f"✅ サービス初期化: 成功")
        
        # エージェント構成の確認
        if service.coordinator_agent:
            sub_agents = service.coordinator_agent.sub_agents
            print(f"👥 エージェント総数: {len(sub_agents) + 1} (coordinator + {len(sub_agents)} specialists)")
            
            agent_names = [agent.name for agent in sub_agents]
            print(f"🤖 専門エージェント:")
            for i, name in enumerate(agent_names, 1):
                print(f"  {i}. {name}")
            
            return {
                "success": True,
                "total_agents": len(sub_agents) + 1,
                "specialist_agents": len(sub_agents),
                "agent_names": agent_names,
                "initialization_time": initialization_time
            }
        else:
            print(f"⚠️ コーディネーターエージェントが初期化されていません")
            return {"success": False, "error": "Coordinator agent not initialized"}
            
    except Exception as e:
        print(f"❌ 例外発生: {e}")
        return {"success": False, "error": str(e)}


# 統合テスト実行
def run_enhanced_features_test():
    """拡張機能の統合テスト実行"""
    print("🚀 ADK拡張機能統合テスト開始")
    print("=" * 60)
    
    results = {}
    
    # 1. アーキテクチャテスト
    print("🏗️ Phase 1: サービスアーキテクチャテスト")
    results["architecture"] = test_enhanced_service_architecture()
    
    # 2. PDF生成テスト
    print("\n📄 Phase 2: PDF生成機能テスト")
    results["pdf_generation"] = test_pdf_generator()
    
    # 3. 画像生成テスト
    print("\n🖼️ Phase 3: 画像生成機能テスト")
    results["image_generation"] = test_image_generator()
    
    # 4. メディア統合テスト
    print("\n🎬 Phase 4: メディア統合機能テスト")
    results["media_integration"] = test_media_integration()
    
    # 5. 教室投稿テスト
    print("\n📤 Phase 5: 教室投稿機能テスト")
    results["classroom_publishing"] = test_classroom_publishing()
    
    # 総合結果
    print("\n" + "=" * 60)
    print("📊 拡張機能テスト結果")
    print("-" * 40)
    
    success_count = sum(1 for result in results.values() 
                       if isinstance(result, dict) and result.get('success', False))
    total_tests = len(results)
    
    print(f"🎯 成功率: {success_count}/{total_tests} ({success_count/total_tests*100:.1f}%)")
    
    for test_name, result in results.items():
        status = "✅" if (isinstance(result, dict) and result.get('success', False)) else "❌"
        print(f"  {status} {test_name}")
        
        if isinstance(result, dict) and result.get('success', False):
            # 詳細情報の表示
            if test_name == "architecture":
                print(f"    👥 エージェント数: {result.get('total_agents', 0)}")
            elif test_name == "pdf_generation":
                print(f"    📊 ファイルサイズ: {result.get('file_size', 0)} bytes")
            elif test_name == "image_generation":
                print(f"    🖼️ 画像サイズ: {result.get('size', 'N/A')}")
            elif test_name == "media_integration":
                print(f"    📦 メディア数: {result.get('media_count', 0)}")
            elif test_name == "classroom_publishing":
                print(f"    👥 受信者数: {result.get('recipients', 0)}")
    
    # 推奨事項
    print(f"\n📋 推奨事項:")
    if results["architecture"]["success"]:
        print("  ✅ 拡張ADKアーキテクチャ正常動作")
    else:
        print("  ⚠️ ADKアーキテクチャに問題があります")
    
    if results["pdf_generation"]["success"]:
        print("  ✅ PDF生成機能利用可能")
    else:
        print("  ⚠️ PDF生成にはWeasyPrintインストールが必要")
    
    if results["image_generation"]["success"]:
        print("  ✅ 画像生成機能利用可能")
    else:
        print("  ⚠️ 画像生成にはPillowインストールが必要")
    
    return results


if __name__ == "__main__":
    # 統合テスト実行
    results = run_enhanced_features_test()