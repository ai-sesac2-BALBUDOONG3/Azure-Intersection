# Intersection

학창 시절 친구들과 다시 연결되는 소셜 네트워크 플랫폼

## 프로젝트 구조

```
intersection-integration/
├── intersection-backend/    # FastAPI 백엔드
└── intersection-frontend/   # Flutter 프론트엔드
```

## 🚀 빠른 시작

### 필수 요구사항

- **Python 3.12+** (백엔드)
- **Flutter SDK 3.10+** (프론트엔드)
- **PostgreSQL** (데이터베이스)
- **Node.js** (선택사항, 웹 개발 시)

---

## 📦 설치 및 실행

### 1. 저장소 클론

```bash
git clone <repository-url>
cd intersection-integration
```

### 2. 백엔드 설정 및 실행

```powershell
cd intersection-backend

# 가상환경 생성
python -m venv .venv

# 가상환경 활성화 (Windows PowerShell)
.\.venv\Scripts\Activate.ps1

# 또는 (Windows CMD)
.\.venv\Scripts\activate.bat

# 패키지 설치
pip install -r requirements.txt

# 환경 변수 설정 (.env 파일 생성)
cp .env.example .env
# .env 파일을 열어서 실제 값으로 수정하세요

# 데이터베이스 생성 (PostgreSQL)
# psql을 사용하거나 GUI 도구로 'intersection' 데이터베이스 생성

# 서버 실행
python -m uvicorn app.main:app --reload --port 8000
```

**백엔드 서버**: http://127.0.0.1:8000

### 3. 프론트엔드 설정 및 실행

#### 모바일 (Android 에뮬레이터)

```bash
cd intersection-frontend

# 패키지 설치
flutter pub get

# Android 에뮬레이터 실행 (먼저 에뮬레이터를 켜두세요)
adb devices  # 에뮬레이터 확인

# 앱 실행
flutter run -d emulator-5554
```

#### 웹 (Chrome)

```bash
cd intersection-frontend

# 패키지 설치
flutter pub get

# Chrome에서 실행
flutter run -d chrome
```

---

## 🔐 환경 변수 설정

### 백엔드 (.env 파일)

`intersection-backend/.env` 파일을 생성하고 다음 값을 입력:

```env
# Kakao OAuth (선택사항 - 개발용 로그인도 가능)
KAKAO_CLIENT_ID=your_kakao_rest_api_key
KAKAO_CLIENT_SECRET=your_kakao_client_secret
KAKAO_REDIRECT_URI=http://localhost:8000/auth/kakao/callback

# JWT Secret (필수 - 강력한 랜덤 문자열로 변경)
JWT_SECRET=your-secure-random-string-here

# Database (필수)
DATABASE_URL=postgresql+psycopg://postgres:postgres@localhost:5432/intersection
```

### 카카오 OAuth 설정 (선택사항)

카카오 로그인을 사용하려면:

1. https://developers.kakao.com 접속
2. 애플리케이션 생성
3. **앱 설정 → 플랫폼 → Web 플랫폼 등록**
   - 사이트 도메인: `http://localhost:8000`
4. **Redirect URI 등록**:
   - `http://localhost:8000/auth/kakao/callback`
5. **카카오 로그인 활성화**: ON
6. **동의항목 설정**: 닉네임 (선택 동의)
7. REST API 키를 `.env` 파일에 입력

💡 **개발용 로그인**: 카카오 설정 없이 "카카오로 로그인 (개발용)" 버튼으로 테스트 가능!

---

## 🗄️ 데이터베이스 설정

### PostgreSQL 설치 및 설정

```bash
# PostgreSQL 설치 후 데이터베이스 생성
createdb intersection

# 또는 psql로:
psql -U postgres
CREATE DATABASE intersection;
\q
```

데이터베이스 테이블은 앱 시작 시 자동으로 생성됩니다.

---

## 📱 플랫폼별 API 설정

프론트엔드는 플랫폼에 따라 자동으로 올바른 API URL을 사용합니다:

- **웹**: `http://127.0.0.1:8000`
- **Android 에뮬레이터**: `http://10.0.2.2:8000`

설정 파일: `intersection-frontend/lib/config/api_config.dart`

---

## 🛠️ 개발

### Hot Reload

- **프론트엔드**: 터미널에서 `r` 키 입력
- **백엔드**: `--reload` 플래그로 자동 재로드

### API 문서

백엔드 실행 후:
- Swagger UI: http://127.0.0.1:8000/docs
- ReDoc: http://127.0.0.1:8000/redoc

---

## 📂 프로젝트 구조

### 백엔드 (FastAPI)

```
intersection-backend/
├── app/
│   ├── main.py           # FastAPI 앱 진입점
│   ├── config.py         # 환경 설정
│   ├── db.py             # 데이터베이스 설정
│   ├── models.py         # SQLModel 모델
│   ├── schemas.py        # Pydantic 스키마
│   ├── auth.py           # JWT 인증 헬퍼
│   └── routers/          # API 라우터
│       ├── auth.py       # 카카오 OAuth
│       ├── users.py      # 사용자 관리
│       ├── posts.py      # 게시물
│       ├── comments.py   # 댓글
│       └── friends.py    # 친구 관리
├── .env.example          # 환경 변수 예시
└── requirements.txt      # Python 패키지
```

### 프론트엔드 (Flutter)

```
intersection-frontend/
├── lib/
│   ├── main.dart
│   ├── config/           # 앱 설정
│   ├── data/             # 상태 관리
│   ├── models/           # 데이터 모델
│   ├── services/         # API 서비스
│   ├── screens/          # UI 화면
│   │   ├── auth/         # 로그인/회원가입
│   │   ├── signup/       # 회원가입 단계
│   │   ├── profile/      # 프로필
│   │   ├── friends/      # 친구
│   │   ├── community/    # 커뮤니티
│   │   ├── chat/         # 채팅
│   │   └── common/       # 공통 컴포넌트
│   └── widgets/          # 재사용 가능한 위젯
└── pubspec.yaml          # Flutter 패키지
```

---

## 🧪 테스트

### 회원가입 테스트

1. 웹 또는 앱에서 "회원가입" 클릭
2. 폰 번호 입력 (테스트: 아무 번호나 입력)
3. 인증번호 입력 (테스트: `123456`)
4. 이름, 생년월일, 성별, 지역 입력
5. 학교 정보 입력
6. 제출 → 자동 로그인 완료!

### 로그인 방법

1. **일반 로그인**: 이메일/비밀번호
2. **카카오 로그인**: 실제 카카오 OAuth
3. **개발용 로그인**: 카카오 설정 없이 즉시 로그인

---

## 🔒 보안 주의사항

⚠️ **절대 커밋하면 안 되는 것들**:

- `intersection-backend/.env` (실제 키/비밀번호)
- 데이터베이스 백업 파일
- 개인 정보가 담긴 파일

✅ **gitignore에 추가됨**:
- `.env` 파일
- `.venv/` 가상환경
- `__pycache__/` Python 캐시
- `build/` 빌드 파일

---

## 🐛 문제 해결

### CORS 에러
- 백엔드가 실행 중인지 확인
- CORS 설정이 올바른지 확인 (자동으로 localhost 허용됨)

### 422 Unprocessable Entity
- 요청 데이터 형식 확인
- 백엔드 스키마와 프론트엔드 요청이 일치하는지 확인

### Not authenticated
- 로그인했는지 확인
- 토큰이 올바르게 저장/로드되는지 확인

### Android 에뮬레이터에서 네트워크 에러
- `AndroidManifest.xml`에 인터넷 권한 확인 (이미 추가됨)
- API URL이 `10.0.2.2:8000`인지 확인 (자동 설정됨)

---

## 📝 주요 기능

- ✅ 회원가입 / 로그인
- ✅ 카카오 OAuth (실제 + 개발용)
- ✅ JWT 기반 인증
- ✅ 친구 추천 및 관리
- ✅ 커뮤니티 게시물/댓글
- ✅ 자동 로그인 (토큰 저장)
- ✅ 멀티 플랫폼 (Web, Android, iOS)

---

## 📄 라이선스

이 프로젝트는 개발 중입니다.

---

## 👥 기여

이 프로젝트는 학창 시절 친구들과 재연결하는 것을 목표로 합니다.

