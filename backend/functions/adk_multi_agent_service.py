"""
ADK Multi-Agent Service - Google Agent Development Kit実装

Google Agent Development Kitを使用したマルチエージェントシステム。
各エージェントが専門性を持って学級通信生成を担当します。

専門エージェント構成:
1. ContentAnalyzer - コンテンツ分析・構造化
2. StyleWriter - 教師らしい文体への変換
3. LayoutDesigner - HTMLレイアウト最適化
4. FactChecker - 事実確認・一貫性チェック
5. EngagementOptimizer - 読者エンゲージメント向上
"""

import asyncio
import time
import json
from typing import Dict, Any, List, Optional
from datetime import datetime
import logging

# Google Cloud imports (ADK用)
try:
    # TODO: ADK SDKが利用可能になったら実際のインポートに置き換え
    # from google.cloud import adk
    # from google.cloud.adk import Agent, MultiAgentSystem
    pass
except ImportError:
    # ADK SDKが未利用可能の場合のフォールバック
    pass

from .ai_service_interface import (
    AIServiceInterface, 
    AIConfig, 
    ContentRequest, 
    ContentResult, 
    ProcessingPhaseResult,
    ProcessingPhase
)
from .gemini_api_service import generate_text, get_gemini_client

logger = logging.getLogger(__name__)


class ADKAgent:
    """ADKエージェントの基底クラス"""
    
    def __init__(self, name: str, role: str, prompt_template: str, config: AIConfig):
        self.name = name
        self.role = role
        self.prompt_template = prompt_template
        self.config = config
        self.logger = logging.getLogger(f"{__name__}.{name}")
    
    async def process(self, input_text: str, context: Dict[str, Any] = None) -> Dict[str, Any]:
        """
        エージェント処理を実行
        
        Args:
            input_text (str): 入力テキスト
            context (Dict[str, Any]): 処理コンテキスト
            
        Returns:
            Dict[str, Any]: 処理結果
        """
        start_time = time.time()
        
        try:
            # プロンプト構築
            prompt = self._build_prompt(input_text, context)
            
            # TODO: 実際のADK APIが利用可能になったら置き換え
            # 現在はGemini APIを使用してエージェント動作をシミュレート
            result = await self._call_gemini_api(prompt)
            
            processing_time = int((time.time() - start_time) * 1000)
            
            if result["success"]:
                return {
                    "success": True,
                    "output_text": result["data"]["text"],
                    "processing_time_ms": processing_time,
                    "agent_metadata": {
                        "agent_name": self.name,
                        "role": self.role,
                        "input_length": len(input_text),
                        "output_length": len(result["data"]["text"]),
                        "processing_time_ms": processing_time
                    }
                }
            else:
                return {
                    "success": False,
                    "error": result["error"]["message"],
                    "processing_time_ms": processing_time
                }
                
        except Exception as e:
            processing_time = int((time.time() - start_time) * 1000)
            self.logger.error(f"Agent {self.name} processing failed: {e}")
            return {
                "success": False,
                "error": str(e),
                "processing_time_ms": processing_time
            }
    
    def _build_prompt(self, input_text: str, context: Dict[str, Any] = None) -> str:
        """エージェント固有のプロンプトを構築"""
        context_str = ""
        if context:
            context_str = f"コンテキスト: {json.dumps(context, ensure_ascii=False)}\n\n"
        
        return f"""
{self.prompt_template}

{context_str}入力テキスト:
{input_text}

上記の入力に対して、あなたの専門分野 ({self.role}) の観点から処理を行ってください。
        """.strip()
    
    async def _call_gemini_api(self, prompt: str) -> Dict[str, Any]:
        """Gemini APIを呼び出し（ADK APIの代替）"""
        return await asyncio.get_event_loop().run_in_executor(
            None,
            generate_text,
            prompt,
            self.config.project_id,
            self.config.credentials_path,
            self.config.model_name,
            self.config.temperature,
            self.config.max_output_tokens
        )


class ContentAnalyzerAgent(ADKAgent):
    """コンテンツ分析エージェント"""
    
    def __init__(self, config: AIConfig):
        prompt_template = """
あなたは教育コンテンツ分析の専門家です。
音声認識されたテキストを分析し、学級通信に適した構造化された情報を抽出してください。

【分析観点】
1. 主要な出来事・活動の特定
2. 子どもたちの様子・成長の記録
3. 重要なメッセージの抽出
4. 時系列での情報整理
5. 保護者に伝えるべき要点の明確化

【出力形式】
- 主要トピック: [箇条書き]
- 子どもたちの様子: [具体的な描写]
- 重要メッセージ: [要点]
- 推奨構成: [提案]
        """
        super().__init__("ContentAnalyzer", "コンテンツ分析・構造化", prompt_template, config)


class StyleWriterAgent(ADKAgent):
    """文体変換エージェント"""
    
    def __init__(self, config: AIConfig):
        prompt_template = """
あなたは小学校教師の文章スタイルの専門家です。
分析された内容を、温かみのある教師らしい文体で学級通信として書き直してください。

【文体要件】
1. 親しみやすく温かい語りかけ
2. 具体的で分かりやすい表現
3. 子どもたちへの愛情が伝わる文章
4. 保護者への感謝の気持ちを込める
5. 適度な敬語使用

【文章構成】
- 導入：季節の挨拶や全体の様子
- 本文：具体的な活動や子どもたちの様子
- 結び：保護者への感謝やお願い
        """
        super().__init__("StyleWriter", "教師らしい文体への変換", prompt_template, config)


class LayoutDesignerAgent(ADKAgent):
    """レイアウト設計エージェント"""
    
    def __init__(self, config: AIConfig):
        prompt_template = """
あなたはHTMLレイアウト設計の専門家です。
教師が書いた文章を、読みやすく美しいHTMLレイアウトに変換してください。

【HTML制約】
- 見出しは h1, h2, h3 タグのみ使用
- 段落は p タグで囲む
- リストは ul, ol, li タグを使用
- 強調は strong, em タグを使用
- 改行は br タグを使用
- 色指定、フォントサイズ指定は禁止
- スクリプトタグは禁止
- インラインスタイルは禁止

【レイアウト方針】
- 読みやすい構造化
- 重要な情報の強調
- 視覚的な階層の明確化
- 印刷時の見栄えを考慮
        """
        super().__init__("LayoutDesigner", "HTMLレイアウト最適化", prompt_template, config)


class FactCheckerAgent(ADKAgent):
    """事実確認エージェント"""
    
    def __init__(self, config: AIConfig):
        prompt_template = """
あなたは教育コンテンツの事実確認専門家です。
生成された学級通信の内容を確認し、一貫性や適切性をチェックしてください。

【確認観点】
1. 日付や時期の整合性
2. 学校行事の適切性
3. 子どもの発達段階との適合性
4. 保護者向けメッセージの適切性
5. 文章の論理的一貫性

【修正提案】
問題があれば具体的な修正案を提示してください。
問題がなければ「確認完了」として承認してください。
        """
        super().__init__("FactChecker", "事実確認・一貫性チェック", prompt_template, config)


class EngagementOptimizerAgent(ADKAgent):
    """エンゲージメント最適化エージェント"""
    
    def __init__(self, config: AIConfig):
        prompt_template = """
あなたは読者エンゲージメントの専門家です。
学級通信を保護者が興味深く読めるよう、最終的な調整を行ってください。

【最適化観点】
1. 読者の興味を引く表現
2. 感情に訴える具体的なエピソード
3. 保護者の関心事への配慮
4. 行動を促すメッセージ
5. 読みやすさの向上

【調整方針】
- 子どもの成長が見える具体例
- 保護者の協力を求める自然な流れ
- 温かみのある締めくくり
        """
        super().__init__("EngagementOptimizer", "読者エンゲージメント向上", prompt_template, config)


class ADKMultiAgentService(AIServiceInterface):
    """ADK マルチエージェントサービス実装"""
    
    def __init__(self, config: AIConfig):
        super().__init__(config)
        self.agents = self._initialize_agents()
        self.processing_pipeline = [
            ("content_analysis", "ContentAnalyzer"),
            ("style_writing", "StyleWriter"),
            ("layout_design", "LayoutDesigner"),
            ("fact_checking", "FactChecker"),
            ("engagement_optimization", "EngagementOptimizer")
        ]
    
    def _initialize_agents(self) -> Dict[str, ADKAgent]:
        """エージェントを初期化"""
        return {
            "ContentAnalyzer": ContentAnalyzerAgent(self.config),
            "StyleWriter": StyleWriterAgent(self.config),
            "LayoutDesigner": LayoutDesignerAgent(self.config),
            "FactChecker": FactCheckerAgent(self.config),
            "EngagementOptimizer": EngagementOptimizerAgent(self.config)
        }
    
    async def generate_newsletter(self, request: ContentRequest) -> ContentResult:
        """
        マルチエージェントで学級通信を生成
        
        Args:
            request (ContentRequest): 生成リクエスト
            
        Returns:
            ContentResult: 生成結果
        """
        start_time = time.time()
        processing_phases = []
        current_text = request["text"]
        
        # リクエストコンテキストを構築
        context = {
            "template_type": request["template_type"],
            "include_greeting": request["include_greeting"],
            "target_audience": request["target_audience"],
            "season": request["season"],
            "original_text": request["text"]
        }
        
        try:
            # 各エージェントを順次実行
            for phase_name, agent_name in self.processing_pipeline:
                self.logger.info(f"Starting phase: {phase_name} with agent: {agent_name}")
                
                agent = self.agents[agent_name]
                result = await agent.process(current_text, context)
                
                phase_result = ProcessingPhaseResult(
                    phase=phase_name,
                    agent_name=agent_name,
                    input_text=current_text,
                    output_text=result.get("output_text", ""),
                    processing_time_ms=result.get("processing_time_ms", 0),
                    success=result.get("success", False),
                    error=result.get("error")
                )
                
                processing_phases.append(phase_result)
                
                if not result["success"]:
                    self.logger.error(f"Phase {phase_name} failed: {result.get('error')}")
                    return ContentResult(
                        success=False,
                        data=None,
                        error={
                            "code": "ADK_PHASE_ERROR",
                            "message": f"Phase {phase_name} failed: {result.get('error')}",
                            "details": {
                                "failed_phase": phase_name,
                                "agent_name": agent_name,
                                "processing_time_ms": int((time.time() - start_time) * 1000),
                                "timestamp": datetime.now().isoformat()
                            }
                        },
                        processing_phases=processing_phases
                    )
                
                # 次のフェーズの入力として使用
                current_text = result["output_text"]
                
                # コンテキストを更新
                context[f"{phase_name}_result"] = result["output_text"]
            
            # 全フェーズ完了
            total_processing_time = int((time.time() - start_time) * 1000)
            
            return ContentResult(
                success=True,
                data={
                    "newsletter_html": current_text,
                    "original_speech": request["text"],
                    "template_type": request["template_type"],
                    "season": request["season"],
                    "ai_metadata": {
                        "provider": "adk_multi_agent",
                        "model": f"multi_agent_{self.config.model_name}",
                        "processing_time_ms": total_processing_time,
                        "word_count": len(current_text.split()),
                        "character_count": len(current_text),
                        "multi_agent": True,
                        "agents_used": [agent_name for _, agent_name in self.processing_pipeline],
                        "processing_phases": len(self.processing_pipeline)
                    },
                    "generated_at": datetime.now().isoformat()
                },
                error=None,
                processing_phases=processing_phases
            )
            
        except Exception as e:
            total_processing_time = int((time.time() - start_time) * 1000)
            self.logger.error(f"Multi-agent newsletter generation failed: {e}")
            
            return ContentResult(
                success=False,
                data=None,
                error={
                    "code": "ADK_SYSTEM_ERROR",
                    "message": str(e),
                    "details": {
                        "processing_time_ms": total_processing_time,
                        "timestamp": datetime.now().isoformat()
                    }
                },
                processing_phases=processing_phases
            )
    
    async def generate_text(self, prompt: str, context: Optional[List[Dict[str, str]]] = None) -> ContentResult:
        """
        汎用テキスト生成（簡易版・ContentAnalyzerのみ使用）
        
        Args:
            prompt (str): プロンプトテキスト
            context (Optional[List[Dict[str, str]]]): コンテキスト履歴
            
        Returns:
            ContentResult: 生成結果
        """
        start_time = time.time()
        
        try:
            # 汎用テキスト生成はContentAnalyzerを使用
            agent = self.agents["ContentAnalyzer"]
            context_dict = {"context_history": context} if context else {}
            
            result = await agent.process(prompt, context_dict)
            
            if result["success"]:
                return ContentResult(
                    success=True,
                    data={
                        "text": result["output_text"],
                        "ai_metadata": {
                            "provider": "adk_multi_agent",
                            "model": f"single_agent_{self.config.model_name}",
                            "processing_time_ms": result["processing_time_ms"],
                            "word_count": len(result["output_text"].split()),
                            "agent_used": "ContentAnalyzer"
                        },
                        "timestamp": datetime.now().isoformat()
                    },
                    error=None,
                    processing_phases=[
                        ProcessingPhaseResult(
                            phase="content_analysis",
                            agent_name="ContentAnalyzer",
                            input_text=prompt,
                            output_text=result["output_text"],
                            processing_time_ms=result["processing_time_ms"],
                            success=True,
                            error=None
                        )
                    ]
                )
            else:
                return ContentResult(
                    success=False,
                    data=None,
                    error={
                        "code": "ADK_TEXT_GENERATION_ERROR",
                        "message": result["error"],
                        "details": {
                            "processing_time_ms": result["processing_time_ms"],
                            "timestamp": datetime.now().isoformat()
                        }
                    },
                    processing_phases=None
                )
                
        except Exception as e:
            processing_time = int((time.time() - start_time) * 1000)
            self.logger.error(f"ADK text generation failed: {e}")
            
            return ContentResult(
                success=False,
                data=None,
                error={
                    "code": "ADK_EXCEPTION",
                    "message": str(e),
                    "details": {
                        "processing_time_ms": processing_time,
                        "timestamp": datetime.now().isoformat()
                    }
                },
                processing_phases=None
            )
    
    async def check_connection(self) -> Dict[str, Any]:
        """
        ADK接続確認（各エージェントの接続確認）
        
        Returns:
            Dict[str, Any]: 接続結果
        """
        start_time = time.time()
        
        try:
            # 各エージェントの接続確認（簡易テスト）
            agent_status = {}
            
            for agent_name, agent in self.agents.items():
                try:
                    test_result = await agent.process("接続テスト", {"test": True})
                    agent_status[agent_name] = {
                        "status": "available" if test_result["success"] else "error",
                        "response_time_ms": test_result.get("processing_time_ms", 0),
                        "error": test_result.get("error")
                    }
                except Exception as e:
                    agent_status[agent_name] = {
                        "status": "error",
                        "error": str(e)
                    }
            
            # 全体的な接続状況を判定
            all_available = all(
                status["status"] == "available" 
                for status in agent_status.values()
            )
            
            processing_time = int((time.time() - start_time) * 1000)
            
            return {
                "success": all_available,
                "data": {
                    "connection_status": "ok" if all_available else "partial",
                    "agent_status": agent_status,
                    "processing_time_ms": processing_time,
                    "timestamp": datetime.now().isoformat()
                }
            }
            
        except Exception as e:
            processing_time = int((time.time() - start_time) * 1000)
            self.logger.error(f"ADK connection check failed: {e}")
            
            return {
                "success": False,
                "error": {
                    "code": "ADK_CONNECTION_ERROR",
                    "message": str(e),
                    "details": {
                        "processing_time_ms": processing_time,
                        "timestamp": datetime.now().isoformat()
                    }
                }
            }
    
    def get_service_info(self) -> Dict[str, Any]:
        """
        ADKサービス情報
        
        Returns:
            Dict[str, Any]: サービス情報
        """
        return {
            "provider": "adk_multi_agent",
            "model_name": self.config.model_name,
            "project_id": self.config.project_id,
            "capabilities": {
                "text_generation": True,
                "contextual_generation": True,
                "newsletter_generation": True,
                "multi_agent": True,
                "specialized_agents": True
            },
            "agents": {
                agent_name: {
                    "name": agent.name,
                    "role": agent.role
                }
                for agent_name, agent in self.agents.items()
            },
            "processing_pipeline": [
                {"phase": phase, "agent": agent}
                for phase, agent in self.processing_pipeline
            ],
            "configuration": {
                "temperature": self.config.temperature,
                "max_output_tokens": self.config.max_output_tokens
            }
        }