from typing import Optional, List
from pydantic import BaseModel

# ------------------------------------------------------
# 🔐 인증 & 토큰
# ------------------------------------------------------
class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"


class TokenData(BaseModel):
    user_id: Optional[int] = None


# ------------------------------------------------------
# 🏫 학교 관련 (School)
# ------------------------------------------------------
class SchoolCreate(BaseModel):
    """회원가입 시 학교 정보"""
    name: str
    school_type: str                  # ✅ 프론트에서 오는 필드명과 맞춤
    admission_year: Optional[int] = None


class SchoolRead(BaseModel):
    """조회용 학교 정보"""
    id: Optional[int] = None
    name: str
    school_type: str                  # ✅ 동일하게 유지
    admission_year: Optional[int] = None


# ------------------------------------------------------
# 👤 사용자 (User)
# ------------------------------------------------------
class UserCreate(BaseModel):
    login_id: str
    password: str
    name: Optional[str] = None
    nickname: Optional[str] = None
    birth_year: Optional[int] = None
    gender: Optional[str] = None
    region: Optional[str] = None

    # 단일 학교 (하위 호환용)
    school_name: Optional[str] = None
    school_type: Optional[str] = None
    admission_year: Optional[int] = None

    # ✅ 다중 학교 등록용
    # 프론트에서 body.schools[0] = {name, school_type, admission_year}
    schools: Optional[List[SchoolCreate]] = None

    profile_image: Optional[str] = None
    background_image: Optional[str] = None
    phone: Optional[str] = None


class UserRead(BaseModel):
    id: int
    name: Optional[str] = None
    nickname: Optional[str] = None
    birth_year: Optional[int] = None
    gender: Optional[str] = None
    region: Optional[str] = None

    # 단일 학교 표시용
    school_name: Optional[str] = None
    school_type: Optional[str] = None
    admission_year: Optional[int] = None

    # 전체 학교 목록
    schools: Optional[List[SchoolRead]] = None

    phone: Optional[str] = None
    profile_image: Optional[str] = None
    background_image: Optional[str] = None

    # 프로필 피드용 이미지
    feed_images: List[str] = []


class UserUpdate(BaseModel):
    name: Optional[str] = None
    nickname: Optional[str] = None
    birth_year: Optional[int] = None
    gender: Optional[str] = None
    region: Optional[str] = None

    school_name: Optional[str] = None
    school_type: Optional[str] = None
    admission_year: Optional[int] = None

    profile_image: Optional[str] = None
    background_image: Optional[str] = None


# ------------------------------------------------------
# 📝 게시글 (Post)
# ------------------------------------------------------
class PostCreate(BaseModel):
    content: str
    image_url: Optional[str] = None


class PostRead(BaseModel):
    id: int
    author_id: int
    content: str
    image_url: Optional[str] = None
    created_at: Optional[str] = None

    author_name: Optional[str] = None
    author_school: Optional[str] = None
    author_region: Optional[str] = None

    like_count: int = 0
    is_liked: bool = False
    comment_count: int = 0


class PostReportCreate(BaseModel):
    reason: str


class PostReportRead(BaseModel):
    id: int
    reason: str
    status: str
    created_at: str


# ------------------------------------------------------
# 💬 댓글 (Comment)
# ------------------------------------------------------
class CommentCreate(BaseModel):
    content: str


class CommentRead(BaseModel):
    id: int
    post_id: int
    user_id: int
    content: str
    created_at: Optional[str] = None

    user_name: Optional[str] = None
    author_profile_image: Optional[str] = None

    like_count: int = 0
    is_liked: bool = False


class CommentUpdate(BaseModel):
    content: str


class CommentReportCreate(BaseModel):
    comment_id: int
    reason: str


class CommentReportRead(BaseModel):
    id: int
    reporter_id: int
    reported_comment_id: int
    reason: str
    status: str
    created_at: str


# ------------------------------------------------------
# 🗨️ 채팅 (Chat)
# ------------------------------------------------------
class ChatRoomCreate(BaseModel):
    friend_id: int


class ChatRoomRead(BaseModel):
    id: int
    user1_id: int
    user2_id: int
    friend_id: int
    friend_name: Optional[str] = None
    last_message: Optional[str] = None
    last_message_time: Optional[str] = None
    unread_count: int = 0
    created_at: str

    last_message_type: Optional[str] = None
    last_file_url: Optional[str] = None
    last_file_name: Optional[str] = None

    friend_profile_image: Optional[str] = None

    i_reported_them: bool = False
    they_blocked_me: bool = False
    they_left: bool = False
    is_pinned: bool = False


class ChatMessageCreate(BaseModel):
    content: str
    file_url: Optional[str] = None
    file_name: Optional[str] = None
    file_size: Optional[int] = None
    file_type: Optional[str] = None


class ChatMessageRead(BaseModel):
    id: int
    room_id: int
    sender_id: int
    content: str
    message_type: str = "normal"
    is_read: bool
    created_at: str

    file_url: Optional[str] = None
    file_name: Optional[str] = None
    file_size: Optional[int] = None
    file_type: Optional[str] = None
    is_pinned: bool = False


# ------------------------------------------------------
# 🚫 차단 & 사용자 신고
# ------------------------------------------------------
class UserBlockCreate(BaseModel):
    blocked_user_id: int


class UserBlockRead(BaseModel):
    id: int
    user_id: int
    blocked_user_id: int
    blocked_user_name: Optional[str] = None
    created_at: str


class UserReportCreate(BaseModel):
    reported_user_id: int
    reason: str
    content: Optional[str] = None


class UserReportRead(BaseModel):
    id: int
    reporter_id: int
    reported_user_id: int
    reason: str
    status: str
    created_at: str


# ------------------------------------------------------
# 🔔 알림
# ------------------------------------------------------
class NotificationRead(BaseModel):
    id: int
    sender_id: int
    sender_name: Optional[str] = None
    sender_profile_image: Optional[str] = None
    type: str
    message: str
    related_post_id: Optional[int] = None
    is_read: bool
    created_at: str


# ------------------------------------------------------
# 🤝 AI 친구 추천
# ------------------------------------------------------
class FriendRecommendationAI(BaseModel):
    user: UserRead
    reason: str
    first_messages: List[str] = []
