# intersection-backend/app/main.py

import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles  # 정적 파일 서빙
from .db import create_db_and_tables

# 라우터 모듈 불러오기
from .routers import auth as auth_router
from .routers import users as users_router
from .routers import posts as posts_router
from .routers import comments as comments_router
from .routers import friends as friends_router
from .routers import common as common_router  # 파일 업로드 라우터
from .routers import chat as chat_router      # 💬 채팅 라우터
from .routers import moderation as moderation_router  # 🚫 차단/신고 라우터

app = FastAPI(title="Intersection Backend")

# ----------------------------------------------------
# Health Check
# ----------------------------------------------------
@app.get("/health", tags=["health"])
def health_check():
  return {"status": "ok"}

# ----------------------------------------------------
# CORS 설정
#  - 로컬 개발용 도메인들
#  - 배포된 Static Web Apps 도메인
# ----------------------------------------------------
ALLOWED_ORIGINS = [
  # ✅ 배포된 Flutter Web (Azure Static Web Apps)
  "https://jolly-sand-0dcc3e60f.3.azurestaticapps.net",

  # 🔧 필요 시 다른 프론트 도메인도 여기 추가
]

app.add_middleware(
  CORSMiddleware,
  allow_origins=ALLOWED_ORIGINS,                       # 명시 도메인
  allow_origin_regex=r"http://(localhost|127\.0\.0\.1|10\.0\.2\.2)(:\d+)?",  # 로컬용
  allow_credentials=True,
  allow_methods=["*"],
  allow_headers=["*"],
)

# ----------------------------------------------------
# 업로드/정적 파일 설정
# ----------------------------------------------------
UPLOAD_DIR = "uploads"
if not os.path.exists(UPLOAD_DIR):
  os.makedirs(UPLOAD_DIR)

# http://<백엔드>/uploads/... 로 접근 가능
app.mount("/uploads", StaticFiles(directory=UPLOAD_DIR), name="uploads")

# ----------------------------------------------------
# Startup Hook
# ----------------------------------------------------
@app.on_event("startup")
def on_startup():
  create_db_and_tables()

# ----------------------------------------------------
# 기능별 라우터 등록
# ----------------------------------------------------
app.include_router(auth_router.router)
app.include_router(users_router.router)
app.include_router(posts_router.router)
app.include_router(comments_router.router)
app.include_router(friends_router.router)
app.include_router(common_router.router)      # 파일 업로드
app.include_router(chat_router.router)        # 채팅
app.include_router(moderation_router.router)  # 차단/신고

# ----------------------------------------------------
# 루트 엔드포인트
# ----------------------------------------------------
@app.get("/")
def root():
  return {"message": "Intersection backend running"}
