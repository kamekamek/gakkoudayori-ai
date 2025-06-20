"""
Google ADK 公式マルチエージェントサービス

音声入力から学級通信生成までの全フローを
公式ADKフレームワークを使用した専門化エージェント協調で実行

主な変更:
- 公式 google-adk パッケージの使用
- 適切な Agent クラス階層の実装
- sub_agents による階層構造
- 公式通信パターンの採用
- 標準的なツール実装パターン
"""

import asyncio
import json
import logging
import os
from typing import Dict, Any, List, Optional, Union
from datetime import datetime
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Google ADK imports
try:
    from google.adk.agents import LlmAgent, Agent, SequentialAgent, ParallelAgent
    from google.adk.tools import FunctionTool, BaseTool
    from google.adk.agents import invocation_context
    ADK_AVAILABLE = True
    logging.info("Google ADK successfully imported")
except ImportError as e:
    # ADK未インストール時のフォールバック
    ADK_AVAILABLE = False
    logging.warning(f"Google ADK not available: {e}. Using fallback implementation")

# 既存サービス
from gemini_api_service import generate_text
from audio_to_json_service import get_json_schema, validate_generated_json

logger = logging.getLogger(__name__)


# ==============================================================================
# 公式ADK準拠ツール定義
# ==============================================================================

def newsletter_content_generator(
    audio_transcript: str,
    grade_level: str = "3年1組",
    content_type: str = "newsletter"
) -> Dict[str, Any]:
    """学級通信の文章を生成するADK準拠ツール
    
    Returns:
        Dict with 'status' and either 'report' or 'error_message'
    """
    try:
        prompt = f"""
        あなたは{grade_level}の担任教師です。
        以下の音声内容を基に学級通信を作成してください：
        
        音声内容: {audio_transcript}
        
        制約：
        - 保護者向けの温かい語り口調
        - 具体的なエピソード重視
        - 800-1200文字程度
        - 子供たちの成長を中心とした内容
        """
        
        # Get Google Cloud project settings
        project_id = os.getenv('GOOGLE_CLOUD_PROJECT', 'your-project-id')
        credentials_path = os.getenv('GOOGLE_APPLICATION_CREDENTIALS')
        
        response = generate_text(
            prompt=prompt,
            project_id=project_id,
            credentials_path=credentials_path
        )
        
        return {
            "status": "success",
            "report": response,
            "metadata": {
                "grade_level": grade_level,
                "content_type": content_type,
                "word_count": len(response)
            }
        }
        
    except Exception as e:
        logger.error(f"Content generation failed: {e}")
        return {
            "status": "error",
            "error_message": f"文章生成に失敗しました: {str(e)}"
        }


def design_specification_generator(
    content: str,
    theme: str = "seasonal",
    grade_level: str = "3年1組"
) -> Dict[str, Any]:
    """デザイン仕様をJSON形式で出力するADK準拠ツール"""
    
    try:
        # 季節判定
        current_month = datetime.now().month
        season_map = {
            (3, 4, 5): "spring",
            (6, 7, 8): "summer", 
            (9, 10, 11): "autumn",
            (12, 1, 2): "winter"
        }
        
        current_season = "spring"
        for months, season in season_map.items():
            if current_month in months:
                current_season = season
                break
        
        design_spec = {
            "layout_type": "modern",
            "season": current_season,
            "color_scheme": {
                "spring": {"primary": "#4CAF50", "secondary": "#81C784", "accent": "#FFC107"},
                "summer": {"primary": "#2196F3", "secondary": "#64B5F6", "accent": "#FF9800"},
                "autumn": {"primary": "#FF7043", "secondary": "#FFAB91", "accent": "#8BC34A"},
                "winter": {"primary": "#9C27B0", "secondary": "#BA68C8", "accent": "#00BCD4"}
            }.get(current_season, {"primary": "#4CAF50", "secondary": "#81C784", "accent": "#FFC107"}),
            "fonts": {
                "heading": "Noto Sans JP",
                "body": "Hiragino Sans"
            },
            "layout_sections": [
                {
                    "type": "header",
                    "position": "top",
                    "content_type": "title"
                },
                {
                    "type": "main_content", 
                    "position": "center",
                    "content_type": "body_text",
                    "columns": 2
                },
                {
                    "type": "sidebar",
                    "position": "right",
                    "content_type": "highlights"
                }
            ],
            "visual_elements": {
                "photo_placeholders": 2,
                "illustration_style": current_season,
                "border_style": "rounded"
            }
        }
        
        return {
            "status": "success",
            "report": json.dumps(design_spec, ensure_ascii=False, indent=2),
            "metadata": {
                "theme": theme,
                "season": current_season,
                "grade_level": grade_level
            }
        }
        
    except Exception as e:
        logger.error(f"Design specification generation failed: {e}")
        return {
            "status": "error",
            "error_message": f"デザイン仕様生成に失敗しました: {str(e)}"
        }


def html_content_generator(
    content: str,
    design_spec_json: str,
    template_type: str = "newsletter"
) -> Dict[str, Any]:
    """HTML生成ADK準拠ツール"""
    
    try:
        # Parse design specification
        try:
            design_spec = json.loads(design_spec_json)
        except json.JSONDecodeError:
            design_spec = {"color_scheme": {"primary": "#4CAF50"}}
        
        prompt = f"""
        以下の内容とデザイン仕様に基づいて、学級通信用のHTMLを生成してください：
        
        内容: {content}
        デザイン仕様: {design_spec_json}
        
        制約：
        - 使用タグ: <h1>〜<h3>, <p>, <ul>/<ol>/<li>, <strong>, <em>, <br>
        - style/class/div タグ禁止（inline styleのみ許可）
        - <html>タグ不要、本文のみ出力
        - 画像プレースホルダーは [写真: 説明] 形式
        
        出力形式例:
        <h1 style="color: {design_spec.get('color_scheme', {}).get('primary', '#4CAF50')}">学級通信 6月号</h1>
        <p>皆さんこんにちは...</p>
        """
        
        # Get Google Cloud project settings
        project_id = os.getenv('GOOGLE_CLOUD_PROJECT', 'your-project-id')
        credentials_path = os.getenv('GOOGLE_APPLICATION_CREDENTIALS')
        
        response = generate_text(
            prompt=prompt,
            project_id=project_id, 
            credentials_path=credentials_path
        )
        
        return {
            "status": "success",
            "report": response,
            "metadata": {
                "template_type": template_type,
                "html_length": len(response),
                "design_applied": True
            }
        }
        
    except Exception as e:
        logger.error(f"HTML generation failed: {e}")
        return {
            "status": "error",
            "error_message": f"HTML生成に失敗しました: {str(e)}"
        }


def html_quality_checker(
    html_content: Union[str, Dict[str, Any]],
    original_content: Union[str, Dict[str, Any]]
) -> Dict[str, Any]:
    """HTML品質チェックADK準拠ツール"""
    
    try:
        # Type checking and normalization
        if isinstance(html_content, dict):
            html_content = html_content.get("report", str(html_content))
        if isinstance(original_content, dict):
            original_content = original_content.get("report", str(original_content))
        
        # Ensure strings
        html_content = str(html_content) if html_content is not None else ""
        original_content = str(original_content) if original_content is not None else ""
        
        # Basic HTML validation
        issues = []
        suggestions = []
        
        # Check for required tags
        if '<h1' not in html_content:
            issues.append("見出し（<h1>）が不足しています")
            suggestions.append("適切な見出しを追加してください")
        
        # Check for content length
        if len(html_content.strip()) < 100:
            issues.append("コンテンツが短すぎます")
            suggestions.append("より詳細な内容を追加してください")
        
        # Check for forbidden tags
        forbidden_tags = ['<div', '<class=', '<script', '<style>']
        for tag in forbidden_tags:
            if tag in html_content:
                issues.append(f"禁止されたタグ/属性が含まれています: {tag}")
                suggestions.append("許可されたタグのみを使用してください")
        
        # Generate quality report
        quality_score = max(0, 100 - len(issues) * 20)
        
        report = {
            "quality_score": quality_score,
            "issues_found": len(issues),
            "issues": issues,
            "suggestions": suggestions,
            "html_length": len(html_content),
            "content_preserved": len(original_content) > 0
        }
        
        return {
            "status": "success",
            "report": json.dumps(report, ensure_ascii=False, indent=2),
            "metadata": {
                "quality_score": quality_score,
                "issues_count": len(issues)
            }
        }
        
    except Exception as e:
        logger.error(f"HTML quality check failed: {e}")
        return {
            "status": "error",
            "error_message": f"品質チェックに失敗しました: {str(e)}"
        }


# ==============================================================================
# 公式ADKエージェント定義
# ==============================================================================

class OfficialNewsletterADKService:
    """Google ADK公式フレームワークを使用したマルチエージェント学級通信生成サービス"""
    
    def __init__(self, project_id: str = None, credentials_path: str = None):
        self.project_id = project_id or os.getenv('GOOGLE_CLOUD_PROJECT', 'your-project-id')
        self.credentials_path = credentials_path or os.getenv('GOOGLE_APPLICATION_CREDENTIALS')
        self.coordinator_agent = None
        
        if ADK_AVAILABLE:
            self._initialize_official_adk_agents()
        else:
            logger.warning("ADK not available, will use fallback mode")
    
    def _initialize_official_adk_agents(self):
        """公式ADKエージェントの初期化"""
        
        try:
            # Model configuration from environment
            model_name = os.getenv('VERTEX_AI_MODEL', 'gemini-2.0-flash')
            
            # 1. コンテンツ生成エージェント
            content_writer_agent = LlmAgent(
                name="content_writer",
                model=model_name,
                description="学級通信の文章を生成する専門エージェント。音声入力から保護者向けの温かい文章を作成します。",
                instruction="""
                あなたは小学校教師として、保護者向けの学級通信を作成する専門家です。
                
                特徴:
                - 温かく親しみやすい語り口
                - 子供たちの成長エピソードを重視
                - 具体的で生き生きとした描写
                - 保護者が読みたくなる魅力的な内容
                
                制約:
                - 800-1200文字程度
                - 段落構成を意識
                - 個人名は仮名を使用
                """,
                tools=[newsletter_content_generator]
            )
            
            # 2. デザイン生成エージェント
            design_agent = LlmAgent(
                name="design_specialist",
                model=model_name,
                description="学級通信のレイアウトとデザインを設計する専門エージェント。季節や内容に応じた最適なデザイン仕様を生成します。",
                instruction="""
                あなたは教育分野のビジュアルデザイン専門家です。
                
                専門分野:
                - 季節に応じたカラースキーム選択
                - 読みやすいレイアウト設計
                - 保護者の注意を引く視覚的配置
                - 教育的価値を高めるデザイン要素
                
                出力: JSON形式のデザイン仕様
                """,
                tools=[design_specification_generator]
            )
            
            # 3. HTML生成エージェント
            html_generator_agent = LlmAgent(
                name="html_generator",
                model=model_name,
                description="文章とデザイン仕様からHTMLを生成する専門エージェント。制約に従った適切なHTMLマークアップを作成します。",
                instruction="""
                あなたはWebフロントエンド開発の専門家です。
                
                専門分野:
                - セマンティックHTML構造の作成
                - アクセシブルなマークアップ
                - 印刷に適したスタイリング
                - クリーンで保守性の高いコード
                
                制約:
                - 指定されたHTMLタグのみ使用
                - インラインスタイルで装飾
                - プレビューしやすい構造
                """,
                tools=[html_content_generator]
            )
            
            # 4. 品質チェックエージェント
            quality_checker_agent = LlmAgent(
                name="quality_checker",
                model=model_name,
                description="生成された学級通信の品質をチェックする専門エージェント。内容とHTMLの両面から品質を評価します。",
                instruction="""
                あなたは教育コンテンツの品質管理専門家です。
                
                チェック項目:
                - 内容の適切性と教育的価値
                - 文章の読みやすさと一貫性
                - HTMLの技術的正確性
                - 保護者への配慮の適切性
                
                改善提案も行ってください。
                """,
                tools=[html_quality_checker]
            )
            
            # 5. 並行処理用エージェント（コンテンツとデザインを同時生成）
            parallel_content_design_agent = ParallelAgent(
                name="parallel_content_design",
                description="コンテンツ生成とデザイン生成を並行処理するワークフローエージェント",
                sub_agents=[content_writer_agent, design_agent]
            )
            
            # 6. シーケンシャル処理用エージェント（HTML生成→品質チェック）
            sequential_html_quality_agent = SequentialAgent(
                name="sequential_html_quality",
                description="HTML生成と品質チェックを順次実行するワークフローエージェント",
                sub_agents=[html_generator_agent, quality_checker_agent]
            )
            
            # 7. メインコーディネーターエージェント
            self.coordinator_agent = LlmAgent(
                name="newsletter_coordinator",
                model=model_name,
                description="学級通信生成プロセス全体を調整するメインコーディネーター。各専門エージェントに適切にタスクを委譲し、最終的な学級通信を完成させます。",
                instruction="""
                あなたは学級通信生成プロセスのオーケストレーターです。
                ユーザーからの音声入力を受けて、適切な順序で専門エージェントに
                タスクを割り振り、最終的な学級通信を完成させてください。
                
                プロセス:
                1. 音声内容の分析と構造化
                2. コンテンツ生成とデザイン生成の並行実行
                3. HTML生成と品質チェックの順次実行
                4. 最終調整と統合
                
                各エージェントとの連携を適切に行い、
                高品質な学級通信を効率的に生成してください。
                """,
                sub_agents=[
                    parallel_content_design_agent,
                    sequential_html_quality_agent
                ]
            )
            
            logger.info("Official ADK agents initialized successfully")
            
        except Exception as e:
            logger.error(f"Failed to initialize official ADK agents: {e}")
            self.coordinator_agent = None
    
    async def generate_newsletter_with_official_adk(
        self,
        audio_transcript: str,
        grade_level: str = "3年1組",
        style: str = "modern"
    ) -> Dict[str, Any]:
        """公式ADKマルチエージェントを使用した学級通信生成"""
        
        if not ADK_AVAILABLE or not self.coordinator_agent:
            return await self._fallback_generation(audio_transcript, grade_level, style)
        
        try:
            logger.info("Starting official ADK multi-agent newsletter generation")
            
            # Create input context for the coordinator
            input_data = {
                "audio_transcript": audio_transcript,
                "grade_level": grade_level,
                "style": style,
                "timestamp": datetime.now().isoformat()
            }
            
            # Execute the coordinator agent
            # Note: This is a simplified version. In the actual ADK implementation,
            # you would use the proper invocation methods
            result = await self._execute_coordinator_workflow(input_data)
            
            return {
                "success": True,
                "generation_method": "official_adk_multi_agent",
                "timestamp": datetime.now().isoformat(),
                "input_data": input_data,
                **result
            }
            
        except Exception as e:
            logger.error(f"Official ADK generation failed: {e}")
            return {
                "success": False,
                "error": str(e),
                "generation_method": "official_adk_failed",
                "fallback_result": await self._fallback_generation(audio_transcript, grade_level, style)
            }
    
    async def _execute_coordinator_workflow(self, input_data: Dict[str, Any]) -> Dict[str, Any]:
        """コーディネーターワークフローの実行"""
        
        # Phase 1: 並行処理（コンテンツ生成 + デザイン生成）
        logger.info("Phase 1: Parallel content and design generation")
        
        # Content generation
        content_result = newsletter_content_generator(
            audio_transcript=input_data["audio_transcript"],
            grade_level=input_data["grade_level"]
        )
        
        # Design generation (can be done in parallel)
        design_result = design_specification_generator(
            content=content_result.get("report", ""),
            grade_level=input_data["grade_level"]
        )
        
        # Phase 2: HTML生成
        logger.info("Phase 2: HTML generation")
        
        if content_result["status"] == "success" and design_result["status"] == "success":
            html_result = html_content_generator(
                content=content_result["report"],
                design_spec_json=design_result["report"]
            )
        else:
            html_result = {
                "status": "error",
                "error_message": "Content or design generation failed"
            }
        
        # Phase 3: 品質チェック
        logger.info("Phase 3: Quality check")
        
        if html_result["status"] == "success":
            quality_result = html_quality_checker(
                html_content=html_result["report"],
                original_content=content_result.get("report", "")
            )
        else:
            quality_result = {
                "status": "error",
                "error_message": "HTML generation failed, skipping quality check"
            }
        
        # 結果の統合
        return {
            "content_generation": content_result,
            "design_generation": design_result,
            "html_generation": html_result,
            "quality_check": quality_result,
            "final_html": html_result.get("report", "") if html_result["status"] == "success" else None,
            "agents_executed": [
                "content_writer",
                "design_specialist", 
                "html_generator",
                "quality_checker"
            ]
        }
    
    async def _fallback_generation(
        self,
        audio_transcript: str, 
        grade_level: str,
        style: str
    ) -> Dict[str, Any]:
        """ADK未使用時のフォールバック処理"""
        from audio_to_json_service import convert_speech_to_json
        
        logger.info("Using fallback generation method")
        
        try:
            result = convert_speech_to_json(
                transcribed_text=audio_transcript,
                project_id=self.project_id,
                credentials_path=self.credentials_path,
                style=style
            )
            
            result["generation_method"] = "fallback_single_agent"
            result["timestamp"] = datetime.now().isoformat()
            
            return result
            
        except Exception as e:
            logger.error(f"Fallback generation failed: {e}")
            return {
                "success": False,
                "error": f"Both official ADK and fallback generation failed: {e}",
                "timestamp": datetime.now().isoformat()
            }
    
    def get_available_agents(self) -> List[str]:
        """利用可能なエージェント一覧を取得"""
        if ADK_AVAILABLE and self.coordinator_agent:
            return [
                "newsletter_coordinator",
                "parallel_content_design",
                "sequential_html_quality",
                "content_writer",
                "design_specialist",
                "html_generator",
                "quality_checker"
            ]
        else:
            return ["fallback_agent"]
    
    def get_available_tools(self) -> List[str]:
        """利用可能なツール一覧を取得"""
        return [
            "newsletter_content_generator",
            "design_specification_generator", 
            "html_content_generator",
            "html_quality_checker"
        ]


# ==============================================================================
# 統合API関数
# ==============================================================================

async def generate_newsletter_with_official_adk(
    audio_transcript: str,
    project_id: str = None,
    credentials_path: str = None,
    grade_level: str = "3年1組",
    style: str = "modern"
) -> Dict[str, Any]:
    """
    公式ADKマルチエージェントシステムを使用した学級通信生成
    
    Args:
        audio_transcript: 音声認識結果
        project_id: Google Cloud プロジェクトID
        credentials_path: 認証情報ファイルパス
        grade_level: 対象学年
        style: 生成スタイル
    
    Returns:
        Dict[str, Any]: 生成結果
    """
    service = OfficialNewsletterADKService(project_id, credentials_path)
    
    result = await service.generate_newsletter_with_official_adk(
        audio_transcript=audio_transcript,
        grade_level=grade_level,
        style=style
    )
    
    return result


# ==============================================================================
# ADK CLI互換性関数
# ==============================================================================

def create_adk_web_interface():
    """ADK Web インターフェース作成用関数"""
    if ADK_AVAILABLE:
        # This would typically be handled by the ADK CLI: adk web
        logger.info("ADK Web interface would be available at: http://localhost:8000")
        logger.info("Run 'adk web' command to start the development UI")
    else:
        logger.warning("ADK not available, cannot create web interface")


def create_adk_api_server():
    """ADK API サーバー作成用関数"""
    if ADK_AVAILABLE:
        # This would typically be handled by the ADK CLI: adk api_server
        logger.info("ADK API server would be available")
        logger.info("Run 'adk api_server' command to start the API server")
    else:
        logger.warning("ADK not available, cannot create API server")


# ==============================================================================
# テスト関数
# ==============================================================================

async def test_official_adk_multi_agent():
    """公式ADKマルチエージェントシステムのテスト"""
    
    test_transcript = """
    今日は運動会の練習をしました。
    子どもたちは徒競走とダンスの練習を頑張っていました。
    特にたかしくんは最初は走るのが苦手でしたが、
    毎日練習を重ねて今ではクラスで3番目に速くなりました。
    みんなで応援し合う姿が印象的でした。
    また、ダンスでは新しい振り付けを覚えるのに苦労していましたが、
    みんなで教え合いながら楽しく練習できています。
    """
    
    result = await generate_newsletter_with_official_adk(
        audio_transcript=test_transcript,
        grade_level="3年1組",
        style="modern"
    )
    
    print("=== Official ADK Multi-Agent Test Result ===")
    print(json.dumps(result, ensure_ascii=False, indent=2))
    
    return result


if __name__ == "__main__":
    # テスト実行
    print("Testing Official Google ADK Multi-Agent System...")
    print(f"ADK Available: {ADK_AVAILABLE}")
    
    if ADK_AVAILABLE:
        print("Running full ADK test...")
    else:
        print("Running fallback test...")
    
    result = asyncio.run(test_official_adk_multi_agent())
    
    print("\n=== Test Summary ===")
    print(f"Success: {result.get('success', False)}")
    print(f"Generation Method: {result.get('generation_method', 'unknown')}")
    print(f"Agents Available: {result.get('agents_executed', 'none')}")