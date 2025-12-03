# 파일 경로: intersection-backend/app/auth.py

from datetime import datetime, timedelta
from typing import Optional

from jose import jwt, JWTError
from passlib.context import CryptContext

from .config import settings

# =========================
# JWT 기본 설정
# =========================

# config에서 ENV에 따라 JWT_SECRET을 보장해주므로 여기서는 그대로 사용
SECRET_KEY = settings.JWT_SECRET  # type: ignore[assignment]
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24 * 30  # 30일

if not SECRET_KEY:
    # 이 경우는 사실상 config 쪽 로직이 깨진 상황이므로 방어적으로 한 번 더 체크
    raise RuntimeError(
        "SECRET_KEY(JWT_SECRET)가 설정되지 않았습니다. "
        "config.py에서 ENV/JWT_SECRET 설정을 확인하세요."
    )

# =========================
# 비밀번호 해시/검증 설정
# =========================

pwd_context = CryptContext(
    schemes=["argon2", "bcrypt_sha256", "bcrypt"],
    deprecated="auto",
)


def verify_password(plain_password, hashed_password):
    if hashed_password is None:
        return False

    # bcrypt는 입력 최대 72바이트 제한 → 동일하게 맞춰주기
    try:
        if isinstance(plain_password, str):
            plain_bytes = plain_password.encode("utf-8")
        else:
            plain_bytes = bytes(plain_password)
    except Exception:
        plain_bytes = str(plain_password).encode("utf-8")

    if len(plain_bytes) > 72:
        # 디버깅에 도움이 되도록 서버 로그에 경고 출력
        print(
            "[auth.verify_password] plain_password length >72 bytes, "
            "truncating for verification"
        )
        plain_password = plain_bytes[:72].decode("utf-8", errors="ignore")

    return pwd_context.verify(plain_password, hashed_password)


def get_password_hash(password: str) -> str:
    # bcrypt backend는 비밀번호 최대 72바이트까지 지원 → 초과분은 잘라서 사용
    try:
        if isinstance(password, str):
            password_bytes = password.encode("utf-8")
        else:
            password_bytes = bytes(password)
    except Exception:
        password_bytes = str(password).encode("utf-8")

    if len(password_bytes) > 72:
        print(
            "[auth.get_password_hash] password length >72 bytes, "
            "truncating before hashing"
        )
        password_bytes = password_bytes[:72]

    # passlib은 str 입력을 기대하므로 안전하게 디코딩
    safe_password = password_bytes.decode("utf-8", errors="ignore")
    return pwd_context.hash(safe_password)


def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    to_encode = data.copy()

    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)

    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt


def decode_access_token(token: str) -> Optional[dict]:
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        return payload
    except JWTError:
        return None
