# 카카오 로그인 빠른 설정 (이메일 없이)

## ✅ 이메일 동의항목 없이 작동하도록 수정 완료!

백엔드가 카카오 ID만으로도 작동하도록 수정되었습니다.
이메일이 제공되지 않아도 `kakao:{카카오_ID}` 형식으로 사용자를 생성합니다.

## 🔧 카카오 개발자 콘솔 최소 설정

### 1. Web 플랫폼 등록
**앱 설정 → 플랫폼 → Web 플랫폼 등록**
```
사이트 도메인:
- http://localhost:8000
- http://127.0.0.1:8000
- https://692d00b9ee2a.ngrok-free.app
```

### 2. Redirect URI 등록
**앱 설정 → 플랫폼 → Web → Redirect URI**
```
✅ http://localhost:8000/auth/kakao/callback
✅ http://127.0.0.1:8000/auth/kakao/callback
✅ https://692d00b9ee2a.ngrok-free.app/auth/kakao/callback
```

⚠️ **중요**: 반드시 포트 번호 `:8000` 포함!

### 3. 카카오 로그인 활성화
**카카오 로그인 메뉴**
```
활성화 설정: ON
```

### 4. 동의 항목 설정 (최소)
**카카오 로그인 → 동의항목**
```
✅ 닉네임: 선택 동의
✅ 프로필 사진: 선택 동의
❌ 카카오계정(이메일): 비활성화되어 있어도 OK!
```

### 5. 앱 키 확인
**앱 설정 → 앱 키**
```
REST API 키 복사 → .env 파일의 KAKAO_CLIENT_ID에 입력
```

### 6. Client Secret (선택사항)
**앱 설정 → 보안**
```
Client Secret: 활성화 (권장)
코드 복사 → .env 파일의 KAKAO_CLIENT_SECRET에 입력
```

## 📝 .env 파일 확인

```env
KAKAO_CLIENT_ID=your_rest_api_key_here
KAKAO_CLIENT_SECRET=your_client_secret_here (없으면 비워두기)
KAKAO_REDIRECT_URI=https://692d00b9ee2a.ngrok-free.app/auth/kakao/callback
```

## 🚀 백엔드 재시작

```bash
cd intersection-backend
.\.venv\Scripts\Activate.ps1
python -m uvicorn app.main:app --reload --port 8000
```

## ✅ 체크리스트

```
□ Web 플랫폼 등록 (포트 포함!)
□ Redirect URI 등록 (포트 포함!)
□ 카카오 로그인 활성화
□ 닉네임 동의항목 설정
□ REST API 키 복사 → .env 파일
□ 백엔드 재시작
□ 테스트!
```

## 💡 작동 방식

### 이메일이 있는 경우:
- login_id: `kakao:{카카오_ID}`
- email: 사용자 이메일
- nickname: 카카오 닉네임

### 이메일이 없는 경우 (현재 상황):
- login_id: `kakao:{카카오_ID}`
- email: null
- nickname: 카카오 닉네임 또는 `카카오사용자{ID마지막4자리}`

둘 다 정상 작동합니다! 🎉

