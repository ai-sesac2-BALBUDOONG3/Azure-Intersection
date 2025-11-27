# 카카오 로그인 설정 가이드

## 1. 카카오 개발자 콘솔 설정

### Step 1: Web 플랫폼 등록
1. https://developers.kakao.com 접속
2. 내 애플리케이션 선택
3. **앱 설정 → 플랫폼** 메뉴
4. **Web 플랫폼 등록** 클릭
5. 사이트 도메인 등록:
   - `http://localhost:8000`
   - `http://127.0.0.1:8000`
   - `https://692d00b9ee2a.ngrok-free.app` (ngrok 실행 시)

### Step 2: Redirect URI 등록
1. **앱 설정 → 플랫폼** 메뉴에서 Web 선택
2. **Redirect URI** 등록:
   ```
   http://127.0.0.1:8000/auth/kakao/callback
   http://localhost:8000/auth/kakao/callback
   https://692d00b9ee2a.ngrok-free.app/auth/kakao/callback
   ```
   ⚠️ **주의**: `localhost`와 `localhost:8000`은 다릅니다! 포트 필수!

### Step 3: Client Secret 활성화 (권장)
1. **앱 설정 → 보안** 메뉴
2. **Client Secret** 코드 생성
3. **활성화 상태**: ON
4. **코드 복사** (나중에 .env 파일에 사용)

### Step 4: 동의 항목 설정
1. **카카오 로그인 → 동의항목** 메뉴
2. 필수 동의 항목 설정:
   - **닉네임**: 필수 동의
   - **카카오계정(이메일)**: 필수 동의

### Step 5: 앱 키 확인
1. **앱 설정 → 앱 키** 메뉴
2. **REST API 키** 복사

### Step 6: 카카오 로그인 활성화
1. **카카오 로그인** 메뉴
2. **활성화 설정**: ON으로 변경

## 2. .env 파일 설정

`intersection-backend/.env` 파일을 다음과 같이 설정:

```env
# Kakao OAuth Settings
KAKAO_CLIENT_ID=your_rest_api_key_here
KAKAO_CLIENT_SECRET=your_client_secret_here
KAKAO_REDIRECT_URI=https://692d00b9ee2a.ngrok-free.app/auth/kakao/callback

# 로컬 테스트 시에는 이렇게 변경:
# KAKAO_REDIRECT_URI=http://127.0.0.1:8000/auth/kakao/callback

# JWT Secret
JWT_SECRET=dev-secret-for-local-testing

# Database
DATABASE_URL=postgresql+psycopg://postgres:postgres@localhost:5432/intersection
```

## 3. 백엔드 재시작

.env 파일 수정 후 백엔드를 재시작해야 합니다:

```bash
cd intersection-backend
.\.venv\Scripts\Activate.ps1
python -m uvicorn app.main:app --reload --port 8000
```

## 4. 테스트

### 웹에서 테스트:
1. http://localhost:8000/auth/kakao/login 접속
2. 카카오 로그인 페이지로 리다이렉트
3. 로그인 완료 후 콜백 URL로 리다이렉트

### Flutter 앱에서 테스트:
1. "카카오로 로그인" 버튼 클릭
2. 카카오 로그인 진행
3. 앱으로 자동 리다이렉트

## 5. 문제 해결

### 에러: "invalid_client"
- Client Secret이 잘못되었거나 활성화되지 않음
- KAKAO_CLIENT_ID가 REST API 키인지 확인

### 에러: "redirect_uri_mismatch"
- Redirect URI가 카카오 개발자 콘솔에 등록되지 않음
- 포트 번호 확인 (localhost vs localhost:8000)
- .env 파일의 KAKAO_REDIRECT_URI와 일치하는지 확인

### 에러: "unauthorized"
- 카카오 로그인이 활성화되지 않음
- Web 플랫폼이 등록되지 않음

### ngrok URL이 바뀌면?
1. 새 ngrok URL 확인: `curl http://127.0.0.1:4040/api/tunnels`
2. 카카오 개발자 콘솔에서 Redirect URI 업데이트
3. .env 파일의 KAKAO_REDIRECT_URI 업데이트
4. 백엔드 재시작

## 6. 개발용 로그인 (OAuth 없이 테스트)

카카오 OAuth 설정이 번거로우면 개발용 로그인 사용:

```
GET http://127.0.0.1:8000/auth/kakao/dev_token
```

Flutter 앱에서 "카카오로 로그인 (개발용)" 버튼을 사용하세요.

