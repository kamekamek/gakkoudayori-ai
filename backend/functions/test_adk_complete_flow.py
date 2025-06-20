#!/usr/bin/env python3
"""
ADK完全フロー統合テスト

音声入力から最終配信までの完全なパイプラインをテスト
"""

import asyncio
import json
import time
from datetime import datetime
from typing import Dict, Any

async def test_complete_adk_flow():
    """音声→PDF・配信完全フローのテスト"""
    print("🌟 ADK完全フロー統合テスト開始")
    print("🎯 目標: 音声入力 → マルチエージェント処理 → PDF/配信")
    print("=" * 60)
    
    # テストデータ
    test_audio_transcript = """
    今日は運動会の練習をしました。
    子どもたちは徒競走とダンスの練習を頑張っていました。
    特にたかしくんは最初は走るのが苦手でしたが、
    毎日練習を重ねて今ではクラスで3番目に速くなりました。
    
    さやかちゃんはダンスがとても上手で、みんなのお手本になっています。
    みんなで応援し合う姿が印象的でした。
    
    運動会当日は、保護者の皆様もぜひ子どもたちの成長した姿をご覧ください。
    一生懸命練習した成果をきっと見せてくれると思います。
    """
    
    teacher_profile = {
        "name": "田中花子",
        "writing_style": "温かく親しみやすい",
        "grade": "3年1組",
        "school": "さくら小学校"
    }
    
    generation_options = {
        "include_pdf": True,
        "include_images": True,
        "include_publishing": True,
        "quality_check": True,
        "media_requests": [
            {"type": "image", "description": "運動会練習の様子", "position": "center"},
            {"type": "image", "description": "子どもたちの集合写真", "position": "footer"}
        ]
    }
    
    total_start_time = time.time()
    results = {}
    
    # Phase 1: 基本ADK処理
    print("📝 Phase 1: 基本コンテンツ生成（既存ADK）")
    try:
        from adk_official_service import generate_newsletter_with_official_adk
        
        phase1_start = time.time()
        basic_result = await generate_newsletter_with_official_adk(
            audio_transcript=test_audio_transcript,
            teacher_profile=teacher_profile,
            grade_level=teacher_profile["grade"]
        )
        phase1_time = time.time() - phase1_start
        
        if basic_result.get("success"):
            print(f"  ✅ 基本生成成功 ({phase1_time:.2f}s)")
            basic_data = basic_result.get("data", {})
            print(f"  📝 コンテンツ長: {len(basic_data.get('content', ''))} 文字")
            print(f"  🏗️ HTML長: {len(basic_data.get('html', ''))} 文字")
            print(f"  📋 セクション数: {len(basic_data.get('sections', []))}")
            
            results["phase1"] = {
                "success": True,
                "time": phase1_time,
                "content": basic_data.get("content", ""),
                "html": basic_data.get("html", ""),
                "design_spec": basic_data.get("design_spec", "{}"),
                "sections": basic_data.get("sections", [])
            }
        else:
            print(f"  ❌ 基本生成失敗: {basic_result.get('error', 'Unknown error')}")
            results["phase1"] = {"success": False, "error": basic_result.get("error")}
    
    except Exception as e:
        print(f"  ❌ Phase 1例外: {e}")
        results["phase1"] = {"success": False, "error": str(e)}
    
    # Phase 2: PDF生成
    print(f"\\n📄 Phase 2: PDF生成")
    if results["phase1"]["success"]:
        try:
            from adk_enhanced_service import pdf_generator_tool
            
            phase2_start = time.time()
            pdf_result = pdf_generator_tool(
                html_content=results["phase1"]["html"],
                metadata={
                    "title": f"学級通信 - {teacher_profile['grade']}",
                    "author": teacher_profile["name"],
                    "subject": "運動会練習の様子",
                    "creator": "学校だよりAI"
                },
                output_format="A4"
            )
            phase2_time = time.time() - phase2_start
            
            if pdf_result.get("status") == "success":
                print(f"  ✅ PDF生成成功 ({phase2_time:.2f}s)")
                pdf_metadata = pdf_result.get("metadata", {})
                print(f"  📊 PDFサイズ: {pdf_metadata.get('file_size', 0)} bytes")
                print(f"  📑 推定ページ数: {pdf_metadata.get('pages_estimated', 1)}")
                
                results["phase2"] = {
                    "success": True,
                    "time": phase2_time,
                    "pdf_size": pdf_metadata.get("file_size", 0),
                    "pdf_data": pdf_result.get("report", "")[:100] + "..."  # 先頭100文字のみ
                }
            else:
                print(f"  ❌ PDF生成失敗: {pdf_result.get('report', 'Unknown error')}")
                results["phase2"] = {"success": False, "error": pdf_result.get("report")}
        
        except Exception as e:
            print(f"  ❌ Phase 2例外: {e}")
            results["phase2"] = {"success": False, "error": str(e)}
    else:
        print("  ⏭️ Phase 1失敗のためスキップ")
        results["phase2"] = {"success": False, "error": "Phase 1 failed"}
    
    # Phase 3: 画像・メディア統合
    print(f"\\n🖼️ Phase 3: 画像・メディア統合")
    try:
        from adk_enhanced_service import image_generator_tool, media_integration_tool
        
        phase3_start = time.time()
        
        # 画像生成
        image_result = image_generator_tool(
            content_description="運動会練習での子どもたちの頑張り",
            style_preferences={
                "color_scheme": "warm",
                "season": "summer", 
                "target_age": "elementary"
            },
            image_type="school_activity"
        )
        
        # メディア統合
        media_result = media_integration_tool(
            media_requests=generation_options.get("media_requests", []),
            content_context=results["phase1"].get("content", "")
        )
        
        phase3_time = time.time() - phase3_start
        
        image_success = image_result.get("status") == "success"
        media_success = media_result.get("status") == "success"
        
        if image_success and media_success:
            print(f"  ✅ メディア統合成功 ({phase3_time:.2f}s)")
            
            image_metadata = image_result.get("metadata", {})
            media_metadata = media_result.get("metadata", {})
            
            print(f"  🖼️ 生成画像: {image_metadata.get('width')}x{image_metadata.get('height')} PNG")
            print(f"  📦 統合メディア数: {media_metadata.get('media_count', 0)}")
            
            results["phase3"] = {
                "success": True,
                "time": phase3_time,
                "image_size": f"{image_metadata.get('width')}x{image_metadata.get('height')}",
                "media_count": media_metadata.get("media_count", 0)
            }
        else:
            error_msg = []
            if not image_success:
                error_msg.append(f"画像生成失敗: {image_result.get('report', 'Unknown')}")
            if not media_success:
                error_msg.append(f"メディア統合失敗: {media_result.get('report', 'Unknown')}")
            
            print(f"  ❌ メディア処理失敗: {'; '.join(error_msg)}")
            results["phase3"] = {"success": False, "error": "; ".join(error_msg)}
    
    except Exception as e:
        print(f"  ❌ Phase 3例外: {e}")
        results["phase3"] = {"success": False, "error": str(e)}
    
    # Phase 4: 教室投稿・配信
    print(f"\\n📤 Phase 4: 教室投稿・配信")
    if results["phase1"]["success"]:
        try:
            from adk_enhanced_service import classroom_publishing_tool
            
            phase4_start = time.time()
            
            newsletter_data = {
                "title": f"学級通信 - {teacher_profile['grade']}",
                "content": results["phase1"]["content"],
                "html": results["phase1"]["html"],
                "author": teacher_profile["name"],
                "grade": teacher_profile["grade"],
                "school": teacher_profile.get("school", "さくら小学校"),
                "images": [req["description"] for req in generation_options.get("media_requests", []) if req["type"] == "image"],
                "has_pdf": results["phase2"]["success"]
            }
            
            distribution_settings = {
                "target_audience": ["parents", "students"],
                "delivery_method": ["email", "web_portal", "mobile_app"],
                "schedule": "immediate",
                "format": ["html", "pdf"] if results["phase2"]["success"] else ["html"]
            }
            
            publishing_result = classroom_publishing_tool(newsletter_data, distribution_settings)
            phase4_time = time.time() - phase4_start
            
            if publishing_result.get("status") == "success":
                print(f"  ✅ 配信準備成功 ({phase4_time:.2f}s)")
                
                pub_metadata = publishing_result.get("metadata", {})
                pub_report = json.loads(publishing_result.get("report", "{}"))
                
                print(f"  📄 出版ID: {pub_metadata.get('publication_id', 'N/A')}")
                print(f"  👥 推定受信者: {pub_metadata.get('recipients_count', 0)}名")
                print(f"  📡 配信方法: {pub_metadata.get('delivery_methods', 0)}種類")
                
                # 配信URLの表示
                distribution_report = pub_report.get("distribution_report", {})
                web_url = distribution_report.get("web_portal_url", "N/A")
                print(f"  🌐 Web URL: {web_url}")
                
                results["phase4"] = {
                    "success": True,
                    "time": phase4_time,
                    "publication_id": pub_metadata.get("publication_id"),
                    "recipients": pub_metadata.get("recipients_count", 0),
                    "web_url": web_url
                }
            else:
                print(f"  ❌ 配信準備失敗: {publishing_result.get('report', 'Unknown error')}")
                results["phase4"] = {"success": False, "error": publishing_result.get("report")}
        
        except Exception as e:
            print(f"  ❌ Phase 4例外: {e}")
            results["phase4"] = {"success": False, "error": str(e)}
    else:
        print("  ⏭️ Phase 1失敗のためスキップ")
        results["phase4"] = {"success": False, "error": "Phase 1 failed"}
    
    total_time = time.time() - total_start_time
    
    # 総合結果
    print("\\n" + "=" * 60)
    print("🎯 完全フロー統合テスト結果")
    print("-" * 40)
    
    successful_phases = sum(1 for phase in results.values() if phase.get("success", False))
    total_phases = len(results)
    
    print(f"⏱️ 総処理時間: {total_time:.2f}秒")
    print(f"🎯 成功率: {successful_phases}/{total_phases} ({successful_phases/total_phases*100:.1f}%)")
    
    for phase_name, result in results.items():
        status = "✅" if result.get("success", False) else "❌"
        time_info = f"({result.get('time', 0):.2f}s)" if result.get("time") else ""
        print(f"  {status} {phase_name}: {time_info}")
        
        if result.get("success", False):
            # 各フェーズの成果物表示
            if phase_name == "phase1":
                print(f"    📝 {len(result.get('content', ''))}文字のコンテンツ生成")
                print(f"    🏗️ {len(result.get('html', ''))}文字のHTML生成")
            elif phase_name == "phase2":
                print(f"    📄 {result.get('pdf_size', 0)} bytes のPDF生成")
            elif phase_name == "phase3":
                print(f"    🖼️ {result.get('image_size', 'N/A')} の画像生成")
                print(f"    📦 {result.get('media_count', 0)}個のメディア統合")
            elif phase_name == "phase4":
                print(f"    📤 {result.get('recipients', 0)}名への配信準備")
                print(f"    📄 ID: {result.get('publication_id', 'N/A')}")
    
    # パフォーマンス分析
    print(f"\\n📊 パフォーマンス分析:")
    if results["phase1"]["success"]:
        phase1_time = results["phase1"]["time"]
        phase2_time = results["phase2"].get("time", 0)
        phase3_time = results["phase3"].get("time", 0)
        phase4_time = results["phase4"].get("time", 0)
        
        print(f"  🚀 最速フェーズ: Phase 3 (メディア) - {phase3_time:.2f}s")
        print(f"  🐌 最遅フェーズ: Phase 1 (基本生成) - {phase1_time:.2f}s")
        print(f"  ⚡ 平均処理時間: {total_time/total_phases:.2f}s/フェーズ")
    
    # 品質評価
    print(f"\\n🏆 品質評価:")
    if successful_phases == total_phases:
        print("  🎉 完璧！全フェーズ成功 - 本格運用可能レベル")
    elif successful_phases >= 3:
        print("  ✨ 優秀！主要機能動作 - 実用レベル")
    elif successful_phases >= 2:
        print("  👍 良好！基本機能動作 - 開発継続推奨")
    else:
        print("  ⚠️ 要改善！基盤見直し必要")
    
    return results


if __name__ == "__main__":
    # 完全フロー統合テスト実行
    asyncio.run(test_complete_adk_flow())