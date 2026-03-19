#Mahika Bagri
#March 14 2026

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import timedelta

from database import get_db
from models.user import User
from schemas.user import UserPy, Login, Token
from auth import create_token

from dotenv import load_dotenv
import os

load_dotenv() 

TOKEN_EXPIRES = int(os.environ.get("TOKEN_EXPIRES", 3600))

router = APIRouter()

@router.post("/user")
def add(user: UserPy, db: Session = Depends(get_db)):
    try:
        User.check_input(user.username, user.password, db)
    except ValueError as error:
        raise HTTPException(status_code=400, detail=str(error))

    User.add(db, user.username, user.password, True)

    return {"status": "user created"}

@router.post("/token", response_model=Token)
def verify(login: Login, db: Session = Depends(get_db)):
    user = User.check_password(login.username, login.password, db)

    if not user.is_active:
        raise HTTPException(status_code=404)

    token_expires = timedelta(hours=TOKEN_EXPIRES)

    token = create_token(data={"sub": user.username}, expires_delta=token_expires)

    return {"access_token": token, "token_type": "bearer"}