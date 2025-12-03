# 파일 경로: intersection-backend/app/azure_ai.py

from __future__ import annotations

import json
from typing import List, Dict, Any

from openai import AzureOpenAI  # pip 패키지: openai
from .config import settings
from .models import User

_client: AzureOpenAI | None = None


def get_azure_client() -> AzureOpenAI:
    """
    Azure OpenAI 클라이언트 싱글톤 생성.
    설정이 비어 있으면 RuntimeError 를 발생시켜 호출측에서 fallback 가능하게 함.
    """
    global _client

    if _client is not None:
        return _client

    if not settings.AZURE_OPENAI_ENDPOINT or not settings.AZURE_OPENAI_API_KEY:
        raise RuntimeError("Azure OpenAI 설정이 없습니다. ENDPOINT / API_KEY 를 확인하세요.")

    if not settings.AZURE_OPENAI_CHAT_DEPLOYMENT:
        raise RuntimeError("AZURE_OPENAI_CHAT_DEPLOYMENT 가 설정되지 않았습니다.")

    _client = AzureOpenAI(
        api_key=settings.AZURE_OPENAI_API_KEY,
        api_version=settings.AZURE_OPENAI_API_VERSION,
        azure_endpoint=settings.AZURE_OPENAI_ENDPOINT,
    )
    return _client


def _build_friend_reco_payload(current_user: User, candidates: List[User]) -> Dict[str, Any]:
    """
    LLM에 넘길 최소한의 유저 정보만 정리.
    개인정보 과도 노출 방지를 위해 매칭에 필요한 정보만 사용.
    """
    me = {
        "id": current_user.id,
        "name": current_user.name,
        "birth_year": current_user.birth_year,
        "region": current_user.region,
        "school_name": current_user.school_name,
        "school_type": current_user.school_type,
        "admission_year": current_user.admission_year,
    }

    cands = []
    for u in candidates:
        cands.append(
            {
                "id": u.id,
                "name": u.name,
                "birth_year": u.birth_year,
                "region": u.region,
                "school_name": u.school_name,
                "school_type": u.school_type,
                "admission_year": u.admission_year,
            }
        )

    return {"me": me, "candidates": cands}


def generate_friend_recommendations_ai(
    current_user: User,
    candidates: List[User],
) -> List[Dict[str, Any]]:
    """
    Azure OpenAI Chat 을 호출해서
    - 추천 이유(reason)
    - 첫 메시지 후보(first_messages)
    를 생성한다.

    반환 형식:
    [
      {
        "user_id": 4,
        "reason": "...",
        "first_messages": ["...", "..."]
      },
      ...
    ]
    """
    payload = _build_friend_reco_payload(current_user, candidates)

    client = get_azure_client()

    # system / user 메시지 구성
    system_prompt = (
        "너는 친구 추천 서비스를 위한 추천 설명 도우미야. "
        "사용자의 프로필과 추천 후보들의 프로필을 보고, "
        "왜 이 사람들을 추천하는지 한두 문장으로 한국어로 설명해주고, "
        "상대에게 부담스럽지 않은 첫 채팅 문장을 2~3개 만들어줘.\n\n"
        "출력은 반드시 JSON 형식으로만 반환해야 한다. "
        '형식은 {\"recommendations\": [{\"user_id\": ..., \"reason\": \"...\", \"first_messages\": [\"...\"]}]} 이다.'
    )

    user_prompt = (
        "다음은 현재 사용자(me)와 추천 후보들(candidates)의 정보야.\n"
        "이 정보를 기반으로 추천 이유와 첫 메시지 후보를 만들어줘.\n\n"
        f"{json.dumps(payload, ensure_ascii=False)}"
    )

    response = client.chat.completions.create(
        model=settings.AZURE_OPENAI_CHAT_DEPLOYMENT,
        messages=[
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_prompt},
        ],
        temperature=0.7,
        max_tokens=800,
        response_format={"type": "json_object"},
    )

    content = response.choices[0].message.content
    try:
        data = json.loads(content)
    except Exception:
        # JSON 파싱 실패 시, 아주 단순한 fallback 생성
        results: List[Dict[str, Any]] = []
        for u in candidates:
            results.append(
                {
                    "user_id": u.id,
                    "reason": "학교/입학년도/지역이 비슷한 친구라 추천합니다.",
                    "first_messages": [
                        f"{u.name}님, 우리 학년/학교가 비슷해서 추천 친구로 떴어요. 반가워요!",
                        "요즘 뭐 하면서 지내시는지 궁금해서 연락드렸어요 :)",
                    ],
                }
            )
        return results

    recos = data.get("recommendations", [])
    cleaned: List[Dict[str, Any]] = []

    for item in recos:
        user_id = item.get("user_id")
        reason = item.get("reason") or "비슷한 학교/지역/나이대라 추천합니다."
        first_messages = item.get("first_messages") or []

        # first_messages 는 문자열 리스트로 강제
        fm_list: List[str] = []
        if isinstance(first_messages, list):
            for v in first_messages:
                if isinstance(v, str) and v.strip():
                    fm_list.append(v.strip())
        elif isinstance(first_messages, str):
            fm_list.append(first_messages.strip())

        cleaned.append(
            {
                "user_id": user_id,
                "reason": reason,
                "first_messages": fm_list,
            }
        )

    return cleaned
