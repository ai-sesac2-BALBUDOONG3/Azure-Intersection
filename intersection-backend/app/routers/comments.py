from fastapi import APIRouter, Depends, HTTPException, status
from typing import List, Optional
from sqlmodel import Session, select, func
from sqlalchemy import or_ # or_ 임포트 추가 (불필요하지만 혹시 모르니)
from ..db import engine
from ..models import Comment, Post, User, CommentReport, Notification, CommentLike
from ..schemas import (
    CommentCreate, 
    CommentRead, 
    CommentUpdate, 
    CommentReportCreate, 
    CommentReportRead
)
# 🔥 [수정 완료] 순환 참조 해결: users 라우터 대신 dependencies에서 가져옴
from ..dependencies import get_current_user

router = APIRouter(tags=["comments"])

@router.post("/posts/{post_id}/comments", response_model=CommentRead)
def create_comment(post_id: int, payload: CommentCreate, current_user: User = Depends(get_current_user)):
    """
    댓글 생성 API
    - CommentRead 반환 시 작성자의 실명/닉네임과 프로필 이미지를 포함합니다.
    """
    with Session(engine) as session:
        statement = select(Post).where(Post.id == post_id)
        post = session.exec(statement).first()
        if not post:
            raise HTTPException(status_code=404, detail="Post not found")
            
        comment = Comment(post_id=post_id, user_id=current_user.id, content=payload.content)
        session.add(comment)
        session.commit()
        session.refresh(comment)
        
        # 🔔 알림 생성 (작성자가 본인이 아닐 경우)
        if post.author_id != current_user.id:
            sender_name = current_user.name or current_user.nickname or "알 수 없음"
            notif = Notification(
                receiver_id=post.author_id,
                sender_id=current_user.id,
                type="comment",
                message=f"{sender_name}님이 회원님의 게시글에 댓글을 남겼습니다.",
                related_post_id=post.id
            )
            session.add(notif)
            session.commit()
        
        # 🔥 [실명 표시 최종 확인] 프론트엔드가 요구하는 author_name 필드에 실명/닉네임 설정
        display_name = current_user.name or current_user.nickname or current_user.login_id
        
        return CommentRead(
            id=comment.id, 
            post_id=comment.post_id, 
            user_id=comment.user_id, 
            content=comment.content, 
            # user_name과 author_name을 모두 채워 프론트엔드 모델의 어떤 필드를 쓰든 대응
            user_name=display_name, 
            author_name=display_name, 
            author_profile_image=current_user.profile_image, 
            created_at=comment.created_at.isoformat(),
            likes_count=0,
            liked=False
        )

@router.get("/posts/{post_id}/comments", response_model=List[CommentRead])
def list_comments(
    post_id: int,
    current_user: Optional[User] = Depends(get_current_user)
):
    """
    댓글 목록 조회 API
    - 댓글 작성자의 실명/닉네임, 좋아요 수, 좋아요 여부를 포함합니다.
    """
    with Session(engine) as session:
        statement = (
            select(Comment, User)
            .join(User, Comment.user_id == User.id)
            .where(Comment.post_id == post_id)
            .order_by(Comment.created_at.asc())
        )
        results = session.exec(statement).all()
        
        comments_list = []
        for comment, user in results:
            # 🔥 [실명 표시 최종 확인] user_name/author_name에 실명(name)을 우선적으로 사용
            display_name = user.name or user.nickname or user.login_id or "익명"
            
            # ❤️ 좋아요 수 계산
            like_count = session.exec(
                select(func.count(CommentLike.id)).where(CommentLike.comment_id == comment.id)
            ).one()
            
            # ❤️ 내가 좋아요 눌렀는지 확인
            is_liked = False
            if current_user:
                liked_check = session.exec(
                    select(CommentLike).where(
                        CommentLike.comment_id == comment.id, 
                        CommentLike.user_id == current_user.id
                    )
                ).first()
                if liked_check:
                    is_liked = True

            comments_list.append(CommentRead(
                id=comment.id, 
                post_id=comment.post_id, 
                user_id=comment.user_id, 
                content=comment.content, 
                user_name=display_name, 
                author_name=display_name, # 🔥 프론트엔드 스키마 불일치 해결
                author_profile_image=user.profile_image, 
                created_at=comment.created_at.isoformat(),
                likes_count=like_count, 
                liked=is_liked      
            ))

        return comments_list

@router.put("/posts/{post_id}/comments/{comment_id}", response_model=CommentRead)
def update_comment(
    post_id: int, 
    comment_id: int, 
    comment_data: CommentUpdate, 
    current_user: User = Depends(get_current_user)
):
    with Session(engine) as session:
        comment = session.get(Comment, comment_id)
        if not comment:
            raise HTTPException(status_code=404, detail="Comment not found")
        
        if comment.user_id != current_user.id:
            raise HTTPException(status_code=403, detail="Not authorized to edit this comment")
            
        comment.content = comment_data.content
        session.add(comment)
        session.commit()
        session.refresh(comment)
        
        display_name = current_user.name or current_user.nickname or current_user.login_id

        # 좋아요 정보 재조회
        like_count = session.exec(
            select(func.count(CommentLike.id)).where(CommentLike.comment_id == comment.id)
        ).one()
        
        is_liked = session.exec(
            select(CommentLike).where(
                CommentLike.comment_id == comment.id, 
                CommentLike.user_id == current_user.id
            )
        ).first() is not None

        return CommentRead(
            id=comment.id,
            post_id=comment.post_id,
            user_id=comment.user_id,
            content=comment.content,
            user_name=display_name,
            author_name=display_name, # 🔥 프론트엔드 스키마 불일치 해결
            author_profile_image=current_user.profile_image,
            created_at=comment.created_at.isoformat(),
            likes_count=like_count,
            liked=is_liked
        )

@router.delete("/posts/{post_id}/comments/{comment_id}")
def delete_comment(
    post_id: int, 
    comment_id: int, 
    current_user: User = Depends(get_current_user)
):
    """
    댓글 삭제 API
    - 본인 댓글만 삭제 가능하며, 연관된 좋아요 데이터를 함께 삭제합니다.
    """
    with Session(engine) as session:
        # 🔥 [핵심 수정] 댓글 객체를 DB에서 가져옵니다. (session.get 사용)
        comment = session.get(Comment, comment_id)
        if not comment:
            raise HTTPException(status_code=404, detail="Comment not found")
            
        # 권한 확인
        if comment.user_id != current_user.id:
            raise HTTPException(status_code=403, detail="Not authorized to delete this comment")
            
        # 좋아요 데이터도 함께 삭제 (FK 오류 방지)
        for like in session.exec(select(CommentLike).where(CommentLike.comment_id == comment_id)).all():
             session.delete(like)

        session.delete(comment)
        session.commit()
        return {"ok": True}

# ------------------------------------------------------
# ❤️ 댓글 좋아요 기능 (토글)
# ------------------------------------------------------
@router.post("/comments/{comment_id}/like")
def toggle_comment_like(
    comment_id: int,
    current_user: User = Depends(get_current_user)
):
    """댓글 좋아요 토글 (ON/OFF)"""
    with Session(engine) as session:
        # 댓글 존재 확인
        comment = session.get(Comment, comment_id)
        if not comment:
            raise HTTPException(status_code=404, detail="Comment not found")

        # 이미 좋아요 눌렀는지 확인
        existing_like = session.exec(
            select(CommentLike).where(
                CommentLike.user_id == current_user.id,
                CommentLike.comment_id == comment_id
            )
        ).first()

        if existing_like:
            session.delete(existing_like)
            is_liked = False
        else:
            new_like = CommentLike(user_id=current_user.id, comment_id=comment_id)
            session.add(new_like)
            is_liked = True
        
        session.commit()
        
        like_count = session.exec(
            select(func.count(CommentLike.id)).where(CommentLike.comment_id == comment_id)
        ).one()

        return {"is_liked": is_liked, "like_count": like_count}

@router.delete("/comments/{comment_id}/like")
def unlike_comment(comment_id: int, current_user: User = Depends(get_current_user)):
    with Session(engine) as session:
        existing_like = session.exec(
            select(CommentLike).where(
                CommentLike.comment_id == comment_id, 
                CommentLike.user_id == current_user.id
            )
        ).first()

        if existing_like:
            session.delete(existing_like)
            session.commit()
        
        return {"ok": True}

# ------------------------------------------------------
# 🚨 댓글 신고 기능
# ------------------------------------------------------
@router.post("/posts/{post_id}/comments/{comment_id}/report", response_model=CommentReportRead)
def report_comment(
    post_id: int,
    comment_id: int,
    report_data: CommentReportCreate,
    current_user: User = Depends(get_current_user)
):
    """댓글 신고 API (게시글 ID는 편의상 경로에 포함)"""
    with Session(engine) as session:
        comment = session.get(Comment, comment_id)
        if not comment:
            raise HTTPException(status_code=404, detail="Comment not found")

        if comment.user_id == current_user.id:
             raise HTTPException(status_code=400, detail="Cannot report your own comment")

        new_report = CommentReport(
            reporter_id=current_user.id,
            reported_comment_id=comment_id,
            reason=report_data.reason,
            status="pending"
        )
        session.add(new_report)
        session.commit()
        session.refresh(new_report)
        
        return CommentReportRead(
            id=new_report.id,
            reporter_id=new_report.reporter_id,
            reported_comment_id=new_report.reported_comment_id,
            reason=new_report.reason,
            status=new_report.status,
            created_at=new_report.created_at.isoformat()
        )