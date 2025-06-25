"""
ADK Agent Performance Monitoring & Optimization
パフォーマンス監視と最適化機能
"""
import time
import asyncio
import logging
import psutil
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any
from dataclasses import dataclass, field
from collections import defaultdict, deque
import json


@dataclass
class PerformanceMetrics:
    """パフォーマンスメトリクス"""
    execution_time: float
    memory_usage: float  # MB
    cpu_usage: float  # %
    success: bool
    error_message: Optional[str] = None
    timestamp: datetime = field(default_factory=datetime.utcnow)
    agent_name: str = ""
    operation: str = ""
    context_data: Dict[str, Any] = field(default_factory=dict)


class PerformanceMonitor:
    """パフォーマンス監視システム"""
    
    def __init__(self, max_history: int = 1000):
        self.logger = logging.getLogger(__name__)
        self.metrics_history: deque = deque(maxlen=max_history)
        self.agent_stats: Dict[str, List[PerformanceMetrics]] = defaultdict(list)
        self.start_time = datetime.utcnow()
        self.thresholds = {
            'execution_time': 30.0,  # seconds
            'memory_usage': 500.0,   # MB
            'cpu_usage': 80.0,       # %
            'error_rate': 0.1        # 10%
        }
        
    def start_monitoring(self, agent_name: str, operation: str) -> 'PerformanceContext':
        """パフォーマンス監視を開始"""
        return PerformanceContext(self, agent_name, operation)
    
    def record_metrics(self, metrics: PerformanceMetrics):
        """メトリクスを記録"""
        self.metrics_history.append(metrics)
        self.agent_stats[metrics.agent_name].append(metrics)
        
        # しきい値チェック
        self._check_thresholds(metrics)
        
        # ログ出力
        self._log_metrics(metrics)
    
    def _check_thresholds(self, metrics: PerformanceMetrics):
        """しきい値をチェックして警告を出力"""
        warnings = []
        
        if metrics.execution_time > self.thresholds['execution_time']:
            warnings.append(f"Execution time exceeded: {metrics.execution_time:.2f}s")
        
        if metrics.memory_usage > self.thresholds['memory_usage']:
            warnings.append(f"Memory usage exceeded: {metrics.memory_usage:.2f}MB")
        
        if metrics.cpu_usage > self.thresholds['cpu_usage']:
            warnings.append(f"CPU usage exceeded: {metrics.cpu_usage:.2f}%")
        
        if warnings:
            self.logger.warning(
                f"Performance warnings for {metrics.agent_name}.{metrics.operation}: "
                f"{', '.join(warnings)}"
            )
    
    def _log_metrics(self, metrics: PerformanceMetrics):
        """メトリクスをログ出力"""
        log_data = {
            'agent': metrics.agent_name,
            'operation': metrics.operation,
            'execution_time': round(metrics.execution_time, 3),
            'memory_mb': round(metrics.memory_usage, 2),
            'cpu_percent': round(metrics.cpu_usage, 2),
            'success': metrics.success,
            'timestamp': metrics.timestamp.isoformat()
        }
        
        if metrics.error_message:
            log_data['error'] = metrics.error_message
        
        self.logger.info(f"Performance metrics: {json.dumps(log_data)}")
    
    def get_agent_stats(self, agent_name: str, hours: int = 24) -> Dict[str, Any]:
        """エージェントの統計情報を取得"""
        cutoff_time = datetime.utcnow() - timedelta(hours=hours)
        recent_metrics = [
            m for m in self.agent_stats[agent_name] 
            if m.timestamp > cutoff_time
        ]
        
        if not recent_metrics:
            return {'agent_name': agent_name, 'no_data': True}
        
        execution_times = [m.execution_time for m in recent_metrics]
        memory_usages = [m.memory_usage for m in recent_metrics]
        cpu_usages = [m.cpu_usage for m in recent_metrics]
        successes = [m.success for m in recent_metrics]
        
        return {
            'agent_name': agent_name,
            'period_hours': hours,
            'total_operations': len(recent_metrics),
            'success_rate': sum(successes) / len(successes) if successes else 0,
            'avg_execution_time': sum(execution_times) / len(execution_times),
            'max_execution_time': max(execution_times),
            'min_execution_time': min(execution_times),
            'avg_memory_usage': sum(memory_usages) / len(memory_usages),
            'max_memory_usage': max(memory_usages),
            'avg_cpu_usage': sum(cpu_usages) / len(cpu_usages),
            'max_cpu_usage': max(cpu_usages),
            'last_operation': recent_metrics[-1].timestamp.isoformat()
        }
    
    def get_system_health(self) -> Dict[str, Any]:
        """システムの健全性を取得"""
        try:
            memory = psutil.virtual_memory()
            cpu_percent = psutil.cpu_percent(interval=1)
            disk = psutil.disk_usage('/')
            
            # 最近1時間のエラー率
            cutoff_time = datetime.utcnow() - timedelta(hours=1)
            recent_metrics = [
                m for m in self.metrics_history 
                if m.timestamp > cutoff_time
            ]
            
            error_rate = 0
            if recent_metrics:
                errors = sum(1 for m in recent_metrics if not m.success)
                error_rate = errors / len(recent_metrics)
            
            health_status = "healthy"
            issues = []
            
            if cpu_percent > self.thresholds['cpu_usage']:
                health_status = "warning"
                issues.append(f"High CPU usage: {cpu_percent:.1f}%")
            
            if memory.percent > 85:
                health_status = "warning"
                issues.append(f"High memory usage: {memory.percent:.1f}%")
            
            if error_rate > self.thresholds['error_rate']:
                health_status = "critical" if error_rate > 0.3 else "warning"
                issues.append(f"High error rate: {error_rate:.1%}")
            
            return {
                'status': health_status,
                'uptime_hours': (datetime.utcnow() - self.start_time).total_seconds() / 3600,
                'cpu_percent': cpu_percent,
                'memory_percent': memory.percent,
                'memory_available_gb': memory.available / (1024**3),
                'disk_free_gb': disk.free / (1024**3),
                'error_rate_1h': error_rate,
                'total_operations': len(self.metrics_history),
                'issues': issues,
                'timestamp': datetime.utcnow().isoformat()
            }
        except Exception as e:
            self.logger.error(f"Failed to get system health: {e}")
            return {
                'status': 'unknown',
                'error': str(e),
                'timestamp': datetime.utcnow().isoformat()
            }
    
    def get_performance_recommendations(self) -> List[str]:
        """パフォーマンス改善の推奨事項を生成"""
        recommendations = []
        
        # 最近の統計から問題を特定
        recent_stats = {}
        for agent_name in self.agent_stats:
            stats = self.get_agent_stats(agent_name, hours=24)
            if not stats.get('no_data'):
                recent_stats[agent_name] = stats
        
        # 実行時間の問題
        slow_agents = [
            name for name, stats in recent_stats.items()
            if stats['avg_execution_time'] > self.thresholds['execution_time']
        ]
        if slow_agents:
            recommendations.append(
                f"以下のエージェントの処理速度を改善してください: {', '.join(slow_agents)}"
            )
        
        # メモリ使用量の問題
        memory_hungry_agents = [
            name for name, stats in recent_stats.items()
            if stats['avg_memory_usage'] > self.thresholds['memory_usage']
        ]
        if memory_hungry_agents:
            recommendations.append(
                f"以下のエージェントのメモリ使用量を最適化してください: {', '.join(memory_hungry_agents)}"
            )
        
        # エラー率の問題
        error_prone_agents = [
            name for name, stats in recent_stats.items()
            if stats['success_rate'] < (1 - self.thresholds['error_rate'])
        ]
        if error_prone_agents:
            recommendations.append(
                f"以下のエージェントのエラーハンドリングを改善してください: {', '.join(error_prone_agents)}"
            )
        
        # システムレベルの推奨事項
        health = self.get_system_health()
        if health['cpu_percent'] > 70:
            recommendations.append("CPU使用率が高いため、並行処理を見直してください")
        
        if health['memory_percent'] > 80:
            recommendations.append("メモリ使用率が高いため、キャッシュ戦略を見直してください")
        
        return recommendations or ["現在のパフォーマンスは良好です"]


class PerformanceContext:
    """パフォーマンス監視コンテキスト"""
    
    def __init__(self, monitor: PerformanceMonitor, agent_name: str, operation: str):
        self.monitor = monitor
        self.agent_name = agent_name
        self.operation = operation
        self.start_time = None
        self.start_memory = None
        self.start_cpu = None
        
    async def __aenter__(self):
        """監視開始"""
        self.start_time = time.time()
        
        try:
            process = psutil.Process()
            self.start_memory = process.memory_info().rss / (1024 * 1024)  # MB
            self.start_cpu = process.cpu_percent()
        except:
            self.start_memory = 0
            self.start_cpu = 0
        
        return self
    
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        """監視終了とメトリクス記録"""
        execution_time = time.time() - self.start_time
        
        try:
            process = psutil.Process()
            end_memory = process.memory_info().rss / (1024 * 1024)  # MB
            end_cpu = process.cpu_percent()
            
            memory_usage = max(end_memory - self.start_memory, 0)
            cpu_usage = end_cpu
        except:
            memory_usage = 0
            cpu_usage = 0
        
        success = exc_type is None
        error_message = str(exc_val) if exc_val else None
        
        metrics = PerformanceMetrics(
            execution_time=execution_time,
            memory_usage=memory_usage,
            cpu_usage=cpu_usage,
            success=success,
            error_message=error_message,
            agent_name=self.agent_name,
            operation=self.operation
        )
        
        self.monitor.record_metrics(metrics)


# グローバルパフォーマンスモニターのインスタンス
performance_monitor = PerformanceMonitor()


def monitor_performance(operation: str = "unknown"):
    """パフォーマンス監視デコレータ"""
    def decorator(func):
        if asyncio.iscoroutinefunction(func):
            async def async_wrapper(self, *args, **kwargs):
                agent_name = getattr(self, 'name', self.__class__.__name__)
                async with performance_monitor.start_monitoring(agent_name, operation):
                    return await func(self, *args, **kwargs)
            return async_wrapper
        else:
            def sync_wrapper(self, *args, **kwargs):
                agent_name = getattr(self, 'name', self.__class__.__name__)
                # 同期関数用の簡易監視
                start_time = time.time()
                try:
                    result = func(self, *args, **kwargs)
                    success = True
                    error_message = None
                except Exception as e:
                    success = False
                    error_message = str(e)
                    raise
                finally:
                    execution_time = time.time() - start_time
                    metrics = PerformanceMetrics(
                        execution_time=execution_time,
                        memory_usage=0,  # 同期関数では簡易計測
                        cpu_usage=0,
                        success=success,
                        error_message=error_message,
                        agent_name=agent_name,
                        operation=operation
                    )
                    performance_monitor.record_metrics(metrics)
                return result
            return sync_wrapper
    return decorator