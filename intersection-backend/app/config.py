# 파일 경로: intersection-backend/app/config.py

try:
    # pydantic v2: BaseSettings는 pydantic-settings로 분리됨
    from pydantic_settings import BaseSettings
except Exception:
    # pydantic v1 호환용 fallback
    from pydantic import BaseSettings


class Settings(BaseSettings):
    # =========================
    # 기본 환경 설정
    # =========================
    # 예: "development", "production", "prod", "staging" 등
    ENV: str = "development"
    
    # =========================
    # Kakao OAuth
    # =========================
    KAKAO_CLIENT_ID: str | None = None
    KAKAO_CLIENT_SECRET: str | None = None
    KAKAO_REDIRECT_URI: str = "http://127.0.0.1:8000/auth/kakao/callback"
    
    # =========================
    # JWT
    # =========================
    # ❗ 여기서는 기본값을 두지 않고, 아래에서 ENV에 따라 강제 처리
    JWT_SECRET: str | None = None
    
    # =========================
    # Database
    # =========================
    # 로컬 기본값 (운영에서는 반드시 .env 또는 App Service 설정으로 override)
    DATABASE_URL: str = "postgresql+psycopg://postgres:postgres@localhost:5432/intersection"
    
    # =========================
    # CORS (프로덕션용)
    # =========================
    # 예: "https://app.example.com,https://admin.example.com"
    # None이면 백엔드 코드에서 별도 기본값 처리
    ALLOWED_ORIGINS: str | None = None

    class Config:
        env_file = ".env"
        # Pydantic v2에서 정의되지 않은 필드가 들어와도 무시
        extra = "ignore"


settings = Settings()

# =========================
# ENV / JWT_SECRET 후처리
# =========================

# 운영 환경으로 취급할 ENV 값들 (필요하면 추가)
_PRODUCTION_ENVS = {"production", "prod"}

env_lower = (settings.ENV or "").lower()

if env_lower in _PRODUCTION_ENVS:
    # 🔒 운영에서는 반드시 강력한 JWT_SECRET이 설정되어 있어야 함
    if not settings.JWT_SECRET or settings.JWT_SECRET == "dev-secret-for-local-testing":
        # 여기서 바로 예외를 발생시켜 서버가 기동되지 않도록 막는다.
        raise RuntimeError(
            "JWT_SECRET must be set to a strong value in production. "
            "현재 ENV=production/prod 이지만 JWT_SECRET이 비어 있거나 "
            "'dev-secret-for-local-testing' 값으로 설정되어 있습니다. "
            "App Service 구성 또는 .env 파일을 확인하세요."
        )
else:
    # 🧪 개발/테스트 환경에서는 JWT_SECRET이 없으면 dev용 시크릿을 자동으로 사용
    if not settings.JWT_SECRET:
        settings.JWT_SECRET = "dev-secret-for-local-testing"
