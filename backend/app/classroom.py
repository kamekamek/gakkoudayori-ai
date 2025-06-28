
from fastapi import APIRouter, Depends, HTTPException
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError
from pydantic import BaseModel

from services.google_auth import get_credentials

router = APIRouter(
    prefix="/classroom",
    tags=["Google Classroom"],
)

class ClassroomRequest(BaseModel):
    course_id: str
    title: str
    text: str

@router.post(
    "/",
    summary="Google Classroomへアナウンスを投稿",
    response_description="投稿結果"
)
async def post_announcement(
    req: ClassroomRequest,
    creds = Depends(get_credentials)
):
    """
    指定されたGoogle Classroomのコースにアナウンスを投稿します。
    """
    try:
        service = build('classroom', 'v1', credentials=creds)
        announcement = {
            'text': f"【{req.title}】\n\n{req.text}",
        }
        post = service.courses().announcements().create(
            courseId=req.course_id,
            body=announcement
        ).execute()
        return {
            "status": "success",
            "message": "アナウンスが正常に投稿されました。",
            "course_id": post.get('courseId'),
            "announcement_id": post.get('id'),
            "link": post.get('alternateLink')
        }
    except HttpError as error:
        raise HTTPException(
            status_code=error.resp.status,
            detail=f"Classroomへの投稿中にエラーが発生しました: {error.reason}"
        )
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"予期せぬエラーが発生しました: {str(e)}"
        )
