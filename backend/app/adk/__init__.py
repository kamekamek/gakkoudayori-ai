from .agents import create_generation_workflow_agent

# ADKがアプリケーションのエントリーポイントとして認識する規約です。
root_agent = create_generation_workflow_agent()
