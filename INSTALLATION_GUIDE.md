# 🚀 Intersection 설치 가이드

이 프로젝트를 클론 받아서 사용하기 위한 필수 패키지 및 설정 가이드입니다.

## 📋 필수 요구사항

### 시스템 필수 설치 항목

1. **Python 3.12 이상**
   - 다운로드: https://www.python.org/downloads/
   - 설치 확인: `python --version`

2. **PostgreSQL**
   - 다운로드: https://www.postgresql.org/download/
   - 설치 확인: `psql --version`

3. **Flutter SDK 3.10 이상**
   - 다운로드: https://docs.flutter.dev/get-started/install
   - 설치 확인: `flutter --version`

4. **Git**
   - 다운로드: https://git-scm.com/downloads
   - 설치 확인: `git --version`

### 선택 사항

5. **Android Studio** (Android 앱 개발 시)
   - 다운로드: https://developer.android.com/studio
   - Android SDK 및 에뮬레이터 포함

6. **Xcode** (iOS 앱 개발 시, macOS만)
   - App Store에서 설치

7. **Chrome** (웹 개발 및 테스트)
   - 다운로드: https://www.google.com/chrome/

---

## 📥 프로젝트 클론 및 설치

### 1단계: 저장소 클론

```bash
git clone <repository-url>
cd intersection-integration
```

---

## 🔧 백엔드 설정

### 2단계: Python 가상환경 생성 및 패키지 설치

```powershell
cd intersection-backend

# 가상환경 생성
python -m venv .venv

# 가상환경 활성화
# Windows PowerShell:
.\.venv\Scripts\Activate.ps1

# Windows CMD:
.\.venv\Scripts\activate.bat

# macOS/Linux:
source .venv/bin/activate

# 패키지 설치
pip install -r requirements.txt
```

### 필수 Python 패키지 (requirements.txt)

```
fastapi==0.104.1
uvicorn[standard]==0.24.0
sqlmodel==0.0.14
psycopg[binary]==3.1.13
python-jose[cryptography]==3.3.0
passlib[bcrypt]==1.7.4
python-multipart==0.0.6
python-dotenv==1.0.0
httpx==0.25.1
```

### 3단계: PostgreSQL 데이터베이스 생성

```bash
# PostgreSQL 접속
psql -U postgres

# 데이터베이스 생성
CREATE DATABASE intersection;

# 확인 후 종료
\l
\q
```

또는 간단하게:

```bash
createdb intersection
```

### 4단계: 환경 변수 설정

```powershell
# .env.example을 .env로 복사
cp .env.example .env

# .env 파일을 편집기로 열기
notepad .env
```

`.env` 파일 내용 (실제 값으로 변경):

```env
# Kakao OAuth (선택사항 - 나중에 설정 가능)
KAKAO_CLIENT_ID=your_kakao_rest_api_key_here
KAKAO_CLIENT_SECRET=your_kakao_client_secret_here
KAKAO_REDIRECT_URI=http://localhost:8000/auth/kakao/callback

# JWT Secret (필수 - 반드시 변경!)
JWT_SECRET=your-very-secure-random-string-here-change-this

# Database (필수)
DATABASE_URL=postgresql+psycopg://postgres:postgres@localhost:5432/intersection
```

**💡 팁**: 
- JWT_SECRET은 긴 랜덤 문자열로 설정 (예: `openssl rand -hex 32`)
- Kakao OAuth는 선택사항. 나중에 설정해도 됨 (개발용 로그인 사용 가능)

### 5단계: 백엔드 서버 실행

```powershell
python -m uvicorn app.main:app --reload --port 8000
```

서버 실행 확인: http://127.0.0.1:8000/docs

---

## 🎨 프론트엔드 설정

### 6단계: Flutter 패키지 설치

```bash
cd ../intersection-frontend

# 패키지 설치
flutter pub get
```

### 필수 Flutter 패키지 (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  shared_preferences: ^2.2.2
  flutter_web_auth: ^0.5.0
  file_picker: ^6.1.1
```

### 7단계: 플랫폼별 실행

#### Option A: 웹 브라우저 (Chrome)

```bash
flutter run -d chrome
```

#### Option B: Android 에뮬레이터

```bash
# 에뮬레이터 실행 확인
flutter devices

# 에뮬레이터에서 실행
flutter run -d emulator-5554
```

#### Option C: iOS 시뮬레이터 (macOS만)

```bash
flutter run -d ios
```

---

## ✅ 설치 완료 확인

### 백엔드 확인

1. http://127.0.0.1:8000/docs 접속
2. Swagger UI가 표시되면 성공!

### 프론트엔드 확인

1. 앱이 실행되면 성공!
2. "카카오로 로그인 (개발용)" 버튼 클릭
3. 회원가입 플로우 진행
4. 메인 화면 진입 확인

---

## 🔍 문제 해결

### Python 가상환경 활성화 안 됨 (PowerShell)

```powershell
# PowerShell 실행 정책 변경
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### PostgreSQL 연결 실패

- PostgreSQL 서비스가 실행 중인지 확인
- `.env`의 `DATABASE_URL` 확인 (사용자명/비밀번호)
- 방화벽 설정 확인

### Flutter 실행 오류

```bash
# Flutter Doctor로 문제 확인
flutter doctor

# 문제 해결 후 다시 실행
flutter clean
flutter pub get
flutter run
```

### Android 에뮬레이터 네트워크 에러

- 백엔드가 실행 중인지 확인 (http://127.0.0.1:8000)
- API URL이 자동으로 `10.0.2.2:8000`으로 설정됨 (확인됨)

---

## 📦 전체 설치 요약 (체크리스트)

- [ ] Python 3.12+ 설치
- [ ] PostgreSQL 설치
- [ ] Flutter SDK 설치
- [ ] 프로젝트 클론
- [ ] 백엔드: Python 가상환경 생성
- [ ] 백엔드: pip install -r requirements.txt
- [ ] 백엔드: PostgreSQL 데이터베이스 생성
- [ ] 백엔드: .env 파일 생성 및 설정
- [ ] 백엔드: 서버 실행 확인
- [ ] 프론트엔드: flutter pub get
- [ ] 프론트엔드: flutter run 확인
- [ ] 앱 로그인/회원가입 테스트

---

## 🎉 완료!

모든 설치가 완료되었습니다! 이제 개발을 시작할 수 있습니다.

추가 질문이나 문제가 있으면 README.md를 참고하세요.

