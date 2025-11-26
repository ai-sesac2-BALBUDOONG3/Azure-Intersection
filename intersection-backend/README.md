# intersection-backend (FastAPI)

학창 시절 친구들과 재연결하는 플랫폼의 백엔드 API 서버

## 🚀 빠른 시작

### 필수 요구사항
- Python 3.12+
- PostgreSQL

### 설치 및 실행

```powershell
# 가상환경 생성
python -m venv .venv

# 가상환경 활성화 (Windows PowerShell)
.\.venv\Scripts\Activate.ps1

# 패키지 설치
pip install -r requirements.txt

# 환경 변수 설정
cp .env.example .env
# .env 파일을 열어서 실제 값으로 수정하세요

# 서버 실행
python -m uvicorn app.main:app --reload --port 8000
```

서버 실행 후: http://127.0.0.1:8000

## 🔐 환경 변수 설정

`.env.example` 파일을 `.env`로 복사하고 다음 값을 입력:

```env
# Kakao OAuth (선택사항 - 개발용 로그인도 가능)
KAKAO_CLIENT_ID=your_kakao_rest_api_key
KAKAO_CLIENT_SECRET=your_kakao_client_secret
KAKAO_REDIRECT_URI=http://localhost:8000/auth/kakao/callback

# JWT Secret (필수 - 강력한 랜덤 문자열로 변경)
JWT_SECRET=your-secure-random-string

# Database (필수)
DATABASE_URL=postgresql+psycopg://postgres:postgres@localhost:5432/intersection
```

⚠️ **주의**: `.env` 파일은 절대 Git에 커밋하지 마세요!

## 🗄️ 데이터베이스

PostgreSQL 데이터베이스가 필요합니다:

```bash
# PostgreSQL 설치 후 데이터베이스 생성
createdb intersection

# 또는 psql로:
psql -U postgres
CREATE DATABASE intersection;
\q
```

테이블은 서버 시작 시 자동으로 생성됩니다.

## 📚 API 문서

서버 실행 후 자동 생성된 API 문서:
- **Swagger UI**: http://127.0.0.1:8000/docs
- **ReDoc**: http://127.0.0.1:8000/redoc

## 🔑 주요 기능

- **사용자 인증**: JWT 기반 로그인/회원가입
- **Kakao OAuth**: 실제 카카오 로그인 + 개발용 모의 로그인
- **커뮤니티**: 게시물 및 댓글 CRUD
- **친구 관리**: 친구 추가, 추천 친구
- **CORS**: 로컬 개발 환경 자동 설정

## 📂 프로젝트 구조

```
intersection-backend/
├── app/
│   ├── main.py           # FastAPI 앱 진입점
│   ├── config.py         # 환경 설정
│   ├── db.py             # 데이터베이스 설정
│   ├── models.py         # SQLModel 데이터 모델
│   ├── schemas.py        # Pydantic 스키마
│   ├── auth.py           # JWT 인증
│   └── routers/          # API 라우터
│       ├── auth.py       # Kakao OAuth
│       ├── users.py      # 사용자 관리
│       ├── posts.py      # 게시물
│       ├── comments.py   # 댓글
│       └── friends.py    # 친구 관리
├── .env.example          # 환경 변수 예시
├── .gitignore
└── requirements.txt      # Python 패키지
```

## 🛠️ 개발

### Hot Reload
`--reload` 플래그로 코드 변경 시 자동 재시작

### 개발용 로그인
카카오 설정 없이 테스트하려면:
- 프론트엔드에서 "카카오로 로그인 (개발용)" 버튼 사용
- 또는 직접 `/auth/kakao/dev_token` 엔드포인트 호출

## 🔒 보안

⚠️ **절대 커밋하면 안 되는 것**:
- `.env` 파일 (실제 키/비밀번호)
- 데이터베이스 백업
- 개인 정보

✅ **gitignore에 포함됨**:
- `.env`
- `.venv/`
- `__pycache__/`
- `*.pyc`
