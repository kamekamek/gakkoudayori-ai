import logging
from typing import List

from fastapi import APIRouter, Depends, HTTPException, status, Header
from fastapi.responses import JSONResponse

from app.auth import User, get_current_user
from services.user_settings_service import UserSettingsService
from models.user_settings import (
    TitleSuggestion,
    TitleSuggestionRequest,
    TitleTemplate,
    UserSettingsCreate,
    UserSettingsResponse,
    UserSettingsUpdate,
)
from services.user_settings_service import user_settings_service

logger = logging.getLogger(__name__)
router = APIRouter()

# テスト用の認証回避エンドポイント（Firebase無効時のテスト用）
@router.get("/users/settings/test", response_model=UserSettingsResponse)
async def get_user_settings_test():
    """ユーザー設定を取得（テスト用・認証不要）"""
    # Firestoreが利用できない場合は固定レスポンスを返す
    return UserSettingsResponse(
        settings=None,
        is_complete=False,
        missing_fields=["school_name", "class_name", "teacher_name"],
        suggestions=["初期設定を完了してください"]
    )


@router.post("/users/settings", response_model=UserSettingsResponse, status_code=status.HTTP_201_CREATED)
async def create_user_settings(
    settings: UserSettingsCreate,
    current_user: User = Depends(get_current_user)
):
    """ユーザー設定を新規作成"""
    try:
        # 既存設定の確認
        existing_settings = await user_settings_service.get_user_settings(current_user.uid)
        if existing_settings:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="ユーザー設定は既に存在します。更新する場合はPUTメソッドを使用してください。"
            )

        # 新規作成
        created_settings = await user_settings_service.create_user_settings(current_user.uid, settings)

        # 完了状況を検証
        validation_result = await user_settings_service.validate_settings_completeness(current_user.uid)

        response = UserSettingsResponse(
            settings=created_settings,
            is_complete=validation_result["is_complete"],
            missing_fields=validation_result["missing_fields"],
            suggestions=validation_result["suggestions"]
        )

        logger.info(f"ユーザー設定作成完了: {current_user.uid}")
        return response

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"ユーザー設定作成エラー: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="ユーザー設定の作成に失敗しました"
        )


@router.get("/users/settings", response_model=UserSettingsResponse)
async def get_user_settings_endpoint(
    x_user_id: str = Header(None, alias="X-User-ID")
):
    """
    現在のユーザーの設定を取得または作成するエンドポイント。
    X-User-IDヘッダーからユーザーIDを取得します。
    """
    # ヘッダーからユーザーIDを取得、なければデフォルト値を使用
    user_id = x_user_id or "temp-fixed-user-id-for-debug"
    
    print(f"⚙️ Getting settings for user: {user_id}")
    try:
        # UserSettingsServiceはシングルトンインスタンスを使用
        logger.info(f"ユーザー設定取得リクエスト: user_id={user_id}")
        settings = await user_settings_service.get_user_settings(user_id)

        if not settings:
            # 設定が存在しない場合、空の応答を返す
            return UserSettingsResponse(
                settings=None,
                is_complete=False,
                missing_fields=["all"],
                suggestions=["初期設定を完了してください"]
            )

        # 完了状況を検証
        validation_result = await user_settings_service.validate_settings_completeness(user_id)

        response = UserSettingsResponse(
            settings=settings,
            is_complete=validation_result["is_complete"],
            missing_fields=validation_result["missing_fields"],
            suggestions=validation_result["suggestions"]
        )

        return response

    except Exception as e:
        logger.error(f"ユーザー設定取得エラー: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="ユーザー設定の取得に失敗しました"
        )


@router.put("/users/settings", response_model=UserSettingsResponse)
async def update_user_settings(
    settings_update: UserSettingsUpdate,
    current_user: User = Depends(get_current_user)
):
    """ユーザー設定を更新"""
    try:
        updated_settings = await user_settings_service.update_user_settings(current_user.uid, settings_update)

        if not updated_settings:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="ユーザー設定が見つかりません"
            )

        # 完了状況を検証
        validation_result = await user_settings_service.validate_settings_completeness(current_user.uid)

        response = UserSettingsResponse(
            settings=updated_settings,
            is_complete=validation_result["is_complete"],
            missing_fields=validation_result["missing_fields"],
            suggestions=validation_result["suggestions"]
        )

        logger.info(f"ユーザー設定更新完了: {current_user.uid}")
        return response

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"ユーザー設定更新エラー: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="ユーザー設定の更新に失敗しました"
        )


@router.delete("/users/settings", status_code=status.HTTP_204_NO_CONTENT)
async def delete_user_settings(current_user: User = Depends(get_current_user)):
    """ユーザー設定を削除"""
    try:
        success = await user_settings_service.delete_user_settings(current_user.uid)

        if not success:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="削除対象のユーザー設定が見つかりません"
            )

        logger.info(f"ユーザー設定削除完了: {current_user.uid}")

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"ユーザー設定削除エラー: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="ユーザー設定の削除に失敗しました"
        )


@router.post("/users/settings/title-templates", status_code=status.HTTP_201_CREATED)
async def add_title_template(
    template: TitleTemplate,
    current_user: User = Depends(get_current_user)
):
    """タイトルテンプレートを追加"""
    try:
        success = await user_settings_service.add_title_template(current_user.uid, template)

        if not success:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="タイトルテンプレートの追加に失敗しました"
            )

        logger.info(f"タイトルテンプレート追加完了: {current_user.uid}, {template.name}")
        return {"message": "タイトルテンプレートが追加されました", "template_id": template.id}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"タイトルテンプレート追加エラー: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="タイトルテンプレートの追加に失敗しました"
        )


@router.delete("/users/settings/title-templates/{template_id}", status_code=status.HTTP_204_NO_CONTENT)
async def remove_title_template(
    template_id: str,
    current_user: User = Depends(get_current_user)
):
    """タイトルテンプレートを削除"""
    try:
        success = await user_settings_service.remove_title_template(current_user.uid, template_id)

        if not success:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="削除対象のタイトルテンプレートが見つかりません"
            )

        logger.info(f"タイトルテンプレート削除完了: {current_user.uid}, {template_id}")

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"タイトルテンプレート削除エラー: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="タイトルテンプレートの削除に失敗しました"
        )


@router.post("/users/settings/title-suggestions", response_model=List[TitleSuggestion])
async def get_title_suggestions(
    request: TitleSuggestionRequest,
    current_user: User = Depends(get_current_user)
):
    """タイトル提案を取得"""
    try:
        suggestions = await user_settings_service.generate_title_suggestions(current_user.uid, request)

        logger.info(f"タイトル提案生成完了: {current_user.uid}, {len(suggestions)}件")
        return suggestions

    except Exception as e:
        logger.error(f"タイトル提案生成エラー: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="タイトル提案の生成に失敗しました"
        )


@router.post("/users/settings/title-usage")
async def update_title_usage(
    title: str,
    current_user: User = Depends(get_current_user)
):
    """タイトル使用統計を更新"""
    try:
        success = await user_settings_service.update_title_usage(current_user.uid, title)

        if not success:
            logger.warning(f"タイトル使用統計更新に失敗: {current_user.uid}, {title}")

        return {"message": "タイトル使用統計が更新されました"}

    except Exception as e:
        logger.error(f"タイトル使用統計更新エラー: {e}")
        # 統計更新の失敗は致命的でないため、警告レベルで処理
        return {"message": "タイトル使用統計の更新をスキップしました"}


@router.get("/users/settings/validation")
async def validate_settings(current_user: User = Depends(get_current_user)):
    """ユーザー設定の完了状況を検証"""
    try:
        validation_result = await user_settings_service.validate_settings_completeness(current_user.uid)
        return validation_result

    except Exception as e:
        logger.error(f"設定検証エラー: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="設定の検証に失敗しました"
        )


@router.get("/users/settings/export")
async def export_user_settings(current_user: User = Depends(get_current_user)):
    """ユーザー設定をエクスポート"""
    try:
        settings = await user_settings_service.get_user_settings(current_user.uid)

        if not settings:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="エクスポート可能な設定が見つかりません"
            )

        # エクスポート用の辞書を作成（機密情報を除外）
        export_data = settings.dict()

        # 不要なメタデータを除外
        export_data.pop('created_at', None)
        export_data.pop('updated_at', None)

        logger.info(f"ユーザー設定エクスポート完了: {current_user.uid}")
        return JSONResponse(content=export_data, headers={
            "Content-Disposition": f"attachment; filename=user_settings_{current_user.uid}.json"
        })

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"設定エクスポートエラー: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="設定のエクスポートに失敗しました"
        )
