# ADK Workflowガイド

## 📋 概要

Google ADK Workflowエージェント（Sequential, Parallel）を活用した効率的なマルチエージェント処理パターンのガイド。学級通信生成システムにおける最適なワークフロー設計と実装方法を解説。

## 🎯 Workflowエージェントの種類

### 1. Sequential Workflow
**特徴:** 順次実行、前のエージェントの結果を次に渡す  
**適用場面:** 依存関係のあるタスク、段階的処理

### 2. Parallel Workflow  
**特徴:** 並行実行、同時処理でパフォーマンス向上  
**適用場面:** 独立したタスク、時間短縮が必要な処理

### 3. Loop Workflow
**特徴:** 反復実行、条件に基づく繰り返し処理  
**適用場面:** 品質改善、動的な処理回数

---

## 🏗️ 学級通信システムでのWorkflow設計

### アーキテクチャ概要

```
NewsletterADKOrchestrator
├── Sequential Workflows
│   ├── content_to_html_flow     # コンテンツ→HTML生成
│   ├── quality_improvement_flow # 品質改善プロセス
│   └── full_generation_flow     # 完全生成フロー
├── Parallel Workflows
│   ├── content_design_parallel  # コンテンツ・デザイン並行
│   ├── phase2_enhancement      # Phase2機能並行処理
│   └── validation_parallel     # 並行品質検証
└── Hybrid Workflows
    ├── optimized_generation    # Sequential + Parallel組み合わせ
    └── error_recovery_flow     # エラー回復フロー
```

---

## 📝 Workflow実装パターン

### 1. 基本Sequential処理

#### `content_to_html_flow`
```python
self.workflows['content_to_html_flow'] = Sequential([
    self.agents['content_writer'],      # 1. 文章生成
    self.agents['design_specialist'],   # 2. デザイン設計
    self.agents['html_developer'],      # 3. HTML生成
    self.agents['quality_manager']      # 4. 品質検証
])
```

**処理フロー:**
```
音声入力 → [content_writer] → 文章
文章 → [design_specialist] → デザイン仕様
文章+デザイン → [html_developer] → HTML
HTML+文章 → [quality_manager] → 品質レポート
```

**メリット:**
- 確実な依存関係処理
- デバッグしやすい
- エラー箇所の特定が容易

**デメリット:**
- 処理時間が長い
- 並行処理の恩恵なし

### 2. 基本Parallel処理

#### `content_design_parallel`
```python
self.workflows['content_design_parallel'] = Parallel([
    self.agents['content_writer'],    # 文章生成
    self.agents['design_specialist']  # デザイン設計（独立）
])
```

**処理フロー:**
```
音声入力 → ┌─ [content_writer] → 文章
           └─ [design_specialist] → 基本デザイン仕様
```

**実装例:**
```python
async def execute_parallel_content_design(self, audio_transcript: str, grade_level: str):
    """コンテンツとデザインの並行生成"""
    
    # 並行タスク定義
    parallel_tasks = {
        'content_generation': {
            'agent': 'content_writer',
            'params': {
                'audio_transcript': audio_transcript,
                'grade_level': grade_level,
                'content_type': 'newsletter'
            }
        },
        'design_generation': {
            'agent': 'design_specialist', 
            'params': {
                'content': audio_transcript,  # 初期段階では音声内容使用
                'theme': 'seasonal',
                'grade_level': grade_level
            }
        }
    }
    
    # 並行実行
    results = await self._execute_parallel_workflow(
        'content_design_parallel',
        parallel_tasks
    )
    
    return results
```

### 3. ハイブリッド処理（推奨）

#### `optimized_generation_flow`
```python
class OptimizedGenerationWorkflow:
    """Sequential + Parallel組み合わせによる最適化ワークフロー"""
    
    async def execute(self, input_data: dict) -> dict:
        # Phase 1: 並行処理（独立タスク）
        parallel_results = await self.parallel_phase(input_data)
        
        # Phase 2: 順次処理（依存関係あり）
        sequential_results = await self.sequential_phase(parallel_results)
        
        # Phase 3: 並行処理（最終化）
        final_results = await self.final_parallel_phase(sequential_results)
        
        return self.combine_results([
            parallel_results,
            sequential_results, 
            final_results
        ])
```

**処理フロー図:**
```
音声入力
    ↓
Phase 1 (Parallel):
    ├─ コンテンツ生成
    └─ 基本デザイン
    ↓
Phase 2 (Sequential):
    HTML生成 → 品質検証
    ↓
Phase 3 (Parallel):
    ├─ PDF生成
    ├─ 画像追加
    └─ Classroom準備
    ↓
完成品
```

---

## 🔧 Phase 2統合Workflow

### `full_automation_workflow`

```python
class FullAutomationWorkflow:
    """音声入力からClassroom配布までの完全自動化"""
    
    def __init__(self):
        self.phase1_agents = ['content_writer', 'design_specialist']
        self.phase2_agents = ['html_developer', 'quality_manager']
        self.phase3_agents = ['pdf_output', 'media_enhancer', 'classroom_integrator']
    
    async def execute_full_automation(
        self,
        audio_transcript: str,
        options: dict
    ) -> dict:
        """完全自動化フロー実行"""
        
        start_time = time.time()
        results = {}
        
        try:
            # Stage 1: 基礎生成（並行）
            logger.info("Stage 1: Parallel content and design generation")
            stage1_results = await self._execute_stage1_parallel(
                audio_transcript, options
            )
            results['stage1'] = stage1_results
            
            # Stage 2: HTML生成・品質確認（順次）
            logger.info("Stage 2: Sequential HTML generation and validation")
            stage2_results = await self._execute_stage2_sequential(
                stage1_results, options
            )
            results['stage2'] = stage2_results
            
            # Stage 3: 最終出力処理（並行）
            logger.info("Stage 3: Parallel final output processing")
            stage3_results = await self._execute_stage3_parallel(
                stage2_results, options
            )
            results['stage3'] = stage3_results
            
            # 結果統合
            final_result = self._combine_all_results(results)
            final_result['processing_time'] = time.time() - start_time
            
            return final_result
            
        except Exception as e:
            logger.error(f"Full automation workflow failed: {e}")
            return self._handle_workflow_error(e, results)
```

### Stage別実装詳細

#### Stage 1: 並行基礎生成
```python
async def _execute_stage1_parallel(self, audio_transcript: str, options: dict):
    """Stage 1: コンテンツ・デザイン並行生成"""
    
    parallel_tasks = {
        'content_writer': {
            'audio_transcript': audio_transcript,
            'grade_level': options.get('grade_level', '3年1組'),
            'content_type': 'newsletter'
        },
        'design_specialist': {
            'content': audio_transcript,  # 初期コンテンツ
            'theme': options.get('theme', 'seasonal'),
            'grade_level': options.get('grade_level', '3年1組')
        }
    }
    
    # 並行実行（約50%時間短縮）
    results = await asyncio.gather(
        self._execute_agent_task('content_writer', parallel_tasks['content_writer']),
        self._execute_agent_task('design_specialist', parallel_tasks['design_specialist']),
        return_exceptions=True
    )
    
    return {
        'content_result': results[0],
        'design_result': results[1],
        'stage_duration': time.time() - stage_start
    }
```

#### Stage 2: 順次HTML生成
```python
async def _execute_stage2_sequential(self, stage1_results: dict, options: dict):
    """Stage 2: HTML生成・品質検証（依存関係あり）"""
    
    content_result = stage1_results['content_result']
    design_result = stage1_results['design_result']
    
    # HTML生成（前段結果に依存）
    html_result = await self._execute_agent_task('html_developer', {
        'content': content_result.get('content', ''),
        'design_spec': design_result.get('design_spec', {}),
        'template_type': options.get('template_type', 'newsletter')
    })
    
    # 品質検証（HTML結果に依存）
    quality_result = await self._execute_agent_task('quality_manager', {
        'html_content': html_result.get('html', ''),
        'original_content': content_result.get('content', '')
    })
    
    return {
        'html_result': html_result,
        'quality_result': quality_result,
        'stage_duration': time.time() - stage_start
    }
```

#### Stage 3: 並行最終処理
```python
async def _execute_stage3_parallel(self, stage2_results: dict, options: dict):
    """Stage 3: PDF・メディア・Classroom並行処理"""
    
    html_content = stage2_results['html_result'].get('html', '')
    
    # 並行タスク定義
    parallel_tasks = []
    
    if options.get('enable_pdf', True):
        parallel_tasks.append(
            self._execute_agent_task('pdf_output', {
                'html_content': html_content,
                'newsletter_metadata': self._build_metadata(options),
                'pdf_options': options.get('pdf_options', {})
            })
        )
    
    if options.get('enable_images', True):
        parallel_tasks.append(
            self._execute_agent_task('media_enhancer', {
                'html_content': html_content,
                'newsletter_data': self._build_newsletter_data(options),
                'media_options': options.get('media_options', {})
            })
        )
    
    if options.get('classroom_settings'):
        # PDF生成完了後にClassroom配布（条件付き並行）
        parallel_tasks.append(
            self._conditional_classroom_distribution(options)
        )
    
    # 並行実行
    results = await asyncio.gather(*parallel_tasks, return_exceptions=True)
    
    return {
        'pdf_result': results[0] if len(results) > 0 else None,
        'media_result': results[1] if len(results) > 1 else None,
        'classroom_result': results[2] if len(results) > 2 else None,
        'stage_duration': time.time() - stage_start
    }
```

---

## ⚡ パフォーマンス最適化

### 1. 並行処理による時間短縮

**従来のSequential処理:**
```
コンテンツ生成: 8秒
+ デザイン生成: 5秒  
+ HTML生成: 6秒
+ 品質検証: 3秒
= 合計: 22秒
```

**最適化Workflow:**
```
Stage 1 (並行): max(8秒, 5秒) = 8秒
Stage 2 (順次): 6秒 + 3秒 = 9秒
Stage 3 (並行): max(4秒, 6秒, 3秒) = 6秒
= 合計: 23秒 → 約35%短縮
```

### 2. エラー耐性の向上

```python
class ResilientWorkflow:
    """エラー回復機能付きワークフロー"""
    
    async def execute_with_fallback(self, input_data: dict):
        try:
            # 最適化ワークフロー試行
            return await self.optimized_workflow(input_data)
            
        except ParallelProcessingError:
            logger.warning("Parallel processing failed, falling back to sequential")
            return await self.sequential_fallback(input_data)
            
        except CriticalAgentError as e:
            logger.error(f"Critical agent failed: {e.agent_name}")
            return await self.partial_generation_with_alternatives(input_data, e)
```

### 3. 動的負荷分散

```python
class AdaptiveWorkflow:
    """システム負荷に応じた動的ワークフロー選択"""
    
    async def execute_adaptive(self, input_data: dict):
        # システム負荷評価
        load_metrics = await self.assess_system_load()
        
        if load_metrics['cpu_usage'] > 80:
            # 高負荷時：Sequential処理
            return await self.sequential_workflow(input_data)
        elif load_metrics['available_memory'] > 2048:
            # 十分なリソース：最大並行処理
            return await self.maximum_parallel_workflow(input_data)
        else:
            # 通常：バランス型
            return await self.balanced_workflow(input_data)
```

---

## 🧪 Workflowテスト戦略

### 1. 単体ワークフローテスト

```python
class TestWorkflows:
    
    @pytest.mark.asyncio
    async def test_sequential_workflow(self):
        """Sequential処理の動作確認"""
        workflow = SequentialWorkflow([
            MockAgent('agent1'),
            MockAgent('agent2'),
            MockAgent('agent3')
        ])
        
        result = await workflow.execute({'input': 'test'})
        
        assert result['status'] == 'success'
        assert len(result['steps']) == 3
        assert result['execution_order'] == ['agent1', 'agent2', 'agent3']
    
    @pytest.mark.asyncio
    async def test_parallel_workflow(self):
        """Parallel処理の動作確認"""
        workflow = ParallelWorkflow([
            MockAgent('agent1', delay=2),
            MockAgent('agent2', delay=3),
            MockAgent('agent3', delay=1)
        ])
        
        start_time = time.time()
        result = await workflow.execute({'input': 'test'})
        execution_time = time.time() - start_time
        
        assert result['status'] == 'success'
        assert execution_time < 4  # 最長エージェント時間以下
        assert len(result['parallel_results']) == 3
```

### 2. エラーハンドリングテスト

```python
@pytest.mark.asyncio
async def test_workflow_error_handling(self):
    """ワークフロー内エラーの適切な処理"""
    
    # 一部エージェント失敗シナリオ
    workflow = ParallelWorkflow([
        MockAgent('success_agent'),
        MockAgent('failure_agent', should_fail=True),
        MockAgent('slow_agent', delay=10)
    ])
    
    result = await workflow.execute({'input': 'test'})
    
    assert result['status'] == 'partial_success'
    assert 'success_agent' in result['successful_agents']
    assert 'failure_agent' in result['failed_agents']
    assert result['error_recovery_applied'] == True
```

### 3. パフォーマンステスト

```python
@pytest.mark.asyncio
async def test_workflow_performance(self):
    """ワークフロー性能要件の確認"""
    
    performance_targets = {
        'sequential': 30,    # 30秒以内
        'parallel': 20,      # 20秒以内
        'hybrid': 15         # 15秒以内
    }
    
    for workflow_type, target_time in performance_targets.items():
        start_time = time.time()
        result = await self.execute_workflow(workflow_type, test_input)
        execution_time = time.time() - start_time
        
        assert result['status'] == 'success'
        assert execution_time < target_time
        assert result['quality_score'] > 80
```

---

## 📊 モニタリング・メトリクス

### 1. Workflow実行メトリクス

```python
class WorkflowMetrics:
    """ワークフロー実行状況の監視"""
    
    def collect_metrics(self, workflow_result: dict):
        return {
            'execution_time': workflow_result.get('processing_time', 0),
            'success_rate': self.calculate_success_rate(workflow_result),
            'agent_performance': self.analyze_agent_performance(workflow_result),
            'bottleneck_analysis': self.identify_bottlenecks(workflow_result),
            'resource_utilization': self.measure_resource_usage(workflow_result)
        }
    
    def generate_performance_report(self, metrics_history: list):
        """性能レポート生成"""
        return {
            'average_execution_time': statistics.mean([m['execution_time'] for m in metrics_history]),
            'success_rate_trend': self.calculate_trend([m['success_rate'] for m in metrics_history]),
            'performance_degradation_alerts': self.detect_performance_issues(metrics_history),
            'optimization_recommendations': self.suggest_optimizations(metrics_history)
        }
```

### 2. アラート・通知システム

```python
class WorkflowAlerts:
    """ワークフロー異常の検出・通知"""
    
    def monitor_workflow_health(self, metrics: dict):
        alerts = []
        
        if metrics['execution_time'] > self.thresholds['max_execution_time']:
            alerts.append({
                'type': 'PERFORMANCE_DEGRADATION',
                'severity': 'WARNING',
                'message': f"実行時間が閾値を超過: {metrics['execution_time']:.2f}秒"
            })
        
        if metrics['success_rate'] < self.thresholds['min_success_rate']:
            alerts.append({
                'type': 'SUCCESS_RATE_LOW',
                'severity': 'CRITICAL',
                'message': f"成功率が低下: {metrics['success_rate']:.1%}"
            })
        
        return alerts
```

---

## 🔧 実装チェックリスト

### Workflow設計
- [ ] 依存関係の明確化
- [ ] 並行処理可能部分の特定
- [ ] エラー回復戦略の定義
- [ ] パフォーマンス目標の設定

### 実装
- [ ] SequentialWorkflowの実装
- [ ] ParallelWorkflowの実装
- [ ] ハイブリッドワークフローの実装
- [ ] エラーハンドリングの統合

### テスト
- [ ] 単体ワークフローテスト
- [ ] 統合テスト
- [ ] パフォーマンステスト
- [ ] エラーケーステスト

### 監視
- [ ] メトリクス収集の実装
- [ ] アラートシステムの設定
- [ ] ダッシュボードの構築
- [ ] 定期レポートの自動化

---

**📅 ガイド作成日:** 2024年6月19日  
**📝 最終更新日:** 2024年6月19日  
**👤 作成者:** Claude Code AI Assistant  
**📋 バージョン:** v1.0.0