from fastapi import APIRouter, Depends, HTTPException
from typing import List
from ..schemas import CommentCreate, CommentRead
from ..models import Comment, Post, User
from ..db import engine
from sqlmodel import Session, select
from ..routers.users import get_current_user

router = APIRouter(tags=["comments"])


@router.post("/posts/{post_id}/comments", response_model=CommentRead)
def create_comment(post_id: int, payload: CommentCreate, current_user: User = Depends(get_current_user)):
    with Session(engine) as session:
        statement = select(Post).where(Post.id == post_id)
        post = session.exec(statement).first()
        if not post:
            raise HTTPException(status_code=404, detail="Post not found")
        comment = Comment(post_id=post_id, user_id=current_user.id, content=payload.content)
        session.add(comment)
        session.commit()
        session.refresh(comment)
        author = session.get(User, comment.user_id)
        return CommentRead(id=comment.id, post_id=comment.post_id, user_id=comment.user_id, content=comment.content, user_name=author.name if author else None, created_at=comment.created_at.isoformat())


@router.get("/posts/{post_id}/comments", response_model=List[CommentRead])
def list_comments(post_id: int):
    with Session(engine) as session:
        statement = select(Comment).where(Comment.post_id == post_id).order_by(Comment.created_at.asc())
        rows = session.exec(statement).all()
        results = []
        for r in rows:
            author = session.get(User, r.user_id)
            results.append(CommentRead(id=r.id, post_id=r.post_id, user_id=r.user_id, content=r.content, user_name=author.name if author else None, created_at=r.created_at.isoformat()))

        return results
