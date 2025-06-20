"""
Classroom統合エージェント - ADKマルチエージェントシステム統合

Google Classroom APIとの連携によるPDF自動投稿・配布を専門化するエージェント
教師のワークフロー完全自動化を実現
"""

import asyncio
import json
import logging
import os
import time
import base64
from typing import Dict, Any, List, Optional, Tuple
from datetime import datetime, timedelta
import mimetypes

# Google ADK imports
try:
    from google.adk.agents import LlmAgent, Agent
    from google.adk.tools import google_search
    from google.adk.orchestration import Sequential, Parallel
    ADK_AVAILABLE = True
except ImportError:
    ADK_AVAILABLE = False
    logging.warning("Google ADK not available, using fallback implementation")

# Google Classroom API imports
try:
    from google.oauth2.credentials import Credentials
    from google.oauth2.service_account import Credentials as ServiceAccountCredentials
    from googleapiclient.discovery import build
    from googleapiclient.errors import HttpError
    from googleapiclient.http import MediaFileUpload, MediaIoBaseUpload
    import io
    CLASSROOM_API_AVAILABLE = True
except ImportError:
    CLASSROOM_API_AVAILABLE = False
    logging.warning("Google Classroom API not available, posting disabled")

# 既存サービス
from gemini_api_service import generate_text

logger = logging.getLogger(__name__)

# Classroom API設定
CLASSROOM_SCOPES = [
    'https://www.googleapis.com/auth/classroom.courses.readonly',
    'https://www.googleapis.com/auth/classroom.coursework.students.readonly',
    'https://www.googleapis.com/auth/classroom.coursework.me',
    'https://www.googleapis.com/auth/classroom.announcements',
    'https://www.googleapis.com/auth/drive.file'
]


# ==============================================================================
# Classroom統合ツール定義
# ==============================================================================

def analyze_classroom_posting_context(
    newsletter_data: Dict[str, Any],
    grade: str,
    posting_type: str = "announcement"
) -> Dict[str, Any]:
    """Classroom投稿のコンテキストを分析し最適な投稿方法を提案するツール"""
    
    try:
        # 基本投稿情報の抽出
        title = newsletter_data.get("main_title", "学級通信")
        issue_date = newsletter_data.get("issue_date", datetime.now().strftime("%Y年%m月%d日"))
        sections = newsletter_data.get("sections", [])
        
        # 投稿タイトルの生成
        posting_title = f"【{grade}】{title} - {issue_date}"
        
        # 投稿説明文の生成
        description_parts = []
        
        # 挨拶文
        description_parts.append("保護者の皆様へ")
        description_parts.append("")
        description_parts.append(f"本日の{title}をお送りいたします。")
        
        # セクション概要の追加
        if sections:
            description_parts.append("")
            description_parts.append("【今回の内容】")
            for section in sections[:3]:  # 最大3つのセクション
                section_title = section.get("title", "")
                if section_title:
                    description_parts.append(f"• {section_title}")
        
        # 締めの文
        description_parts.append("")
        description_parts.append("ご質問やご不明な点がございましたら、お気軽にお声かけください。")
        description_parts.append("今後ともどうぞよろしくお願いいたします。")
        
        posting_description = "\n".join(description_parts)
        
        # 投稿オプションの決定
        posting_options = {
            "title": posting_title,
            "description": posting_description,
            "posting_type": posting_type,
            "allow_comments": True,
            "notify_recipients": True,
            "schedule_post": False,
            "post_immediately": True
        }
        
        # 適切な投稿時間の提案
        suggested_time = _suggest_optimal_posting_time()
        
        # メタデータ
        context_analysis = {
            "content_complexity": _analyze_content_complexity(sections),
            "target_audience": "parents_guardians",
            "urgency_level": _determine_urgency_level(newsletter_data),
            "expected_engagement": _predict_engagement_level(sections),
            "optimal_posting_time": suggested_time
        }
        
        return {
            "success": True,
            "posting_options": posting_options,
            "context_analysis": context_analysis,
            "recommendations": _generate_posting_recommendations(context_analysis)
        }
        
    except Exception as e:
        logger.error(f"Classroom投稿コンテキスト分析エラー: {e}")
        return {
            "success": False,
            "error": str(e),
            "posting_options": {
                "title": f"学級通信 - {datetime.now().strftime('%m月%d日')}",
                "description": "学級通信をお送りいたします。",
                "posting_type": "announcement"
            }
        }


def _suggest_optimal_posting_time() -> Dict[str, Any]:
    """最適な投稿時間の提案"""
    
    now = datetime.now()
    
    # 平日の夕方（17:00-19:00）を推奨
    if now.weekday() < 5:  # 月-金
        if 17 <= now.hour < 19:
            return {
                "immediate": True,
                "reason": "平日夕方の推奨時間帯です"
            }
        elif now.hour < 17:
            suggested_time = now.replace(hour=17, minute=0, second=0)
            return {
                "immediate": False,
                "suggested_datetime": suggested_time.isoformat(),
                "reason": "平日夕方（17:00）の投稿を推奨します"
            }
    
    # その他の時間帯
    return {
        "immediate": True,
        "reason": "現在時刻での投稿が適切です"
    }


def _analyze_content_complexity(sections: List[Dict[str, Any]]) -> str:
    """コンテンツの複雑さを分析"""
    
    if not sections:
        return "simple"
    
    total_length = sum(len(s.get("content", "")) for s in sections)
    section_count = len(sections)
    
    if total_length > 1000 or section_count > 4:
        return "complex"
    elif total_length > 500 or section_count > 2:
        return "moderate"
    else:
        return "simple"


def _determine_urgency_level(newsletter_data: Dict[str, Any]) -> str:
    """緊急度レベルの判定"""
    
    # 緊急キーワードの検出
    urgent_keywords = ["緊急", "重要", "至急", "お知らせ", "変更", "中止"]
    
    content_text = json.dumps(newsletter_data, ensure_ascii=False).lower()
    
    urgent_count = sum(1 for keyword in urgent_keywords if keyword in content_text)
    
    if urgent_count >= 2:
        return "high"
    elif urgent_count >= 1:
        return "medium"
    else:
        return "low"


def _predict_engagement_level(sections: List[Dict[str, Any]]) -> str:
    """エンゲージメントレベルの予測"""
    
    engagement_keywords = ["写真", "画像", "イベント", "運動会", "発表", "作品", "活動"]
    
    engagement_score = 0
    for section in sections:
        content = section.get("content", "").lower()
        engagement_score += sum(1 for keyword in engagement_keywords if keyword in content)
    
    if engagement_score >= 3:
        return "high"
    elif engagement_score >= 1:
        return "medium"
    else:
        return "low"


def _generate_posting_recommendations(context_analysis: Dict[str, Any]) -> List[str]:
    """投稿に関する推奨事項の生成"""
    
    recommendations = []
    
    complexity = context_analysis.get("content_complexity", "simple")
    urgency = context_analysis.get("urgency_level", "low")
    engagement = context_analysis.get("expected_engagement", "medium")
    
    if complexity == "complex":
        recommendations.append("内容が豊富なため、重要なポイントを説明文で強調することを推奨します")
    
    if urgency == "high":
        recommendations.append("緊急性が高い内容のため、即座に投稿し通知を有効にしてください")
    
    if engagement == "high":
        recommendations.append("高いエンゲージメントが期待されるため、コメント機能を有効にしてください")
    
    recommendations.append("投稿後はClassroomの閲覧数やコメントを確認し、必要に応じてフォローアップを行ってください")
    
    return recommendations


def create_classroom_service(credentials_path: str) -> Optional[Any]:
    """Google Classroom APIサービスの作成"""
    
    try:
        if not CLASSROOM_API_AVAILABLE:
            logger.error("Google Classroom API not available")
            return None
        
        # サービスアカウントキーを使用
        credentials = ServiceAccountCredentials.from_service_account_file(
            credentials_path,
            scopes=CLASSROOM_SCOPES
        )
        
        service = build('classroom', 'v1', credentials=credentials)
        logger.info("Classroom APIサービス作成成功")
        return service
        
    except Exception as e:
        logger.error(f"Classroom APIサービス作成エラー: {e}")
        return None


def get_teacher_courses(service: Any, teacher_email: str) -> List[Dict[str, Any]]:
    """教師が担当するコース一覧を取得"""
    
    try:
        # 教師として参加しているコースを取得
        results = service.courses().list(
            teacherId=teacher_email,
            pageSize=50
        ).execute()
        
        courses = results.get('courses', [])
        
        # アクティブなコースのみフィルタリング
        active_courses = [
            course for course in courses
            if course.get('courseState') == 'ACTIVE'
        ]
        
        return active_courses
        
    except HttpError as e:
        logger.error(f"コース取得エラー: {e}")
        return []
    except Exception as e:
        logger.error(f"予期せぬエラー: {e}")
        return []


def upload_pdf_to_drive(
    service: Any,
    pdf_path: str,
    filename: str
) -> Optional[str]:
    """PDFファイルをGoogle Driveにアップロード"""
    
    try:
        # Drive APIサービスの作成
        drive_service = build('drive', 'v3', credentials=service._http.credentials)
        
        # ファイルメタデータ
        file_metadata = {
            'name': filename,
            'parents': []  # 特定のフォルダに保存する場合はフォルダIDを指定
        }
        
        # MIMEタイプの決定
        mime_type = mimetypes.guess_type(pdf_path)[0] or 'application/pdf'
        
        # ファイルアップロード
        media = MediaFileUpload(
            pdf_path,
            mimetype=mime_type,
            resumable=True
        )
        
        file = drive_service.files().create(
            body=file_metadata,
            media_body=media,
            fields='id,webViewLink,webContentLink'
        ).execute()
        
        # ファイルを公開設定に変更（閲覧権限を付与）
        drive_service.permissions().create(
            fileId=file.get('id'),
            body={
                'role': 'reader',
                'type': 'anyone'  # または 'domain' for organization only
            }
        ).execute()
        
        logger.info(f"PDF Driveアップロード成功: {file.get('id')}")
        return file.get('webViewLink')
        
    except Exception as e:
        logger.error(f"PDF Driveアップロードエラー: {e}")
        return None


def post_to_classroom(
    service: Any,
    course_id: str,
    posting_options: Dict[str, Any],
    pdf_drive_link: Optional[str] = None
) -> Dict[str, Any]:
    """Google Classroomに投稿"""
    
    try:
        posting_type = posting_options.get("posting_type", "announcement")
        
        if posting_type == "announcement":
            return _create_announcement(service, course_id, posting_options, pdf_drive_link)
        elif posting_type == "coursework":
            return _create_coursework(service, course_id, posting_options, pdf_drive_link)
        else:
            raise ValueError(f"Unsupported posting type: {posting_type}")
            
    except Exception as e:
        logger.error(f"Classroom投稿エラー: {e}")
        return {
            "success": False,
            "error": str(e)
        }


def _create_announcement(
    service: Any,
    course_id: str,
    posting_options: Dict[str, Any],
    pdf_drive_link: Optional[str] = None
) -> Dict[str, Any]:
    """アナウンスメントの作成"""
    
    try:
        announcement_body = {
            'text': posting_options.get("description", ""),
            'state': 'PUBLISHED'
        }
        
        # PDF添付の追加
        if pdf_drive_link:
            announcement_body['materials'] = [
                {
                    'link': {
                        'url': pdf_drive_link,
                        'title': posting_options.get("title", "学級通信PDF"),
                        'thumbnailUrl': ''
                    }
                }
            ]
        
        # スケジュール投稿の処理
        if posting_options.get("schedule_post", False):
            scheduled_time = posting_options.get("scheduled_datetime")
            if scheduled_time:
                announcement_body['scheduledTime'] = scheduled_time
                announcement_body['state'] = 'DRAFT'
        
        # アナウンスメント作成
        announcement = service.courses().announcements().create(
            courseId=course_id,
            body=announcement_body
        ).execute()
        
        logger.info(f"アナウンスメント作成成功: {announcement.get('id')}")
        
        return {
            "success": True,
            "announcement_id": announcement.get('id'),
            "announcement_url": announcement.get('alternateLink'),
            "posting_type": "announcement",
            "course_id": course_id
        }
        
    except HttpError as e:
        error_msg = f"アナウンスメント作成失敗: {e}"
        logger.error(error_msg)
        return {
            "success": False,
            "error": error_msg
        }


def _create_coursework(
    service: Any,
    course_id: str,
    posting_options: Dict[str, Any],
    pdf_drive_link: Optional[str] = None
) -> Dict[str, Any]:
    """課題（コースワーク）の作成"""
    
    try:
        coursework_body = {
            'title': posting_options.get("title", "学級通信"),
            'description': posting_options.get("description", ""),
            'state': 'PUBLISHED',
            'workType': 'ASSIGNMENT',
            'submissionModificationMode': 'MODIFIABLE_UNTIL_TURNED_IN'
        }
        
        # PDF添付の追加
        if pdf_drive_link:
            coursework_body['materials'] = [
                {
                    'link': {
                        'url': pdf_drive_link,
                        'title': posting_options.get("title", "学級通信PDF")
                    }
                }
            ]
        
        # 期限設定（オプション）
        due_date = posting_options.get("due_date")
        if due_date:
            coursework_body['dueDate'] = due_date
            coursework_body['dueTime'] = posting_options.get("due_time", {"hours": 23, "minutes": 59})
        
        # コースワーク作成
        coursework = service.courses().courseWork().create(
            courseId=course_id,
            body=coursework_body
        ).execute()
        
        logger.info(f"コースワーク作成成功: {coursework.get('id')}")
        
        return {
            "success": True,
            "coursework_id": coursework.get('id'),
            "coursework_url": coursework.get('alternateLink'),
            "posting_type": "coursework",
            "course_id": course_id
        }
        
    except HttpError as e:
        error_msg = f"コースワーク作成失敗: {e}"
        logger.error(error_msg)
        return {
            "success": False,
            "error": error_msg
        }


# ==============================================================================
# Classroom統合エージェント本体
# ==============================================================================

class ClassroomIntegrationAgent:
    """Google Classroom統合専門エージェント - ADK統合対応"""
    
    def __init__(self, project_id: str, credentials_path: str):
        self.project_id = project_id
        self.credentials_path = credentials_path
        self.agent = None
        self.classroom_service = None
        
        if ADK_AVAILABLE:
            self._initialize_adk_agent()
        else:
            logger.warning("ADK not available for ClassroomIntegrationAgent, using fallback mode")
        
        # Classroom APIサービス初期化
        if CLASSROOM_API_AVAILABLE:
            self.classroom_service = create_classroom_service(credentials_path)
    
    def _initialize_adk_agent(self):
        """ADKエージェントの初期化"""
        
        self.agent = LlmAgent(
            model="gemini-2.5-pro-preview-06-05",
            name="classroom_integration_agent",
            description="Google Classroom統合・自動投稿の専門エージェント",
            instruction="""
            あなたはGoogle Classroom統合の専門家です。
            
            専門分野:
            - Google Classroom API活用
            - PDF自動投稿・配布
            - 保護者向けコミュニケーション最適化
            - 投稿タイミングとエンゲージメント分析
            - 教師ワークフローの効率化
            
            責任:
            - 確実なPDF配布の実現
            - 保護者への適切な情報伝達
            - 投稿コンテンツの品質管理
            - セキュリティとプライバシー保護
            
            制約:
            - 教育現場のプライバシー配慮
            - 適切な投稿タイミング遵守
            - Google Classroom利用規約準拠
            - 保護者への配慮と丁寧な説明
            """,
            tools=[
                analyze_classroom_posting_context,
                get_teacher_courses,
                upload_pdf_to_drive,
                post_to_classroom
            ]
        )
    
    async def distribute_newsletter_to_classroom(
        self,
        pdf_path: str,
        newsletter_data: Dict[str, Any],
        classroom_settings: Dict[str, Any]
    ) -> Dict[str, Any]:
        """学級通信のClassroom配布 - ADK統合版"""
        
        start_time = time.time()
        logger.info("Classroom統合エージェント: 学級通信配布開始")
        
        try:
            if not self.classroom_service:
                return {
                    "success": False,
                    "error": "Classroom APIサービスが利用できません",
                    "agent": "classroom_integration_agent"
                }
            
            # Step 1: 投稿コンテキストの分析
            logger.info("Classroom統合エージェント: 投稿コンテキスト分析")
            
            grade = newsletter_data.get("grade", "")
            posting_type = classroom_settings.get("posting_type", "announcement")
            
            context_result = analyze_classroom_posting_context(
                newsletter_data=newsletter_data,
                grade=grade,
                posting_type=posting_type
            )
            
            if not context_result["success"]:
                logger.warning("投稿コンテキスト分析に失敗、デフォルト設定を使用")
            
            posting_options = context_result.get("posting_options", {})
            
            # 設定の上書き適用
            posting_options.update(classroom_settings.get("posting_options", {}))
            
            # Step 2: 対象コースの特定
            logger.info("Classroom統合エージェント: 対象コース特定")
            
            teacher_email = classroom_settings.get("teacher_email")
            target_course_id = classroom_settings.get("course_id")
            
            if not target_course_id and teacher_email:
                # 教師のコース一覧から自動選択
                courses = get_teacher_courses(self.classroom_service, teacher_email)
                
                if not courses:
                    return {
                        "success": False,
                        "error": "対象コースが見つかりません",
                        "agent": "classroom_integration_agent"
                    }
                
                # 学年に基づいてコースを選択
                target_course = self._select_course_by_grade(courses, grade)
                target_course_id = target_course.get("id") if target_course else courses[0]["id"]
            
            if not target_course_id:
                return {
                    "success": False,
                    "error": "投稿先のコースIDが指定されていません",
                    "agent": "classroom_integration_agent"
                }
            
            # Step 3: PDFのDriveアップロード
            logger.info("Classroom統合エージェント: PDF Driveアップロード")
            
            filename = newsletter_data.get("main_title", "学級通信") + ".pdf"
            pdf_drive_link = upload_pdf_to_drive(
                service=self.classroom_service,
                pdf_path=pdf_path,
                filename=filename
            )
            
            if not pdf_drive_link:
                logger.warning("PDF Driveアップロードに失敗、直接投稿を試行")
            
            # Step 4: Classroom投稿実行
            logger.info("Classroom統合エージェント: Classroom投稿実行")
            
            posting_result = post_to_classroom(
                service=self.classroom_service,
                course_id=target_course_id,
                posting_options=posting_options,
                pdf_drive_link=pdf_drive_link
            )
            
            if not posting_result["success"]:
                logger.error(f"Classroom投稿失敗: {posting_result['error']}")
                return {
                    "success": False,
                    "error": posting_result["error"],
                    "agent": "classroom_integration_agent",
                    "processing_time_ms": int((time.time() - start_time) * 1000)
                }
            
            # 処理時間計算
            processing_time = time.time() - start_time
            
            # 結果構築
            result = {
                "success": True,
                "data": {
                    "posting_result": posting_result,
                    "pdf_drive_link": pdf_drive_link,
                    "course_id": target_course_id,
                    "posting_options": posting_options,
                    "context_analysis": context_result.get("context_analysis", {}),
                    "recommendations": context_result.get("recommendations", []),
                    "distribution_summary": {
                        "posting_type": posting_result.get("posting_type"),
                        "post_id": posting_result.get("announcement_id") or posting_result.get("coursework_id"),
                        "post_url": posting_result.get("announcement_url") or posting_result.get("coursework_url"),
                        "pdf_accessible": pdf_drive_link is not None
                    }
                },
                "metadata": {
                    "agent": "classroom_integration_agent",
                    "processing_time_ms": int(processing_time * 1000),
                    "posted_at": datetime.now().isoformat(),
                    "adk_enabled": ADK_AVAILABLE and self.agent is not None,
                    "classroom_api_enabled": CLASSROOM_API_AVAILABLE
                }
            }
            
            logger.info(f"Classroom統合エージェント: 配布完了 ({processing_time:.2f}s)")
            return result
            
        except Exception as e:
            error_msg = f"Classroom統合エージェント: 予期せぬエラー - {str(e)}"
            logger.error(error_msg)
            return {
                "success": False,
                "error": error_msg,
                "agent": "classroom_integration_agent",
                "processing_time_ms": int((time.time() - start_time) * 1000)
            }
    
    def _select_course_by_grade(self, courses: List[Dict[str, Any]], grade: str) -> Optional[Dict[str, Any]]:
        """学年に基づいてコースを選択"""
        
        try:
            # 学年番号の抽出
            grade_number = None
            for char in grade:
                if char.isdigit():
                    grade_number = char
                    break
            
            if not grade_number:
                return None
            
            # コース名に学年番号が含まれるコースを検索
            for course in courses:
                course_name = course.get("name", "").lower()
                if grade_number in course_name or grade.lower() in course_name:
                    return course
            
            return None
            
        except Exception as e:
            logger.error(f"コース選択エラー: {e}")
            return None
    
    async def get_posting_analytics(
        self,
        course_id: str,
        post_id: str,
        post_type: str = "announcement"
    ) -> Dict[str, Any]:
        """投稿の分析情報を取得"""
        
        try:
            if not self.classroom_service:
                return {
                    "success": False,
                    "error": "Classroom APIサービスが利用できません"
                }
            
            # 投稿情報の取得
            if post_type == "announcement":
                post_data = self.classroom_service.courses().announcements().get(
                    courseId=course_id,
                    id=post_id
                ).execute()
            else:
                post_data = self.classroom_service.courses().courseWork().get(
                    courseId=course_id,
                    id=post_id
                ).execute()
            
            # 分析データの構築
            analytics = {
                "post_id": post_id,
                "post_type": post_type,
                "creation_time": post_data.get("creationTime"),
                "update_time": post_data.get("updateTime"),
                "state": post_data.get("state"),
                "view_url": post_data.get("alternateLink")
            }
            
            return {
                "success": True,
                "analytics": analytics
            }
            
        except Exception as e:
            logger.error(f"投稿分析エラー: {e}")
            return {
                "success": False,
                "error": str(e)
            }


# ==============================================================================
# 統合API関数
# ==============================================================================

async def distribute_to_classroom_with_adk(
    pdf_path: str,
    newsletter_data: Dict[str, Any],
    classroom_settings: Dict[str, Any],
    project_id: str,
    credentials_path: str
) -> Dict[str, Any]:
    """
    ADK Classroom統合エージェントを使用した学級通信配布
    
    Args:
        pdf_path: 配布するPDFファイルパス
        newsletter_data: 学級通信データ
        classroom_settings: Classroom設定
        project_id: Google Cloud プロジェクトID
        credentials_path: 認証情報ファイルパス
    
    Returns:
        Dict[str, Any]: 配布結果
    """
    agent = ClassroomIntegrationAgent(project_id, credentials_path)
    
    result = await agent.distribute_newsletter_to_classroom(
        pdf_path=pdf_path,
        newsletter_data=newsletter_data,
        classroom_settings=classroom_settings
    )
    
    return result


# ==============================================================================
# テスト機能
# ==============================================================================

async def test_classroom_integration_agent():
    """Classroom統合エージェントのテスト"""
    
    # テスト用データ
    test_newsletter_data = {
        "main_title": "3年1組 学級通信",
        "grade": "3年1組",
        "issue_date": "2024年06月19日",
        "school_name": "テスト小学校",
        "sections": [
            {
                "type": "main",
                "title": "運動会の練習",
                "content": "今日は運動会の練習をしました。"
            }
        ]
    }
    
    test_classroom_settings = {
        "teacher_email": "teacher@test-school.com",
        "posting_type": "announcement",
        "posting_options": {
            "allow_comments": True,
            "notify_recipients": True
        }
    }
    
    print("=== Classroom統合エージェント テスト ===")
    
    try:
        # PDF配布テスト（模擬）
        fake_pdf_path = "/tmp/test_newsletter.pdf"
        
        result = await distribute_to_classroom_with_adk(
            pdf_path=fake_pdf_path,
            newsletter_data=test_newsletter_data,
            classroom_settings=test_classroom_settings,
            project_id="test-project",
            credentials_path="test-credentials.json"
        )
        
        print("=== Classroom統合エージェント テスト結果 ===")
        print(json.dumps(result, ensure_ascii=False, indent=2))
        
        if result["success"]:
            print("✅ Classroom統合エージェント: テスト成功")
            distribution = result["data"]["distribution_summary"]
            print(f"投稿タイプ: {distribution['posting_type']}")
            print(f"投稿ID: {distribution['post_id']}")
            print(f"PDF利用可能: {distribution['pdf_accessible']}")
        else:
            print("❌ Classroom統合エージェント: テスト失敗")
            print(f"エラー: {result['error']}")
        
        return result
        
    except Exception as e:
        print(f"❌ テストエラー: {e}")
        return {"success": False, "error": str(e)}


if __name__ == "__main__":
    # テスト実行
    asyncio.run(test_classroom_integration_agent())