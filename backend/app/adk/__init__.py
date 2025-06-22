from .agents import create_orchestrator_agent

# ADKがアプリケーションのエントリーポイントとして認識する規約です。
root_agent = create_orchestrator_agent()
