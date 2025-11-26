from fastapi import APIRouter, Depends, HTTPException, status
from typing import List
from ..schemas import PostCreate, PostRead
from ..models import Post, User
from ..db import engine
from sqlmodel import Session, select
from ..routers.users import get_current_user

router = APIRouter(tags=["posts"])


@router.post("/users/me/posts/", response_model=PostRead)
def create_post(payload: PostCreate, current_user: User = Depends(get_current_user)):
    with Session(engine) as session:
        post = Post(author_id=current_user.id, content=payload.content)
        session.add(post)
        session.commit()
        session.refresh(post)
        return PostRead(id=post.id, author_id=post.author_id, content=post.content, created_at=post.created_at.isoformat())


@router.get("/posts/", response_model=List[PostRead])
def list_posts():
    with Session(engine) as session:
        statement = select(Post).order_by(Post.created_at.desc()).limit(100)
        posts = session.exec(statement).all()
        return [PostRead(id=p.id, author_id=p.author_id, content=p.content, created_at=p.created_at.isoformat()) for p in posts]


@router.put("/posts/{post_id}", response_model=PostRead)
def update_post(post_id: int, payload: PostCreate, current_user: User = Depends(get_current_user)):
    with Session(engine) as session:
        statement = select(Post).where(Post.id == post_id)
        post = session.exec(statement).first()
        if not post:
            raise HTTPException(status_code=404, detail="Post not found")
        if post.author_id != current_user.id:
            raise HTTPException(status_code=403, detail="Not post author")
        post.content = payload.content
        session.add(post)
        session.commit()
        session.refresh(post)
        return PostRead(id=post.id, author_id=post.author_id, content=post.content, created_at=post.created_at.isoformat())


@router.delete("/posts/{post_id}")
def delete_post(post_id: int, current_user: User = Depends(get_current_user)):
    with Session(engine) as session:
        statement = select(Post).where(Post.id == post_id)
        post = session.exec(statement).first()
        if not post:
            raise HTTPException(status_code=404, detail="Post not found")
        if post.author_id != current_user.id:
            raise HTTPException(status_code=403, detail="Not post author")
        session.delete(post)
        session.commit()
        return {"ok": True}
