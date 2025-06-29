import re
from datetime import datetime
from typing import List, Optional

from pydantic import BaseModel, Field, validator


class TitleTemplate(BaseModel):
    """タイトルテンプレートの個別設定"""
    id: str = Field(..., description="テンプレートID")
    name: str = Field(..., min_length=1, max_length=50, description="テンプレート名")
    pattern: str = Field(..., min_length=1, max_length=100, description="タイトルパターン（○は自動置換）")
    category: str = Field(default="custom", description="カテゴリ（custom/seasonal/event）")
    usage_count: int = Field(default=0, description="使用回数")
    last_used: Optional[datetime] = Field(default=None, description="最終使用日時")


class TitleTemplates(BaseModel):
    """タイトルテンプレート管理"""
    primary: str = Field(default="学級だより○号", description="メインテンプレート")
    seasonal: List[str] = Field(default_factory=lambda: ["夏休み号", "冬休み号", "運動会号"], description="季節・行事テンプレート")
    custom: List[TitleTemplate] = Field(default_factory=list, description="カスタムテンプレート")
    default_pattern: str = Field(default="○年○組 学級通信", description="デフォルトパターン")
    auto_numbering: bool = Field(default=True, description="自動ナンバリング有効")
    current_number: int = Field(default=1, description="現在の号数")


class UIPreferences(BaseModel):
    """UI表示設定"""
    show_title_field: bool = Field(default=False, description="タイトル入力フィールド表示")
    auto_generate_title: bool = Field(default=True, description="AI自動タイトル生成")
    image_upload_location: str = Field(default="chat", description="画像アップロード位置")
    theme: str = Field(default="default", description="テーマ設定")
    language: str = Field(default="ja", description="言語設定")

    @validator('image_upload_location')
    def validate_image_location(cls, v):
        if v not in ['chat', 'header', 'both', 'hidden']:
            raise ValueError('image_upload_location must be chat, header, both, or hidden')
        return v


class NotificationSettings(BaseModel):
    """通知設定"""
    email_notifications: bool = Field(default=True, description="メール通知")
    browser_notifications: bool = Field(default=False, description="ブラウザ通知")
    reminder_frequency: str = Field(default="weekly", description="リマインダー頻度")
    quiet_hours_start: Optional[str] = Field(default="22:00", description="静音時間開始")
    quiet_hours_end: Optional[str] = Field(default="08:00", description="静音時間終了")


class WorkflowSettings(BaseModel):
    """ワークフロー設定"""
    auto_save_interval: int = Field(default=30, description="自動保存間隔（秒）")
    draft_retention_days: int = Field(default=30, description="下書き保持日数")
    backup_enabled: bool = Field(default=True, description="バックアップ有効")
    collaboration_mode: bool = Field(default=False, description="コラボレーションモード")


class UserSettings(BaseModel):
    """ユーザー設定の統合モデル"""
    # 基本設定
    school_name: str = Field(..., min_length=1, max_length=50, description="学校名")
    class_name: str = Field(..., description="クラス名")
    teacher_name: str = Field(..., min_length=1, max_length=20, description="先生名")

    # 拡張設定
    title_templates: TitleTemplates = Field(default_factory=TitleTemplates, description="タイトルテンプレート")
    ui_preferences: UIPreferences = Field(default_factory=UIPreferences, description="UI設定")
    notification_settings: NotificationSettings = Field(default_factory=NotificationSettings, description="通知設定")
    workflow_settings: WorkflowSettings = Field(default_factory=WorkflowSettings, description="ワークフロー設定")

    # メタデータ
    version: str = Field(default="2.0", description="設定スキーマバージョン")
    created_at: Optional[datetime] = Field(default=None, description="作成日時")
    updated_at: Optional[datetime] = Field(default=None, description="更新日時")

    @validator('class_name')
    def validate_class_name(cls, v):
        # 日本の学級名パターンをチェック（例: "3年1組", "6年A組"）
        if not re.match(r'^[0-9]+年[0-9A-Za-z]+組$', v):
            # 柔軟性を持たせ、基本的な文字列として受け入れる
            if len(v.strip()) == 0:
                raise ValueError('class_name cannot be empty')
        return v.strip()

    @validator('school_name', 'teacher_name')
    def validate_non_empty_strings(cls, v):
        if not v or not v.strip():
            raise ValueError('Field cannot be empty')
        return v.strip()


class UserSettingsCreate(BaseModel):
    """ユーザー設定作成用モデル"""
    school_name: str
    class_name: str
    teacher_name: str
    title_templates: Optional[TitleTemplates] = None
    ui_preferences: Optional[UIPreferences] = None
    notification_settings: Optional[NotificationSettings] = None
    workflow_settings: Optional[WorkflowSettings] = None


class UserSettingsUpdate(BaseModel):
    """ユーザー設定更新用モデル"""
    school_name: Optional[str] = None
    class_name: Optional[str] = None
    teacher_name: Optional[str] = None
    title_templates: Optional[TitleTemplates] = None
    ui_preferences: Optional[UIPreferences] = None
    notification_settings: Optional[NotificationSettings] = None
    workflow_settings: Optional[WorkflowSettings] = None


class TitleSuggestion(BaseModel):
    """タイトル提案用モデル"""
    title: str = Field(..., description="提案タイトル")
    confidence: float = Field(..., ge=0.0, le=1.0, description="信頼度")
    source: str = Field(..., description="提案ソース")
    template_used: Optional[str] = Field(default=None, description="使用テンプレート")


class TitleSuggestionRequest(BaseModel):
    """タイトル提案リクエスト"""
    content_hint: Optional[str] = Field(default=None, description="内容ヒント")
    event_type: Optional[str] = Field(default=None, description="イベントタイプ")
    season: Optional[str] = Field(default=None, description="季節")
    urgency: str = Field(default="normal", description="緊急度")


class UserSettingsResponse(BaseModel):
    """ユーザー設定レスポンス用モデル"""
    settings: Optional[UserSettings]
    is_complete: bool = Field(..., description="設定完了フラグ")
    missing_fields: List[str] = Field(default_factory=list, description="未設定フィールド")
    suggestions: List[str] = Field(default_factory=list, description="設定改善提案")
