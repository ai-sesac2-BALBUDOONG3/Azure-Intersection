# 파일 경로: intersection-backend/app/routers/friends.py

from typing import List, Tuple, Set
from random import shuffle

from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session, select

from ..db import engine
from ..models import User, UserFriendship, UserBlock, UserReport
from ..schemas import UserRead
from ..routers.users import get_current_user

router = APIRouter(tags=["friends"])


# ======================================================
# 내부용 추천 로직 (services 폴더 없이 이 파일 안에 정리)
# ======================================================

def _collect_excluded_user_ids(session: Session, current_user: User) -> Set[int]:
    """
    추천 대상에서 제외할 사용자 ID들을 모아 반환합니다.
    - 나 자신
    - 이미 친구인 사용자
    - 내가 차단한 사용자
    - 내가 신고한 사용자
    - 나를 차단한 사용자
    - 나를 신고한 사용자
    """
    excluded_ids: Set[int] = {current_user.id}

    # 이미 친구인 사용자
    friend_ids = session.exec(
        select(UserFriendship.friend_user_id).where(
            UserFriendship.user_id == current_user.id
        )
    ).all()
    excluded_ids.update(friend_ids)

    # 내가 차단한 사용자
    blocked_ids = session.exec(
        select(UserBlock.blocked_user_id).where(
            UserBlock.user_id == current_user.id
        )
    ).all()
    excluded_ids.update(blocked_ids)

    # 내가 신고한 사용자
    reported_ids = session.exec(
        select(UserReport.reported_user_id).where(
            UserReport.reporter_id == current_user.id
        )
    ).all()
    excluded_ids.update(reported_ids)

    # 나를 차단한 사용자
    blocked_me_ids = session.exec(
        select(UserBlock.user_id).where(
            UserBlock.blocked_user_id == current_user.id
        )
    ).all()
    excluded_ids.update(blocked_me_ids)

    # 나를 신고한 사용자
    reported_me_ids = session.exec(
        select(UserReport.reporter_id).where(
            UserReport.reported_user_id == current_user.id
        )
    ).all()
    excluded_ids.update(reported_me_ids)

    return excluded_ids


def _score_candidate(me: User, other: User) -> int:
    """
    두 사용자 간의 유사도를 점수로 계산합니다.
    - 같은 학교 이름: +30
    - 같은 학교 유형(초/중/고/대 등): +10
    - 입학년도 차이 0년: +20 / 1년: +10 / 3년 이내: +5
    - 같은 지역: +10
    - 출생연도 차이 0년: +10 / 2년 이내: +5
    - 같은 성별: +2
    - 프로필 이미지가 있는 경우: +1 (활성 사용자 가중치)
    """
    score = 0

    # 학교 이름
    if me.school_name and other.school_name:
        if me.school_name == other.school_name:
            score += 30

    # 학교 유형 (초/중/고/대 등)
    if me.school_type and other.school_type:
        if me.school_type == other.school_type:
            score += 10

    # 입학년도
    if me.admission_year and other.admission_year:
        diff = abs(me.admission_year - other.admission_year)
        if diff == 0:
            score += 20
        elif diff == 1:
            score += 10
        elif diff <= 3:
            score += 5

    # 지역
    if me.region and other.region:
        if me.region == other.region:
            score += 10

    # 출생연도 (나이대 비슷)
    if me.birth_year and other.birth_year:
        diff_age = abs(me.birth_year - other.birth_year)
        if diff_age == 0:
            score += 10
        elif diff_age <= 2:
            score += 5

    # 성별
    if me.gender and other.gender and me.gender == other.gender:
        score += 2

    # 프로필 이미지 보유 (서비스 참여도 가중치)
    if other.profile_image:
        score += 1

    return score


def _get_recommended_friends(
    session: Session,
    current_user: User,
    limit: int = 20,
) -> List[User]:
    """
    현재 사용자 기준으로 추천 친구를 반환합니다.

    1) 추천 대상에서 제외할 사용자 ID 수집
    2) 나머지 전체 후보 조회
    3) 각 후보에 대해 점수 계산
    4) 점수 순으로 정렬 후 상위 N명 반환
    5) 모든 후보의 점수가 0이거나 너무 적을 경우, 일부 랜덤으로 채워 넣기 (fallback)
    """
    excluded_ids = _collect_excluded_user_ids(session, current_user)

    # 1. 후보군 조회 (나 / 친구 / 차단 / 신고 / 나를 차단/신고한 사용자 제외)
    stmt = select(User)
    if excluded_ids:
        stmt = stmt.where(User.id.notin_(excluded_ids))

    candidates: List[User] = session.exec(stmt).all()

    if not candidates:
        return []

    # 2. 점수 계산
    scored: List[Tuple[int, User]] = []
    for u in candidates:
        score = _score_candidate(current_user, u)
        scored.append((score, u))

    # 3. 점수 순으로 정렬 (점수 높은 순)
    scored.sort(key=lambda x: x[0], reverse=True)

    # 4. 1차: 점수 > 0 인 후보만 상위 limit명
    primary: List[User] = [u for score, u in scored if score > 0][:limit]

    # 5. fallback: 너무 적으면, 점수 0인 후보에서 랜덤으로 채워넣기
    if len(primary) < limit:
        remaining_slots = limit - len(primary)
        zero_scored = [u for score, u in scored if score == 0]
        if zero_scored:
            shuffle(zero_scored)
            primary.extend(zero_scored[:remaining_slots])

    return primary


# ======================================================
# 실제 API 엔드포인트들
# ======================================================

@router.post("/friends/{target_user_id}")
def add_friend(target_user_id: int, current_user: User = Depends(get_current_user)):
    """
    친구 추가 API
    - 자기 자신은 친구로 추가 불가
    - 이미 친구인 경우 ok=True로 응답
    - 양방향 친구 관계를 생성 (A->B, B->A)
    """
    if current_user.id == target_user_id:
        raise HTTPException(status_code=400, detail="Cannot add yourself")

    with Session(engine) as session:
        # 대상 사용자 존재 여부 확인
        target = session.get(User, target_user_id)
        if not target:
            raise HTTPException(status_code=404, detail="Target user not found")

        # 이미 친구인지 체크
        existing_friendship = session.exec(
            select(UserFriendship).where(
                UserFriendship.user_id == current_user.id,
                UserFriendship.friend_user_id == target_user_id,
            )
        ).first()

        if existing_friendship:
            return {"ok": True, "message": "Already friends"}

        # 양방향 친구 추가
        friendship1 = UserFriendship(
            user_id=current_user.id,
            friend_user_id=target_user_id,
            status="accepted",
        )
        friendship2 = UserFriendship(
            user_id=target_user_id,
            friend_user_id=current_user.id,
            status="accepted",
        )

        session.add(friendship1)
        session.add(friendship2)
        session.commit()

        return {"ok": True}


@router.get("/friends/me", response_model=List[UserRead])
def list_friends(current_user: User = Depends(get_current_user)):
    """
    내 친구 목록 조회
    - 내가 차단하거나 신고한 사용자,
      (필요시) 나를 차단/신고한 사용자도 제외
    """
    with Session(engine) as session:
        # 1. 차단/신고한 사용자 ID 수집
        blocked_ids = session.exec(
            select(UserBlock.blocked_user_id).where(
                UserBlock.user_id == current_user.id
            )
        ).all()

        reported_ids = session.exec(
            select(UserReport.reported_user_id).where(
                UserReport.reporter_id == current_user.id,
                UserReport.status == "pending",
            )
        ).all()

        excluded_ids = set(blocked_ids + reported_ids)

        # 2. 친구 목록 조회 (JOIN 사용 + 차단/신고 필터링)
        statement = (
            select(User)
            .join(UserFriendship, UserFriendship.friend_user_id == User.id)
            .where(UserFriendship.user_id == current_user.id)
        )

        if excluded_ids:
            statement = statement.where(User.id.notin_(excluded_ids))

        friends = session.exec(statement).all()

        # 3. UserRead 변환 (프로필/배경 이미지 포함)
        return [
            UserRead(
                id=u.id,
                name=u.name,
                birth_year=u.birth_year,
                region=u.region,
                school_name=u.school_name,
                profile_image=u.profile_image,
                background_image=u.background_image,
                feed_images=[],
            )
            for u in friends
        ]


@router.get("/friends/recommendations", response_model=List[UserRead])
def recommend_friends(current_user: User = Depends(get_current_user)):
    """
    추천 친구 목록 조회
    - 나 자신, 이미 친구인 사용자 제외
    - 차단/신고한 사용자, 나를 차단/신고한 사용자 제외
    - 학교/입학년도/지역/나이/성별 등을 기반으로 점수 계산
    - 점수 순으로 상위 20명 반환
    - 후보가 적을 경우, 점수 0인 사용자도 일부 랜덤으로 섞어서 fallback
    """
    with Session(engine) as session:
        candidates = _get_recommended_friends(session, current_user, limit=20)

        return [
            UserRead(
                id=u.id,
                name=u.name,
                birth_year=u.birth_year,
                region=u.region,
                school_name=u.school_name,
                profile_image=u.profile_image,
                background_image=u.background_image,
                feed_images=[],
            )
            for u in candidates
        ]
