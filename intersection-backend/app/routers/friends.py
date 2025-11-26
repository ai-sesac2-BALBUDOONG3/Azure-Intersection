from fastapi import APIRouter, Depends, HTTPException
from ..models import User, UserFriendship
from ..db import engine
from sqlmodel import Session, select
from ..routers.users import get_current_user
from ..schemas import UserRead

router = APIRouter(tags=["friends"])


@router.post("/friends/{target_user_id}")
def add_friend(target_user_id: int, current_user: User = Depends(get_current_user)):
    if current_user.id == target_user_id:
        raise HTTPException(status_code=400, detail="Cannot add yourself")

    with Session(engine) as session:
        # check if target exists
        statement = select(User).where(User.id == target_user_id)
        target = session.exec(statement).first()
        if not target:
            raise HTTPException(status_code=404, detail="Target user not found")

        # create friendship (simple, auto-accepted)
        friendship = UserFriendship(user_id=current_user.id, friend_user_id=target_user_id)
        session.add(friendship)
        session.commit()
        session.refresh(friendship)
        return {"ok": True}


@router.get("/friends/me", response_model=list[UserRead])
def list_friends(current_user: User = Depends(get_current_user)):
    with Session(engine) as session:
        statement = select(UserFriendship).where(UserFriendship.user_id == current_user.id)
        rows = session.exec(statement).all()
        friends = []
        for row in rows:
            u = session.get(User, row.friend_user_id)
            if u:
                friends.append(UserRead(id=u.id, name=u.name, birth_year=u.birth_year, region=u.region, school_name=u.school_name))
        return friends
