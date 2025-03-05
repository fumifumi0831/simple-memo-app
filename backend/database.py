from sqlalchemy import create_engine, Column, Integer, String, Text, DateTime, Boolean
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import datetime

# SQLiteデータベースを使用
SQLALCHEMY_DATABASE_URL = "sqlite:///./memo_app.db"
engine = create_engine(SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False})

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# DBセッションの取得
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()