from fastapi import APIRouter, Depends, HTTPException, status
from typing import Optional, List
from pydantic import BaseModel
from ..schemas import UserCreate, UserRead, UserUpdate, Token
from ..models import User
from ..db import engine
from sqlmodel import Session, select
from ..auth import get_password_hash, verify_password, create_access_token, decode_access_token
from fastapi.security import OAuth2PasswordBearer

# 추천 / 커뮤니티 서비스 import
from ..services import assign_community, get_recommended_friends

router = APIRouter(tags=["users"])

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/token")


def get_user_by_id(session: Session, user_id: int) -> Optional[User]:
    statement = select(User).where(User.id == user_id)
    return session.exec(statement).first()


def get_current_user(token: str = Depends(oauth2_scheme)) -> User:
    payload = decode_access_token(token)
    if payload is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid authentication token")
    user_id = payload.get("user_id")
    if not user_id:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid authentication token")

    with Session(engine) as session:
        user = get_user_by_id(session, int(user_id))
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
        return user


class LoginRequest(BaseModel):
    email: str
    password: str


@router.post("/token", response_model=Token, tags=["auth"])
def login_for_token(login_data: LoginRequest):
    with Session(engine) as session:
        from sqlalchemy import or_
        statement = select(User).where(
            or_(
                User.email == login_data.email,
                User.login_id == login_data.email
            )
        )
        user = session.exec(statement).first()

        if not user or not verify_password(login_data.password, user.password_hash):
            raise HTTPException(status_code=401, detail="Incorrect email or password")

        token = create_access_token({"user_id": user.id})
        return {"access_token": token, "token_type": "bearer"}


@router.post("/users/", response_model=UserRead)
def create_user(data: UserCreate):
    with Session(engine) as session:
        statement = select(User).where(User.login_id == data.login_id)
        exists = session.exec(statement).first()
        if exists:
            raise HTTPException(status_code=400, detail="login_id already exists")

        # profile/background 이미지 필드는 optional하게 처리 (스키마에 있으면 전달)
        profile_image = getattr(data, "profile_image", None)
        background_image = getattr(data, "background_image", None)

        user = User(
            login_id=data.login_id,
            name=data.name,
            nickname=getattr(data, "nickname", None),
            birth_year=getattr(data, "birth_year", None),
            gender=getattr(data, "gender", None),
            region=getattr(data, "region", None),
            school_name=getattr(data, "school_name", None),
            school_type=getattr(data, "school_type", None),
            admission_year=getattr(data, "admission_year", None),
            email=data.login_id,
            profile_image=profile_image,
            background_image=background_image
        )
        user.password_hash = get_password_hash(data.password)

        session.add(user)
        session.commit()
        session.refresh(user)

        # assign_community: user 객체를 업데이트할 수 있으므로 호출 후 다시 커밋
        try:
            assign_community(session, user)
            session.add(user)
            session.commit()
            session.refresh(user)
        except Exception:
            # assign_community 가 없거나 실패해도 기존 생성은 유효하도록 예외를 무시하지 않고 로그 남기는 것이 좋음.
            # 여기서는 안전히 넘어감(실제 환경에서는 로깅 필요)
            pass

        # 반환시 가능한 필드만 포함 (UserRead 스키마에 맞춰)
        return UserRead(
            id=user.id,
            name=user.name,
            birth_year=user.birth_year,
            region=user.region,
            school_name=user.school_name,
            profile_image=getattr(user, "profile_image", None),
            background_image=getattr(user, "background_image", None),
            nickname=getattr(user, "nickname", None)
        )


@router.get("/users/me", response_model=UserRead)
def get_my_info(current_user: User = Depends(get_current_user)):
    # Feed(Post) 관련 기능은 models.Post 가 있을 때만 수행 — 없으면 빈 리스트 반환
    feed_images: List[str] = []
    # nickname 포함 등 스키마 호환성 고려해 반환
    try:
        # 지연 임포트: 프로젝트에 Post 모델/desc 가 없으면 ImportError 발생 가능
        from ..models import Post
        from sqlmodel import desc

        with Session(engine) as session:
            statement = (
                select(Post)
                .where(Post.author_id == current_user.id)
                .where(Post.image_url != None)
                .order_by(desc(Post.created_at))
            )
            my_posts = session.exec(statement).all()
            feed_images = [post.image_url for post in my_posts if getattr(post, "image_url", None)]
    except Exception:
        # Post 모델이 없거나 다른 오류 발생 시 feed_images는 빈 리스트
        feed_images = []

    return UserRead(
        id=current_user.id,
        name=current_user.name,
        nickname=getattr(current_user, "nickname", None),
        birth_year=getattr(current_user, "birth_year", None),
        region=getattr(current_user, "region", None),
        school_name=getattr(current_user, "school_name", None),
        profile_image=getattr(current_user, "profile_image", None),
        background_image=getattr(current_user, "background_image", None),
        feed_images=feed_images
    )


@router.get("/users/me/recommended", response_model=List[UserRead])
def recommended(current_user: User = Depends(get_current_user)):
    with Session(engine) as session:
        friends = []
        try:
            friends = get_recommended_friends(session, current_user)
        except Exception:
            friends = []

        return [
            UserRead(
                id=u.id,
                name=u.name,
                birth_year=getattr(u, "birth_year", None),
                region=getattr(u, "region", None),
                school_name=getattr(u, "school_name", None),
                profile_image=getattr(u, "profile_image", None),
                background_image=getattr(u, "background_image", None),
                nickname=getattr(u, "nickname", None)
            ) for u in friends
        ]


@router.put("/users/me", response_model=UserRead)
def update_my_info(data: UserUpdate, token: str = Depends(oauth2_scheme)):
    payload = decode_access_token(token)
    if payload is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid authentication token")

    user_id = payload.get("user_id")
    if not user_id:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid authentication token")

    with Session(engine) as session:
        user = get_user_by_id(session, int(user_id))
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        # 텍스트 필드 업데이트 (존재하면 덮어쓰기)
        for fld in ("name", "nickname", "birth_year", "gender", "region", "school_name", "school_type", "admission_year"):
            if getattr(data, fld, None) is not None:
                setattr(user, fld, getattr(data, fld))

        # 이미지 필드 (옵셔널)
        if getattr(data, "profile_image", None) is not None:
            user.profile_image = data.profile_image
        if getattr(data, "background_image", None) is not None:
            user.background_image = data.background_image

        # 저장
        session.add(user)
        session.commit()
        session.refresh(user)

        # 커뮤니티 재배치 (필요 시)
        try:
            assign_community(session, user)
            session.add(user)
            session.commit()
            session.refresh(user)
        except Exception:
            pass

        return UserRead(
            id=user.id,
            name=user.name,
            birth_year=getattr(user, "birth_year", None),
            region=getattr(user, "region", None),
            school_name=getattr(user, "school_name", None),
            profile_image=getattr(user, "profile_image", None),
            background_image=getattr(user, "background_image", None),
            nickname=getattr(user, "nickname", None)
        )
