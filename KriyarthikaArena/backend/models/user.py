#Mahika Bagri
#March 19 2026

from sqlalchemy import Column, Integer, String, Boolean
from sqlalchemy.orm import relationship
from passlib.hash import argon2
from fastapi import HTTPException
import string 

from database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True)
    username = Column(String(50), nullable=False)
    password = Column(String(225), nullable=False)
    is_active = Column(Boolean, default=True)

    arenas = relationship("Arena", back_populates="user")
    todos = relationship("Todo", back_populates="user")

    @classmethod
    def check_password(cls, username, password, db):
        user = db.query(User).filter(User.username == username).first()

        if not user:
            raise HTTPException(status_code=401, detail="The username or password is incorrect.")

        if not argon2.verify(password, user.password):
            raise HTTPException(status_code=401, detail="The username or password is incorrect.")

        return user

    @classmethod
    def check_input(cls, username, password, db):
        if not username:
            raise ValueError("The username cannot be empty.")

        if not password:
            raise ValueError("The password cannot be empty.")

        if len(password) < 8:
            raise ValueError("The password cannot be shorter than 8 characters.")
        if not any(character.isupper() for character in password):
            raise ValueError("The password must contain an uppercase letter.")    
        if not any(character.islower() for character in password):
            raise ValueError("The password must contain a lowercase letter.")    
        if not any(c in string.punctuation for c in password):
            raise ValueError("The password must contain a special character.")    


        if db.query(User).filter(User.username == username).first():
            raise ValueError("Please try a different username.")

    @classmethod
    def add(cls, db, username, password, is_active=True):
        hash = argon2.hash(password)

        db.add(User(username=username, password=hash, is_active=is_active))
        db.commit()