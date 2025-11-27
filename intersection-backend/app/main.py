from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .db import create_db_and_tables

from .routers import auth as auth_router
from .routers import users as users_router
from .routers import posts as posts_router
from .routers import comments as comments_router
from .routers import friends as friends_router

app = FastAPI(title="Intersection Backend (dev)")

app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=r"http://(localhost|127\.0\.0\.1|10\.0\.2\.2)(:\d+)?",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
def on_startup():
    create_db_and_tables()


app.include_router(auth_router.router)
app.include_router(users_router.router)
app.include_router(posts_router.router)
app.include_router(comments_router.router)
app.include_router(friends_router.router)


@app.get("/")
def root():
    return {"message": "Intersection backend running"}
