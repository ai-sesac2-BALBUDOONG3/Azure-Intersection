import os
from functools import lru_cache
from typing import List

# ✅ .env 자동 로드 (python-dotenv 없어도 안전하게 패스)
try:
    from dotenv import load_dotenv
    load_dotenv()
except Exception:
    pass


class Settings:
    """Pydantic 없이 환경 변수 기반 설정"""

    def __init__(self):
        # 기본 환경
        self.ENV: str = os.getenv("ENV", "development")

        # JWT 설정
        self.JWT_SECRET: str = os.getenv("JWT_SECRET", "dev-secret-for-local-testing")
        self.ACCESS_TOKEN_EXPIRE_MINUTES: int = int(
            os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "1440")
        )

        # DB 연결
        self.DATABASE_URL: str = os.getenv(
            "DATABASE_URL", "sqlite:///./intersection_dev.db"
        )

        # CORS 허용 도메인
        self.ALLOWED_ORIGINS: str = os.getenv(
            "ALLOWED_ORIGINS",
            "http://localhost:3000,http://localhost:5173,https://jolly-sand-0dcc3e60f.3.azurestaticapps.net",
        )

        # Azure OpenAI
        self.AZURE_OPENAI_ENDPOINT: str = os.getenv("AZURE_OPENAI_ENDPOINT", "")
        self.AZURE_OPENAI_API_KEY: str = os.getenv("AZURE_OPENAI_API_KEY", "")
        self.AZURE_OPENAI_API_VERSION: str = os.getenv(
            "AZURE_OPENAI_API_VERSION", "2024-06-01"
        )
        self.AZURE_OPENAI_CHAT_DEPLOYMENT: str = os.getenv(
            "AZURE_OPENAI_CHAT_DEPLOYMENT", ""
        )
        self.AZURE_OPENAI_EMBEDDING_DEPLOYMENT: str = os.getenv(
            "AZURE_OPENAI_EMBEDDING_DEPLOYMENT", ""
        )

        # Kakao OAuth
        self.KAKAO_CLIENT_ID: str = os.getenv("KAKAO_CLIENT_ID", "")
        self.KAKAO_CLIENT_SECRET: str = os.getenv("KAKAO_CLIENT_SECRET", "")
        self.KAKAO_REDIRECT_URI: str = os.getenv(
            "KAKAO_REDIRECT_URI", "http://127.0.0.1:8000/auth/kakao/callback"
        )

    @property
    def allowed_origins_list(self) -> List[str]:
        """ALLOWED_ORIGINS를 리스트로 변환"""
        return [o.strip() for o in self.ALLOWED_ORIGINS.split(",") if o.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()

# 🔒 운영 환경 검증
if settings.ENV.lower() in {"production", "prod"}:
    if (
        not settings.JWT_SECRET
        or settings.JWT_SECRET == "dev-secret-for-local-testing"
    ):
        raise RuntimeError(
            "⚠️ ENV=production인데 JWT_SECRET이 설정되지 않았습니다. "
            "App Service 환경변수를 확인하세요."
        )
    if settings.DATABASE_URL.startswith("sqlite"):
        raise RuntimeError(
            "⚠️ ENV=production인데 DATABASE_URL이 SQLite입니다. "
            "Azure Database for PostgreSQL 연결 문자열을 설정하세요."
        )
