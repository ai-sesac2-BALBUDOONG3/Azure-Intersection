from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import OAuth2PasswordBearer
from sqlmodel import Session, select
from typing import List

from ..models import UserBlock, UserReport, User
from ..schemas import UserBlockCreate, UserBlockRead, UserReportCreate, UserReportRead
from ..db import engine
from ..auth import decode_access_token

router = APIRouter(prefix="/moderation", tags=["moderation"])
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/token")


def get_current_user_id(token: str = Depends(oauth2_scheme)) -> int:
    """토큰에서 사용자 ID 추출"""
    payload = decode_access_token(token)
    user_id = payload.get("user_id")
    if not user_id:
        raise HTTPException(status_code=401, detail="Invalid token")
    return user_id


# ------------------------------------------------------
# 🚫 차단 기능
# ------------------------------------------------------

@router.post("/block", response_model=UserBlockRead)
def block_user(
    data: UserBlockCreate,
    current_user_id: int = Depends(get_current_user_id)
):
    """사용자 차단"""
    with Session(engine) as session:
        # 자기 자신 차단 방지
        if current_user_id == data.blocked_user_id:
            raise HTTPException(status_code=400, detail="Cannot block yourself")
        
        # 이미 차단했는지 확인
        statement = select(UserBlock).where(
            UserBlock.user_id == current_user_id,
            UserBlock.blocked_user_id == data.blocked_user_id
        )
        existing = session.exec(statement).first()
        
        if existing:
            raise HTTPException(status_code=400, detail="Already blocked")
        
        # 차단 추가
        block = UserBlock(
            user_id=current_user_id,
            blocked_user_id=data.blocked_user_id
        )
        session.add(block)
        session.commit()
        session.refresh(block)
        
        # 차단된 사용자 정보
        blocked_user = session.get(User, data.blocked_user_id)
        
        return UserBlockRead(
            id=block.id,
            user_id=block.user_id,
            blocked_user_id=block.blocked_user_id,
            blocked_user_name=blocked_user.name if blocked_user else None,
            created_at=block.created_at.isoformat()
        )


@router.delete("/block/{blocked_user_id}")
def unblock_user(
    blocked_user_id: int,
    current_user_id: int = Depends(get_current_user_id)
):
    """사용자 차단 해제"""
    with Session(engine) as session:
        statement = select(UserBlock).where(
            UserBlock.user_id == current_user_id,
            UserBlock.blocked_user_id == blocked_user_id
        )
        block = session.exec(statement).first()
        
        if not block:
            raise HTTPException(status_code=404, detail="Block not found")
        
        session.delete(block)
        session.commit()
        
        return {"message": "User unblocked successfully"}


@router.get("/blocked", response_model=List[UserBlockRead])
def get_blocked_users(current_user_id: int = Depends(get_current_user_id)):
    """내가 차단한 사용자 목록"""
    with Session(engine) as session:
        statement = select(UserBlock).where(
            UserBlock.user_id == current_user_id
        )
        blocks = session.exec(statement).all()
        
        result = []
        for block in blocks:
            blocked_user = session.get(User, block.blocked_user_id)
            result.append(UserBlockRead(
                id=block.id,
                user_id=block.user_id,
                blocked_user_id=block.blocked_user_id,
                blocked_user_name=blocked_user.name if blocked_user else None,
                created_at=block.created_at.isoformat()
            ))
        
        return result


@router.get("/is-blocked/{user_id}")
def check_if_blocked(
    user_id: int,
    current_user_id: int = Depends(get_current_user_id)
):
    """두 사용자 간 차단 여부 확인 (양방향)"""
    with Session(engine) as session:
        # 내가 상대방을 차단했는지
        statement1 = select(UserBlock).where(
            UserBlock.user_id == current_user_id,
            UserBlock.blocked_user_id == user_id
        )
        i_blocked = session.exec(statement1).first()
        
        # 상대방이 나를 차단했는지
        statement2 = select(UserBlock).where(
            UserBlock.user_id == user_id,
            UserBlock.blocked_user_id == current_user_id
        )
        blocked_me = session.exec(statement2).first()
        
        return {
            "is_blocked": i_blocked is not None or blocked_me is not None,
            "i_blocked_them": i_blocked is not None,
            "they_blocked_me": blocked_me is not None
        }


# ------------------------------------------------------
# 📢 신고 기능
# ------------------------------------------------------

@router.post("/report", response_model=UserReportRead)
def report_user(
    data: UserReportCreate,
    current_user_id: int = Depends(get_current_user_id)
):
    """사용자 신고"""
    with Session(engine) as session:
        # 자기 자신 신고 방지
        if current_user_id == data.reported_user_id:
            raise HTTPException(status_code=400, detail="Cannot report yourself")
        
        # 신고 추가
        report = UserReport(
            reporter_id=current_user_id,
            reported_user_id=data.reported_user_id,
            reason=data.reason,
            content=data.content,
            status="pending"
        )
        session.add(report)
        session.commit()
        session.refresh(report)
        
        return UserReportRead(
            id=report.id,
            reporter_id=report.reporter_id,
            reported_user_id=report.reported_user_id,
            reason=report.reason,
            status=report.status,
            created_at=report.created_at.isoformat()
        )


@router.get("/reports/my", response_model=List[UserReportRead])
def get_my_reports(current_user_id: int = Depends(get_current_user_id)):
    """내가 신고한 내역"""
    with Session(engine) as session:
        statement = select(UserReport).where(
            UserReport.reporter_id == current_user_id
        ).order_by(UserReport.created_at.desc())
        
        reports = session.exec(statement).all()
        
        return [
            UserReportRead(
                id=r.id,
                reporter_id=r.reporter_id,
                reported_user_id=r.reported_user_id,
                reason=r.reason,
                status=r.status,
                created_at=r.created_at.isoformat()
            )
            for r in reports
        ]

