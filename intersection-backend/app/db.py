from sqlmodel import create_engine, SQLModel, Session
from typing import Optional
from .config import settings

DATABASE_URL = settings.DATABASE_URL

# Use the sqlite "check_same_thread" arg only for sqlite; Postgres doesn't need it
connect_args = {}
if DATABASE_URL.startswith("sqlite"):
    connect_args = {"check_same_thread": False}

engine = create_engine(DATABASE_URL, echo=False, connect_args=connect_args)

def create_db_and_tables():
    SQLModel.metadata.create_all(engine)

def get_session():
    with Session(engine) as session:
        yield session
