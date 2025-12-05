# 파일 경로: intersection-backend/app/main.py

import os
import logging
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from .db import create_db_and_tables
from .config import settings

# 라우터
from .routers import (
    auth as auth_router,
    users as users_router,
    posts as posts_router,
    comments as comments_router,
    friends as friends_router,
    common as common_router,
    chat as chat_router,
    moderation as moderation_router,
)

app = FastAPI(title="Intersection Backend")
logger = logging.getLogger("uvicorn.error")

# ✅ CORS 설정
origins = settings.allowed_origins_list

# ALLOWED_ORIGINS가 비어 있거나 파싱 실패했을 때를 위한 안전장치
if not origins:
    logger.warning(
        "ALLOWED_ORIGINS is empty or invalid. "
        "Temporarily allowing all origins for CORS."
    )
    origins = ["*"]

logger.info(f"✅ CORS allowed_origins: {origins}")

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,          # 🔥 리스트 형태로 전달
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ✅ 파일 업로드 디렉토리
UPLOAD_DIR = "uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)
app.mount("/static", StaticFiles(directory=UPLOAD_DIR), name="static")


# ✅ Startup: DB 생성
@app.on_event("startup")
def on_startup():
    try:
        create_db_and_tables()
        logger.info("✅ Database initialized successfully.")
    except Exception as e:
        logger.error(f"⚠️ Database init skipped or failed: {e}")


# ✅ 라우터 등록
for router in [
    auth_router.router,
    users_router.router,
    posts_router.router,
    comments_router.router,
    friends_router.router,
    common_router.router,
    chat_router.router,
    moderation_router.router,
]:
    app.include_router(router)


# ✅ 헬스체크
@app.get("/")
def root():
    return {
        "message": "Intersection backend running",
        "env": settings.ENV,
        "allowed_origins": settings.allowed_origins_list,
    }
