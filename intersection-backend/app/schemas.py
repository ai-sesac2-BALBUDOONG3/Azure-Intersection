from typing import Optional
from pydantic import BaseModel

class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"

class TokenData(BaseModel):
    user_id: Optional[int]

class UserCreate(BaseModel):
    login_id: str
    password: str
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

class UserRead(BaseModel):
    id: int
    name: Optional[str] = None
    birth_year: Optional[int] = None
    region: Optional[str] = None
    school_name: Optional[str] = None


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

class PostCreate(BaseModel):
    content: str
    image_url: Optional[str] = None  # 📷 [추가됨]

class PostRead(BaseModel):
    id: int
    author_id: int
    content: str
    image_url: Optional[str] = None  # 📷 [추가됨]
    created_at: Optional[str] = None

class CommentCreate(BaseModel):
    content: str

class CommentRead(BaseModel):
    id: int
    post_id: int
    user_id: int
    content: str
    user_name: Optional[str] = None
    created_at: Optional[str] = None


# ------------------------------------------------------
# 💬 Chat (채팅) 스키마
# ------------------------------------------------------
class ChatRoomCreate(BaseModel):
    """채팅방 생성 요청"""
    friend_id: int  # 채팅할 친구 ID


class ChatRoomRead(BaseModel):
    """채팅방 조회 응답"""
    id: int
    user1_id: int
    user2_id: int
    friend_id: int  # 상대방 ID
    friend_name: Optional[str] = None
    last_message: Optional[str] = None
    last_message_time: Optional[str] = None
    unread_count: int = 0
    created_at: str


class ChatMessageCreate(BaseModel):
    """메시지 전송 요청"""
    content: str


class ChatMessageRead(BaseModel):
    """메시지 조회 응답"""
    id: int
    room_id: int
    sender_id: int
    content: str
    is_read: bool
    created_at: str
