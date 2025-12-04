from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File
from sqlmodel import Session, select, func, desc, or_
from typing import List, Optional
from ..db import engine
from ..models import (
    User, Post, PostLike, Comment, CommentLike, 
    PostReport, CommentReport, Notification, UserBlock, UserReport
)
from ..dependencies import get_current_user
from ..schemas import PostRead, PostCreate, PostReportRead, PostReportCreate
from .common import upload_file

router = APIRouter(tags=["posts"])

# -------------------------------------------------------
# 📝 게시글 작성
# -------------------------------------------------------
@router.post("/users/me/posts/", response_model=PostRead)
def create_post(payload: PostCreate, current_user: User = Depends(get_current_user)):
    with Session(engine) as session:
        post = Post(
            author_id=current_user.id, 
            content=payload.content, 
            image_url=payload.image_url
        )
        session.add(post)
        session.commit()
        session.refresh(post)

        return PostRead(
            id=post.id, 
            author_id=post.author_id, 
            content=post.content, 
            image_url=post.image_url,
            created_at=post.created_at.isoformat(),
            author_name=current_user.name,
            author_nickname=current_user.nickname, # 닉네임 추가
            author_profile_image=current_user.profile_image, # 프로필 이미지 추가
            author_school=current_user.school_name,
            author_region=current_user.region,
            like_count=0,
            comment_count=0, # 새 글은 댓글 0개
            is_liked=False
        )

# -------------------------------------------------------
# 📋 게시글 목록 조회 (검색 + 필터링 + 차단)
# -------------------------------------------------------
@router.get("/posts/", response_model=List[PostRead])
def list_posts(
    skip: int = 0,    
    limit: int = 10,  
    keyword: Optional[str] = None,
    filter_type: str = "all",  # "all"(전체), "school"(내 커뮤니티만)
    current_user: Optional[User] = Depends(get_current_user)
):
    with Session(engine) as session:
        statement = select(Post, User).join(User, Post.author_id == User.id)

        # 🔍 1. 검색 기능 (키워드가 있을 때만 작동)
        if keyword:
            statement = statement.where(
                or_(
                    Post.content.contains(keyword),      # 내용 검색
                    User.name.contains(keyword),         # 작성자 이름 검색
                    User.nickname.contains(keyword)      # 닉네임 검색
                )
            )

        # 🏫 2. 게시판 분리 (필터링)
        if filter_type == "school" and current_user:
            if current_user.community_id:
                statement = statement.where(User.community_id == current_user.community_id)
            else:
                statement = statement.where(User.id == -1) # 커뮤니티 없는 경우 빈 결과

        # 🚫 3. 차단 및 신고 필터링
        if current_user:
            # 차단 관계 (내가 차단함 OR 나를 차단함)
            blocking_stmt = select(UserBlock.blocked_user_id).where(UserBlock.user_id == current_user.id)
            blocking_ids = session.exec(blocking_stmt).all()
            
            blocked_by_stmt = select(UserBlock.user_id).where(UserBlock.blocked_user_id == current_user.id)
            blocked_by_ids = session.exec(blocked_by_stmt).all()
            
            # 신고 관계 (내가 신고한 사람 - pending 상태)
            reported_stmt = select(UserReport.reported_user_id).where(
                UserReport.reporter_id == current_user.id,
                UserReport.status == "pending"
            )
            reported_ids = session.exec(reported_stmt).all()
            
            excluded_ids = list(set(blocking_ids + blocked_by_ids + reported_ids))
            
            if excluded_ids:
                statement = statement.where(Post.author_id.notin_(excluded_ids))

        # 정렬 및 페이징
        statement = statement.order_by(Post.created_at.desc()).offset(skip).limit(limit)
        results = session.exec(statement).all()
        
        post_reads = []
        for post, user in results:
            # ❤️ 좋아요 수 계산
            like_count = session.exec(select(func.count(PostLike.id)).where(PostLike.post_id == post.id)).one()
            
            # 💬 댓글 수 계산 (추가됨)
            comment_count = session.exec(select(func.count(Comment.id)).where(Comment.post_id == post.id)).one()

            # ❤️ 내가 좋아요 눌렀는지 확인
            is_liked = False
            if current_user:
                liked_check = session.exec(
                    select(PostLike).where(PostLike.post_id == post.id, PostLike.user_id == current_user.id)
                ).first()
                if liked_check:
                    is_liked = True

            post_reads.append(PostRead(
                id=post.id,
                author_id=post.author_id,
                content=post.content,
                image_url=post.image_url,
                created_at=post.created_at.isoformat(),
                author_name=user.name,
                author_nickname=user.nickname,
                author_profile_image=user.profile_image,
                author_school=user.school_name,
                author_region=user.region,
                like_count=like_count,
                comment_count=comment_count, # 반환값에 포함
                is_liked=is_liked
            ))
        return post_reads

# -------------------------------------------------------
# 📄 게시글 상세 조회
# -------------------------------------------------------
@router.get("/posts/{post_id}", response_model=PostRead)
def get_post(post_id: int, current_user: Optional[User] = Depends(get_current_user)):
    with Session(engine) as session:
        statement = select(Post, User).where(Post.id == post_id).join(User, Post.author_id == User.id)
        result = session.exec(statement).first()
        
        if not result:
            raise HTTPException(status_code=404, detail="Post not found")
            
        post, user = result
        
        # 차단 체크
        if current_user:
            block_check = session.exec(
                select(UserBlock).where(
                    (UserBlock.user_id == current_user.id) & (UserBlock.blocked_user_id == user.id) |
                    (UserBlock.user_id == user.id) & (UserBlock.blocked_user_id == current_user.id)
                )
            ).first()
            if block_check:
                raise HTTPException(status_code=403, detail="Blocked user's post")

        like_count = session.exec(select(func.count(PostLike.id)).where(PostLike.post_id == post.id)).one()
        comment_count = session.exec(select(func.count(Comment.id)).where(Comment.post_id == post.id)).one()
        
        is_liked = False
        if current_user:
            liked_check = session.exec(
                select(PostLike).where(PostLike.post_id == post.id, PostLike.user_id == current_user.id)
            ).first()
            if liked_check:
                is_liked = True
        
        return PostRead(
            id=post.id,
            author_id=post.author_id,
            content=post.content,
            image_url=post.image_url,
            created_at=post.created_at.isoformat(),
            author_name=user.name,
            author_nickname=user.nickname,
            author_profile_image=user.profile_image,
            author_school=user.school_name,
            author_region=user.region,
            like_count=like_count,
            comment_count=comment_count,
            is_liked=is_liked
        )

# -------------------------------------------------------
# ✏️ 게시글 수정
# -------------------------------------------------------
@router.put("/posts/{post_id}", response_model=PostRead)
def update_post(post_id: int, payload: PostCreate, current_user: User = Depends(get_current_user)):
    with Session(engine) as session:
        post = session.get(Post, post_id)
        
        if not post:
            raise HTTPException(status_code=404, detail="Post not found")
        if post.author_id != current_user.id:
            raise HTTPException(status_code=403, detail="Not post author")
            
        post.content = payload.content
        post.image_url = payload.image_url
        
        session.add(post)
        session.commit()
        session.refresh(post)
        
        like_count = session.exec(select(func.count(PostLike.id)).where(PostLike.post_id == post.id)).one()
        comment_count = session.exec(select(func.count(Comment.id)).where(Comment.post_id == post.id)).one()
        
        liked_check = session.exec(
            select(PostLike).where(PostLike.post_id == post.id, PostLike.user_id == current_user.id)
        ).first()
        is_liked = bool(liked_check)

        return PostRead(
            id=post.id, 
            author_id=post.author_id, 
            content=post.content, 
            image_url=post.image_url, 
            created_at=post.created_at.isoformat(),
            author_name=current_user.name,
            author_nickname=current_user.nickname,
            author_profile_image=current_user.profile_image,
            author_school=current_user.school_name,
            author_region=current_user.region,
            like_count=like_count,
            comment_count=comment_count,
            is_liked=is_liked
        )

# -------------------------------------------------------
# 🗑️ 게시글 삭제 (강력한 버전)
# -------------------------------------------------------
@router.delete("/posts/{post_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_post(post_id: int, current_user: User = Depends(get_current_user)):
    """
    게시글 삭제: 연관된 댓글, 좋아요, 신고, 알림을 모두 제거하고 본문 삭제
    """
    with Session(engine) as session:
        post = session.get(Post, post_id)
        
        if not post:
            raise HTTPException(status_code=404, detail="Post not found")
        if post.author_id != current_user.id:
            raise HTTPException(status_code=403, detail="Not post author")
            
        # 1. 댓글 및 댓글의 하위 데이터(좋아요, 신고) 삭제
        comments = session.exec(select(Comment).where(Comment.post_id == post_id)).all()
        for comment in comments:
            # 댓글 좋아요
            c_likes = session.exec(select(CommentLike).where(CommentLike.comment_id == comment.id)).all()
            for cl in c_likes: session.delete(cl)
            # 댓글 신고
            c_reports = session.exec(select(CommentReport).where(CommentReport.reported_comment_id == comment.id)).all()
            for cr in c_reports: session.delete(cr)
            # 댓글 자체
            session.delete(comment)

        # 2. 게시글 좋아요 삭제
        p_likes = session.exec(select(PostLike).where(PostLike.post_id == post_id)).all()
        for pl in p_likes: session.delete(pl)

        # 3. 게시글 신고 삭제
        p_reports = session.exec(select(PostReport).where(PostReport.reported_post_id == post_id)).all()
        for pr in p_reports: session.delete(pr)

        # 4. 관련 알림 삭제
        notifs = session.exec(select(Notification).where(Notification.related_post_id == post_id)).all()
        for n in notifs: session.delete(n)
            
        # 5. 게시글 최종 삭제
        session.delete(post)
        session.commit()
        return None

# -------------------------------------------------------
# ❤️ 게시글 좋아요 (알림 기능 포함)
# -------------------------------------------------------
@router.post("/posts/{post_id}/like")
def like_post(post_id: int, current_user: User = Depends(get_current_user)):
    with Session(engine) as session:
        post = session.get(Post, post_id)
        if not post:
            raise HTTPException(status_code=404, detail="Post not found")

        existing_like = session.exec(
            select(PostLike).where(PostLike.post_id == post_id, PostLike.user_id == current_user.id)
        ).first()

        liked = False
        if existing_like:
            session.delete(existing_like)
            session.commit()
            liked = False
        else:
            new_like = PostLike(user_id=current_user.id, post_id=post_id)
            session.add(new_like)
            session.commit()
            liked = True
            
            # 🔔 알림 생성
            if post.author_id != current_user.id:
                existing_notif = session.exec(
                    select(Notification).where(
                        Notification.receiver_id == post.author_id,
                        Notification.sender_id == current_user.id,
                        Notification.type == "like",
                        Notification.related_post_id == post.id
                    )
                ).first()
                
                if not existing_notif:
                    sender_name = current_user.nickname or current_user.name or "알 수 없음"
                    notif = Notification(
                        receiver_id=post.author_id,
                        sender_id=current_user.id,
                        type="like",
                        message=f"{sender_name}님이 회원님의 게시글을 좋아합니다.",
                        related_post_id=post.id
                    )
                    session.add(notif)
                    session.commit()
            
        like_count = session.exec(select(func.count(PostLike.id)).where(PostLike.post_id == post.id)).one()
        
        return {"ok": True, "is_liked": liked, "like_count": like_count}

# -------------------------------------------------------
# 🚨 게시글 신고
# -------------------------------------------------------
@router.post("/posts/{post_id}/report", response_model=PostReportRead)
def report_post(
    post_id: int, 
    report_data: PostReportCreate, 
    current_user: User = Depends(get_current_user)
):
    with Session(engine) as session:
        post = session.get(Post, post_id)
        if not post:
            raise HTTPException(status_code=404, detail="Post not found")
            
        if post.author_id == current_user.id:
            raise HTTPException(status_code=400, detail="Cannot report your own post")

        new_report = PostReport(
            reporter_id=current_user.id,
            reported_post_id=post_id,
            reason=report_data.reason,
            status="pending"
        )
        session.add(new_report)
        session.commit()
        session.refresh(new_report)
        
        return PostReportRead(
            id=new_report.id,
            reason=new_report.reason,
            status=new_report.status,
            created_at=new_report.created_at.isoformat()
        )