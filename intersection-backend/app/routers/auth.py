from fastapi import APIRouter, Request, Depends, HTTPException, status
from fastapi.responses import RedirectResponse, HTMLResponse
from typing import Optional
from ..auth import create_access_token, get_password_hash, verify_password
from ..models import User
from ..db import engine, create_db_and_tables
from sqlmodel import Session, select
from sqlalchemy import or_
from sqlalchemy.exc import IntegrityError
from urllib.parse import quote, unquote
from ..config import settings
import httpx

router = APIRouter(prefix="/auth", tags=["auth"])

KAKAO_CLIENT_ID = settings.KAKAO_CLIENT_ID
KAKAO_CLIENT_SECRET = settings.KAKAO_CLIENT_SECRET
KAKAO_REDIRECT_URI = settings.KAKAO_REDIRECT_URI


@router.get("/kakao/login")
async def kakao_login(client_redirect: str | None = None):
    # If client id is provided, redirect to Kakao OAUTH page
    if KAKAO_CLIENT_ID:
        # If the configured redirect URI points to localhost, that endpoint
        # will not be reachable by Kakao's servers in most real-world cases
        # (and mobile devices won't be able to contact your desktop's 127.0.0.1).
        # When developing with a mobile client that passes a client_redirect
        # scheme (eg. intersection://oauth) we provide a friendly dev fallback
        # page to either simulate the callback locally or instruct the
        # developer to expose the backend (eg. via ngrok) and register that
        # redirect URI with the Kakao app settings.
        if client_redirect and ("127.0.0.1" in KAKAO_REDIRECT_URI or "localhost" in KAKAO_REDIRECT_URI):
            # render a helpful page with a quick "simulate login" link
            state = quote(client_redirect) if client_redirect else None
            simulate_link = f"/auth/kakao/callback?mock=1" + (f"&state={state}" if state else "")
            html = (
                f"<html><body><h2>Kakao redirect is configured to a localhost callback.</h2>"
                f"<p>Kakao cannot reach <code>{KAKAO_REDIRECT_URI}</code> from the public internet or from mobile devices."
                f"</p><p>Options:</p>"
                f"<ul>"
                f"<li>Start the backend on the configured host/port so Kakao's redirect reaches your server.</li>"
                f"<li>Expose your local server with a tunnel (eg. <code>ngrok</code>) and set that URL as KAKAO_REDIRECT_URI in the app settings.</li>"
                f"<li>For quick testing, use the <a href='{simulate_link}'>simulate login (mock)</a> which will create a test user locally and proceed to your client_redirect.</li>"
                f"</ul>"
                f"</body></html>"
            )
            return HTMLResponse(html)
        # If client_redirect is provided, include it in state (url-quoted) so callback can redirect back
        state = quote(client_redirect) if client_redirect else None
        kakao_oauth = (
            f"https://kauth.kakao.com/oauth/authorize?client_id={KAKAO_CLIENT_ID}&redirect_uri={KAKAO_REDIRECT_URI}&response_type=code" + (f"&state={state}" if state else "")
        )
        return RedirectResponse(kakao_oauth)

    # Otherwise provide a simulated flow link for local testing
    # This will create a test user on callback when clicked
    return RedirectResponse("/auth/kakao/callback?mock=1")


@router.get("/kakao/callback")
async def kakao_callback(request: Request, code: Optional[str] = None, mock: Optional[int] = None, state: Optional[str] = None):
    # If configured, exchange code for Kakao token and fetch profile
    profile = None

    if mock or not KAKAO_CLIENT_ID:
        # simulated profile for local development
        profile = {"id": "kakao-local-12345", "kakao_account": {"email": "kakao_local@example.com", "profile": {"nickname": "KakaoUser"}}}
    else:
        async with httpx.AsyncClient() as client:
            try:
                token_resp = await client.post(
                    "https://kauth.kakao.com/oauth/token",
                    data={
                        "grant_type": "authorization_code",
                        "client_id": KAKAO_CLIENT_ID,
                        "client_secret": KAKAO_CLIENT_SECRET,
                        "redirect_uri": KAKAO_REDIRECT_URI,
                        "code": code,
                    },
                )
                token_resp.raise_for_status()
            except httpx.HTTPStatusError as exc:
                # provide helpful debugging info in development
                text = getattr(exc.response, "text", "")
                status = getattr(exc.response, "status_code", None)
                # log minimal info
                print(f"[auth.kakao.callback] token exchange failed: status={status} body={text}")
                return HTMLResponse(f"Token exchange failed (status={status}). Response: {text}", status_code=502)

            access_token = token_resp.json().get("access_token")

            # fetch profile
            try:
                profile_resp = await client.get("https://kapi.kakao.com/v2/user/me", headers={"Authorization": f"Bearer {access_token}"})
                profile_resp.raise_for_status()
                profile = profile_resp.json()
            except httpx.HTTPStatusError as exc:
                text = getattr(exc.response, "text", "")
                status = getattr(exc.response, "status_code", None)
                print(f"[auth.kakao.callback] profile fetch failed: status={status} body={text}")
                return HTMLResponse(f"Profile fetch failed (status={status}). Response: {text}", status_code=502)

    # Upsert user in DB and give JWT access token
    try:
        with Session(engine) as session:
            # Try find by email if exists
            email = None
            nickname = None
            kakao_id = str(profile.get('id'))
            
            if profile.get("kakao_account"):
                email = profile["kakao_account"].get("email")
                if profile["kakao_account"].get("profile"):
                    nickname = profile["kakao_account"]["profile"].get("nickname")
            
            # If no nickname from profile, use a default
            if not nickname:
                nickname = f"카카오사용자{kakao_id[-4:]}"

            existing = None
            # Use kakao:ID as login_id (email is optional and may not be available)
            login_id_val = f"kakao:{kakao_id}"
            
            # Try to find existing user by login_id first, then by email if available
            statement = select(User).where(User.login_id == login_id_val)
            existing = session.exec(statement).first()
            
            # If not found by login_id and email is available, try to find by email
            if not existing and email:
                statement = select(User).where(User.email == email)
                existing = session.exec(statement).first()
                # If found by email, update login_id to kakao format
                if existing:
                    existing.login_id = login_id_val
                    session.add(existing)
                    session.commit()
                    session.refresh(existing)

            if existing is None:
                # create a new user record
                user = User(login_id=login_id_val, email=email, name=nickname, nickname=nickname)
                user.password_hash = get_password_hash("kakao-oauth")
                try:
                    session.add(user)
                    session.commit()
                    session.refresh(user)
                    existing = user
                except IntegrityError as exc:
                    # This can happen if another process created the same login_id concurrently.
                    session.rollback()
                    print(f"[auth.kakao.callback] IntegrityError while inserting user: {exc}")
                    # Try to load the existing user now
                    fallback = session.exec(select(User).where(User.login_id == login_id_val)).first()
                    if fallback is not None:
                        existing = fallback
                    else:
                        # Unexpected — re-raise for higher-level handling
                        raise

            # create access token
            token = create_access_token({"user_id": existing.id})
    except Exception as exc:
        # Unexpected DB error — log and return a readable message for debugging (dev only)
        print(f"[auth.kakao.callback] DB error: {exc}")
        return HTMLResponse(f"Server error while storing user: {exc}", status_code=500)

    # For a mobile client, if a state was provided containing the client redirect scheme, redirect to it
    client_redirect = None
    if state:
        try:
            client_redirect = unquote(state)
        except Exception:
            client_redirect = None

    # If a client redirect scheme was provided, send token via fragment so flutter_web_auth can pick it up
    if client_redirect:
        # Build redirect: append token as fragment
        sep = "#" if "#" not in client_redirect else "&"
        return RedirectResponse(f"{client_redirect}{sep}access_token={token}")

    # Otherwise return HTMLResponse page to be consumed in browser (postMessage or display token)
    # Build the minimal HTML/JS response without using a multi-line f-string
    # (avoids f-string parsing issues with JS object braces)
    html = (
        "<html><body><script>"
        f"const token = '{token}';"
        # When opened from a web client, flutter_web_auth's web implementation
        # listens for a postMessage with the key 'flutter-web-auth' whose
        # value is a URL string. Return a URL containing the token in the
        # fragment so the plugin can parse it.
        "if (window.opener) {"
        "  const message = window.location.origin + '/#access_token=' + token;"
        "  window.opener.postMessage({ 'flutter-web-auth': message }, window.location.origin);"
        "  window.close();"
        "} else {"
        "  document.write('Login successful. Token: ' + token);"
        "}"
        "</script></body></html>"
    )

    return HTMLResponse(html)


@router.get("/kakao/dev_token")
async def kakao_dev_token():
    """Development-only helper: return an access token for a local test user.
    Intended for local development/testing only.
    """
    # upsert a test user and return JWT
    profile = {"id": "kakao-local-dev", "kakao_account": {"email": "kakao_dev@example.com", "profile": {"nickname": "DevUser"}}}

    from sqlmodel import Session, select
    with Session(engine) as session:
        statement = select(User).where(User.email == profile["kakao_account"]["email"])
        existing = session.exec(statement).first()
        if existing is None:
            user = User(login_id=profile["kakao_account"]["email"], email=profile["kakao_account"]["email"], name="DevUser", nickname="DevUser")
            user.password_hash = get_password_hash("dev-token")
            session.add(user)
            session.commit()
            session.refresh(user)
            existing = user

        token = create_access_token({"user_id": existing.id})
        return {"access_token": token}
