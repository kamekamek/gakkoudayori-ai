"""
ADK準拠オーケストレーター

Google ADK公式仕様に完全準拠したマルチエージェント学級通信生成システム
Workflowエージェント（Sequential, Parallel）を活用した最適化処理
"""

import asyncio
import logging
import time
import uuid
from typing import Dict, Any, List, Optional
from datetime import datetime

# Google ADK imports
try:
    from google.adk.agents import LlmAgent, Agent
    from google.adk.orchestration import Sequential, Parallel
    from google.adk.tools import ToolRegistry
    ADK_AVAILABLE = True
except ImportError:
    # ADK未インストール時のフォールバック
    ADK_AVAILABLE = False
    logging.warning("Google ADK not available, using fallback implementation")

# ADK準拠ツール関数
from adk_compliant_tools import (
    generate_newsletter_content,
    generate_design_specification,
    generate_html_newsletter,
    modify_html_content,
    validate_newsletter_quality
)

logger = logging.getLogger(__name__)


# ==============================================================================
# ADK準拠エージェント定義
# ==============================================================================

class ADKToolWrapper:
    """ADKツールを関数形式でラップするクラス"""
    
    def __init__(self, func, name: str, description: str):
        self.func = func
        self.name = name
        self.description = description
    
    async def execute(self, **kwargs) -> dict:
        """非同期実行ラッパー"""
        try:
            if asyncio.iscoroutinefunction(self.func):
                return await self.func(**kwargs)
            else:
                return self.func(**kwargs)
        except Exception as e:
            logger.error(f"Tool {self.name} execution failed: {e}")
            return {
                "status": "error",
                "error_message": f"ツール実行エラー: {str(e)}",
                "error_code": "TOOL_EXECUTION_ERROR"
            }


class NewsletterADKOrchestrator:
    """Google ADK準拠学級通信生成オーケストレーター"""
    
    def __init__(self, project_id: str, credentials_path: str):
        self.project_id = project_id
        self.credentials_path = credentials_path
        self.agents = {}
        self.workflows = {}
        self.tools = {}
        self.metrics = MetricsCollector()
        
        self._initialize_tools()
        
        if ADK_AVAILABLE:
            self._initialize_adk_agents()
            self._initialize_workflows()
        else:
            logger.warning("ADK not available, using direct tool execution")
    
    def _initialize_tools(self):
        """ADK準拠ツールの初期化"""
        self.tools = {
            'content_generator': ADKToolWrapper(
                generate_newsletter_content,
                'content_generator',
                '音声認識結果から学級通信の文章を生成するツール'
            ),
            'design_generator': ADKToolWrapper(
                generate_design_specification,
                'design_generator',
                'コンテンツに基づいてデザイン仕様を生成するツール'
            ),
            'html_generator': ADKToolWrapper(
                generate_html_newsletter,
                'html_generator',
                'コンテンツとデザインからHTMLを生成するツール'
            ),
            'html_modifier': ADKToolWrapper(
                modify_html_content,
                'html_modifier',
                '既存HTMLに修正を適用するツール'
            ),
            'quality_validator': ADKToolWrapper(
                validate_newsletter_quality,
                'quality_validator',
                '学級通信の品質を検証するツール'
            )
        }
        
        logger.info(f"Initialized {len(self.tools)} ADK-compliant tools")
    
    def _initialize_adk_agents(self):
        """ADKエージェントの初期化"""
        
        # 1. 統合オーケストレーターエージェント
        self.agents['master_orchestrator'] = LlmAgent(
            model="gemini-2.5-pro-preview-06-05",
            name="master_orchestrator",
            description="学級通信生成の全体調整を行うマスターエージェント",
            instruction="""
            あなたは学級通信生成システムのマスターオーケストレーターです。
            音声入力から最終的な学級通信完成まで全体プロセスを調整します。
            
            責任範囲:
            - プロセス全体の進行管理
            - エージェント間の調整
            - 品質基準の維持
            - エラー処理と回復
            
            処理原則:
            - 効率性: 並行処理を活用した時間短縮
            - 品質性: 教育現場に適した高品質出力
            - 信頼性: エラー時の適切な回復処理
            """,
            tools=list(self.tools.values())
        )
        
        # 2. コンテンツ専門エージェント
        self.agents['content_specialist'] = LlmAgent(
            model="gemini-2.5-pro-preview-06-05",
            name="content_specialist",
            description="学級通信のコンテンツ生成専門エージェント",
            instruction="""
            あなたは小学校教師向け学級通信のコンテンツ生成専門家です。
            
            専門スキル:
            - 教師らしい温かい語り口調
            - 保護者の関心を引く内容構成
            - 学年に応じた適切な表現
            - 教育的価値の高いエピソード選択
            
            品質基準:
            - 800-1200文字の適切な分量
            - 具体的で生き生きとした描写
            - 読みやすい段落構成
            - 個人情報保護への配慮
            """,
            tools=[self.tools['content_generator']]
        )
        
        # 3. デザイン専門エージェント
        self.agents['design_specialist'] = LlmAgent(
            model="gemini-2.5-flash-preview-05-20",
            name="design_specialist", 
            description="学級通信のデザイン設計専門エージェント",
            instruction="""
            あなたは教育分野のビジュアルデザイン専門家です。
            
            専門分野:
            - 季節感のあるカラースキーム選択
            - 読みやすいレイアウト設計
            - 教育現場に適したフォント選択
            - 印刷時の美しさを考慮した構成
            
            設計原則:
            - アクセシビリティ重視
            - 印刷適応性の確保
            - 視覚的魅力と実用性の両立
            - 学年特性への対応
            """,
            tools=[self.tools['design_generator']]
        )
        
        # 4. HTML開発専門エージェント
        self.agents['html_developer'] = LlmAgent(
            model="gemini-2.5-pro-preview-06-05",
            name="html_developer",
            description="学級通信のHTML生成・修正専門エージェント",
            instruction="""
            あなたはWebフロントエンド開発とHTML制約対応の専門家です。
            
            技術領域:
            - セマンティックHTML構造の作成
            - アクセシブルなマークアップ
            - 厳格なタグ制約への準拠
            - 印刷最適化されたスタイリング
            
            制約遵守:
            - 指定HTMLタグのみ使用
            - インラインスタイルでの装飾
            - クリーンで保守性の高いコード
            - エラー回復を考慮した設計
            """,
            tools=[self.tools['html_generator'], self.tools['html_modifier']]
        )
        
        # 5. 品質管理専門エージェント
        self.agents['quality_manager'] = LlmAgent(
            model="gemini-2.5-pro-preview-06-05",
            name="quality_manager",
            description="学級通信の品質管理・評価専門エージェント",
            instruction="""
            あなたは教育コンテンツの品質管理とプロセス改善の専門家です。
            
            評価領域:
            - 教育的価値と内容の適切性
            - 技術的正確性と構造品質
            - 読みやすさとアクセシビリティ
            - 保護者への配慮と満足度
            
            改善提案:
            - 具体的で実行可能な改善案
            - 優先度に基づく提案順序
            - 教育現場の制約を考慮した実用性
            - 継続的改善のためのフィードバック
            """,
            tools=[self.tools['quality_validator']]
        )
        
        logger.info(f"Initialized {len(self.agents)} ADK agents")
    
    def _initialize_workflows(self):
        """Workflowエージェントの初期化"""
        
        # 1. 基本Sequential処理フロー
        self.workflows['sequential_basic'] = Sequential([
            self.agents['content_specialist'],
            self.agents['design_specialist'],
            self.agents['html_developer'],
            self.agents['quality_manager']
        ])
        
        # 2. 最適化Parallel処理フロー
        self.workflows['parallel_optimized'] = Parallel([
            self.agents['content_specialist'],
            self.agents['design_specialist']
        ])
        
        # 3. ハイブリッド処理フロー
        self.workflows['hybrid_advanced'] = self._create_hybrid_workflow()
        
        logger.info(f"Initialized {len(self.workflows)} workflow patterns")
    
    def _create_hybrid_workflow(self):
        """ハイブリッドワークフロー（Sequential + Parallel組み合わせ）の構築"""
        
        class HybridWorkflow:
            def __init__(self, orchestrator):
                self.orchestrator = orchestrator
            
            async def execute(self, input_data: dict) -> dict:
                """ハイブリッド実行: 並行 → 順次 → 並行"""
                
                results = {
                    'execution_id': str(uuid.uuid4()),
                    'start_time': time.time(),
                    'stages': {}
                }
                
                try:
                    # Stage 1: 並行処理（独立タスク）
                    stage1_result = await self.orchestrator._execute_parallel_stage(
                        input_data, ['content_specialist', 'design_specialist']
                    )
                    results['stages']['stage1_parallel'] = stage1_result
                    
                    # Stage 2: 順次処理（依存関係あり）
                    stage2_result = await self.orchestrator._execute_sequential_stage(
                        stage1_result, ['html_developer']
                    )
                    results['stages']['stage2_sequential'] = stage2_result
                    
                    # Stage 3: 最終並行処理（品質管理・最適化）
                    stage3_result = await self.orchestrator._execute_final_stage(
                        stage2_result, ['quality_manager']
                    )
                    results['stages']['stage3_final'] = stage3_result
                    
                    # 結果統合
                    results['final_output'] = self.orchestrator._combine_workflow_results(
                        results['stages']
                    )
                    results['success'] = True
                    results['processing_time'] = time.time() - results['start_time']
                    
                    return results
                    
                except Exception as e:
                    logger.error(f"Hybrid workflow execution failed: {e}")
                    results['success'] = False
                    results['error'] = str(e)
                    return results
        
        return HybridWorkflow(self)
    
    async def generate_newsletter(
        self,
        audio_transcript: str,
        grade_level: str = "3年1組",
        style: str = "modern",
        use_parallel_processing: bool = True,
        quality_threshold: int = 80
    ) -> dict:
        """メイン学級通信生成処理"""
        
        start_time = time.time()
        execution_id = str(uuid.uuid4())
        
        try:
            # メトリクス記録開始
            await self.metrics.start_execution(execution_id, {
                'audio_length': len(audio_transcript),
                'grade_level': grade_level,
                'style': style,
                'parallel_processing': use_parallel_processing,
                'quality_threshold': quality_threshold
            })
            
            # 入力検証
            validation_result = self._validate_inputs(audio_transcript, grade_level)
            if validation_result['status'] == 'error':
                return validation_result
            
            # ワークフロー選択と実行
            if ADK_AVAILABLE and use_parallel_processing:
                result = await self._execute_hybrid_workflow(
                    audio_transcript, grade_level, style
                )
            elif ADK_AVAILABLE:
                result = await self._execute_sequential_workflow(
                    audio_transcript, grade_level, style
                )
            else:
                result = await self._execute_fallback_workflow(
                    audio_transcript, grade_level, style
                )
            
            # 品質チェック
            if result.get('success') and result.get('final_output'):
                quality_check = await self._perform_quality_check(
                    result['final_output'], quality_threshold
                )
                result['quality_check'] = quality_check
                
                if quality_check['meets_threshold']:
                    result['status'] = 'success'
                else:
                    # 品質改善の試行
                    improved_result = await self._improve_quality(
                        result['final_output'], quality_check['suggestions']
                    )
                    if improved_result['success']:
                        result['final_output'] = improved_result['improved_output']
                        result['quality_improvement'] = improved_result
            
            # メトリクス記録完了
            processing_time = time.time() - start_time
            await self.metrics.complete_execution(execution_id, {
                'success': result.get('success', False),
                'processing_time': processing_time,
                'workflow_used': result.get('workflow_type', 'unknown'),
                'quality_score': result.get('quality_check', {}).get('score', 0)
            })
            
            # 最終結果の構成
            result.update({
                'execution_id': execution_id,
                'processing_time_seconds': processing_time,
                'timestamp': datetime.now().isoformat(),
                'adk_compliant': True,
                'system_version': 'adk_compliant_v1.0'
            })
            
            return result
            
        except Exception as e:
            logger.error(f"Newsletter generation failed: {e}", exc_info=True)
            await self.metrics.error_execution(execution_id, str(e))
            
            return {
                'status': 'error',
                'error_message': f'学級通信生成中にエラーが発生しました: {str(e)}',
                'error_code': 'GENERATION_ERROR',
                'execution_id': execution_id,
                'processing_time_seconds': time.time() - start_time,
                'timestamp': datetime.now().isoformat()
            }
    
    async def _execute_hybrid_workflow(
        self, 
        audio_transcript: str, 
        grade_level: str, 
        style: str
    ) -> dict:
        """ハイブリッドワークフロー実行（推奨）"""
        
        logger.info("Executing hybrid workflow (parallel + sequential optimization)")
        
        input_data = {
            'audio_transcript': audio_transcript,
            'grade_level': grade_level,
            'style': style
        }
        
        result = await self.workflows['hybrid_advanced'].execute(input_data)
        result['workflow_type'] = 'hybrid_optimized'
        
        return result
    
    async def _execute_sequential_workflow(
        self,
        audio_transcript: str,
        grade_level: str, 
        style: str
    ) -> dict:
        """順次ワークフロー実行"""
        
        logger.info("Executing sequential workflow")
        
        try:
            # Step 1: コンテンツ生成
            content_result = await self.tools['content_generator'].execute(
                audio_transcript=audio_transcript,
                grade_level=grade_level,
                content_type='newsletter'
            )
            
            if content_result['status'] != 'success':
                return {'success': False, 'error': 'Content generation failed'}
            
            # Step 2: デザイン生成
            design_result = await self.tools['design_generator'].execute(
                content=content_result['content'],
                theme=style,
                grade_level=grade_level
            )
            
            if design_result['status'] != 'success':
                return {'success': False, 'error': 'Design generation failed'}
            
            # Step 3: HTML生成
            html_result = await self.tools['html_generator'].execute(
                content=content_result['content'],
                design_spec=design_result['design_spec'],
                template_type='newsletter'
            )
            
            if html_result['status'] != 'success':
                return {'success': False, 'error': 'HTML generation failed'}
            
            # Step 4: 品質検証
            quality_result = await self.tools['quality_validator'].execute(
                html_content=html_result['html'],
                original_content=content_result['content']
            )
            
            return {
                'success': True,
                'workflow_type': 'sequential',
                'final_output': {
                    'content': content_result,
                    'design': design_result,
                    'html': html_result,
                    'quality': quality_result
                }
            }
            
        except Exception as e:
            logger.error(f"Sequential workflow failed: {e}")
            return {'success': False, 'error': str(e)}
    
    async def _execute_fallback_workflow(
        self,
        audio_transcript: str,
        grade_level: str,
        style: str
    ) -> dict:
        """フォールバックワークフロー実行（ADK未使用）"""
        
        logger.info("Executing fallback workflow (direct tool execution)")
        
        return await self._execute_sequential_workflow(
            audio_transcript, grade_level, style
        )
    
    async def _execute_parallel_stage(
        self, 
        input_data: dict, 
        agent_names: List[str]
    ) -> dict:
        """並行ステージ実行"""
        
        tasks = []
        for agent_name in agent_names:
            if agent_name == 'content_specialist':
                task = self.tools['content_generator'].execute(
                    audio_transcript=input_data['audio_transcript'],
                    grade_level=input_data['grade_level'],
                    content_type='newsletter'
                )
            elif agent_name == 'design_specialist':
                task = self.tools['design_generator'].execute(
                    content=input_data.get('content', input_data['audio_transcript']),
                    theme=input_data.get('style', 'seasonal'),
                    grade_level=input_data['grade_level']
                )
            else:
                continue
            
            tasks.append(task)
        
        results = await asyncio.gather(*tasks, return_exceptions=True)
        
        return {
            'agent_results': dict(zip(agent_names, results)),
            'stage_type': 'parallel',
            'success': all(
                isinstance(r, dict) and r.get('status') == 'success' 
                for r in results
            )
        }
    
    async def _execute_sequential_stage(
        self,
        previous_result: dict,
        agent_names: List[str]
    ) -> dict:
        """順次ステージ実行"""
        
        results = {}
        
        for agent_name in agent_names:
            if agent_name == 'html_developer':
                # 前ステージ結果から必要な情報を取得
                content_data = previous_result['agent_results']['content_specialist']
                design_data = previous_result['agent_results']['design_specialist']
                
                result = await self.tools['html_generator'].execute(
                    content=content_data['content'],
                    design_spec=design_data['design_spec'],
                    template_type='newsletter'
                )
                
                results[agent_name] = result
        
        return {
            'agent_results': results,
            'stage_type': 'sequential',
            'success': all(
                r.get('status') == 'success' for r in results.values()
            )
        }
    
    async def _execute_final_stage(
        self,
        previous_result: dict,
        agent_names: List[str]
    ) -> dict:
        """最終ステージ実行"""
        
        results = {}
        
        for agent_name in agent_names:
            if agent_name == 'quality_manager':
                html_data = previous_result['agent_results']['html_developer']
                
                # 元のコンテンツを取得（複数ステージから）
                original_content = None
                if 'content_specialist' in previous_result.get('agent_results', {}):
                    original_content = previous_result['agent_results']['content_specialist']['content']
                else:
                    # 前々ステージから取得
                    original_content = "フォールバック内容"
                
                result = await self.tools['quality_validator'].execute(
                    html_content=html_data['html'],
                    original_content=original_content
                )
                
                results[agent_name] = result
        
        return {
            'agent_results': results,
            'stage_type': 'final',
            'success': all(
                r.get('status') == 'success' for r in results.values()
            )
        }
    
    def _combine_workflow_results(self, stages: dict) -> dict:
        """ワークフロー結果の統合"""
        
        combined = {
            'content_result': None,
            'design_result': None, 
            'html_result': None,
            'quality_result': None,
            'stages_executed': list(stages.keys()),
            'overall_success': True
        }
        
        # Stage 1の結果
        if 'stage1_parallel' in stages:
            stage1 = stages['stage1_parallel']
            if 'content_specialist' in stage1['agent_results']:
                combined['content_result'] = stage1['agent_results']['content_specialist']
            if 'design_specialist' in stage1['agent_results']:
                combined['design_result'] = stage1['agent_results']['design_specialist']
        
        # Stage 2の結果
        if 'stage2_sequential' in stages:
            stage2 = stages['stage2_sequential']
            if 'html_developer' in stage2['agent_results']:
                combined['html_result'] = stage2['agent_results']['html_developer']
        
        # Stage 3の結果
        if 'stage3_final' in stages:
            stage3 = stages['stage3_final']
            if 'quality_manager' in stage3['agent_results']:
                combined['quality_result'] = stage3['agent_results']['quality_manager']
        
        # 成功判定
        for stage in stages.values():
            if not stage.get('success', False):
                combined['overall_success'] = False
                break
        
        return combined
    
    def _validate_inputs(
        self, 
        audio_transcript: str, 
        grade_level: str
    ) -> dict:
        """入力値検証"""
        
        if not audio_transcript or not audio_transcript.strip():
            return {
                'status': 'error',
                'error_message': '音声認識結果が空です',
                'error_code': 'EMPTY_AUDIO_TRANSCRIPT'
            }
        
        if not grade_level or not grade_level.strip():
            return {
                'status': 'error',
                'error_message': '学年情報が空です',
                'error_code': 'EMPTY_GRADE_LEVEL'
            }
        
        return {'status': 'success'}
    
    async def _perform_quality_check(
        self, 
        output: dict, 
        threshold: int
    ) -> dict:
        """品質チェック実行"""
        
        quality_result = output.get('quality_result')
        if not quality_result or quality_result.get('status') != 'success':
            return {
                'meets_threshold': False,
                'score': 0,
                'suggestions': ['品質検証を再実行してください']
            }
        
        score = quality_result.get('quality_score', 0)
        
        return {
            'meets_threshold': score >= threshold,
            'score': score,
            'suggestions': quality_result.get('suggestions', []),
            'category_scores': quality_result.get('category_scores', {})
        }
    
    async def _improve_quality(
        self,
        output: dict,
        suggestions: List[str]
    ) -> dict:
        """品質改善処理"""
        
        try:
            # HTML改善の試行
            if output.get('html_result') and suggestions:
                improvement_request = "品質向上のため以下の改善を実施: " + ", ".join(suggestions[:3])
                
                improved_html = await self.tools['html_modifier'].execute(
                    current_html=output['html_result']['html'],
                    modification_request=improvement_request
                )
                
                if improved_html['status'] == 'success':
                    # 改善されたHTMLで再品質検証
                    new_quality = await self.tools['quality_validator'].execute(
                        html_content=improved_html['modified_html'],
                        original_content=output['content_result']['content']
                    )
                    
                    if new_quality['status'] == 'success':
                        # 結果更新
                        output['html_result']['html'] = improved_html['modified_html']
                        output['quality_result'] = new_quality
                        
                        return {
                            'success': True,
                            'improved_output': output,
                            'improvements_applied': suggestions[:3]
                        }
            
            return {
                'success': False,
                'error': '品質改善を適用できませんでした'
            }
            
        except Exception as e:
            logger.error(f"Quality improvement failed: {e}")
            return {
                'success': False,
                'error': str(e)
            }


# ==============================================================================
# メトリクス収集
# ==============================================================================

class MetricsCollector:
    """実行メトリクス収集クラス"""
    
    def __init__(self):
        self.executions = {}
    
    async def start_execution(self, execution_id: str, metadata: dict):
        """実行開始記録"""
        self.executions[execution_id] = {
            'start_time': time.time(),
            'metadata': metadata,
            'status': 'running'
        }
        logger.info(f"Execution {execution_id} started with metadata: {metadata}")
    
    async def complete_execution(self, execution_id: str, results: dict):
        """実行完了記録"""
        if execution_id in self.executions:
            self.executions[execution_id].update({
                'end_time': time.time(),
                'status': 'completed',
                'results': results
            })
            logger.info(f"Execution {execution_id} completed: {results}")
    
    async def error_execution(self, execution_id: str, error: str):
        """実行エラー記録"""
        if execution_id in self.executions:
            self.executions[execution_id].update({
                'end_time': time.time(),
                'status': 'error',
                'error': error
            })
            logger.error(f"Execution {execution_id} failed: {error}")
    
    def get_metrics_summary(self) -> dict:
        """メトリクスサマリー取得"""
        completed = [e for e in self.executions.values() if e['status'] == 'completed']
        
        if not completed:
            return {'total_executions': 0}
        
        avg_time = sum(
            e['end_time'] - e['start_time'] for e in completed
        ) / len(completed)
        
        success_rate = len([
            e for e in completed if e.get('results', {}).get('success', False)
        ]) / len(completed)
        
        return {
            'total_executions': len(self.executions),
            'completed_executions': len(completed),
            'average_processing_time': avg_time,
            'success_rate': success_rate,
            'error_count': len([e for e in self.executions.values() if e['status'] == 'error'])
        }


# ==============================================================================
# 統合API関数
# ==============================================================================

async def generate_newsletter_with_adk_compliant(
    audio_transcript: str,
    project_id: str,
    credentials_path: str,
    grade_level: str = "3年1組",
    style: str = "modern",
    use_parallel_processing: bool = True,
    quality_threshold: int = 80
) -> dict:
    """
    ADK準拠オーケストレーターを使用した学級通信生成
    
    Args:
        audio_transcript: 音声認識結果
        project_id: Google Cloud プロジェクトID
        credentials_path: 認証情報ファイルパス
        grade_level: 対象学年
        style: 生成スタイル
        use_parallel_processing: 並行処理使用フラグ
        quality_threshold: 品質閾値
    
    Returns:
        Dict[str, Any]: ADK準拠生成結果
    """
    
    orchestrator = NewsletterADKOrchestrator(project_id, credentials_path)
    
    result = await orchestrator.generate_newsletter(
        audio_transcript=audio_transcript,
        grade_level=grade_level,
        style=style,
        use_parallel_processing=use_parallel_processing,
        quality_threshold=quality_threshold
    )
    
    return result


# ==============================================================================
# テスト関数
# ==============================================================================

async def test_adk_compliant_orchestrator():
    """ADK準拠オーケストレーターのテスト"""
    
    test_transcript = """
    今日は運動会の練習をしました。
    子どもたちは徒競走とダンスの練習を頑張っていました。
    特にたかしくんは最初は走るのが苦手でしたが、
    毎日練習を重ねて今ではクラスで3番目に速くなりました。
    みんなで応援し合う姿が印象的でした。
    """
    
    result = await generate_newsletter_with_adk_compliant(
        audio_transcript=test_transcript,
        project_id="test-project",
        credentials_path="test-credentials.json",
        grade_level="3年1組",
        style="seasonal",
        use_parallel_processing=True,
        quality_threshold=75
    )
    
    print("=== ADK準拠オーケストレーター テスト結果 ===")
    print(f"ステータス: {result.get('status')}")
    print(f"実行時間: {result.get('processing_time_seconds', 0):.2f}秒")
    print(f"ワークフロー: {result.get('workflow_type')}")
    
    if result.get('final_output'):
        output = result['final_output']
        print(f"品質スコア: {output.get('quality_result', {}).get('quality_score', 'N/A')}")
        print(f"生成されたHTML文字数: {len(output.get('html_result', {}).get('html', ''))}")
    
    return result


if __name__ == "__main__":
    # テスト実行
    import asyncio
    asyncio.run(test_adk_compliant_orchestrator())