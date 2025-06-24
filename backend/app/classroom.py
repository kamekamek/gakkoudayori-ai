from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from backend.agents.tools.classroom_sender import ClassroomSenderTool

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
async def post_announcement(req: ClassroomRequest):
    """
    指定されたGoogle Classroomのコースにアナウンスを投稿します。
    """
    tool = ClassroomSenderTool()
    # ツールの実行メソッドを呼び出す
    result = tool._run(
        course_id=req.course_id,
        title=req.title,
        text=req.text
    )

    if result.get("status") == "error":
        raise HTTPException(
            status_code=500,
            detail=f"Classroomへの投稿に失敗しました: {result.get('message')}"
        )

    return result
