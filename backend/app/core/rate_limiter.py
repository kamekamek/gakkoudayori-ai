"""
FastAPI Rate Limiting & API Security
レート制限とAPIセキュリティ機能
"""

import asyncio
import hashlib
import logging
import time
from collections import defaultdict, deque
from datetime import datetime, timedelta
from typing import Dict, List, Optional

import redis
from fastapi import Depends, HTTPException, Request
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer


class InMemoryRateLimiter:
    """インメモリレート制限（Redis不使用版）"""

    def __init__(self):
        self.requests: Dict[str, deque] = defaultdict(lambda: deque())
        self.blocked_ips: Dict[str, float] = {}
        self.logger = logging.getLogger(__name__)

    def is_allowed(
        self, identifier: str, limit: int, window: int
    ) -> tuple[bool, Dict[str, any]]:
        """
        レート制限チェック

        Args:
            identifier: 識別子（IPアドレス、ユーザーID等）
            limit: 制限回数
            window: 時間窓（秒）

        Returns:
            (許可可否, メタデータ)
        """
        current_time = time.time()

        # ブロック中のIPチェック
        if identifier in self.blocked_ips:
            if current_time < self.blocked_ips[identifier]:
                remaining_time = int(self.blocked_ips[identifier] - current_time)
                return False, {
                    "blocked": True,
                    "reset_time": remaining_time,
                    "reason": "IP temporarily blocked due to rate limit violations",
                }
            else:
                # ブロック期間終了
                del self.blocked_ips[identifier]

        # 古いリクエストを削除
        request_times = self.requests[identifier]
        while request_times and request_times[0] < current_time - window:
            request_times.popleft()

        # レート制限チェック
        if len(request_times) >= limit:
            # 連続違反の場合は一時ブロック
            if len(request_times) >= limit * 2:
                self.blocked_ips[identifier] = current_time + 300  # 5分間ブロック
                self.logger.warning(
                    f"IP {identifier} blocked for 5 minutes due to excessive requests"
                )

            remaining_time = int(window - (current_time - request_times[0]))
            return False, {
                "blocked": False,
                "limit": limit,
                "remaining": 0,
                "reset_time": remaining_time,
                "reason": f"Rate limit exceeded: {limit} requests per {window} seconds",
            }

        # リクエストを記録
        request_times.append(current_time)

        return True, {
            "blocked": False,
            "limit": limit,
            "remaining": limit - len(request_times),
            "reset_time": window,
        }


class APISecurityMonitor:
    """API セキュリティ監視"""

    def __init__(self):
        self.suspicious_patterns = {
            "sql_injection": [
                "union select",
                "drop table",
                "delete from",
                "insert into",
                "update set",
                "exec(",
                "execute(",
            ],
            "xss": [
                "<script",
                "javascript:",
                "onerror=",
                "onload=",
                "eval(",
                "setTimeout(",
                "setInterval(",
            ],
            "path_traversal": [
                "../",
                "..\\",
                "/etc/passwd",
                "/etc/shadow",
                "c:\\windows",
                "c:/windows",
            ],
            "command_injection": [
                ";rm -rf",
                ";cat /etc",
                "|nc ",
                "&whoami",
                "`id`",
                "$(whoami)",
                ";curl ",
                ";wget ",
            ],
        }

        self.threat_scores: Dict[str, int] = defaultdict(int)
        self.threat_history: Dict[str, List[Dict]] = defaultdict(list)
        self.logger = logging.getLogger(__name__)

    def analyze_request(self, request: Request) -> Dict[str, any]:
        """リクエストのセキュリティ分析"""
        client_ip = self._get_client_ip(request)
        threats_detected = []
        threat_score = 0

        # URL パス分析
        path_threats = self._check_patterns(request.url.path, "path_traversal")
        threats_detected.extend(path_threats)

        # クエリパラメータ分析
        if request.url.query:
            query_threats = []
            for pattern_type in self.suspicious_patterns:
                query_threats.extend(
                    self._check_patterns(request.url.query, pattern_type)
                )
            threats_detected.extend(query_threats)

        # ヘッダー分析
        suspicious_headers = self._analyze_headers(request.headers)
        threats_detected.extend(suspicious_headers)

        # User-Agent 分析
        user_agent = request.headers.get("user-agent", "")
        if self._is_suspicious_user_agent(user_agent):
            threats_detected.append(
                {
                    "type": "suspicious_user_agent",
                    "description": "Potentially malicious user agent",
                    "severity": "medium",
                }
            )

        # 脅威スコア計算
        for threat in threats_detected:
            if threat["severity"] == "high":
                threat_score += 10
            elif threat["severity"] == "medium":
                threat_score += 5
            else:
                threat_score += 1

        # 累積脅威スコア更新
        self.threat_scores[client_ip] += threat_score

        # 脅威履歴記録
        if threats_detected:
            self.threat_history[client_ip].append(
                {
                    "timestamp": datetime.utcnow().isoformat(),
                    "threats": threats_detected,
                    "score": threat_score,
                    "path": request.url.path,
                    "method": request.method,
                }
            )

        return {
            "client_ip": client_ip,
            "threats_detected": threats_detected,
            "threat_score": threat_score,
            "cumulative_score": self.threat_scores[client_ip],
            "is_suspicious": threat_score > 0 or self.threat_scores[client_ip] > 50,
        }

    def _get_client_ip(self, request: Request) -> str:
        """クライアントIPアドレスを取得"""
        # プロキシ経由の場合のヘッダーをチェック
        forwarded_for = request.headers.get("x-forwarded-for")
        if forwarded_for:
            return forwarded_for.split(",")[0].strip()

        real_ip = request.headers.get("x-real-ip")
        if real_ip:
            return real_ip

        # デフォルトのクライアントIP
        return request.client.host if request.client else "unknown"

    def _check_patterns(self, text: str, pattern_type: str) -> List[Dict]:
        """パターンマッチングによる脅威検出"""
        threats = []
        text_lower = text.lower()

        for pattern in self.suspicious_patterns.get(pattern_type, []):
            if pattern in text_lower:
                threats.append(
                    {
                        "type": pattern_type,
                        "pattern": pattern,
                        "description": f"Potential {pattern_type.replace('_', ' ')} attempt",
                        "severity": (
                            "high"
                            if pattern_type in ["sql_injection", "command_injection"]
                            else "medium"
                        ),
                    }
                )

        return threats

    def _analyze_headers(self, headers) -> List[Dict]:
        """HTTPヘッダー分析"""
        threats = []

        # 疑わしいヘッダーのチェック
        suspicious_headers = {
            "x-forwarded-host": "potential_host_header_injection",
            "x-original-url": "potential_url_rewrite_attack",
            "x-rewrite-url": "potential_url_rewrite_attack",
        }

        for header, threat_type in suspicious_headers.items():
            if header in headers:
                threats.append(
                    {
                        "type": threat_type,
                        "description": f"Suspicious header detected: {header}",
                        "severity": "medium",
                    }
                )

        return threats

    def _is_suspicious_user_agent(self, user_agent: str) -> bool:
        """疑わしいUser-Agentの判定"""
        suspicious_patterns = [
            "sqlmap",
            "nikto",
            "nmap",
            "masscan",
            "nessus",
            "openvas",
            "burp",
            "metasploit",
            "w3af",
            "skipfish",
        ]

        user_agent_lower = user_agent.lower()
        return any(pattern in user_agent_lower for pattern in suspicious_patterns)


# グローバルインスタンス
rate_limiter = InMemoryRateLimiter()
security_monitor = APISecurityMonitor()


async def check_rate_limit(
    request: Request, limit: int = 100, window: int = 3600  # 1時間
):
    """レート制限チェック用の依存関数"""
    client_ip = security_monitor._get_client_ip(request)

    # セキュリティ分析
    security_analysis = security_monitor.analyze_request(request)

    # 高脅威の場合は厳しいレート制限
    if security_analysis["threat_score"] > 10:
        limit = min(limit, 10)
        window = max(window, 3600)

    # レート制限チェック
    allowed, metadata = rate_limiter.is_allowed(client_ip, limit, window)

    if not allowed:
        # セキュリティアラートをログ出力
        if security_analysis["is_suspicious"]:
            logging.getLogger(__name__).warning(
                f"Rate limit exceeded for suspicious IP {client_ip}: "
                f"threats={len(security_analysis['threats_detected'])}, "
                f"score={security_analysis['threat_score']}"
            )

        raise HTTPException(
            status_code=429,
            detail={
                "error": "Rate limit exceeded",
                "metadata": metadata,
                "security_info": {
                    "threat_score": security_analysis["threat_score"],
                    "is_suspicious": security_analysis["is_suspicious"],
                },
            },
            headers={"Retry-After": str(metadata.get("reset_time", 60))},
        )

    return {
        "client_ip": client_ip,
        "rate_limit_info": metadata,
        "security_analysis": security_analysis,
    }


# 各エンドポイント用のレート制限設定
async def rate_limit_strict(request: Request):
    """厳しいレート制限（AIエンドポイント用）"""
    return await check_rate_limit(request, limit=20, window=3600)  # 1時間に20回


async def rate_limit_moderate(request: Request):
    """中程度のレート制限（一般API用）"""
    return await check_rate_limit(request, limit=100, window=3600)  # 1時間に100回


async def rate_limit_relaxed(request: Request):
    """緩いレート制限（静的コンテンツ用）"""
    return await check_rate_limit(request, limit=1000, window=3600)  # 1時間に1000回


class SecurityHeaders:
    """セキュリティヘッダーミドルウェア"""

    @staticmethod
    def add_security_headers(response):
        """セキュリティヘッダーを追加"""
        # XSS保護
        response.headers["X-XSS-Protection"] = "1; mode=block"

        # コンテンツタイプ嗅ぎ取り防止
        response.headers["X-Content-Type-Options"] = "nosniff"

        # Clickjacking防止
        response.headers["X-Frame-Options"] = "DENY"

        # HTTPS強制（本番環境）
        response.headers["Strict-Transport-Security"] = (
            "max-age=31536000; includeSubDomains"
        )

        # リファラー制御
        response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"

        # 権限ポリシー
        response.headers["Permissions-Policy"] = (
            "geolocation=(), microphone=(), camera=()"
        )

        return response


def get_security_report() -> Dict[str, any]:
    """セキュリティレポートを取得"""
    total_threats = sum(
        len(history) for history in security_monitor.threat_history.values()
    )
    high_risk_ips = [
        ip for ip, score in security_monitor.threat_scores.items() if score > 50
    ]

    recent_attacks = []
    for ip, history in security_monitor.threat_history.items():
        for event in history[-5:]:  # 最新5件
            recent_attacks.append(
                {
                    "ip": ip,
                    "timestamp": event["timestamp"],
                    "threats": len(event["threats"]),
                    "score": event["score"],
                    "path": event["path"],
                }
            )

    return {
        "total_monitored_ips": len(security_monitor.threat_scores),
        "total_threats_detected": total_threats,
        "high_risk_ips": high_risk_ips,
        "blocked_ips": len(rate_limiter.blocked_ips),
        "recent_attacks": sorted(
            recent_attacks, key=lambda x: x["timestamp"], reverse=True
        )[:10],
        "timestamp": datetime.utcnow().isoformat(),
    }
