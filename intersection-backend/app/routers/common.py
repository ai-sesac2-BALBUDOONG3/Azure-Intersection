from typing import List  # ✅ [수정] List 임포트 추가
from fastapi import APIRouter, UploadFile, File, Depends, HTTPException
from fastapi.security import OAuth2PasswordBearer
from sqlmodel import Session, select  # ✅ [수정] DB 관련 임포트 추가
import shutil
import os
import uuid
from pathlib import Path

# ✅ JWT 인증 및 DB 엔진, 모델 임포트
from ..auth import decode_access_token
from ..db import engine           # ✅ [수정] engine 임포트 (DB 연결용)
from ..models import Community    # ✅ [수정] Community 모델 임포트

router = APIRouter(tags=["common"])
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/token")

UPLOAD_DIR = "uploads"

# ✅ uploads 폴더 자동 생성
Path(UPLOAD_DIR).mkdir(exist_ok=True)

# ✅ 파일 크기 제한 (10MB)
MAX_FILE_SIZE = 10 * 1024 * 1024

# ✅ 허용된 확장자
ALLOWED_EXTENSIONS = {
    "jpg", "jpeg", "png", "gif", "webp", "bmp",  # 이미지
    "pdf", "doc", "docx", "txt", "hwp",  # 문서
    "zip", "rar", "7z"  # 압축
}


def get_current_user_id(token: str = Depends(oauth2_scheme)) -> int:
    """토큰에서 사용자 ID 추출"""
    payload = decode_access_token(token)
    if payload is None:
        raise HTTPException(status_code=401, detail="Invalid token")
    user_id = payload.get("user_id")
    if not user_id:
        raise HTTPException(status_code=401, detail="Invalid token")
    return user_id


@router.post("/upload")
async def upload_file(
    file: UploadFile = File(...),
    current_user_id: int = Depends(get_current_user_id)
):
    """
    이미지/파일을 업로드하면, 접속 가능한 URL을 반환해주는 API
    """
    
    # ✅ 파일 확장자 확인
    file_ext = os.path.splitext(file.filename)[1].lower().replace(".", "")
    if file_ext not in ALLOWED_EXTENSIONS:
        raise HTTPException(
            status_code=400,
            detail=f"허용되지 않은 파일 형식입니다. 허용: {', '.join(ALLOWED_EXTENSIONS)}"
        )
    
    # ✅ 파일 크기 확인
    file.file.seek(0, 2)
    file_size = file.file.tell()
    file.file.seek(0)
    
    if file_size > MAX_FILE_SIZE:
        raise HTTPException(
            status_code=400,
            detail=f"파일 크기가 너무 큽니다. 최대 {MAX_FILE_SIZE / 1024 / 1024}MB"
        )
    
    # 1. 랜덤 ID 생성
    filename = f"{uuid.uuid4()}.{file_ext}"
    file_location = os.path.join(UPLOAD_DIR, filename)
    
    # 2. 파일 저장
    with open(file_location, "wb") as file_object:
        shutil.copyfileobj(file.file, file_object)
    
    # 3. 반환
    return {
        "success": True,
        "file_url": f"/uploads/{filename}",
        "filename": file.filename,
        "size": file_size,
        "type": file.content_type
    }


# 🏫 학교 이름 자동완성 검색 API (에러 났던 부분 수정됨)
@router.get("/common/search/schools", response_model=List[str])
def search_schools(keyword: str):
    """
    학교 이름 자동완성 검색 API
    """
    if not keyword:
        return []

    # ✅ [수정] engine을 직접 사용하여 세션 생성 (안전한 방식)
    with Session(engine) as session:
        statement = (
            select(Community.school_name)
            .where(Community.school_name.contains(keyword))
            .distinct()
            .limit(10)
        )
        results = session.exec(statement).all()
        return results