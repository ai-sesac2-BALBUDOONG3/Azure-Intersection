from typing import List, Tuple, Set
from random import shuffle

from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session, select

from ..db import engine
from ..models import User, UserFriendship, UserBlock, UserReport
from ..schemas import UserRead, FriendRecommendationAI
from ..routers.users import get_current_user
from ..azure_ai import generate_friend_recommendations_ai

router = APIRouter(tags=["friends"])


# ======================================================
# 내부용 추천 로직
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
    if me.school_name and other.school_name and me.school_name == other.school_name:
        score += 30

    # 학교 유형 (초/중/고/대 등)
    if me.school_type and other.school_type and me.school_type == other.school_type:
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
    if me.region and other.region and me.region == other.region:
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

    # 3. 점수 순 정렬
    scored.sort(key=lambda x: x[0], reverse=True)

    # 4. 점수 > 0 인 후보 상위 limit명
    primary: List[User] = [u for score, u in scored if score > 0][:limit]

    # 5. 부족하면 점수 0인 후보 랜덤 채우기
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
    """
    if current_user.id == target_user_id:
        raise HTTPException(status_code=400, detail="Cannot add yourself")

    with Session(engine) as session:
        target = session.get(User, target_user_id)
        if not target:
            raise HTTPException(status_code=404, detail="Target user not found")

        existing_friendship = session.exec(
            select(UserFriendship).where(
                UserFriendship.user_id == current_user.id,
                UserFriendship.friend_user_id == target_user_id,
            )
        ).first()

        if existing_friendship:
            return {"ok": True, "message": "Already friends"}

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
    """
    with Session(engine) as session:
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

        statement = (
            select(User)
            .join(UserFriendship, UserFriendship.friend_user_id == User.id)
            .where(UserFriendship.user_id == current_user.id)
        )

        if excluded_ids:
            statement = statement.where(User.id.notin_(excluded_ids))

        friends = session.exec(statement).all()

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
    규칙 기반 추천 친구 목록
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


@router.get("/friends/recommendations/ai", response_model=List[FriendRecommendationAI])
def recommend_friends_ai(current_user: User = Depends(get_current_user)):
    """
    Azure OpenAI를 사용한 추천 친구 + 추천 이유/첫 메시지
    """
    with Session(engine) as session:
        candidates = _get_recommended_friends(session, current_user, limit=20)
        if not candidates:
            return []

        # 후보 목록을 ID 기준으로 map
        candidates_by_id = {u.id: u for u in candidates}

        # 기본 fallback: 규칙 기반 설명
        def _default_reason(u: User) -> str:
            return "학교/입학년도/지역/나이대가 비슷해서 추천한 친구입니다."

        def _default_first_messages(u: User):
            base_name = u.name or "친구"
            return [
                f"{base_name}님, 우리 프로필이 비슷해서 추천 친구로 떴어요. 반가워요!",
                "혹시 같은 시기에 같은 학교 다녔을지도 모르겠네요 :)",
            ]

        results: List[FriendRecommendationAI] = []

        try:
            ai_items = generate_friend_recommendations_ai(current_user, candidates)
        except RuntimeError:
            # Azure 설정이 없거나 장애인 경우: 규칙 기반만 사용
            for u in candidates:
                results.append(
                    FriendRecommendationAI(
                        user=UserRead(
                            id=u.id,
                            name=u.name,
                            birth_year=u.birth_year,
                            region=u.region,
                            school_name=u.school_name,
                            profile_image=u.profile_image,
                            background_image=u.background_image,
                            feed_images=[],
                        ),
                        reason=_default_reason(u),
                        first_messages=_default_first_messages(u),
                    )
                )
            return results

        # AI 결과를 ID → (reason, first_messages) 로 정리
        ai_by_id = {}
        for item in ai_items:
            uid = item.get("user_id")
            if not uid:
                continue
            ai_by_id[uid] = {
                "reason": item.get("reason"),
                "first_messages": item.get("first_messages") or [],
            }

        # 최종 응답 조립
        for u in candidates:
            meta = ai_by_id.get(u.id, {})
            reason = meta.get("reason") or _default_reason(u)
            first_messages = meta.get("first_messages") or _default_first_messages(u)

            results.append(
                FriendRecommendationAI(
                    user=UserRead(
                        id=u.id,
                        name=u.name,
                        birth_year=u.birth_year,
                        region=u.region,
                        school_name=u.school_name,
                        profile_image=u.profile_image,
                        background_image=u.background_image,
                        feed_images=[],
                    ),
                    reason=reason,
                    first_messages=first_messages,
                )
            )

        return results
