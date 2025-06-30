"""
ADKエージェント間で共有されるファイル操作ユーティリティ
ユーザー固有のファイルパス管理とマルチユーザー対応
"""
import os
import json
import logging
from pathlib import Path
from typing import Optional, Dict, Any

logger = logging.getLogger(__name__)

# ADK Artifacts のベースディレクトリ
ADK_ARTIFACTS_BASE = "/tmp/adk_artifacts"

def get_user_artifacts_dir(user_id: str) -> str:
    """
    ユーザー固有のartifactsディレクトリパスを取得
    
    Args:
        user_id: Firebase UID
        
    Returns:
        ユーザー固有のディレクトリパス
    """
    if not user_id or not user_id.strip():
        raise ValueError("user_idが空または無効です")
    
    # ユーザーIDをサニタイズ（セキュリティ対策）
    safe_user_id = "".join(c for c in user_id.strip() if c.isalnum() or c in ['-', '_'])
    if not safe_user_id:
        raise ValueError(f"無効なuser_id: {user_id}")
    
    user_dir = os.path.join(ADK_ARTIFACTS_BASE, safe_user_id)
    
    # ディレクトリが存在しない場合は作成
    os.makedirs(user_dir, exist_ok=True)
    
    logger.info(f"ユーザー固有ディレクトリ: {user_dir}")
    return user_dir

def get_user_outline_path(user_id: str) -> str:
    """
    ユーザー固有のoutline.jsonファイルパスを取得
    
    Args:
        user_id: Firebase UID
        
    Returns:
        outline.jsonの完全パス
    """
    user_dir = get_user_artifacts_dir(user_id)
    return os.path.join(user_dir, "outline.json")

def get_user_newsletter_path(user_id: str) -> str:
    """
    ユーザー固有のnewsletter.htmlファイルパスを取得
    
    Args:
        user_id: Firebase UID
        
    Returns:
        newsletter.htmlの完全パス
    """
    user_dir = get_user_artifacts_dir(user_id)
    return os.path.join(user_dir, "newsletter.html")

def get_user_images_dir(user_id: str) -> str:
    """
    ユーザー固有の画像ディレクトリパスを取得
    
    Args:
        user_id: Firebase UID
        
    Returns:
        画像保存用ディレクトリパス
    """
    user_dir = get_user_artifacts_dir(user_id)
    images_dir = os.path.join(user_dir, "images")
    os.makedirs(images_dir, exist_ok=True)
    return images_dir

def save_user_outline(user_id: str, outline_data: Dict[Any, Any]) -> bool:
    """
    ユーザー固有のoutline.jsonファイルを保存
    
    Args:
        user_id: Firebase UID
        outline_data: 保存する構成案データ
        
    Returns:
        保存成功かどうか
    """
    try:
        outline_path = get_user_outline_path(user_id)
        
        with open(outline_path, 'w', encoding='utf-8') as f:
            json.dump(outline_data, f, ensure_ascii=False, indent=2)
        
        logger.info(f"outline.json保存完了: {outline_path}")
        return True
        
    except Exception as e:
        logger.error(f"outline.json保存エラー: {e}")
        return False

def load_user_outline(user_id: str) -> Optional[Dict[Any, Any]]:
    """
    ユーザー固有のoutline.jsonファイルを読み込み
    
    Args:
        user_id: Firebase UID
        
    Returns:
        構成案データ（存在しない場合はNone）
    """
    try:
        outline_path = get_user_outline_path(user_id)
        
        if not os.path.exists(outline_path):
            logger.warning(f"outline.jsonが存在しません: {outline_path}")
            return None
        
        with open(outline_path, 'r', encoding='utf-8') as f:
            outline_data = json.load(f)
        
        logger.info(f"outline.json読み込み完了: {outline_path}")
        return outline_data
        
    except Exception as e:
        logger.error(f"outline.json読み込みエラー: {e}")
        return None

def save_user_newsletter(user_id: str, html_content: str) -> bool:
    """
    ユーザー固有のnewsletter.htmlファイルを保存
    
    Args:
        user_id: Firebase UID
        html_content: HTMLコンテンツ
        
    Returns:
        保存成功かどうか
    """
    try:
        newsletter_path = get_user_newsletter_path(user_id)
        
        with open(newsletter_path, 'w', encoding='utf-8') as f:
            f.write(html_content)
        
        logger.info(f"newsletter.html保存完了: {newsletter_path}")
        return True
        
    except Exception as e:
        logger.error(f"newsletter.html保存エラー: {e}")
        return False

def load_user_newsletter(user_id: str) -> Optional[str]:
    """
    ユーザー固有のnewsletter.htmlファイルを読み込み
    
    Args:
        user_id: Firebase UID
        
    Returns:
        HTMLコンテンツ（存在しない場合はNone）
    """
    try:
        newsletter_path = get_user_newsletter_path(user_id)
        
        if not os.path.exists(newsletter_path):
            logger.warning(f"newsletter.htmlが存在しません: {newsletter_path}")
            return None
        
        with open(newsletter_path, 'r', encoding='utf-8') as f:
            html_content = f.read()
        
        logger.info(f"newsletter.html読み込み完了: {newsletter_path}")
        return html_content
        
    except Exception as e:
        logger.error(f"newsletter.html読み込みエラー: {e}")
        return None

def get_user_id_from_session(session) -> Optional[str]:
    """
    ADKセッション状態からユーザーIDを安全に取得
    
    Args:
        session: ADKセッションオブジェクト
        
    Returns:
        ユーザーID（取得できない場合はNone）
    """
    try:
        if hasattr(session, 'state') and isinstance(session.state, dict):
            user_id = session.state.get('user_id')
            if user_id and isinstance(user_id, str) and user_id.strip():
                return user_id.strip()
        
        # フォールバック: session.user_id属性も確認
        if hasattr(session, 'user_id') and isinstance(session.user_id, str):
            user_id = session.user_id.strip()
            if user_id:
                return user_id
        
        logger.warning("セッションからuser_idを取得できませんでした")
        return None
        
    except Exception as e:
        logger.error(f"セッションからuser_id取得エラー: {e}")
        return None

def cleanup_user_artifacts(user_id: str) -> bool:
    """
    ユーザーのartifactsディレクトリをクリーンアップ
    
    Args:
        user_id: Firebase UID
        
    Returns:
        クリーンアップ成功かどうか
    """
    try:
        user_dir = get_user_artifacts_dir(user_id)
        
        # outline.jsonとnewsletter.htmlを削除
        for filename in ["outline.json", "newsletter.html"]:
            file_path = os.path.join(user_dir, filename)
            if os.path.exists(file_path):
                os.remove(file_path)
                logger.info(f"ファイル削除: {file_path}")
        
        logger.info(f"ユーザーartifactsクリーンアップ完了: {user_dir}")
        return True
        
    except Exception as e:
        logger.error(f"ユーザーartifactsクリーンアップエラー: {e}")
        return False