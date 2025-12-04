# app/main.py

import os
import logging
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from .db import create_db_and_tables
from .config import settings

# 라우터 모듈
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

# -----------------------------------------
# 기본 설정
# -----------------------------------------
app = FastAPI(title="Intersection Backend")
logger = logging.getLogger("uvicorn.error")

# -----------------------------------------
# ✅ CORS 설정
# -----------------------------------------
allowed_origins = []

# 1️⃣ 운영환경이면 .env 또는 Azure App Service 환경변수 사용
if settings.ENV.lower() == "production" and settings.ALLOWED_ORIGINS:
    allowed_origins = [origin.strip() for origin in settings.ALLOWED_ORIGINS.split(",")]
# 2️⃣ 환경변수가 없으면 기본값 설정
else:
    allowed_origins = [
        "http://localhost:3000",
        "http://localhost:5173",
        "https://jolly-sand-0dcc3e60f.3.azurestaticapps.net",
    ]

app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# -----------------------------------------
# 파일 업로드 디렉토리
# -----------------------------------------
UPLOAD_DIR = "uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)
app.mount("/static", StaticFiles(directory=UPLOAD_DIR), name="static")

# -----------------------------------------
# Startup 이벤트: DB 초기화
# -----------------------------------------
@app.on_event("startup")
def on_startup():
    try:
        create_db_and_tables()
        logger.info("✅ Database initialized successfully.")
    except Exception as e:
        logger.error(f"⚠️ Database initialization skipped or failed: {e}")

# -----------------------------------------
# 라우터 등록
# -----------------------------------------
try:
    app.include_router(auth_router.router)
    app.include_router(users_router.router)
    app.include_router(posts_router.router)
    app.include_router(comments_router.router)
    app.include_router(friends_router.router)
    app.include_router(common_router.router)
    app.include_router(chat_router.router)
    app.include_router(moderation_router.router)
except Exception as e:
    logger.error(f"🚫 Router import failed: {e}")

# -----------------------------------------
# 헬스체크
# -----------------------------------------
@app.get("/")
def root():
    return {
        "message": "Intersection backend running",
        "env": settings.ENV,
        "allowed_origins": allowed_origins,
    }
