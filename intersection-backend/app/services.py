from sqlmodel import Session, select
from sqlalchemy import case, desc
from .models import Community, User

def assign_community(session: Session, user: User) -> User:
    """
    유저의 학교/입학년도/지역 정보를 바탕으로 커뮤니티를 자동 배정합니다.
    해당하는 커뮤니티가 없으면 새로 생성합니다.
    """
    if not (user.school_name and user.admission_year and user.region):
        return user

    statement = select(Community).where(
        Community.school_name == user.school_name,
        Community.admission_year == user.admission_year,
        Community.region == user.region
    )
    results = session.exec(statement)
    community = results.first()

    if not community:
        community_name = f"{user.school_name} {user.admission_year}년 입학"
        community = Community(
            name=community_name,
            school_name=user.school_name,
            admission_year=user.admission_year,
            region=user.region
        )
        session.add(community)
        session.commit()
        session.refresh(community)

    user.community_id = community.id
    return user


def get_recommended_friends(session: Session, user: User, limit: int = 20) -> list[User]:
    """
    추천 친구 알고리즘 (Phase 2)
    - 학교, 입학년도, 지역이 일치하는 항목마다 점수를 부여 (+1점씩)
    - 점수가 높은 순으로 정렬하여 반환
    """
    # 1. 점수 계산 로직 (SQL Case문 활용)
    score_expression = (
        case((User.school_name == user.school_name, 1), else_=0) +
        case((User.admission_year == user.admission_year, 1), else_=0) +
        case((User.region == user.region, 1), else_=0)
    ).label("score")

    # 2. 쿼리 작성
    statement = (
        select(User, score_expression)
        .where(User.id != user.id)   # 나 자신은 제외
        .where(User.name.isnot(None)) # 이름 없는 유저(가입 중단 등) 제외
        .order_by(desc("score"))     # 점수 높은 순 정렬
        .limit(limit)
    )

    results = session.exec(statement).all()
    
    # 3. 결과에서 User 객체만 리스트로 뽑되, 
    #    (선택사항) 교집합이 하나도 없는(0점) 사람은 추천 목록에서 제외하고 싶다면 아래 조건 사용
    #    여기서는 1점 이상인 사람만 추천합니다.
    recommended_users = [row[0] for row in results if row[1] > 0]
    
    return recommended_users