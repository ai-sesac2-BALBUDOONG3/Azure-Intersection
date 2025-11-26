from datetime import datetime, timedelta
from typing import Optional
from jose import jwt, JWTError
from passlib.context import CryptContext
import os

from .config import settings

SECRET_KEY = settings.JWT_SECRET or "dev-secret-for-local-testing"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24 * 30

pwd_context = CryptContext(schemes=["argon2", "bcrypt_sha256", "bcrypt"], deprecated="auto")

def verify_password(plain_password, hashed_password):
    if hashed_password is None:
        return False
    # bcrypt has a 72-byte input limit — make sure we verify using the same truncation
    try:
        if isinstance(plain_password, str):
            plain_bytes = plain_password.encode("utf-8")
        else:
            plain_bytes = bytes(plain_password)
    except Exception:
        plain_bytes = str(plain_password).encode("utf-8")

    if len(plain_bytes) > 72:
        # warn in server logs to help debugging
        print("[auth.verify_password] plain_password length >72 bytes, truncating for verification")
        plain_password = plain_bytes[:72].decode("utf-8", errors="ignore")

    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password):
    # bcrypt backend supports up to 72 bytes of password; truncate to avoid exceptions
    try:
        if isinstance(password, str):
            password_bytes = password.encode("utf-8")
        else:
            password_bytes = bytes(password)
    except Exception:
        password_bytes = str(password).encode("utf-8")

    if len(password_bytes) > 72:
        print("[auth.get_password_hash] password length >72 bytes, truncating before hashing")
        password_bytes = password_bytes[:72]

    # passlib expects str input; decode truncated bytes safely
    safe_password = password_bytes.decode("utf-8", errors="ignore")
    return pwd_context.hash(safe_password)

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

def decode_access_token(token: str):
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        return payload
    except JWTError:
        return None
