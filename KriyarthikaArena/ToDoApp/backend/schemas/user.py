#Mahika Bagri
#March 10 2026

from pydantic import BaseModel

class UserPy(BaseModel):
    username: str
    password: str
    is_active: bool = True

class Login(BaseModel):
    username: str
    password: str

class Token(BaseModel):
    access_token: str
    token_type: str