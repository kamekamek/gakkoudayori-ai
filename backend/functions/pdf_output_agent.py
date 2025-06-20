"""
PDF出力エージェント - ADKマルチエージェントシステム統合

学級通信のHTML→PDF変換と配布準備を専門化するエージェント
Google ADKとの統合により教育現場向けの最適化を実現
"""

import asyncio
import json
import logging
import os
import tempfile
import time
from typing import Dict, Any, List, Optional, Tuple
from datetime import datetime
from pathlib import Path

# Google ADK imports
try:
    from google.adk.agents import LlmAgent, Agent
    from google.adk.tools import google_search
    from google.adk.orchestration import Sequential, Parallel
    ADK_AVAILABLE = True
except ImportError:
    ADK_AVAILABLE = False
    logging.warning("Google ADK not available, using fallback implementation")

# 既存PDF生成機能
from pdf_generator import (
    generate_pdf_from_html,
    create_pdf_preview_image,
    get_pdf_info,
    cleanup_temp_files,
    _clean_markdown_codeblocks_pdf
)

# Vertex AI integration
from gemini_api_service import generate_text

logger = logging.getLogger(__name__)


# ==============================================================================
# PDF出力専用ツール定義
# ==============================================================================

def optimize_html_for_pdf(
    html_content: str,
    page_size: str = "A4",
    print_quality: str = "high"
) -> str:
    """HTML内容をPDF出力向けに最適化するツール"""
    
    prompt = f"""
    あなたはPDF出力の専門家です。
    以下のHTMLコンテンツを、A4印刷に最適化してください：
    
    HTML内容: {html_content}
    
    最適化要件：
    - {page_size}サイズでの印刷に適したレイアウト
    - 教育現場での配布を想定した読みやすさ
    - フォントサイズと行間の調整
    - 改ページ位置の最適化
    - 余白とマージンの調整
    
    制約:
    - 既存のコンテンツ内容は保持
    - HTMLタグ制限を遵守
    - インラインスタイルのみ使用
    
    出力: 最適化されたHTMLコンテンツのみ
    """
    
    try:
        response = generate_text(
            prompt=prompt,
            project_id="your-project-id",
            credentials_path="path/to/credentials.json",
            model_name="gemini-2.5-flash-preview-05-20",
            temperature=0.1,
            max_output_tokens=4096
        )
        
        if response and response.get("success"):
            optimized_html = response.get("data", {}).get("text", html_content)
            # Markdownコードブロックのクリーンアップ
            optimized_html = _clean_markdown_codeblocks_pdf(optimized_html)
            return optimized_html
        else:
            logger.warning("HTML最適化に失敗、元のHTMLを使用")
            return html_content
            
    except Exception as e:
        logger.error(f"HTML最適化エラー: {e}")
        return html_content


def generate_pdf_filename(
    title: str,
    grade: str,
    issue_date: str,
    template: str = "newsletter"
) -> str:
    """学級通信のファイル名を自動生成するツール"""
    
    try:
        # 日付の正規化
        normalized_date = datetime.now().strftime("%Y%m%d")
        if issue_date:
            try:
                # 各種日付フォーマットを試行
                for fmt in ["%Y年%m月%d日", "%Y-%m-%d", "%Y/%m/%d"]:
                    try:
                        parsed_date = datetime.strptime(issue_date, fmt)
                        normalized_date = parsed_date.strftime("%Y%m%d")
                        break
                    except ValueError:
                        continue
            except Exception:
                pass
        
        # 学年の正規化
        normalized_grade = grade.replace("年", "").replace("組", "").replace("第", "").replace("学年", "")
        normalized_grade = "".join([c for c in normalized_grade if c.isalnum()])
        
        # タイトルの正規化（ファイル名に適さない文字を除去）
        normalized_title = title.replace("学級通信", "").strip()
        normalized_title = "".join([c for c in normalized_title if c.isalnum() or c in "ーー"])
        if not normalized_title:
            normalized_title = "newsletter"
        
        # ファイル名構築
        filename = f"gakkyu_tsushin_{normalized_grade}_{normalized_date}_{normalized_title}.pdf"
        
        # 長すぎる場合は短縮
        if len(filename) > 100:
            filename = f"gakkyu_tsushin_{normalized_grade}_{normalized_date}.pdf"
        
        return filename
        
    except Exception as e:
        logger.error(f"ファイル名生成エラー: {e}")
        return f"gakkyu_tsushin_{datetime.now().strftime('%Y%m%d')}.pdf"


def analyze_pdf_quality(
    pdf_path: str,
    expected_content: Dict[str, Any]
) -> Dict[str, Any]:
    """生成されたPDFの品質を分析するツール"""
    
    try:
        # PDF基本情報を取得
        pdf_info = get_pdf_info(pdf_path)
        
        if not pdf_info["success"]:
            return {
                "quality_score": 0,
                "issues": ["PDFファイルが読み取れません"],
                "recommendations": ["PDF生成を再実行してください"]
            }
        
        issues = []
        recommendations = []
        quality_score = 100
        
        file_info = pdf_info["data"]
        
        # ファイルサイズチェック
        file_size_mb = file_info["file_size_mb"]
        if file_size_mb > 10:
            issues.append("ファイルサイズが大きすぎます")
            recommendations.append("画像サイズを最適化してください")
            quality_score -= 20
        elif file_size_mb < 0.1:
            issues.append("ファイルサイズが小さすぎます")
            recommendations.append("コンテンツが正しく生成されているか確認してください")
            quality_score -= 30
        
        # ページ数チェック
        page_count = file_info["page_count"]
        if page_count > 3:
            issues.append("ページ数が多すぎます")
            recommendations.append("コンテンツを簡潔にまとめてください")
            quality_score -= 15
        
        # 予期されるコンテンツの長さチェック
        expected_sections = expected_content.get("sections", [])
        if len(expected_sections) > 0:
            avg_section_length = sum(len(s.get("content", "")) for s in expected_sections) / len(expected_sections)
            if avg_section_length < 50:
                issues.append("コンテンツが短すぎる可能性があります")
                recommendations.append("各セクションの内容を充実させてください")
                quality_score -= 10
        
        # 評価カテゴリ決定
        if quality_score >= 80:
            assessment = "excellent"
        elif quality_score >= 60:
            assessment = "good"  
        elif quality_score >= 40:
            assessment = "fair"
        else:
            assessment = "poor"
        
        return {
            "quality_score": max(0, quality_score),
            "assessment": assessment,
            "file_size_mb": file_size_mb,
            "page_count": page_count,
            "issues": issues,
            "recommendations": recommendations,
            "pdf_info": file_info
        }
        
    except Exception as e:
        logger.error(f"PDF品質分析エラー: {e}")
        return {
            "quality_score": 0,
            "assessment": "error",
            "issues": [f"分析エラー: {str(e)}"],
            "recommendations": ["PDF生成を再実行してください"]
        }


# ==============================================================================
# PDF出力エージェント本体
# ==============================================================================

class PDFOutputAgent:
    """PDF出力専門エージェント - ADK統合対応"""
    
    def __init__(self, project_id: str, credentials_path: str):
        self.project_id = project_id
        self.credentials_path = credentials_path
        self.agent = None
        
        if ADK_AVAILABLE:
            self._initialize_adk_agent()
        else:
            logger.warning("ADK not available for PDFOutputAgent, using fallback mode")
    
    def _initialize_adk_agent(self):
        """ADKエージェントの初期化"""
        
        self.agent = LlmAgent(
            model="gemini-2.5-pro-preview-06-05",
            name="pdf_output_agent",
            description="学級通信HTML→PDF変換と配布準備の専門エージェント",
            instruction="""
            あなたは学級通信のPDF出力と配布準備の専門家です。
            
            専門分野:
            - HTML→PDF変換の最適化
            - A4印刷レイアウトの調整
            - 教育現場向けの読みやすさ改善
            - ファイル名の標準化と管理
            - PDF品質の評価と改善提案
            
            責任:
            - 高品質なPDF出力の保証
            - 印刷時の見栄えの最適化
            - ファイルサイズとアクセシビリティのバランス
            - 教師の配布作業効率化
            
            制約:
            - A4サイズに最適化
            - ファイルサイズは5MB以下
            - 日本語フォント対応必須
            - アクセシビリティ配慮
            """,
            tools=[
                optimize_html_for_pdf,
                generate_pdf_filename,
                analyze_pdf_quality
            ]
        )
    
    async def generate_newsletter_pdf(
        self,
        html_content: str,
        newsletter_data: Dict[str, Any],
        options: Dict[str, Any] = None
    ) -> Dict[str, Any]:
        """学級通信PDFの生成 - ADK統合版"""
        
        start_time = time.time()
        logger.info("PDF出力エージェント: 学級通信PDF生成開始")
        
        try:
            # デフォルトオプション
            default_options = {
                "page_size": "A4",
                "margin": "15mm",
                "include_header": False,
                "include_footer": True,
                "print_quality": "high",
                "auto_optimize": True,
                "generate_preview": True,
                "cleanup_temp": True
            }
            
            options = {**default_options, **(options or {})}
            
            # Step 1: HTML最適化（ADK使用時）
            optimized_html = html_content
            if options.get("auto_optimize", True):
                if ADK_AVAILABLE and self.agent:
                    logger.info("PDF出力エージェント: HTML最適化実行")
                    optimized_html = optimize_html_for_pdf(
                        html_content,
                        page_size=options["page_size"],
                        print_quality=options["print_quality"]
                    )
                else:
                    # フォールバック: 基本的なクリーンアップ
                    optimized_html = _clean_markdown_codeblocks_pdf(html_content)
            
            # Step 2: ファイル名生成
            title = newsletter_data.get("main_title", "学級通信")
            grade = newsletter_data.get("grade", "")
            issue_date = newsletter_data.get("issue_date", "")
            
            filename = generate_pdf_filename(title, grade, issue_date)
            logger.info(f"PDF出力エージェント: 生成ファイル名 = {filename}")
            
            # Step 3: PDF生成
            logger.info("PDF出力エージェント: PDF生成実行")
            pdf_result = generate_pdf_from_html(
                html_content=optimized_html,
                title=title,
                page_size=options["page_size"],
                margin=options["margin"],
                include_header=options["include_header"],
                include_footer=options["include_footer"],
                custom_css=options.get("custom_css", ""),
                output_path=None  # 一時ファイルを使用
            )
            
            if not pdf_result["success"]:
                logger.error(f"PDF出力エージェント: PDF生成失敗 - {pdf_result['error']}")
                return {
                    "success": False,
                    "error": pdf_result["error"],
                    "agent": "pdf_output_agent",
                    "processing_time_ms": int((time.time() - start_time) * 1000)
                }
            
            pdf_path = pdf_result["data"]["pdf_path"]
            
            # Step 4: PDF品質分析
            logger.info("PDF出力エージェント: 品質分析実行")
            quality_analysis = analyze_pdf_quality(pdf_path, newsletter_data)
            
            # Step 5: プレビュー画像生成（オプション）
            preview_data = None
            if options.get("generate_preview", True):
                try:
                    logger.info("PDF出力エージェント: プレビュー画像生成")
                    preview_result = create_pdf_preview_image(
                        pdf_path=pdf_path,
                        page_number=1,
                        width=800,
                        dpi=150
                    )
                    if preview_result["success"]:
                        preview_data = preview_result["data"]
                        logger.info("PDF出力エージェント: プレビュー画像生成完了")
                    else:
                        logger.warning(f"プレビュー画像生成失敗: {preview_result['error']}")
                except Exception as e:
                    logger.warning(f"プレビュー画像生成エラー: {e}")
            
            # Step 6: 最終ファイル名でリネーム
            final_pdf_path = os.path.join(os.path.dirname(pdf_path), filename)
            try:
                os.rename(pdf_path, final_pdf_path)
                pdf_path = final_pdf_path
                logger.info(f"PDF出力エージェント: ファイル名変更完了 = {filename}")
            except Exception as e:
                logger.warning(f"ファイル名変更失敗: {e}, 元のパスを使用")
            
            # 結果の構築
            processing_time = time.time() - start_time
            
            result = {
                "success": True,
                "data": {
                    "pdf_path": pdf_path,
                    "pdf_base64": pdf_result["data"]["pdf_base64"],
                    "filename": filename,
                    "file_size_bytes": pdf_result["data"]["file_size_bytes"],
                    "file_size_mb": pdf_result["data"]["file_size_mb"],
                    "page_count": pdf_result["data"]["page_count"],
                    "quality_analysis": quality_analysis,
                    "preview_image": preview_data,
                    "optimization_applied": options.get("auto_optimize", True),
                    "pdf_options": options
                },
                "metadata": {
                    "agent": "pdf_output_agent",
                    "processing_time_ms": int(processing_time * 1000),
                    "generated_at": datetime.now().isoformat(),
                    "adk_enabled": ADK_AVAILABLE and self.agent is not None,
                    "optimization_method": "adk" if ADK_AVAILABLE else "fallback"
                }
            }
            
            logger.info(f"PDF出力エージェント: 生成完了 ({processing_time:.2f}s)")
            return result
            
        except Exception as e:
            error_msg = f"PDF出力エージェント: 予期せぬエラー - {str(e)}"
            logger.error(error_msg)
            return {
                "success": False,
                "error": error_msg,
                "agent": "pdf_output_agent",
                "processing_time_ms": int((time.time() - start_time) * 1000)
            }
    
    async def batch_generate_pdfs(
        self,
        newsletters: List[Dict[str, Any]],
        options: Dict[str, Any] = None
    ) -> Dict[str, Any]:
        """複数学級通信の一括PDF生成"""
        
        start_time = time.time()
        logger.info(f"PDF出力エージェント: 一括PDF生成開始 ({len(newsletters)}件)")
        
        results = []
        successful_count = 0
        failed_count = 0
        
        for i, newsletter in enumerate(newsletters):
            try:
                logger.info(f"PDF出力エージェント: {i+1}/{len(newsletters)} 処理中")
                
                html_content = newsletter.get("html_content", "")
                newsletter_data = newsletter.get("data", {})
                
                if not html_content:
                    results.append({
                        "success": False,
                        "error": "HTMLコンテンツが空です",
                        "index": i
                    })
                    failed_count += 1
                    continue
                
                result = await self.generate_newsletter_pdf(
                    html_content=html_content,
                    newsletter_data=newsletter_data,
                    options=options
                )
                
                result["index"] = i
                results.append(result)
                
                if result["success"]:
                    successful_count += 1
                else:
                    failed_count += 1
                    
            except Exception as e:
                logger.error(f"一括生成エラー (#{i}): {e}")
                results.append({
                    "success": False,
                    "error": str(e),
                    "index": i
                })
                failed_count += 1
        
        processing_time = time.time() - start_time
        
        return {
            "success": failed_count == 0,
            "results": results,
            "summary": {
                "total_count": len(newsletters),
                "successful_count": successful_count,
                "failed_count": failed_count,
                "success_rate": successful_count / len(newsletters) if newsletters else 0,
                "processing_time_ms": int(processing_time * 1000)
            },
            "agent": "pdf_output_agent"
        }
    
    def cleanup_temp_files(self, file_paths: List[str]) -> int:
        """一時ファイルのクリーンアップ"""
        return cleanup_temp_files(file_paths)


# ==============================================================================
# 統合API関数
# ==============================================================================

async def generate_pdf_with_adk(
    html_content: str,
    newsletter_data: Dict[str, Any],
    project_id: str,
    credentials_path: str,
    options: Dict[str, Any] = None
) -> Dict[str, Any]:
    """
    ADK PDF出力エージェントを使用したPDF生成
    
    Args:
        html_content: PDF化するHTMLコンテンツ
        newsletter_data: 学級通信データ（タイトル、学年等）
        project_id: Google Cloud プロジェクトID
        credentials_path: 認証情報ファイルパス
        options: PDF生成オプション
    
    Returns:
        Dict[str, Any]: PDF生成結果
    """
    agent = PDFOutputAgent(project_id, credentials_path)
    
    result = await agent.generate_newsletter_pdf(
        html_content=html_content,
        newsletter_data=newsletter_data,
        options=options
    )
    
    return result


# ==============================================================================
# テスト機能
# ==============================================================================

async def test_pdf_output_agent():
    """PDF出力エージェントのテスト"""
    
    # テスト用データ
    test_html = """
    <h1 style="color: #2c3e50; text-align: center;">3年1組 学級通信</h1>
    
    <h2 style="color: #3498db;">今日の活動</h2>
    <p>今日は運動会の練習をしました。子どもたちは徒競走とダンスの練習を頑張っていました。</p>
    
    <h3 style="color: #e74c3c;">各教科の様子</h3>
    <ul>
        <li><strong>国語</strong>: 詩の音読発表</li>
        <li><strong>算数</strong>: 九九の練習</li>
        <li><strong>体育</strong>: 運動会の練習</li>
    </ul>
    
    <h2 style="color: #27ae60;">お知らせ</h2>
    <p>来週の運動会に向けて、体操服の準備をお願いします。</p>
    """
    
    test_newsletter_data = {
        "main_title": "3年1組 学級通信",
        "grade": "3年1組",
        "issue_date": "2024年06月19日",
        "school_name": "テスト小学校",
        "sections": [
            {"type": "main", "content": "運動会の練習内容"}
        ]
    }
    
    test_options = {
        "page_size": "A4",
        "auto_optimize": True,
        "generate_preview": True
    }
    
    print("=== PDF出力エージェント テスト ===")
    
    try:
        result = await generate_pdf_with_adk(
            html_content=test_html,
            newsletter_data=test_newsletter_data,
            project_id="test-project",
            credentials_path="test-credentials.json",
            options=test_options
        )
        
        print("=== PDF出力エージェント テスト結果 ===")
        print(json.dumps(result, ensure_ascii=False, indent=2))
        
        if result["success"]:
            print("✅ PDF出力エージェント: テスト成功")
            quality = result["data"]["quality_analysis"]
            print(f"品質スコア: {quality['quality_score']}/100")
            print(f"ファイルサイズ: {result['data']['file_size_mb']} MB")
            print(f"ページ数: {result['data']['page_count']}")
        else:
            print("❌ PDF出力エージェント: テスト失敗")
            print(f"エラー: {result['error']}")
        
        return result
        
    except Exception as e:
        print(f"❌ テストエラー: {e}")
        return {"success": False, "error": str(e)}


if __name__ == "__main__":
    # テスト実行
    asyncio.run(test_pdf_output_agent())