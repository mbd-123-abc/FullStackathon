#Mahika Bagri
#March 10 2026

from datetime import datetime, timedelta
from typing import Optional
from jose import jwt, JWTError
from fastapi import HTTPException, Depends
from fastapi.security import OAuth2PasswordBearer
import os
from sqlalchemy.orm import Session

from database import get_db
from models.user import User

SECRET_KEY = os.environ.get("SECRET_KEY")
ALGORITHM = os.environ.get("ALGORITHM", "HS256")
TOKEN_EXPIRES = int(os.environ.get("TOKEN_EXPIRES", 3600))

scheme = OAuth2PasswordBearer(tokenUrl="token")


def create_token(data: dict, expires_delta: Optional[timedelta] = None):
    copy = data.copy()

    if expires_delta:
        expires = datetime.utcnow() + expires_delta
    else:
        expires = datetime.utcnow() + timedelta(hours=TOKEN_EXPIRES)

    copy.update({"exp": expires})

    return jwt.encode(copy, SECRET_KEY, algorithm=ALGORITHM)


def verify_token(token: str):
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username: str = payload.get("sub")

        if username is None:
            raise HTTPException(status_code=401)

        return username

    except JWTError:
        raise HTTPException(status_code=401)


def get_user(token: str = Depends(scheme), db: Session = Depends(get_db)):
    username = verify_token(token)

    user = db.query(User).filter(User.username == username).first()

    if user is None:
        raise HTTPException(status_code=401)

    return user


def get_active(curr_user: User = Depends(get_user)):
    if not curr_user.is_active:
        raise HTTPException(status_code=404)

    return curr_user