from googleapiclient.discovery import build
from googleapiclient.errors import HttpError
from google.adk.tools import BaseTool
from pydantic import BaseModel, Field

# 認証は、gcloud auth application-default login やサービスアカウントなど、
# google-api-python-clientが自動で検出する方法に依存します。

class ClassroomSenderTool(BaseTool):
    """
    Google Classroom APIを使用して、指定されたコースにアナウンスを投稿するツール。
    """
    class ClassroomSenderToolSchema(BaseModel):
        course_id: str = Field(..., description="アナウンスを投稿するコースのID。")
        title: str = Field(..., description="アナウンスのタイトル。")
        text: str = Field(..., description="アナウンスの本文。")

    def __init__(self):
        super().__init__(
            name="classroom_sender",
            description="Google Classroomのコースにアナウンスを投稿します。",
            schema=self.ClassroomSenderToolSchema,
        )

    def _run(self, course_id: str, title: str, text: str) -> dict:
        """
        Google Classroomにアナウンスを作成します。
        """
        try:
            # credentials=None とすると、ライブラリは環境から認証情報を探します。
            service = build("classroom", "v1", credentials=None, static_discovery=False)

            announcement_body = {
                'text': f"【学級通信より】{title}\n\n{text}"
            }
            
            created_announcement = service.courses().announcements().create(
                courseId=course_id,
                body=announcement_body
            ).execute()
            
            return {"status": "success", "announcement_id": created_announcement.get("id")}

        except HttpError as error:
            # APIからのエラーレスポンスを処理
            error_details = error.resp.get('content', '{}')
            return {
                "status": "error", 
                "message": f"Classroom APIエラーが発生しました: {error_details}"
            }
        except Exception as e:
            # その他の予期せぬエラー
            return {"status": "error", "message": f"予期せぬエラーが発生しました: {str(e)}"}
