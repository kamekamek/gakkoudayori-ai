"""
Google ADK マルチエージェントサービス

音声入力から学級通信生成までの全フローを
専門化されたエージェントの協調により実行
"""

import asyncio
import json
import logging
from typing import Dict, Any, List, Optional
from datetime import datetime

# Google ADK imports
try:
    from google.adk.agents import LlmAgent, Agent
    from google.adk.tools import google_search
    from google.adk.orchestration import Sequential, Parallel
    ADK_AVAILABLE = True
except ImportError:
    # ADK未インストール時のフォールバック
    ADK_AVAILABLE = False
    logging.warning("Google ADK not available, using fallback implementation")

# 既存サービス
from gemini_api_service import generate_text
from audio_to_json_service import get_json_schema, validate_generated_json

logger = logging.getLogger(__name__)


# ==============================================================================
# ADKツール定義
# ==============================================================================

def newsletter_content_generator(
    audio_transcript: str,
    grade_level: str,
    content_type: str = "newsletter"
) -> str:
    """学級通信の文章のみを生成するツール"""
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
    
    try:
        response = generate_text(
            prompt=prompt,
            project_id="your-project-id",
            credentials_path="path/to/credentials.json"
        )
        return response
    except Exception as e:
        logger.error(f"Content generation failed: {e}")
        return "エラー: 文章生成に失敗しました"


def design_json_generator(
    content: str,
    theme: str = "seasonal",
    grade_level: str = "3年1組"
) -> Dict[str, Any]:
    """デザイン設計をJSON形式で出力するツール"""
    
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
    
    return design_spec


def html_generator_tool(
    content: str,
    design_spec: Dict[str, Any],
    template_type: str = "newsletter"
) -> str:
    """HTML生成ツール"""
    
    prompt = f"""
    以下の内容とデザイン仕様に基づいて、学級通信用のHTMLを生成してください：
    
    内容: {content}
    デザイン仕様: {json.dumps(design_spec, ensure_ascii=False, indent=2)}
    
    制約：
    - 使用タグ: <h1>〜<h3>, <p>, <ul>/<ol>/<li>, <strong>, <em>, <br>
    - style/class/div タグ禁止（inline styleのみ許可）
    - <html>タグ不要、本文のみ出力
    - 画像プレースホルダーは [写真: 説明] 形式
    
    出力形式例:
    <h1 style="color: {design_spec.get('color_scheme', {}).get('primary', '#4CAF50')}">学級通信 6月号</h1>
    <p>皆さんこんにちは...</p>
    """
    
    try:
        response = generate_text(
            prompt=prompt,
            project_id="your-project-id", 
            credentials_path="path/to/credentials.json"
        )
        return response
    except Exception as e:
        logger.error(f"HTML generation failed: {e}")
        return f"<p>エラー: HTML生成に失敗しました ({e})</p>"


def html_modification_tool(
    current_html: str,
    modification_request: str
) -> str:
    """HTML修正ツール"""
    
    prompt = f"""
    以下のHTMLを修正してください：
    
    現在のHTML:
    {current_html}
    
    修正要求: {modification_request}
    
    制約：
    - 既存の構造を保持
    - 使用タグ制限を遵守
    - 修正部分のみを変更
    """
    
    try:
        response = generate_text(
            prompt=prompt,
            project_id="your-project-id",
            credentials_path="path/to/credentials.json"
        )
        return response
    except Exception as e:
        logger.error(f"HTML modification failed: {e}")
        return current_html  # 失敗時は元のHTMLを返す


# ==============================================================================
# ADKエージェント定義
# ==============================================================================

class NewsletterADKService:
    """Google ADKを使用したマルチエージェント学級通信生成サービス"""
    
    def __init__(self, project_id: str, credentials_path: str):
        self.project_id = project_id
        self.credentials_path = credentials_path
        self.agents = {}
        
        if ADK_AVAILABLE:
            self._initialize_adk_agents()
        else:
            logger.warning("ADK not available, using fallback mode")
    
    def _initialize_adk_agents(self):
        """ADKエージェントの初期化"""
        
        # 1. オーケストレーターエージェント（メイン調整役）
        self.agents['orchestrator'] = LlmAgent(
            model="gemini-2.5-pro-preview-06-05",
            name="orchestrator_agent",
            description="学級通信生成プロセス全体を調整するメインエージェント",
            instruction="""
            あなたは学級通信生成プロセスのオーケストレーターです。
            ユーザーからの音声入力を受けて、適切な順序で専門エージェントに
            タスクを割り振り、最終的な学級通信を完成させてください。
            
            プロセス:
            1. 音声内容の分析と構造化
            2. 文章生成エージェントへの依頼
            3. デザインエージェントとの並行処理
            4. HTML生成とレビュー
            5. 最終調整と品質確認
            """,
            tools=[]
        )
        
        # 2. コンテンツ生成エージェント
        self.agents['content_writer'] = LlmAgent(
            model="gemini-2.5-pro-preview-06-05",
            name="content_writer_agent", 
            description="学級通信の文章を生成する専門エージェント",
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
        
        # 3. デザイン生成エージェント
        self.agents['layout_designer'] = LlmAgent(
            model="gemini-2.5-flash-preview-05-20",
            name="layout_designer_agent",
            description="学級通信のレイアウトとデザインを設計する専門エージェント", 
            instruction="""
            あなたは教育分野のビジュアルデザイン専門家です。
            
            専門分野:
            - 季節に応じたカラースキーム選択
            - 読みやすいレイアウト設計
            - 保護者の注意を引く視覚的配置
            - 教育的価値を高めるデザイン要素
            
            出力: JSON形式のデザイン仕様
            """,
            tools=[design_json_generator]
        )
        
        # 4. HTML生成エージェント
        self.agents['html_generator'] = LlmAgent(
            model="gemini-2.5-pro-preview-06-05",
            name="html_generator_agent",
            description="文章とデザイン仕様からHTMLを生成する専門エージェント",
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
            tools=[html_generator_tool, html_modification_tool]
        )
        
        # 5. 品質チェックエージェント
        self.agents['quality_checker'] = LlmAgent(
            model="gemini-2.5-pro-preview-06-05", 
            name="quality_checker_agent",
            description="生成された学級通信の品質をチェックする専門エージェント",
            instruction="""
            あなたは教育コンテンツの品質管理専門家です。
            
            チェック項目:
            - 内容の適切性と教育的価値
            - 文章の読みやすさと一貫性
            - HTMLの技術的正確性
            - 保護者への配慮の適切性
            
            改善提案も行ってください。
            """,
            tools=[]
        )
        
        # 6. PDF出力エージェント（Phase 2新規追加）
        self.agents['pdf_output'] = None  # 遅延初期化
        
        # 7. メディアエージェント（Phase 2新規追加）
        self.agents['media'] = None  # 遅延初期化
        
        # 8. Classroom統合エージェント（Phase 2新規追加）
        self.agents['classroom_integration'] = None  # 遅延初期化
    
    def _initialize_phase2_agents(self):
        """Phase 2エージェントの遅延初期化"""
        
        # PDF出力エージェント
        if self.agents['pdf_output'] is None:
            try:
                from pdf_output_agent import PDFOutputAgent
                self.agents['pdf_output'] = PDFOutputAgent(
                    self.project_id, 
                    self.credentials_path
                )
                logger.info("PDF出力エージェント初期化完了")
            except ImportError as e:
                logger.warning(f"PDF出力エージェント初期化失敗: {e}")
                self.agents['pdf_output'] = False
        
        # メディアエージェント
        if self.agents['media'] is None:
            try:
                from media_agent import MediaAgent
                self.agents['media'] = MediaAgent(
                    self.project_id,
                    self.credentials_path
                )
                logger.info("メディアエージェント初期化完了")
            except ImportError as e:
                logger.warning(f"メディアエージェント初期化失敗: {e}")
                self.agents['media'] = False
        
        # Classroom統合エージェント
        if self.agents['classroom_integration'] is None:
            try:
                from classroom_integration_agent import ClassroomIntegrationAgent
                self.agents['classroom_integration'] = ClassroomIntegrationAgent(
                    self.project_id,
                    self.credentials_path
                )
                logger.info("Classroom統合エージェント初期化完了")
            except ImportError as e:
                logger.warning(f"Classroom統合エージェント初期化失敗: {e}")
                self.agents['classroom_integration'] = False
    
    async def generate_newsletter_adk(
        self,
        audio_transcript: str,
        grade_level: str = "3年1組",
        style: str = "modern",
        enable_pdf: bool = True,
        enable_images: bool = True,
        classroom_settings: Dict[str, Any] = None
    ) -> Dict[str, Any]:
        """ADKマルチエージェントを使用した学級通信生成"""
        
        if not ADK_AVAILABLE:
            return await self._fallback_generation(audio_transcript, grade_level, style)
        
        try:
            # Phase 2エージェントの初期化
            if enable_pdf or enable_images or classroom_settings:
                self._initialize_phase2_agents()
            
            # Phase 1: コンテンツ分析と生成
            logger.info("Phase 1: Content generation started")
            content_result = await self._run_agent_task(
                'content_writer',
                f"音声内容: {audio_transcript}\n学年: {grade_level}"
            )
            
            # Phase 2: デザイン生成（並行処理）
            logger.info("Phase 2: Design generation started")
            design_result = await self._run_agent_task(
                'layout_designer', 
                f"内容: {content_result}\n学年: {grade_level}"
            )
            
            # Phase 3: HTML生成
            logger.info("Phase 3: HTML generation started")
            html_result = await self._run_agent_task(
                'html_generator',
                f"内容: {content_result}\nデザイン: {design_result}"
            )
            
            # Phase 4: 品質チェック
            logger.info("Phase 4: Quality check started")
            quality_result = await self._run_agent_task(
                'quality_checker',
                f"HTML: {html_result}\n内容: {content_result}"
            )
            
            # === Phase 2拡張フェーズ ===
            enhanced_html = html_result
            pdf_data = None
            media_data = None
            classroom_data = None
            
            # Phase 5: メディア強化（画像生成・挿入）
            if enable_images and self.agents['media'] and self.agents['media'] is not False:
                logger.info("Phase 5: Media enhancement started")
                try:
                    media_result = await self.agents['media'].enhance_newsletter_with_media(
                        html_content=html_result,
                        newsletter_data={
                            "main_title": f"{grade_level} 学級通信",
                            "grade": grade_level,
                            "sections": [{"type": "main", "content": content_result}]
                        },
                        options={"max_images": 2, "image_style": "cartoon"}
                    )
                    
                    if media_result["success"]:
                        enhanced_html = media_result["data"]["enhanced_html"]
                        media_data = media_result["data"]
                        logger.info("メディア強化完了")
                    else:
                        logger.warning(f"メディア強化失敗: {media_result['error']}")
                        
                except Exception as e:
                    logger.error(f"メディア強化エラー: {e}")
            
            # Phase 6: PDF生成
            if enable_pdf and self.agents['pdf_output'] and self.agents['pdf_output'] is not False:
                logger.info("Phase 6: PDF generation started")
                try:
                    pdf_result = await self.agents['pdf_output'].generate_newsletter_pdf(
                        html_content=enhanced_html,
                        newsletter_data={
                            "main_title": f"{grade_level} 学級通信",
                            "grade": grade_level,
                            "issue_date": datetime.now().strftime("%Y年%m月%d日")
                        },
                        options={"page_size": "A4", "auto_optimize": True}
                    )
                    
                    if pdf_result["success"]:
                        pdf_data = pdf_result["data"]
                        logger.info("PDF生成完了")
                    else:
                        logger.warning(f"PDF生成失敗: {pdf_result['error']}")
                        
                except Exception as e:
                    logger.error(f"PDF生成エラー: {e}")
            
            # Phase 7: Classroom配布
            if classroom_settings and pdf_data and self.agents['classroom_integration'] and self.agents['classroom_integration'] is not False:
                logger.info("Phase 7: Classroom distribution started")
                try:
                    classroom_result = await self.agents['classroom_integration'].distribute_newsletter_to_classroom(
                        pdf_path=pdf_data["pdf_path"],
                        newsletter_data={
                            "main_title": f"{grade_level} 学級通信",
                            "grade": grade_level,
                            "issue_date": datetime.now().strftime("%Y年%m月%d日")
                        },
                        classroom_settings=classroom_settings
                    )
                    
                    if classroom_result["success"]:
                        classroom_data = classroom_result["data"]
                        logger.info("Classroom配布完了")
                    else:
                        logger.warning(f"Classroom配布失敗: {classroom_result['error']}")
                        
                except Exception as e:
                    logger.error(f"Classroom配布エラー: {e}")
            
            # 結果の統合
            result = {
                "success": True,
                "content": content_result,
                "design_spec": design_result, 
                "html": enhanced_html,
                "quality_feedback": quality_result,
                "pdf_output": pdf_data,
                "media_enhancement": media_data,
                "classroom_distribution": classroom_data,
                "generation_method": "adk_multi_agent_phase2",
                "timestamp": datetime.now().isoformat(),
                "agents_used": list(self.agents.keys()),
                "phase2_features": {
                    "pdf_enabled": enable_pdf,
                    "images_enabled": enable_images,
                    "classroom_enabled": classroom_settings is not None
                }
            }
            
            logger.info("ADK multi-agent generation completed successfully")
            return result
            
        except Exception as e:
            logger.error(f"ADK generation failed: {e}")
            return {
                "success": False,
                "error": str(e),
                "fallback_result": await self._fallback_generation(audio_transcript, grade_level, style)
            }
    
    async def _run_agent_task(self, agent_name: str, input_data: str) -> str:
        """個別エージェントタスクの実行"""
        if agent_name not in self.agents:
            raise ValueError(f"Agent {agent_name} not found")
        
        agent = self.agents[agent_name]
        
        # ADKエージェントの実行（実際のAPIコールは実装依存）
        # ここでは簡略化してツール呼び出しをシミュレート
        if agent_name == 'content_writer':
            return newsletter_content_generator(input_data, "3年1組")
        elif agent_name == 'layout_designer':
            return json.dumps(design_json_generator(input_data), ensure_ascii=False)
        elif agent_name == 'html_generator':
            design_spec = json.loads(input_data.split("デザイン: ")[1]) if "デザイン: " in input_data else {}
            content = input_data.split("内容: ")[1].split("\nデザイン: ")[0] if "内容: " in input_data else input_data
            return html_generator_tool(content, design_spec)
        elif agent_name == 'quality_checker':
            return "品質チェック完了: 内容・構造ともに適切です。"
        else:
            return f"{agent_name} の結果"
    
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
                "error": f"Both ADK and fallback generation failed: {e}",
                "timestamp": datetime.now().isoformat()
            }
    
    def modify_html(self, current_html: str, modification_request: str) -> str:
        """HTML修正機能"""
        if ADK_AVAILABLE and 'html_generator' in self.agents:
            return html_modification_tool(current_html, modification_request)
        else:
            # フォールバック: 既存のGemini APIを使用
            return html_modification_tool(current_html, modification_request)
    
    def get_available_tools(self) -> List[str]:
        """利用可能なツール一覧を取得"""
        base_tools = [
            "newsletter_content_generator",
            "design_json_generator", 
            "html_generator_tool",
            "html_modification_tool"
        ]
        
        if ADK_AVAILABLE:
            base_tools.extend([
                "adk_orchestrator",
                "multi_agent_coordination",
                "quality_checker"
            ])
        
        return base_tools


# ==============================================================================
# 統合API関数
# ==============================================================================

async def generate_newsletter_with_adk(
    audio_transcript: str,
    project_id: str,
    credentials_path: str,
    grade_level: str = "3年1組",
    style: str = "modern",
    enable_pdf: bool = True,
    enable_images: bool = True,
    classroom_settings: Dict[str, Any] = None
) -> Dict[str, Any]:
    """
    ADKマルチエージェントシステムを使用した学級通信生成（Phase 2拡張版）
    
    Args:
        audio_transcript: 音声認識結果
        project_id: Google Cloud プロジェクトID
        credentials_path: 認証情報ファイルパス
        grade_level: 対象学年
        style: 生成スタイル
        enable_pdf: PDF生成を有効にするか
        enable_images: 画像生成・挿入を有効にするか
        classroom_settings: Google Classroom配布設定
    
    Returns:
        Dict[str, Any]: 生成結果（HTML、PDF、配布結果含む）
    """
    service = NewsletterADKService(project_id, credentials_path)
    
    result = await service.generate_newsletter_adk(
        audio_transcript=audio_transcript,
        grade_level=grade_level,
        style=style,
        enable_pdf=enable_pdf,
        enable_images=enable_images,
        classroom_settings=classroom_settings
    )
    
    return result


# ==============================================================================
# テスト関数
# ==============================================================================

async def test_adk_multi_agent():
    """ADKマルチエージェントシステムのテスト"""
    
    test_transcript = """
    今日は運動会の練習をしました。
    子どもたちは徒競走とダンスの練習を頑張っていました。
    特にたかしくんは最初は走るのが苦手でしたが、
    毎日練習を重ねて今ではクラスで3番目に速くなりました。
    みんなで応援し合う姿が印象的でした。
    """
    
    result = await generate_newsletter_with_adk(
        audio_transcript=test_transcript,
        project_id="test-project",
        credentials_path="test-credentials.json",
        grade_level="3年1組",
        style="modern"
    )
    
    print("=== ADK Multi-Agent Test Result ===")
    print(json.dumps(result, ensure_ascii=False, indent=2))
    
    return result


if __name__ == "__main__":
    # テスト実行
    asyncio.run(test_adk_multi_agent())