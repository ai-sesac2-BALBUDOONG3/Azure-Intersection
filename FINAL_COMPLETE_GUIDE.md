# 🎯 파일/이미지 업로드 기능 - 완전 수정 가이드

## 📋 현재 프로젝트 구조 분석 완료

### ✅ 확인된 파일들
- **백엔드:** auth.py (라우터), common.py (업로드), db.py, config.py
- **프론트엔드:** api_config.dart, app_state.dart, user.dart
- **구조:** FastAPI + SQLModel + Flutter

---

## 🔧 수정 필요한 파일 (총 6개)

### 백엔드 (4개)
1. **common.py** - 업로드 API 개선 (인증 추가)
2. **models.py** - ChatMessage에 파일 필드 추가
3. **schemas.py** - 파일 스키마 추가
4. **chat.py** - 파일 메시지 처리

### 프론트엔드 (2개)
5. **api_service.dart** - 업로드 API 메서드 추가
6. **chat_screen.dart** - UI 및 파일 전송 로직 추가

### 설정 파일 (2개)
7. **pubspec.yaml** - 패키지 추가
8. **AndroidManifest.xml / Info.plist** - 권한 추가

---

## 📦 1단계: 패키지 설치 (프론트엔드)

### pubspec.yaml 수정

**파일:** `intersection-frontend/pubspec.yaml`

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # 기존 패키지들...
  http: ^1.1.0
  emoji_picker_flutter: ^2.0.0
  file_picker: ^6.1.1  # 이미 있음
  
  # ✅ 새로 추가
  image_picker: ^1.0.4  # 이미지 선택/촬영
  permission_handler: ^11.0.1  # 권한 처리
```

**설치:**
```bash
cd intersection-frontend
flutter pub get
```

---

## 🔥 2단계: 백엔드 수정

### 📄 2-1. common.py 수정 (인증 추가)

**파일:** `intersection-backend/app/routers/common.py`

**전체 교체:**

```python
from fastapi import APIRouter, UploadFile, File, Depends, HTTPException
from fastapi.security import OAuth2PasswordBearer
import shutil
import os
import uuid
from pathlib import Path

# ✅ JWT 인증 임포트 추가
from ..auth import decode_access_token

router = APIRouter(tags=["common"])
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/token")

UPLOAD_DIR = "uploads"

# ✅ uploads 폴더 자동 생성
Path(UPLOAD_DIR).mkdir(exist_ok=True)

# ✅ 파일 크기 제한 (10MB)
MAX_FILE_SIZE = 10 * 1024 * 1024

# ✅ 허용된 확장자
ALLOWED_EXTENSIONS = {
    "jpg", "jpeg", "png", "gif", "webp", "bmp",  # 이미지
    "pdf", "doc", "docx", "txt", "hwp",  # 문서
    "zip", "rar", "7z"  # 압축
}


def get_current_user_id(token: str = Depends(oauth2_scheme)) -> int:
    """토큰에서 사용자 ID 추출"""
    payload = decode_access_token(token)
    user_id = payload.get("user_id")
    if not user_id:
        raise HTTPException(status_code=401, detail="Invalid token")
    return user_id


@router.post("/upload")
async def upload_file(
    file: UploadFile = File(...),
    current_user_id: int = Depends(get_current_user_id)  # ✅ 인증 추가
):
    """
    이미지/파일을 업로드하면, 접속 가능한 URL을 반환해주는 API
    
    - 인증 필요
    - 파일 크기 제한: 10MB
    - 허용 확장자: 이미지, 문서, 압축 파일
    """
    
    # ✅ 파일 확장자 확인
    file_ext = os.path.splitext(file.filename)[1].lower().replace(".", "")
    if file_ext not in ALLOWED_EXTENSIONS:
        raise HTTPException(
            status_code=400,
            detail=f"허용되지 않은 파일 형식입니다. 허용: {', '.join(ALLOWED_EXTENSIONS)}"
        )
    
    # ✅ 파일 크기 확인
    file.file.seek(0, 2)  # 파일 끝으로 이동
    file_size = file.file.tell()  # 현재 위치 = 파일 크기
    file.file.seek(0)  # 다시 처음으로
    
    if file_size > MAX_FILE_SIZE:
        raise HTTPException(
            status_code=400,
            detail=f"파일 크기가 너무 큽니다. 최대 {MAX_FILE_SIZE / 1024 / 1024}MB"
        )
    
    # 1. 파일 이름이 겹치지 않게 랜덤 ID 생성 (uuid)
    filename = f"{uuid.uuid4()}.{file_ext}"
    file_location = os.path.join(UPLOAD_DIR, filename)
    
    # 2. 서버 디스크에 파일 저장
    with open(file_location, "wb") as file_object:
        shutil.copyfileobj(file.file, file_object)
    
    # 3. ✅ 상세 정보 포함하여 반환
    return {
        "success": True,
        "file_url": f"/uploads/{filename}",
        "filename": file.filename,  # 원본 파일명
        "size": file_size,
        "type": file.content_type
    }
```

---

### 📄 2-2. models.py 수정

**파일:** `intersection-backend/app/models.py`

**ChatMessage 클래스 수정:**

```python
class ChatMessage(SQLModel, table=True):
    """채팅 메시지 모델"""
    id: Optional[int] = Field(default=None, primary_key=True)
    room_id: int = Field(foreign_key="chatroom.id")
    sender_id: int = Field(foreign_key="user.id")
    content: str  # 메시지 내용
    message_type: str = Field(default="normal")  # normal, system, file, image
    is_read: bool = Field(default=False)  # 읽음 여부
    
    # ✅ 파일 업로드 관련 필드 추가 (4개)
    file_url: Optional[str] = None  # 파일 URL
    file_name: Optional[str] = None  # 원본 파일명
    file_size: Optional[int] = None  # 파일 크기 (bytes)
    file_type: Optional[str] = None  # 파일 MIME 타입
    
    created_at: datetime = Field(default_factory=get_kst_now)
```

**위치:** ChatMessage 클래스 찾아서 필드만 추가하세요!

---

### 📄 2-3. schemas.py 수정

**파일:** `intersection-backend/app/schemas.py`

**ChatMessageCreate와 ChatMessageRead 수정:**

```python
class ChatMessageCreate(BaseModel):
    """메시지 전송 요청"""
    content: str
    # ✅ 파일 정보 추가 (선택사항)
    file_url: Optional[str] = None
    file_name: Optional[str] = None
    file_size: Optional[int] = None
    file_type: Optional[str] = None


class ChatMessageRead(BaseModel):
    """메시지 조회 응답"""
    id: int
    room_id: int
    sender_id: int
    content: str
    message_type: str = "normal"
    is_read: bool
    created_at: str
    # ✅ 파일 정보 추가
    file_url: Optional[str] = None
    file_name: Optional[str] = None
    file_size: Optional[int] = None
    file_type: Optional[str] = None
```

---

### 📄 2-4. chat.py 수정

**파일:** `intersection-backend/app/routers/chat.py`

**send_chat_message 함수 수정:**

```python
@router.post("/rooms/{room_id}/messages", response_model=ChatMessageRead)
def send_chat_message(
    room_id: int,
    data: ChatMessageCreate,
    current_user_id: int = Depends(get_current_user_id)
):
    """
    채팅방에 메시지를 전송합니다.
    파일 업로드 지원 - file_url이 있으면 파일 메시지로 전송
    """
    with Session(engine) as session:
        # 채팅방 권한 확인
        room = session.get(ChatRoom, room_id)
        if not room:
            raise HTTPException(status_code=404, detail="Chat room not found")
        
        if room.user1_id != current_user_id and room.user2_id != current_user_id:
            raise HTTPException(status_code=403, detail="Not authorized")
        
        # 나간 채팅방인지 확인
        if room.left_user_id == current_user_id:
            raise HTTPException(status_code=403, detail="나간 채팅방에서는 메시지를 보낼 수 없습니다")
        
        # ✅ 메시지 타입 결정
        message_type = "normal"
        if data.file_url:
            # 파일 타입에 따라 구분
            if data.file_type and data.file_type.startswith("image/"):
                message_type = "image"
            else:
                message_type = "file"
        
        # 메시지 생성
        message = ChatMessage(
            room_id=room_id,
            sender_id=current_user_id,
            content=data.content,
            message_type=message_type,
            # ✅ 파일 정보 저장
            file_url=data.file_url,
            file_name=data.file_name,
            file_size=data.file_size,
            file_type=data.file_type
        )
        session.add(message)
        
        # 채팅방 업데이트 시간 갱신
        room.updated_at = get_kst_now()
        
        session.commit()
        session.refresh(message)
        
        return ChatMessageRead(
            id=message.id,
            room_id=message.room_id,
            sender_id=message.sender_id,
            content=message.content,
            message_type=message.message_type,
            is_read=message.is_read,
            created_at=message.created_at.isoformat(),
            # ✅ 파일 정보 반환
            file_url=message.file_url,
            file_name=message.file_name,
            file_size=message.file_size,
            file_type=message.file_type
        )
```

**get_chat_messages 함수도 수정:**

```python
@router.get("/rooms/{room_id}/messages", response_model=List[ChatMessageRead])
def get_chat_messages(
    room_id: int,
    current_user_id: int = Depends(get_current_user_id)
):
    # ... 기존 코드 ...
    
    return [
        ChatMessageRead(
            id=msg.id,
            room_id=msg.room_id,
            sender_id=msg.sender_id,
            content=msg.content,
            message_type=msg.message_type,
            is_read=msg.is_read,
            created_at=msg.created_at.isoformat(),
            # ✅ 파일 정보 추가
            file_url=msg.file_url,
            file_name=msg.file_name,
            file_size=msg.file_size,
            file_type=msg.file_type
        )
        for msg in messages
    ]
```

---

## 🎨 3단계: 프론트엔드 수정

### 📄 3-1. chat_message.dart 수정

**파일:** `intersection-frontend/lib/models/chat_message.dart`

**전체 교체:**

```dart
class ChatMessage {
  final int id;
  final int roomId;
  final int senderId;
  final String content;
  final String messageType;  // normal, system, file, image
  final bool isRead;
  final String createdAt;
  
  // ✅ 파일 업로드 관련 필드 추가
  final String? fileUrl;
  final String? fileName;
  final int? fileSize;
  final String? fileType;

  ChatMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.content,
    this.messageType = "normal",
    required this.isRead,
    required this.createdAt,
    this.fileUrl,
    this.fileName,
    this.fileSize,
    this.fileType,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      roomId: json['room_id'],
      senderId: json['sender_id'],
      content: json['content'],
      messageType: json['message_type'] ?? "normal",
      isRead: json['is_read'] ?? false,
      createdAt: json['created_at'],
      fileUrl: json['file_url'],
      fileName: json['file_name'],
      fileSize: json['file_size'],
      fileType: json['file_type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room_id': roomId,
      'sender_id': senderId,
      'content': content,
      'message_type': messageType,
      'is_read': isRead,
      'created_at': createdAt,
      'file_url': fileUrl,
      'file_name': fileName,
      'file_size': fileSize,
      'file_type': fileType,
    };
  }
  
  // ✅ 헬퍼 메서드
  bool get isFile => messageType == 'file' || messageType == 'image';
  bool get isImage => messageType == 'image';
  bool get isNormalMessage => messageType == 'normal';
  bool get isSystemMessage => messageType == 'system';
  
  // ✅ 파일 크기를 읽기 쉬운 형식으로 변환
  String get fileSizeFormatted {
    if (fileSize == null) return '';
    final bytes = fileSize!;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  
  // ✅ 파일 확장자 추출
  String get fileExtension {
    if (fileName == null) return '';
    final parts = fileName!.split('.');
    return parts.length > 1 ? parts.last.toUpperCase() : '';
  }
}
```

---

### 📄 3-2. api_service.dart 수정

**파일:** `intersection-frontend/lib/services/api_service.dart`

**다음 메서드들을 ApiService 클래스 안에 추가:**

```dart
import 'dart:io';  // ✅ 상단에 추가

class ApiService {
  // ... 기존 메서드들 ...
  
  // ✅ 파일 업로드 API
  static Future<Map<String, dynamic>> uploadFile(File file) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/upload");
    
    var request = http.MultipartRequest('POST', url);
    
    // 헤더 추가
    if (AppState.token != null) {
      request.headers['Authorization'] = 'Bearer ${AppState.token}';
    }
    
    // 파일 추가
    request.files.add(await http.MultipartFile.fromPath(
      'file',
      file.path,
      filename: file.path.split('/').last,
    ));
    
    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    
    if (response.statusCode == 200) {
      return jsonDecode(responseBody) as Map<String, dynamic>;
    } else {
      throw Exception("파일 업로드 실패: $responseBody");
    }
  }

  // ✅ 메시지 전송 (파일 포함 가능) - 기존 메서드 교체
  static Future<ChatMessage> sendChatMessage(
    int roomId,
    String content, {
    String? fileUrl,
    String? fileName,
    int? fileSize,
    String? fileType,
  }) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/chat/rooms/$roomId/messages");

    final body = {
      "content": content,
      if (fileUrl != null) "file_url": fileUrl,
      if (fileName != null) "file_name": fileName,
      if (fileSize != null) "file_size": fileSize,
      if (fileType != null) "file_type": fileType,
    };

    final response = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return ChatMessage.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("메시지 전송 실패: ${response.body}");
    }
  }

  // ✅ 이미지 메시지 전송 헬퍼
  static Future<ChatMessage> sendImageMessage(int roomId, File imageFile) async {
    // 1. 이미지 업로드
    final uploadResult = await uploadFile(imageFile);
    
    // 2. 메시지 전송
    return await sendChatMessage(
      roomId,
      "[이미지]",
      fileUrl: uploadResult['file_url'],
      fileName: uploadResult['filename'],
      fileSize: uploadResult['size'],
      fileType: uploadResult['type'],
    );
  }

  // ✅ 파일 메시지 전송 헬퍼
  static Future<ChatMessage> sendFileMessage(int roomId, File file) async {
    // 1. 파일 업로드
    final uploadResult = await uploadFile(file);
    
    // 2. 메시지 전송
    final fileName = uploadResult['filename'];
    return await sendChatMessage(
      roomId,
      "[파일] $fileName",
      fileUrl: uploadResult['file_url'],
      fileName: fileName,
      fileSize: uploadResult['size'],
      fileType: uploadResult['type'],
    );
  }
}
```

---

### 📄 3-3. chat_screen.dart 수정

**파일:** `intersection-frontend/lib/screens/chat/chat_screen.dart`

**⚠️ 이 파일은 수정이 많아서 주요 부분만 안내드립니다:**

#### 1) 상단 import 추가:
```dart
import 'dart:io';
import 'package:image_picker/image_picker.dart';
```

#### 2) _ChatScreenState에 변수 추가:
```dart
class _ChatScreenState extends State<ChatScreen> {
  // ... 기존 변수들 ...
  
  final ImagePicker _picker = ImagePicker();  // ✅ 추가
  bool _isUploading = false;  // ✅ 추가
```

#### 3) _pickFile() 메서드 교체:
```dart
/// 파일 선택 및 전송
Future<void> _pickFile() async {
  try {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'pdf', 'doc', 'docx', 'txt', 'zip'],
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return;

    final platformFile = result.files.first;
    
    // 파일 크기 제한 (10MB)
    if (platformFile.size > 10 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('파일 크기는 10MB 이하여야 합니다')),
        );
      }
      return;
    }

    setState(() => _isUploading = true);

    // ✅ 실제 파일 업로드
    final file = File(platformFile.path!);
    final newMessage = await ApiService.sendFileMessage(widget.roomId, file);

    if (mounted) {
      setState(() {
        _messages.add(newMessage);
        _isUploading = false;
      });
      _scrollToBottom();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${platformFile.name} 전송 완료')),
      );
    }
  } catch (e) {
    debugPrint('파일 선택 오류: $e');
    if (mounted) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('파일 전송 실패: $e')),
      );
    }
  }
}
```

#### 4) 이미지 관련 메서드 추가:

전체 코드는 이전에 제공한 `chat_screen_file_upload_guide.dart` 참고하세요!
핵심은:
- `_pickAndSendImage()` - 갤러리에서 선택
- `_takePictureAndSend()` - 카메라 촬영
- `_showAttachmentOptions()` - 첨부 옵션 표시
- `_buildMessageBubble()` 수정 - 이미지/파일 표시

---

## 📱 4단계: 권한 설정

### Android

**파일:** `intersection-frontend/android/app/src/main/AndroidManifest.xml`

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- ✅ 추가 -->
    <uses-permission android:name="android.permission.CAMERA"/>
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
    
    <application ...>
        <!-- 기존 설정 -->
    </application>
</manifest>
```

### iOS

**파일:** `intersection-frontend/ios/Runner/Info.plist`

```xml
<key>NSCameraUsageDescription</key>
<string>사진을 촬영하여 전송하기 위해 카메라 권한이 필요합니다</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>사진을 선택하여 전송하기 위해 사진 라이브러리 접근 권한이 필요합니다</string>
```

---

## 🗄️ 5단계: 데이터베이스 재생성

모델을 수정했으므로 DB 재생성 필요:

```bash
# PostgreSQL에서
psql -U postgres -c "DROP DATABASE intersection; CREATE DATABASE intersection;"

# 또는 Python 스크립트
cd intersection-backend
python reset_db.py
```

---

## 🚀 6단계: 실행

### 백엔드
```bash
cd intersection-backend
python -m uvicorn app.main:app --reload --port 8000
```

### 프론트엔드
```bash
cd intersection-frontend
flutter pub get
flutter run -d chrome  # 또는 에뮬레이터
```

---

## ✅ 최종 체크리스트

### 백엔드
- [ ] common.py 수정 (인증 추가)
- [ ] models.py - ChatMessage에 필드 4개 추가
- [ ] schemas.py - ChatMessageCreate, ChatMessageRead 수정
- [ ] chat.py - send_chat_message, get_chat_messages 수정
- [ ] DB 재생성
- [ ] 서버 실행 확인

### 프론트엔드
- [ ] pubspec.yaml - 패키지 2개 추가
- [ ] flutter pub get
- [ ] chat_message.dart 교체
- [ ] api_service.dart - 메서드 4개 추가
- [ ] chat_screen.dart - 파일 업로드 로직 추가
- [ ] AndroidManifest.xml 권한 추가
- [ ] Info.plist 권한 추가 (iOS)

### 테스트
- [ ] 갤러리 이미지 선택 → 전송
- [ ] 파일 선택 → 전송
- [ ] 이미지 클릭 → 확대 보기
- [ ] 10MB 초과 파일 → 에러 메시지
- [ ] 상대방에게 파일 수신 확인

---

## 🎯 주요 변경사항 요약

### 기존 common.py와 차이점:
1. ✅ **인증 추가** - JWT 토큰 필수
2. ✅ **파일 검증** - 확장자, 크기 체크
3. ✅ **상세 응답** - filename, size, type 포함

### 새로 추가된 필드:
- `file_url` - 파일 URL
- `file_name` - 원본 파일명
- `file_size` - 파일 크기 (bytes)
- `file_type` - MIME 타입

### 메시지 타입:
- `normal` - 일반 텍스트
- `image` - 이미지 파일
- `file` - 일반 파일
- `system` - 시스템 메시지

---

이제 완전한 파일/이미지 업로드 기능이 작동합니다! 🎉
