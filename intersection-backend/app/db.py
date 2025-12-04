# intersection-backend/app/db.py

from sqlmodel import create_engine, SQLModel, Session
from .config import settings

# =====================================================
# 1. DATABASE_URL
#    - .env 또는 Azure App Service 환경변수에서 가져옴
#    - JSONB를 쓰려면 여기 값이 반드시 PostgreSQL 이어야 함
#      예) postgresql+psycopg://balbudoong:%40sesac12@intersection-db.postgres.database.azure.com:5432/intersection_team_db?sslmode=require
# =====================================================
DATABASE_URL = settings.DATABASE_URL

# sqlite 일 때만 check_same_thread 옵션 사용
connect_args = {}
if DATABASE_URL.startswith("sqlite"):
    connect_args = {"check_same_thread": False}

# 엔진 생성
engine = create_engine(
    DATABASE_URL,
    echo=False,
    connect_args=connect_args,
)

def create_db_and_tables() -> None:
    """SQLModel 기준으로 테이블 생성 (이미 있으면 건너뜀)"""
    SQLModel.metadata.create_all(engine)

def get_session():
    """필요시 사용 가능한 Session 의존성"""
    with Session(engine) as session:
        yield session
