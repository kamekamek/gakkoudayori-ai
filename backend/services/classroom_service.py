"""
Google Classroom API 統合サービス
学級通信の自動投稿・生徒通知機能
"""
from typing import List, Optional, Dict, Any
from dataclasses import dataclass
from datetime import datetime
import tempfile
import os

try:
    from google.oauth2 import service_account
    from googleapiclient.discovery import build
    from googleapiclient.http import MediaFileUpload, MediaIoBaseUpload
    from googleapiclient.errors import HttpError
    import io
    GOOGLE_API_AVAILABLE = True
except ImportError:
    GOOGLE_API_AVAILABLE = False


@dataclass
class ClassroomPostResult:
    """Classroom投稿結果"""
    success: bool
    post_id: Optional[str] = None
    course_work_id: Optional[str] = None
    error_message: Optional[str] = None
    shared_url: Optional[str] = None


@dataclass
class CourseInfo:
    """コース情報"""
    id: str
    name: str
    description: str
    section: str
    teacher_email: str
    student_count: int
    enrollment_code: Optional[str] = None


class ClassroomService:
    """Google Classroom APIサービス"""
    
    def __init__(self, credentials_path: Optional[str] = None):
        """
        初期化
        
        Args:
            credentials_path: サービスアカウント認証情報のパス
        """
        if not GOOGLE_API_AVAILABLE:
            raise ImportError("Google API Client libraries are not installed")
        
        self.credentials_path = credentials_path
        self.service = None
        self._initialize_service()
    
    def _initialize_service(self):
        """Classroom APIサービスを初期化"""
        try:
            if self.credentials_path and os.path.exists(self.credentials_path):
                credentials = service_account.Credentials.from_service_account_file(
                    self.credentials_path,
                    scopes=[
                        'https://www.googleapis.com/auth/classroom.courses.readonly',
                        'https://www.googleapis.com/auth/classroom.coursework.students',
                        'https://www.googleapis.com/auth/classroom.announcements',
                        'https://www.googleapis.com/auth/drive.file'
                    ]
                )
                self.service = build('classroom', 'v1', credentials=credentials)
            else:
                print("Classroom API credentials not found - running in mock mode")
                
        except Exception as e:
            print(f"Classroom API initialization error: {e}")
    
    def get_courses(self, teacher_email: Optional[str] = None) -> List[CourseInfo]:
        """
        教師のコース一覧を取得
        
        Args:
            teacher_email: 教師のメールアドレス（省略時は全てのコース）
        
        Returns:
            List[CourseInfo]: コース情報リスト
        """
        if not self.service:
            return []
        
        try:
            courses = []
            page_token = None
            
            while True:
                request = self.service.courses().list(
                    teacherId=teacher_email,
                    pageToken=page_token,
                    pageSize=100
                )
                
                response = request.execute()
                
                for course in response.get('courses', []):
                    # 学生数を取得
                    student_count = self._get_student_count(course['id'])
                    
                    course_info = CourseInfo(
                        id=course['id'],
                        name=course['name'],
                        description=course.get('description', ''),
                        section=course.get('section', ''),
                        teacher_email=teacher_email or '',
                        student_count=student_count,
                        enrollment_code=course.get('enrollmentCode')
                    )
                    courses.append(course_info)
                
                page_token = response.get('nextPageToken')
                if not page_token:
                    break
            
            return courses
            
        except HttpError as e:
            print(f"Error getting courses: {e}")
            return []
    
    def _get_student_count(self, course_id: str) -> int:
        """コースの学生数を取得"""
        try:
            if not self.service:
                return 0
            
            students = self.service.courses().students().list(
                courseId=course_id
            ).execute()
            
            return len(students.get('students', []))
            
        except HttpError as e:
            print(f"Error getting student count: {e}")
            return 0
    
    def post_announcement(
        self,
        course_id: str,
        title: str,
        content: str,
        attachments: Optional[List[Dict[str, Any]]] = None
    ) -> ClassroomPostResult:
        """
        お知らせを投稿
        
        Args:
            course_id: コースID
            title: タイトル
            content: 内容
            attachments: 添付ファイル
        
        Returns:
            ClassroomPostResult: 投稿結果
        """
        if not self.service:
            return ClassroomPostResult(
                success=False,
                error_message="Classroom API service not available"
            )
        
        try:
            announcement_body = {
                'text': content,
                'state': 'PUBLISHED'
            }
            
            # 添付ファイルがある場合
            if attachments:
                announcement_body['materials'] = []
                for attachment in attachments:
                    if attachment.get('type') == 'drive_file':
                        announcement_body['materials'].append({
                            'driveFile': {
                                'driveFile': {
                                    'id': attachment['file_id'],
                                    'title': attachment['title']
                                },
                                'shareMode': 'VIEW'
                            }
                        })
            
            announcement = self.service.courses().announcements().create(
                courseId=course_id,
                body=announcement_body
            ).execute()
            
            return ClassroomPostResult(
                success=True,
                post_id=announcement['id'],
                shared_url=announcement.get('alternateLink')
            )
            
        except HttpError as e:
            return ClassroomPostResult(
                success=False,
                error_message=f"Classroom announcement error: {str(e)}"
            )
    
    def post_coursework(
        self,
        course_id: str,
        title: str,
        description: str,
        pdf_file_id: Optional[str] = None,
        due_date: Optional[datetime] = None
    ) -> ClassroomPostResult:
        """
        課題を投稿
        
        Args:
            course_id: コースID
            title: タイトル
            description: 説明
            pdf_file_id: PDFファイルのGoogle Drive ID
            due_date: 提出期限
        
        Returns:
            ClassroomPostResult: 投稿結果
        """
        if not self.service:
            return ClassroomPostResult(
                success=False,
                error_message="Classroom API service not available"
            )
        
        try:
            coursework_body = {
                'title': title,
                'description': description,
                'state': 'PUBLISHED',
                'workType': 'ASSIGNMENT'
            }
            
            # 提出期限設定
            if due_date:
                coursework_body['dueDate'] = {
                    'year': due_date.year,
                    'month': due_date.month,
                    'day': due_date.day
                }
                coursework_body['dueTime'] = {
                    'hours': due_date.hour,
                    'minutes': due_date.minute
                }
            
            # PDF添付
            if pdf_file_id:
                coursework_body['materials'] = [{
                    'driveFile': {
                        'driveFile': {
                            'id': pdf_file_id,
                            'title': f"{title}.pdf"
                        },
                        'shareMode': 'VIEW'
                    }
                }]
            
            coursework = self.service.courses().courseWork().create(
                courseId=course_id,
                body=coursework_body
            ).execute()
            
            return ClassroomPostResult(
                success=True,
                course_work_id=coursework['id'],
                shared_url=coursework.get('alternateLink')
            )
            
        except HttpError as e:
            return ClassroomPostResult(
                success=False,
                error_message=f"Classroom coursework error: {str(e)}"
            )
    
    def upload_pdf_to_drive(
        self,
        pdf_data: bytes,
        filename: str,
        folder_id: Optional[str] = None
    ) -> Optional[str]:
        """
        PDFをGoogle Driveにアップロード
        
        Args:
            pdf_data: PDFデータ
            filename: ファイル名
            folder_id: アップロード先フォルダID
        
        Returns:
            str: アップロードされたファイルのID
        """
        try:
            # Drive APIサービス構築
            drive_service = build('drive', 'v3', credentials=self.service._http.credentials)
            
            file_metadata = {
                'name': filename,
                'parents': [folder_id] if folder_id else []
            }
            
            media = MediaIoBaseUpload(
                io.BytesIO(pdf_data),
                mimetype='application/pdf',
                resumable=True
            )
            
            file = drive_service.files().create(
                body=file_metadata,
                media_body=media,
                fields='id'
            ).execute()
            
            # ファイルを公開可能に設定
            drive_service.permissions().create(
                fileId=file['id'],
                body={
                    'role': 'reader',
                    'type': 'anyone'
                }
            ).execute()
            
            return file['id']
            
        except Exception as e:
            print(f"Drive upload error: {e}")
            return None
    
    def post_newsletter_to_classroom(
        self,
        course_id: str,
        title: str,
        content: str,
        pdf_data: bytes,
        teacher_name: str,
        class_name: str
    ) -> ClassroomPostResult:
        """
        学級通信をClassroomに投稿
        
        Args:
            course_id: コースID
            title: タイトル
            content: HTML内容（テキスト化される）
            pdf_data: PDFデータ
            teacher_name: 先生名
            class_name: クラス名
        
        Returns:
            ClassroomPostResult: 投稿結果
        """
        try:
            # HTMLタグを除去してテキスト化
            import re
            clean_content = re.sub('<[^<]+?>', '', content)
            clean_content = re.sub(r'\s+', ' ', clean_content).strip()
            
            # PDFをDriveにアップロード
            pdf_filename = f"{title}_{datetime.now().strftime('%Y%m%d')}.pdf"
            pdf_file_id = self.upload_pdf_to_drive(pdf_data, pdf_filename)
            
            if not pdf_file_id:
                return ClassroomPostResult(
                    success=False,
                    error_message="PDF upload to Drive failed"
                )
            
            # Classroomにお知らせとして投稿
            announcement_content = f"""
{class_name} 学級通信

{clean_content}

--- 
{teacher_name}
ゆとり職員室 自動投稿システム
"""
            
            attachment = {
                'type': 'drive_file',
                'file_id': pdf_file_id,
                'title': pdf_filename
            }
            
            result = self.post_announcement(
                course_id=course_id,
                title=title,
                content=announcement_content,
                attachments=[attachment]
            )
            
            return result
            
        except Exception as e:
            return ClassroomPostResult(
                success=False,
                error_message=f"Newsletter posting error: {str(e)}"
            )


# グローバルインスタンス
classroom_service = None

def get_classroom_service(credentials_path: Optional[str] = None) -> Optional[ClassroomService]:
    """Classroom サービスインスタンスを取得"""
    global classroom_service
    
    if classroom_service is None and GOOGLE_API_AVAILABLE:
        try:
            classroom_service = ClassroomService(credentials_path)
        except Exception as e:
            print(f"Classroom service initialization failed: {e}")
            classroom_service = None
    
    return classroom_service