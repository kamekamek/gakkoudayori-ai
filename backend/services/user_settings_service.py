import logging
from datetime import datetime, timezone
from functools import lru_cache
from typing import Any, Dict, List, Optional

from google.cloud import firestore

from models.user_settings import (
    NotificationSettings,
    TitleSuggestion,
    TitleSuggestionRequest,
    TitleTemplate,
    TitleTemplates,
    UIPreferences,
    UserSettings,
    UserSettingsCreate,
    UserSettingsUpdate,
    WorkflowSettings,
)

logger = logging.getLogger(__name__)


@lru_cache()
def get_db_client() -> firestore.AsyncClient:
    """Firestoreクライアントのシングルトンインスタンスを返す"""
    return firestore.AsyncClient()


class UserSettingsService:
    """ユーザー設定管理サービス"""

    def __init__(self):
        self.db = get_db_client()

    async def get_user_settings(self, user_id: str) -> Optional[UserSettings]:
        """ユーザー設定を取得"""
        try:
            doc_ref = self.db.collection("users").document(user_id).collection("settings").document("main")
            doc = await doc_ref.get()

            if doc.exists:
                data = doc.to_dict()
                logger.info(f"Firestore取得データ: {data}")
                
                # 日時フィールドを適切に変換
                if 'created_at' in data and data['created_at']:
                    data['created_at'] = data['created_at'].replace(tzinfo=timezone.utc) if hasattr(data['created_at'], 'replace') else data['created_at']
                if 'updated_at' in data and data['updated_at']:
                    data['updated_at'] = data['updated_at'].replace(tzinfo=timezone.utc) if hasattr(data['updated_at'], 'replace') else data['updated_at']

                try:
                    return UserSettings(**data)
                except Exception as validation_error:
                    logger.error(f"UserSettings validation error: {validation_error}")
                    logger.error(f"Data keys: {list(data.keys())}")
                    raise
            
            logger.info(f"ユーザー設定が見つかりません: {user_id}")
            return None

        except Exception as e:
            logger.error(f"ユーザー設定取得エラー (user_id: {user_id}): {e}")
            logger.error(f"Error type: {type(e)}")
            raise

    async def create_user_settings(self, user_id: str, settings_data: UserSettingsCreate) -> UserSettings:
        """ユーザー設定を新規作成"""
        try:
            now = datetime.now(timezone.utc)

            # デフォルト値を設定してUserSettingsオブジェクトを作成
            settings = UserSettings(
                school_name=settings_data.school_name,
                class_name=settings_data.class_name,
                teacher_name=settings_data.teacher_name,
                title_templates=settings_data.title_templates or TitleTemplates(),
                ui_preferences=settings_data.ui_preferences or UIPreferences(),
                notification_settings=settings_data.notification_settings or NotificationSettings(),
                workflow_settings=settings_data.workflow_settings or WorkflowSettings(),
                created_at=now,
                updated_at=now
            )

            doc_ref = self.db.collection("users").document(user_id).collection("settings").document("main")

            # Pydanticモデルを辞書に変換してFirestoreに保存
            settings_dict = settings.dict()
            await doc_ref.set(settings_dict)

            logger.info(f"ユーザー設定作成完了 (user_id: {user_id})")
            return settings

        except Exception as e:
            logger.error(f"ユーザー設定作成エラー (user_id: {user_id}): {e}")
            raise

    async def update_user_settings(self, user_id: str, settings_update: UserSettingsUpdate) -> Optional[UserSettings]:
        """ユーザー設定を更新"""
        try:
            doc_ref = self.db.collection("users").document(user_id).collection("settings").document("main")

            # 更新データを準備
            update_data = {}
            for field, value in settings_update.dict(exclude_unset=True).items():
                if value is not None:
                    update_data[field] = value

            update_data['updated_at'] = datetime.now(timezone.utc)

            await doc_ref.update(update_data)

            # 更新後の設定を取得して返す
            updated_settings = await self.get_user_settings(user_id)
            logger.info(f"ユーザー設定更新完了 (user_id: {user_id})")
            return updated_settings

        except Exception as e:
            logger.error(f"ユーザー設定更新エラー (user_id: {user_id}): {e}")
            return None

    async def delete_user_settings(self, user_id: str) -> bool:
        """ユーザー設定を削除"""
        try:
            doc_ref = self.db.collection("users").document(user_id).collection("settings").document("main")
            await doc_ref.delete()
            logger.info(f"ユーザー設定削除完了 (user_id: {user_id})")
            return True

        except Exception as e:
            logger.error(f"ユーザー設定削除エラー (user_id: {user_id}): {e}")
            return False

    async def add_title_template(self, user_id: str, template: TitleTemplate) -> bool:
        """タイトルテンプレートを追加"""
        try:
            settings = await self.get_user_settings(user_id)
            if not settings:
                logger.warning(f"ユーザー設定が見つかりません (user_id: {user_id})")
                return False

            # 新しいテンプレートを追加
            settings.title_templates.custom.append(template)
            settings.updated_at = datetime.now(timezone.utc)

            # 更新を保存
            doc_ref = self.db.collection("users").document(user_id).collection("settings").document("main")
            await doc_ref.update({
                'title_templates': settings.title_templates.dict(),
                'updated_at': settings.updated_at
            })

            logger.info(f"タイトルテンプレート追加完了 (user_id: {user_id}, template: {template.name})")
            return True

        except Exception as e:
            logger.error(f"タイトルテンプレート追加エラー (user_id: {user_id}): {e}")
            return False

    async def remove_title_template(self, user_id: str, template_id: str) -> bool:
        """タイトルテンプレートを削除"""
        try:
            settings = await self.get_user_settings(user_id)
            if not settings:
                return False

            # テンプレートを削除
            original_count = len(settings.title_templates.custom)
            settings.title_templates.custom = [
                t for t in settings.title_templates.custom if t.id != template_id
            ]

            if len(settings.title_templates.custom) == original_count:
                logger.warning(f"削除対象のテンプレートが見つかりません (template_id: {template_id})")
                return False

            settings.updated_at = datetime.now(timezone.utc)

            # 更新を保存
            doc_ref = self.db.collection("users").document(user_id).collection("settings").document("main")
            await doc_ref.update({
                'title_templates': settings.title_templates.dict(),
                'updated_at': settings.updated_at
            })

            logger.info(f"タイトルテンプレート削除完了 (user_id: {user_id}, template_id: {template_id})")
            return True

        except Exception as e:
            logger.error(f"タイトルテンプレート削除エラー (user_id: {user_id}): {e}")
            return False

    async def generate_title_suggestions(self, user_id: str, request: TitleSuggestionRequest) -> List[TitleSuggestion]:
        """タイトル提案を生成"""
        try:
            settings = await self.get_user_settings(user_id)
            suggestions = []

            if settings:
                # メインテンプレートベースの提案
                if settings.title_templates.primary:
                    primary_title = settings.title_templates.primary.replace('○', str(settings.title_templates.current_number))
                    suggestions.append(TitleSuggestion(
                        title=primary_title,
                        confidence=0.9,
                        source="primary_template",
                        template_used=settings.title_templates.primary
                    ))

                # 季節テンプレートベースの提案
                for seasonal in settings.title_templates.seasonal:
                    if request.season and request.season in seasonal.lower():
                        suggestions.append(TitleSuggestion(
                            title=seasonal,
                            confidence=0.8,
                            source="seasonal_template",
                            template_used=seasonal
                        ))

                # カスタムテンプレートベースの提案
                for custom in settings.title_templates.custom:
                    if request.content_hint and request.content_hint.lower() in custom.pattern.lower():
                        suggested_title = custom.pattern.replace('○', str(settings.title_templates.current_number))
                        suggestions.append(TitleSuggestion(
                            title=suggested_title,
                            confidence=0.7,
                            source="custom_template",
                            template_used=custom.pattern
                        ))

            # デフォルト提案
            if not suggestions:
                default_title = f"{datetime.now().month}月号学級通信"
                suggestions.append(TitleSuggestion(
                    title=default_title,
                    confidence=0.5,
                    source="default",
                    template_used=None
                ))

            # 信頼度でソート
            suggestions.sort(key=lambda x: x.confidence, reverse=True)

            logger.info(f"タイトル提案生成完了 (user_id: {user_id}, suggestions: {len(suggestions)})")
            return suggestions[:5]  # 上位5件を返す

        except Exception as e:
            logger.error(f"タイトル提案生成エラー (user_id: {user_id}): {e}")
            return []

    async def update_title_usage(self, user_id: str, title: str) -> bool:
        """使用されたタイトルの統計を更新"""
        try:
            settings = await self.get_user_settings(user_id)
            if not settings:
                return False

            # 号数を自動インクリメント
            if settings.title_templates.auto_numbering:
                settings.title_templates.current_number += 1

            # 使用されたテンプレートの統計を更新
            template_updated = False
            for template in settings.title_templates.custom:
                if template.pattern in title:
                    template.usage_count += 1
                    template.last_used = datetime.now(timezone.utc)
                    template_updated = True
                    break

            if template_updated or settings.title_templates.auto_numbering:
                settings.updated_at = datetime.now(timezone.utc)
                doc_ref = self.db.collection("users").document(user_id).collection("settings").document("main")
                await doc_ref.update({
                    'title_templates': settings.title_templates.dict(),
                    'updated_at': settings.updated_at
                })

            logger.info(f"タイトル使用統計更新完了 (user_id: {user_id}, title: {title})")
            return True

        except Exception as e:
            logger.error(f"タイトル使用統計更新エラー (user_id: {user_id}): {e}")
            return False

    async def validate_settings_completeness(self, user_id: str) -> Dict[str, Any]:
        """設定の完了状況を検証"""
        try:
            settings = await self.get_user_settings(user_id)

            if not settings:
                return {
                    "is_complete": False,
                    "missing_fields": ["all"],
                    "completion_percentage": 0,
                    "suggestions": ["ユーザー設定を作成してください"]
                }

            missing_fields = []
            suggestions = []

            # 必須フィールドのチェック
            if not settings.school_name or len(settings.school_name.strip()) == 0:
                missing_fields.append("school_name")
            if not settings.class_name or len(settings.class_name.strip()) == 0:
                missing_fields.append("class_name")
            if not settings.teacher_name or len(settings.teacher_name.strip()) == 0:
                missing_fields.append("teacher_name")

            # 推奨設定のチェック
            if not settings.title_templates.custom:
                suggestions.append("よく使うタイトルテンプレートを追加することをお勧めします")

            if settings.title_templates.current_number == 1:
                suggestions.append("号数設定を現在の状況に合わせて調整してください")

            completion_percentage = max(0, 100 - (len(missing_fields) * 33))

            return {
                "is_complete": len(missing_fields) == 0,
                "missing_fields": missing_fields,
                "completion_percentage": completion_percentage,
                "suggestions": suggestions
            }

        except Exception as e:
            logger.error(f"設定完了状況検証エラー (user_id: {user_id}): {e}")
            return {
                "is_complete": False,
                "missing_fields": ["validation_error"],
                "completion_percentage": 0,
                "suggestions": ["設定の検証中にエラーが発生しました"]
            }


# シングルトンインスタンス
user_settings_service = UserSettingsService()
