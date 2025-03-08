from fastapi import FastAPI, Depends, HTTPException, status, Body
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from typing import List, Optional
from pydantic import BaseModel
from datetime import timedelta, datetime

from database import get_db, engine, Base
from models import User, Note
from auth import (
    Token, UserCreate, UserResponse, authenticate_user, create_access_token, 
    get_current_active_user, ACCESS_TOKEN_EXPIRE_MINUTES
)

# データベースとテーブルの作成
Base.metadata.create_all(bind=engine)

# FastAPIアプリケーションの初期化
app = FastAPI(title="Memo App API")

# CORSミドルウェアの設定（フロントエンドからのリクエストを許可）
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000", 
        "https://simple-memo-app-frontend-prod.azurewebsites.net", 
        "https://simple-memo-app-frontend-dev.azurewebsites.net"
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# リクエスト/レスポンスモデル定義
class NoteCreate(BaseModel):
    title: str
    content: str

class NoteResponse(BaseModel):
    id: int
    title: str
    content: str
    created_at: datetime
    updated_at: datetime

    class Config:
        orm_mode = True

# トークンを取得するエンドポイント（ログイン）
@app.post("/token", response_model=Token, tags=["Authentication"])
async def login_for_access_token(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    user = authenticate_user(db, form_data.username, form_data.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.username}, expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer"}

# ユーザー登録エンドポイント
@app.post("/users/", response_model=UserResponse, tags=["Users"])
def create_user(user: UserCreate, db: Session = Depends(get_db)):
    db_user = db.query(User).filter(User.username == user.username).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Username already registered")
    
    db_user = db.query(User).filter(User.email == user.email).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    
    hashed_password = User.get_password_hash(user.password)
    db_user = User(username=user.username, email=user.email, hashed_password=hashed_password)
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

# 自分のユーザー情報を取得するエンドポイント
@app.get("/users/me/", response_model=UserResponse, tags=["Users"])
async def read_users_me(current_user: User = Depends(get_current_active_user)):
    return current_user

# APIエンドポイント
@app.get("/", tags=["Root"])
def read_root():
    return {"message": "Welcome to Memo App API"}

# メモ作成エンドポイント
@app.post("/notes/", response_model=NoteResponse, status_code=status.HTTP_201_CREATED, tags=["Notes"])
def create_note(note: NoteCreate, db: Session = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    db_note = Note(title=note.title, content=note.content, owner_id=current_user.id)
    db.add(db_note)
    db.commit()
    db.refresh(db_note)
    return db_note

# メモ一覧取得エンドポイント
@app.get("/notes/", response_model=List[NoteResponse], tags=["Notes"])
def read_notes(skip: int = 0, limit: int = 100, db: Session = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    notes = db.query(Note).filter(Note.owner_id == current_user.id).offset(skip).limit(limit).all()
    return notes

# 特定のメモを取得するエンドポイント
@app.get("/notes/{note_id}", response_model=NoteResponse, tags=["Notes"])
def read_note(note_id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    db_note = db.query(Note).filter(Note.id == note_id, Note.owner_id == current_user.id).first()
    if db_note is None:
        raise HTTPException(status_code=404, detail="Note not found")
    return db_note

# メモ削除エンドポイント
@app.delete("/notes/{note_id}", status_code=status.HTTP_204_NO_CONTENT, tags=["Notes"])
def delete_note(note_id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    db_note = db.query(Note).filter(Note.id == note_id, Note.owner_id == current_user.id).first()
    if db_note is None:
        raise HTTPException(status_code=404, detail="Note not found")
    db.delete(db_note)
    db.commit()
    return None