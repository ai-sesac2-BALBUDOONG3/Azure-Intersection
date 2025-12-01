# 🔥 CORS 에러 해결 가이드

## 문제 상황
```
Access to fetch at 'http://127.0.0.1:8000/chat/rooms' from origin 'http://localhost:61367' 
has been blocked by CORS policy: No 'Access-Control-Allow-Origin' header is present 
on the requested resource.
```

## 원인
- 백엔드의 CORS 설정에서 `allow_origin_regex` 패턴이 동적 포트를 제대로 허용하지 못함
- Flutter 웹이 실행될 때마다 다른 포트(예: 61367)를 사용하는데, 정규식이 이를 제대로 매치하지 못함

---

## ✅ 해결 방법

### 방법 1: 간단한 개발 환경 설정 (권장)

**intersection-backend/app/main.py** 파일의 CORS 설정 부분을 수정하세요:

```python
# 기존 코드 (문제 있음)
app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=r"http://(localhost|127\.0\.0\.1|10\.0\.2\.2)(:\d+)?",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

**⬇️ 이렇게 변경 ⬇️**

```python
# 개발 환경용 (모든 출처 허용)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 🔥 모든 출처 허용 (개발 전용)
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

---

### 방법 2: 환경별 설정 (프로덕션 고려)

환경 변수를 사용해서 개발/프로덕션 환경을 구분합니다.

**main.py 수정:**

```python
import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="Intersection Backend")

# 환경 변수로 환경 구분
ENV = os.getenv("ENV", "development")

if ENV == "production":
    # 프로덕션: 특정 도메인만 허용
    ALLOWED_ORIGINS = os.getenv("ALLOWED_ORIGINS", "").split(",")
    app.add_middleware(
        CORSMiddleware,
        allow_origins=ALLOWED_ORIGINS,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
else:
    # 개발: 모든 출처 허용
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
```

**.env 파일 설정:**

```bash
# 개발 환경
ENV=development

# 프로덕션 환경
# ENV=production
# ALLOWED_ORIGINS=https://yourdomain.com,https://www.yourdomain.com
```

---

## 🚀 적용 방법

### 1단계: main.py 수정
위의 코드로 `intersection-backend/app/main.py` 파일을 수정합니다.

### 2단계: 서버 재시작
```bash
cd intersection-backend

# 서버 종료 (Ctrl+C)

# 서버 재시작
python -m uvicorn app.main:app --reload --port 8000
```

### 3단계: 프론트엔드 새로고침
```bash
cd intersection-frontend

# 웹 브라우저 새로고침 (F5)
# 또는 Flutter 앱 재시작
flutter run -d chrome
```

---

## 📝 추가 팁

### CORS 관련 주의사항

1. **개발 환경**
   - `allow_origins=["*"]`로 설정하면 모든 출처에서 접근 가능
   - 빠른 개발에 편리하지만 보안에 취약

2. **프로덕션 환경**
   - 반드시 실제 도메인만 허용해야 함
   - 예: `allow_origins=["https://yourdomain.com"]`

3. **로컬 테스트**
   - Flutter 웹은 매번 다른 포트를 사용할 수 있음
   - 개발 중에는 `["*"]`를 사용하는 것이 편리함

### 디버깅 방법

**브라우저 개발자 도구 (F12) → Network 탭**에서:
1. 실패한 요청을 클릭
2. "Headers" 탭 확인
3. "Response Headers"에 `Access-Control-Allow-Origin`이 있는지 확인

**서버 로그 확인:**
```bash
# 터미널에서 FastAPI 서버 로그 확인
# CORS 관련 에러가 있으면 표시됨
```

---

## 🎯 정리

**간단하게 빠르게 해결하려면:**
```python
# main.py의 CORS 설정을 이렇게만 바꾸세요
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # ← 이것만 바꾸면 됨!
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

서버 재시작하고 브라우저 새로고침하면 끝!

---

## 🔒 프로덕션 배포 시

나중에 실제 서비스를 배포할 때는:

```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "https://yourdomain.com",
        "https://www.yourdomain.com",
        "https://app.yourdomain.com"
    ],  # 실제 도메인만 허용
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

이렇게 변경하세요!
