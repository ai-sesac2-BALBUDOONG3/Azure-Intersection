try:
    # pydantic v2 moved BaseSettings into pydantic-settings package
    from pydantic_settings import BaseSettings
except Exception:
    # fallback for environments with older pydantic that still expose BaseSettings
    from pydantic import BaseSettings


class Settings(BaseSettings):
    KAKAO_CLIENT_ID: str | None = None
    KAKAO_CLIENT_SECRET: str | None = None
    KAKAO_REDIRECT_URI: str = "http://127.0.0.1:8000/auth/kakao/callback"
    JWT_SECRET: str = "dev-secret-for-local-testing"
    # Default development DB is PostgreSQL. Adjust this value to your local Postgres instance.
    # Example: postgresql+psycopg://postgres:postgres@localhost:5432/intersection
    DATABASE_URL: str = "postgresql+psycopg://postgres:@sesac12@localhost:5432/inter_section"

    class Config:
        env_file = ".env"


settings = Settings()
