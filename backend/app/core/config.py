from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    """
    アプリケーション全体の設定を管理します。
    環境変数や.envファイルから値を読み込むことができます。
    """
    # --------------------------------
    # LLM Model Settings
    # --------------------------------
    # 使用するモデル名を指定します
    GEMINI_MODEL: str = "gemini-2.5-pro"


settings = Settings() 